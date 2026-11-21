"""Exact benchmarks for non-stationary drought queues (Paper 3 methods core).

Two reference systems that an ML rate estimator must be tested against:

1. **Floquet / periodic steady state.** For periodic rates lam(t+P)=lam(t),
   mu(t+P)=mu(t), solve dPhi/dt = Phi A(t) over one period.  The periodic
   steady-state distribution is the left eigenvector of the monodromy matrix
   Phi(P) at eigenvalue 1.  This gives an exact target for the time-varying
   solution without relying on a long transient burn-in.

2. **Markov-modulated arrivals (MMPP/2).** Demand arrives in "high" and "low"
   environmental regimes with different rates; regime switching is itself a
   CTMC.  The joint process (backlog, regime) is a finite CTMC with a solvable
   stationary distribution.  This tests whether clustered arrivals at the same
   mean rate amplify drought backlog -- a question the M/M/1 benchmark in Paper 1
   cannot answer.

NumPy only.  Units: days, claims, claims/day.

Run:  python paper3/src/nonstationary_bench.py
"""

from __future__ import annotations

from dataclasses import dataclass
import numpy as np
import sys
from pathlib import Path

# Make the Paper 1 core importable when running this file directly.
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "paper1" / "src"))
from queue_core import (  # noqa: E402
    QueueConfig, birth_rates, death_rates, generator, stationary, indicators,
)

__all__ = [
    "FloquetResult",
    "floquet_steady_state",
    "mmpp_generator",
    "mmpp_stationary",
    "mmpp_indicators",
    "compare_burstiness",
    "run_demos",
]


# --------------------------------------------------------------------------
# 1. Periodic (Floquet) benchmark
# --------------------------------------------------------------------------
@dataclass
class FloquetResult:
    period: float
    times: np.ndarray
    transition: np.ndarray          # Phi(t) at each stored time
    p_periodic: np.ndarray          # p* at t=0 (left eigenvector, eigenvalue 1)
    P_periodic: np.ndarray          # distribution over one period
    eig_residual: float             # |p* Phi(P) - p*|_1

    def summary(self, lam_fn, mu_fn, cfg: QueueConfig, q_star: int = 6) -> dict:
        return indicators(self.times, self.P_periodic, lam_fn, mu_fn, cfg,
                          q_star=q_star)


def floquet_steady_state(lam_fn, mu_fn, cfg: QueueConfig, period: float,
                         steps: int = 2000) -> FloquetResult:
    """Integrate Phi over one period and extract the periodic steady state.

    Phi solves dPhi/dt = Phi A(t), Phi(0)=I.  Its value at t=P is the
    monodromy matrix M.  p* satisfies p* M = p*, found as the left eigenvector
    of M at the eigenvalue nearest 1.
    """
    if period <= 0 or steps < 2:
        raise ValueError("period must be positive and steps >= 2")
    # RK4 stability: the generator's largest |eigenvalue| can reach ~8.5/day
    # here, so dt must stay below ~0.28 day.  Cap at 0.1 day regardless of the
    # requested output resolution.
    max_dt = 0.1
    eff_steps = max(steps, int(np.ceil(period / max_dt)))
    dt = period / eff_steps
    n = cfg.K + 1
    Phi = np.eye(n, dtype=float)
    store_times = np.linspace(0.0, period, eff_steps + 1)
    transitions = np.empty((eff_steps + 1, n, n), dtype=float)
    transitions[0] = Phi

    for k in range(eff_steps):
        t = store_times[k]

        def A(s):
            return generator(lam_fn(s), mu_fn(s), cfg)

        k1 = Phi @ A(t)
        k2 = (Phi + 0.5 * dt * k1) @ A(t + 0.5 * dt)
        k3 = (Phi + 0.5 * dt * k2) @ A(t + 0.5 * dt)
        k4 = (Phi + dt * k3) @ A(t + dt)
        Phi = Phi + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
        transitions[k + 1] = Phi

    M = transitions[-1]
    vals, vecs = np.linalg.eig(M.T)              # right eigenvectors of M.T
    idx = int(np.argmin(np.abs(vals - 1.0)))
    p = np.real(vecs[:, idx])
    if p.sum() < 0:
        p = -p
    p = p / p.sum()
    residual = float(np.abs(p @ M - p).sum())

    P_periodic = np.array([p @ Phi_t for Phi_t in transitions])
    P_periodic = np.clip(P_periodic, 0.0, None)
    P_periodic /= P_periodic.sum(axis=1, keepdims=True)

    return FloquetResult(period, store_times, transitions, p, P_periodic,
                         residual)


# --------------------------------------------------------------------------
# 2. Markov-modulated arrivals
# --------------------------------------------------------------------------
def mmpp_generator(lam: tuple[float, float], mu: float, cfg: QueueConfig,
                   q01: float, q10: float) -> np.ndarray:
    """Generator of the joint (backlog, regime) CTMC, ordered j*(K+1)+n.

    Regime 0 = high demand, regime 1 = low demand.  Switching rates q01, q10
    are per day.  Service rates are shared across regimes.
    """
    K = cfg.K
    size = 2 * (K + 1)
    A = np.zeros((size, size), dtype=float)
    n = np.arange(K + 1)
    d = death_rates(mu, cfg)

    for j in range(2):
        off = j * (K + 1)
        bj = birth_rates(float(lam[j]), cfg)

        q_exit = (q01, q10)[j]
        diag = -(bj + d + q_exit)                # births, deaths, regime exit
        A[off + n, off + n] = diag

        idx = off + n
        A[idx[:-1], idx[:-1] + 1] = bj[:-1]      # backlog births
        A[idx[1:], idx[1:] - 1] = d[1:]          # backlog deaths

        other = (1 - j) * (K + 1)
        A[idx, other + n] += (q01, q10)[j]       # regime switches

    return A


