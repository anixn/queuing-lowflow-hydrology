"""Acceptance tests for the queue core (run: python paper1/src/test_queue_core.py)."""
import numpy as np
import queue_core as q


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


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
        print(f"PASS  {t.__name__}")
    print(f"\n{len(tests)} tests passed.")
