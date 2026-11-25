"""Acceptance tests for the queue core (run: python tests/test_queue_core.py)."""
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from shared import queue_core as q  # noqa: E402


def test_generator_rows_sum_to_zero():
    cfg = q.QueueConfig()
    A = q.generator(0.8, 1.0, cfg)
    assert np.abs(A.sum(axis=1)).max() < 1e-12


def test_rk4_matches_exact_stationary():
    cfg = q.QueueConfig()
    pi = q.stationary(0.8, 1.0, cfg)
    _, P = q.solve_transient(lambda t: 0.8, lambda t: 1.0, cfg, T=800.0, dt=0.05)
    assert np.abs(P[-1] - pi).sum() < 1e-3


def test_des_matches_exact_within_two_percent():
    cfg = q.QueueConfig()
    exact = float(q.stationary(0.8, 1.0, cfg) @ np.arange(cfg.K + 1))
    states, clocks = q.simulate_des(lambda t: 0.8, lambda t: 1.0, cfg,
                                    T=100000.0, seed=11)
    des = q.des_time_average(states, clocks, 100000.0)
    assert abs(des - exact) / exact < 0.02


def test_nonstationary_increases_peak_backlog():
    cfg = q.QueueConfig()
    T = 365.0 * 3
    _, Ps = q.solve_transient(lambda t: 0.8, lambda t: 1.0, cfg, T, 0.25)
    _, Pn = q.solve_transient(
        lambda t: 0.8 + 0.35 * np.sin(2 * np.pi * t / 365.0),
        lambda t: 1.0 - 0.28 * np.sin(2 * np.pi * (t - 75.0) / 365.0),
        cfg, T, 0.25)
    n = np.arange(cfg.K + 1)
    assert (Pn @ n).max() > 1.8 * (Ps @ n).max()


def test_probabilities_normalised():
    cfg = q.QueueConfig()
    _, P = q.solve_transient(
        lambda t: 0.8 + 0.35 * np.sin(2 * np.pi * t / 365.0),
        lambda t: 1.0 - 0.28 * np.sin(2 * np.pi * (t - 75.0) / 365.0),
        cfg, 365.0, 0.5)
    assert np.allclose(P.sum(axis=1), 1.0)


def test_blocked_demand_is_counted():
    cfg = q.QueueConfig(K=2, c=1, theta=99, eta=0.0)
    times, P = q.solve_transient(
        lambda t: 5.0, lambda t: 0.1, cfg, T=2.0, dt=0.01,
        p0=np.array([0.0, 0.0, 1.0]))
    out = q.indicators(times, P, lambda t: 5.0, lambda t: 0.1, cfg)
    assert out["blocked_demand_claims"] > 9.0
    assert out["abandoned_demand_claims"] >= out["blocked_demand_claims"]


def test_demand_conservation_ledger_closes():
    cfg = q.QueueConfig(K=5, c=2, theta=3, alpha=1.3, eta=0.02)
    lam_fn = lambda t: 0.8 + 0.3 * np.sin(2 * np.pi * t / 30.0)
    mu_fn = lambda t: 1.0 - 0.2 * np.cos(2 * np.pi * t / 30.0)
    times, P = q.solve_transient(lam_fn, mu_fn, cfg, T=60.0, dt=0.02)
    out = q.indicators(times, P, lam_fn, mu_fn, cfg)
    scale = max(1.0, out["total_arrivals_claims"])
    assert abs(out["ledger_residual_claims"]) < 1e-4 * scale


def test_backlog_exposure_and_abandoned_demand_are_distinct():
    cfg = q.QueueConfig(K=4, c=1, theta=3, alpha=1.2, eta=0.05)
    lam_fn = lambda t: 1.2
    mu_fn = lambda t: 0.4
    times, P = q.solve_transient(lam_fn, mu_fn, cfg, T=10.0, dt=0.02)
    out = q.indicators(times, P, lam_fn, mu_fn, cfg)
    assert out["backlog_exposure_claim_days"] > 0.0
    assert out["abandoned_demand_claims"] > 0.0
    assert not np.isclose(out["backlog_exposure_claim_days"],
                          out["abandoned_demand_claims"])


def test_box1_sensitivity_baseline_reproduces_anchor():
    from P01.box1_sensitivity import SensitivityCase, run_case
    row = run_case(SensitivityCase(case_id="test", experiment="test"), dt=0.25)
    assert abs(row["peak_E_Q_ratio"] - 2.3) < 0.05
    assert abs(row["seasonal_ledger_residual_claims"]) < 1e-4
    assert row["provenance"] == "synthetic_illustrative_under_stated_assumptions"
    try:
        run_case(SensitivityCase(case_id="unsafe", experiment="test"), dt=0.5)
    except ValueError:
        pass
    else:
        raise AssertionError("unsafe RK4 step was not rejected")


def test_claim_scale_envelope_is_physically_invariant():
    from P01.claim_scale_envelope import ClaimConvention, physical_forcing, fluid_ledger
    working = ClaimConvention(45_000, 20)
    assert working.claim_volume_m3 == 9_000_000
    assert working.K == 20
    assert working.q_star == 6
    assert abs(working.service_cap_claims_day - 3.0) < 1e-12
    demand, supply = physical_forcing(730, 0.5)
    reference = fluid_ledger(demand, supply)
    for area, depth in ((174_000, 10), (190_000, 40)):
        conv = ClaimConvention(area, depth)
        assert conv.K * conv.depth_mm == 400.0
        assert conv.q_star * conv.depth_mm == 120.0
        assert abs(conv.service_cap_claims_day * conv.depth_mm - 60.0) < 1e-12
        assert fluid_ledger(demand, supply) == reference


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
        print(f"PASS  {t.__name__}")
    print(f"\n{len(tests)} tests passed.")
