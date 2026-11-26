# HELP — run the study, find the data, read the outputs

This is the operator's manual. It is intentionally short: one study, three
commands, one output folder.

---

## 1. What the study does

It tests whether a **deficit queue** adds drought information beyond SSI-3, using
the **same method** in India and the USA. The target is the catchment's own
**SPEI-3** (precipitation minus Hargreaves ET0), not a district product and not a
reservoir record.

---

## 2. Requirements

- R 4.5+.
- Packages: `data.table`, `ggplot2`, `rmarkdown`, `knitr`.
  Install missing packages with:
  ```powershell
  Rscript -e "install.packages(c('data.table','ggplot2','rmarkdown','knitr'))"
  ```

---

## 3. Data locations

All paths are in `R/config.R` and can be overridden with environment variables.

```text
D:\Datasets\
  CIMP6_India\data_raw\camels_ind_forcings\
    catchment_mean_forcings\        # one CSV per gauge: prcp, tmax, tmin, tavg
    streamflow_timeseries\streamflow_observed.csv
    attributes_csv\                 # cwc_area, basin, lat/lon
  Caravan_2025\
    attributes\camels\              # area, lat/lon
    timeseries\camels\              # streamflow, prcp, tmax, tmin, tmean
```

The study uses **no district polygon, no soil-moisture product, no US Drought
Monitor and no reservoir data**. The map in `figures/fig_study_map.pdf` uses
the Drought Intelligence Explorer outline and state boundaries for India and
state polygons for the conterminous USA; it is a figure input only.

---

## 4. Run

From the repository root:

```powershell
Rscript R/verify.R      # 15 checks; all must pass
Rscript R/study.R       # both regions; writes output/*.csv
Rscript R/figures.R     # writes figures/*.png and *.pdf
Rscript -e "rmarkdown::render('MANUSCRIPT.Rmd')"   # the paper PDF
```

`R/study.R` is linear: load -> rates -> screen -> queue -> target -> fit ->
paired comparison. It prints progress. A per-gauge failure is caught and written
to the fit meta; a pipeline failure stops the run.

---

## 5. Outputs

| File | Contents |
|---|---|
| `output/india_screen.csv` | every India gauge: rho, zero fraction, gap, coverage, in/out |
| `output/usa_screen.csv` | same for the USA |
| `output/india_fit_meta.csv` | India event counts and fit status |
| `output/usa_fit_meta.csv` | same for the USA |
| `output/india_paired.csv` | per-gauge paired Brier/AUC deltas, SPEI-3 target |
| `output/usa_paired.csv` | same for the USA |
| `output/india_paired_spi3.csv` | same, SPI-3 sensitivity target |
| `output/usa_paired_spi3.csv` | same for the USA |
| `output/region_summary.csv` | regional medians, CIs, sign tests (both targets) |
| `output/region_difference.csv` | USA minus India, bootstrap CI (both targets) |

Each CSV carries a `.json` sidecar with the git hash, code hash, row/column
counts and the R session.

Generated files are **never** hand-edited. Every value in the paper comes from
these CSVs.

---

## 6. Parameters

All in `R/config.R`, one place:

| Parameter | Value | Meaning |
|---|---:|---|
| `d_mm` | 20 | claim depth (mm) |
| `phi` | 0.7 | effective-rain fraction |
| `Kc` | 0.8 | crop coefficient (both regions) |
| `f_irr` | 0.10 | irrigated fraction of catchment |
| `s_firm` | 0.5 | firm share of observed flow |
| `cap_mm` | 10 | infrastructure cap (mm/day) |
| `q_days` | 60 | `q* = ceil(60 * lambda_bar)` |
| `K_days` | 365 | capacity in days of mean demand |
| `theta_mult` | 1.5 | `theta = ceil(1.5 * q*)` |
| `alpha` | 1.5 | service boost above theta |
| `eta` | 1/60 | reneging rate (per day) |
| `rho_window` | 0.15–1.20 | utilisation screen |
| train / test | 1981–2010 / 2011–2020 | split |
| `L2` | 1.0 | ridge penalty |
| `seed` | 20261125 | all stochastic steps |

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| `package 'data.table' was built under R version ...` | Warning only; ignore. |
| `cannot open file ...` | Check the data paths in `R/config.R` or set `QDJ_DATA_ROOT`. |
| A region selects 0 gauges | Check `rho_window` and the zero/gap screen in `*_screen.csv`. |
| A gauge is skipped | The blocking guard tripped or too few events; it is recorded in the fit meta. |
| Figure is empty | Run `R/study.R` first; `R/figures.R` reads `output/`. |

---

## 8. Reading order

1. `README.md` — the design in one page.
2. `HELP.md` — this file.
3. `MANUSCRIPT.Rmd` / `MANUSCRIPT.pdf` — the paper, in fragment form.
4. `STUDY.Rmd` — data, methods and results in one technical document.
5. `R/config.R` — every parameter.
6. `R/study.R` — the pipeline, top to bottom.
7. `R/functions/` — the verified engine and evaluation functions.
8. `AGENTS.md` — operating rules and the frozen novelty sentence.
9. `P01/literature_audit.md` — the literature evidence.

---

## 9. What this study does not do

- No district soil-moisture target.
- No US Drought Monitor target.
- No reservoir operations or OpenET.
- No future-climate scenario; CMIP6 remains out of scope.
- No claim that the queue beats SPI/SSI; the result is reported as it is.
