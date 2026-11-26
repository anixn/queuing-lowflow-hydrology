# Data access specification — IMD / CAMELS-IND / CMIP6 / GRACE

Revision 3, 25 November 2026. Paths and findings below were verified against
the files on disk and the CAMELS-IND data-description PDF.

## 0. Data actually available

| Source | Path | Content | Status |
|---|---|---|---|
| IMD gridded | `D:\Datasets\imd\pr`, `\tmax`, `\tmin` | 75 annual NetCDF/HDF5 files each (1951–2025), ~25 MB each | Present. Files start with HDF5 magic; use R (`ncdf4`, `terra`) or the `drought` Python environment (`netCDF4`). Base Python lacks `netCDF4`/`h5py`. |
| CAMELS-IND forcings | `D:\Datasets\CIMP6_India\data_raw\camels_ind_forcings\catchment_mean_forcings` | 472 catchment daily CSVs, `03001.csv` … `170xx.csv`; columns `prcp(mm/day)`, `tmax(C)`, `tmin(C)`, `pet_gleam(mm/day)`, soil moisture | Present and readable with plain R/Python. This is the near-term route. |
| CAMELS-IND streamflow | `...\streamflow_timeseries\streamflow_observed.csv` | 472 gauge columns, 1980 onward; also `lstm_pred_streamflow.csv` | Present. Column headers are gauge IDs; **use `check.names=FALSE` in R** or they become `X4026`. |
| CAMELS-IND attributes | `...\attributes_csv\camels_ind_*.csv` | name, topo, hydro, climate, land, soil, anthology, geology | Present. `camels_ind_name.csv` gives basin/gauge names; `camels_ind_topo.csv` gives area and coordinates. |
| Catchment shapefiles | `D:\Datasets\CIMP6_India\data_raw\catchments\` | 17 basin folders + `merged` | Present. For mapping only; not needed for the first queue run. |
| CMIP6 historical | `D:\Datasets\CIMP6_India\data_raw\cmip6\{pr,tasmax,tasmin}` | 24 models × 34 years (1981–2014) | Present. |
| CMIP6 SSP | `D:\Datasets\Download_CMIP\SSP\{pr,tasmax,tasmin}` | Raw SSP126/245/370/585 forcing; 3,564 files per variable | Present. Fallback/sensitivity forcing; bias correction required before published use. |
| CAMELS-IND-Proj | `D:\Datasets\CAMELS_IND_Proj` | 13 CMIP6 models × historical + four SSPs; daily projected streamflow 1980–2100; bias-corrected forcing archive | Present. Gauge 4026 is complete in all 65 streamflow files. Conditional future μ ensemble after historical/provenance validation; do not double bias correct forcing. |

## 1. Claim convention — v2 per-gauge unit system (current)

Updated 26 November 2026 for the R/v2 rebuild. The v1 district proxies
(45,000 ha Sangli; 72,252 ha Yadgir) are **superseded** and are not part of the
current analysis. The current convention
lives in exactly one place in code — `R/config.R` (`P$d_mm`, `P$f_irr`,
`P$s_firm`, `P$cap_mm`) applied through `R/00_utils/units.R` — and is documented
in `protocol/PROTOCOL_v2.md` §2.

**This is a stated assumption, not a calibrated value.**

| Quantity | v2 definition | Physical reading |
|---|---|---|
| Command area (per gauge) | `A_cmd = f_irr * A_catchment` | `f_irr = 0.10` default; swept {0.03, 0.10, 0.25} |
| One claim | `V_claim = d/1000 * A_cmd` | `d = 20 mm`; one volume per gauge, used by BOTH demand and supply |
| Demand | `lambda = need_mm / d` | claims/day; area cancels because demand is a depth rate |
| Supply | `mu = min(S_mm, cap_mm) / d` | `S_mm = Q*86400*s_firm/A_cmd*1000`; `s_firm = 0.5`, `cap_mm = 10` |
| Capacity `K` | `min(80, max(25, ceil(K_days*lam_bar)))` | catchment-relative; `K_days = 365` |
| Severe state `q*` | `ceil(q_days*lam_bar)` | `q_days = 60` |
| Service boost `theta` | `ceil(1.5*q*)` | catchment-relative |

Why this is more defensible than v1: the same claim volume scales demand and
supply, so the unit-mix defect (F1) cannot recur; thresholds are functions of
each gauge's mean demand, so a wet and a dry gauge are comparable; and the
`f_irr` sweep carries the demand-uncertainty envelope. Stage-B measured demand
would replace the envelope but was unavailable.

Source: `R/config.R`, `R/00_utils/units.R`, `protocol/PROTOCOL_v2.md`.

## 2. Study data (v2)

| Study | Data | Target |
|---|---|---|
| India | CAMELS-IND, 472 gauges; Drought Intelligence Explorer | district SMA <= -15% (primary); training-only SPI-3 (sensitivity) |
| USA | Caravan-US, 671 gauges; ResOpsUS, 678 reservoirs; USDM county DSCI | USDM DSCI >= 100 (reservoir pilot); training-only SPI-3 (common protocol) |

The India endpoint set is **15 gauges across 8 basins** (V1 screen; at least 5
training and 3 test design events). The US reservoir pilot is exploratory (14
paired in-window). The common-protocol comparison uses Caravan-US gauges (270
strict-pass) and a training-only SPI-3 target.

## 3. Data-quality findings (v2)

- Zero-flow semantics in CAMELS-IND are unresolved. The five-class proxy audit
  is in `output/zero_audit_summary.csv`. Feeding artifact zeros as real zeros
  (V0) changes the sensitivity result; V1 is primary.
- The Drought Intelligence Explorer SMA/SPI/SPEI use an external 1981-2020
  climatology. The primary target is therefore not strictly leakage-free; the
  training-only SPI-3 target is the clean sensitivity.
- Stage-B crop-area and canal-command records are unavailable. Demand is a
  Stage-A envelope with `f_irr` swept. The USA uses a declared `Kc = 0.8`.
- OpenET validation is pending the 1 December 2026 quota reset; WaPOR/GLEAM are
  keyless alternatives.

## 4. What has been built (v2)

| Script | Purpose |
|---|---|
| `R/run_pipeline.R` | India S2-S7 backbone |
| `R/us_pilot/` | USA reservoir-centric data assembly and evaluation |
| `R/compare/` | Like-for-like India-US common-protocol comparison |
| `R/00_utils/` | Engine, unit wall, indices, metrics, IO, audit |
| `R/verify/` | 14-check verification battery |
| `steps/` | Numbered executable sequence |


## 5. Still missing / next actions

1. **Crop area, calendar and canal command area** — needed to replace the
   district proxy and generic Kc curve. `camels_ind_anth.csv` supplies crop/dam
   covariates but not command boundaries or daily operations; obtain district
   agriculture and CWC/India-WRIS records.
2. **CAMELS-IND-Proj historical validation** — projected streamflow is available
   for 13 models and all scenarios. Validate the historical 1980–2014 simulations
   against observed/LSTM streamflow before using the 2015–2100 ensemble as future μ.
3. **Future forcing** — CAMELS-IND-Proj describes its forcing as bias-corrected,
   but the forcing subset is not extracted and standard archive tools failed.
   Recover/re-extract it; otherwise bias-correct raw SSP forcing against IMD.
4. **GRACE/GRACE-FO** — not found; required only for independent storage validation.
5. **Claim volume convention** — see Section 1.
6. **Regulation status** — CAMELS-IND attributes show 86 India-WRIS large/medium
   dams for gauge 4026 (total storage about 6.26×10⁹ m³; irrigation fraction
   0.867) and 271 for gauge 4064 (about 1.51×10¹⁰ m³; irrigation fraction
   0.927). This establishes substantial dam presence, not station operating
   rules. The PDF has no gauge-specific regulation, abstraction, release or
   intermittency statement. Obtain CWC/India-WRIS station metadata and
   release/diversion/canal-operation records before causal interpretation.

## 6. Original file contracts (unchanged, for reference)

```text
IMD extract      : date, rainfall_mm, tmax_c, tmin_c
CWC extract      : date, discharge_m3s
CMIP6 extract    : date, pr_mm, tas_c, model, ssp  (bias-corrected)
GRACE extract    : date, twsa_cm
Crop/calendar    : year, district, crop, area_ha, sowing_doy, harvest_doy
```

The R loaders in `R/00_utils/io.R` cover the CAMELS-IND pilot. The future CMIP6
stage will add its own loader under `R/50_future/`; no Python loader is part of
the current analysis.
