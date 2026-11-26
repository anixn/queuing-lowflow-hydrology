# RESULTS_v2 — Multi-catchment deficit-queue evaluation (audit-corrected)

**Status:** Path B, v2.1 after the 26 November 2026 external audit. Date: 26 November 2026.
**All numbers are produced by the scripts named in §13.** They are
`[measurement]` unless marked `[assumption]`. Queue outputs are *illustrative
under the stated Stage-A demand and SUP-1 supply assumptions*; they are not
observed unmet demand.

---

## 0. One-paragraph summary

We screened 472 CAMELS-IND gauges, retained **15 endpoint gauges across 8
basins** with a V1 utilisation screen and a minimum design-event rule, and ran an
exactly verified finite-capacity queue on each. The **primary confirmatory
endpoint (external district SMA target) is null**: the paired median Brier
improvement from adding queue probability to SSI-3 is **+0.00204** with a
two-level bootstrap 95% CI of **[−0.00187, +0.00415]** and a sign test of 10/15
(p = 0.151). The prospective endpoint is also null. The minimal detectable
Brier effect at N = 15 is **0.00371**, so any true gain is below about 0.004 —
an interpretable null.

The **leakage-clean target sensitivity is positive**: with a training-only SPI-3
drought target and the matching predictor dropped, the paired median Brier
improvement is **+0.00397**, CI **[+0.00013, +0.00949]**, sign **12/15**
(p = 0.0176), with **AUC +0.0379 (14/15)**. This is a **secondary sensitivity**,
not a confirmatory win, and it is reported as such.

The ranking signal is real but modest: mean AUC rises from **0.771 (SSI-3)** to
**0.815 (SSI-3 + queue)**, and queue-alone reaches **0.846**. The utilisation
slope is directionally positive in India (+0.0066) but not significant
(p = 0.188), so the conditional rule is a hypothesis, not a demonstrated
mechanism. The US reservoir-centric pilot is an exploratory replication and is
null on both Brier and AUC once the utilisation window is applied.

---

## 1. Data and screening funnel (V1, audit-corrected)

| Step | Count | Source |
|---|---:|---|
| CAMELS-IND gauges with streamflow columns | 472 | `output/inventory.csv` |
| Profiled (>= 300 days + forcings) | 279 | `output/_recon_gauge_stats.csv` |
| Data-quality candidates (zero fraction < 0.30, interior gap <= 30 d) | 43 | `output/screen_report.csv` |
| Inside the V1 utilisation window 0.15–1.20 | 39 | `output/screen_report.csv` |
| After both-period coverage and <= 3 per basin (candidates) | 23 | `output/candidate_gauges.csv` |
| **Endpoint set (>= 5 train and >= 3 test design events)** | **15** | `output/selected_gauges.csv` |
| Basins in the endpoint set | **8** | `output/selected_gauges.csv` |

`[measurement]` The earlier “212 inside window / 24 gauges” figures came from the
V0 reconnaissance table; they are **superseded**. The authoritative screen is
V1, computed before selection. The V0 table is retained only as a profiling
record. The 8 endpoint basins are Brahmani-Baitarani (3), Cauvery (2), EFRN (1),
Krishna (3), Mahanadi (2), Mahi (1), Pennar (1) and Subernarekha (2).

**Unit wall `[assumption]`.** One claim = 20 mm over `A_cmd = f_irr ×
A_catchment` with `f_irr = 0.10`. Demand and supply share the claim volume; the
engine receives only claims/day.

---

## 2. Utilisation and regime

`[measurement]` The endpoint set has `rho` from **0.188 to 1.054** (all inside
the 0.15–1.20 window). Catchment-relative thresholds give `q* = 3–4` and
`K = 25`; peak `E[Q]` is 2.6–5.8 claims and peak `P(Q >= q*)` is 0.48–0.87. The
largest `P(Q = K)` is **6.6×10⁻⁹** (guard 10⁻³) and the ledger residual is
**1.5×10⁻¹⁵**. The blocking guard is now *enforced*, not merely recorded.

