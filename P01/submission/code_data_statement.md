# Code and data availability statement — draft

## Code availability

The queueing engine, reproducible demonstrations, sensitivity analyses and acceptance tests are organised in the project repository:

- `src/shared/queue_core.py` — finite-capacity non-stationary birth–death CTMC, exact stationary solution, RK4 propagator, Gillespie/thinning discrete-event simulation and conservation-ledger indicators.
- `src/P01/box1_sensitivity.py` — 44-case synthetic sensitivity grid.
- `src/P01/claim_scale_envelope.py` — 30-case claim-scale and physical-invariance checks.
- `src/P01/figure_data.py` and `src/P01/make_figures.py` — script-backed manuscript figures.
- `src/P01/validate_literature_counts.py` — read-only validator for the quoted WoS/Scopus and citation-trace totals.
- `tests/` — 25 acceptance tests covering solver agreement, blocked demand, conservation, claim-scale invariance, figure-data anchors, literature counts, benchmarks and estimators.

From the repository root:

```powershell
python tests/test_queue_core.py
python tests/test_nonstationary_bench.py
python tests/test_rate_estimators.py
python src/P01/box1_sensitivity.py
python src/P01/claim_scale_envelope.py
python src/P01/make_figures.py
python src/P01/validate_literature_counts.py
```

**Action required before submission:** replace this statement with the final public repository URL, archived release/DOI and software licence.

## Data availability

P01 uses no new observational dataset for its numerical claims. Box 1, the 44-case sensitivity grid and the claim-scale envelope are synthetic and explicitly labelled illustrative under the stated assumptions.

The literature evidence is preserved in:

- `P01/literature_audit.md` and `P01/search_protocol.md`;
- `analysis/P01_literature/` — WoS screening records, citation trace and raw exports;
- `analysis/novelty_2026-11-25/` — supplementary search log, evidence matrix, candidate audit and sensitivity output;
- `analysis/claim_convention_2026-11-25/` — official irrigation-area sources and claim-scale output.

The P01 manuscript does not use raw CMIP6 output. Future P02 work will use CAMELS-IND-Proj only after historical/provenance validation; raw CMIP6 remains pipeline-check-only under the project rules.

**Action required before submission:** confirm that the public archive includes the literature exports and official source PDFs, subject to their original terms.
