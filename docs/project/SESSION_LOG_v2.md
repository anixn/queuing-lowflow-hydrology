# SESSION LOG v2 — R rebuild and Path-B outcome

Date: 26 November 2026. One paragraph of plain language per stage, with gate
reports and sources. This log replaces the v1 session record for the rebuild.

---

## 0. One-paragraph summary of what changed and why

The v1 Python pilot's null was not interpretable: it mixed units, sat at
utilisation `rho ~ 0.02–0.08` where a null is guaranteed, and tested two gauges
with four held-out drought months each. We rebuilt the entire analysis in R and
R Markdown, archived the Python on `legacy-python` (tag `v1-audited`), and
predeclared a multi-catchment design with one claim volume per gauge,
catchment-relative thresholds, a utilisation screen, a locked protocol, and every
sensitivity reported. The rebuild keeps the verified queue mathematics. The
confirmatory Brier endpoints are still null, but now the null is **powered and
clean**, so it is a publishable Path-B result rather than an artifact.

---

## 1. Gate G1 — engine and verification (PASS)

`Rscript R/verify/run_tests.R` -> **14/14**.

| Check | Result |
|---|---|
| V1 M/M/1/K closed form | max abs diff 1.39e-17 |
| V2 M/M/c/K closed form | max abs diff 2.78e-17 |
| V3 RK4 converges to stationary | E[Q] diff 1.78e-15 |
| V4 RK4 vs thinning DES (seasonal) | 2.0318 vs 2.0465 (0.72%, 23,924 events) |
| V5 conservation ledger | max per-day residual 1.25e-15 |
| V6 first passage vs simulation | 10.467 vs 10.368 (2 SE 0.435) |
| V7 blocking guard | P(Q=K)=0.499 triggers rerun suggestion |
| V8 unit wall | claim volumes differ per gauge by design |
| V9 Hargreaves 0.408 | Ra(0,80)=37.824 (ref 37.8) |
| V10 relative thresholds | q*, K scale with `lam_bar` |
| V11 indices | direct diff 0, mean z 2.17e-17 |
| V12 metrics | hand cases exact |
| V13 zero classifier | labels exact |
| V14 gap rule | 6-day pause, long-gap month exclusion |

Source: `R/verify/run_tests.R`, `R/verify/verify_engine.R`.

## 2. Gate G2 — inventory and zero audit (PASS)

- Inventory covers **472** CAMELS-IND gauges (`output/inventory.csv`).
- Every selected gauge has a zero-classification table with `match_grade =
  "proxy"` (`output/zero_audit_summary.csv`). No independent CWC/India-WRIS
  daily record was available; this is the plan's documented fallback.
- Unresolved-zero fraction is computed per gauge; V1 is the primary treatment,
  V0/V2 are sensitivities.
- Gap tables are complete; V13/V14 pass on real fixtures.

Source: `output/inventory.csv`, `output/zero_audit_summary.csv`,
`R/10_data/01_inventory.Rmd`, `R/10_data/02_zero_audit.Rmd`.

## 3. Gate G3 — utilisation window (PASS)

Screening funnel:

| Step | Count |
|---|---:|
| Gauges with streamflow columns | 472 |
| Profiled (>= 300 days + forcings) | 279 |
| Inside `rho` window 0.15–1.20 (SUP-1) | 212 |
| Strict data-quality screen | 40 |
| Both-period coverage + <= 3/basin | **24** |
| Basins represented | **11** |

Realised `rho` range for selected gauges: **0.152–1.164**. Gate G3 requires
`>= 15` in-window gauges; 24 qualify. Source: `output/screen_report.csv`,
`output/selected_gauges.csv`, `R/20_rates/06_build_rates.Rmd`.

## 4. Gate G4 — protocol lock and power (PASS)

- `protocol/PROTOCOL_v2.md` locked; tag `protocol-v2-locked`.
- Power using the paired per-gauge effect-size distribution:
  - Brier SD 0.004661, **MDE(N=24)=0.002666**, observed median +0.000847.
  - AUC SD 0.078637, **MDE(N=24)=0.044970**, observed median +0.042763.
- Simulation sign-test power at N=24: 0.722 for +0.05 AUC, 0.983 for +0.08.
- G4 passes because the AUC MDE is at or below the predeclared +0.05 grid point.

Source: `output/power_analysis.csv`, `output/power_grid.csv`,
`R/analysis/power_analysis.R`.

## 5. Gate G5 — outcome routing (Path B)

### Confirmatory endpoints (paired, identical held-out months)

