"""Predeclared retrospective queue-indicator comparison on two Indian gauges.

Units are mm/day for rainfall and PET, m3/s for discharge, claims/day for queue
rates, claims for backlog, and monthly probabilities for the comparison target.
The primary target is district 3-month soil-moisture anomaly <= -15 percent.
Training years are 1981-2010 and held-out years are 2011-2020.

This is retrospective diagnosis. Same-month observed streamflow is allowed;
no ahead-of-event forecasting claim is made. Missing streamflow is linearly
interpolated inside the observed record and every filled day is flagged.

Run from the repository root with the ``drought`` Conda environment:
    python src/P02/real_data_comparison.py --audit-only
    python src/P02/real_data_comparison.py
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from dataclasses import asdict, dataclass, replace
from pathlib import Path
import re
import sys
from typing import Iterable

import numpy as np
import pandas as pd
from scipy.stats import rankdata

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from shared.queue_core import (  # noqa: E402
    QueueConfig,
    birth_rates,
    death_rates,
)

__all__ = [
    "GaugeSpec",
    "ComparisonConfig",
    "GAUGES",
    "MODEL_NAMES",
    "Q_STARS",
    "prepare_daily",
    "interpolate_flagged",
    "demand_rates",
    "supply_rates",
    "daily_queue_probabilities",
    "aggregate_monthly",
    "load_district_targets",
    "compute_ssi3",
    "SeasonalLogisticL2",
    "fit_predict_models",
    "binary_metrics",
    "compute_metrics",
    "year_block_bootstrap",
    "imputation_sensitivity",
    "reliability_table",
    "event_table",
    "run_audit",
    "run_pipeline",
]

DEFAULT_CAMELS_ROOT = Path(
    r"D:\Datasets\CIMP6_India\data_raw\camels_ind_forcings"
)
DEFAULT_DIE_ROOT = Path(
    r"D:\Datasets\Drought_Intelligence_Explorer_v2\source"
    r"\anixn-drought-intelligence-explorer-d0b1573\data"
)
DEFAULT_OUTPUT = ROOT / "analysis/P02_methods/data"
TRAIN_YEARS = tuple(range(1981, 2011))
TEST_YEARS = tuple(range(2011, 2021))
Q_STARS = (4, 6, 8)
MODEL_NAMES = (
    "climatology",
    "spi3",
    "spei3",
    "ssi3",
    "queue",
    "ssi3_plus_queue",
)
CONVENTIONAL_MODELS = ("climatology", "spi3", "spei3", "ssi3")
PROVENANCE = (
    "src/P02/real_data_comparison.py; "
    "analysis/P02_methods/REAL_DATA_COMPARISON_PROTOCOL.md; 2026-11-25"
)


@dataclass(frozen=True)
class GaugeSpec:
    """One gauge-to-district mapping and its explicit area proxy."""

    gauge_id: int
    district_id: str
    district_name: str
    area_ha: float


GAUGES = (
    GaugeSpec(4026, "maharashtra-sangli", "Sangli", 45_000.0),
    GaugeSpec(4064, "karnataka-yadgir", "Yadgir", 72_252.0),
)


@dataclass(frozen=True)
class ComparisonConfig:
    """Fixed settings for the predeclared comparison."""

    camels_root: Path = DEFAULT_CAMELS_ROOT
    die_root: Path = DEFAULT_DIE_ROOT
    output_dir: Path = DEFAULT_OUTPUT
    train_years: tuple[int, ...] = TRAIN_YEARS
    test_years: tuple[int, ...] = TEST_YEARS
    warmup_year: int = 1980
    end_year: int = 2020
    claim_depth_mm: float = 20.0
    firm_share: float = 0.5
    service_cap_claims_day: float = 3.0
    effective_rain_fraction: float = 0.7
    sowing_doy: int = 200
    season_length_days: int = 120
    peak_kc: float = 1.2
    l2_penalty: float = 1.0
    max_queue_step_days: float = 0.1
    flow_imputation_method: str = "linear"
    max_flow_gap_days: int = 7
    reliability_bins: int = 5
    onset_window_months: int = 6
    onset_probability_threshold: float = 0.5
    sma_drought_threshold_pct: float = -15.0
    bootstrap_replicates: int = 2000
    bootstrap_seed: int = 20261125

    @property
    def queue_config(self) -> QueueConfig:
        """Return the fixed finite-capacity aggregate-supply queue settings."""
        return QueueConfig(K=20, c=1, theta=8, alpha=1.5, eta=0.02)


def _date_from_parts(frame: pd.DataFrame) -> pd.Series:
    return pd.to_datetime(frame[["year", "month", "day"]])


def _longest_true_run(mask: Iterable[bool]) -> int:
    longest = current = 0
    for value in mask:
        if bool(value):
            current += 1
            longest = max(longest, current)
        else:
            current = 0
    return longest


def _fill_short_gaps(series: pd.Series, method: str,
                     max_gap_days: int) -> pd.Series:
    """Fill only bounded interior gaps; leave long/edge gaps missing."""
    if max_gap_days < 1:
        raise ValueError("max_gap_days must be at least one")
    values = pd.Series(series, copy=True)
    if method == "linear":
        candidate = values.interpolate(method="time", limit_area="inside")
    elif method == "forward":
        candidate = values.ffill()
    else:
        raise ValueError("method must be 'linear' or 'forward'")
    missing = values.isna()
    if missing.any():
        run_id = missing.ne(missing.shift()).cumsum()
        for _, run in values.loc[missing].groupby(run_id.loc[missing]):
            if len(run) > max_gap_days:
                candidate.loc[run.index] = np.nan
    return candidate


def interpolate_flagged(series: pd.Series, method: str = "linear",
                        max_gap_days: int = 7
                        ) -> tuple[pd.Series, pd.Series]:
    """Fill interior missing values and return an explicit imputation flag.

    ``linear`` uses time-linear interpolation to match the R/repository
    contract. ``forward`` carries the last observation forward and is used only
    as a causal sensitivity. Neither method extrapolates leading/trailing gaps.
    """
    values = pd.Series(series, copy=True)
    missing = values.isna()
    filled = _fill_short_gaps(values, method, max_gap_days)
    if filled.loc[missing].isna().any():
        raise ValueError("leading/trailing missing values cannot be filled")
    return filled, missing


def demand_rates(dates: pd.DatetimeIndex, rainfall_mm: np.ndarray,
                 pet_mm: np.ndarray, cfg: ComparisonConfig) -> np.ndarray:
    """Reproduce the R crop-water-demand formula exactly, in claims/day."""
    doy = dates.day_of_year.to_numpy(dtype=int)
    phase = ((doy - cfg.sowing_doy) % 365) / cfg.season_length_days
    kc = np.where(
        phase <= 1.0,
        0.4 + (cfg.peak_kc - 0.4) * np.sin(np.pi * np.clip(phase, 0.0, 1.0)),
        0.35,
    )
    rainfall_mm = np.asarray(rainfall_mm, dtype=float)
    pet_mm = np.asarray(pet_mm, dtype=float)
    need_mm = np.maximum(kc * pet_mm - cfg.effective_rain_fraction * rainfall_mm, 0.0)
    # The area cancels in lambda, but the full physical formula is retained to
    # mirror P02/R/01_build_rates.R and to make the unit conversion explicit.
    area_ha = GAUGES[0].area_ha
    claim_volume_m3 = area_ha * 10.0 * cfg.claim_depth_mm
    return need_mm * area_ha * 10.0 / claim_volume_m3


def supply_rates(discharge_m3s: np.ndarray, area_ha: float,
                 cfg: ComparisonConfig) -> np.ndarray:
    """Convert observed discharge to capped aggregate service, claims/day."""
    discharge_m3s = np.asarray(discharge_m3s, dtype=float)
    claim_volume_m3 = area_ha * 10.0 * cfg.claim_depth_mm
    firm_m3_day = discharge_m3s * 86_400.0 * cfg.firm_share
    return np.minimum(firm_m3_day / claim_volume_m3,
                      cfg.service_cap_claims_day)


def prepare_daily(spec: GaugeSpec, cfg: ComparisonConfig) -> pd.DataFrame:
    """Load one gauge on a complete daily calendar and construct lambda/mu.

    The record is trimmed to the last complete observed month. Interior missing
    streamflow is linearly interpolated between observed values; leading gaps
    are not extrapolated and cause an error. Imputation is retrospective
    reconstruction, not a forecasting operation.
    """
    force_path = (cfg.camels_root / "catchment_mean_forcings"
                  / f"{spec.gauge_id:05d}.csv")
    flow_path = (cfg.camels_root / "streamflow_timeseries"
                 / "streamflow_observed.csv")
    force = pd.read_csv(
        force_path,
        usecols=["year", "month", "day", "prcp(mm/day)", "pet_gleam(mm/day)"],
    )
    flow = pd.read_csv(
        flow_path,
        usecols=["year", "month", "day", str(spec.gauge_id)],
    )
    force["date"] = _date_from_parts(force)
    flow["date"] = _date_from_parts(flow)
    flow = flow.rename(columns={str(spec.gauge_id): "q_m3s"})
    daily = force.merge(flow[["date", "q_m3s"]], on="date",
                        how="inner", validate="one_to_one")
    daily = daily.sort_values("date").set_index("date")
    expected = pd.date_range(
        f"{cfg.warmup_year}-01-01", f"{cfg.end_year}-12-31", freq="D"
    )
    daily = daily.reindex(expected)
    daily.index.name = "date"
    source_missing = int(daily["q_m3s"].isna().sum())
    source_zero = int((daily["q_m3s"] == 0.0).sum())
    last_observed = daily["q_m3s"].last_valid_index()
    if last_observed is None:
        raise ValueError(f"{spec.gauge_id}: no observed discharge")
    complete_month_end = last_observed + pd.offsets.MonthEnd(0)
    if last_observed != complete_month_end:
        complete_month_end = last_observed + pd.offsets.MonthEnd(-1)
    analysis_end = min(complete_month_end, expected[-1])
    observed_flow_full = daily["q_m3s"].copy()
    if (observed_flow_full.dropna() < 0).any():
        raise ValueError(f"{spec.gauge_id}: negative observed discharge")
    filled_full = _fill_short_gaps(
        observed_flow_full, cfg.flow_imputation_method, cfg.max_flow_gap_days
    )
    first_unfilled = filled_full.index[filled_full.isna()]
    if len(first_unfilled):
        continuous_end = (
            first_unfilled[0] - pd.Timedelta(days=1)
        ) + pd.offsets.MonthEnd(0)
        analysis_end = min(analysis_end, continuous_end)
    if analysis_end < expected[0]:
        raise ValueError(f"{spec.gauge_id}: no complete usable flow month")
    excluded_trailing = int((daily.index > analysis_end).sum())

    # Observations around a short gap may bracket it retrospectively. Long
    # gaps remain missing and end the usable record; nothing is extrapolated.
    daily = daily.loc[:analysis_end].copy()
    observed_flow = observed_flow_full.loc[:analysis_end]
    filled_flow = filled_full.loc[:analysis_end]
    missing = observed_flow.isna()
    if filled_flow.loc[missing].isna().any():
        raise ValueError(f"{spec.gauge_id}: leading flow gaps cannot be filled")
    daily.attrs.update({
        "source_missing_flow_days": source_missing,
        "source_longest_missing_run_days": _longest_true_run(
            observed_flow_full.isna()
        ),
        "source_zero_flow_days": source_zero,
        "source_last_observed_date": str(last_observed.date()),
        "analysis_end_date": str(analysis_end.date()),
        "excluded_trailing_flow_days": excluded_trailing,
    })

    for column in ("prcp(mm/day)", "pet_gleam(mm/day)"):
        if daily[column].isna().any():
            raise ValueError(f"{spec.gauge_id}: missing {column}; no silent fill")
        if (daily[column] < 0).any():
            raise ValueError(f"{spec.gauge_id}: negative {column}")
    daily["q_missing"] = missing
    daily["q_imputed"] = missing
    daily["q_m3s"] = filled_flow
    daily["q_imputation_method"] = np.where(
        daily["q_imputed"],
        "linear_time" if cfg.flow_imputation_method == "linear" else "forward_fill",
        "observed",
    )
    daily["q_zero_day"] = daily["q_m3s"] == 0.0

    # lambda is independent of the gauge-specific area because the same area
    # defines a claim; mu is not. The R-equivalent expression is used for both.
    daily["lambda_claims_day"] = demand_rates(
        daily.index,
        daily["prcp(mm/day)"].to_numpy(),
        daily["pet_gleam(mm/day)"].to_numpy(),
        cfg,
    )
    daily["claim_volume_m3"] = spec.area_ha * 10.0 * cfg.claim_depth_mm
    daily["cwr_m3_day"] = (
        daily["lambda_claims_day"] * daily["claim_volume_m3"]
    )
    daily["mu_claims_day"] = supply_rates(
        daily["q_m3s"].to_numpy(), spec.area_ha, cfg
    )
    daily["gauge_id"] = spec.gauge_id
    daily["district_id"] = spec.district_id
    daily["is_warmup"] = daily.index.year < min(cfg.train_years)
    daily["provenance"] = PROVENANCE
    return daily


def _queue_rhs(p: np.ndarray, birth: np.ndarray,
               death: np.ndarray) -> np.ndarray:
    """Forward-equation right-hand side pA without allocating a full matrix."""
    up = birth[:-1] * p[:-1]
    down = death[1:] * p[1:]
    out = np.zeros_like(p)
    out[:-1] -= up
    out[1:] += up
    out[1:] -= down
    out[:-1] += down
    return out


def daily_queue_probabilities(
    lam: np.ndarray,
    mu: np.ndarray,
    cfg: ComparisonConfig,
) -> tuple[np.ndarray, dict[str, float | int]]:
    """Propagate the finite-state queue with piecewise-constant daily rates.

    Rates on day d act from the start to the end of that day. The returned row
    is therefore the end-of-day distribution. RK4 substeps are chosen from the
    generator-rate bound so dt * max|eigenvalue| remains below 2.5.
    """
    lam = np.asarray(lam, dtype=float)
    mu = np.asarray(mu, dtype=float)
    if lam.ndim != 1 or mu.shape != lam.shape or len(lam) == 0:
        raise ValueError("lam and mu must be non-empty one-dimensional arrays")
    if not np.isfinite(lam).all() or not np.isfinite(mu).all():
        raise ValueError("queue rates must be finite")
    if (lam < 0).any() or (mu < 0).any():
        raise ValueError("queue rates must be non-negative")

    qcfg = cfg.queue_config
    p = np.zeros(qcfg.K + 1, dtype=float)
    p[0] = 1.0
    probabilities = np.empty((len(lam), qcfg.K + 1), dtype=float)
    rate_bound = float(np.max(
        lam + qcfg.c * mu * qcfg.alpha + qcfg.K * qcfg.eta
    ))
    if rate_bound <= 0.0:
        n_substeps = 1
    else:
        stability_step = 2.5 / rate_bound
        allowed_step = min(cfg.max_queue_step_days, stability_step)
        n_substeps = max(1, int(math.ceil(1.0 / allowed_step)))
    dt = 1.0 / n_substeps

    for day, (arrival, service) in enumerate(zip(lam, mu, strict=True)):
        birth = birth_rates(float(arrival), qcfg)
        death = death_rates(float(service), qcfg)
        for _ in range(n_substeps):
            k1 = _queue_rhs(p, birth, death)
            k2 = _queue_rhs(p + 0.5 * dt * k1, birth, death)
            k3 = _queue_rhs(p + 0.5 * dt * k2, birth, death)
            k4 = _queue_rhs(p + dt * k3, birth, death)
            p = p + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
            p = np.clip(p, 0.0, None)
            total = float(p.sum())
            if not np.isfinite(total) or total <= 0.0:
                raise FloatingPointError(f"invalid probability sum on day {day}")
            p /= total
        probabilities[day] = p

    diagnostics = {
        "rate_bound_per_day": rate_bound,
        "n_substeps_per_day": n_substeps,
        "step_days": dt,
        "max_abs_probability_sum_error": float(np.max(np.abs(
            probabilities.sum(axis=1) - 1.0
        ))),
    }
    return probabilities, diagnostics


def aggregate_monthly(daily: pd.DataFrame) -> pd.DataFrame:
    """Aggregate end-of-day queue states and daily rates to calendar months."""
    work = daily.copy()
    work["period"] = work.index.to_period("M")
    monthly = work.groupby("period").agg(
        days=("gauge_id", "size"),
        q_m3s_mean=("q_m3s", "mean"),
        q_zero_days=("q_zero_day", "sum"),
        q_imputed_days=("q_imputed", "sum"),
        lambda_mean_claims_day=("lambda_claims_day", "mean"),
        mu_mean_claims_day=("mu_claims_day", "mean"),
    )
    # The queue probability columns are attached by the caller. Here we retain
    # a generic aggregation path for any p_ge_* or E_Q column already present.
    extra = [column for column in work.columns
             if column.startswith("p_ge_") or column == "E_Q_claims"]
    if extra:
        monthly = monthly.join(work.groupby("period")[extra].mean())
    expected = pd.Series(monthly.index.days_in_month, index=monthly.index)
    if not (monthly["days"] == expected).all():
        raise ValueError("daily calendar does not contain complete months")
    return monthly


def load_district_targets(spec: GaugeSpec,
                          cfg: ComparisonConfig) -> pd.DataFrame:
    """Load district SPI-3, SPEI-3 and 3-month soil-moisture anomaly."""
    frames: list[pd.DataFrame] = []
    for filename, name in (
        ("spi_03.csv", "spi3"),
        ("spei_03.csv", "spei3"),
        ("soil_moisture.csv", "sma_pct"),
    ):
        path = cfg.die_root / "drought" / filename
        wide = pd.read_csv(path)
        matches = wide.loc[wide["district_id"] == spec.district_id]
        if len(matches) != 1:
            raise ValueError(f"expected one {spec.district_id} row in {path}")
        month_columns = [column for column in wide.columns
                         if re.fullmatch(r"\d{4}-\d{2}", str(column))]
        values = matches.iloc[0][month_columns].copy()
        values.index = pd.PeriodIndex(values.index, freq="M")
        values = pd.to_numeric(values, errors="coerce")
        values.name = name
        frames.append(values)
    targets = pd.concat(frames, axis=1).sort_index()
    targets = targets.loc[
        (targets.index.year >= min(cfg.train_years))
        & (targets.index.year <= cfg.end_year)
    ]
    targets["y_sma"] = targets["sma_pct"].le(cfg.sma_drought_threshold_pct).astype(
        "Int64"
    )
    targets.loc[targets["sma_pct"].isna(), "y_sma"] = pd.NA
    targets["gauge_id"] = spec.gauge_id
    targets["district_id"] = spec.district_id
    targets["provenance"] = PROVENANCE
    return targets


def compute_ssi3(monthly_flow: pd.DataFrame,
                 cfg: ComparisonConfig) -> pd.DataFrame:
    """Compute a training-standardized 3-month log-flow anomaly (SSI-3 style).

    The transformed variable is log1p of trailing 3-month mean discharge. Its
    per-calendar-month mean and population standard deviation use 1981-2010
    only. This is a transparent log-anomaly proxy, not a gamma/empirical-cdf SSI.
    """
    flow = monthly_flow["q_m3s_mean"].astype(float)
    log_three_month = np.log1p(flow.rolling(3, min_periods=3).mean())
    out = pd.DataFrame({"ssi3_log3month_mean": log_three_month})
    train = log_three_month.loc[
        log_three_month.index.year.isin(cfg.train_years)
    ]
    if train.isna().any():
        raise ValueError("training SSI-3 has missing 3-month windows")
    climatology = train.groupby(train.index.month).agg(["mean", "std"])
    if (climatology["std"] <= 0).any():
        raise ValueError("training SSI-3 has zero monthly variance")
    means = log_three_month.index.month.map(climatology["mean"])
    scales = log_three_month.index.month.map(climatology["std"])
    out["ssi3"] = (log_three_month - means) / scales
    return out


def build_gauge_features(spec: GaugeSpec,
                         cfg: ComparisonConfig) -> tuple[pd.DataFrame, pd.DataFrame,
                                                         dict[str, float | int]]:
    """Build daily queue output and monthly candidate predictors for one gauge."""
    daily = prepare_daily(spec, cfg)
    probabilities, diagnostics = daily_queue_probabilities(
        daily["lambda_claims_day"].to_numpy(),
        daily["mu_claims_day"].to_numpy(),
        cfg,
    )
    daily["E_Q_claims"] = probabilities @ np.arange(probabilities.shape[1])
    for q_star in Q_STARS:
        daily[f"p_ge_{q_star}"] = probabilities[:, q_star:].sum(axis=1)
    monthly = aggregate_monthly(daily)
    monthly = monthly.join(compute_ssi3(monthly, cfg))
    targets = load_district_targets(spec, cfg)
    features = monthly.join(targets, how="inner")
    features = features.loc[
        (features.index.year >= min(cfg.train_years))
        & (features.index.year <= cfg.end_year)
    ].copy()
    features["year"] = features.index.year
    features["month"] = features.index.month
    features["date"] = features.index.to_timestamp()
    features["split"] = np.where(
        features["year"].isin(cfg.train_years), "train", "test"
    )
    if not features["year"].isin(cfg.train_years + cfg.test_years).all():
        raise ValueError("feature years fall outside the declared split")
    features["provenance"] = PROVENANCE
    diagnostics.update({
        "gauge_id": spec.gauge_id,
        "daily_rows": len(daily),
        "monthly_rows": len(features),
    })
    return daily, features, diagnostics


class SeasonalLogisticL2:
    """Small Newton/IRLS logistic model with an unpenalized intercept."""

    def __init__(self, l2_penalty: float = 1.0, max_iter: int = 100,
                 tolerance: float = 1e-9):
        self.l2_penalty = float(l2_penalty)
        self.max_iter = int(max_iter)
        self.tolerance = float(tolerance)
        self.coef_: np.ndarray | None = None
        self.converged_ = False
        self.n_iter_: int = 0

    @staticmethod
    def _sigmoid(eta: np.ndarray) -> np.ndarray:
        eta = np.clip(np.asarray(eta, dtype=float), -40.0, 40.0)
        return 1.0 / (1.0 + np.exp(-eta))

    def _objective(self, X: np.ndarray, y: np.ndarray, beta: np.ndarray) -> float:
        eta = X @ beta
        loss = np.logaddexp(0.0, eta) - y * eta
        penalty = 0.5 * self.l2_penalty * float(beta[1:] @ beta[1:])
        return float(loss.sum() + penalty)

    def fit(self, X: np.ndarray, y: np.ndarray) -> "SeasonalLogisticL2":
        X = np.asarray(X, dtype=float)
        y = np.asarray(y, dtype=float)
        if X.ndim != 2 or y.shape != (len(X),):
            raise ValueError("X and y have incompatible shapes")
        if len(np.unique(y)) != 2:
            raise ValueError("logistic fitting requires both target classes")
        if self.l2_penalty < 0:
            raise ValueError("L2 penalty must be non-negative")
        beta = np.zeros(X.shape[1], dtype=float)
        prevalence = float(np.clip(y.mean(), 1e-6, 1.0 - 1e-6))
        beta[0] = math.log(prevalence / (1.0 - prevalence))
        penalty = np.full(X.shape[1], self.l2_penalty, dtype=float)
        penalty[0] = 0.0
        self.converged_ = False

        for iteration in range(1, self.max_iter + 1):
            probability = self._sigmoid(X @ beta)
            gradient = X.T @ (probability - y) + penalty * beta
            weights = probability * (1.0 - probability)
            hessian = X.T @ (X * weights[:, None]) + np.diag(penalty)
            step = np.linalg.solve(hessian, gradient)
            old_objective = self._objective(X, y, beta)
            fraction = 1.0
            while fraction > 1e-8:
                candidate = beta - fraction * step
                if self._objective(X, y, candidate) <= old_objective + 1e-12:
                    break
                fraction *= 0.5
            beta = candidate
            self.n_iter_ = iteration
            if float(np.max(np.abs(fraction * step))) < self.tolerance:
                self.converged_ = True
                break
        if not np.isfinite(beta).all():
            raise FloatingPointError("non-finite logistic coefficients")
        self.coef_ = beta
        return self

    def predict_proba(self, X: np.ndarray) -> np.ndarray:
        if self.coef_ is None:
            raise RuntimeError("fit must be called before predict_proba")
        return self._sigmoid(np.asarray(X, dtype=float) @ self.coef_)


def _design_matrix(frame: pd.DataFrame, columns: list[str],
                   means: np.ndarray, scales: np.ndarray) -> np.ndarray:
    standardized = (frame[columns].to_numpy(dtype=float) - means) / scales
    month_effects = np.column_stack([
        (frame["month"].to_numpy(dtype=int) == month).astype(float)
        for month in range(2, 13)
    ])
    return np.column_stack([
        np.ones(len(frame), dtype=float), standardized, month_effects
    ])


def fit_predict_models(features: pd.DataFrame, spec: GaugeSpec, target: str,
                       q_star: int, cfg: ComparisonConfig
                       ) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Fit all models on training years and predict the common analysis sample."""
    queue_column = f"p_ge_{q_star}"
    required = [
        f"y_{target}", "spi3", "spei3", "ssi3", "p_ge_4", "p_ge_6", "p_ge_8"
    ]
    complete = features[required].notna().all(axis=1)
    analysis = features.loc[complete].copy().sort_index()
    if analysis.empty:
        raise ValueError(f"no complete cases for gauge {spec.gauge_id}")
    train = analysis["split"].eq("train")
    test = analysis["split"].eq("test")
    if not train.any() or not test.any():
        raise ValueError("both training and test rows are required")
    y_train = analysis.loc[train, f"y_{target}"].astype(int).to_numpy()

    model_columns = {
        "spi3": ["spi3"],
        "spei3": ["spei3"],
        "ssi3": ["ssi3"],
        "queue": [queue_column],
        "ssi3_plus_queue": ["ssi3", queue_column],
    }
    predictions: dict[str, np.ndarray] = {}
    parameters: list[dict[str, object]] = []

    # Training monthly frequencies, numerically clipped only to keep log loss
    # finite. Brier score and AUC use the unmodified clipped probabilities.
    frequencies = (
        analysis.loc[train].groupby("month")[f"y_{target}"].mean().reindex(
            range(1, 13)
        )
    )
    if frequencies.isna().any():
        raise ValueError("a calendar month has no training target values")
    predictions["climatology"] = np.clip(
        analysis["month"].map(frequencies).to_numpy(dtype=float), 1e-6, 1.0 - 1e-6
    )
    for month, value in frequencies.items():
        parameters.append({
            "gauge_id": spec.gauge_id,
            "target": target,
            "q_star": q_star,
            "model": "climatology",
            "parameter_type": "month_frequency",
            "term": f"month_{int(month):02d}",
            "value": float(value),
        })

    for model_name, columns in model_columns.items():
        train_values = analysis.loc[train, columns].to_numpy(dtype=float)
        means = train_values.mean(axis=0)
        scales = train_values.std(axis=0, ddof=0)
        scales = np.where(scales > 1e-12, scales, 1.0)
        X_train = _design_matrix(analysis.loc[train], columns, means, scales)
        X_all = _design_matrix(analysis, columns, means, scales)
        model = SeasonalLogisticL2(cfg.l2_penalty).fit(X_train, y_train)
        predictions[model_name] = model.predict_proba(X_all)
        terms = (["intercept"] + columns
                 + [f"month_{month:02d}" for month in range(2, 13)])
        for term, coefficient in zip(terms, model.coef_, strict=True):
            parameters.append({
                "gauge_id": spec.gauge_id,
                "target": target,
                "q_star": q_star,
                "model": model_name,
                "parameter_type": "coefficient",
                "term": term,
                "value": float(coefficient),
            })
        for column, mean, scale in zip(columns, means, scales, strict=True):
            parameters.append({
                "gauge_id": spec.gauge_id,
                "target": target,
                "q_star": q_star,
                "model": model_name,
                "parameter_type": "training_standardization",
                "term": column,
                "value": float(mean),
                "scale": float(scale),
            })
        parameters.append({
            "gauge_id": spec.gauge_id,
            "target": target,
            "q_star": q_star,
            "model": model_name,
            "parameter_type": "fit_diagnostic",
            "term": "converged",
            "value": float(model.converged_),
        })
        parameters.append({
            "gauge_id": spec.gauge_id,
            "target": target,
            "q_star": q_star,
            "model": model_name,
            "parameter_type": "fit_diagnostic",
            "term": "n_iterations",
            "value": float(model.n_iter_),
        })

    base = analysis[["date", "year", "month", "split", f"y_{target}"]].copy()
    base = base.rename(columns={f"y_{target}": "y"})
    base["gauge_id"] = spec.gauge_id
    base["district_id"] = spec.district_id
    base["target"] = target
    base["q_star"] = q_star
    long_predictions = []
    for model_name, probability in predictions.items():
        part = base.copy()
        part["model"] = model_name
        part["predicted_probability"] = probability
        part["provenance"] = PROVENANCE
        long_predictions.append(part)
    parameter_frame = pd.DataFrame(parameters)
    parameter_frame["provenance"] = PROVENANCE
    return pd.concat(long_predictions, ignore_index=True), parameter_frame


