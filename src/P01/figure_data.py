"""NumPy-only data preparation for P01 manuscript figures."""

from __future__ import annotations

import csv
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from shared.queue_core import QueueConfig, solve_transient  # noqa: E402

__all__ = ["box1_series", "load_sensitivity_rows"]


def box1_series(dt: float = 0.25) -> dict[str, np.ndarray]:
    """Return stationary/seasonal Box 1 series after a one-year spin-up."""
    if not 0.0 < dt <= 0.25:
        raise ValueError("dt must be in (0, 0.25] days for Box 1 figures")
    cfg = QueueConfig(K=20, c=2, theta=8, alpha=1.5, eta=0.02)
    period = 365.0
    horizon = 3.0 * period

    lam_s = lambda _t: 0.8
    mu_s = lambda _t: 1.0
    lam_n = lambda t: 0.8 + 0.35 * np.sin(2.0 * np.pi * t / period)
    mu_n = lambda t: 1.0 - 0.28 * np.sin(
        2.0 * np.pi * (t - 75.0) / period)

    ts, ps = solve_transient(lam_s, mu_s, cfg, horizon, dt)
    tn, pn = solve_transient(lam_n, mu_n, cfg, horizon, dt)
    cs = int(np.searchsorted(ts, period))
    cn = int(np.searchsorted(tn, period))
    ts, ps = ts[cs:], ps[cs:]
    tn, pn = tn[cn:], pn[cn:]
    n = np.arange(cfg.K + 1)
    return {
        "time_s": ts - period,
        "time_n": tn - period,
        "E_Q_s": ps @ n,
        "E_Q_n": pn @ n,
        "P_crit_s": ps[:, 6:].sum(axis=1),
        "P_crit_n": pn[:, 6:].sum(axis=1),
        "lambda_n": np.array([lam_n(t) for t in tn]),
        "mu_n": np.array([mu_n(t) for t in tn]),
    }


def load_sensitivity_rows(
    path: str | Path = ROOT / "analysis/novelty_2026-11-25/data/box1_sensitivity.csv",
) -> list[dict[str, str]]:
    """Load the script-backed 44-case sensitivity CSV."""
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {path}; run python src/P01/box1_sensitivity.py first")
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))
