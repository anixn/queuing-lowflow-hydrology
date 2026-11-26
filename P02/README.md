# P02 working package — superseded by the v2 R rebuild

**This directory is retained for provenance only.** The v1 Python methods
package (rate estimators, benchmarks, two-gauge comparison) is archived on
branch `legacy-python` (tag `v1-audited`) and is **not** part of `main`.

The current methods work lives in the R rebuild:

| Current location | Purpose |
|---|---|
| `../R/00_utils/queue_engine.R` | Finite-capacity CTMC engine (exact, RK4, DES) |
| `../R/00_utils/units.R` | The unit wall (one claim volume per gauge) |
| `../R/00_utils/pipeline.R` | Stages S2–S7 |
| `../R/run_pipeline.R` | Single compute backbone |
| `../R/analysis/` | Power, sensitivity grid, figures |
| `../protocol/PROTOCOL_v2.md` | Locked protocol |
| `../analysis/P02_methods/RESULTS_v2.md` | Current results |

The v1 two-gauge pilot is the **boxed motivating case study** for the rebuild: it
returned a null that was not interpretable because of unit mixing, a
guaranteed-null utilisation regime, and almost no held-out drought events. It is
not a v2 result.

## Why P02 is superseded

- v1 used Python; the deliverable is R / R Markdown.
- v1 used a 45,000 ha district proxy; v2 uses one claim volume per gauge.
- v1 had two gauges; v2 has 24 gauges across 11 basins.
- v1 had no locked protocol or power analysis; v2 has both.

See `../START_HERE.md` and `../REDESIGN_PLAN_v2_R.md` for the governing plan.