def _count_event_runs(y: np.ndarray) -> int:
    values = np.asarray(y, dtype=int)
    if len(values) == 0:
        return 0
    return int(np.sum((values == 1) & np.r_[True, values[:-1] == 0]))


def _calibration_diagnostics(y: np.ndarray, probability: np.ndarray
                             ) -> tuple[float, float]:
    """Fit descriptive held-out calibration intercept/slope without changing p."""
    clipped = np.clip(np.asarray(probability, dtype=float), 1e-6, 1.0 - 1e-6)
    logit = np.log(clipped / (1.0 - clipped))
    if len(np.unique(y)) != 2 or float(np.ptp(logit)) < 1e-10:
        return float("nan"), float("nan")
    X = np.column_stack([np.ones(len(logit)), logit])
    # Tiny ridge is numerical only; ideal calibration is intercept 0, slope 1.
    model = SeasonalLogisticL2(l2_penalty=1e-6).fit(X, y)
    return float(model.coef_[0]), float(model.coef_[1])


def binary_metrics(y: np.ndarray, probability: np.ndarray) -> dict[str, float]:
    """Return Brier score, AUC, log loss and descriptive calibration metrics."""
    y = np.asarray(y, dtype=int)
    probability = np.asarray(probability, dtype=float)
    if y.shape != probability.shape or len(y) == 0:
        raise ValueError("y and probability must be non-empty and aligned")
    if not np.isfinite(probability).all():
        raise ValueError("probabilities must be finite")
    if ((probability < 0) | (probability > 1)).any():
        raise ValueError("probabilities must lie in [0, 1]")
    clipped = np.clip(probability, 1e-6, 1.0 - 1e-6)
    brier = float(np.mean((probability - y) ** 2))
    log_loss = float(-np.mean(y * np.log(clipped)
                              + (1 - y) * np.log(1.0 - clipped)))
    n_positive = int(y.sum())
    n_negative = int(len(y) - n_positive)
    if n_positive == 0 or n_negative == 0:
        auc = float("nan")
    else:
        ranks = rankdata(probability, method="average")
        auc = float((ranks[y == 1].sum() - n_positive * (n_positive + 1) / 2.0)
                    / (n_positive * n_negative))
    calibration_intercept, calibration_slope = _calibration_diagnostics(y, probability)
    return {
        "brier": brier,
        "auc": auc,
        "log_loss": log_loss,
        "calibration_intercept": calibration_intercept,
        "calibration_slope": calibration_slope,
        "n": float(len(y)),
        "event_months": float(n_positive),
        "n_events": float(_count_event_runs(y)),
        "prevalence": float(y.mean()),
        "event_month_mean_probability": float(probability[y == 1].mean())
        if n_positive else float("nan"),
        "non_event_month_mean_probability": float(probability[y == 0].mean())
        if n_negative else float("nan"),
    }


