---
title: "Research protocol: P01 and P03"
subtitle: "Queue-based drought science — objectives, gates and analysis plans"
author: "Ankit Deshmukh"
date: "21 November 2026"
version: "1.0"
---

# Research protocol: P01 and P03

This file is the organising protocol for the two active papers. It uses the
canonical names **P01** and **P03**. The old labels P1 and P3 still appear in
existing file paths and source files, but they are no longer the preferred
human-facing names.

## 0. Name map

| Canonical name | Old label | Physical folder | Current work product |
|---|---|---|---|
| **P01** | Paper 1 / P1 | `paper1/` | `paper1/P1_draft_v2.md` |
| **P03** | Paper 3 / P3 | `paper3/` | Methods package in `paper3/` |
| Not used | Paper 02 / P2 | — | No such paper is defined in the repository |

The repository defines two papers, P1 and P3, and fixes the order P1 first,
P3 second (`AGENTS.md:21-28`; `START_HERE.md:21-28`). The physical folders stay
as `paper1/` and `paper3/` so the tested Python imports and documented run
commands continue to work (`paper3/src/evaluate_estimators.py:30-35`;
`START_HERE.md:141-152`). The detailed working note is
`APPROACH_P01_P03.md`.

## 1. Phase position

We are in **Phase A: finish the gap hunt** (`AGENTS.md:174-180`;
`START_HERE.md:125-130`). The last database task is the record-level screen of
four Web of Science sets: S4 6 records, S5 66 records, Extra A 8 records and
Extra C 13 records — 93 records in total
(`paper1/scopus_wos_search_plan.md:70-74`). Scopus is complete: 295 records
screened, with no gap-changing record (`paper1/literature_audit.md:88-120`).

The order of gates is fixed:

1. **Gate A:** one dated, scoped gap sentence and keep/drop reasons for every
   retained record (`AGENTS.md:181-182`).
2. **Gate B:** P01 stable — gap sentence frozen, prior art cited, every number
   script-backed (`AGENTS.md:184-190`).
3. **Gate C:** P03 ready — estimator beats climatology on held-out data, or an
   honest null result is written (`AGENTS.md:198-199`).

P03 analysis is prepared here but is not started before Gate B
(`AGENTS.md:28`, `:192`).

## 2. P01 — key objective

**Plain objective:** explain why drought can be read as a queue state, cite the
existing water–queue lineage accurately, and set out tests that can show
whether queue-derived indicators add drought information.

P01 is a review/perspective for *Water Resources Research*
(`NOVELTY_AND_PLAN_REPORT.md:55-70`; `START_HERE.md:21-28`). Its objectives are:

1. Reclaim the historical link between storage theory and queueing, beginning
   with Langbein 1958, rather than presenting that link as ours
   (`paper1/P1_draft_v2.md:74-89`).
2. Map queue quantities to drought quantities: arrivals to demand, service to
   supply, backlog to unmet demand, capacity to a system limit, and reneging to
   abandoned demand (`paper1/P1_draft_v2.md:103-150`).
3. Keep two dual representations separate: stored water as the buffer and
   unmet demand as the backlog (`paper1/P1_draft_v2.md:123-150`).
4. Cite the established hydrology, irrigation, groundwater, runoff and
   reliability literature without overstating the gap
   (`paper1/literature_audit.md:122-174`; `paper1/P1_draft_v2.md:152-187`).
5. Show why time-varying rates matter. As of 21 November 2026, the synthetic
   Box 1 gives 2.130 claims peak E[Q] versus 0.916 claims stationary, a 2.3×
   difference, and peak Pr(Q≥6) of 0.0733 versus 0.0043, a 17× difference
   (`paper1/P1_draft_v2.md:266-292`).
6. State a falsifiable research programme with pre-specified metrics,
   baselines, null-result clause and guardrails
   (`paper1/P1_draft_v2.md:294-347`).

## 3. P01 — analysis protocol

This is a scoping-review protocol, not a full systematic review; the distinction
is already recorded in the audit (`paper1/literature_audit.md:12-18`).

### 3.1 Search and screening

1. Use the exact search strings and interface notes in
   `paper1/scopus_wos_search_plan.md:10-61`.
2. Record for each search: database, interface, date, exact string, filters,
   raw hits, screened count, retained count and exclusion reasons
   (`paper1/scopus_wos_search_plan.md:126-139`).
3. Screen the four pending WoS sets and write one keep/drop reason per record
   in `paper1/literature_audit.md`
   (`paper1/scopus_wos_search_plan.md:70-74`, `:141-148`).