---

## 3. Confirmatory endpoint E1 — external SMA target (NULL)

Contrast on identical held-out months: `Delta_g = Brier_g(SSI-3) −
Brier_g(SSI-3 + queue)`, positive = queue improves.

| Rule | Result | Pass? |
|---|---|---:|
| median(Delta_g) > 0 | +0.002044 | yes |
| two-level bootstrap 95% CI excludes 0 | [−0.001866, +0.004154] | **no** |
| sign test p < 0.05, >= 60% improved | 10/15, p = 0.151, 66.7% | **no** |
| harm bound: no gauge Delta_g < −0.005 | 2 gauges breached | **no** |

`[measurement]` E1 fails rules 2–4. Source: `output/meta_endpoints.csv`,
`output/paired_e1.csv`.

---

## 4. Confirmatory endpoint E2 — prospective (NULL)

| Rule | Result | Pass? |
|---|---|---:|
| median(Delta_g) > 0 | −0.000662 | **no** |
| 95% CI excludes 0 | [−0.003515, +0.001296] | **no** |
| sign test p < 0.05, >= 60% improved | 7/15, p = 0.696 | **no** |
| harm bound | 3 gauges breached | **no** |

Source: `output/meta_endpoints.csv`, `output/paired_e2.csv`.

---

## 5. Ranking (secondary)

`[measurement]` Median paired `Delta AUC` is **+0.0222** (12/15) concurrently and
**+0.0156** (11/15) prospectively. Mean held-out AUC by family (E1, endpoint
set): queue alone **0.846**, SPEI-3+queue 0.841, SSI-3+SPEI-3+queue 0.839, SPI-3
0.823, SSI-3+queue **0.815**, SPEI-3 0.813, climatology 0.772, SSI-3 **0.771**.
SSI-3 is the weakest ranker in this sample; adding the queue improves it, but
SPI-3 and SPEI-3 remain better calibrated (lower Brier). The ranking gain is
secondary and is not a confirmatory claim.

A top-decile check (if only 10% of months can be monitored) gives precision
**11.5% for SSI-3 vs 14.9% for SSI-3 + queue** at an event rate of 3.9%.

---

## 6. Power / interpretability bound (post hoc)

`[measurement]` Using the paired per-unit distribution (post hoc; **not**
prospective power):

| Metric | SD | MDE at N=15 | Observed median |
|---|---:|---:|---:|
| Brier Delta | 0.005123 | **0.003706** | +0.002044 |
| AUC Delta | 0.081892 | **0.059238** | +0.022222 |

The observed Brier effect is below the MDE: the null is interpretable. The AUC
point estimate is also below its MDE at N=15, so the ranking signal is not
statistically resolvable in the cleaned sample even though its sign is positive.
The MDE is an **interpretability bound**, not evidence of prospective power.

---

## 7. Leakage-clean target sensitivity (POSITIVE, secondary)

`[measurement]` Training-only SPI-3 drought target (standardised on 1981–2010),
with the matching `spi3` predictor dropped:

| Quantity | Value |
|---|---:|
| n | 15 |
| median Delta Brier | **+0.003974** |
| 95% CI | **[+0.000134, +0.009486]** |
| sign | **12/15** (p = 0.0176, 80%) |
| harm | 0 |
| median Delta AUC | **+0.037879** (14/15) |

This is the clearest positive signal in the work: on a leakage-clean target the
queue+SSI improves both calibrated probability and ranking. It is a **secondary
sensitivity**, not the primary endpoint, and it is not upgraded. The CI lower
bound is close to zero, so the result is fragile.

---

## 8. Secondary contrasts

`[measurement]` The fair demand-side competitor (SPEI-3 + queue) is null on the
primary target: E1 median −0.000709 (6/15), E2 median −0.001866 (5/15). The
queue does not beat the index that already sees the demand channel on the SMA
target.