def compute_metrics(predictions: pd.DataFrame) -> pd.DataFrame:
    """Compute held-out metrics; Brier versus SSI is the sole decision gate."""
    rows: list[dict[str, object]] = []
    test = predictions.loc[predictions["split"].eq("test")].copy()
    for keys, group in test.groupby(
        ["gauge_id", "target", "q_star", "model"], sort=True
    ):
        gauge_id, target, q_star, model = keys
        metrics = binary_metrics(
            group["y"].astype(int).to_numpy(),
            group["predicted_probability"].to_numpy(),
        )
        metrics.update({
            "gauge_id": int(gauge_id),
            "target": str(target),
            "q_star": int(q_star),
            "model": str(model),
            "is_primary": bool(target == "sma" and q_star == 6),
            "baseline_status": (
                "external_non_strict_1981_2020_reference"
                if model in {"spi3", "spei3"} else "training_defined"
            ),
        })
        rows.append(metrics)
    metrics = pd.DataFrame(rows)

    metrics["climatology_brier"] = np.nan
    metrics["brier_skill"] = np.nan
    metrics["delta_brier_vs_ssi3"] = np.nan
    metrics["delta_auc_vs_ssi3"] = np.nan
    metrics["delta_brier_vs_best_conventional"] = np.nan
    metrics["delta_auc_vs_best_conventional"] = np.nan
    metrics["best_conventional_model"] = ""
    metrics["queue_adds_information"] = pd.Series(pd.NA, index=metrics.index,
                                                  dtype="boolean")

    for _, block in metrics.groupby(["gauge_id", "target", "q_star"], sort=True):
        index = block.index
        reference = block.loc[block["model"].eq("climatology")].iloc[0]
        ssi = block.loc[block["model"].eq("ssi3")].iloc[0]
        conventional = block.loc[block["model"].isin(CONVENTIONAL_MODELS)]
        best = conventional.loc[conventional["brier"].idxmin()]
        metrics.loc[index, "climatology_brier"] = reference["brier"]
        metrics.loc[index, "brier_skill"] = 1.0 - block["brier"] / reference["brier"]
        metrics.loc[index, "delta_brier_vs_ssi3"] = block["brier"] - ssi["brier"]
        metrics.loc[index, "delta_auc_vs_ssi3"] = block["auc"] - ssi["auc"]
        metrics.loc[index, "delta_brier_vs_best_conventional"] = (
            block["brier"] - best["brier"]
        )
        metrics.loc[index, "delta_auc_vs_best_conventional"] = (
            block["auc"] - best["auc"]
        )
        metrics.loc[index, "best_conventional_model"] = best["model"]
        for position in block.index[block["model"].eq("ssi3_plus_queue")]:
            metrics.at[position, "queue_adds_information"] = bool(
                metrics.at[position, "delta_brier_vs_ssi3"] < -1e-12
            )
    metrics["provenance"] = PROVENANCE
    return metrics.sort_values(["target", "q_star", "gauge_id", "model"]).reset_index(
        drop=True
    )