| Endpoint | median Delta_g | 95% CI | sign | p | harm | Pass |
|---|---:|---|---:|---:|---:|---|
| E1 concurrent | +0.000847 | [−0.001115, +0.001716] | 15/24 | 0.154 | 4 | **no** |
| E2 prospective | −0.000331 | [−0.001667, +0.000574] | 12/24 | 0.581 | 3 | **no** |

Both fail rules 1–4. Source: `output/meta_endpoints.csv`,
`output/paired_e1.csv`, `output/paired_e2.csv`.

### Secondary contrast (not upgradable)

| Endpoint | median Delta AUC | gauges improved |
|---|---:|---:|
| E1 concurrent | +0.042763 | 19/23 |
| E2 prospective | +0.015625 | 15/23 |

The queue improves ranking but not calibrated drought probability; reliability
shows both models over-predict at low probability. Source:
`output/meta_endpoints.csv`, `figures/fig06_reliability.png`.

### Route

**Path B — honest null.** The paper is the predeclared multi-catchment
evaluation plus the utilisation diagnosis. No superiority claim.

## 6. Methodological correction made during S9 (pre-lock)

The first draft formed the confirmatory estimate from year-averaged deltas and,
in the sensitivity script, from unpaired family-specific metrics. The protocol
defines `Delta_g` as the **paired** per-gauge Brier difference on identical
months. This was fixed in `stage7_paired_stats()` / `stage7_paired_bootstrap()`
and recorded in `protocol/CHANGELOG.md`. The corrected E1 estimate (+0.000847,
CI [−0.001115, +0.001716]) is still null, so the conclusion is unchanged; the
number and interval were corrected everywhere.

## 7. What moved (numbers with units and sources)

- 24 gauges across 11 basins, `rho` 0.152–1.164 (`output/selected_gauges.csv`).
- `q* = 3–5` claims (60 days of mean demand), `K = 25–26` (`output/queue_meta.csv`).
- max `E[Q]` 2.4–6.6 claims; max `P(Q>=q*)` 0.29–0.89 (`output/queue_meta.csv`).
- max `P(Q=K)` 4.8e-8, far below the 1e-3 guard; ledger residual ~1e-15.
- E1 median `Delta_g` +0.000847, CI [−0.001115, +0.001716] (`output/meta_endpoints.csv`).
- E1 secondary median `Delta AUC` +0.042763, 19/23 (`output/paired_e1.csv`).
- Brier MDE at N=24 = 0.002666; AUC MDE = 0.044970 (`output/power_analysis.csv`).

## 7b. US reservoir-centric pilot (26 November 2026)

**Why.** Caravan-US is better instrumented than CAMELS-IND, and ResOpsUS provides
measured reservoir operations. The first attempt to pair reservoirs with CAMELS
gauges failed the feasibility test: only **2 of 678** ResOpsUS reservoirs fall
inside a Caravan catchment polygon, because the large reservoirs are downstream
of the small headwater basins. The unit of analysis was therefore changed to the
**reservoir**.

**Sample.** Caravan-US has 671 catchments (310 irrigated, 59 regulated, 24 with
both). The reservoir-centric core has **50** reservoirs with a ResOpsUS outflow
record and an irrigated Caravan catchment within 20 km; 49 run, 45 have at least
120 months, and **21** have paired test-window predictions. Target: USDM monthly
mean DSCI $\ge 100$ (D1+), 10,681 complete reservoir-months across 48
reservoirs, event rate 34.7%. Supply is measured outflow; demand is
$K_c\,\mathrm{ET}_0$ with $K_c=0.8$ (declared).

**Regime and honesty devices.** $\rho$ 0.103–25.44 (27 reservoirs inside the
0.15–1.20 window); $q^*$ 3–8; $K$ 25–80; max $\Pr(Q=K)$ $1.7\times10^{-6}$;
ledger residual $3.5\times10^{-15}$.

**Result.** The USA pilot reproduces the India pattern. E1 median Brier
improvement $+0.000793$ (95% CI $[-0.004651, +0.007736]$; 12/21, $p=0.332$);
E2 median $-0.000187$ (CI $[-0.004643, +0.011411]$; 10/21, $p=0.668$). Secondary
AUC: $+0.0105$ (E1) and $+0.0296$ (E2). Mean E1 Brier: SSI-3 0.2094, SSI-3 +
queue 0.2074; AUC 0.631 and 0.646.

**Interpretation.** Two independent tests now agree: no calibrated-probability
gain, a small ranking gain. The utilisation diagnosis is the transferable result;
it shows a positive $\rho$ slope in India and a flat relationship in the USA,
where the command-area proxy and the constant $K_c$ dominate. This strengthens
the Path-B framing rather than overturning it.

