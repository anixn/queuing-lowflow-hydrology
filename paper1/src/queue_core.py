"""Self-contained queueing core for the Queueing-Drought Junction (Paper 1 / Paper 3).

Implements a finite-capacity, non-stationary birth-death CTMC for a *deficit*
queue: water-demand claims arrive at rate lam(t), supply clears backlog at rate
mu(t), with finite capacity K, state-dependent emergency service (threshold
theta, multiplier alpha), reneging (abandonment) eta, and blocking at K.

No SciPy or simpy required: transient solution by RK4 on the forward equations,
exact stationary product-form solution, and an independent Gillespie/thinning
discrete-event simulator used as a check on both.

Units: rates are volume claims per day (or per day per claim for eta); time in days.

Run:  python paper1/src/queue_core.py
"""

from __future__ import annotations

from dataclasses import dataclass
import numpy as np

__all__ = [
    "QueueConfig",
    "birth_rates",
    "death_rates",
    "generator",
    "stationary",
    "solve_transient",
    "simulate_des",
    "des_time_average",
    "indicators",
    "mean_recovery_time",
    "run_demos",
]


@dataclass(frozen=True)
class QueueConfig:
    """Physical parameters of the deficit queue (all dimensionless except eta)."""

    K: int = 20          # maximum trackable backlog (claims)
    c: int = 2           # parallel supply sources ("servers": e.g. streamflow, canal)
    theta: int = 8       # backlog at which emergency/drought-mode service switches on
    alpha: float = 1.5   # service-rate multiplier above theta
    eta: float = 0.02    # reneging per waiting claim per day (demand abandonment)
    balk: float = 0.0    # extra fraction of arrivals withheld at full backlog


def birth_rates(lam: float, cfg: QueueConfig) -> np.ndarray:
    """Admitted-arrival rate lambda_n for each backlog state n=0..K.

    Arrivals at n=K are blocked (lost demand), scaled by (1 - balk).
    """
    n = np.arange(cfg.K + 1)
    rate = np.full(cfg.K + 1, float(lam))
    rate[cfg.K] = float(lam) * (1.0 - cfg.balk)
    if cfg.K > 0:
        rate[cfg.K] = 0.0 if cfg.balk >= 1.0 else rate[cfg.K]
    # blocked state cannot accept new claims
    rate[cfg.K] = 0.0
    return rate


def death_rates(mu: float, cfg: QueueConfig) -> np.ndarray:
    """Clearing rate mu_n = service + reneging, with drought-mode boost."""
    n = np.arange(cfg.K + 1)
    base = np.minimum(n, cfg.c) * float(mu)
    boost = np.where(n >= cfg.theta, cfg.alpha, 1.0)
    service = base * boost
    reneging = n * cfg.eta
    out = service + reneging
    out[0] = 0.0
    return out


def generator(lam: float, mu: float, cfg: QueueConfig) -> np.ndarray:
    """Row-generator A(t) for the forward equation dp/dt = p A(t)."""
    b = birth_rates(lam, cfg)
    d = death_rates(mu, cfg)
    A = np.zeros((cfg.K + 1, cfg.K + 1), dtype=float)
    idx = np.arange(cfg.K + 1)
    A[idx, idx] = -(b + d)
    A[idx[:-1], idx[:-1] + 1] = b[:-1]   # upward jumps
    A[idx[1:], idx[1:] - 1] = d[1:]      # downward jumps
    return A


def stationary(lam: float, mu: float, cfg: QueueConfig) -> np.ndarray:
    """Exact product-form stationary distribution of the finite birth-death chain."""
    b = birth_rates(lam, cfg)
    d = death_rates(mu, cfg)
    pi = np.zeros(cfg.K + 1, dtype=float)
    pi[0] = 1.0
    for n in range(1, cfg.K + 1):
        pi[n] = pi[n - 1] * b[n - 1] / d[n]
    return pi / pi.sum()