---

## 9. Predeclared sensitivity grid (S8)

Every one-factor-at-a-time axis on the 15-gauge endpoint set. Positive
`Delta Brier` means the queue improves. Full per-gauge table:
`output/sensitivity_grid.csv`.

| Axis | Level | median ΔBrier | 95% CI | sign | p | median ΔAUC | harm |
|---|---|---:|---|---:|---:|---:|---:|
| baseline | baseline | +0.00204 | [−0.00187, +0.00415] | 10/15 | 0.151 | +0.0222 | 2 |
| zero | V0 | +0.00283 | [−0.00031, +0.00532] | 12/15 | 0.0176 | +0.0428 | 1 |
| zero | V2 | +0.00248 | [−0.00185, +0.00414] | 10/15 | 0.151 | +0.0222 | 2 |
| f_irr | 0.03 | +0.00045 | [−0.00148, +0.00142] | 10/15 | 0.151 | +0.0175 | 1 |
| f_irr | 0.25 | +0.00473 | [−0.00053, +0.00811] | 11/15 | 0.059 | +0.0530 | 2 |
| supply | SUP-2 | +0.00717 | [+0.00004, +0.00947] | 13/15 | 0.0037 | +0.0757 | 1 |
| supply | SUP-3 | −0.00005 | [−0.00296, +0.00088] | 6/15 | 0.849 | +0.0027 | 0 |
| cap | 5 | +0.00191 | [−0.00185, +0.00395] | 10/15 | 0.151 | +0.0194 | 3 |
| cap | 20 | +0.00215 | [−0.00187, +0.00423] | 10/15 | 0.151 | +0.0194 | 2 |
| q_days | 45 | +0.00169 | [−0.00217, +0.00380] | 9/15 | 0.304 | +0.0222 | 2 |
| q_days | 90 | +0.00212 | [−0.00223, +0.00390] | 10/15 | 0.151 | +0.0194 | 3 |
| K_days | 180 | +0.00204 | [−0.00187, +0.00415] | 10/15 | 0.151 | +0.0222 | 2 |
| PET | Hargreaves | +0.00148 | [−0.00124, +0.00474] | 11/15 | 0.059 | +0.0269 | 3 |
| target | SPI3 training-only | +0.00397 | [+0.00013, +0.00949] | 12/15 | 0.0176 | +0.0379 | 0 |

**Reading the grid.**

- The **baseline is null**; only **SUP-2** and the **leakage-clean target** have
  bootstrap intervals that exclude zero. Both are sensitivity/secondary results,
  not upgrades of the confirmatory endpoint.
- **Zero-flow warning:** V0 (artifact zeros treated as real) gives a
  larger apparent gain and a significant sign test (12/15, p = 0.0176), while
  the audited V1 baseline does not. This is the data-quality warning in action.
- **Supply model matters:** SUP-2 is positive (13/15), SUP-3 is null (6/15).
- **`K_days` 180 is identical to 365** because `K` hits the 25 floor at these
  mean arrival rates; the axis is not identifiable in this sample. Reported as
  such rather than dropped.
- `f_irr = 0.25` and Hargreaves PET are positive-leaning (p = 0.059) but not
  significant; `f_irr = 0.03` is near zero.
- Cap and `q_days` are stable around the baseline.

No axis was added after the results. The grid is reported in full, including the
inconvenient rows.

---

## 10. Utilisation slope (hypothesis, not a demonstrated rule)

`[measurement]` Regressing per-unit `Delta Brier` on `rho`:

| Study | n | slope | 95% CI | p | r |
|---|---:|---:|---|---:|---:|
| India (endpoint) | 15 | +0.00664 | [−0.00369, +0.01697] | 0.188 | +0.359 |
| USA (in-window) | 14 | −0.01567 | [−0.05563, +0.02428] | 0.409 | −0.240 |
| USA (full) | 21 | −0.00024 | [−0.00138, +0.00090] | 0.664 | −0.101 |

