# HELP — run the study, find the data, read the outputs

This is the operator's manual for Study P1 (the pivot). It is intentionally
short: one study, a handful of commands, one output folder. The pivot decision
and all gate tables live in `PIVOT.md`; the operating rules live in
`AGENTS.md`.

**Writing or editing the paper?** Start with
`paper01/SUMMARY_FOR_EDITING.md`: it gives the plain-language version of what
was tested, every number the manuscript quotes, which file holds it, and the
order in which to rebuild after a change.

---

## 1. What the study does

It tests whether a **recession-calibrated storage-deficit state** improves
probabilistic forecasts of **hydrological drought** (SSI-3 ≤ −1) and
**low-flow** (monthly mean below the training-period Q90) events at **1, 3 and
6-month leads**, beyond persistence, lagged standard indices and an
antecedent precipitation index. The state is a millimetre-depth storage
propagated by a fluid water balance whose release law is fitted to each
catchment's own training-year recessions. There are no queue artefacts, no
claims and no hectares on this path.

**Gate G2** was the corrected re-run of the retired queue design with dataset
PET, the measured irrigated fraction, training-only thresholds and honest
memory baselines; it converted the old null into a trustworthy null. The gate
closed on 26 November 2026 (**NULL RECORDED**). Its script and result files
were removed from the working tree with the retired study on 27 November 2026;
the decision and its numbers are in `PIVOT.md` §3 and in git history.

---

## 2. Requirements

- R 4.5+.
- Packages: `data.table`, `ggplot2`, `rmarkdown`, `knitr`, `sf`, `patchwork`.
  Install missing packages with:
  ```powershell
  Rscript -e "install.packages(c('data.table','ggplot2','rmarkdown','knitr','sf','patchwork'))"
  ```

---

## 3. Data locations

All paths are in `R/config.R` and can be overridden with environment
variables (`QDJ_DATA_ROOT`, `QDJ_CAMELS_ROOT`, `QDJ_CARAVAN_ROOT`,
`QDJ_DIE_ROOT`).

```text
D:\Datasets\
  CIMP6_India\data_raw\camels_ind_forcings\
    catchment_mean_forcings\        # one CSV per gauge: prcp, tmax/tmin/tavg,
                                    # pet_gleam (GLEAM PET)  <- dataset PET
    streamflow_timeseries\streamflow_observed.csv
    attributes_csv\                 # cwc_area, basin, lat/lon, climate,
                                    # anth (irrigation_frac), land, hydro
  Caravan_B\
    attributes\camels\              # area, lat/lon (CSV or XLSX)
    timeseries\camels\              # streamflow (mm/day), prcp, tmax/min/mean,
                                    # potential_evaporation_sum (ERA5 PE) and,
                                    # where the release ships it, the
                                    # FAO-PM PET column the study prefers
```

The study uses **no district polygon, no soil-moisture product, no US Drought
Monitor, no reservoir record and no raw CMIP6 output**. The map figure uses
the Drought Intelligence Explorer outline/state boundaries for India; figure
input only.

---

## 4. Run

From the repository root:

```powershell
Rscript R/verify.R          # 23/23 checks (gate G1); required before any run
Rscript R/study_p1.R        # Study P1 (India + US transfer arm; p1_*.csv)
Rscript R/kclass_exploratory.R   # labelled post-hoc k-class cut
Rscript R/figures_p1.R      # P1 figures
Rscript -e "rmarkdown::render('paper01/STUDY.Rmd')"
Rscript -e "rmarkdown::render('paper01/MANUSCRIPT_Paper01.Rmd')"
```

PET source and the US transfer arm are environment switches:

```powershell
$env:QDJ_PET_SOURCE   = "shipped"    # or "hargreaves" (sensitivity arm)
$env:QDJ_TRANSFER_ARM = "on"         # or "off"
```

Input roots can be overridden without touching `R/config.R`:

```powershell
$env:QDJ_CAMELS_ROOT  = "D:\Datasets\CAMELS-IND\CAMELS_IND_All_Catchments"
$env:QDJ_CARAVAN_ROOT = "D:\Datasets\Caravan_B"
```

**PET on the transfer arm.** The code prefers the FAO Penman–Monteith column
(`potential_evaporation_sum_FAO_PENMAN_MONTEITH`). When a Caravan release
ships only the ERA5 `potential_evaporation_sum`, that column is *not* used as
PET (it is a different, much larger quantity); the arm falls back to
Hargreaves from temperature and latitude and prints which source it used.

---

## 5. Outputs

Everything is written to `paper01/output/`. Every CSV carries a JSON sidecar
(git hash, code hash, seed, shape, R session).

| File | Written by | Contents |
|---|---|---|
| `p1_sample_report{,_usa}.csv` | P1 | n per screen stage (§4.2) |
| `p1_storage_params{,_usa}.csv` | P1 | per-gauge `(k, p, a, K_a, b_s, S_cap, BFI)` |
| `p1_bss{,_usa}.csv` | P1 | per gauge × family × lead × target BSS |
| `p1_paired{,_usa}.csv` | P1 | per-gauge paired deltas |
| `p1_summary{,_usa}.csv` | P1 | medians, bootstrap CIs, sign tests |
| `p1_confirmatory.csv` | P1 | H1/H2 (+H0) decision table |
| `p1_predictions{,_usa}.csv` | P1 | held-out predictions (large; regenerable, untracked) |
| `p1_bss_by_kclass.csv` | exploratory | labelled post-hoc k-class cut |

The retired study's numbers and backbone live in **git history only**; the
Gate G2 decision is recorded in `PIVOT.md` §3. The sign-test power curve was
withdrawn on 27 November 2026 (see the §4.2 amendment in `PIVOT.md`).

---

## 6. Figures

Written to `paper01/figures/`.

| Figure | Content |
|---|---|
| `fig_p1_map` | sample by screen stage across India |
| `fig_p1_leadtime` | **centrepiece**: median BSS vs lead per family |
| `fig_p1_paired` | per-gauge paired deltas by lead |
| `fig_p1_storage` | recession/storage landscape (k vs S_cap, colour BFI) |
| `fig_p1_state` | the fluid state S(t) for one example catchment |
| `fig_p1_reliability` | pooled reliability curves (T1, 3-month lead) |

---

## 7. Troubleshooting

- **`V17`-`V21` fail** — the storage engine changed without its test; fix the
  engine, not the test.
- **Blocking-guard errors in Study P3** — the measured demand envelope can
  overload the CTMC for some gauges; catch them per gauge and record the
  exclusion. (Nothing on the P1 path runs the CTMC.)
- **A gauge missing from `p1_*` outputs** — it failed a screen stage; the
  reason is in `p1_sample_report.csv` (`pass_complete`, `pass_events_*`,
  `pass_recession`, `borrowed_parameters`).
- **Long runtimes** — `study_p1.R` propagates a daily state and fits ~6
  families × 3 leads × 2 targets per gauge for several hundred gauges;
  expect tens of minutes per region on a workstation.

---

## 8. Session checklist (from `AGENTS.md` §9)

1. State the current gate (G2 / P1 / P3) and the single next action.
2. `Rscript R/verify.R` — report pass/fail (must be 21/21).
3. State which numbers you trust today and where they live.
4. End of session: re-run the battery; update the paper trail; report what
   moved, what is blocked, the exact next action.
