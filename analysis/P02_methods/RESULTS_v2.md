# RESULTS_v2 — Multi-catchment deficit-queue evaluation (honest-null outcome)

**Status:** Path B (predeclared evaluation + utilisation diagnosis). Date: 26 November 2026.
**All numbers below are produced by the scripts named in §12.** They are
`[measurement]` unless marked `[assumption]`. Queue outputs are *illustrative
under the stated Stage-A demand and SUP-1 supply assumptions*; they are not
observed unmet demand.

---

## 0. One-paragraph summary

We screened 472 CAMELS-IND gauges, kept 24 across 11 basins that sit inside a
predeclared utilisation window and span both the training (1981–2010) and test
(2011–2020) periods, and ran an exactly verified finite-capacity queue for each.
The **predeclared confirmatory endpoint (E1: Brier score of SSI-3 vs SSI-3 +
queue) is null**. On identical held-out months, the median per-gauge Brier
improvement is **+0.000847** with a two-level bootstrap 95% CI of
**[−0.001115, +0.001716]** (includes zero) and a one-sided sign test of 15/24
(p = 0.154). The **prospective endpoint (E2) is also null** (median −0.000331,
12/24, p = 0.581). A power analysis shows the Brier minimal detectable effect at
N = 24 is 0.002666, so the null means any Brier gain is smaller than about
0.003 — it is an interpretable null, not an underpowered one. The **secondary AUC
endpoint does improve**: median ΔAUC = +0.0428 (19/23 gauges) concurrently and
+0.0156 (15/23) prospectively. The queue therefore improves *discrimination* but
not *calibrated probability* for rare drought events; this secondary signal is
reported and **not** upgraded to a confirmatory claim.

---

## 1. Data and screening funnel

| Step | Count | Source |
|---|---|---:|
| CAMELS-IND gauges with streamflow columns | 472 | `output/inventory.csv` |
| Profiled (>= 300 days flow + forcings) | 279 | `output/_recon_gauge_stats.csv` |
| Inside utilisation window 0.15 <= rho <= 1.20 (SUP-1) | 212 | `output/screen_report.csv` |
| Strict data-quality screen (zero_frac < 0.30, interior gap <= 30 d) | 40 | `output/screen_report.csv` |
| Both-period coverage (>= 3 y train, >= 2 y test) + <= 3 per basin | **24** | `output/selected_gauges.csv` |

`[measurement]` The 24 analysis gauges span 11 basins: Brahmani-Baitarani (3),
Cauvery (2), EFRN (1), Godavari (3), Krishna (3), Mahanadi (2), Mahi (3),
Narmada (1), Pennar (1), Subernarekha (2), WFRS (3). Utilisation rho (SUP-1)
ranges **0.152 to 1.164**. Gate G3 requires >= 15 gauges in the window; 24
qualify, so the confirmatory framing is permitted subject to power (§7).

**Unit wall `[assumption]`.** One claim = 20 mm of water over the command area
`A_cmd = f_irr * A_catchment` with `f_irr = 0.10`. Demand and supply share that
single claim volume per gauge (`R/00_utils/units.R`); the queue engine receives
only claims/day.

---

## 2. Utilisation screen (Figure 1)

`[measurement]` Across the 279 profiled gauges, 212 (76%) fall inside the
predeclared window under SUP-1; the median rho is 0.48. This is the central
design fix relative to the v1 pilot, which sat at rho ≈ 0.02–0.08 where a null
is guaranteed. For the 24 selected gauges, all lie in the window by
construction. See `figures/fig01_utilization_screen.png`.

---

## 3. Queue regime (Figure 2)

`[measurement]` Catchment-relative thresholds give q\* = 3–5 claims (60 days of
mean demand) and K = 25–26 (≈1 year), theta = 1.5·q\*. Across the 24 gauges the
peak expected backlog `max_t E[Q]` ranges 2.4–6.6 claims and the peak
severe-backlog probability `max_t P(Q >= q*)` ranges 0.29–0.89. The blocking
guard never fired: the largest `max_t P(Q = K)` is 4.8×10⁻⁸, far below the 10⁻³
threshold. The conservation ledger holds on every day of every run (max per-day
residual ≈ 1.7×10⁻¹⁵). See `output/queue_meta.csv`,
`figures/fig02_regime_pq.png`, `figures/fig02_regime_eq.png`.