def year_block_bootstrap(predictions: pd.DataFrame,
                         cfg: ComparisonConfig) -> pd.DataFrame:
    """Paired test-year bootstrap for the primary Brier-score difference."""
    rows = []
    for spec in GAUGES:
        group = predictions.loc[
            predictions["gauge_id"].eq(spec.gauge_id)
            & predictions["target"].eq("sma")
            & predictions["q_star"].eq(6)
            & predictions["split"].eq("test")
            & predictions["model"].isin(["ssi3", "ssi3_plus_queue"])
        ]
        wide = group.pivot(index="date", columns="model",
                           values="predicted_probability")
        y = group.loc[group["model"].eq("ssi3")].set_index("date")["y"].astype(int)
        wide = wide.join(y.rename("y"), how="inner").dropna()
        difference = ((wide["ssi3_plus_queue"] - wide["y"]) ** 2
                      - (wide["ssi3"] - wide["y"]) ** 2)
        annual_sum = difference.groupby(difference.index.year).sum()
        annual_count = difference.groupby(difference.index.year).size()
        if len(annual_sum) < 2:
            raise ValueError("bootstrap requires at least two available test years")
        rng = np.random.default_rng(cfg.bootstrap_seed + spec.gauge_id)
        sums = annual_sum.to_numpy(dtype=float)
        counts = annual_count.to_numpy(dtype=float)
        selected = rng.integers(
            0, len(sums), size=(cfg.bootstrap_replicates, len(sums))
        )
        draws = sums[selected].sum(axis=1) / counts[selected].sum(axis=1)
        lower, upper = np.quantile(draws, [0.025, 0.975])
        rows.append({
            "gauge_id": spec.gauge_id,
            "target": "sma",
            "q_star": 6,
            "comparison": "ssi3_plus_queue_minus_ssi3",
            "metric": "brier",
            "delta": float(difference.mean()),
            "ci_lower": float(lower),
            "ci_upper": float(upper),
            "bootstrap_fraction_improving": float(np.mean(draws < 0.0)),
            "n_test_years": int(len(sums)),
            "n_replicates": cfg.bootstrap_replicates,
            "seed": cfg.bootstrap_seed + spec.gauge_id,
            "provenance": PROVENANCE,
        })
    return pd.DataFrame(rows)


