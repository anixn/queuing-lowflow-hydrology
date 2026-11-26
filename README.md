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
    queue_engine.R      frozen verified CTMC (reused by Study P3)
    storage_engine.R    BFI, recession fits, S_cap inversion, fluid propagator
    units.R             the unit wall (mm-day; seasonal Kc/phi curves)
    pipeline.R          screens, indices, families, paired statistics
    indices/eval/io/audit.R
  study_gate_g2.R       Gate G2: corrected re-run + decision (record)
  study_p1.R            the P1 backbone: India primary + US transfer arm
  power_check.R         sign-test power curve from the G2 variance
  kclass_exploratory.R  labelled post-hoc k-class cut
  figures_p1.R          P1 figures
  verify.R              22-check verification battery
PIVOT.md                the pivot decision, gate tables, change record
STUDY.Rmd               technical document: data, methods, results
MANUSCRIPT.Rmd          paper fragment, knits to MANUSCRIPT.pdf
README.md               this file
HELP.md                 operator's manual
P01/, analysis/         literature-audit evidence records (frozen)
output/                 generated CSVs + JSON provenance sidecars
figures/                generated figures
```

## Run

From the repository root:

```powershell
Rscript R/verify.R          # 21/21 checks (gate G1)
Rscript R/study_gate_g2.R   # Gate G2 (corrected re-run of the retired design)
Rscript R/study_p1.R        # the P1 study (India + US transfer arm)
Rscript R/power_check.R     # power analysis from the G2 variance
Rscript R/figures_p1.R      # P1 figures
```

Knit the technical document / paper:

```powershell
Rscript -e "rmarkdown::render('STUDY.Rmd')"
Rscript -e "rmarkdown::render('MANUSCRIPT.Rmd')"
```

## Result

**Gate G2 (recorded 26 Nov 2026): NULL** — the corrected queue *loses* to the
honest memory baselines (USA median ΔBrier −0.0059 [−0.0187, +0.0026], sign
25/60); the retired design's null is now trustworthy
(`output/gateG2_summary.csv`).

**Study P1 (scored 26 Nov 2026, once, under the frozen protocol):** the
pre-registered H0-parity at 1-month lead is confirmed exactly as predicted;
the confirmatory contrasts **H1 (3-month) and H2 (6-month) FAIL** — the
recession-calibrated storage state adds no skill beyond lagged indices and
persistence for Indian catchments (`output/p1_confirmatory.csv`). What the
study delivers instead is the **first India-wide lead-time skill benchmark**:
BSS vs climatology of 0.42–0.50 at 1 month collapsing to 0.01–0.08 at 3 and
≤ 0.02 at 6 months across 231 catchments, with the US transfer arm scored on
639 gauges. The centre of gravity moves to Study P3 (climate-projection
queue reliability), per the absolute falsifier frozen in `PIVOT.md` §4.10.
Full tables: `STUDY.html`.

## Data

- **India:** CAMELS-IND, 472 gauges (Mangukiya et al., 2025, *ESSD*,
  doi:10.5194/essd-17-461-2025). Forcings include GLEAM PET (`pet_gleam`) and
  the attributes include a measured irrigated fraction (`irrigation_frac`).
- **USA:** Caravan-US (Kratzert et al., 2023, *Scientific Data*,
  doi:10.1038/s41597-023-01975-w), FAO Penman–Monteith PET shipped.

Both are read from local paths defined in `R/config.R`; no data are copied
into this repository.
