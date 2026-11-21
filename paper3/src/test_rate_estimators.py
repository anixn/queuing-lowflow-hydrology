"""Acceptance tests for the P3 rate estimators and evaluation protocol."""

import sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "paper1" / "src"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from rate_estimators import (  # noqa: E402
    isotonic_regression, RateEstimator, calibrate_seasonal_mass,
    predict_with_interval,
)
from evaluate_estimators import make_data, run_queue  # noqa: E402


def test_isotonic_regression_monotone():
    y = np.array([3.0, 1.0, 2.0, 0.0, 4.0])
    out = isotonic_regression(y)
    assert np.all(np.diff(out) >= -1e-12)
    assert abs(out.mean() - y.mean()) < 1e-10   # pooling preserves the mean


def test_predictions_positive():
    rng = np.random.default_rng(0)
    X = rng.normal(size=(200, 3))
    y = np.exp(0.2 + X @ np.array([0.4, -0.3, 0.1]) + rng.normal(0, 0.1, 200))
    p = RateEstimator().fit(X, y).predict(X)
    assert np.all(p > 0)


def test_monotone_in_flow_ceteris_paribus():
    rng = np.random.default_rng(1)
    n = 300
    flow = np.linspace(0.5, 1.5, n)
    rain = rng.normal(size=n)
    X = np.column_stack([np.sin(flow), rain, flow])
    y = np.exp(0.5 * flow + 0.2 * rain)
    model = RateEstimator(monotone_col=2, n_estimators=30).fit(X, y)

    base = X[0].copy()
    X_cf = np.tile(base, (100, 1))
    X_cf[:, 2] = np.linspace(flow.min(), flow.max(), 100)
    pred = model.predict(X_cf)
    assert np.all(np.diff(pred) >= -1e-9)


def test_mass_calibration_exact():
    pred = np.array([1.0, 2.0, 3.0, 4.0])
    out = calibrate_seasonal_mass(pred, 100.0)
    assert abs(out.sum() - 100.0) < 1e-10
    assert np.allclose(out / pred, 10.0)   # target_total / pred.sum() = 100/10


def test_bootstrap_interval_ordering():
    rng = np.random.default_rng(2)
    X = rng.normal(size=(150, 2))
    y = np.exp(0.5 + X @ np.array([0.3, -0.2]) + rng.normal(0, 0.1, 150))
    point, lo, hi = predict_with_interval(X, y, X, RateEstimator(n_estimators=20),
                                          n_boot=5, seed=3)
    assert len(point) == len(lo) == len(hi) == len(X)
    assert np.all(lo <= hi)


def test_constant_baseline_understates_peak_risk():
    """Stationary-at-mean must miss the seasonal amplification (P1 Box 1)."""
    d = make_data(trend=0.0)
    const_l = np.full(365, d["lam_obs"][:730].mean())
    const_m = np.full(365, d["mu_obs"][:730].mean())
    oracle = run_queue(d["lam_true"][730:], d["mu_true"][730:],
                       d["t"][730:] - d["t"][730])
    const = run_queue(const_l, const_m, d["t"][730:] - d["t"][730])
    assert const["E_Q_peak"] < 0.7 * oracle["E_Q_peak"]
    assert const["P_crit_peak"] < 0.3 * oracle["P_crit_peak"]


def test_warming_climatology_understates_critical_risk():
    d = make_data(trend=0.06)
    train_doy = d["phase"][:730].astype(int)
    test_doy = d["phase"][730:].astype(int)
    clim_l = np.array([d["lam_obs"][:730][train_doy == k].mean() for k in test_doy])
    clim_m = np.array([d["mu_obs"][:730][train_doy == k].mean() for k in test_doy])
    oracle = run_queue(d["lam_true"][730:], d["mu_true"][730:],
                       d["t"][730:] - d["t"][730])
    clim = run_queue(clim_l, clim_m, d["t"][730:] - d["t"][730])
    assert clim["P_crit_peak"] < oracle["P_crit_peak"]


def _run_all():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
        print("PASS ", t.__name__)
    print(f"\n{len(tests)} tests passed.")


if __name__ == "__main__":
    _run_all()
