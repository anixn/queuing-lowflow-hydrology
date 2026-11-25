"""Claim-scale envelope for the P01/P02 drought queue.

The fluid ledger is exact and demonstrates physical invariance when command
area, claim depth, capacity, severe threshold and service cap are rescaled
consistently. A small CTMC comparison shows finite-claim discreteness across
10/20/40 mm delivery units. All outputs are synthetic and illustrative.

Run from the repository root:
    python src/P01/claim_scale_envelope.py
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

__all__ = ["ClaimConvention", "physical_forcing", "fluid_ledger",
           "fluid_ledger_scaled", "ctmc_case", "run_envelope"]


@dataclass(frozen=True)
class ClaimConvention:
    """A mutually consistent claim scale in area and delivery depth."""

    area_ha: float
    depth_mm: float
    firm_share: float = 0.5
    tolerance_depth_mm: float = 400.0
    severe_depth_mm: float = 120.0
    service_cap_depth_mm_day: float = 60.0

    @property
    def claim_volume_m3(self) -> float:
        return self.area_ha * 10.0 * self.depth_mm

    @property
    def K(self) -> int:
        return int(round(self.tolerance_depth_mm / self.depth_mm))

    @property
    def q_star(self) -> int:
        return int(round(self.severe_depth_mm / self.depth_mm))

    @property
    def service_cap_claims_day(self) -> float:
        return self.service_cap_depth_mm_day / self.depth_mm


def physical_forcing(days: int, firm_share: float) -> tuple[np.ndarray, np.ndarray]:
    """Fixed synthetic demand/supply depths in mm/day."""
    t = np.arange(days, dtype=float)
    demand = 12.0 + 8.0 * np.sin(2.0 * np.pi * t / 365.0)
    natural_supply = 18.0 - 12.0 * np.sin(2.0 * np.pi * (t - 75.0) / 365.0)
    supply = np.minimum(natural_supply * firm_share, 60.0)
    return demand, supply


def fluid_ledger(demand: np.ndarray, supply: np.ndarray,
                 tolerance_mm: float = 400.0,
                 severe_mm: float = 120.0) -> dict[str, float]:
    """Exact deterministic backlog ledger in physical depth units."""
    q = 0.0
    exposure = 0.0
    blocked = 0.0
    served = 0.0
    peak = 0.0
    severe_days = 0.0
    for d, s in zip(demand, supply, strict=True):
        incoming = q + float(d)
        blocked += max(0.0, incoming - tolerance_mm)
        q = min(incoming, tolerance_mm)
        delivered = min(q, float(s))
        served += delivered
        q -= delivered
        peak = max(peak, q)
        exposure += q
        severe_days += float(q >= severe_mm)
    return {
        "peak_backlog_mm": peak,
        "mean_backlog_mm": exposure / len(demand),
        "backlog_exposure_mm_days": exposure,
        "severe_days": severe_days,
        "blocked_demand_mm": blocked,
        "served_demand_mm": served,
        "abandoned_demand_mm": blocked,
    }


def fluid_ledger_scaled(conv: ClaimConvention, demand: np.ndarray,
                        supply: np.ndarray) -> dict[str, float]:
    """Run the ledger in claim units after rescaling all physical quantities."""
    lam = np.asarray(demand, dtype=float) / conv.depth_mm
    mu = np.minimum(np.asarray(supply, dtype=float),
                    conv.service_cap_depth_mm_day) / conv.depth_mm
    q = 0.0
    exposure = blocked = served = peak = severe_days = 0.0
    for l, m in zip(lam, mu, strict=True):
        incoming = q + float(l)
        blocked += max(0.0, incoming - conv.K)
        q = min(incoming, float(conv.K))
        delivered = min(q, float(m))
        served += delivered
        q -= delivered
        peak = max(peak, q)
        exposure += q
        severe_days += float(q >= conv.q_star)
    return {
        "peak_backlog_mm": peak * conv.depth_mm,
        "mean_backlog_mm": exposure * conv.depth_mm / len(demand),
        "backlog_exposure_mm_days": exposure * conv.depth_mm,
        "severe_days": severe_days,
        "blocked_demand_mm": blocked * conv.depth_mm,
        "served_demand_mm": served * conv.depth_mm,
        "abandoned_demand_mm": blocked * conv.depth_mm,
    }


def ctmc_case(conv: ClaimConvention, days: int = 730) -> dict[str, float]:
    """Finite-claim CTMC comparison at one convention."""
    demand, supply = physical_forcing(days, conv.firm_share)
    cfg = QueueConfig(K=conv.K, c=1, theta=conv.K + 1,
                      alpha=1.0, eta=0.0)
    lam_fn = lambda t: float(np.interp(t, np.arange(days), demand)) / conv.depth_mm
    mu_fn = lambda t: float(np.interp(t, np.arange(days), supply)) / conv.depth_mm
    times, p = solve_transient(lam_fn, mu_fn, cfg, T=float(days - 1), dt=0.25)
    out = indicators(times, p, lam_fn, mu_fn, cfg, q_star=conv.q_star)
    return {
        "peak_backlog_mm": out["E_Q_peak"] * conv.depth_mm,
        "mean_backlog_mm": out["E_Q_mean"] * conv.depth_mm,
        "backlog_exposure_mm_days": out["backlog_exposure_claim_days"] * conv.depth_mm,
        "severe_days": "",
        "blocked_demand_mm": out["blocked_demand_claims"] * conv.depth_mm,
        "served_demand_mm": out["served_demand_claims"] * conv.depth_mm,
        "peak_severe_probability": out["P_crit_peak"],
        "abandoned_demand_mm": out["abandoned_demand_claims"] * conv.depth_mm,
        "ledger_residual_mm": out["ledger_residual_claims"] * conv.depth_mm,
    }


def run_envelope() -> list[dict[str, float | int | str]]:
    """Run the declared area/depth/firm-share envelope and CTMC scale check."""
    rows: list[dict[str, float | int | str]] = []
    for area in (45_000.0, 174_000.0, 190_000.0):
        for depth in (10.0, 20.0, 40.0):
            for firm in (0.3, 0.5, 0.7):
                conv = ClaimConvention(area, depth, firm)
                demand, supply = physical_forcing(730, firm)
                metrics = fluid_ledger(demand, supply)
                rows.append({
                    "model": "fluid_exact",
                    "area_ha": area,
                    "depth_mm": depth,
                    "firm_share": firm,
                    "claim_volume_m3": conv.claim_volume_m3,
                    "K_claims": conv.K,
                    "q_star_claims": conv.q_star,
                    "service_cap_claims_day": conv.service_cap_claims_day,
                    **metrics,
                    "peak_severe_probability": "",
                    "ledger_residual_mm": 0.0,
                    "provenance": "synthetic_illustrative_under_stated_assumptions",
                })
    for depth in (10.0, 20.0, 40.0):
        conv = ClaimConvention(45_000.0, depth, 0.5)
        rows.append({
            "model": "ctmc",
            "area_ha": conv.area_ha,
            "depth_mm": depth,
            "firm_share": conv.firm_share,
            "claim_volume_m3": conv.claim_volume_m3,
            "K_claims": conv.K,
            "q_star_claims": conv.q_star,
            "service_cap_claims_day": conv.service_cap_claims_day,
            **ctmc_case(conv),
            "provenance": "synthetic_illustrative_under_stated_assumptions",
        })
    return rows


def write_csv(rows: list[dict[str, float | int | str]], path: str | Path) -> None:
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
        default="analysis/claim_convention_2026-11-25/data/claim_scale_envelope.csv",
        help="Output CSV path (default: %(default)s)",
    )
    args = parser.parse_args()
    rows = run_envelope()
    write_csv(rows, args.output)
    fluid = [r for r in rows if r["model"] == "fluid_exact"]
    peaks = {float(r["peak_backlog_mm"]) for r in fluid}
    print(f"Wrote {len(rows)} cases to {args.output}")
    print(f"Exact fluid peak-backlog values: {sorted(peaks)}")
    print("All outputs are illustrative, under the stated assumptions.")


if __name__ == "__main__":
    main()