4. Add the required citation-trace seeds: Yang 2019, Harel & Mouche 2014,
   Mouche & Harel 2016 and Prajamwong 1997
   (`AGENTS.md:176-180`; `NOVELTY_AND_PLAN_REPORT.md:225-230`).
5. Full-text screen the retained set and keep the keep/drop table in the audit
   file (`paper1/literature_audit.md:196-204`).

### 3.2 Synthesis

1. Build the concept map from queue term to hydrological meaning and caveat
   (`paper1/P1_draft_v2.md:103-150`).
2. Keep prior-art rows with three columns: representation, what it does, what
   it leaves open (`paper1/P1_draft_v2.md:159-175`).
3. Use only script-backed synthetic numbers. The anchor three-way check is
   exact E[Q] 0.91607 claims, RK4 E[Q] 0.91607 claims and DES time-average
   E[Q] 0.91295 claims, a 0.34% difference on 21 November 2026
   (`AGENTS.md:87-90`; `paper1/README.md:41-49`).
4. Label every pilot number "illustrative, under the stated assumptions"
   (`AGENTS.md:47-52`; `START_HERE.md:87-92`).
5. Do not use raw CMIP6 output in any published number
   (`AGENTS.md:53-55`).

### 3.3 Language and gate check

Search the draft for strong claim words and "no study" phrases; check each
against the scoped, dated gap sentence (`AGENTS.md:30-45`;
`paper1/P1_draft_v2.md:44`, `:349-362`). P01 is stable only when Gate B is met
(`AGENTS.md:189-190`).

## 4. P03 — key objective

**Plain objective:** estimate changing demand and supply rates from data,
verify the estimates against exact mathematics, and test whether queue state
adds drought information beyond standard baselines.

P03 is a methods paper for *Hydrology and Earth System Sciences* later in the
roadmap (`NOVELTY_AND_PLAN_REPORT.md:72-84`; `paper3/README.md:1-11`). Its
objectives are:

1. Estimate λ(t) from demand covariates and μ(t) from flow and climate
   covariates (`NOVELTY_AND_PLAN_REPORT.md:76-81`).
2. Validate against exact references: stationary-at-mean, Floquet periodic,
   MMPP/2 and discrete-event simulation (`paper3/README.md:24-35`, `:65-88`).
3. Compare against constant rate, climatological rates, SPI/SPEI/SSI and
   low-flow statistics (`paper3/README.md:113-130`).
4. Use held-out years, held-out basins and named drought events
   (`NOVELTY_AND_PLAN_REPORT.md:258-263`).
5. Report a null result if queue indicators do not add information beyond
   baselines (`AGENTS.md:59-61`; `NOVELTY_AND_PLAN_REPORT.md:260-263`).
6. Do not present machine learning for queues, time-varying arrivals or
   correlated arrivals as our contribution (`AGENTS.md:62-66`;
   `paper1/literature_audit.md:144-174`).

## 5. P03 — pre-registered analysis protocol

The metrics, baselines and null rule must be fixed before results are examined
(`NOVELTY_AND_PLAN_REPORT.md:258`).

### 5.1 Work order