def mmpp_stationary(A: np.ndarray) -> np.ndarray:
    """Stationary distribution of a finite irreducible CTMC (linear solve)."""
    Q = A.T.copy()
    m = Q.shape[0]
    Q[-1, :] = 1.0
    rhs = np.zeros(m)
    rhs[-1] = 1.0
    p = np.linalg.solve(Q, rhs)
    if np.any(p < -1e-8):
        raise ValueError("stationary solution has materially negative entries")
    p = np.clip(p, 0.0, None)
    return p / p.sum()


def mmpp_indicators(A: np.ndarray, cfg: QueueConfig, q_star: int = 6) -> dict:
    """Drought indicators marginalised over the environmental regime."""
    K = cfg.K
    p = mmpp_stationary(A).reshape(2, K + 1)
    marg = p.sum(axis=0)                         # P(Q = n)
    n = np.arange(K + 1)
    E_Q = float(marg @ n)
    P_crit = float(marg[q_star:].sum()) if 0 < q_star <= K else 0.0
    return {
        "E_Q": E_Q,
        "P_backlog": float(1.0 - marg[0]),
        "P_crit": P_crit,
        "marginal": marg,
        "regime_mass": p.sum(axis=1),
    }


def compare_burstiness(mean_lam: float, mu: float, cfg: QueueConfig,
                       switch_rate: float = 0.03, contrast: float = 3.0) -> dict:
    """Compare a constant-rate queue with a bursty MMPP at the same mean lambda.

    With symmetric switching the two regimes have equal stationary mass, so
    lam_high = mean * 2r/(1+r) and lam_low = mean * 2/(1+r) for contrast r.
    """
    lam_high = mean_lam * 2.0 * contrast / (1.0 + contrast)
    lam_low = mean_lam * 2.0 / (1.0 + contrast)

    pi = stationary(mean_lam, mu, cfg)
    const_stats = {
        "E_Q": float(pi @ np.arange(cfg.K + 1)),
        "P_backlog": float(1.0 - pi[0]),
        "P_crit": float(pi[6:].sum()) if cfg.K >= 6 else 0.0,
    }

    A_mmpp = mmpp_generator((lam_high, lam_low), mu, cfg,
                            q01=switch_rate, q10=switch_rate)
    bursty = mmpp_indicators(A_mmpp, cfg)

    return {
        "mean_lam": mean_lam,
        "lam_high": float(lam_high),
        "lam_low": float(lam_low),
        "switch_rate": switch_rate,
        "constant": const_stats,
        "bursty": {k: v for k, v in bursty.items()
                   if k not in ("marginal", "regime_mass")},
        "amplification_E_Q": bursty["E_Q"] / max(const_stats["E_Q"], 1e-12),
    }


# --------------------------------------------------------------------------
# Demo
# --------------------------------------------------------------------------
def run_demos(verbose: bool = True) -> dict:
    cfg = QueueConfig(K=20, c=2, theta=8, alpha=1.5, eta=0.02)
    period = 365.0

    lam_fn = lambda t: 0.8 + 0.35 * np.sin(2 * np.pi * t / period)
    mu_fn = lambda t: 1.0 - 0.28 * np.sin(2 * np.pi * (t - 75.0) / period)

    f = floquet_steady_state(lam_fn, mu_fn, cfg, period, steps=2000)
    fl = f.summary(lam_fn, mu_fn, cfg)

    pi = stationary(0.8, 1.0, cfg)
    st = {
        "E_Q": float(pi @ np.arange(cfg.K + 1)),
        "P_crit": float(pi[6:].sum()),
    }

    burst = compare_burstiness(mean_lam=0.9, mu=1.0, cfg=cfg,
                               switch_rate=0.02)

    if verbose:
        print("FLOQUET PERIODIC BENCHMARK")
        print(f"  eigenvalue residual : {f.eig_residual:.2e}")
        print(f"  periodic mean E[Q]  : {fl['E_Q_mean']:.4f}")
        print(f"  periodic peak E[Q]  : {fl['E_Q_peak']:.4f}")
        print(f"  periodic peak P(Q>=6): {fl['P_crit_peak']:.4f}")
        print(f"  stationary-at-mean E[Q]: {st['E_Q']:.4f}")
        print(f"  stationary-at-mean P(Q>=6): {st['P_crit']:.4f}")
        print()
        print("MARKOV-MODULATED ARRIVALS (same mean lambda, clustered spells)")
        print(f"  lambda high/low : {burst['lam_high']:.3f} / {burst['lam_low']:.3f}")
        print(f"  switch rate     : {burst['switch_rate']:.3f} /day")
        print(f"  constant E[Q]   : {burst['constant']['E_Q']:.4f}")
        print(f"  bursty   E[Q]   : {burst['bursty']['E_Q']:.4f}")
        print(f"  amplification   : {burst['amplification_E_Q']:.2f}x")

    return {"floquet": f, "floquet_stats": fl, "stationary_stats": st,
            "bursty": burst}


if __name__ == "__main__":
    run_demos()