**Files.** `R/us_pilot/01…08`, `output_us/`, `analysis/P02_methods/US_PILOT_RESULTS.md`,
`figures/fig_study_map`, `figures/fig_india_us_comparison`,
`figures/fig_utilisation_diagnosis`.

**Known US limitations.** 21 paired reservoirs; command area is a
nearest-catchment proxy; $K_c=0.8$ is not yet calibrated; OpenET quota is
exhausted until 1 December 2026; USDM county DSCI is coarse.

## 7c. Code and manuscript organization (26 November 2026)

The working code was reorganized into a numbered, linear sequence for both
studies:

- `steps/step_00_setup.R` … `step_12_verify.R`, plus `steps/run_all_steps.R`.
- `steps/rmd/step_00_overview.Rmd` … `step_11_comparison.Rmd`, all rendered and
  asserting the written outputs.
- `HELP.md` — operator's manual (requirements, data layout, every step, outputs,
  credentials, troubleshooting, reproducibility).
- `R/00_utils/README.md` — function-library map and invariants.
- `manuscript/MANUSCRIPT.md` — HESS-style draft with literature, hypothesis,
  LaTeX methods, results, India–USA comparison, discussion, limitations and
  figure captions.
- `manuscript/SUPPLEMENT_LITERATURE.md` (2,479 words, 49 audited references,
  frozen gap sentence verbatim) and `manuscript/SUPPLEMENT_METHODS.md` (2,798
  words, full LaTeX equations).
- New figures: workflow, two-panel study map, India–USA comparison, utilisation
  diagnosis.

The verification battery still passes **14/14** after the reorganization.

## 7d. Audit response and reframing (26 November 2026)

The external audit (`REPO_AUDIT_v2_2026-11-26.md`) found the engine and endpoint
arithmetic sound, but the pre-registration packaging overstated. We accepted the
audit and implemented Route A.

**Integrity fixes.**

- Committed the governing plan at `protocol/REDESIGN_PLAN_v2_R.md`; added a
  timing disclosure to `PROTOCOL_v2.md`; added a `code_hash` to every sidecar.
- Replaced the V0 reconnaissance selection with the **V1** screen computed
  before selection.
- Added a **design-event rule** (at least 5 training and 3 test events): 23
  candidates reduce to **15 endpoint gauges across 8 basins**.
- Reran the strict-target sensitivity **paired**. It is **positive**: median
  +0.00397, 95% CI [+0.00013, +0.00949], 12/15, p = 0.0176, AUC +0.038
  (14/15). This is the buried positive the audit said was contradicted.
- Primary E1 remains **null**: +0.00204, CI [−0.00187, +0.00415], 10/15,
  p = 0.151; E2 null.

**Honest tempering.**

- Power at N=15: Brier MDE 0.0037, so the primary null is interpretable; but
  sign-test power for a +0.05 AUC uplift is only **0.394**, so the ranking
  signal is secondary and hypothesis-generating, not powered.
- India ρ slope +0.0066, p = 0.188: the “stressed basins only” rule is a
  hypothesis, not a demonstrated mechanism.
- US arm relabelled **exploratory**; with the ρ window the primary sample is 14
  paired reservoirs and is null on **both** Brier and AUC. The India ranking
  signal does not replicate.

**Protocol–code alignment.** The blocking guard is enforced; PET substitution is
flagged; SUP-2 uses training-only quantiles; negative discharge is treated as
missing; the unused warm-up config is removed; the implemented gap rule is
recorded in the changelog.

**Reframing.** The paper is now “What queueing can and cannot do for low-flow
hydrology”, with four contributions: (1) one honest null; (2) one
target-dependent positive; (3) one verified reusable engine; (4) one zero-flow
data-quality warning.

The full 14-config sensitivity grid is running on the 15-gauge endpoint set. The
V0 row already shows a larger apparent Brier gain than V1 (+0.00283 vs +0.00206),
which is the zero-flow warning in action; `RESULTS_v2.md` §9 will be filled when
the grid completes.

## 8. Blocked / disclosed

- `renv` not installed; no lockfile. Documented gap.
- Independent zero-flow record unavailable; proxy grade only.
- Stage-B measured demand unavailable; Stage-A envelope with `f_irr` sweep.
- External SMA target not strictly leakage-free; clean SPI-3 sensitivity shown.
- Future-climate stage gated; no raw CMIP6 number.

## 9. Exact next action

Author sign-off on (a) the Path-B framing in `docs/project/MERGED_PAPER_PLAN.md`,
(b) the Gate B checklist author items, and (c) submission metadata/archive.
No further analysis changes are permitted without a protocol changelog entry.
