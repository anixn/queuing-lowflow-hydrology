---
title: "Research protocol: P01 and P02"
subtitle: "Queue-based drought science — objectives, gates and analysis plans"
author: "Ankit Deshmukh"
date: "25 November 2026"
version: "1.1"
---

# Research protocol: P01 and P02

This file is the organising protocol for the two active papers. It uses the
canonical names **P01** and **P02**. The old labels P01 and P02 still appear in
existing file paths and source files, but they are no longer the preferred
human-facing names.

## 0. Name map

| Canonical name | Old label | Physical folder | Current work product |
|---|---|---|---|
| **P01** | Paper 1 / P1 | `P01/` | `P01/P01_draft_v2.md` |
| **P02** | Paper 3 / P3 (renumbered) | `P02/` | Methods package in `P02/` |

The repository defines two papers, P01 and P02, and fixes the order P01 first,
P02 second (`AGENTS.md` §1; `START_HERE.md` §2). Shared code lives in `src/shared/`,
P01 code in `src/P01/`, P02 code in `src/P02/`, and tests in `tests/`. The ordered
plan is in `docs/novelty/NOVELTY_AND_PLAN_REPORT.md`.

## 1. Phase position

We are in **Phase B: finish P01** (`AGENTS.md` §8;
`START_HERE.md` §7) — **Phase A closed 21 November 2026**. The record-level
screens are complete: the four Web of Science sets (S4 6 records, S5 66
records, Extra A 8 records, Extra C 13 records — 93 in total) were screened
by export with zero records retained
(`analysis/P01_literature/wos_screening_2026-11-21.md`), and all seeds were traced in
WoS/Scopus with 76 citing records screened
(`analysis/P01_literature/citation_trace_2026-11-21.md`). Scopus is complete: 295 records
screened, with no gap-changing record (`P01/literature_audit.md:88-120`).
In total 437 record-level hits + 76 citing records screened across both
databases.

The order of gates is fixed:

1. **Gate A:** one dated, scoped gap sentence and keep/drop reasons for every
   retained record (`AGENTS.md` §8).
2. **Gate B:** P01 stable — gap sentence frozen, prior art cited, every number
   script-backed (`AGENTS.md` §8).
3. **Gate C:** P02 ready — estimator beats climatology on held-out data, or an
   honest null result is written (`AGENTS.md` §8).

P01's technical Gate B passes. On the author's instruction, the first P02
real-data pilot is complete and its null result is written; broader P02 work
still awaits author sign-off (`AGENTS.md` §§1, 8).

## 2. P01 — key objective

**Plain objective:** explain why drought can be read as a queue state, cite the
existing water–queue lineage accurately, and set out tests that can show
whether queue-derived indicators add drought information.

P01 is a review/perspective for *Water Resources Research*
(`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:55-70`; `START_HERE.md:21-28`). Its objectives are:

1. Reclaim the historical link between storage theory and queueing, beginning
   with Langbein 1958, rather than presenting that link as ours
   (`P01/P01_draft_v2.md` §1).
2. Map queue quantities to drought quantities: arrivals to demand, service to
   supply, backlog to unmet demand, capacity to a system limit, and reneging to
   abandoned demand (`P01/P01_draft_v2.md` §2).
3. Keep physical storage and unmet-demand backlog distinct, couple them through
   the served-water flux and conservation ledger, and test identification
   (`P01/P01_draft_v2.md` §2.2 and §5).
4. Cite the established hydrology, irrigation, groundwater, runoff and
   reliability literature without overstating the gap
   (`P01/literature_audit.md` “Verified prior art”; `P01/P01_draft_v2.md` §2.3).
5. Show why time-varying rates matter. As of 21 November 2026, the synthetic
   Box 1 gives 2.130 claims peak E[Q] versus 0.916 claims stationary, a 2.3×
   difference, and peak Pr(Q≥6) of 0.0733 versus 0.0043, a 17× difference
   (`P01/P01_draft_v2.md` Box 1).
6. State a falsifiable research programme with pre-specified metrics,
   baselines, null-result clause and guardrails
   (`P01/P01_draft_v2.md` §§5–6).

## 3. P01 — analysis protocol

This is a scoping-review protocol, not a full systematic review; the distinction
is already recorded in the audit (`P01/literature_audit.md:12-18`).

### 3.1 Search and screening

1. Use the exact search strings and interface notes in
   `P01/search_protocol.md:10-61`.
2. Record for each search: database, interface, date, exact string, filters,
   raw hits, screened count, retained count and exclusion reasons
   (`P01/search_protocol.md:126-139`).
