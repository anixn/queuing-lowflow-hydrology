# US reservoir-centric pilot — first results (provisional)

Date: 26 November 2026. **Pilot, not a confirmatory result.**
Data: Caravan-US (local), ResOpsUS (Zenodo 6612040), USDM county DSCI.
OpenET: key valid but the account's monthly request limit is exhausted until
1 December 2026; the 2016–2020 ET validation slice is **not yet included**.

## Design

- **Unit:** reservoir, not the CAMELS gauge. Only 2 ResOpsUS reservoirs fall
  inside a Caravan catchment polygon, so the gauge is the wrong unit.
- **Core sample:** 50 reservoirs with a ResOpsUS outflow record and an
  irrigated Caravan catchment within 20 km.
- **Demand:** `need = max(Kc * ET0_FAO_PM - 0.7 * P, 0)`, `lambda = need / 20`,
  with `Kc = 0.8` (declared constant, a sensitivity axis).
- **Supply:** `mu = min(outflow*86400/A_cmd*1000, 10) / 20`.
- **Capacity:** `K` from reservoir storage in claims, capped 25–80.
- **Target:** USDM monthly mean DSCI >= 100 (D1 or worse).
- **Split:** train 2000–2012, test 2013–2020.
- **Baseline:** SSI-3 on monthly firm supply `mean_mu`.
- **Queue:** `mean_E[Q]`, `mean_P(Q >= q*)`.

## Sample and regime

| Quantity | Value |
|---|---:|
| Core reservoirs | 50 |
| Reservoirs run | 49 |
| Design matrices (>= 120 months) | 45 |
| **Paired E1/E2 reservoirs** | **21** |
| Complete reservoir-months with USDM | 10,681 |
| Target event rate (DSCI >= 100) | 34.7% |
| `rho` range | 0.103–25.44 |
| Reservoirs inside `rho` window 0.15–1.20 | 27 |
| `q*` range | 3–8 |
| `K` range | 25–80 |
| max `P(Q = K)` | 1.7×10⁻⁶ |
| max ledger residual | 3.5×10⁻¹⁵ |

## Paired comparison (SSI-3 vs SSI-3 + queue)

| Endpoint | n | median ΔBrier | 95% CI | sign | p | median ΔAUC | harm (< −0.005) |
|---|---:|---:|---|---:|---:|---:|---:|
| E1 concurrent | 21 | **+0.000793** | [−0.004651, +0.007736] | 12/21 | 0.332 | +0.0105 | 7/21 |
| E2 prospective | 21 | −0.000187 | [−0.004643, +0.011411] | 10/21 | 0.668 | +0.0296 | — |

Mean E1 held-out metrics: SSI-3 Brier 0.2094 / AUC 0.631; SSI-3+queue Brier
0.2074 / AUC 0.646; queue alone Brier 0.2479 / AUC 0.583; climatology Brier
0.2550 / AUC 0.530.

## Interpretation

`[measurement]` The US reservoir-centric pilot **reproduces the India result**:
adding queue probability to SSI-3 does not improve calibrated Brier score
(median +0.0008, interval includes zero, sign test non-significant), while AUC
edges up slightly. With measured reservoir operations and an observed drought
target (USDM), the null persists.

This is a **pilot**, not a confirmatory test: only 21 reservoirs have paired
test-window predictions, `Kc = 0.8` is a declared constant, the command area is
the nearest irrigated Caravan catchment (a proxy), and OpenET is not yet used.

## Limitations

- ResOpsUS record coverage: many reservoirs end before 2013 or lose too many
  complete months, leaving 21 paired reservoirs.
- `Kc = 0.8` is a single declared value; a Kc/target-threshold sensitivity is
  required before any claim.
- The command area is a nearest-catchment proxy, not a measured service area.
- OpenET 2016–2020 validation is pending the 1 December quota reset.
- USDM county DSCI is a coarse target; a HUC8 or shapefile join would be finer.

## Next steps

1. Kc sensitivity (0.6 / 0.8 / 1.0) and target threshold (D0+, D1+, D2+).
2. Broaden or re-split the test window to increase the paired sample.
3. OpenET 2016–2020 validation after 1 December; WaPOR as a keyless alternative.
4. If the null survives, record it as a second, independent multi-catchment
   confirmation of the Path-B outcome.

Source scripts: `R/us_pilot/01_screen_caravan.R` … `08_run_us_eval.R`.
Outputs: `output_us/reservoir_core.csv`, `reservoir_queue_meta.csv`,
`reservoir_monthly.csv`, `us_metrics.csv`, `us_paired_e1.csv`, `us_meta.csv`.
