# Merged paper plan (v2, outcome-contingent)

Date: 26 November 2026. Supersedes the 25 November v1 plan.

The v1 pilot is the motivating case study, not the evidence base. The evidence
base is the v2 rebuild: 24 CAMELS-IND gauges across 11 basins, a locked protocol,
an exact verification battery, and every predeclared sensitivity reported.

## Outcome

The **primary** predeclared confirmatory Brier endpoint (external district SMA
target) is **null**: median +0.00204, 95% CI [−0.00187, +0.00415], 10/15,
p = 0.151. The **leakage-clean** training-only SPI-3 target is **positive**:
median +0.00397, CI [+0.00013, +0.00949], 12/15, p = 0.0176, AUC +0.038
(14/15). The ranking signal is secondary (mean AUC 0.771 → 0.815); the
utilisation slope is positive but not significant (p = 0.188). The US
exploratory replication is null on both Brier and AUC once the window is
applied.

This is **Path B with a target-dependent positive**, not a superiority claim.
The paper's contribution is fourfold: one honest null, one target-dependent
positive, one verified reusable engine, and one zero-flow data-quality warning.

## Working title

**What queueing can and cannot do for low-flow hydrology: a target-dependent
deficit-queue signal, a verified engine, and a zero-flow warning**

## Central claim

A finite-capacity unmet-demand queue produces interpretable drought-state
indicators and improves event ranking and (on a leakage-clean target) calibrated
probability, but it does **not** beat SSI-3 on the primary external target and
does not replicate in the US reservoir sample. The value is conditional and
descriptive, not a general replacement for indices.

## Why one merged paper

- P01 supplies the conceptual mapping, prior art and guardrails.
- P02 supplies the actual test: observed data, held-out years, baselines, power.
- A single paper forces every conceptual claim to face data.
- It avoids a perspective paper that asks readers to wait for a methods paper.

## Structure

1. Introduction: anomaly indices versus accumulated unmet demand; what queueing
   can and cannot do; the scoped gap.
2. Related work: the queueing lineage, hydrological queue applications,
   non-stationary queues, coupled state-space drought work, ML-for-queues.
3. Design: primary E1/E2, the leakage-clean secondary, the ranking and
   conditional questions, the utilisation screen and the minimum-events rule.
4. Data: CAMELS-IND and the Drought Intelligence Explorer; Caravan-US, ResOpsUS
   and the US Drought Monitor; the zero-flow audit.
5. Methods: unit wall, demand/supply, the finite-capacity CTMC, RK4 and ledger,
   indicators, paired Brier/AUC, bootstrap and the post-hoc interpretability
   bound.
6. Results: primary null; target-dependent positive on the leakage-clean
   target; modest ranking gain; non-significant utilisation slope; the verified
   engine; the zero-flow warning; the US exploratory null.
7. Discussion: four contributions (honest null, target-dependent positive,
   verified engine, zero-flow warning), the conditional use rule, and what data
   would change the verdict.
8. Limitations and conclusion: a conditional, descriptive role for queue
   indicators, not a replacement for calibrated indices.

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
- The v1 Python code and its generated CSVs are on branch `legacy-python`
  (tag `v1-audited`); they are not part of `main`.
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