3. ~~Screen the four pending WoS sets and write one keep/drop reason per record~~
   **Done 21 November 2026** — 93/93 screened, zero retained; the table is in
   `analysis/P01_literature/wos_screening_2026-11-21.md` §5 and the summary in
   `P01/literature_audit.md`.
4. ~~Complete the required citation-trace seeds~~ **Done 21 November 2026** —
   all seeds were traced inside WoS/Scopus where indexed; 76 citing records
   were screened and two non-gap-changing records were added
   (`analysis/P01_literature/citation_trace_2026-11-21.md`).
5. ~~Full-text screen the retained set~~ — empty by definition: nothing was
   retained at title/abstract level.

### 3.2 Synthesis

1. Build the concept map from queue term to hydrological meaning and caveat
   (`P01/P01_draft_v2.md` §2).
2. Keep prior-art rows with three columns: representation, what it does, what
   it leaves open (`P01/P01_draft_v2.md` §2.3).
3. Use only script-backed synthetic numbers. The anchor three-way check is
   exact E[Q] 0.91607 claims, RK4 E[Q] 0.91607 claims and DES time-average
   E[Q] 0.91295 claims, a 0.34% difference on 21 November 2026
   (`AGENTS.md` §4; `P01/README.md` “Verified synthetic results”).
4. Label every pilot number "illustrative, under the stated assumptions"
   (`AGENTS.md:47-52`; `START_HERE.md:87-92`).
5. Do not use raw CMIP6 output in any published number
   (`AGENTS.md:53-55`).

### 3.3 Language and gate check

Search the draft for strong claim words and "no study" phrases; check each
against the scoped, dated gap sentence (`AGENTS.md:30-45`;
`P01/P01_draft_v2.md` abstract and §6). P01 is stable only when Gate B is met
(`AGENTS.md:189-190`).

## 4. P02 — key objective

**Plain objective:** estimate changing demand and supply rates from data,
verify the estimates against exact mathematics, and test whether queue state
adds drought information beyond standard baselines.

P02 is a methods paper for *Hydrology and Earth System Sciences* later in the
roadmap (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:72-84`; `P02/README.md`). Its
objectives are:

1. Estimate λ(t) from demand covariates and μ(t) from flow and climate
   covariates (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:76-81`).
2. Validate against exact references: stationary-at-mean, Floquet periodic,
   MMPP/2 and discrete-event simulation (`P02/README.md` “Contents” and “Verified synthetic results”).
3. Compare against constant rate, climatological rates, SPI/SPEI/SSI and
   low-flow statistics (`P02/README.md` “Planned P02 sequence after Gate B”).
