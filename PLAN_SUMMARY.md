# Plan summary — one merged drought-queue methods paper

Date: 25 November 2026

## Bottom line

We tested the central idea on actual data: **does a queue of unmet water demand add drought information beyond climatology, SPI, SPEI and SSI?**

The first two-gauge test says **no under the current assumptions**. Adding queue probability to SSI did not improve Brier score in either gauge. We keep that negative result unchanged.

The recommended paper is therefore **one HESS-style methods and negative-result evaluation**, not a claim that queue indicators are superior.

## 1. Objective

Represent drought as a finite-capacity queue:

- water demand arrives at rate λ(t);
- available supply serves demand at rate μ(t);
- unmet demand accumulates as backlog Q(t);
- backlog indicators describe drought state, exposure, abandonment and recovery.

The paper must do two things:

1. prove the queue calculations against exact mathematical references;
2. test whether the indicators add information on observed drought events.

A synthetic example alone is not enough.

## 2. The gap we are testing

The frozen 21 November 2026 sentence is unchanged:

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens (295
> records), plus the citation traces, we found no study that puts all four of
> these together: (1) drought as an accumulated unmet-demand backlog with a
> finite-capacity state; (2) queue-state indicators reported as drought
> quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

In plain language: the mathematics is old, but this drought-specific combination was not found in the documented search scope. We do not claim that no such study exists anywhere.

## 3. Data used in the actual comparison

| Source | Role | Status |
|---|---|---|
| CAMELS-IND catchment forcings | Daily rainfall and PET for process-based demand λ | Used |
| CAMELS-IND observed streamflow | Daily supply μ for gauges 4026 and 4064 | Used, with gaps and zero-flow caveats |
| Drought Intelligence Explorer v2 | District SMA target and published SPI-3/SPEI-3 benchmarks | Used |
| CAMELS-IND attributes | Gauge/basin identity and dam-presence context | Used for limitations |
| IMD gridded data | Available for a future strict training-only climate baseline | Not used in the current comparison |
| CMIP6 / CAMELS-IND-Proj | Available for later conditional future supply analysis | No raw CMIP6 number is published |

The gauge-to-district mapping is:

- 4026 Kurundwad → Sangli;
- 4064 Yadgir → Yadgir.

The supplied SMA target and published SPI/SPEI use an external **1981–2020 climatology**. That overlaps the nominal test years, so target construction and those benchmarks are **not strictly held-out**. No test labels enter model fitting, but this limitation must remain in the paper.

## 4. Method in plain language

1. Build daily demand from the R-equivalent crop-water formula.
2. Convert observed streamflow to a capped firm-supply rate.
3. Propagate the finite-state queue with a stability-controlled RK4 solver.
4. Aggregate monthly queue probabilities and a training-standardized SSI-3 proxy.
5. Fit calendar-month-aware L2 logistic models on 1981–2010 only.
6. Compare climatology, SPI-3, SPEI-3, SSI-3, queue alone and SSI+queue.
7. Score Brier skill, AUC, log loss, calibration, reliability and event timing.
8. Use whole held-out years, a paired year-block bootstrap and predeclared sensitivities.

The confirmatory question is narrow: **does SSI+queue lower Brier score relative to SSI alone at q*=6 in both gauges?**

## 5. Actual data coverage

Long discharge gaps prevent a complete 2011–2020 test:

- gauge 4026 has a 611-day interior gap;
- gauge 4064 has a 661-day trailing gap;
- only gaps of seven days or less are interpolated and flagged;
- both usable records end on 28 February 2019.

Each gauge contributes:

- 360 target/flow-available training months, but **358 common complete cases** because January–February 1981 lack SPI/SPEI;
- **98 held-out months**;
- **4 held-out SMA-drought months in 3 events**.

Source: `analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`, Source-data audit and Target availability.

## 6. What the actual data showed

Lower Brier score is better.

| Gauge | SSI Brier | SSI+queue Brier | Change | Result |
|---:|---:|---:|---:|---|
| 4026 | 0.041008 | 0.041279 | +0.000271 | Worse |
| 4064 | 0.044246 | 0.044836 | +0.000590 | Worse |

AUC also declined when queue was added to SSI. Queue alone had small Brier skill over climatology (0.0347 and 0.0320), while the external SPEI benchmark performed better.

The result is unchanged for:

- q*=4, 6 and 8;
- causal forward-fill of short gaps;
- exclusion of months containing imputed flow.

Source: `analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md:29`, `:52`, `:68`, `:79`.

**Interpretation:** the current proxy-based queue indicators are **illustrative, under the stated assumptions**, and add no demonstrated incremental information in this pilot. This is retrospective diagnosis, not forecasting.

## 7. Recommended single-paper plan

**Working title:**

**Do deficit-queue indicators add drought information? Exact validation and a held-out comparison with SPI, SPEI, SSI and climatology**

Suggested structure:

1. Introduction: anomaly indices versus accumulated unmet demand.
2. Related work: storage/queue lineage and the frozen scoped gap.
3. Model and conservation ledger.
4. Exact, Floquet and discrete-event verification.
5. Data, preprocessing and actual coverage.
6. Predeclared comparison design.
7. Results: null held-out comparison, calibration and sensitivities.
8. Discussion: identifiability, proxy demand, zero flows, regulation and scale mismatch.
9. Conclusion: no demonstrated incremental skill; requirements for a stronger test.
10. Data/code availability and complete negative-results trail.

The results-backed abstract and submission position are in `docs/project/MERGED_PAPER_PLAN.md`.

## 8. What we did not do

- No ahead-of-event forecast; same-month observed flow is used.
- No measured irrigation-demand series; λ remains a process scenario.
- No resolution of zero-flow or regulation semantics for either gauge.
- No strict 1981–2010 reconstruction of the SMA/SPI/SPEI climatologies.
- No broad multi-gauge or many-event validation.
- No crop-loss prediction or causal demand–supply attribution.
- No future climate result; CAMELS-IND-Proj still needs historical/provenance validation.
- No raw CMIP6 number is used.

## 9. Exact next actions

1. Author approves the one-paper methods/negative-result framing.
2. Obtain measured canal/crop demand or a defensible demand envelope.
3. Resolve zero-flow and station-regulation semantics with CWC/India-WRIS records.
4. Rebuild strict training-only SMA/SPI/SPEI from raw inputs.
5. Expand to more gauges and held-out drought events.
6. Keep the present null unless a predeclared stronger test shows otherwise.

## 10. Where to look

- Plain orientation: `START_HERE.md`
- Locked comparison protocol: `analysis/P02_methods/REAL_DATA_COMPARISON_PROTOCOL.md`
- Generated results: `analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`
- Actual-data figure: `analysis/P02_methods/figures/real_data_comparison.png`
- Pipeline: `src/P02/real_data_comparison.py`
- Merged-paper strategy: `docs/project/MERGED_PAPER_PLAN.md`
- Tests: 42/42 passing, including 17 real-data comparison tests
