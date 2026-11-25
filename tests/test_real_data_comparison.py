"""Acceptance tests for the predeclared real-data comparison pipeline."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile

import numpy as np
import pandas as pd
from scipy.linalg import expm

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from P02.real_data_comparison import (  # noqa: E402
    ComparisonConfig,
    GaugeSpec,
    _event_runs,
    aggregate_monthly,
    binary_metrics,
    compute_metrics,
    compute_ssi3,
    daily_queue_probabilities,
    demand_rates,
    fit_predict_models,
    interpolate_flagged,
    load_district_targets,
    reliability_table,
    supply_rates,
    year_block_bootstrap,
)
from shared.queue_core import generator, stationary  # noqa: E402


def test_demand_formula_matches_r_golden_values():
    cfg = ComparisonConfig()
    dates = pd.DatetimeIndex(["2001-07-19", "2001-09-17", "2001-11-16",
                              "2001-11-17"])
    rainfall = np.array([0.0, 1.0, 0.0, 0.0])
    pet = np.full(4, 5.0)
    actual = demand_rates(dates, rainfall, pet, cfg)
    # DOY 200: Kc=.4; DOY 260: Kc=1.2; DOY 320: Kc=.4; DOY 321: Kc=.35.
    expected = np.array([0.1, 0.265, 0.1, 0.0875])
    np.testing.assert_allclose(actual, expected, atol=1e-14)


def test_supply_units_and_cap():
    cfg = ComparisonConfig()
    actual = supply_rates(np.array([0.0, 100.0, 625.0, 1000.0]), 45_000.0, cfg)
    np.testing.assert_allclose(actual, [0.0, 0.48, 3.0, 3.0], atol=1e-14)


def test_linear_and_forward_fill_are_flagged():
    index = pd.date_range("2001-01-01", periods=5, freq="D")
    series = pd.Series([1.0, np.nan, np.nan, 4.0, 5.0], index=index)
    linear, flag = interpolate_flagged(series, "linear")
    np.testing.assert_allclose(linear, [1.0, 2.0, 3.0, 4.0, 5.0])
    assert flag.tolist() == [False, True, True, False, False]
    forward, flag = interpolate_flagged(series, "forward")
    np.testing.assert_allclose(forward, [1.0, 1.0, 1.0, 4.0, 5.0])
    assert flag.tolist() == [False, True, True, False, False]


def test_long_gap_is_not_interpolated():
    series = pd.Series(
        [1.0] + [np.nan] * 8 + [2.0],
        index=pd.date_range("2001-01-01", periods=10, freq="D"),
    )
    try:
        interpolate_flagged(series, "linear", max_gap_days=7)
    except ValueError:
        pass
    else:
        raise AssertionError("an eight-day gap should not be interpolated")


def test_leading_missing_value_is_not_extrapolated():
    series = pd.Series([np.nan, 1.0, 2.0],
                       index=pd.date_range("2001-01-01", periods=3, freq="D"))
    try:
        interpolate_flagged(series, "forward")
    except ValueError:
        pass
    else:
        raise AssertionError("leading gap should not be extrapolated")


def test_daily_queue_matches_independent_matrix_exponential():
    cfg = ComparisonConfig(max_queue_step_days=0.1)
    lam = np.array([0.8, 0.2, 1.1, 0.4, 0.7])
    mu = np.array([0.5, 0.1, 0.8, 0.3, 0.6])
    probabilities, diagnostics = daily_queue_probabilities(lam, mu, cfg)
    p = np.zeros(21)
    p[0] = 1.0
    for day, (arrival, service) in enumerate(zip(lam, mu, strict=True)):
        p = p @ expm(generator(float(arrival), float(service), cfg.queue_config))
        np.testing.assert_allclose(probabilities[day], p, atol=2e-6)
    np.testing.assert_allclose(probabilities.sum(axis=1), 1.0, atol=1e-12)
    assert diagnostics["step_days"] <= 0.1
    assert diagnostics["max_abs_probability_sum_error"] < 1e-12


def test_daily_queue_converges_to_exact_stationary():
    cfg = ComparisonConfig(max_queue_step_days=0.1)
    probabilities, _ = daily_queue_probabilities(
        np.full(250, 0.8), np.full(250, 1.0), cfg
    )
    np.testing.assert_allclose(
        probabilities[-1], stationary(0.8, 1.0, cfg.queue_config), atol=2e-6
    )


def test_queue_prefix_is_causal():
    cfg = ComparisonConfig(max_queue_step_days=0.1)
    lam = np.linspace(0.1, 1.0, 12)
    mu = np.linspace(0.8, 0.2, 12)
    full, _ = daily_queue_probabilities(lam, mu, cfg)
    prefix, _ = daily_queue_probabilities(lam[:7], mu[:7], cfg)
    np.testing.assert_allclose(prefix, full[:7], atol=0.0)


def test_monthly_aggregation_and_imputation_counts():
    index = pd.date_range("2001-01-01", "2001-02-28", freq="D")
    daily = pd.DataFrame({
        "gauge_id": 1,
        "q_m3s": np.linspace(1.0, 2.0, len(index)),
        "q_zero_day": False,
        "q_imputed": index.day == 1,
        "lambda_claims_day": 0.2,
        "mu_claims_day": 0.1,
        "E_Q_claims": np.linspace(0.0, 1.0, len(index)),
        "p_ge_6": np.linspace(0.0, 0.2, len(index)),
    }, index=index)
    monthly = aggregate_monthly(daily)
    assert monthly.loc["2001-01", "days"] == 31
    assert monthly.loc["2001-01", "q_imputed_days"] == 1
    assert monthly.loc["2001-02", "days"] == 28
    assert np.isclose(monthly.loc["2001-01", "p_ge_6"],
                      daily.loc["2001-01", "p_ge_6"].mean())


def test_district_target_loader_preserves_missing_values():
    spec = GaugeSpec(4026, "maharashtra-sangli", "Sangli", 45_000.0)
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        (root / "drought").mkdir()
        for filename, values in (
            ("spi_03.csv", [-0.5, np.nan]),
            ("spei_03.csv", [-0.7, -1.2]),
            ("soil_moisture.csv", [-20.0, -5.0]),
        ):
            pd.DataFrame({
                "district_id": [spec.district_id],
                "district_name": [spec.district_name],
                "state_name": ["Maharashtra"],
                "1981-01": [values[0]],
                "1981-02": [values[1]],
            }).to_csv(root / "drought" / filename, index=False)
        cfg = ComparisonConfig(
            die_root=root, train_years=(1981,), test_years=(1982,), end_year=1982
        )
        targets = load_district_targets(spec, cfg)
        assert targets.loc["1981-01", "y_sma"] == 1
        assert targets.loc["1981-02", "y_sma"] == 0
        assert pd.isna(targets.loc["1981-02", "spi3"])


def test_ssi_standardization_uses_training_only():
    cfg = ComparisonConfig(
        train_years=(1981, 1982), test_years=(1983, 1984), end_year=1984
    )
    periods = pd.period_range("1980-01", "1984-12", freq="M")
    month = np.arange(len(periods))
    flow = pd.DataFrame({
        "q_m3s_mean": 10.0 + np.sin(month / 3.0) + 0.05 * month
    }, index=periods)
    first = compute_ssi3(flow, cfg)
    changed = flow.copy()
    changed.loc[changed.index.year >= 1983, "q_m3s_mean"] *= 100.0
    second = compute_ssi3(changed, cfg)
    train_mask = first.index.year.isin(cfg.train_years)
    np.testing.assert_allclose(
        first.loc[train_mask, "ssi3"], second.loc[train_mask, "ssi3"], atol=1e-12
    )
    assert not np.allclose(first["ssi3"], second["ssi3"])


def _synthetic_features() -> tuple[pd.DataFrame, ComparisonConfig]:
    cfg = ComparisonConfig(
        train_years=(1981, 1982), test_years=(1983, 1984), end_year=1984
    )
    periods = pd.period_range("1981-01", "1984-12", freq="M")
    frame = pd.DataFrame(index=periods)
    frame["year"] = frame.index.year
    frame["month"] = frame.index.month
    frame["date"] = frame.index.to_timestamp()
    frame["split"] = np.where(frame["year"].isin(cfg.train_years), "train", "test")
    wave = np.sin(2.0 * np.pi * frame["month"] / 12.0)
    frame["spi3"] = wave + 0.1 * frame["year"]
    frame["spei3"] = wave - 0.2 * frame["year"]
    frame["ssi3"] = -wave + 0.05 * frame["year"]
    frame["p_ge_4"] = 0.1 + 0.03 * frame["month"]
    frame["p_ge_6"] = 0.05 + 0.02 * frame["month"]
    frame["p_ge_8"] = 0.02 + 0.01 * frame["month"]
    frame["sma_pct"] = -20.0 * ((frame["year"] + frame["month"]) % 3 == 0)
    frame["y_sma"] = (frame["sma_pct"] <= -15.0).astype(int)
    return frame, cfg


def test_logistic_models_do_not_learn_from_test_targets():
    frame, cfg = _synthetic_features()
    spec = GaugeSpec(4026, "maharashtra-sangli", "Sangli", 45_000.0)
    first, first_parameters = fit_predict_models(frame, spec, "sma", 6, cfg)
    changed = frame.copy()
    test = changed["split"].eq("test")
    changed.loc[test, "y_sma"] = 1 - changed.loc[test, "y_sma"]
    second, second_parameters = fit_predict_models(changed, spec, "sma", 6, cfg)
    first_test = first.loc[first["split"].eq("test")].sort_values(["model", "date"])
    second_test = second.loc[second["split"].eq("test")].sort_values(["model", "date"])
    np.testing.assert_allclose(
        first_test["predicted_probability"], second_test["predicted_probability"],
        atol=1e-12,
    )
    coefficients = first_parameters["parameter_type"].eq("coefficient")
    np.testing.assert_allclose(
        first_parameters.loc[coefficients, "value"],
        second_parameters.loc[coefficients, "value"],
        atol=1e-12,
    )


def test_binary_metrics_hand_values():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.4, 0.35, 0.8])
    metrics = binary_metrics(y, p)
    assert np.isclose(metrics["brier"], 0.158125)
    assert np.isclose(metrics["auc"], 0.75)
    expected_log_loss = -np.mean(
        y * np.log(p) + (1 - y) * np.log(1 - p)
    )
    assert np.isclose(metrics["log_loss"], expected_log_loss)


def test_decision_rule_uses_brier_not_auc():
    rows = []
    probabilities = {
        "climatology": 0.2,
        "spi3": 0.2,
        "spei3": 0.2,
        "ssi3": 0.2,
        "queue": 0.15,
        "ssi3_plus_queue": 0.1,
    }
    for model, probability in probabilities.items():
        for date in pd.date_range("2011-01-01", periods=4, freq="MS"):
            rows.append({
                "gauge_id": 4026, "target": "sma", "q_star": 6, "model": model,
                "date": date, "year": date.year, "month": date.month,
                "split": "test", "y": 0, "predicted_probability": probability,
            })
    metrics = compute_metrics(pd.DataFrame(rows))
    combined = metrics.loc[metrics["model"].eq("ssi3_plus_queue")].iloc[0]
    assert bool(combined["queue_adds_information"])
    assert np.isnan(combined["auc"])


def test_year_block_bootstrap_uses_available_years_and_is_deterministic():
    rows = []
    for gauge_id, last_date in ((4026, "2020-12-01"), (4064, "2019-11-01")):
        dates = pd.date_range("2011-01-01", last_date, freq="MS")
        for model, offset in (("ssi3", 0.0), ("ssi3_plus_queue", -0.05)):
            for position, date in enumerate(dates):
                rows.append({
                    "gauge_id": gauge_id, "target": "sma", "q_star": 6,
                    "model": model, "date": date, "year": date.year,
                    "month": date.month, "split": "test",
                    "y": int(position % 4 == 0),
                    "predicted_probability": 0.3 + offset,
                })
    predictions = pd.DataFrame(rows)
    gauge_rows = predictions.loc[predictions["gauge_id"].eq(4026)]
    wide = gauge_rows.pivot(index="date", columns="model",
                            values="predicted_probability")
    y = gauge_rows.loc[gauge_rows["model"].eq("ssi3")].set_index("date")["y"]
    # The point estimate must weight months, not give a partial year equal weight.
    expected_delta = float((((wide["ssi3_plus_queue"] - y) ** 2
                             - (wide["ssi3"] - y) ** 2).mean()))
    first = year_block_bootstrap(predictions, ComparisonConfig())
    second = year_block_bootstrap(predictions, ComparisonConfig())
    pd.testing.assert_frame_equal(first, second)
    assert np.isclose(first["delta"].iloc[0], expected_delta)
    assert first.set_index("gauge_id").loc[4026, "n_test_years"] == 10
    assert first.set_index("gauge_id").loc[4064, "n_test_years"] == 9
    assert (first["ci_lower"] <= first["ci_upper"]).all()


def test_event_runs_and_censoring():
    frame = pd.DataFrame({
        "date": pd.date_range("2011-01-01", periods=5, freq="MS"),
        "y": [0, 1, 1, 0, 1],
        "target_value": [-5.0, -20.0, -10.0, -5.0, -16.0],
    })
    events = _event_runs(frame)
    assert len(events) == 2
    assert events[0]["duration_months"] == 2
    assert np.isclose(events[0]["severity"], 30.0)
    assert events[1]["right_censored"]

    boundary = pd.DataFrame({
        "date": pd.date_range("2011-01-01", periods=4, freq="MS"),
        "y": [1.0, 1.0, np.nan, 1.0],
        "target_value": [-20.0, -10.0, np.nan, -16.0],
    })
    boundary_events = _event_runs(boundary)
    assert len(boundary_events) == 2
    assert boundary_events[0]["left_censored"]
    assert boundary_events[0]["duration_months"] == 2
    assert not boundary_events[1]["left_censored"]


def test_reliability_bins_are_fixed():
    predictions = pd.DataFrame({
        "gauge_id": [4026] * 3,
        "target": ["sma"] * 3,
        "q_star": [6] * 3,
        "model": ["queue"] * 3,
        "split": ["test"] * 3,
        "predicted_probability": [0.0, 0.5, 1.0],
        "y": [0, 1, 1],
    })
    reliability = reliability_table(predictions, ComparisonConfig())
    assert reliability["bin"].tolist() == [0, 2, 4]
    assert reliability["n"].sum() == 3


if __name__ == "__main__":
    for name, value in sorted(globals().items()):
        if name.startswith("test_") and callable(value):
            value()
            print(f"PASS  {name}")
    print(f"{sum(name.startswith('test_') for name in globals())} tests passed.")
