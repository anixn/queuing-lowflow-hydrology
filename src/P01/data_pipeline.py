"""Data-to-rates pipeline skeleton for the Queueing-Drought Junction.

Turns hydroclimatic series into the two rate functions consumed by ``queue_core``:

    lambda(t) = demand claims arriving per day       (demand pressure)
    mu(t)     = backlog claims cleared per server/day (supply capacity)

The module is deliberately data-source agnostic.  Real loaders for IMD, CWC /
India-WRIS, CMIP6 and GRACE are specified in ``load_*`` functions below and
raise ``NotImplementedError`` with the exact product and column expectations
until the files are obtained.  A clearly-labelled synthetic generator lets the
whole chain be exercised today with NumPy only.

RUN
    python src/P01/data_pipeline.py            # synthetic Punjab/Maharashtra demo
    python src/P01/data_pipeline.py --help

DECISION 1 (revisable working assumption, unlocked 25 Nov 2026; see ../../START_HERE.md)
    1. CLAIM_VOLUME_M3 = 9e6 m^3, with COMMAND_AREA_HA = 45,000 ha. One claim
       is therefore one 20 mm bulk delivery over the district canal-irrigated
       proxy area. K=20
       claims = 400 mm.  These are explicit assumptions, not measurements;
       replace only if real canal-command records are found.  The demo below
       deliberately rescales volume for illustration, so it does not test this
       convention.
    2. Which servers are real: c in QueueConfig must equal the number of
       independent supply sources actually modelled (streamflow, canal,
       groundwater).  Do not inflate c to make rho look safe.
    3. Whether mu is proportional to total flow or to baseflow only.  The
       review argues baseflow is the dry-season workhorse; test both.

See ../../P01/queueing_howto.md and ../../P01/literature_audit.md.
"""

from __future__ import annotations

from dataclasses import dataclass
import argparse
from pathlib import Path
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from shared.queue_core import QueueConfig, solve_transient, indicators  # noqa: E402

__all__ = [
    "CLAIM_VOLUME_M3",
    "COMMAND_AREA_HA",
    "Pilot",
    "PILOTS",
    "rate_interpolator",
    "crop_water_requirement",
    "demand_rate",
    "supply_rate",
    "load_imd",
    "load_cwc",
    "load_cmip6",
    "load_grace",
    "synthetic_series",
    "run_pilot",
]


# --------------------------------------------------------------------------
# Convention (DECISION 1 — revisable proxy, not a gauge measurement)
# --------------------------------------------------------------------------
CLAIM_VOLUME_M3 = 9e6  # one claim = 20 mm over 45,000 ha
COMMAND_AREA_HA = 45000  # Sangli canal-irrigated area proxy (hectares)
# K = 20 claims = 1.8e8 m^3 = 400 mm over the proxy command.
# Source: ../../START_HERE.md section 4 and
# ../../analysis/claim_convention_2026-11-25/README.md.


@dataclass(frozen=True)
class Pilot:
    """A pilot region: cropping calendar and supply characteristics."""

    name: str
    state: str
    start_doy: int          # 1-based day of year when the main kharif crop is sown
    season_length: int      # days of the growing season
    peak_kc: float          # FAO-56 midpoint crop coefficient
    command_area_ha: float  # nominal irrigated area used for the volume conversion
    baseflow_fraction: float  # share of streamflow treated as firm dry-season supply
    canal_share: float      # share of demand met by a second, canal "server"

    @property
    def sowing_doy(self) -> int:
        return self.start_doy


PILOTS = {
    "punjab": Pilot(
        name="Punjab (rice-wheat)",
        state="Punjab",
        start_doy=185,          # late June / early July transplanting
        season_length=120,
        peak_kc=1.15,
        command_area_ha=50_000.0,
        baseflow_fraction=0.55,
        canal_share=0.60,
    ),
    "maharashtra": Pilot(
        name="Maharashtra (sugarcane / kharif)",
        state="Maharashtra",
        start_doy=200,
        season_length=140,
        peak_kc=1.20,
        command_area_ha=35_000.0,
        baseflow_fraction=0.35,
        canal_share=0.35,
    ),
}


# --------------------------------------------------------------------------
# Rate construction
# --------------------------------------------------------------------------
def rate_interpolator(times: np.ndarray, values: np.ndarray):
    """Return a callable rate(t) for ``queue_core.solve_transient``.

    Linear interpolation with constant extrapolation outside the observed
    range.  ``times`` and ``values`` must be equal length and sorted.
    """
    t = np.asarray(times, dtype=float)
    v = np.asarray(values, dtype=float)
    if t.ndim != 1 or v.ndim != 1 or t.size != v.size or t.size < 2:
        raise ValueError("times and values must be 1-D, equal length, >= 2")
    if np.any(np.diff(t) <= 0):
        raise ValueError("times must be strictly increasing")

    def rate(x: float) -> float:
        return float(np.interp(x, t, v, left=v[0], right=v[-1]))

    return rate


