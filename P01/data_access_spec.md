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

## 1. Claim convention — revisable working assumption (unlocked 25 November 2026)

Decision recorded in `../START_HERE.md` §4 and applied in both code packages.
**This is a stated assumption, not a calibrated value.** It is written at the
top of `P02/R/01_build_rates.R` and in `src/P01/data_pipeline.py` so it
can be changed in one place.

| Quantity | Value | Physical reading |
|---|---|---|
| Command area | 45,000 ha | Sangli district canal-irrigated area used as a proxy; not gauge-specific |
| Yadgir command-area proxy | 72,252 ha | 14% of 516,088 ha net sown area, rounded; `[assumption]` for gauge 4064, not gauge-specific |
| One claim | 20 mm depth | 9×10⁶ m³ over 45,000 ha; 1.44504×10⁷ m³ over 72,252 ha — a modelling unit, not a measured release |
| Capacity K | 20 claims | 400 mm over either proxy; 1.8×10⁸ m³ for Sangli and 2.89008×10⁸ m³ for Yadgir |
| Service cap | 3 claims/day | 60 mm/day; 2.7×10⁷ m³/day for Sangli and 4.33512×10⁷ m³/day for Yadgir |
| Firm share | 0.5 of streamflow | Dry-season baseflow treated as dependable supply |

Why this scale: 45,000 ha is the canal-irrigated area reported for Sangli in
the official agriculture contingency plan. It is a documented district proxy,
not a gauge-4026 command area. A 20 mm delivery unit preserves readable physical
depths: K=20 remains 400 mm and the service cap remains 60 mm/day. Rescaling the
claim rescales λ, μ and K together, so pilot numbers stay illustrative until
gauge-specific canal/crop records are found. Source and envelope:
`../analysis/claim_convention_2026-11-25/`.

## 2. Pilot regions — revised

The original plan proposed Punjab and Maharashtra. **CAMELS-IND does not
cover the Indus/Punjab**, so that pair is not possible with these files.
Available high-coverage gauges (from `camels_ind_name.csv`):

| Gauge | Name | Basin | Coverage | Basin area |
|---|---|---|---|---|
| 12035 | Mandleshwar | Narmada | 96.13% | — |
| 4026 | Kurundwad | Krishna | 95.54% | 15,190 km² |
| 4064 | Yadgir | Krishna | 95.48% | 69,863 km² |

**Pilot chosen: gauge 4026 (Kurundwad, Krishna, Maharashtra).** It is in the
target state and has the best coverage. Alternative 4064 can be used by
changing one line in `P02/R/01_build_rates.R`.

## 3. Data-quality findings

- Gauge 4026 has 9,710 zero entries among 14,308 non-missing days (67.9%);
  gauge 4064 has 4,596 among 14,299 (32.1%). The CAMELS-IND PDF defines a
  `q_zero` attribute but does not state whether literal zeros are measured
  no-flow days or a coding convention. Treat zero semantics as unresolved.
- Missing streamflow totals 668 days for 4026 and 677 for 4064. The PDF does
  not define the CSV missing-value token; blank fields are observed locally,
  but the official convention remains unknown.
- Gauge 4026 has a 611-day interior gap beginning 1 March 2019; 4064 has a
  661-day trailing gap after 11 March 2019. The new comparison interpolates
  only gaps of seven days or less and flags every filled day. Longer gaps end
  the usable record; both gauges therefore end on 28 February 2019.
- The nominal 2011–2020 test window yields 98 complete months per gauge
  (2011–2018 plus January–February 2019). No trailing flow is extrapolated.
- No crop-area or canal-command records were found. Crop water requirement in
  the R script therefore uses a **district-level proxy** of 45,000 ha and a generic Kc curve;
  it is a pipeline demonstration, not a calibrated irrigation demand.

## 4. What has been built against these files

| Script | Purpose |
|---|---|
| `P02/R/01_build_rates.R` | Read forcing CSV + observed streamflow for one gauge, build daily `lambda`, `mu`, write `P02/data/generated/rates_4026.csv`. |
| `P02/R/02_run_queue.R` | Read that CSV and RK4-solve the finite-capacity CTMC. The legacy indicator summary was removed pending unit/server-accounting correction. |
| `src/P02/real_data_comparison.py` | Two-gauge daily queue, monthly predictors, held-out logistic comparison, bootstrap and sensitivities |
| `src/P02/make_comparison_figure.py` | Render the saved Brier-skill and reliability outputs |

`01_build_rates.R` has been run successfully on gauge 4026. The generated rate
file is retained as a pipeline artifact. The new Python comparison has a
corrected output contract and a complete negative result in
`../analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`; no legacy R indicator
summary is trusted.

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

`src/P01/data_pipeline.py` still specifies `load_imd`, `load_cwc`,
`load_cmip6`, `load_grace` as unimplemented. The R scripts bypass them for the
CAMELS-IND pilot; the Python loaders remain for the future CMIP6 stage.