The India slope is positive but not significant. The conditional rule (“the
queue helps when the system is stressed”) is therefore a **hypothesis** with a
consistent sign, not a demonstrated mechanism. Source: `output/rho_slope.csv`.

---

## 11. US reservoir-centric pilot (exploratory)

`[measurement]` With the same $\rho$ window, the US primary sample has **14
paired reservoirs**: E1 median **+0.000388** (CI [−0.010481, +0.009345]; 7/14,
p = 0.605; Delta AUC +0.0077), E2 median −0.002387. The full 21-reservoir sample
is also null on Brier (+0.000793, 12/21, p = 0.332; Delta AUC +0.0105). With the
window applied the US arm is null on **both** Brier and AUC. It is an
**exploratory replication**, not a second confirmatory test. Source:
`analysis/P02_methods/US_PILOT_RESULTS.md`, `output_us/us_meta.csv`.

---

## 11b. Common-protocol India–US comparison (null in both)

`[measurement]` Under the like-for-like protocol (`protocol/COMMON_PROTOCOL.md`:
common `Kc = 0.8`, SUP-1, training-only SPI-3 target, same split), the queue does
not improve the SPI-3 target in either region:

| Region | n | median Delta Brier | 95% CI | sign | p | median Delta AUC |
|---|---:|---:|---|---:|---:|---:|
| India | 15 | −0.000321 | [−0.001268, +0.003946] | 6/15 | 0.849 | +0.0025 |
| USA | 240 | +0.000423 | [−0.000081, +0.000851] | 131/240 | 0.088 | 0.0000 |
| USA − India | — | +0.000745 | [−0.003298, +0.001489] | — | — | — |

The region difference includes zero and the ranking gain is effectively zero in
both regions. **The earlier India positive is target- and demand-model-dependent,
not a general queue advantage.** Source:
`analysis/P02_methods/COMMON_RESULTS.md`, `output_compare/`.

---

## 12. Outcome routing — Path B, with a target-dependent signal

The primary confirmatory endpoints are null while the design is verified and the
effect bound is interpretable, so the outcome is **Path B** per plan §8. The
paper is a methods and negative-result contribution with three additional
assets: a **target-dependent positive** (leakage-clean target), a **ranking
signal** (India, secondary), a **verified reusable engine**, and a **zero-flow
data-quality warning**. No v1 number is cited as a v2 result.

---

## 13. Reproduction

```powershell
Rscript steps/step_00_setup.R
Rscript steps/step_02_india_pipeline.R
Rscript steps/step_03_india_power.R
Rscript steps/step_04_india_sensitivity.R   # full grid, long
Rscript steps/step_05_india_figures.R
Rscript steps/step_10_usa_eval.R
Rscript steps/step_11_manuscript_figures.R
Rscript steps/step_12_verify.R
```

Every CSV carries a JSON sidecar with the git hash, **code hash**, parameters,
seed and `sessionInfo`. `output/` is never hand-edited.

---

## 14. Honest limitations

- `[assumption]` Demand is a Stage-A crop-water envelope (`f_irr = 0.10`), not
  measured irrigation; the `f_irr` sweep carries the uncertainty.
- `[assumption]` Supply is SUP-1 (50% firm share, 10 mm/day cap).
- `[measurement]` Zero-flow classification uses same-basin peers (proxy grade).
- `[measurement]` The primary SMA target is not strictly leakage-free; the
  training-only SPI-3 target is the clean check and is **positive**, but it is a
  secondary sensitivity with a CI close to zero.
- `[measurement]` The India utilisation slope is not significant (p = 0.188).
- `[measurement]` The US arm is exploratory and null on both endpoints with the
  window applied; 14 paired reservoirs.
- `[measurement]` `renv` is not installed; no lockfile.