def imputation_sensitivity(config: ComparisonConfig = ComparisonConfig()
                           ) -> pd.DataFrame:
    """Repeat the primary analysis with causal fill and without imputed months."""
    rows = []
    for sensitivity in ("causal_forward_fill", "exclude_imputed_months"):
        local_config = replace(
            config,
            flow_imputation_method=(
                "forward" if sensitivity == "causal_forward_fill" else "linear"
            ),
        )
        for spec in GAUGES:
            _, features, _ = build_gauge_features(spec, local_config)
            if sensitivity == "exclude_imputed_months":
                features = features.loc[features["q_imputed_days"].eq(0)].copy()
            predictions, _ = fit_predict_models(
                features, spec, "sma", 6, local_config
            )
            metrics = compute_metrics(predictions)
            metrics["sensitivity"] = sensitivity
            metrics["flow_imputation_method"] = local_config.flow_imputation_method
            rows.append(metrics)
    return pd.concat(rows, ignore_index=True)


def reliability_table(predictions: pd.DataFrame,
                      cfg: ComparisonConfig) -> pd.DataFrame:
    """Aggregate held-out predictions into fixed equal-width reliability bins."""
    test = predictions.loc[predictions["split"].eq("test")].copy()
    test["bin"] = np.minimum(
        (test["predicted_probability"] * cfg.reliability_bins).astype(int),
        cfg.reliability_bins - 1,
    )
    rows = []
    for keys, group in test.groupby(
        ["gauge_id", "target", "q_star", "model", "bin"], sort=True
    ):
        gauge_id, target, q_star, model, bin_id = keys
        rows.append({
            "gauge_id": int(gauge_id),
            "target": str(target),
            "q_star": int(q_star),
            "model": str(model),
            "bin": int(bin_id),
            "bin_lower": float(bin_id / cfg.reliability_bins),
            "bin_upper": float((bin_id + 1) / cfg.reliability_bins),
            "n": int(len(group)),
            "mean_predicted_probability": float(
                group["predicted_probability"].mean()
            ),
            "observed_frequency": float(group["y"].mean()),
            "provenance": PROVENANCE,
        })
    return pd.DataFrame(rows)


