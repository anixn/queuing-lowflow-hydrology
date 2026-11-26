# Common protocol — like-for-like India–US comparison

Status: **planned / in progress**, 26 November 2026. This is a new analysis arm,
not a relabel of the existing two case studies.

## Why

The India and US arms currently differ in unit type, supply rule, demand rule,
target and split. They are two applications, not a comparison. This protocol
fixes everything except the region, so that any difference is attributable to
hydroclimate and catchment sample, not to method.

## Common rules

| Element | Rule (identical in both regions) |
|---|---|
| Unit | gauge catchment |
| Command area | `A_cmd = f_irr * A_catchment`, `f_irr = 0.10` |
| Demand | `need = max(Kc * ET0_FAO_PM - 0.7 * P, 0)`, `lambda = need / 20`, **`Kc = 0.8` constant** |
| Supply | SUP-1: `mu = min(Q * 86400 * 0.5 / A_cmd * 1000, 10) / 20` |
| Capacity | `K = min(80, max(25, ceil(365 * lambda_bar)))` |
| Severe state | `q* = ceil(60 * lambda_bar)`, `theta = ceil(1.5 * q*)` |
| Target (primary) | **SPI-3 <= -1**, standardized on 1981–2010 only |
| Target (sensitivity) | **SPEI-3 <= -1**, same standardization |
| Split | train 1981–2010, test 2011–2020 |
| Screen | zero fraction < 0.30, interior gap <= 30 d, V1 rho in 0.15–1.20, >= 3 y train and >= 2 y test, >= 5 train and >= 3 test design events, <= 3 per basin |
| Evaluation | eight families, paired Brier/AUC, two-level bootstrap, sign test, harm bound |

## Data

- **India:** CAMELS-IND (472 gauges), the same 15 endpoint gauges if they pass
  the common screen.
- **USA:** Caravan-US (671 gauges), daily ERA5-Land forcing and streamflow.

## What differs

Only the region and its catchments. The queue, units, demand, supply, target,
split and evaluation are identical.

## Comparison statistic

For each region, the per-unit paired contrast
`Delta_g = Brier_g(SPI-3) - Brier_g(SPI-3 + queue)`.
Report the regional medians with two-level bootstrap CIs, the sign test, and a
formal **region × treatment** comparison (bootstrap of the difference in
medians, or a meta-regression with region as a moderator). The reservoir-centric
US arm remains a separate **measured-operations case study**, not part of this
comparison.

## Status

- [ ] US gauge screening (`R/compare/01_screen_us_gauges.R`)
- [ ] Common-rate builder for Caravan gauges
- [ ] SPI-3/SPEI-3 target for both regions
- [ ] Common queue and evaluation
- [ ] Region comparison and figure

This protocol is additive: the India primary result and the US reservoir case
study are unchanged.