def crop_water_requirement(
    et0_mm: np.ndarray,
    kc: np.ndarray,
    effective_rain_mm: np.ndarray,
    area_ha: float,
) -> np.ndarray:
    """Daily irrigation requirement in m^3/day (FAO-56 double crop coefficient).

    ETc = Kc * ET0; irrigation need = max(0, ETc - P_eff), converted over the
    commanded area.  Rainfall above ETc does not create a negative claim.
    """
    et0_mm = np.asarray(et0_mm, dtype=float)
    kc = np.asarray(kc, dtype=float)
    p_eff = np.asarray(effective_rain_mm, dtype=float)
    if not (et0_mm.shape == kc.shape == p_eff.shape):
        raise ValueError("et0_mm, kc and effective_rain_mm must have the same shape")
    et_c_mm = kc * et0_mm
    need_mm = np.maximum(et_c_mm - p_eff, 0.0)
    return need_mm * area_ha * 10.0  # 1 mm over 1 ha = 10 m^3


def demand_rate(cwr_m3: np.ndarray, claim_volume_m3: float | None = None) -> np.ndarray:
    """Convert a daily demand-volume series into claims/day (lambda series)."""
    vol = CLAIM_VOLUME_M3 if claim_volume_m3 is None else claim_volume_m3
    if vol <= 0:
        raise ValueError("claim volume must be positive")
    return np.asarray(cwr_m3, dtype=float) / vol


def demo_claim_volume(cwr_m3: np.ndarray, target_peak: float = 1.5) -> float:
    """Pick a claim volume so the *synthetic demo* has peak lambda ~ target.

    This is a numerical scaling device for the illustration only.  It is NOT a
    physical convention: a real study must fix CLAIM_VOLUME_M3 independently
    from the quantity being modelled (see OPEN DECISIONS 1).
    """
    peak = float(np.max(cwr_m3))
    if peak <= 0:
        raise ValueError("demand series has no positive values")
    return peak / target_peak


def supply_rate(
    streamflow_m3s: np.ndarray,
    pilot: Pilot,
    claim_volume_m3: float | None = None,
) -> np.ndarray:
    """Convert mean daily streamflow into firm clearing capacity (mu per server).

    Firm supply = baseflow fraction of streamflow plus a canal contribution
    expressed as a fraction of the same volume.  See OPEN DECISIONS 2 and 3.
    """
    vol = CLAIM_VOLUME_M3 if claim_volume_m3 is None else claim_volume_m3
    q = np.asarray(streamflow_m3s, dtype=float)
    daily_m3 = q * 86_400.0
    firm_m3 = daily_m3 * pilot.baseflow_fraction
    firm_m3 = firm_m3 + pilot.canal_share * firm_m3  # second, partially independent server
    return firm_m3 / vol


# --------------------------------------------------------------------------
# Real data loaders — specified, not yet implemented
# --------------------------------------------------------------------------
def load_imd(path: str) -> tuple[np.ndarray, np.ndarray]:
    """Load IMD daily gridded rainfall and temperature for a pilot point.

    Expected: CSV/Parquet with columns ``date, rainfall_mm, tmax_c, tmin_c``
    after extracting the 0.25-degree grid cell covering the pilot district.
    Products: IMD gridded rainfall (0.25 deg) and gridded maximum/minimum
    temperature.  Return (dates, dataframe-like arrays).
    """
    raise NotImplementedError(
        f"IMD loader not yet implemented for {path!r}. "
        "Extract the 0.25-deg grid cell for the pilot district first and pass "
        "columns date, rainfall_mm, tmax_c, tmin_c. See queueing_howto.md §6."
    )


def load_cwc(path: str) -> tuple[np.ndarray, np.ndarray]:
    """Load CWC / India-WRIS observed daily streamflow for the pilot basin.

    Expected: ``date, discharge_m3s``.  Baseflow separation (digital filter or
    recession method) is applied downstream by ``pilot.baseflow_fraction`` for
    the skeleton; replace with an explicit filter before publication.
    """
    raise NotImplementedError(
        f"CWC/India-WRIS loader not yet implemented for {path!r}. "
        "Expected columns: date, discharge_m3s."
    )


def load_cmip6(path: str) -> tuple[np.ndarray, np.ndarray]:
    """Load bias-corrected CMIP6 daily precipitation/temperature for a scenario.

    Expected: ``date, precipitation_mm, tas_c`` for one model and one SSP after
    bias correction against the IMD baseline.  Ensemble spread must be carried
    through as rate uncertainty, not collapsed to a single mean series.
    """
    raise NotImplementedError(
        f"CMIP6 loader not yet implemented for {path!r}. "
        "Expected columns: date, precipitation_mm, tas_c (bias-corrected)."
    )


def load_grace(path: str) -> tuple[np.ndarray, np.ndarray]:
    """Load GRACE / GRACE-FO terrestrial water storage anomaly for validation.

    Expected: ``date, twsa_cm`` for the pilot region.  Used as an independent
    check on the *storage* representation, not as a fitted input to lambda/mu.
    """
    raise NotImplementedError(
        f"GRACE loader not yet implemented for {path!r}. "
        "Expected columns: date, twsa_cm. Use only for independent validation."
    )


