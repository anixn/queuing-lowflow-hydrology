# P02 methods analysis (v2 rebuild)

**Status (26 November 2026):** the v2 multi-catchment rebuild is complete through
S9. The predeclared confirmatory Brier endpoints are **null**; the secondary AUC
contrast is positive but not upgradable. The outcome is **Path B** (predeclared
evaluation + utilisation diagnosis). See `RESULTS_v2.md`.

## v2 artifacts (current)

| File | Purpose |
|---|---|
| `RESULTS_v2.md` | Assembled v2 results, corrected paired statistics, sensitivity grid, limitations |
| `../protocol/PROTOCOL_v2.md` | Locked predeclared protocol (tag `protocol-v2-locked`) |
| `../output/*.csv` + `.json` | Generated per-gauge metrics, paired deltas, meta endpoints, sensitivity grid |
| `../figures/*.pdf`, `*.png` | Publication figures |
| `../R/run_pipeline.R` | The single compute backbone (S2–S7) |
| `../R/analysis/sensitivity_grid.R` | Every predeclared sensitivity axis (S8) |
| `data_v1_superseded/` | Audited-defective v1 CSV outputs, provenance only |

## v1 artifacts (superseded, provenance only)

The v1 two-gauge comparison and its generated CSVs are retained only for
provenance. They are **not** v2 results and must not be cited as such:

- `REAL_DATA_COMPARISON_PROTOCOL.md`
- `REAL_DATA_COMPARISON_RESULTS.md`
- `data_v1_superseded/real_data_*.csv`
- `figures/real_data_comparison.{png,svg}`

The v1 Python code that produced them is on branch `legacy-python`
(tag `v1-audited`).

## Design and inventory

- `MODELLING_PLAN.md` — broader model stack, equations and validation ladder.
- `DATA_REQUIREMENTS.md` — what a stronger test would need.
- `data_inventory_2026-11-25.csv` — verified local/remote data inventory.

## Remaining work after sign-off

1. Measured irrigation demand to replace the Stage-A envelope.
2. Independent zero-flow/regulation records (CWC/India-WRIS).
3. A strictly leakage-free external benchmark reconstruction.
4. A stronger multi-gauge test that beats climatology on held-out data, or an
   honest null written up.
5. Conditional future `mu` from CAMELS-IND-Proj (gated; no raw CMIP6 number).

Generated files must never be hand-edited. Regenerate them with the R scripts in
`../R/`.
