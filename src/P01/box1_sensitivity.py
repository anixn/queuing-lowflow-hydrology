"""Reproducible sensitivity grid for P01 Box 1.

All outputs are synthetic and illustrative, under the stated assumptions.
The script compares a stationary queue with a seasonal queue at identical mean
arrival and service rates. It varies one parameter at a time and then uses a
small combined amplitude/phase grid. No observational data are used. The
default 0.25-day RK4 step is required for stability at the generator rates used
here; larger steps can silently corrupt the probability vector.

Run from the repository root:
    python src/P01/box1_sensitivity.py
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from shared.queue_core import QueueConfig, indicators, solve_transient  # noqa: E402

__all__ = ["SensitivityCase", "run_case", "run_sensitivity", "write_csv"]


@dataclass(frozen=True)
class SensitivityCase:
    """One synthetic Box 1 comparison."""

    case_id: str
    experiment: str
    lam_amp: float = 0.35
    mu_amp: float = 0.28
    phase_lag_days: float = 75.0
    K_q: int = 20
    q_star: int = 6
    theta: int = 8
    alpha: float = 1.5
    eta: float = 0.02


def run_case(case: SensitivityCase, dt: float = 0.25) -> dict[str, float | int | str]:
    """Run one stationary/seasonal pair and return script-backed metrics."""
    if not 0.0 < dt <= 0.25:
        raise ValueError("dt must be in (0, 0.25] days for this sensitivity grid")
    cfg = QueueConfig(K=case.K_q, c=2, theta=case.theta,
                      alpha=case.alpha, eta=case.eta)
    lam_mean, mu_mean = 0.8, 1.0
    period = 365.0
    horizon = 3.0 * period

    def lam_stat(_t):
        return lam_mean

    def mu_stat(_t):
        return mu_mean

    def lam_seasonal(t):
        return lam_mean + case.lam_amp * np.sin(2.0 * np.pi * t / period)

    def mu_seasonal(t):
        return mu_mean - case.mu_amp * np.sin(
            2.0 * np.pi * (t - case.phase_lag_days) / period)

    times_s, p_s = solve_transient(lam_stat, mu_stat, cfg, horizon, dt)
    times_n, p_n = solve_transient(lam_seasonal, mu_seasonal, cfg, horizon, dt)
    cut_s = int(np.searchsorted(times_s, period))
    cut_n = int(np.searchsorted(times_n, period))
    stat = indicators(times_s[cut_s:], p_s[cut_s:], lam_stat, mu_stat, cfg,
                      q_star=case.q_star)
    nonstat = indicators(times_n[cut_n:], p_n[cut_n:], lam_seasonal,
                         mu_seasonal, cfg, q_star=case.q_star)

    row: dict[str, float | int | str] = {
        "case_id": case.case_id,
        "experiment": case.experiment,
        "lam_amp_claims_per_day": case.lam_amp,
        "mu_amp_claims_per_day": case.mu_amp,
        "phase_lag_days": case.phase_lag_days,
        "K_q_claims": case.K_q,
        "q_star_claims": case.q_star,
        "theta_claims": case.theta,
        "alpha": case.alpha,
        "eta_per_claim_day": case.eta,
        "stationary_peak_E_Q_claims": stat["E_Q_peak"],
        "seasonal_peak_E_Q_claims": nonstat["E_Q_peak"],
        "peak_E_Q_ratio": nonstat["E_Q_peak"] / stat["E_Q_peak"],
        "stationary_peak_P_crit": stat["P_crit_peak"],
        "seasonal_peak_P_crit": nonstat["P_crit_peak"],
        "peak_P_crit_ratio": nonstat["P_crit_peak"] / stat["P_crit_peak"],
        "stationary_abandoned_claims": stat["abandoned_demand_claims"],
        "seasonal_abandoned_claims": nonstat["abandoned_demand_claims"],
        "abandoned_ratio": (nonstat["abandoned_demand_claims"] /
                            stat["abandoned_demand_claims"]),
        "stationary_backlog_exposure_claim_days": stat["backlog_exposure_claim_days"],
        "seasonal_backlog_exposure_claim_days": nonstat["backlog_exposure_claim_days"],
        "seasonal_ledger_residual_claims": nonstat["ledger_residual_claims"],
        "provenance": "synthetic_illustrative_under_stated_assumptions",
    }
    return row


def run_sensitivity(dt: float = 0.25) -> list[dict[str, float | int | str]]:
    """Run one-at-a-time and combined synthetic sensitivity cases."""
    base = SensitivityCase(case_id="baseline", experiment="baseline")
    cases = [base]

    one_at_a_time = {
        "lam_amp": [0.20, 0.50],
        "mu_amp": [0.15, 0.40],
        "phase_lag_days": [0.0, 150.0],
        "K_q": [10, 30],
        "q_star": [4, 8],
        "theta": [4, 12],
        "alpha": [1.0, 2.0],
        "eta": [0.0, 0.05],
    }
    for field, values in one_at_a_time.items():
        for value in values:
            kwargs = {field: value}
            cases.append(SensitivityCase(
                case_id=f"oat_{field}_{value}",
                experiment="one_at_a_time",
                **kwargs,
            ))

    for lam_amp in (0.20, 0.35, 0.50):
        for mu_amp in (0.15, 0.28, 0.40):
            for lag in (0.0, 75.0, 150.0):
                cases.append(SensitivityCase(
                    case_id=f"grid_l{lam_amp}_m{mu_amp}_p{lag}",
                    experiment="combined_amplitude_phase",
                    lam_amp=lam_amp,
                    mu_amp=mu_amp,
                    phase_lag_days=lag,
                ))

    return [run_case(case, dt=dt) for case in cases]


def write_csv(rows: list[dict[str, float | int | str]], path: str | Path) -> None:
    """Write generated sensitivity results with provenance."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        default="analysis/novelty_2026-11-25/data/box1_sensitivity.csv",
        help="Output CSV path (default: %(default)s)",
    )
    parser.add_argument("--dt", type=float, default=0.25,
                        help="RK4 step in days (default: %(default)s)")
    args = parser.parse_args()
    rows = run_sensitivity(dt=args.dt)
    write_csv(rows, args.output)
    baseline = rows[0]
    ratios = [float(row["peak_E_Q_ratio"]) for row in rows]
    print(f"Wrote {len(rows)} synthetic cases to {args.output}")
    print(f"Baseline peak E[Q] ratio: {baseline['peak_E_Q_ratio']:.3f}")
    print(f"Peak E[Q] ratio range: {min(ratios):.3f} to {max(ratios):.3f}")
    print("All outputs are illustrative, under the stated assumptions.")


if __name__ == "__main__":
    main()
