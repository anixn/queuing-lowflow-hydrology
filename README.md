# Storage-deficit states for seasonal drought and low-flow forecasting

**Study P1 of the pivot (`PIVOT.md`):** does a *recession-calibrated
storage-deficit state* — estimated from the catchment's own recession
behaviour and driven by a mass-balance-verified fluid water balance — improve
probabilistic forecasts of **hydrological drought and low-flow events** at
**1, 3 and 6-month leads**, beyond what lagged standard indices, persistence
and an antecedent precipitation index already carry?

- **India (CAMELS-IND, 472-catchment large sample) is the study.**
- **USA (Caravan-US) runs the identical protocol as a declared transfer
  check** — never as a cross-region contrast.

## Why the pivot (one paragraph)

The retired deficit-queue study (see `AGENTS.md` §1, `PIVOT.md` §1) produced a
trustworthy null: +0.002 Brier over SSI-3 (1–3 % relative) with an
unresolvable India arm (n = 12 of 472). An external expert review diagnosed
three design causes — no information beyond the benchmark's own predictors,
the wrong queue class (M/M/1/K artefacts on a fluid process), and a
utilisation screen that selected on assumed constants — and a full redesign
followed (`PIVOT.md`). The queue's artefact parameters (reneging, service
boost, blocking) are gone on the forecasting path; the state is millimetres of
catchment storage; the demand envelope is measured where the dataset measures
it; every threshold, screen, standardisation and fit uses training years
(1981–2010) only, and test years are touched once, at scoring.

## The study in one table

| Element | Rule |
|---|---|
| Unit | gauge catchment; storage state `S` in mm of depth |
| Engine | fluid balance `S' = clip(S + Pe − Ea − Q_g, 0, S_cap)`, per-day ledger ±1e−9 |
| Fitted per gauge | baseflow index, recession constant `k`, exponent `p`, release coefficient `K_a`, storage scale `S_cap` (training years only) |
| Targets | **T1: SSI-3 ≤ −1 (confirmatory)**; T2: monthly mean flow < training Q90 (descriptive) |
| Leads | 1, 3, 6 months, strictly prospective (issue `t` → target `t+h`) |
| Split | train 1981–2010 (features from 1982 after warm-up), test 2011–2020 |
| Families | climatology, persistence, lagged indices (SPI/SSI-3/6), API, **storage**, **storage+indices (confirmatory)** |
| Headline | Brier skill score vs climatology; paired per-gauge deltas on identical months; two-level block bootstrap |

## Files

```text
R/
  config.R              paths, seeds, all parameters (P, P1_* blocks)
  functions/
    queue_engine.R      frozen verified CTMC (Study P3 only; not on the P1 path)
    demand_envelope.R   measured demand envelope in claims/day (Study P3 only)
    storage_engine.R    BFI, recession fits, S_cap inversion, fluid propagator
    units.R             the unit wall (mm-day; seasonal Kc/phi curves)
    pipeline.R          daily prep, screen, indices, fit, paired statistics
    indices/eval/io/audit.R
  study_p1.R            the P1 backbone: India primary + US transfer arm
  paired_analysis_p1.R  equivalence test + paired skill benchmark
  attr_analysis_p1.R    catchment attributes vs skill (descriptive)
  kclass_exploratory.R  labelled post-hoc k-class cut
  novelty_p1_screen.R   rapid Crossref/OpenAlex P1 prior-art screen
  figures_p1.R          P1 figures
  figures_p1_finding.R  the three argument figures (memory, skill, equivalence)
  figures_p1_grid.R     the two summary plates (whole argument, basin grid)
  figures_paper01.R     paper01 figures (Fig01-Fig07)
  tables_paper01.R      paper01 tables
  verify.R              23-check verification battery
paper01/                the paper package (see paper01/README.md):
                        manuscript, technical document, figures, tables,
                        output (the study's results), literature audit
PIVOT.md                the pivot decision, gate tables, change record
README.md               this file
HELP.md                 operator's manual
```

## Run

From the repository root:

```powershell
Rscript R/verify.R          # 23/23 checks (gate G1)
Rscript R/study_p1.R        # the P1 study (India + US transfer arm)
Rscript R/figures_p1.R      # P1 figures
```

Knit the paper package (technical document and manuscript):

```powershell
Rscript -e "rmarkdown::render('paper01/STUDY.Rmd')"
Rscript -e "rmarkdown::render('paper01/MANUSCRIPT_Paper01.Rmd')"
```

## Result

**Gate G2 (recorded 26 Nov 2026): NULL** — the corrected queue *loses* to the
honest memory baselines (USA median ΔBrier −0.0059 [−0.0187, +0.0026], sign
25/60); the retired design's null is now trustworthy. The gate's code and
result files were removed from the working tree with the retired study; the
record stands in `PIVOT.md` §3 and in git history.

**Study P1 (scored 26 Nov 2026; lead extension and equivalence added 27 Nov
2026):** the pre-registered H0-parity at 1 month is confirmed exactly as
predicted; the confirmatory contrasts **H1 (3 month) and H2 (6 month) FAIL**.
The null is **bounded, not unresolved**: at all five leads (1, 2, 3, 6, 12
months) the 90 % interval of the paired difference lies inside the declared
harm bound of ±0.005 Brier, so any gain is smaller than the smallest change an
operator would act on (`paper01/output/p1_equivalence.csv`). What the study
delivers instead is the **India-wide lead-time ceiling**: Brier skill score vs
climatology falls from about 0.50 at one month to 0.23, 0.07, 0.02 and 0.01 at
two, three, six and twelve months, measured on one common sample across 231
catchments (`paper01/output/p1_bss_paired.csv`). The mechanism is measured:
median recession constant about 9 days, so the state holds a few per cent of
its memory at one month and none beyond (`paper01/output/p1_storage_params.csv`).
The centre of gravity moves to Study P3 (climate-projection queue reliability),
per the absolute falsifier frozen in `PIVOT.md` §4.10.
Full tables: `paper01/STUDY.html`.

## Data

- **India:** CAMELS-IND, 472 gauges (Mangukiya et al., 2025, *ESSD*,
  doi:10.5194/essd-17-461-2025). Forcings include GLEAM PET (`pet_gleam`) and
  the attributes include a measured irrigated fraction (`irrigation_frac`).
- **USA:** Caravan (Kratzert et al., 2023, *Scientific Data*,
  doi:10.1038/s41597-023-01975-w). Streamflow is **mm/day** (Caravan's own
  unit, declared in the code). PET is the FAO Penman–Monteith column where
  the release ships it; where it ships only the ERA5
  `potential_evaporation_sum` (a different quantity), the arm runs the
  declared Hargreaves fallback — it never substitutes ERA5 PE for PET.

Both are read from local paths defined in `R/config.R`; no data are copied
into this repository.
