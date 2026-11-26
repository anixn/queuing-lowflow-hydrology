# Common-protocol India–US comparison — results

Date: 26 November 2026. **Like-for-like comparison**, not two case studies.
Protocol: `protocol/COMMON_PROTOCOL.md`.

## Design

Identical in both regions:

- gauge catchments;
- `f_irr = 0.10`, `Kc = 0.8` constant, `phi = 0.7`;
- SUP-1: `mu = min(Q*86400*0.5/A_cmd*1000, 10)/20`;
- `K = min(80, max(25, ceil(365*lambda_bar)))`, `q* = ceil(60*lambda_bar)`;
- target: **training-only SPI-3 <= -1**;
- split 1981–2010 / 2011–2020;
- eight families, paired Brier/AUC, two-level bootstrap;
- >= 5 training and >= 3 test design events; <= 3 per basin (US: HUC4).

## Sample

| Region | Data | Gauges fitted | Paired after min events |
|---|---|---:|---:|
| India | CAMELS-IND endpoint gauges | 15 | 15 |
| USA | Caravan-US, V1 screen | 248 | 240 |

The US screen: 671 Caravan gauges → 290 in the V1 utilisation window → 270
strict-pass → 256 after the HUC4 cap → 248 fitted → 240 paired.

## Results

| Region | n | median ΔBrier | 95% CI | sign | p | median ΔAUC | harm |
|---|---:|---:|---|---:|---:|---:|---:|
| India | 15 | **−0.000321** | [−0.001268, +0.003946] | 6/15 | 0.849 | +0.0025 | 0 |
| USA | 240 | **+0.000423** | [−0.000081, +0.000851] | 131/240 | 0.088 | 0.0000 | 20 |
| USA − India | — | +0.000745 | [−0.003298, +0.001489] | — | — | — | — |

The region difference is an independent bootstrap of the difference in medians.

## Interpretation

`[measurement]` Under the **same** demand, supply, target and split, the queue
does **not** improve calibrated drought probability in either region: the India
median is slightly negative, the USA median is slightly positive, both intervals
include zero, and the region difference includes zero. The ranking gain is
effectively zero in both regions (India +0.0025, USA 0.0000).

This is the central result of the like-for-like comparison: **the earlier India
positive is target- and demand-model-dependent, not a general queue advantage.**
The India external-SMA result (+0.022 AUC) and the leakage-clean kharif-demand
result (+0.038 AUC) do not survive a common `Kc = 0.8` and a common SPI-3
target. The queue's case therefore rests on its descriptive quantities (unmet
volume, severe-state probability, recovery time) and on the verified engine, not
on a general calibrated-probability or ranking gain.

## Limitations

- The India sample is 15 gauges selected under the kharif/SUP-1 screen; the US
  sample is 240 Caravan gauges. The selection is common in rules, not in size.
- `Kc = 0.8` is a declared constant, not a measured crop coefficient.
- The target is SPI-3, a precipitation index; it is not the same as the India
  district SMA target or the US USDM target.
- No measured irrigation deliveries; Stage-B demand remains unavailable.

## Files

`R/compare/01_screen_us_gauges.R`, `R/compare/02_common_arm.R`;
`output_compare/us_gauges_screen.csv`, `common_meta.csv`,
`common_predictions.csv`, `common_paired_india.csv`, `common_paired_usa.csv`,
`common_region_difference.csv`; figure `figures/fig_common_comparison.png`.
