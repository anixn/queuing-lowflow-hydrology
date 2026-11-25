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
| Phase | Phase B, finish P01; Gate A passed 21 Nov 2026 | `AGENTS.md:182-201`; `START_HERE.md` §7 |
| Scopus screen | Complete: 295 records, no gap-changing study | `paper1/literature_audit.md:88-120` |
| WoS screen | Complete: 93 records screened 21 Nov 2026, no gap-changing study | `analysis/P01/wos_screening_2026-11-21.md` |
| P01 draft | Draft v2 exists; language and package still to finish | `paper1/P1_draft_v2.md:1-10`; `NOVELTY_AND_PLAN_REPORT.md:234-246` |
| P03 analysis | Prepared only; starts after Gate B | `AGENTS.md:28`, `:192`; `analysis/P03/README.md:3` |
| Engine | 22/22 tests pass after the 25 Nov conservation-ledger and sensitivity additions | `analysis/P02_novelty_2026-11-25/13_reproducibility_report.md` |
| CMIP6 output | Pipeline check only; not usable in published numbers | `AGENTS.md:53-55`; `paper3/README.md:141-143` |

The last database action is done: the WoS record-level screen of all 93
remaining records (S4 6, S5 66, Extra A 8, Extra C 13) was completed on
21 November 2026 via WoS Excel exports — no institutional profile sign-in was
needed, the IP-entitled session allowed search and export
(`analysis/P01/wos_screening_2026-11-21.md:14-33`), and the forward-citation
trace of all seeds inside WoS/Scopus is also complete
(`analysis/P01/citation_trace_2026-11-21.md`).

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
| ~~WoS sign-in~~ | Resolved 21 Nov 2026: 93 records exported and screened without profile sign-in; gap sentence frozen | `analysis/P01/wos_screening_2026-11-21.md` |
| Zero-flow meaning for gauge 4026 | 68% zero-flow days affect interpretation of ρ | `paper1/data_access_spec.md:59-61` |
| Canal/crop records | Replace the 50,000 ha / 10⁷ m³ provisional convention | `paper1/data_access_spec.md:80-97` |
| CMIP6 bias correction | Raw future climate output must not be published | `AGENTS.md:53-55` |
| Regulation status of gauge 4026 | Unknown; affects whether μ is managed or natural supply | `paper1/data_access_spec.md:95-97` |
| ~~Git is not initialised~~ | Resolved: the workspace is a Git repository | `git status --short --branch`, 25 Nov 2026 |

## 7. Organized file map

| Layer | Files | Purpose |
|---|---|---|
| Field-level state | `field/README.md` | Objectives and initial state for the whole programme. |
| Protocol | `../RESEARCH_PROTOCOL.md` | Phase, gates, P01/P03 analysis plans, reproducibility. |
| Work sequence | `../APPROACH_P01_P03.md` | Ordered steps from Phase A through P03 writing. |
| Screening | `../analysis/P01/wos_screening_2026-11-21.md` | Completed 93-record WoS screen. |
| Citation trace | `../analysis/P01/citation_trace_2026-11-21.md` | Completed seed trace in WoS/Scopus (76 citing records). |
| Paper packages | `../paper1/`, `../paper3/` | Existing manuscript and methods code. |
| Session trail | `../SESSION_LOG.md` | What changed and why. |

## 8. Exact next action

DONE 21 November 2026 — the WoS record-level screen of the 93 records in
`analysis/P01/wos_screening_2026-11-21.md` is complete, keep/drop reasons are
transferred to `paper1/literature_audit.md`, and the dated gap sentence is
frozen as follows.

**Frozen gap sentence, 21 November 2026** (canonical copy in `AGENTS.md` §2;
also in `START_HERE.md` §5 and `paper1/literature_audit.md`):

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens
> (295 records), plus the citation traces, we found no study that puts all
> four of these together: (1) drought as an accumulated unmet-demand backlog
> with a finite-capacity state; (2) queue-state indicators reported as
> drought quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

Next action (Phase A tail): ~~forward-citation tracing inside WoS/Scopus~~
DONE 21 November 2026 — all seeds traced or confirmed unindexed; 76 citing
records screened; two new non-gap-changing prior-art records found
(`analysis/P01/citation_trace_2026-11-21.md`). The frozen sentence is
unchanged by the trace. **Gate A is passed; Phase B (finish P1) is the
current phase** — next action: tighten the mapping section (§2), expand prior
art with the two new records, and continue the P01 work sequence
(`../APPROACH_P01_P03.md`).
