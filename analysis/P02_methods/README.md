# P02 methods analysis

**Current status:** the first predeclared two-gauge retrospective comparison is complete. The confirmatory result is null: adding queue probability to SSI did not improve nominally held-out Brier score in either gauge. The supplied SMA target uses an external 1981–2020 climatology, so target construction is not strictly leakage-free. Broader methods work awaits author sign-off.

## Completed first-cycle artifacts

- `REAL_DATA_COMPARISON_PROTOCOL.md` — locked target, split, models, decision rule and sensitivities.
- `REAL_DATA_COMPARISON_RESULTS.md` — generated results, source audit, calibration, bootstrap, sensitivities and negative-result interpretation.
- `data/real_data_*.csv` — daily queue states, monthly predictors, predictions, metrics, reliability, events, bootstrap and missing-flow sensitivities.
- `data/real_data_run_metadata.json` — settings, numerical diagnostics and source SHA-256 hashes.
- `figures/real_data_comparison.png` / `.svg` — Brier-skill and reliability figure.

## Design and inventory

- `MODELLING_PLAN.md` — broader model stack, equations, validation ladder and work packages.
- `DATA_REQUIREMENTS.md` — what is required now, before validation and only for stronger claims.
- `data_inventory_2026-11-25.csv` — verified local/remote data inventory.

## Remaining work after sign-off

1. Expand to more gauges and held-out drought events.
2. Replace or envelope proxy demand with measured canal/crop evidence.
3. Resolve zero-flow and regulation semantics with CWC/India-WRIS records.
4. Rebuild strict training-only SPI/SPEI from raw gridded inputs.
5. Complete indicator-contract, recovery and identification work.
6. Complete the μ-error diagnostic, Floquet convergence study and MMPP sweep.
7. Validate CAMELS-IND-Proj historical skill/provenance before conditional future μ.
8. Propagate uncertainty and write the merged methods/negative-result paper.

Generated CSV files must never be hand-edited. Regenerate them with `src/P02/real_data_comparison.py`.

Details are in `../../docs/project/RESEARCH_PROTOCOL.md`, `../../docs/project/MERGED_PAPER_PLAN.md` and `../../docs/novelty/NOVELTY_AND_PLAN_REPORT.md`.
