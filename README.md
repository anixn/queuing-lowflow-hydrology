# Queueing–Drought Junction

Two active papers read drought and low-flow behaviour as a queueing process:

- **P01 — perspective paper** for *Water Resources Research*: why the queue view belongs in drought science, what the prior art is, and which tests would make the programme credible.
- **P02 — methods paper** for *Hydrology and Earth System Sciences*: estimate non-stationary demand/service rates, validate the queue against exact references, and test incremental drought information on held-out data.

P01 comes first. P02 starts only after Gate B.

## Start here

1. `START_HERE.md` — plain-language orientation and current phase.
2. `AGENTS.md` — operating rules, frozen novelty sentence and verification protocol.
3. `docs/project/RESEARCH_PROTOCOL.md` — gates, objectives and analysis plan.
4. `P01/README.md` and `P02/README.md` — paper-package contents and run commands.

## Repository map

| Path | Purpose |
|---|---|
| `P01/` | Current P01 manuscript, literature audit, search protocol and technical notes |
| `P02/` | P02 methods package, R pipeline and generated data |
| `src/shared/` | Queueing engine shared by both papers |
| `src/P01/` | P01 demonstrations and data-to-rates skeleton |
| `src/P02/` | Exact benchmarks, rate estimators and evaluation code |
| `tests/` | Full Python acceptance suite |
| `analysis/P01_literature/` | Completed WoS screen, citation trace and raw exports |
| `analysis/novelty_2026-11-25/` | Dated novelty-strengthening investigation and sensitivity outputs |
| `analysis/claim_convention_2026-11-25/` | Official area evidence, WoS refresh and revisable claim convention |
| `analysis/P02_methods/` | P02 model protocol, data requirements, inventory and planned outputs |
| `docs/` | Project protocol, session log, novelty plan and data specifications |
| `references/` | Original roadmap source retained for historical provenance |
| `P02/data/generated/` | Reproducible R outputs; never hand-edit |

## Run the tests

Use the existing `drought` Conda environment:

```powershell
python tests/test_queue_core.py
python tests/test_nonstationary_bench.py
python tests/test_rate_estimators.py
python tests/test_real_data_comparison.py
```

All **42 tests** should pass. The exact interpreter path is recorded in `START_HERE.md` §8.

## Current status

- **Phase A complete:** 142 WoS and 295 Scopus records screened; citation traces complete; the 21 November 2026 gap sentence is frozen.
- **Phase B current:** P01 technical Gate B passes; author sign-off is pending.
- **Claim convention revised:** 45,000 ha district canal-irrigated proxy; 9×10⁶ m³ per 20 mm claim; 30-case scale envelope checked.
- **First real-data comparison complete:** queue+SSI did not improve held-out Brier score in either pilot gauge; the null is retained in `analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`.
- **Merged-paper strategy updated:** one HESS-style methods/negative-result paper, with a results-backed title and abstract in `docs/project/MERGED_PAPER_PLAN.md`.
- **Broader Phase C not started:** more gauges/events, measured demand, strict SPI/SPEI and future μ remain gated on author sign-off.

See `docs/project/SESSION_LOG.md` for the session-by-session record.
