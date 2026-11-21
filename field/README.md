---
title: "Field-level initial state: P01 and P03"
subtitle: "Queueing theory meets hydrological drought and low-flow analysis"
date: "21 November 2026"
status: "initial state only — no scientific claim is being made"
---

# Field-level initial state: P01 and P03

## 1. Field aim

We are building a research programme at the junction of queueing theory and
hydrological drought / low-flow analysis. The core idea is plain:

- demand arrives as irrigation, environmental and water-use claims;
- river, canal, groundwater and reservoir supply clear those claims;
- demand that cannot be met accumulates as a backlog `Q`;
- a finite capacity `K` marks the limit before demand is shed;
- abandoned demand and recovery time become drought-impact quantities.

The historical point matters: hydrology already published the storage–queue
link in Langbein 1958. We are not saying the link is ours. We are
**reclaiming and updating** it for drought deficit accounting, non-stationary
rates and pre-specified validation (`paper1/P1_draft_v2.md:74-89`;
`paper1/literature_audit.md:122-130`).

## 2. Initial state of the work

| Area | State on 21 November 2026 | Source |
|---|---|---|
| Phase | Phase A, gap hunt | `AGENTS.md:174-180`; `START_HERE.md:125-130` |
| Scopus screen | Complete: 295 records, no gap-changing study | `paper1/literature_audit.md:88-120` |
| WoS screen | 93 records pending: S4 6, S5 66, Extra A 8, Extra C 13 | `paper1/scopus_wos_search_plan.md:70-74` |
| P01 draft | Draft v2 exists; language and package still to finish | `paper1/P1_draft_v2.md:1-10`; `NOVELTY_AND_PLAN_REPORT.md:234-246` |
| P03 analysis | Prepared only; starts after Gate B | `AGENTS.md:28`, `:192`; `analysis/P03/README.md:3` |
| Engine | 18/18 tests pass | `AGENTS.md:78-86`; `SESSION_LOG.md:8-10` |
| CMIP6 output | Pipeline check only; not usable in published numbers | `AGENTS.md:53-55`; `paper3/README.md:141-143` |

The next database action is still the WoS record-level screen. No WoS records
have been read in this session; the screening sheet is empty until institutional
sign-in is available (`analysis/P01/wos_screening_2026-11-21.md:18-58`).

## 3. Objectives formulated for P01

P01 is the review/perspective paper for *Water Resources Research*. Its
objective is to establish why the queue view belongs in drought and low-flow
science and to define the research programme honestly
(`NOVELTY_AND_PLAN_REPORT.md:55-70`; `START_HERE.md:21-28`).

| # | P01 objective | Success criterion |
|---:|---|---|
| 1 | Frame the drought–queue mapping precisely: demand, supply, backlog, capacity, abandonment, recovery. | Every queue term has one hydrological meaning and one caveat (`paper1/P1_draft_v2.md:103-150`). |
| 2 | Reclaim the historical storage–queue lineage, beginning with Langbein 1958. | Prior art is cited, not rediscovered as our claim (`paper1/P1_draft_v2.md:74-89`; `paper1/literature_audit.md:122-130`). |
| 3 | Complete the prior-art audit and freeze a dated, scoped gap sentence. | Every WoS record has a keep/drop reason and every retained record is full-text screened (`AGENTS.md:181-182`; `paper1/literature_audit.md:196-204`). |
| 4 | Show why non-stationary rates are scientifically necessary. | The 2.3× peak-backlog difference and 17× severe-probability difference are presented with units and scripts (`paper1/P1_draft_v2.md:266-292`). |
| 5 | Define queue-derived drought indicators. | Backlog, severe-state probability, unmet demand, wait/recovery time and abandonment are defined and script-backed (`paper1/P1_draft_v2.md:205-243`). |
| 6 | Set a falsifiable programme with baselines and null-result rule. | SPI/SPEI/SSI and climatological baselines are named; a null result is acceptable (`paper1/P1_draft_v2.md:294-347`; `AGENTS.md:59-61`). |
| 7 | Prepare the WRR submission package. | Abstract, cover letter, code/data statement and reproducible figures exist (`NOVELTY_AND_PLAN_REPORT.md:244`). |

**P01 is stable at Gate B when:** the gap sentence is frozen, prior art is
cited, and every numerical claim has a script behind it
(`AGENTS.md:189-190`).

## 4. Objectives formulated for P03

P03 is the methods paper for *Hydrology and Earth System Sciences*. Its
objective is to make the queue parameterisation usable on real hydrological
data and to test whether it adds drought information beyond existing baselines
(`NOVELTY_AND_PLAN_REPORT.md:72-84`; `paper3/README.md:113-130`).