def solve_transient(lam_fn, mu_fn, cfg: QueueConfig, T: float, dt: float,
                    p0: np.ndarray | None = None):
    """RK4 integration of the non-stationary forward equations."""
    times = np.linspace(0.0, T, int(round(T / dt)) + 1)
    P = np.zeros((len(times), cfg.K + 1), dtype=float)
    if p0 is None:
        P[0, 0] = 1.0                      # start with an empty deficit queue
    else:
        P[0] = np.asarray(p0, dtype=float)
        P[0] /= P[0].sum()
    for k in range(len(times) - 1):
        t = times[k]
        p = P[k]

        def A(s):
            return generator(lam_fn(s), mu_fn(s), cfg)

        k1 = p @ A(t)
        k2 = (p + 0.5 * dt * k1) @ A(t + 0.5 * dt)
        k3 = (p + 0.5 * dt * k2) @ A(t + 0.5 * dt)
        k4 = (p + dt * k3) @ A(t + dt)
        nxt = p + (dt / 6.0) * (k1 + 2 * k2 + 2 * k3 + k4)
        nxt = np.clip(nxt, 0.0, None)
        P[k + 1] = nxt / nxt.sum()
    return times, P


def _total_rate_bound(lam_fn, mu_fn, cfg: QueueConfig, T: float, grid=4001) -> float:
    """Upper bound on the total jump rate, for Gillespie thinning."""
    ts = np.linspace(0.0, T, grid)
    lam_max = max(float(lam_fn(t)) for t in ts)
    mu_max = max(float(mu_fn(t)) for t in ts)
    return lam_max + cfg.c * mu_max * cfg.alpha + cfg.K * cfg.eta + 1e-9


def simulate_des(lam_fn, mu_fn, cfg: QueueConfig, T: float, seed: int = 0,
                 burn_in: float = 0.0):
    """Independent discrete-event simulation (Gillespie thinning).

    Returns (state, time) arrays sampled at jump epochs after burn_in.
    """
    rng = np.random.default_rng(seed)
    cap = _total_rate_bound(lam_fn, mu_fn, cfg, T)
    state, clock = 0, 0.0
    states, clocks = [], []
    while True:
        clock += rng.exponential(1.0 / cap)
        if clock >= T:
            break
        b = birth_rates(lam_fn(clock), cfg)[state]
        d = death_rates(mu_fn(clock), cfg)[state]
        total = b + d
        if total <= 0.0:
            continue
        if rng.random() > total / cap:            # thinning rejection
            continue
        if rng.random() < b / total:              # only the current state's events
            state = min(state + 1, cfg.K)
        else:
            state = max(state - 1, 0)
        if clock >= burn_in:
            states.append(state)
            clocks.append(clock)
    return np.asarray(states, dtype=int), np.asarray(clocks, dtype=float)


def des_time_average(states, clocks, horizon: float, burn_in: float = 0.0) -> float:
    """Dwell-time-weighted mean backlog from a DES trajectory (jump-epoch means are biased)."""
    if len(states) == 0:
        return float("nan")
    durations = np.diff(clocks, append=horizon)
    keep = clocks >= burn_in
    if not keep.any():
        return float("nan")
    return float(np.average(states[keep], weights=durations[keep]))


def indicators(times, P, lam_fn, mu_fn, cfg: QueueConfig, q_star: int = 6):
    """Queue-state drought indicators from a transient solution."""
    n = np.arange(cfg.K + 1)
    E_Q = P @ n
    P_pos = 1.0 - P[:, 0]
    P_crit = P[:, q_star:].sum(axis=1) if 0 < q_star <= cfg.K else np.zeros_like(E_Q)

    lam_eff = np.array([
        birth_rates(lam_fn(t), cfg) @ P[i] for i, t in enumerate(times)
    ])
    with np.errstate(divide="ignore", invalid="ignore"):
        E_W = np.where(lam_eff > 0, E_Q / lam_eff, np.nan)   # Little's law

    # Abandoned demand = blocked at K + reneging from waiting claims.
    abandoned = np.array([
        (lam_fn(t) * (1.0 - cfg.balk) if cfg.K == 0 else 0.0) * P[i, cfg.K]
        + cfg.eta * (n * P[i]).sum()
        for i, t in enumerate(times)
    ])
    U = float(np.trapezoid(abandoned, times))

    rho = np.array([lam_fn(t) / mu_fn(t) for t in times])
    return {
        "E_Q_peak": float(E_Q.max()),
        "E_Q_mean": float(np.trapezoid(E_Q, times) / (times[-1] - times[0])),
        "P_backlog_peak": float(P_pos.max()),
        "P_backlog_mean": float(np.trapezoid(P_pos, times) / (times[-1] - times[0])),
        "P_crit_peak": float(P_crit.max()),
        "E_wait_mean": float(np.nanmean(E_W)),
        "unmet_demand_U": U,
        "rho_peak": float(rho.max()),
        "rho_mean": float(np.trapezoid(rho, times) / (times[-1] - times[0])),
    }


