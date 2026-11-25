# Merged P01/P02 paper plan

Date: 25 November 2026. Recommendation: **one HESS-style methods/negative-result paper**, not a separate synthetic perspective followed by an unwritten methods paper. The observed comparison returned a null; the strategy below is updated accordingly.

## Working title

**A conservation-constrained queue-state model for hydrological drought: exact validation and incremental information beyond SPI, SPEI and SSI**

## Central claim

A finite-capacity unmet-demand queue can produce interpretable drought-state indicators, but its value must be demonstrated against exact reference solutions and observed drought events—not inferred from a synthetic averaging example alone.

## Why merge

- P01 supplies the conceptual mapping, prior art and guardrails.
- P02 supplies the actual test: observed data, held-out years and baseline comparisons.
- A single paper forces every conceptual claim to face data.
- It avoids a perspective paper that asks readers to wait for a future methods paper.

## Proposed structure

1. Introduction: anomaly indices versus accumulated unmet demand.
2. Related work: storage/queue lineage, drought indices, queue estimation and coupled drought state spaces.
3. Model: conservation ledger, finite-capacity CTMC and indicators.
4. Verification: exact stationary, Floquet, MMPP and DES references.
5. Data and preprocessing: CAMELS-IND, Drought Intelligence Explorer and explicit assumptions.
6. Comparison design: predeclared target, baselines, split and metrics.
7. Results: synthetic verification plus held-out observed-event comparison.
8. Discussion: when queue indicators add information, identifiability and limitations.
9. Conclusion: including a null result if the queue does not beat baselines.

## Minimum evidence needed

- Exact solver agreement.
- A reproducible real-data queue series for gauges 4026 and 4064.
- Held-out comparison against climatology, SPI, SPEI and SSI.
- An incremental SSI + queue test.
- Sensitivity to q*, claim scale and structural assumptions.
- Honest limitations on demand proxies, zero flows, regulation and spatial scale.

## What happens to existing P01 material

- Keep the literature audit and frozen gap sentence.
- Compress the long perspective narrative.
- Retain the mapping, conservation ledger and exact benchmarks.
- Remove any implication that the synthetic 2.3× result is an empirical finding.
- Replace the WRR submission package with an HESS methods package after the comparison.

## What happens to P02 material

- The modelling plan becomes the core methods section.
- The first real-data comparison becomes the empirical results section.
- Future CMIP6 work remains a separate later extension unless it is needed for the central claim.

## Gate for the merged paper

The merged paper is viable only if the observed comparison is reported transparently, including a null. If queue indicators add no information, the paper becomes a methods/negative-result contribution about when deficit-queue metrics fail—not a superiority claim.

## Observed outcome — 25 November 2026

The predeclared real-data comparison is complete. The confirmatory result is **null/negative**: adding queue probability to SSI did not lower held-out Brier score in either gauge at q*=6.

| Quantity | Gauge 4026 | Gauge 4064 | Source |
|---|---:|---:|---|
| Held-out months / SMA drought months | 98 / 4 | 98 / 4 | `REAL_DATA_COMPARISON_RESULTS.md`, Target availability |
| SSI Brier | 0.041008 | 0.044246 | Primary held-out results |
| SSI + queue Brier | 0.041279 | 0.044836 | Primary held-out results |
| ΔBrier (combined − SSI) | +0.000271 | +0.000590 | Incremental decision |
| ΔAUC (combined − SSI) | −0.0678 | −0.0080 | Incremental decision |
| Queue-only Brier skill vs climatology | 0.0347 | 0.0320 | Primary held-out results |
| External SPEI-3 Brier | 0.029799 | 0.033204 | Primary held-out results |

The paired year-block bootstrap gives ΔBrier intervals of [−0.00134, 0.00219] for 4026 and [0.000086, 0.00109] for 4064. All q*=4/6/8 and missing-flow sensitivity analyses preserve the no-improvement result. Source: `real_data_bootstrap.csv` and the q*/missing-flow tables in `REAL_DATA_COMPARISON_RESULTS.md`.

### Recommended single-paper title

**Do deficit-queue indicators add drought information? Exact validation and a held-out comparison with SPI, SPEI, SSI and climatology**

### Results-backed abstract draft

Queueing theory represents unmet demand as a backlog that accumulates under constrained supply, but its value for drought diagnosis must be tested rather than inferred from synthetic examples. We formulate a conservation-constrained finite-capacity deficit queue, verify it against exact stationary, Floquet and discrete-event references, and evaluate its indicators on two Krishna-basin gauges mapped to Sangli and Yadgir districts. Models are fitted on 358 common complete training months in 1981–2010 and tested on the 98 complete observed months available per gauge in 2011–February 2019. The target is district Soil Moisture Anomaly as supplied at or below −15%; comparators are climatology, published SPI-3 and SPEI-3, a training-standardized 3-month log-flow anomaly, and SSI combined with queue probability. The supplied SMA and published SPI/SPEI use an external 1981–2020 climatology, so target construction and those benchmarks are not strictly held-out. Adding queue probability to SSI did not reduce held-out Brier score in either gauge, and AUC did not improve. Queue-only indicators had small Brier skill over climatology, while the external SPEI benchmark performed better. The result is unchanged across q*=4, 6 and 8 and two missing-flow sensitivities. Under the stated proxy demand, area and supply assumptions, the queue indicators are illustrative and add no demonstrated incremental information in this pilot. Long discharge gaps, unresolved zero-flow semantics, regulation, gauge–district scale mismatch and only four held-out drought months per gauge limit inference. The negative result motivates measured-demand and multi-gauge identification studies rather than a superiority claim.

### Revised section structure

1. Introduction: anomaly indices versus accumulated unmet demand; state the negative-result question.
2. Related work: retain P01's storage/queue lineage and frozen scoped gap statement.
3. Model and conservation ledger: finite-capacity CTMC and indicators.
4. Verification: exact stationary, Floquet, DES and numerical checks.
5. Data and preprocessing: CAMELS-IND, Drought Intelligence Explorer, seven-day gap cap and actual coverage.
6. Predeclared comparison: SMA target, SSI+queue confirmatory test, external SPI/SPEI status and metrics.
7. Results: solver verification, null held-out comparison, calibration, q*/imputation sensitivities and event timing.
8. Discussion: why queue-state information may be redundant with flow under proxy demand; identifiability and data limitations.
9. Conclusion: no demonstrated incremental skill; requirements for a stronger test.
10. Data/code availability and the complete negative-results trail.

### Submission position

A single HESS-style methods/evaluation paper remains defensible **only as a transparent pilot and negative-result contribution**. It is not currently defensible as evidence that queue indicators outperform SPI/SPEI/SSI. A broader superiority claim requires more gauges and held-out drought events, measured demand or a validated demand envelope, resolved zero-flow/regulation semantics, and strict training-only SMA/SPI/SPEI baselines.
