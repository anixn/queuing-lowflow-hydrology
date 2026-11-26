# Protocol changelog

All amendments to `protocol/PROTOCOL_v2.md` after the `protocol-v2-locked` tag
are recorded here with date, reason and scope. Any amendment that touches a
confirmatory endpoint forces a rerun of S7–S8 with both old and new results
reported.

## 2026-11-26 — audit-driven amendments (v2.1)

A deep external audit (REPO_AUDIT_v2_2026-11-26.md) found that the engine and
arithmetic were sound but the packaging overstated the pre-registration. The
following changes were made and all affected results were rerun.

### Pre-registration posture (F1, F2)

- The governing plan `protocol/REDESIGN_PLAN_v2_R.md` is now committed, so the
  endpoints, contrasts and rules can be checked against a dated document.
- **Timing disclosure:** the endpoints were fixed by that governing plan, but
  the protocol document itself was finalised after the first execution. The
  paper no longer claims a prospective pre-registration; it states that the
  design was pre-specified in the plan and documented retrospectively, with the
  timing disclosed.
- Sidecars now record a `code_hash` (fingerprint of `R/` and `steps/`) in
  addition to the git hash, so an output identifies the code that produced it
  even when the working tree is uncommitted.

### Selection (F7, F8)

- The authoritative screen is now the **V1** screen (`stage3_screen` with the
  zero audit), computed **before** selection. The V0 reconnaissance `rho` is no
  longer used to select gauges; the recon file is retained only as a profiling
  record. The funnel counts are relabelled accordingly.
- Minimum design-event rule: a unit enters the confirmatory set only with
  **≥5 training events and ≥3 test events** in the complete-month design. The
  rule is applied to the design counts, not raw district months, so zero- and
  one-event units cannot enter the endpoint as noise.
- The previous 24-gauge set and its endpoints are superseded; the recomputed
  set is reported in `output/selected_gauges.csv` with `in_endpoint`.

### Statistics (F3, F5, F4, F6)

- The power/MDE analysis is **post hoc**: it is computed from the held-out
  per-unit deltas. It is now reported as an **interpretability bound** ("any
  true Brier gain is below about 0.003 at 24 units"), not as evidence that the
  study was prospectively powered. The "G4 passes / powered design" language is
  removed.
- The strict-target (training-only SPI-3) sensitivity is rerun with the
  **paired** statistic; its Brier and AUC deltas are both reported. The earlier
  "remains null" sentence, which was based on unpaired metrics, is replaced by
  the paired result.
- The full one-factor sensitivity grid is run with the current paired script;
  the placeholder in `RESULTS_v2.md` §9 is removed and every axis level is
  reported.

### Protocol–code alignment (F9–F13)

- **Gap rule:** the implemented rule is stricter than the plan: every missing
  day pauses the state, and any month containing a missing day is excluded.
  The protocol text is amended to the implemented rule (this changelog entry is
  the amendment); V14 remains a valid test of the declared behaviour.
- **Blocking guard:** now enforced with an explicit `stop()` when
  `max P(Q=K) >= 1e-3`, not merely recorded.
- **Warm-up:** the unused `warmup_start`/`warmup_discard` config entries are
  removed; the chain starts empty at 1981-01-01. The early-month bias is
  negligible at the service rates used and is disclosed.
- **Event definition:** the confirmatory endpoints score monthly outcomes. The
  plan's ≥2-consecutive-month event definition is not used; this is disclosed
  as a limitation rather than silently omitted.
- **PET substitution:** a `pet_source_used` column records every Hargreaves
  fallback day; no substitution is silent.
- **SUP-2:** the 5th-percentile dependable flow is estimated on training years
  only; gauges with no training-period flow fall back to the full record.
- **Negative flow:** negative discharge is treated as missing with an explicit
  per-gauge message.

### Model fitting (F15)

- The confirmatory families are still fitted on their own complete-case
  training rows; the paired contrast is scored on the intersection. This is
  disclosed. A common-sample refit is a possible future sensitivity, not a
  hidden choice.

### US arm (F16–F19)

- The US arm is labelled an **exploratory replication**, not a second
  predeclared confirmatory test.
- The predeclared `rho` window is applied to the primary US sample; the full
  sample is reported as a sensitivity. The window composition is stated.
- A regression of incremental skill on `rho` is reported for both studies
  (`output/rho_slope.csv`), replacing the unsupported "positive slope" claim.
- The US demand model uses `s_firm = 1` (measured outflow) and `K` from
  reservoir storage; these design differences are stated in the manuscript.
- The hardcoded Caravan/ResOpsUS paths are moved to `R/config.R`.

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