---

## 4. Confirmatory endpoint E1 — concurrent Brier (NULL)

Contrast on the **same** held-out months: `Delta_g = Brier_g(SSI-3) −
Brier_g(SSI-3 + queue)`, positive = queue improves. Target: district
soil-moisture anomaly <= −15% (external product; 1981–2020 climatology leakage
disclosed).

| Rule (protocol §9) | Result | Pass? |
|---|---|---:|
| median(Delta_g) > 0 | +0.000847 | yes |
| two-level bootstrap 95% CI excludes 0 | [−0.001115, +0.001716] | **no** |
| sign test one-sided p < 0.05, >= 60% improved | 15/24, p = 0.154, 62.5% | **no** |
| harm bound: no gauge Delta_g < −0.005 | 4 gauges breached | **no** |

`[measurement]` E1 fails rules 2–4. Source: `output/meta_endpoints.csv` (row
E1), `output/paired_e1.csv`, `figures/fig03_brier_forest_e1.png`.

---

## 5. Confirmatory endpoint E2 — prospective (1-month lead) Brier (NULL)

All predictors taken at month t−1 (SSI-3 at t−1; mean and increment of
P(Q >= q\*) over t−1) predicting the drought outcome at month t.

| Rule | Result | Pass? |
|---|---|---:|
| median(Delta_g) > 0 | −0.000331 | **no** |
| 95% CI excludes 0 | [−0.001667, +0.000574] | **no** |
| sign test p < 0.05, >= 60% improved | 12/24, p = 0.581, 50% | **no** |
| harm bound | 3 gauges breached | **no** |

`[measurement]` E2 fails all four rules. Source: `output/meta_endpoints.csv`
(row E2), `output/paired_e2.csv`.

---

## 6. Secondary endpoint — AUC (positive signal, not upgradable)

`[measurement]` The queue improves discrimination on held-out months even though
Brier does not:

| Endpoint | median Delta AUC | mean Delta AUC | gauges improved |
|---|---:|---:|---:|
| E1 concurrent (SSI-3 -> SSI-3 + queue) | +0.0428 | +0.0453 | 19 / 23 |
| E2 prospective | +0.0156 | +0.0289 | 15 / 23 |

Mean held-out AUC by family (E1): `queue` alone 0.848, `SSI-3 + queue` 0.841,
`SSI-3` 0.796, climatology 0.783. The queue carries real ranking information
that SSI-3 alone does not. **Per the locked protocol, AUC is a secondary endpoint
and is reported, never upgraded post hoc.** Source: `output/metrics_e1.csv`,
`output/paired_e1.csv`, `figures/fig04_auc_forest.png`.

---

## 7. Power / minimal detectable effect (G4)

`[measurement]` Using the paired per-gauge effect-size distribution:

| Metric | SD | MDE at N=24 (alpha=0.05, power=0.80) | Observed median |
|---|---:|---:|---:|
| Brier Delta | 0.004661 | 0.002666 | +0.000847 |
| AUC Delta | 0.078637 | 0.044970 | +0.042763 |

The observed Brier effect (0.0008) is well below the Brier MDE (0.0027): the
null is *interpretable*. The AUC MDE (0.0450) is at the predeclared +0.05 grid
point, so **G4 passes** (the study is powered to detect a +0.05 AUC uplift at
N=24). Simulation sign-test power at N=24 is 0.722 for +0.05 AUC and 0.983 for
+0.08. Source: `output/power_analysis.csv`, `output/power_grid.csv`.

---

## 8. Harm bound and reliability (Figure 6)

