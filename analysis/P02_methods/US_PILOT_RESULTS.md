# US reservoir-centric pilot — results (exploratory)

Date: 26 November 2026. **Exploratory replication, not a predeclared
confirmatory test.** Data: Caravan-US, ResOpsUS, USDM. OpenET is not included
(quota exhausted until 1 December 2026); demand uses Caravan ET0 with a declared
`Kc = 0.8`.

## Design

- **Unit:** reservoir. Only 2 ResOpsUS reservoirs fall inside a Caravan
  catchment polygon, so the gauge is the wrong unit.
- **Core sample:** 50 reservoirs with a ResOpsUS outflow record and an
  irrigated Caravan catchment within 20 km.
- **Primary sample:** the predeclared utilisation window `0.15 <= rho <= 1.20`,
  matching the India rule. **14 paired reservoirs** have paired test-window
  predictions. The full sample (**21 paired**) is reported as a sensitivity.
- **Demand:** `need = max(Kc * ET0_FAO_PM - 0.7 * P, 0)`, `lambda = need / 20`,
  `Kc = 0.8` (declared).
- **Supply:** `mu = min(outflow*86400/A_cmd*1000, 10) / 20`, i.e. measured
  outflow with `s_firm = 1` (a design difference from the India SUP-1 rule).
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
| Paired, full sample | 21 |
| **Paired, in-window (primary)** | **14** |
| Complete reservoir-months with USDM | 10,681 |
| Target event rate (DSCI >= 100) | 34.7% |
| `rho` range | 0.103–25.44 |
| Reservoirs inside `rho` window | 27 of 49 |
| `q*` range | 3–8 |
| `K` range | 25–80 |
| max `P(Q = K)` | 1.7×10⁻⁶ |
| max ledger residual | 3.5×10⁻¹⁵ |

## Paired comparison (SSI-3 vs SSI-3 + queue)

**Primary: in-window sample (14 reservoirs).**

| Endpoint | n | median ΔBrier | 95% CI | sign | p | median ΔAUC | harm |
|---|---:|---:|---|---:|---:|---:|---:|
| E1 concurrent | 14 | **+0.000388** | [−0.010481, +0.009345] | 7/14 | 0.605 | +0.0077 | 6/14 |
| E2 prospective | 14 | −0.002387 | [−0.008578, +0.012724] | 6/14 | 0.788 | +0.0103 | 4/14 |

**Sensitivity: full sample (21 reservoirs).**

| Endpoint | n | median ΔBrier | 95% CI | sign | p | median ΔAUC | harm |
|---|---:|---:|---|---:|---:|---:|---:|
| E1 concurrent | 21 | +0.000793 | [−0.004651, +0.007736] | 12/21 | 0.332 | +0.0105 | 7/21 |
| E2 prospective | 21 | −0.000187 | [−0.004643, +0.011411] | 10/21 | 0.668 | +0.0296 | 5/21 |

Mean held-out E1 metrics (full sample): SSI-3 Brier 0.2094 / AUC 0.631;
SSI-3 + queue Brier 0.2074 / AUC 0.646; queue alone Brier 0.2479 / AUC 0.583;
climatology Brier 0.2550 / AUC 0.530.

## Interpretation

`[measurement]` With the utilisation window applied, the US arm is **null on
both Brier and AUC**: E1 median +0.0004 (CI includes zero, 7/14) and ΔAUC
+0.008. The full sample is also null on Brier, with a small AUC gain (+0.010).
The India AUC signal does **not** replicate in the US reservoir sample.

This is an **exploratory replication**, not a second confirmatory test. It
supports the paper's honest-null framing and shows that the India ranking signal
is not automatic: it depends on the data system and the demand/supply
representation. It does **not** support a general claim that the queue improves
event ranking everywhere.

## Limitations

- 14 paired reservoirs in the primary sample; 21 in the full sample.
- ResOpsUS records end before 2013 for many reservoirs, causing the attrition.
- The command area is the nearest irrigated Caravan catchment, a proxy.
- `Kc = 0.8` is a declared constant; OpenET validation is pending.
- The USDM county DSCI is a coarse target.
- 6/14 harm-bound breaches on E1 (in-window), disclosed.

## Files

`R/us_pilot/01…08`; `output_us/reservoir_core.csv`,
`output_us/reservoir_queue_meta.csv`, `output_us/us_meta.csv` (in-window),
`output_us/us_meta_full.csv` (full), `output_us/us_paired_in_window_e1.csv`,
`output_us/us_paired_full_e1.csv`; `output/rho_slope.csv`.
