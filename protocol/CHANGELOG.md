# Protocol changelog

All amendments to `protocol/PROTOCOL_v2.md` after the `protocol-v2-locked` tag
are recorded here with date, reason and scope. Any amendment that touches a
confirmatory endpoint forces a rerun of S7–S8 with both old and new results
reported.

## 2026-11-26 — protocol locked

- Locked `PROTOCOL_v2.md` and tagged `protocol-v2-locked`.
- Scope: the predeclared design of `REDESIGN_PLAN_v2_R.md`. No endpoint,
  contrast, target or variant was changed after seeing a held-out metric.

## 2026-11-26 — paired-statistic clarification (pre-lock)

- **Reason:** the first implementation formed the confirmatory estimate from
  year-averaged deltas and, in the sensitivity script, from unpaired
  family-specific metrics. This was a specification inconsistency, not a result.
- **Scope:** the confirmatory statistic is now the **paired** per-gauge Brier
  difference on identical held-out months (`stage7_paired_stats`,
  `stage7_paired_bootstrap`). The predeclared endpoint definition did not change;
  the implementation now matches it. The corrected E1 estimate is reported in
  `analysis/P02_methods/RESULTS_v2.md`.
- **Effect on conclusions:** none — the corrected interval still includes zero
  and the sign test is still non-significant.
