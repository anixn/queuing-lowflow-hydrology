# HELP — how to run, read and extend this project

This file is the operator's manual. It tells you what the project does, where
the data live, how to run it in order, and where every output comes from.

---

## 1. What this project is

A predeclared, multi-catchment test of whether a **finite-capacity deficit
queue** adds drought information beyond standard indices (SSI-3, SPI-3, SPEI-3,
climatology).

Two independent studies are included:

| Study | Unit | Data | Target |
|---|---|---|---|
| **India** | 24 CAMELS-IND gauges, 11 basins | CAMELS-IND flow/forcing + Drought Intelligence Explorer | district soil-moisture anomaly ≤ −15% |
| **USA** | 50 reservoir–catchment pairs | Caravan-US + ResOpsUS + USDM | county DSCI ≥ 100 (D1+) |

Both return the same qualitative result: **no calibrated-probability gain from
adding queue indicators to SSI-3; a small ranking (AUC) gain.** The paper is a
methods + negative-result contribution with a utilisation diagnosis (Path B).

---

## 2. Requirements

- R 4.5+.
- Packages: `data.table`, `ggplot2`, `sf`, `rmarkdown`, `knitr`, `jsonlite`,
  `lubridate`, `rnaturalearth`, `maps` (optional: `patchwork`).
- Install missing packages:
  ```powershell
  Rscript R/install_packages.R
  ```

`renv` is not installed in this environment; the lockfile is a known gap.

---

## 3. Data layout

Paths are defined in `R/config.R` and can be overridden with environment
variables (`QDJ_DATA_ROOT`, `QDJ_CAMELS_ROOT`, `QDJ_DROUGHT_ROOT`, ...).

```text
D:\Datasets\
  CIMP6_India\data_raw\camels_ind_forcings\   # CAMELS-IND flow + forcing + attributes
  Drought_Intelligence_Explorer_v2\...\data\  # SMA / SPI-3 / SPEI-3 / districts
  Caravan_2025\                               # Caravan-US (and 6 other regions)
  ResOpsUS\extracted\ResOpsUS\                # reservoir attributes + daily series
  US_boundaries\                              # US county boundaries (for USDM)
```

Expected extracts:

```text
IMD      : date, rainfall_mm, tmax_c, tmin_c
CWC      : date, discharge_m3s
CMIP6    : date, pr_mm, tas_c, model, ssp   (bias-corrected only)
GRACE    : date, twsa_cm
Crop     : year, district, crop, area_ha, sowing_doy, harvest_doy
```

---

## 4. Quick start

From the repository root:

```powershell
Rscript steps/run_all_steps.R
```

This runs the baseline sequence (India baseline, USA, figures, verification).
For the full India sensitivity grid (long, ~1–2 h):

```powershell
Rscript steps/run_all_steps.R --full
```

Individual steps are listed in §5.

---

## 5. The numbered sequence

| Step | Script | What it does | Main outputs |
|---|---|---|---|
| 00 | `steps/step_00_setup.R` | Check R, packages, data paths, create dirs | readiness report |
| 01 | `steps/step_01_india_recon.R` | Profile CAMELS-IND gauges (non-destructive) | `output/_recon_gauge_stats.csv` |
| 02 | `steps/step_02_india_pipeline.R` | India S2–S7: inventory → fit → meta | `output/*.csv` + sidecars |
| 03 | `steps/step_03_india_power.R` | Power / minimal detectable effect | `output/power_analysis.csv` |
| 04 | `steps/step_04_india_sensitivity.R` | Predeclared one-factor grid (long) | `output/sensitivity_*.csv` |
| 05 | `steps/step_05_india_figures.R` | India figures | `figures/fig01…fig06` |
| 06 | `steps/step_06_usa_screen.R` | Caravan-US screening | `output_us/caravan_us_screen.csv` |
| 07 | `steps/step_07_usa_match.R` | ResOpsUS ↔ Caravan match; reservoir core | `output_us/resops_caravan_match.csv`, `reservoir_core.csv` |
| 08 | `steps/step_08_usa_target.R` | County FIPS + USDM target (OpenET optional) | `output_us/usdm_monthly.csv` |
| 09 | `steps/step_09_usa_rates.R` | Reservoir λ, μ, K; queue run | `output_us/reservoir_*.csv` |
| 10 | `steps/step_10_usa_eval.R` | Paired SSI-3 vs SSI-3+queue | `output_us/us_*.csv` |
| 11 | `steps/step_11_manuscript_figures.R` | Workflow, map, comparison, diagnosis | `figures/fig_*.png/pdf` |
| 12 | `steps/step_12_verify.R` | 14-check engine battery (G1) | console report |