# --------------------------------------------------------------------------
# Synthetic pilot (illustrative, never to be reported as a result)
# --------------------------------------------------------------------------
def synthetic_series(pilot: Pilot, days: int = 365 * 3, seed: int = 7):
    """Generate plausible daily ET0, rainfall and streamflow for a pilot.

    This exists so the pipeline can be tested without data files.  It encodes a
    monotonic seasonal cycle plus noise; it is NOT a climate projection and no
    scientific conclusion should be drawn from its output.
    """
    rng = np.random.default_rng(seed)
    t = np.arange(days)
    doy = t % 365 + 1

    # Warm-season reference evapotranspiration, 3-6 mm/day
    et0 = 4.2 + 1.6 * np.sin(2 * np.pi * (doy - 100) / 365)
    et0 += rng.normal(0.0, 0.35, days)
    et0 = np.maximum(et0, 0.5)

    # Monsoon rainfall pulse; IMD-like concentrated June-September
    rain = np.zeros(days)
    monsoon = (doy >= 170) & (doy <= 265)
    rain[monsoon] = rng.gamma(2.0, 5.0, monsoon.sum())
    rain += rng.exponential(0.6, days)
    effective_rain = 0.7 * rain  # simple runoff/interception loss

    # FAO-56-style triangular Kc over the sowing window
    phase = ((doy - pilot.sowing_doy) % 365) / pilot.season_length
    kc = np.where(
        phase <= 1.0,
        0.4 + (pilot.peak_kc - 0.4) * np.sin(np.pi * np.clip(phase, 0, 1)),
        0.35,
    )

    # Streamflow: baseflow + delayed monsoon recharge (75-day lag, as in Box 1)
    q = 40.0 + 18.0 * np.sin(2 * np.pi * (doy - 75) / 365)
    q += 25.0 * np.exp(-0.5 * (((doy - 240 + 75) % 365) / 45.0) ** 2)
    q += rng.normal(0.0, 3.0, days)
    q = np.maximum(q, 5.0)

    return {
        "t": t.astype(float),
        "et0_mm": et0,
        "kc": kc,
        "effective_rain_mm": effective_rain,
        "streamflow_m3s": q,
    }


def run_pilot(key: str = "punjab", days: int = 365 * 3) -> dict:
    """Build rates from a synthetic pilot and run the queue; returns diagnostics."""
    pilot = PILOTS[key]
    s = synthetic_series(pilot, days=days)

    cwr = crop_water_requirement(s["et0_mm"], s["kc"], s["effective_rain_mm"],
                                 pilot.command_area_ha)
    # Demo-only scaling so K=20 is an informative buffer. Real studies use the
    # revisable proxy convention (see START_HERE.md section 4).
    vol = demo_claim_volume(cwr)
    lam_v = demand_rate(cwr, claim_volume_m3=vol)
    mu_v = supply_rate(s["streamflow_m3s"], pilot, claim_volume_m3=vol)
    lam = rate_interpolator(s["t"], lam_v)
    mu = rate_interpolator(s["t"], mu_v)

    cfg = QueueConfig(K=20, c=2, theta=8, alpha=1.5, eta=0.02)
    times, P = solve_transient(lam, mu, cfg, T=float(days), dt=1.0)

    ind = indicators(times, P, lam, mu, cfg)
    rho_max = float(ind["rho_peak"])

    return {
        "pilot": pilot.name,
        "days": days,
        "lam_min": float(lam_v.min()),
        "lam_max": float(lam_v.max()),
        "mu_min": float(mu_v.min()),
        "mu_max": float(mu_v.max()),
        "rho_max": rho_max,
        "claim_volume_m3_demo": vol,
        "indicators": ind,
        "times": times,
        "P": P,
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pilot", choices=sorted(PILOTS), default="punjab")
    ap.add_argument("--days", type=int, default=365 * 3)
    args = ap.parse_args()

    r = run_pilot(args.pilot, days=args.days)
    print(f"Pilot: {r['pilot']}  ({r['days']} days, SYNTHETIC data)")
    print(f"  lambda range : {r['lam_min']:.3f} - {r['lam_max']:.3f} claims/day")
    print(f"  mu range     : {r['mu_min']:.3f} - {r['mu_max']:.3f} claims/server/day")
    print(f"  peak rho     : {r['rho_max']:.2f}")
    print(f"  demo claim vol: {r['claim_volume_m3_demo']:,.0f} m^3 "
          "(numerical scaling, NOT a physical convention)")
    print(f"  indicators   : {r['indicators']}")
    print("\nNOTE: synthetic demo only. Its volume is a scaling device, not the "
          "revisable proxy convention (9e6 m^3, see START_HERE.md section 4). Replace "
          "synthetic_series() with load_imd()/load_cwc() before reporting numbers.")


if __name__ == "__main__":
    main()