def _event_runs(frame: pd.DataFrame) -> list[dict[str, object]]:
    """Extract consecutive target-positive runs from a sorted monthly frame."""
    y = frame["y"].astype(int).to_numpy()
    rows: list[dict[str, object]] = []
    start: int | None = None
    for position in range(len(frame) + 1):
        positive = position < len(frame) and y[position] == 1
        if positive and start is None:
            start = position
        if not positive and start is not None:
            end = position - 1
            rows.append({
                "start": frame.iloc[start]["date"],
                "end": frame.iloc[end]["date"],
                "duration_months": int(end - start + 1),
                "left_censored": bool(start > 0 and y[start - 1] == 1),
                "right_censored": bool(
                    (end < len(frame) - 1 and y[end + 1] == 1)
                    or end == len(frame) - 1
                ),
                "severity": float(-frame.iloc[start:end + 1]["target_value"].sum()),
            })
            start = None
    return rows


def event_table(predictions: pd.DataFrame, features: pd.DataFrame,
                cfg: ComparisonConfig) -> pd.DataFrame:
    """Summarize held-out SMA events and retrospective onset offsets."""
    rows: list[dict[str, object]] = []
    test_start = pd.Timestamp(f"{min(cfg.test_years)}-01-01")
    for spec in GAUGES:
        base = predictions.loc[
            (predictions["gauge_id"].eq(spec.gauge_id))
            & (predictions["target"].eq("sma"))
            & (predictions["model"].eq("climatology"))
            & (predictions["q_star"].eq(6))
        ].sort_values("date").copy()
        source = features.loc[
            features["gauge_id"].eq(spec.gauge_id), ["date", "sma_pct"]
        ].copy()
        base = base.merge(source, on="date", how="left", validate="one_to_one")
        base = base.rename(columns={"sma_pct": "target_value"})
        events = [
            event for event in _event_runs(base)
            if pd.Timestamp(event["start"]).year in cfg.test_years
        ]
        for event in events:
            for (q_star, model), group in predictions.loc[
                (predictions["gauge_id"].eq(spec.gauge_id))
                & (predictions["target"].eq("sma"))
                & (predictions["date"].ge(test_start))
            ].groupby(["q_star", "model"], sort=True):
                group = group.sort_values("date")
                in_event = group.loc[
                    group["date"].between(event["start"], event["end"])
                ]
                search_start = max(
                    pd.Timestamp(event["start"]) - pd.DateOffset(
                        months=cfg.onset_window_months
                    ),
                    test_start,
                )
                before_onset = group.loc[
                    group["date"].between(search_start, event["start"])
                    & group["predicted_probability"].gt(
                        cfg.onset_probability_threshold
                    )
                ]
                crossing = (pd.Timestamp(before_onset.iloc[0]["date"])
                            if not before_onset.empty else pd.NaT)
                offset = (
                    (pd.Timestamp(event["start"]).year * 12
                     + pd.Timestamp(event["start"]).month
                     - crossing.year * 12 - crossing.month)
                    if pd.notna(crossing) else float("nan")
                )
                rows.append({
                    "gauge_id": spec.gauge_id,
                    "target": "sma",
                    "q_star": int(q_star),
                    "model": str(model),
                    "start": event["start"],
                    "end": event["end"],
                    "duration_months": event["duration_months"],
                    "left_censored": event["left_censored"],
                    "right_censored": event["right_censored"],
                    "severity_pct_months": event["severity"],
                    "n_event_months_scored": int(len(in_event)),
                    "event_mean_probability": float(
                        in_event["predicted_probability"].mean()
                    ) if len(in_event) else float("nan"),
                    "event_max_probability": float(
                        in_event["predicted_probability"].max()
                    ) if len(in_event) else float("nan"),
                    "threshold_crossing_date": crossing,
                    "retrospective_onset_offset_months": offset,
                    "search_window_months": cfg.onset_window_months,
                    "threshold": cfg.onset_probability_threshold,
                    "timing_interpretation": (
                        "retrospective threshold exceedance; not forecast lead"
                    ),
                    "provenance": PROVENANCE,
                })
    columns = [
        "gauge_id", "target", "q_star", "model", "start", "end",
        "duration_months", "left_censored", "right_censored", "severity_pct_months",
        "n_event_months_scored", "event_mean_probability", "event_max_probability",
        "threshold_crossing_date", "retrospective_onset_offset_months",
        "search_window_months", "threshold", "timing_interpretation", "provenance",
    ]
    return pd.DataFrame(rows, columns=columns)


def _source_audit(daily: pd.DataFrame, spec: GaugeSpec) -> dict[str, object]:
    source_missing = int(daily.attrs["source_missing_flow_days"])
    source_zero = int(daily.attrs["source_zero_flow_days"])
    source_days = int(len(daily) + daily.attrs["excluded_trailing_flow_days"])
    return {
        "gauge_id": spec.gauge_id,
        "district_id": spec.district_id,
        "source_last_observed_date": daily.attrs["source_last_observed_date"],
        "analysis_start_date": str(daily.index.min().date()),
        "analysis_end_date": daily.attrs["analysis_end_date"],
        "source_days": source_days,
        "analysis_daily_rows": int(len(daily)),
        "missing_flow_days": source_missing,
        "analysis_missing_flow_days": int(daily["q_missing"].sum()),
        "imputed_flow_days": int(daily["q_imputed"].sum()),
        "excluded_unusable_flow_days": int(
            daily.attrs["excluded_trailing_flow_days"]
        ),
        "source_longest_missing_run_days": int(
            daily.attrs["source_longest_missing_run_days"]
        ),
        "longest_filled_gap_days": _longest_true_run(daily["q_missing"]),
        "zero_flow_days": source_zero,
        "zero_flow_fraction_observed": float(
            source_zero / (source_days - source_missing)
        ),
        "train_imputed_flow_days": int(
            daily.loc[daily.index.year.isin(TRAIN_YEARS), "q_imputed"].sum()
        ),
        "test_imputed_flow_days": int(
            daily.loc[daily.index.year.isin(TEST_YEARS), "q_imputed"].sum()
        ),
        "provenance": PROVENANCE,
    }


