# Merged paper plan (v2, outcome-contingent)

Date: 26 November 2026. Supersedes the 25 November v1 plan.

The v1 pilot is the motivating case study, not the evidence base. The evidence
base is the v2 rebuild: 24 CAMELS-IND gauges across 11 basins, a locked protocol,
an exact verification battery, and every predeclared sensitivity reported.

## Outcome

The predeclared confirmatory Brier endpoints (E1 concurrent, E2 prospective) are
**null**. The secondary AUC contrast is positive but is not upgradable. This
routes to **Path B** in `REDESIGN_PLAN_v2_R.md` §8:

> *Path B — honest null: the paper is the predeclared evaluation + utilization
> diagnosis: rho distribution across basins, the regime table, what demand/supply
> regimes would put the queue in its informative window, and the new descriptive
> quantities (unmet volume, recovery times) the queue formulation provides.*

## Working title

**Does a deficit queue add drought information? A predeclared multi-catchment
test and a utilization diagnosis**

## Central claim

A finite-capacity unmet-demand queue produces interpretable drought-state
indicators, but in this multi-catchment test it does **not** improve calibrated
drought probability beyond SSI-3. The utilization diagnosis explains when the
queue is informative and what data a stronger test requires.

## Why one merged paper

- P01 supplies the conceptual mapping, prior art and guardrails.
- P02 supplies the actual test: observed data, held-out years, baselines, power.
- A single paper forces every conceptual claim to face data.
- It avoids a perspective paper that asks readers to wait for a methods paper.

## Structure

1. Introduction: anomaly indices versus accumulated unmet demand; the question.
2. Related work: storage/queue lineage and the frozen scoped gap.
3. Model and unit system: per-gauge claim volume and conservation ledger.
4. Verification: exact stationary, RK4 vs discrete-event, first passage, ledger.
5. Data and screening: CAMELS-IND, zero audit, utilization window, 24 gauges.
6. Predeclared comparison: E1/E2, harm bound, power, target decision.
7. Results: null confirmatory Brier, secondary AUC, regime table, sensitivities.
8. Utilization diagnosis: why v1 failed and which regimes are informative.
9. Discussion: identifiability, proxy demand, zero flows, regulation, scale.
10. Conclusion: no demonstrated calibrated-probability skill; requirements for a
    stronger test; data/code availability.

## Minimum evidence (all present in v2)

- Exact solver agreement (14/14 battery).
- Reproducible multi-catchment queue series (`output/queue_meta.csv`).
- Held-out comparison against climatology, SPI-3, SPEI-3, SSI-3 and SSI+queue.
- Paired confirmatory statistic on identical held-out months.
- Power / minimal detectable effect (`output/power_analysis.csv`).
- Every predeclared sensitivity axis (`output/sensitivity_meta.csv`).
- Honest limitations on demand proxy, zero flows, regulation and scale.
- The v1 two-gauge pilot as a boxed motivating case study (with the audit's
  numbers), never as a v2 result.

## What happens to existing material

- Keep the literature audit and the frozen gap sentence verbatim.
- Retire the v1 Python code and its generated CSVs to `legacy-python` /
  `analysis/P02_methods/data_v1_superseded/` (provenance only).
- Compress the long perspective narrative.
- Retain the mapping, conservation ledger and exact benchmarks, now in R.
- Do not imply the synthetic 2.3x averaging result is an empirical finding.

## Gate

The paper is viable only as a transparent methods + negative-result
contribution. It is **not** evidence that queue indicators outperform
SPI/SPEI/SSI. A superiority claim would require measured demand, independent
zero-flow/regulation records, a strictly leakage-free external benchmark, and a
stronger multi-gauge test that beats climatology on held-out data — none of
which exists in this build.
