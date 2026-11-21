# Data access specification — IMD / CAMELS-India / CMIP6 / GRACE

Revision 2, 20 November 2026. **Revised after inspecting the actual files on
disk.** The first revision assumed no data were present; that is no longer
true. Paths and findings below are verified.

## 0. Data actually available

| Source | Path | Content | Status |
|---|---|---|---|
| IMD gridded | `D:\Datasets\imd\pr`, `\tmax`, `\tmin` | 75 annual NetCDF/HDF5 files each (1951–2025), ~25 MB each | Present. Files start with HDF5 magic; Python here has no `netCDF4`/`h5py`, but **R has `ncdf4` and `terra`**. |
| CAMELS-India forcings | `D:\Datasets\CIMP6_India\data_raw\camels_ind_forcings\catchment_mean_forcings` | 472 catchment daily CSVs, `03001.csv` … `170xx.csv`; columns `prcp(mm/day)`, `tmax(C)`, `tmin(C)`, `pet_gleam(mm/day)`, soil moisture | Present and readable with plain R/Python. This is the near-term route. |
| CAMELS-India streamflow | `...\streamflow_timeseries\streamflow_observed.csv` | 472 gauge columns, 1980 onward; also `lstm_pred_streamflow.csv` | Present. Column headers are gauge IDs; **use `check.names=FALSE` in R** or they become `X4026`. |
| CAMELS-India attributes | `...\attributes_csv\camels_ind_*.csv` | name, topo, hydro, climate, land, soil, anthology, geology | Present. `camels_ind_name.csv` gives basin/gauge names; `camels_ind_topo.csv` gives area and coordinates. |
| Catchment shapefiles | `D:\Datasets\CIMP6_India\data_raw\catchments\` | 17 basin folders + `merged` | Present. For mapping only; not needed for the first queue run. |
| CMIP6 historical | `D:\Datasets\CIMP6_India\data_raw\cmip6\{pr,tasmax,tasmin}` | 24 models × 34 years (1981–2014) | Present. |
| CMIP6 SSP | `D:\Datasets\Download_CMIP\SSP\{pr,tasmax,tasmin}` | 14-model hybrid list × SSP1-2.6 / SSP2-4.5 / SSP3-7.0 / SSP5-8.5; years 2015–2040, 2041–2060, 2081–2100 | **Download in progress** (~75 GB so far). 28 model/SSP combinations already have all three variables and ≥60 years ready. See Section 5. |

## 1. Claim convention — locked provisionally (21 November 2026)

Decision recorded in `../START_HERE.md` §4 and applied in both code packages.
**This is a stated assumption, not a calibrated value.** It is written at the
top of `paper3/R/01_build_rates.R` and in `paper1/src/data_pipeline.py` so it
can be changed in one place.

| Quantity | Value | Physical reading |
|---|---|---|
| Command area | 50,000 ha | Nominal irrigated area served by one bulk delivery system |
| One claim | 10⁷ m³ | 20 mm of water over that command — one standard irrigation application |
| Capacity K | 20 claims | 2×10⁸ m³ = 400 mm — roughly one season's cumulative supply |
| Service cap | 3 claims/day | 60 mm/day = 3×10⁷ m³/day intake ceiling |
| Firm share | 0.5 of streamflow | Dry-season baseflow treated as dependable supply |

Why this scale: 20 mm is a normal single irrigation depth; it makes λ of order
0.05–0.26 claims/day in the pilot and K=20 a physically readable ceiling. A
field-day (100 m³) or outlet-turn (1,000–10,000 m³) convention would be more
operational but would require canal records we do not have. Rescaling the claim
rescales λ, μ and K together, so the pilot numbers stay illustrative until the
50,000 ha and 10⁷ m³ are replaced with real canal/crop records.

## 2. Pilot regions — revised

The original plan proposed Punjab and Maharashtra. **CAMELS-India does not
cover the Indus/Punjab**, so that pair is not possible with these files.
Available high-coverage gauges (from `camels_ind_name.csv`):

| Gauge | Name | Basin | Coverage | Basin area |
|---|---|---|---|---|
| 12035 | Mandleshwar | Narmada | 96.13% | — |
| 4026 | Kurundwad | Krishna | 95.54% | 15,190 km² |
| 4064 | Yadgir | Krishna | 95.48% | 69,863 km² |

**Pilot chosen: gauge 4026 (Kurundwad, Krishna, Maharashtra).** It is in the
target state and has the best coverage. Alternative 4064 can be used by
changing one line in `paper3/R/01_build_rates.R`.

## 3. Data-quality findings

- Gauge 4026 has 9,710 zero-flow days out of 14,308 non-missing (68%). Whether
  these are true zeros or a fill value must be checked against the CAMELS-India
  documentation before publication. Gauge 4064 has 4,596 zeros out of 14,299.
- 668 missing streamflow days in the 4026 series were linearly interpolated in
  the R script and flagged in the output column `q_imputed`.
- Observed streamflow ends in 2020 (4026) / 2019 (4064); forcings end 2020.
- No crop-area or canal-command records were found. Crop water requirement in
  the R script therefore uses an **assumed** 50,000 ha and a generic Kc curve;
  it is a pipeline demonstration, not a calibrated irrigation demand.

## 4. What has been built against these files

| Script | Purpose |
|---|---|
| `paper3/R/01_build_rates.R` | Read forcing CSV + observed streamflow for one gauge, build daily `lambda`, `mu`, write `paper3/data/rates_4026.csv`. |
| `paper3/R/02_run_queue.R` | Read that CSV, RK4 solve the finite-capacity CTMC, write E[Q], Pr(Q≥6), peak ρ, unmet demand. Base R only. |

Both were run successfully on 4026. The queue produces non-trivial dynamics
(E[Q] mean 1.43, peak 3.60, peak Pr(Q≥6) 0.156 over 2001–2020) **under the
stated assumptions**. These numbers are a pipeline check, not results.

## 5. Still missing / next actions

1. **Crop area and canal command area** — needed to replace the assumed
   `command_area_ha` and `canal_share`. Search `attributes_csv/camels_ind_anth.csv`
   first; if absent, this must come from CWC/India-WRIS records.
2. **SSP scenario CMIP6 files are downloading** into `D:\Datasets\Download_CMIP\SSP`
   (script: `D:\Datasets\Download_CMIP\download_cmip6_ssp.R`). Four scenarios and
   a 14-model hybrid selection. **Ready now** (all three variables, ≥60 years):
   ACCESS-ESM1-5, BCC-CSM2-MR, CanESM5, CNRM-CM6-1, EC-Earth3, EC-Earth3-Veg-LR,
   NorESM2-MM for SSP1-2.6 / SSP2-4.5 / SSP5-8.5; BCC-CSM2-MR, ACCESS-ESM1-5,
   CNRM-CM6-1 also have SSP3-7.0. Wait for more combinations before ensemble analysis.
3. **Bias correction** — CMIP6 must be bias-corrected against IMD before use.
   The R `ncdf4` package can read both formats; no Python NetCDF reader here.
4. **GRACE/GRACE-FO** — not found; required only for independent storage validation.
5. **Claim volume convention** — see Section 1.
6. **Regulation status** — whether gauge 4026 flows are natural or regulated is
   not documented in the files found. If regulated, μ is managed supply and must
   include release/diversion records.

## 6. Original file contracts (unchanged, for reference)

```text
IMD extract      : date, rainfall_mm, tmax_c, tmin_c
CWC extract      : date, discharge_m3s
CMIP6 extract    : date, pr_mm, tas_c, model, ssp  (bias-corrected)
GRACE extract    : date, twsa_cm
Crop/calendar    : year, district, crop, area_ha, sowing_doy, harvest_doy
```

`paper1/src/data_pipeline.py` still specifies `load_imd`, `load_cwc`,
`load_cmip6`, `load_grace` as unimplemented. The R scripts bypass them for the
CAMELS-India pilot; the Python loaders remain for the future CMIP6 stage.