| Order | Work package | Deliverable and stop rule |
|---:|---|---|
| 1 | μ error near ρ≈1 | Fix the dominant estimator weakness first (`NOVELTY_AND_PLAN_REPORT.md:250`). Current synthetic diagnostics show μ RMSE about 0.098/day and mass-calibrated overprediction under warming; treat both as diagnostics, not findings (`paper3/README.md:81-84`; `paper3/src/evaluate_estimators.py:127-133`). Add a test. |
| 2 | Floquet convergence | Vary dt; report residual and peak-indicator stability. Keep the RK4 cap: generator reaches about 8.5/day and dt×|λmax| must stay below about 2.78 (`paper3/README.md:86-88`; `AGENTS.md:137-139`). |
| 3 | MMPP sweep | Sweep switching rate and high/low contrast. The 1.16× amplification is one setting only (`paper3/README.md:74-79`; `NOVELTY_AND_PLAN_REPORT.md:252`). |
| 4 | Multi-gauge R pipeline | Add gauge 4064 Yadgir while keeping linear BLOCK-1 scripts and base R (`paper1/data_access_spec.md:47-55`; `NOVELTY_AND_PLAN_REPORT.md:253`). |
| 5 | Zero-flow semantics | Resolve gauge 4026 zero-flow meaning against the CAMELS-India documentation. There are 9,710 zero-flow days out of 14,308 non-missing days, 68%, and ρ must not be interpreted on those days until resolved (`paper1/data_access_spec.md:59-61`; `AGENTS.md:163-166`). |
| 6 | Claim convention | Find real canal/crop records or run a documented sensitivity envelope; keep pilot numbers illustrative meanwhile (`paper1/data_access_spec.md:19-39`, `:80-97`). Change the convention in all required places in one step (`AGENTS.md:73-76`). |
| 7 | CMIP6 bias correction | Bias-correct against IMD/CAMELS before use; raw CMIP6 and Hargreaves ET0 are pipeline checks only (`AGENTS.md:53-55`; `paper1/data_access_spec.md:91-93`). |
| 8 | Future μ(t) | Use delta-change scaling of observed streamflow or a rainfall–runoff transfer function; CMIP6 extraction gives pr and temperature, not streamflow (`paper3/README.md:144-146`). |
| 9 | Validation design | Pre-register held-out years, basins, events, metrics and baselines (`NOVELTY_AND_PLAN_REPORT.md:258`). |
| 10 | Uncertainty | Propagate bootstrap intervals from rate estimates into E[Q], Pr(Q≥6), U and recovery time (`NOVELTY_AND_PLAN_REPORT.md:259`; `paper3/README.md:30`). |
| 11 | Ablation | Test incremental information beyond SPI/SPEI/SSI and a climatological queue; record the null if none appears (`AGENTS.md:59-61`; `NOVELTY_AND_PLAN_REPORT.md:260`). |
| 12 | Writing | Write only after Gate C (`AGENTS.md:198-199`). |

### 5.2 Metrics and baselines

Use rate RMSE, peak E[Q] error, severe-state probability error, unmet-demand
error, lead time and probabilistic scores such as Brier, AUC or CRPS where
applicable (`paper1/queueing_howto.md:170-180`; `paper3/README.md:117-130`).
Baselines are constant rate, climatological rate, SPI/SPEI/SSI, low-flow
statistics and a climatological queue (`paper3/README.md:119-123`;
`NOVELTY_AND_PLAN_REPORT.md:260`). Use block cross-validation, never random-row
splits (`paper1/queueing_howto.md:157-162`).

## 6. Shared operating rules

1. Run all 18 tests after every change and before reporting
   (`AGENTS.md:78-86`). On 21 November 2026 all 18 passed with the existing
   `drought` environment (`SESSION_LOG.md:8-10`).
2. Keep three-way agreement between exact solution, RK4 and DES
   (`AGENTS.md:87-91`).
3. Every manuscript number has a named script (`AGENTS.md:92-94`).
4. Report with file and line sources (`AGENTS.md:94-98`).
5. Label assumptions and measurements when first used (`AGENTS.md:222-227`).
6. Never hand-edit generated `data/*.csv` files (`AGENTS.md:123-124`).
7. Keep the claim convention fixed in all four documented locations
   (`AGENTS.md:73-76`).

## 7. Exact next action

Sign in to Web of Science in the open Clarivate tab, then screen the 93 pending
WoS records in `analysis/P01/wos_screening_2026-11-21.md` and transfer the
completed keep/drop table to `paper1/literature_audit.md`
(`APPROACH_P01_P03.md:15-17`). After Gate A, freeze the scoped gap sentence and
start the P01 work sequence (`APPROACH_P01_P03.md:57-99`).

## 8. Analysis workspace

The working analysis files are organised under `analysis/`:

- `analysis/README.md` — index and status.
- `analysis/P01/README.md` — P01 file list and decision rule.
- `analysis/P01/wos_screening_2026-11-21.md` — live 93-record WoS screen.
- `analysis/P03/README.md` — P03 outputs to create after Gate B.
- `field/README.md` — field-level initial state and formulated objectives for
  P01 and P03.

The P01 screening sheet records the access blocker honestly; no records are
invented. It will be filled only from signed-in WoS result pages
(`analysis/P01/wos_screening_2026-11-21.md:9-16`).

## 9. Reproducibility commands

Use the existing `drought` Conda environment; the default `python` has no NumPy
(`START_HERE.md:141-148`).

```powershell
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_nonstationary_bench.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_rate_estimators.py

& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R
```

Render this protocol to HTML with:

```powershell
pandoc RESEARCH_PROTOCOL.md -o RESEARCH_PROTOCOL.html --standalone --toc --number-sections --css=protocol.css
```
