"""End-to-end P3 experiment: do estimated rates preserve drought risk?

Compares five rate pairs on a held-out year, feeding each through the P1 queue:

  oracle        - true lambda(t), mu(t) (upper bound, not achievable)
  constant      - stationary rates at the training mean
  climatology   - day-of-year means of the observed rate records
  estimated     - GBDT rate estimators with monotone-mu
  estimated+mass- as above, with lambda rescaled to the observed annual total

Two synthetic scenarios are run:

  periodic      - truth is exactly seasonal; favours climatology (stress test
                  for the estimator, which must fit noise)
  warming       - demand baseline rises and the dry-season service dip shifts
                  later over the three years; climatology must fail

All data are synthetic.  The point is to establish the *evaluation protocol*,
not to report a scientific result.

Run:  python paper3/src/evaluate_estimators.py
"""

from __future__ import annotations

import sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "paper1" / "src"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from queue_core import QueueConfig, solve_transient, indicators  # noqa: E402
from data_pipeline import rate_interpolator  # noqa: E402
from rate_estimators import (  # noqa: E402
    RateEstimator, calibrate_seasonal_mass,
)

CFG = QueueConfig(K=20, c=2, theta=8, alpha=1.5, eta=0.02)
DAYS = 365 * 3


def make_data(seed: int = 11, trend: float = 0.0) -> dict:
    """Three years of synthetic rates, noisy covariates and noisy observations."""
    rng = np.random.default_rng(seed)
    t = np.arange(float(DAYS))
    phase = t % 365.0
    years = t / 365.0

    lam_true = (0.8 + trend * (years - 1.5)
                + 0.35 * np.sin(2 * np.pi * phase / 365.0))
    shift = 12.0 * trend / 0.06
    mu_true = 1.0 - 0.28 * np.sin(2 * np.pi * (phase - 75.0 - shift) / 365.0)
    lam_true = np.maximum(lam_true, 0.1)
    mu_true = np.maximum(mu_true, 0.2)

    temp = 0.9 * np.sin(2 * np.pi * phase / 365.0) + rng.normal(0, 0.25, DAYS)
    rain = -0.9 * np.sin(2 * np.pi * (phase - 75.0 - shift) / 365.0) + rng.normal(0, 0.25, DAYS)
    flow = 1.0 + 0.7 * (mu_true - 1.0) + rng.normal(0, 0.12, DAYS)

    lam_obs = lam_true * np.exp(rng.normal(0, 0.10, DAYS))
    mu_obs = mu_true * np.exp(rng.normal(0, 0.08, DAYS))

    harm1 = np.sin(2 * np.pi * phase / 365.0)
    harm2 = np.cos(2 * np.pi * phase / 365.0)
    X_lam = np.column_stack([harm1, harm2, temp, rain, years])
    X_mu = np.column_stack([harm1, harm2, rain, flow, years])
    return dict(t=t, phase=phase, years=years, lam_true=lam_true,
                mu_true=mu_true, lam_obs=lam_obs, mu_obs=mu_obs,
                X_lam=X_lam, X_mu=X_mu)


def clim_by_doy(doy_train: np.ndarray, vals: np.ndarray,
                doy_test: np.ndarray) -> np.ndarray:
    """Day-of-year mean benchmark, indexed directly for the test year."""
    out = np.empty(len(doy_test), float)
    for d in np.unique(doy_test):
        m = doy_train == d
        out[doy_test == d] = vals[m].mean() if m.any() else np.nan
    return out


def run_queue(lam_v: np.ndarray, mu_v: np.ndarray, t: np.ndarray) -> dict:
    """Solve the queue on the held-out year using interpolated daily rates."""
    lam = rate_interpolator(t, lam_v)
    mu = rate_interpolator(t, mu_v)
    times, P = solve_transient(lam, mu, CFG, T=float(t[-1] - t[0]), dt=0.2)
    return indicators(times, P, lam, mu, CFG)


def run_scenario(name: str, trend: float) -> dict:
    d = make_data(trend=trend)
    train = np.arange(2 * 365)
    test = np.arange(2 * 365, DAYS)
    t_test = d["t"][test] - d["t"][test[0]]

    lam_model = RateEstimator().fit(d["X_lam"][train], d["lam_obs"][train])
    mu_model = RateEstimator(monotone_col=3).fit(d["X_mu"][train], d["mu_obs"][train])
    lam_est = lam_model.predict(d["X_lam"][test])
    mu_est = mu_model.predict(d["X_mu"][test])
    lam_est_cal = calibrate_seasonal_mass(lam_est, d["lam_obs"][test].sum())

    cases = {
        "oracle": (d["lam_true"][test], d["mu_true"][test]),
        "constant": (np.full(len(test), d["lam_obs"][train].mean()),
                     np.full(len(test), d["mu_obs"][train].mean())),
        "climatology": (clim_by_doy(d["phase"][train].astype(int),
                                    d["lam_obs"][train], d["phase"][test].astype(int)),
                        clim_by_doy(d["phase"][train].astype(int),
                                    d["mu_obs"][train], d["phase"][test].astype(int))),
        "estimated": (lam_est, mu_est),
        "estimated+mass": (lam_est_cal, mu_est),
    }

    print(f"\n=== Scenario: {name} (trend={trend}) ===")
    print(f"{'case':<16}{'lamRMSE':>9}{'muRMSE':>9}{'E[Q]pk':>9}{'Pcrit pk':>10}{'U':>9}")
    results = {}
    for case, (lv, mv) in cases.items():
        r = run_queue(lv, mv, t_test)
        results[case] = r
        lr = np.sqrt(np.mean((lv - d["lam_true"][test]) ** 2))
        mr = np.sqrt(np.mean((mv - d["mu_true"][test]) ** 2))
        print(f"{case:<16}{lr:>9.4f}{mr:>9.4f}{r['E_Q_peak']:>9.3f}"
              f"{r['P_crit_peak']:>10.4f}{r['unmet_demand_U']:>9.2f}")

    base = results["oracle"]
    print("Relative to oracle (1.00 = perfect recovery):")
    for case in ("constant", "climatology", "estimated", "estimated+mass"):
        r = results[case]
        print(f"  {case:<16} E[Q]pk {r['E_Q_peak']/base['E_Q_peak']:.2f}x  "
              f"Pcrit {r['P_crit_peak']/max(base['P_crit_peak'],1e-9):.2f}x  "
              f"U {r['unmet_demand_U']/base['unmet_demand_U']:.2f}x")
    return results


def main() -> None:
    print("P3 RATE-ESTIMATOR EVALUATION (synthetic held-out year)")
    periodic = run_scenario("periodic", trend=0.0)
    warming = run_scenario("warming", trend=0.06)
    print("\nINTERPRETATION")
    print("  In the periodic case, climatology is hard to beat because the truth")
    print("  is exactly seasonal; estimator rate RMSE is far lower but mu errors")
    print("  near rho~1 still amplify risk. In the warming case, check whether")
    print("  climatology's fixed seasonality understates the trend while the")
    print("  estimators, which include a year index, track it.")
    return {"periodic": periodic, "warming": warming}


if __name__ == "__main__":
    main()