Every step stops the run on failure.

---

## 6. Function library (`R/`)

| File | Role |
|---|---|
| `R/config.R` | **The only place** for paths, seeds and scientific parameters |
| `R/00_utils/units.R` | Unit wall: one claim volume per gauge/reservoir |
| `R/00_utils/queue_engine.R` | CTMC, stationary, RK4, DES, first passage, ledger |
| `R/00_utils/indices.R` | SPI-3, SPEI-3, SSI-3, standardization |
| `R/00_utils/eval.R` | Brier, AUC, log loss, reliability, bootstrap, sign test |
| `R/00_utils/io.R` | Data readers and provenance sidecars |
| `R/00_utils/audit.R` | Zero-flow classification and gap rules |
| `R/00_utils/pipeline.R` | India stages S2–S7 as functions |
| `R/00_utils/notebook_setup.R` | Shared Rmd bootstrap and assertions |
| `R/run_pipeline.R` | India compute backbone |
| `R/analysis/` | Power, sensitivity, figures, manuscript figures |
| `R/us_pilot/` | USA data assembly, rates, evaluation |
| `R/verify/` | 14-check verification battery |

---

## 7. Output map

| Path | Contents |
|---|---|
| `output/` | India result CSVs + JSON sidecars; `output/notebooks/` rendered docs |
| `output_us/` | USA result CSVs (+ logs) |
| `figures/` | All publication figures (PDF + 300-dpi PNG) |
| `manuscript/` | Manuscript draft, literature review, methods, tables |
| `protocol/` | Locked protocol and changelog |
| `analysis/P02_methods/` | Assembled results (India and USA) |

Generated files must **never** be hand-edited. Every CSV carries a JSON sidecar
with the git hash, parameters, seed and R session.

---

## 8. Changing parameters

All scientific parameters live in `R/config.R` (`P`). Do not hardcode a
parameter elsewhere. After changing a parameter, rerun from step 02 (or step 09
for the USA) and record the change in `protocol/CHANGELOG.md` if it touches a
confirmatory endpoint.

---

## 9. Credentials (OpenET)

OpenET is **optional** and used only to validate the crop-coefficient demand
model over 2016–2020. Set the key in the environment, never in a tracked file:

```powershell
$env:OPENET_API_KEY = "<your-key>"
Rscript R/us_pilot/05_openet_extract.R
```

The free OpenET account has a monthly request limit. If the API returns
`Monthly request limit has been reached`, wait until 00:00 UTC on the 1st of the
next month, or use WaPOR/GLEAM as keyless alternatives. The API key is not
committed; `.gitignore` excludes `.env` and local credentials.

---

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `package 'data.table' was built under R version 4.5.3` | Benign version warning; scripts still run. |
| `Missing output/... — run stage X first` | Run the numbered step in order. |
| `Conservation ledger failed` | A numerical or unit error; do not ignore. Re-run the verification battery. |
| OpenET `HTTP 404` with a quota message | Monthly quota exhausted; wait for reset or use WaPOR. |
| `sf` point-in-polygon returns no match | Reservoir is outside the Caravan polygon; the script records the nearest catchment and distance. |
| `renv` missing | Documented gap; use `Rscript R/install_packages.R`. |

---

## 11. Reproducibility

- `Rscript steps/step_12_verify.R` runs the 14-check battery; all must pass.
- Seeds: `P$seed = 20261125` for every stochastic step.
- Every output has a `.json` sidecar (git hash, parameters, seed, session).
- The India sensitivity grid is one-factor-at-a-time; interactions are not swept.
- The confirmatory statistic is **paired** on identical held-out months; per-family
  metrics on different samples are descriptive only.

---

## 12. Reading order

1. `START_HERE.md` — plain-language orientation.
2. `README.md` — rebuild summary.
3. `manuscript/MANUSCRIPT.md` — the paper draft.
4. `protocol/PROTOCOL_v2.md` — the locked predeclared protocol.
5. `analysis/P02_methods/RESULTS_v2.md` and `US_PILOT_RESULTS.md` — results with sources.
6. `docs/project/SESSION_LOG_v2.md` — gate reports.

---

## 13. Citation

If you use this code, cite the manuscript and the underlying datasets:
CAMELS-IND (Mangukiya et al., 2025, *ESSD*, doi:10.5194/essd-17-461-2025),
Caravan (Kratzert et al., 2023, *Scientific Data*,
doi:10.1038/s41597-023-01975-w), ResOpsUS (Steyaert et al., 2022,
doi:10.1038/s41597-022-01134-7), USDM (NDMC/NOAA/USDA), and the Drought
Intelligence Explorer (Deshmukh, 2026, doi:10.5281/zenodo.24444860).