4. Use held-out years, held-out basins and named drought events
   (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:258-263`).
5. Report a null result if queue indicators do not add information beyond
   baselines (`AGENTS.md:59-61`; `docs/novelty/NOVELTY_AND_PLAN_REPORT.md:260-263`).
6. Do not present machine learning for queues, time-varying arrivals or
   correlated arrivals as our contribution (`AGENTS.md:62-66`;
   `P01/literature_audit.md:144-174`).

## 5. P02 — pre-registered analysis protocol

The metrics, baselines and null rule must be fixed before results are examined
(`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:258`).

### 5.1 Work order

| Order | Work package | Deliverable and stop rule |
|---:|---|---|
| 1 | μ error near ρ≈1 | Fix the dominant estimator weakness first (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:250`). Current synthetic diagnostics show μ RMSE about 0.098/day and mass-calibrated overprediction under warming; treat both as diagnostics, not findings (`P02/README.md` “Verified synthetic results”; `src/P02/evaluate_estimators.py:127-133`). Add a test. |
| 2 | Floquet convergence | Vary dt; report residual and peak-indicator stability. Keep the RK4 cap: generator reaches about 8.5/day and dt×|λmax| must stay below about 2.78 (`P02/README.md` “Verified synthetic results”; `AGENTS.md:137-139`). |
| 3 | MMPP sweep | Sweep switching rate and high/low contrast. The 1.16× amplification is one setting only (`P02/README.md` “Verified synthetic results”; `docs/novelty/NOVELTY_AND_PLAN_REPORT.md:252`). |
| 4 | Multi-gauge R pipeline | Add gauge 4064 Yadgir while keeping linear BLOCK-1 scripts and base R (`P01/data_access_spec.md:47-55`; `docs/novelty/NOVELTY_AND_PLAN_REPORT.md:253`). |
| 5 | Zero-flow semantics | Resolve gauge 4026 zero-flow meaning against the CAMELS-IND documentation. There are 9,710 zero-flow days out of 14,308 non-missing days, 68%, and ρ must not be interpreted on those days until resolved (`P01/data_access_spec.md:59-61`; `AGENTS.md:163-166`). |
| 6 | Claim convention | Find real canal/crop records or run a documented sensitivity envelope; keep pilot numbers illustrative meanwhile (`P01/data_access_spec.md:19-39`, `:80-97`). Change the convention in all required places in one step (`AGENTS.md:73-76`). |
| 7 | Projected-data validation | Document CAMELS-IND-Proj LSTM provenance and validate historical streamflow against observed/LSTM flow. Avoid double bias correction; recover its forcing subset or bias-correct raw SSP forcing against IMD (`analysis/P02_methods/MODELLING_PLAN.md`). |
| 8 | Future μ(t) | Use the CAMELS-IND-Proj 13-model/four-SSP ensemble as a conditional projection after historical validation. Raw CMIP6 remains pipeline-check-only; any delta-change comparison must pass its own bias-correction gate. |
| 9 | Validation design | Pre-register held-out years, basins, events, metrics and baselines (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:258`). |
| 10 | Uncertainty | Propagate bootstrap intervals from rate estimates into E[Q], Pr(Q≥6), U and recovery time (`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:259`; `src/P02/rate_estimators.py`). |
| 11 | Ablation | Test incremental information beyond SPI/SPEI/SSI and a climatological queue; record the null if none appears (`AGENTS.md:59-61`; `docs/novelty/NOVELTY_AND_PLAN_REPORT.md:260`). |
| 12 | Writing | Write only after Gate C (`AGENTS.md` §8). |

### 5.2 Metrics and baselines

Use rate RMSE, peak E[Q] error, severe-state probability error, unmet-demand
error, lead time and probabilistic scores such as Brier, AUC or CRPS where
applicable (`P01/queueing_howto.md` §7; `P02/README.md` “Planned P02 sequence after Gate B”).
Baselines are constant rate, climatological rate, SPI/SPEI/SSI, low-flow
statistics and a climatological queue (`P02/README.md` “Planned P02 sequence after Gate B”;
`docs/novelty/NOVELTY_AND_PLAN_REPORT.md:260`). Use block cross-validation, never random-row
splits (`P01/queueing_howto.md` §6).

## 6. Shared operating rules

1. Run the full test suite after every change and before reporting
   (`AGENTS.md` §4). On 25 November 2026 all 42 tests passed with the existing
   `drought` environment (12 shared/P01, 6 benchmark, 7 estimator, 17 real-data comparison).
2. Keep three-way agreement between exact solution, RK4 and DES
   (`AGENTS.md:87-91`).
3. Every manuscript number has a named script (`AGENTS.md:92-94`).
4. Report with file and line sources (`AGENTS.md:94-98`).
5. Label assumptions and measurements when first used (`AGENTS.md:222-227`).
6. Never hand-edit generated `P02/data/generated/*.csv` files (`AGENTS.md` §§5–6).
7. Keep the claim convention fixed in all four documented locations
   (`AGENTS.md:73-76`).

## 7. Exact next action

Gate A passed on 21 November 2026. The WoS/Scopus screens and database citation traces are complete, and the gap sentence is frozen in `AGENTS.md` §2. The 25 November supplementary search and P01 indicator-contract revisions are complete.

**Phase B (finish P01 and test the merged-paper claim) is current.** The reproducible figures and WRR package drafts are complete, and `P01/GATE_B_CHECKLIST.md` records a technical Gate B pass. The first predeclared real-data comparison is also complete and found no held-out Brier improvement from adding queue probability to SSI in either gauge (`analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`). Exact next action: author sign-off on submission metadata, archive links, recovery/μ definitions, disclosed literature limitations and the negative-result merged-paper strategy in `docs/project/MERGED_PAPER_PLAN.md`.

## 8. Analysis workspace

The working analysis files are organised under `analysis/`:

- `analysis/README.md` — index and status.
- `analysis/P01_literature/` — completed WoS screen, citation trace and raw exports.
- `analysis/novelty_2026-11-25/` — supplementary novelty investigation and Box 1 sensitivity grid.
- `analysis/claim_convention_2026-11-25/` — official area evidence, WoS refresh and claim-scale envelope.
- `analysis/P02_methods/README.md` — P02 outputs to create after Gate B.

The P01 literature folder preserves five WoS search exports and two citing-article exports. Two citing-set exports are absent and two citation-count discrepancies remain unreconciled; these limitations are disclosed in the trace note. No records are invented.

## 9. Reproducibility commands

Use the existing `drought` Conda environment; the default `python` has no NumPy
(`START_HERE.md` §8).

```powershell
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_queue_core.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_nonstationary_bench.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_rate_estimators.py

& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' P02/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' P02/R/02_run_queue.R
```
