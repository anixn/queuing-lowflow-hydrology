# US pilot — ResOpsUS + Caravan-US + OpenET + USDM

Status: data acquisition / feasibility. Date: 26 November 2026.

This pilot replaces the two weakest assumptions of the India study:

| India study assumption | US pilot replacement |
|---|---|
| `f_irr = 0.10` fixed command area | Caravan/HydroATLAS `ire_pc_sse` (per-catchment irrigated fraction) |
| `mu = 0.5 * observed streamflow` | **ResOpsUS reservoir outflow** (measured releases) |
| `K = 365 * lambda_bar` | `rev_mc_usu` / reservoir capacity where available |
| district SMA target (leakage disclosed) | **USDM** drought severity (observed, public) |
| crop-water envelope only | Caravan forcing demand, **OpenET-validated** (2016+) |

## Data sources

| Source | Role | Coverage | Access |
|---|---|---|---|
| Caravan-US (`D:/Datasets/Caravan_2025`) | streamflow, ERA5-Land forcing, HydroATLAS attributes | 671 catchments, 1951–2023 | local |
| ResOpsUS (Zenodo 6612040) | daily storage, inflow, outflow, elevation | ~679 reservoirs, 1974–2020 | open, CC BY 4.0 |
| OpenET (`etdata.org`) | field-scale actual ET | 2016–present, 17 western states → 48 states | **API key required** |
| USDM (`usdmdataservices.unl.edu`) | weekly drought severity (D0–D4, DSCI) | 2000–present | public REST |

## Important time-window constraint

ResOpsUS ends in 2020 and OpenET begins in 2016. A multi-decade train/test split
(1981–2010 / 2011–2020) therefore **cannot** use OpenET as the primary demand
series. The design is:

- **Primary demand** `lambda(t)`: Caravan forcing (precipitation, FAO-PM PET,
  temperature) × `ire_pc_sse`, the same crop-water envelope but with a
  data-driven irrigated area.
- **Demand sensitivity**: Huang et al. (2018) reconstructed monthly irrigation
  withdrawal (0.5°, 1971–2010) aggregated to each catchment.
- **Demand validation**: OpenET actual ET over 2016–2020, used to check the
  crop-coefficient envelope, not to drive the multi-decade fit.
- **Supply** `mu(t)`: ResOpsUS reservoir outflow / the per-catchment claim volume.
- **Target**: USDM weekly D0–D4 / DSCI at the catchment's HUC8 or centroid,
  aggregated to months.

## Candidate sample (screened)

From `output_us/caravan_us_screen.csv`:

- 671 Caravan-US catchments;
- 310 with `ire_pc_sse > 0`;
- 59 with `dor_pc_pva > 0` or `rev_mc_usu > 0`;
- **24 with both irrigation and regulation** (the core queue candidates).

The spatial match to ResOpsUS reservoirs will determine the final sample; a
catchment whose polygon contains a ResOpsUS reservoir is queue-relevant even if
HydroATLAS does not flag it.

## Scripts

| Script | Purpose |
|---|---|
| `R/us_pilot/01_screen_caravan.R` | Profile Caravan-US catchments; write `output_us/caravan_us_screen.csv` |
| `R/us_pilot/02_match_resops.R` | Spatial match of ResOpsUS reservoirs to Caravan catchments (next) |
| `R/us_pilot/03_build_us_rates.R` | Build daily `lambda`, `mu` from Caravan + ResOpsUS (next) |
| `R/us_pilot/04_run_us_queue.R` | Run the existing queue engine and evaluation |

## Blocker

OpenET bulk access requires a free API key (register at
`https://account.etdata.org/`). Without it, the 2016–2020 validation slice cannot
be pulled. Everything else (Caravan, ResOpsUS, USDM) is accessible without a key.
