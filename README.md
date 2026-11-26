# Queueing–Drought Junction (v2, R rebuild)

This repository tests one question: **does a finite-capacity deficit queue add
drought information beyond climatology, SPI, SPEI and SSI?**

The v1 Python analysis returned a null that was not defensible: it mixed units,
sat in a demand/supply regime where a null was guaranteed, and used a
two-gauge pilot with almost no held-out drought events. v2 is a **full rebuild in
R and R Markdown only**, following `REDESIGN_PLAN_v2_R.md`: one unit system, a
predeclared utilisation screen, a multi-catchment design, a locked protocol, an
exact verification battery, and every sensitivity axis reported.

## What is new in v2

- **Python removed from `main`.** The audited v1 code is preserved on the
  `legacy-python` branch and tagged `v1-audited`; nothing is deleted from
  history. All current code is linear R / R Markdown.
- **One claim volume per gauge.** Demand and supply share a single command-area
  claim (`R/00_utils/units.R`); the queue engine only ever sees claims/day.
- **Catchment-relative thresholds** (`q*`, `K`, `theta`) instead of absolute
  counts, so gauges are comparable.
- **Utilisation screen.** Gauges are admitted only when
  `0.15 <= rho = sum(lambda)/sum(mu) <= 1.20`, fixing the v1 regime defect.
- **Multi-catchment.** 24 CAMELS-IND gauges across 11 basins, both split
  periods, at most 3 per basin.
- **Predeclared protocol and power analysis** (`protocol/PROTOCOL_v2.md`), with
  every one-factor-at-a-time sensitivity reported (`R/analysis/sensitivity_grid.R`).
- **Exact engine verification**: 14/14 checks (closed forms, RK4 vs
  discrete-event simulation, conservation ledger, unit wall, gap rules).

## Outcome (updated 26 November 2026)

The predeclared confirmatory Brier endpoint is **null**: the paired per-gauge
improvement from adding queue probability to SSI-3 has a median of about
`+0.0020` with a two-level bootstrap 95% interval that includes zero. The
leakage-clean SPI-3 target is **positive** on the kharif demand model, but a
like-for-like India–US common protocol (same `Kc`, SUP-1, SPI-3 target, same
split) **removes the effect in both regions** (India −0.0003, USA +0.0004;
difference CI includes zero). The positive is therefore target- and
demand-model-dependent, not a general queue advantage. The US reservoir pilot is
an **exploratory replication**, null on both Brier and AUC with the window
applied. The outcome is **Path B (honest null)** with a fragile,
target-dependent secondary signal and a utilisation diagnosis.

## Run it (from the repository root)

```powershell
Rscript steps/run_all_steps.R            # India baseline + USA + figures + verification
Rscript steps/run_all_steps.R --full     # also the long India sensitivity grid
Rscript steps/step_12_verify.R           # 14/14 engine + unit + gap tests
```

`HELP.md` is the operator's manual: every step, input, output, credential and
troubleshooting note. The numbered scripts in `steps/` are the executable
sequence; the matching R Markdown documents are in `steps/rmd/`.

`output/_recon_gauge_stats.csv` is the committed one-time gauge-profiling table;
`Rscript R/analysis/recon.R` regenerates it only with `--force` (the frozen table
defines the analysis set, so a regeneration must be checked against
`output/selected_gauges.csv`).

`output/` and `figures/` are generated; never hand-edit them. Every CSV carries
a JSON sidecar with the git hash, parameters, seed and R session.

## Manuscript

| File | Contents |
|---|---|
| `manuscript/MANUSCRIPT.md` | Full HESS-style draft: literature, hypothesis, data, LaTeX methods, results, India–USA comparison, discussion |
| `manuscript/_draft_literature.md` | Extended literature review (audited references only) |
| `manuscript/_draft_methods.md` | Extended data and methods draft |
| `manuscript/figures/` | Figure index / copies for the manuscript build |

## Repository map

| Path | Purpose |
|---|---|
| `R/config.R` | **The only place** for paths, seeds and scientific parameters |
| `R/00_utils/` | Unit wall, queue engine, indices, metrics, IO, audit, pipeline |
| `R/verify/` | 14-test verification battery (gate G1) |
| `R/run_pipeline.R` | Single compute backbone for stages S2–S7 |
| `R/analysis/` | Power, sensitivity grid, publication figures, slope statistics |
| `R/us_pilot/` | USA reservoir-centric data assembly and evaluation |
| `R/compare/` | Like-for-like India–US common-protocol comparison |
| `R/10_data/ … R/50_future/` | R Markdown notebooks (documentation + assertions) |
| `HELP.md` | Operator's manual: data, steps, outputs, troubleshooting |
| `steps/` | Numbered executable sequence (India then USA) |
| `steps/rmd/` | Step-level R Markdown documents |
| `manuscript/` | HESS draft, extended literature/methods, figure index |
| `protocol/PROTOCOL_v2.md` | Locked protocol with timing disclosure |
| `protocol/COMMON_PROTOCOL.md` | Common rules for the like-for-like India–US comparison |
| `protocol/REDESIGN_PLAN_v2_R.md` | Governing plan (committed for external verification) |
| `protocol/CHANGELOG.md` | Dated amendments, including the audit response |
| `output/` | Generated CSVs + `.json` sidecars (regenerable) |
| `figures/` | Generated PDF + 300-dpi PNG figures |
| `analysis/P02_methods/RESULTS_v2.md` | Assembled v2 results (numbers referenced, not retyped) |
| `analysis/P02_methods/US_PILOT_RESULTS.md` | Exploratory US reservoir pilot results |
| `P01/`, `analysis/P01_literature/` | Literature audit, frozen gap sentence, search trail |
| `docs/project/` | Plan, protocol history, session log |

## Reading order

1. `START_HERE.md` — plain-language orientation and current phase.
2. `PLAN_SUMMARY.md` — one-page plan, result and next actions.
3. `HELP.md` — how to run the numbered sequence.
4. `manuscript/MANUSCRIPT.md` — the reframed HESS draft.
5. `protocol/PROTOCOL_v2.md` — the pre-specified design, with timing disclosure.
6. `AGENTS.md` — operating rules, frozen novelty sentence, verification protocol.
7. `analysis/P02_methods/RESULTS_v2.md` and `US_PILOT_RESULTS.md` — results with sources.
8. `docs/project/MERGED_PAPER_PLAN.md` — outcome-contingent paper framing.

## The frozen novelty sentence

The scoped gap sentence (frozen 21 November 2026) is unchanged by the rebuild.
It states only what these databases and screens did **not** contain. It never
says "no such study exists" and never uses "first", "novel" or "unique" about
the junction itself. See `AGENTS.md` §2.

## Requirements

R 4.5+, with `data.table`, `ggplot2`, `sf`, `rmarkdown`, `knitr`, `jsonlite`,
`lubridate`. Run `Rscript R/install_packages.R` to install any that are missing.
`renv` is not installed in this environment; a lockfile is a known pending
deliverable, and `R/install_packages.R` is the documented fallback.