| # | P03 objective | Success criterion |
|---:|---|---|
| 1 | Estimate λ(t) and μ(t) from hydroclimatic covariates. | Rates are positive, monotone where needed, calibrated and interval-bearing (`paper3/README.md:24-31`; `NOVELTY_AND_PLAN_REPORT.md:76-81`). |
| 2 | Validate against exact reference solutions. | Stationary-at-mean, Floquet, MMPP/2 and DES agree within documented tolerances (`paper3/README.md:65-88`). |
| 3 | Fix the dominant estimator weakness near ρ≈1. | μ error and severe-probability bias are quantified and reduced, with a test (`NOVELTY_AND_PLAN_REPORT.md:250`; `paper3/README.md:81-84`). |
| 4 | Extend the real-data pipeline to more gauges. | Gauges 4026 and 4064 run in the same linear BLOCK-1 R pipeline (`paper1/data_access_spec.md:47-55`; `NOVELTY_AND_PLAN_REPORT.md:253`). |
| 5 | Resolve zero-flow semantics before interpreting ρ. | The 68% zero-flow issue for gauge 4026 is documented and either resolved or excluded (`paper1/data_access_spec.md:59-61`; `AGENTS.md:163-166`). |
| 6 | Replace or envelope the provisional claim convention. | Real canal/crop records are found, or a sensitivity envelope is run and every pilot number stays illustrative (`paper1/data_access_spec.md:19-39`, `:80-97`). |
| 7 | Build future μ(t) only from bias-corrected CMIP6. | No raw CMIP6 number reaches a published result (`AGENTS.md:53-55`; `paper3/README.md:141-146`). |
| 8 | Pre-register validation on held-out years, basins and events. | Metrics, baselines and null rule are written before result inspection (`NOVELTY_AND_PLAN_REPORT.md:258`). |
| 9 | Test incremental information. | Queue indicators are compared with SPI/SPEI/SSI and a climatological queue; a null result is publishable (`AGENTS.md:59-61`; `NOVELTY_AND_PLAN_REPORT.md:260`). |
| 10 | Propagate uncertainty. | Bootstrap intervals from rates are carried into E[Q], Pr(Q≥6), U and recovery time (`NOVELTY_AND_PLAN_REPORT.md:259`). |

**P03 is ready at Gate C when:** the estimator beats climatology on held-out
data, or an honest null result is written (`AGENTS.md:198-199`).

## 5. What is not an objective

1. Not to claim that queueing in hydrology is ours.
2. Not to claim ML-for-queues, time-varying arrivals or correlated arrivals as
   the contribution (`AGENTS.md:62-66`; `paper1/literature_audit.md:144-174`).
3. Not to publish raw CMIP6 output (`AGENTS.md:53-55`).
4. Not to interpret ρ on zero-flow days before the documentation question is
   resolved (`AGENTS.md:163-166`).
5. Not to present pilot numbers as findings; they remain illustrative under
   the stated assumptions (`START_HERE.md:87-92`).
6. Not to hide a null result (`AGENTS.md:59-61`).

## 6. Current blockers

| Blocker | Why it matters | Source |
|---|---|---|
| WoS sign-in | 93 records still unread; gap sentence cannot be frozen yet | `analysis/P01/wos_screening_2026-11-21.md:18-24` |
| Zero-flow meaning for gauge 4026 | 68% zero-flow days affect interpretation of ρ | `paper1/data_access_spec.md:59-61` |
| Canal/crop records | Replace the 50,000 ha / 10⁷ m³ provisional convention | `paper1/data_access_spec.md:80-97` |
| CMIP6 bias correction | Raw future climate output must not be published | `AGENTS.md:53-55` |
| Regulation status of gauge 4026 | Unknown; affects whether μ is managed or natural supply | `paper1/data_access_spec.md:95-97` |
| Git is not initialised | Required before further major edits | `AGENTS.md:201-203` |

## 7. Organized file map

| Layer | Files | Purpose |
|---|---|---|
| Field-level state | `field/README.md` | Objectives and initial state for the whole programme. |
| Protocol | `../RESEARCH_PROTOCOL.md` | Phase, gates, P01/P03 analysis plans, reproducibility. |
| Work sequence | `../APPROACH_P01_P03.md` | Ordered steps from Phase A through P03 writing. |
| Screening | `../analysis/P01/wos_screening_2026-11-21.md` | Live 93-record WoS screen. |
| Paper packages | `../paper1/`, `../paper3/` | Existing manuscript and methods code. |
| Session trail | `../SESSION_LOG.md` | What changed and why. |

## 8. Exact next action

Complete institutional sign-in to Web of Science, screen the 93 records in
`analysis/P01/wos_screening_2026-11-21.md`, transfer keep/drop reasons to
`paper1/literature_audit.md`, then freeze the dated gap sentence.
