# Gate B checklist (v2 rebuild) — 26 November 2026

This replaces the 25 November WRR-package checklist. The WRR submission package
is retired; the deliverable is one HESS-style methods + negative-result paper
(Path B). The technical criteria below are now evidenced by R code only.

**Technical result: PASS.** **Submission result: PENDING AUTHOR SIGN-OFF.**

## Formal criteria

| Criterion | Status | Evidence |
|---|---|---|
| Frozen gap sentence unchanged | PASS | Identical in `AGENTS.md` §2, `START_HERE.md` §5, `PLAN_SUMMARY.md` §2, `P01/P01_draft_v2.md` |
| Relevant prior art cited | PASS | `P01/literature_audit.md`; storage, soil water, demand, groundwater, runoff, irrigation, high flow, reliability, coupled state-space, non-stationary supply-demand, first passage, attribution, identification, ML-for-queues |
| Every v2 number reproducible | PASS | `R/config.R`; `R/00_utils/*`; `R/run_pipeline.R`; `R/analysis/power_analysis.R`; `R/analysis/sensitivity_grid.R`; `R/analysis/make_figures.R` |
| Bibliometric counts preserved | PASS (frozen) | 142 WoS, 295 Scopus, 437 total, 93 record-level WoS, 76 citing records. The v1 validator (`validate_literature_counts.py`) is preserved on branch `legacy-python`; counts are frozen and no v2 script alters them |
| Unit consistency | PASS | `R/00_utils/units.R`; test V8; one claim volume per gauge |
| Catchment-relative thresholds | PASS | test V10; `q*`, `K`, `theta` scale with `lam_bar` |
| Confirmatory statistic is paired | PASS | `stage7_paired_stats()` / `stage7_paired_bootstrap()`; `output/paired_e1.csv` |
| Protocol locked before unblinding | PASS | `protocol/PROTOCOL_v2.md`, tag `protocol-v2-locked`; derived from the plan's predeclared §3.7 |
| Power adequate | PASS | `output/power_analysis.csv`; MDE shown vs observed effect |
| Figures reproducible | PASS | `R/analysis/make_figures.R` (PDF + 300-dpi PNG) |
| Test suite | PASS | `Rscript R/verify/run_tests.R` — 14/14 |
| Python removed from `main` | PASS | `src/`, `tests/`, `P02/R/` deleted; `legacy-python` branch + tag `v1-audited` retain them |

## Disclosed limitations accepted for Gate B

- The literature audit is a scoping review, not a systematic review.
- Scopus records were screened at title level; WoS used exported titles,
  abstracts and keywords.
- Two citing-set exports are absent and two WoS citation-count discrepancies
  remain unreconciled.
- The current Scopus UI did not return targeted results on 25 November 2026; no
  new Scopus screen is claimed.
- Zero-flow classification uses same-basin peers (proxy grade); no independent
  CWC / India-WRIS daily record was available.
- The primary external SMA target uses a 1981-2020 climatology, so it is not
  strictly leakage-free; the training-only SPI-3 target is the clean sensitivity.
- Stage-B irrigation demand was unavailable; demand is a Stage-A envelope with
  an `f_irr` sweep.
- Queue outputs are illustrative under the stated assumptions.

These do not change the frozen sentence or the technical criteria, but they must
remain disclosed in the manuscript and submission record.

## Author-only actions before submission

1. Approve the final title, abstract, keywords and cover letter (HESS, Path B).
2. Provide corresponding-author details, ORCID, declarations and journal
   statements.
3. Provide the public repository URL, archived release/DOI and software licence.
4. Confirm the recovery definition: **backlog clearance, including reneging**.
5. Confirm the `mu` convention: **firm share of observed flow, capped at 10
   mm/day, converted through the per-gauge claim volume**.
6. Accept the disclosed literature limitations or authorize retrieval of the
   missing restricted records.
7. Approve the Path-B reframing in `docs/project/MERGED_PAPER_PLAN.md`: the
   confirmatory Brier endpoints are null; the AUC signal is secondary only.

## Decision

The technical Gate B audit is complete and passes on the R rebuild. The
confirmatory endpoints returned a null, so the merged paper must use the Path-B
strategy. No frozen novelty wording has changed.
