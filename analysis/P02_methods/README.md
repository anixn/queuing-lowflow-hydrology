# P02 methods analysis (v2)

**Status (26 November 2026):** the v2 multi-catchment rebuild is complete through
S9, with the external audit corrections applied. The primary external-target
Brier endpoint is **null**; the leakage-clean SPI-3 target is **positive** as a
secondary sensitivity; the ranking signal is secondary; the US reservoir pilot is
exploratory. See `RESULTS_v2.md` and `US_PILOT_RESULTS.md`.

## Current artifacts

| File | Purpose |
|---|---|
| `RESULTS_v2.md` | India results, corrected paired statistics, sensitivity grid, limitations |
| `US_PILOT_RESULTS.md` | USA reservoir-centric exploratory pilot |
| `../protocol/PROTOCOL_v2.md` | Locked protocol with timing disclosure |
| `../protocol/CHANGELOG.md` | Dated amendments, including the audit response |
| `../protocol/COMMON_PROTOCOL.md` | Like-for-like India–US comparison rules |
| `../output/*.csv` + `.json` | India per-gauge metrics, paired deltas, meta endpoints, sensitivity grid |
| `../output_us/*.csv` | USA sample, regime, paired results (in-window and full) |
| `../output_compare/*.csv` | Common-protocol India–US results |
| `../figures/*.pdf`, `*.png` | Publication figures |
| `../R/run_pipeline.R` | India compute backbone |
| `../R/us_pilot/` | USA reservoir-centric pipeline |
| `../R/compare/` | Common-protocol comparison |

## Superseded v1 material

The v1 Python code, the two-gauge comparison and the old generated CSVs are on
branch `legacy-python` (tag `v1-audited`). They are **not** in `main` and must
not be cited as v2 results.

## Remaining work after sign-off

1. Measured irrigation demand to replace the Stage-A envelope.
2. Independent zero-flow/regulation records (CWC/India-WRIS).
3. A strictly leakage-free external benchmark reconstruction.
4. OpenET/WaPOR validation of the US crop coefficient (quota resets 1 December 2026).
5. A stronger multi-gauge test, or an honest null written up.

Generated files must never be hand-edited. Regenerate them with the scripts in
`../R/` and the numbered sequence in `../steps/`.
