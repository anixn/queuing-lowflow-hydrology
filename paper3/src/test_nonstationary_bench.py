"""Acceptance tests for the Paper 3 non-stationary benchmarks."""

import sys
from pathlib import Path
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from nonstationary_bench import (  # noqa: E402
    floquet_steady_state, mmpp_generator, mmpp_stationary,
    mmpp_indicators, compare_burstiness,
)
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "paper1" / "src"))
from queue_core import QueueConfig  # noqa: E402

CFG = QueueConfig(K=20, c=2, theta=8, alpha=1.5, eta=0.02)


def test_generator_rows_sum_to_zero():
    A = mmpp_generator((1.3, 0.5), 1.0, CFG, q01=0.02, q10=0.02)
    assert np.allclose(A.sum(axis=1), 0.0, atol=1e-12)


def test_mmpp_stationary_is_normalised_and_positive():
    A = mmpp_generator((1.3, 0.5), 1.0, CFG, q01=0.02, q10=0.02)
    p = mmpp_stationary(A)
    assert abs(p.sum() - 1.0) < 1e-10
    assert np.all(p >= 0.0)
    marg = mmpp_indicators(A, CFG)["marginal"]
    assert abs(marg.sum() - 1.0) < 1e-10


def test_symmetric_switching_gives_equal_regime_mass():
    A = mmpp_generator((1.3, 0.5), 1.0, CFG, q01=0.02, q10=0.02)
    mass = mmpp_indicators(A, CFG)["regime_mass"]
    assert abs(mass[0] - mass[1]) < 1e-8


def test_floquet_residual_tiny():
    P, mu = 365.0, 1.0
    lam_fn = lambda t: 0.8 + 0.35 * np.sin(2 * np.pi * t / P)
    mu_fn = lambda t: mu - 0.28 * np.sin(2 * np.pi * (t - 75.0) / P)
    f = floquet_steady_state(lam_fn, mu_fn, CFG, P, steps=1000)
    assert f.eig_residual < 1e-8


def test_floquet_reproduces_box1():
    """Independent method must match Paper 1's RK4/DES Box 1 numbers."""
    P = 365.0
    lam_fn = lambda t: 0.8 + 0.35 * np.sin(2 * np.pi * t / P)
    mu_fn = lambda t: 1.0 - 0.28 * np.sin(2 * np.pi * (t - 75.0) / P)
    f = floquet_steady_state(lam_fn, mu_fn, CFG, P, steps=2000)
    s = f.summary(lam_fn, mu_fn, CFG)
    assert abs(s["E_Q_peak"] - 2.130) < 0.01
    assert abs(s["P_crit_peak"] - 0.0733) < 0.005


def test_burstiness_amplifies_backlog():
    r = compare_burstiness(mean_lam=0.9, mu=1.0, cfg=CFG, switch_rate=0.02)
    assert r["lam_high"] > r["mean_lam"] > r["lam_low"]
    assert r["amplification_E_Q"] > 1.0


def _run_all():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
        print("PASS ", t.__name__)
    print(f"\n{len(tests)} tests passed.")


if __name__ == "__main__":
    _run_all()