def _target_audit(features: pd.DataFrame, spec: GaugeSpec) -> list[dict[str, object]]:
    rows = []
    for split in ("train", "test"):
        group = features.loc[features["split"].eq(split)]
        y = group["y_sma"].dropna().astype(int)
        expected_months = 12 * len(TRAIN_YEARS if split == "train" else TEST_YEARS)
        rows.append({
            "gauge_id": spec.gauge_id,
            "district_id": spec.district_id,
            "target": "sma",
            "split": split,
            "expected_months": expected_months,
            "months": int(len(group)),
            "excluded_flow_or_incomplete_months": expected_months - int(len(group)),
            "missing_target_months": int(group["y_sma"].isna().sum()),
            "event_months": int(y.sum()),
            "event_fraction": float(y.mean()) if len(y) else float("nan"),
            "n_events": _count_event_runs(y.to_numpy()),
            "provenance": PROVENANCE,
        })
    return rows


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _write_csv(frame: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frame.to_csv(path, index=False, float_format="%.10g")


def _metadata(config: ComparisonConfig, mode: str,
              queue_diagnostics: list[dict[str, float | int]]) -> dict[str, object]:
    source_paths = [
        config.camels_root / "streamflow_timeseries" / "streamflow_observed.csv",
        config.camels_root / "catchment_mean_forcings" / "04026.csv",
        config.camels_root / "catchment_mean_forcings" / "04064.csv",
        config.die_root / "drought" / "soil_moisture.csv",
        config.die_root / "drought" / "spi_03.csv",
        config.die_root / "drought" / "spei_03.csv",
        ROOT / "analysis/P02_methods/REAL_DATA_COMPARISON_PROTOCOL.md",
    ]
    settings = asdict(config)
    settings["camels_root"] = str(config.camels_root)
    settings["die_root"] = str(config.die_root)
    settings["output_dir"] = str(config.output_dir)
    return {
        "mode": mode,
        "date": "2026-11-25",
        "settings": settings,
        "queue_diagnostics": queue_diagnostics,
        "source_sha256": {str(path): _sha256(path) for path in source_paths},
        "numpy_version": np.__version__,
        "pandas_version": pd.__version__,
        "analysis_interpretation": "retrospective diagnosis; not ahead-of-event forecasting",
    }


def run_audit(config: ComparisonConfig = ComparisonConfig()) -> dict[str, object]:
    """Run source and target diagnostics without fitting any comparison model."""
    source_rows = []
    target_rows = []
    for spec in GAUGES:
        daily = prepare_daily(spec, config)
        source_rows.append(_source_audit(daily, spec))
        monthly = aggregate_monthly(daily)
        targets = load_district_targets(spec, config)
        features = monthly.join(targets, how="inner")
        features["split"] = np.where(
            features.index.year.isin(config.train_years), "train", "test"
        )
        target_rows.extend(_target_audit(features, spec))
    source_audit = pd.DataFrame(source_rows)
    target_audit = pd.DataFrame(target_rows)
    _write_csv(source_audit, config.output_dir / "real_data_source_audit.csv")
    _write_csv(target_audit, config.output_dir / "real_data_target_audit.csv")
    metadata = _metadata(config, "audit_only", [])
    (config.output_dir / "real_data_audit_metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    return {"source_audit": source_audit, "target_audit": target_audit}


def _format_metric(value: object) -> str:
    return "NA" if pd.isna(value) else f"{float(value):.4f}"


def _decision_text(primary: pd.DataFrame) -> str:
    combined = primary.loc[primary["model"].eq("ssi3_plus_queue")]
    decisions = combined["queue_adds_information"].fillna(False).astype(bool)
    if len(decisions) == 2 and decisions.all():
        return (
            "Both gauges meet the predeclared rule: adding queue probability to "
            "SSI lowers held-out Brier score for SMA drought at q*=6. This "
            "supports a pilot association, not forecasting or broad superiority."
        )
    if decisions.any():
        return (
            "The result is mixed: adding queue probability to SSI lowers held-out "
            "Brier score in one gauge but not the other. The queue indicator is "
            "not robust across the two co-primary pilot gauges."
        )
    return (
        "Neither gauge meets the predeclared rule: adding queue probability to "
        "SSI does not lower held-out Brier score for SMA drought at q*=6. The "
        "null/negative result is retained; no superiority claim may be made."
    )


def write_results_report(metrics: pd.DataFrame, events: pd.DataFrame,
                         source_audit: pd.DataFrame, target_audit: pd.DataFrame,
                         bootstrap: pd.DataFrame, sensitivity: pd.DataFrame,
                         config: ComparisonConfig) -> Path:
    """Write the results narrative directly from generated tables."""
    primary = metrics.loc[
        metrics["target"].eq("sma") & metrics["q_star"].eq(6)
    ]
    lines = [
        "# Real-data queue-indicator comparison — results",
        "",
        "Date: 25 November 2026. Generated by `src/P02/real_data_comparison.py` "
        "from the locked protocol; no test-year tuning was performed.",
        "",
        "## Decision",
        "",
        _decision_text(primary),
        "",
        "The confirmatory rule is narrow: at q*=6, SSI+queue must have lower "
        "held-out Brier score than SSI alone. The two gauges are co-primary and "
        "overall support requires improvement in both. AUC, calibration, q*=4/8 "
        "and published SPI/SPEI comparisons are secondary or exploratory.",
        "",
        "## Source-data audit",
        "",
        "| Gauge | District | Analysis end | Source missing days | Source longest gap (days) | Imputed days | Excluded unusable days | Longest filled gap (days) | Zero entries | Zero fraction of observed |",
        "|---:|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for _, row in source_audit.iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {row['district_id']} | "
            f"{row['analysis_end_date']} | {int(row['missing_flow_days'])} | "
            f"{int(row['source_longest_missing_run_days'])} | "
            f"{int(row['imputed_flow_days'])} | "
            f"{int(row['excluded_unusable_flow_days'])} | "
            f"{int(row['longest_filled_gap_days'])} | "
            f"{int(row['zero_flow_days'])} | "
            f"{row['zero_flow_fraction_observed']:.3f} |"
        )
    lines.extend([
        "",
        "The analysis stops at each gauge's last complete observed month; "
        "trailing incomplete months are excluded rather than extrapolated. "
        "Only interior gaps of at most seven days were linearly interpolated "
        "and flagged day by day; a longer gap ends the usable record. Zero "
        "entries were retained as recorded; "
        "their hydrological/coding semantics remain unresolved. No rho "
        "interpretation is made for zero-flow days. CAMELS documents m3/s units "
        "and a q_zero attribute but not a station-specific zero/regulation rule.",
        "",
        "## Target availability",
        "",
        "| Gauge | Target | Split | Expected months | Available months | Excluded flow/incomplete | Missing target | Event months | Event fraction | Events |",
        "|---:|---|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for _, row in target_audit.iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {row['target']} | {row['split']} | "
            f"{int(row['expected_months'])} | {int(row['months'])} | "
            f"{int(row['excluded_flow_or_incomplete_months'])} | "
            f"{int(row['missing_target_months'])} | "
            f"{int(row['event_months'])} | {row['event_fraction']:.3f} | "
            f"{int(row['n_events'])} |"
        )

    lines.extend([
        "",
        "## Primary held-out results: SMA drought, q*=6",
        "",
        "| Gauge | Model | Brier | Brier skill | AUC | Log loss | Cal. intercept | Cal. slope | Event-month mean p |",
        "|---:|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for _, row in primary.sort_values(["gauge_id", "model"]).iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {row['model']} | "
            f"{_format_metric(row['brier'])} | {_format_metric(row['brier_skill'])} | "
            f"{_format_metric(row['auc'])} | {_format_metric(row['log_loss'])} | "
            f"{_format_metric(row['calibration_intercept'])} | "
            f"{_format_metric(row['calibration_slope'])} | "
            f"{_format_metric(row['event_month_mean_probability'])} |"
        )

    lines.extend([
        "",
        "Calibration intercept/slope are descriptive held-out diagnostics; ideal "
        "values are 0 and 1. Predictions were not recalibrated.",
        "",
        "![Figure 1. Held-out Brier skill and reliability for the primary comparison.](figures/real_data_comparison.png)",
        "",
        "*Figure 1. Queue alone has small Brier skill over climatology, while "
        "adding queue to SSI does not improve the primary metric. SPI/SPEI are "
        "external, non-strict benchmarks. The comparison is retrospective, not "
        "a forecast.*",
        "",
        "## Incremental decision",
        "",
        "| Gauge | ΔBrier vs SSI | ΔAUC vs SSI | Best conventional model (descriptive) | ΔBrier vs best conventional | Rule met |",
        "|---:|---:|---:|---|---:|---|",
    ])
    for _, row in primary.loc[primary["model"].eq("ssi3_plus_queue")].iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | "
            f"{_format_metric(row['delta_brier_vs_ssi3'])} | "
            f"{_format_metric(row['delta_auc_vs_ssi3'])} | "
            f"{row['best_conventional_model']} | "
            f"{_format_metric(row['delta_brier_vs_best_conventional'])} | "
            f"{'yes' if bool(row['queue_adds_information']) else 'no'} |"
        )

    lines.extend([
        "",
        "Negative Brier differences are improvements. The best conventional "
        "model is selected on the test set only for description and is not a "
        "confirmatory comparator.",
        "",
        "## Paired year-block bootstrap",
        "",
        "| Gauge | ΔBrier (SSI+queue − SSI) | 95% interval | Bootstrap fraction improving |",
        "|---:|---:|---|---:|",
    ])
    for _, row in bootstrap.sort_values("gauge_id").iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {_format_metric(row['delta'])} | "
            f"[{_format_metric(row['ci_lower'])}, {_format_metric(row['ci_upper'])}] | "
            f"{row['bootstrap_fraction_improving']:.3f} |"
        )

    lines.extend([
        "",
        "## q* sensitivity: SSI+queue (exploratory)",
        "",
        "| Gauge | q* | Brier | Brier skill | AUC | ΔBrier vs SSI | ΔAUC vs SSI | Lower Brier than SSI |",
        "|---:|---:|---:|---:|---:|---:|---:|---|",
    ])
    q_sensitivity = metrics.loc[
        metrics["target"].eq("sma") & metrics["model"].eq("ssi3_plus_queue")
    ]
    for _, row in q_sensitivity.sort_values(["gauge_id", "q_star"]).iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {int(row['q_star'])} | "
            f"{_format_metric(row['brier'])} | {_format_metric(row['brier_skill'])} | "
            f"{_format_metric(row['auc'])} | {_format_metric(row['delta_brier_vs_ssi3'])} | "
            f"{_format_metric(row['delta_auc_vs_ssi3'])} | "
            f"{'yes' if bool(row['queue_adds_information']) else 'no'} |"
        )

    lines.extend([
        "",
        "## Missing-flow sensitivity: SSI+queue, q*=6",
        "",
        "| Gauge | Sensitivity | Fill | Test n | Brier | ΔBrier vs SSI | Lower Brier than SSI |",
        "|---:|---|---|---:|---:|---:|---|",
    ])
    sensitivity_combined = sensitivity.loc[
        sensitivity["model"].eq("ssi3_plus_queue")
    ]
    for _, row in sensitivity_combined.sort_values(["gauge_id", "sensitivity"]).iterrows():
        lines.append(
            f"| {int(row['gauge_id'])} | {row['sensitivity']} | "
            f"{row['flow_imputation_method']} | {int(row['n'])} | "
            f"{_format_metric(row['brier'])} | "
            f"{_format_metric(row['delta_brier_vs_ssi3'])} | "
            f"{'yes' if bool(row['queue_adds_information']) else 'no'} |"
        )

    lines.extend([
        "",
        "## External SPI/SPEI benchmark status",
        "",
        "The published district SPI-3 and SPEI-3 use a 1981-2020 reference "
        "period that overlaps the held-out years. Raw CHIRPS/ERA5 inputs are not "
        "available locally, so these models are external, non-strict benchmarks. "
        "They do not determine the confirmatory decision.",
        "",
        "## Event timing",
        "",
        "The retrospective onset offset is the first calibrated queue probability "
        ">0.5 within six months before/on observed SMA onset, using held-out "
        "predictions only. Zero means concurrent threshold exceedance. This is "
        "**not forecast lead time**.",
        "",
        "| Gauge | Test events | Events with crossing | Median offset (months) | Range |",
        "|---:|---:|---:|---:|---|",
    ])
    event_primary = events.loc[
        events["target"].eq("sma")
        & events["q_star"].eq(6)
        & events["model"].eq("ssi3_plus_queue")
    ]
    for gauge_id, group in event_primary.groupby("gauge_id"):
        offset = group["retrospective_onset_offset_months"].dropna()
        lines.append(
            f"| {int(gauge_id)} | {len(group)} | {len(offset)} | "
            f"{_format_metric(offset.median())} | "
            f"{'NA' if offset.empty else f'{offset.min():.0f} to {offset.max():.0f}'} |"
        )

    lines.extend([
        "",
        "## Interpretation limits",
        "",
        "- Proxy-derived queue outputs are **illustrative, under the stated assumptions**.",
        "- Demand lambda is a process scenario, not measured irrigation demand.",
        "- District area proxies are assumptions, not gauge command areas.",
        "- Gauge and district spatial scales differ.",
        "- Same-month observed flow makes this retrospective diagnosis only.",
        "- SSI and queue share observed flow; any gain may reflect richer flow "
        "information rather than queue-state information specifically.",
        "- Published SPI/SPEI have a non-strict 1981-2020 reference period.",
        "- Two gauges are a pilot. No population-general significance is claimed.",
        "- Soil moisture is a land-state target, not a direct crop-loss measure.",
        "- Zero-flow semantics and station regulation remain unresolved.",
        "",
        "## Reproduce",
        "",
        "```powershell",
        "& 'C:\\Users\\ankit.deshmukh\\AppData\\Local\\miniconda3\\envs\\drought\\python.exe' src/P02/real_data_comparison.py",
        "python src/P02/make_comparison_figure.py",
        "```",
        "",
        "No raw CMIP6 output is used anywhere in this comparison.",
        "",
    ])
    path = config.output_dir.parent / "REAL_DATA_COMPARISON_RESULTS.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def run_pipeline(config: ComparisonConfig = ComparisonConfig()) -> dict[str, object]:
    """Run the complete predeclared comparison and write all outputs."""
    config.output_dir.mkdir(parents=True, exist_ok=True)
    all_daily = []
    all_features = []
    queue_diagnostics = []
    source_rows = []
    target_rows = []
    for spec in GAUGES:
        daily, features, diagnostics = build_gauge_features(spec, config)
        all_daily.append(daily.reset_index())
        all_features.append(features.reset_index(drop=True))
        queue_diagnostics.append(diagnostics)
        source_rows.append(_source_audit(daily, spec))
        target_rows.extend(_target_audit(features, spec))

    daily_frame = pd.concat(all_daily, ignore_index=True)
    feature_frame = pd.concat(all_features, ignore_index=True)
    source_audit = pd.DataFrame(source_rows)
    target_audit = pd.DataFrame(target_rows)
    _write_csv(daily_frame, config.output_dir / "real_data_queue_daily.csv")
    _write_csv(feature_frame, config.output_dir / "real_data_comparison_monthly.csv")
    _write_csv(source_audit, config.output_dir / "real_data_source_audit.csv")
    _write_csv(target_audit, config.output_dir / "real_data_target_audit.csv")

    prediction_parts = []
    parameter_parts = []
    for spec in GAUGES:
        features = feature_frame.loc[feature_frame["gauge_id"].eq(spec.gauge_id)]
        for q_star in Q_STARS:
            predictions, parameters = fit_predict_models(
                features, spec, "sma", q_star, config
            )
            prediction_parts.append(predictions)
            parameter_parts.append(parameters)
    predictions = pd.concat(prediction_parts, ignore_index=True)
    parameters = pd.concat(parameter_parts, ignore_index=True)
    metrics = compute_metrics(predictions)
    reliability = reliability_table(predictions, config)
    events = event_table(predictions, feature_frame, config)
    bootstrap = year_block_bootstrap(predictions, config)
    sensitivity = imputation_sensitivity(config)

    _write_csv(predictions, config.output_dir / "real_data_comparison_predictions.csv")
    _write_csv(parameters, config.output_dir / "real_data_model_parameters.csv")
    _write_csv(metrics, config.output_dir / "real_data_comparison_metrics.csv")
    _write_csv(reliability, config.output_dir / "real_data_reliability.csv")
    _write_csv(events, config.output_dir / "real_data_comparison_events.csv")
    _write_csv(bootstrap, config.output_dir / "real_data_bootstrap.csv")
    _write_csv(sensitivity, config.output_dir / "real_data_imputation_sensitivity.csv")
    metadata = _metadata(config, "full_comparison", queue_diagnostics)
    (config.output_dir / "real_data_run_metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    report = write_results_report(
        metrics, events, source_audit, target_audit, bootstrap, sensitivity, config
    )
    return {
        "daily": daily_frame,
        "monthly": feature_frame,
        "predictions": predictions,
        "metrics": metrics,
        "reliability": reliability,
        "events": events,
        "bootstrap": bootstrap,
        "sensitivity": sensitivity,
        "report": report,
        "metadata": metadata,
    }


def main() -> dict[str, object]:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--camels-root", type=Path, default=DEFAULT_CAMELS_ROOT)
    parser.add_argument("--die-root", type=Path, default=DEFAULT_DIE_ROOT)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--audit-only", action="store_true")
    args = parser.parse_args()
    config = ComparisonConfig(
        camels_root=args.camels_root,
        die_root=args.die_root,
        output_dir=args.output_dir,
    )
    if args.audit_only:
        result = run_audit(config)
        print(f"Wrote preprocessing audits to {config.output_dir}")
        return result
    result = run_pipeline(config)
    primary = result["metrics"].loc[
        result["metrics"]["target"].eq("sma")
        & result["metrics"]["q_star"].eq(6)
        & result["metrics"]["model"].eq("ssi3_plus_queue")
    ]
    print(_decision_text(primary))
    print(f"Wrote results to {result['report']}")
    return result


if __name__ == "__main__":
    main()