def mean_recovery_time(lam: float, mu: float, cfg: QueueConfig, start: int) -> float:
    """Mean first-passage time from backlog `start` to empty, stationary rates."""
    A = generator(lam, mu, cfg)
    m = np.arange(1, cfg.K + 1)                       # transient states
    M = np.empty((cfg.K, cfg.K), dtype=float)
    for i, si in enumerate(m):
        for j, sj in enumerate(m):
            M[i, j] = -A[si, sj] if i != j else -A[si, si]
    sol = np.linalg.solve(M, np.ones(cfg.K))
    return float(sol[start - 1])


def run_demos(verbose: bool = True):
    """Three reproducible checks/illustrations used in Paper 1's Box 1."""
    cfg = QueueConfig()
    out = {}

    # (1) solver verification: exact stationary vs RK4 long-run vs DES time average
    lam_s, mu_s = 0.8, 1.0
    pi_exact = stationary(lam_s, mu_s, cfg)
    times, P = solve_transient(lambda t: lam_s, lambda t: mu_s, cfg, T=800.0, dt=0.05)
    pi_rk4 = P[-1]
    states, clocks = simulate_des(lambda t: lam_s, lambda t: mu_s, cfg,
                                  T=100000.0, seed=11, burn_in=1000.0)
    pi_des = np.bincount(states, minlength=cfg.K + 1) / len(states)
    out["verification"] = {
        "stationary_E_Q": float(pi_exact @ np.arange(cfg.K + 1)),
        "rk4_E_Q": float(pi_rk4 @ np.arange(cfg.K + 1)),
        "des_time_avg_E_Q": des_time_average(states, clocks, 100000.0, 1000.0),
        "des_jump_epoch_E_Q": float(pi_des @ np.arange(cfg.K + 1)),
        "l1_rk4_exact": float(np.abs(pi_rk4 - pi_exact).sum()),
        "l1_des_jump_exact": float(np.abs(pi_des - pi_exact).sum()),
    }

    # (2) stationarity vs non-stationarity at the SAME mean lam and mean mu.
    #     Dry-season service dip lags the demand peak: a realistic monsoon signal.
    lam_mean, mu_mean = 0.80, 1.00

    def lam_ns(t):
        return lam_mean + 0.35 * np.sin(2 * np.pi * t / 365.0)

    def mu_ns(t):
        return mu_mean - 0.28 * np.sin(2 * np.pi * (t - 75.0) / 365.0)

    T = 365.0 * 3
    _, P_stat = solve_transient(lambda t: lam_mean, lambda t: mu_mean, cfg, T, 0.25)
    times_ns, P_ns = solve_transient(lam_ns, mu_ns, cfg, T, 0.25)
    cut = int(0.25 * len(times_ns))     # discard first-year warm-up
    out["stationary"] = indicators(times_ns[cut:], P_stat[cut:],
                                   lambda t: lam_mean, lambda t: mu_mean, cfg)
    out["nonstationary"] = indicators(times_ns[cut:], P_ns[cut:],
                                      lam_ns, mu_ns, cfg)
    out["recovery_time_q6"] = mean_recovery_time(lam_mean, mu_mean, cfg, 6)

    # (3) critical transition: ramp lam across rho = 1
    def lam_ramp(t):
        return 0.70 + 0.45 * (t / T)

    times_r, P_r = solve_transient(lam_ramp, lambda t: mu_mean, cfg, T, 0.25)
    out["transition"] = indicators(times_r, P_r, lam_ramp, lambda t: mu_mean, cfg)

    if verbose:
        for key, val in out.items():
            print(f"[{key}]")
            if isinstance(val, dict):
                for k, v in val.items():
                    print(f"  {k:>20s} : {v: .5f}")
            else:
                print(f"  {val: .5f}")
    return out


if __name__ == "__main__":
    run_demos()