`[measurement]` Four gauges breach the −0.005 Brier harm bound concurrently
and three prospectively (exact gauge list in `output/paired_e1.csv` and
`output/paired_e2.csv`). Pooled
reliability shows **both** SSI-3 and SSI-3 + queue over-predict drought at low
probabilities (predicted 0.15–0.5, observed 0.05–0.1); the queue does not repair
this calibration gap, which is why Brier does not improve even as AUC does.
Source: `figures/fig06_reliability.png`, `output/paired_e1.csv`. The harm-bound
breach is recorded as a limitation; no positive claim is made, so it does not
block the Path-B framing.

---

## 9. Predeclared sensitivity grid (S8)

<!-- SENSITIVITY_TABLE -->

---

## 10. Leakage-clean target sensitivity

`[measurement]` Replacing the external SMA target with a training-only
(1981–2010) SPI-3 drought target and dropping the matching `spi3` predictor
(circularity guard) does not change the conclusion: the primary SSI-3 vs SSI-3 +
queue contrast remains null. Source: `output/sensitivity_strict_e1.csv` and the
`target: SPI3_training_only` row of `output/sensitivity_meta.csv`.

---

## 11. Predeclared secondary contrasts

`[measurement]` The fair demand-side competitor (`spei3` vs `spei3 + queue`) is
also null: E1 median Delta = −0.000292 with CI [−0.003647, +0.001016] (11/24),
E2 median Delta = −0.001272 (9/24). The queue does not beat the index that
already sees the demand channel. Source: `output/meta_endpoints.csv`
(rows `E1_spei3_contrast`, `E2_spei3_contrast`).

---

## 12. Outcome routing — Path B

Because both confirmatory endpoints fail while the test is powered and clean,
the outcome is **Path B (honest null)** per plan §8:

> "Does a deficit queue add drought information? A predeclared multi-catchment
> test and a utilization diagnosis."

The headline is the utilisation table and the Brier-null / AUC-positive split:
the queue re-orders drought risk (discrimination) but does not produce
better-calibrated drought probabilities for these catchments and this target.
This is reported unchanged; no v1 number is cited as a v2 result.

### Methodological correction (recorded, not hidden)

The first draft of this document quoted a median of +0.00048 computed from
year-averaged deltas, and the sensitivity draft compared families on different
complete-case samples. The protocol defines `Delta_g` as the **paired** per-gauge
Brier difference on identical held-out months. The corrected estimate is
+0.000847 (CI [−0.001115, +0.001716]). The direction and the null conclusion are
unchanged; the number and interval are corrected everywhere. See
`protocol/CHANGELOG.md`.

---

## 13. Reproduction

```powershell
Rscript R/verify/run_tests.R            # G1: 14/14
Rscript R/run_pipeline.R                # S2-S7: writes output/*.csv + sidecars
Rscript R/analysis/power_analysis.R     # S4: power / MDE
Rscript R/analysis/sensitivity_grid.R   # S8: every predeclared axis
Rscript R/analysis/make_figures.R       # figures/*.pdf + *.png
Rscript R/run_all.R                     # renders notebooks; fails on any bad assertion
```

Every CSV carries a JSON sidecar with the git hash, parameters, seed and
`sessionInfo`. `output/` is never hand-edited. `protocol/PROTOCOL_v2.md` is the
locked predeclared protocol.

---

## 14. Honest limitations

- `[assumption]` Demand is a Stage-A crop-water envelope (`f_irr = 0.10`), not
  measured irrigation; Stage-B demand data were unavailable. The `f_irr` bounds
  sweep is the declared uncertainty envelope.
- `[assumption]` Supply is SUP-1 (50% firm share of observed flow, capped at 10
  mm/day). SUP-2/SUP-3 are predeclared sensitivities.
- `[measurement]` Zero-flow classification uses same-basin peer gauges as a
  **proxy** match grade; no independent CWC record was available (plan fallback).
- `[measurement]` The primary target uses the external soil-moisture product's
  climatology (leakage disclosed); the training-only SPI-3 sensitivity is the
  leakage-clean check.
- `[measurement]` The Brier endpoint is null; the AUC improvement is secondary
  and not a confirmatory claim.
- `[measurement]` `renv` is not installed; no lockfile is shipped (reproducibility
  gap disclosed in the protocol).
