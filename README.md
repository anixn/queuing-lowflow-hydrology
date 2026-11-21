# Queueing–Drought Junction

This repository contains the working files for two papers that read drought
and low-flow behaviour as a queueing problem:

- **P01** — review/perspective paper for *Water Resources Research*.
- **P03** — methods paper for *Hydrology and Earth System Sciences*.

There is no P02/Paper 02 in this project. The physical folders are still
`paper1/` and `paper3/` because the code and tests depend on those paths.

## Start here

1. Read `START_HERE.md` for the plain-language project overview.
2. Read `RESEARCH_PROTOCOL.md` for the current phase, gates and analysis plan.
3. Read `field/README.md` for the field-level objectives of P01 and P03.
4. Read `analysis/P01/wos_screening_2026-11-21.md` for the live Web of Science
   record-level screening sheet.

## Folder map

| Folder | Purpose |
|---|---|
| `paper1/` | P01 manuscript, literature audit, data spec, Python core engine. |
| `paper3/` | P03 methods code, R real-data pipeline, generated pilot outputs. |
| `analysis/` | Working analysis files, including the WoS screening sheet. |
| `field/` | Field-level objectives and initial state. |
| `RESEARCH_PROTOCOL.md` | Current protocol, phase and gates. |
| `APPROACH_P01_P03.md` | Ordered work plan for P01 and P03. |

## Run the tests

Use the existing `drought` Conda environment:

```powershell
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_nonstationary_bench.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_rate_estimators.py
```

All 18 tests should pass. See `RESEARCH_PROTOCOL.md` §9 for the exact command
block and the R real-data pipeline commands.

## Notes for working from another computer

If you clone this repository on another machine:

1. Read `START_HERE.md` before changing any file.
2. Run the three Python test commands above before touching code.
3. If using R, run `paper3/R/01_build_rates.R` and `paper3/R/02_run_queue.R`
   in that order.
4. Do not edit files under `paper3/data/` by hand. They are generated outputs.
5. Keep the P01/P03 naming and the physical folder paths unchanged.

## Current work status

- Phase A is active: the record-level literature screens are complete
  (Scopus 295 + WoS 93 records; zero retained) and the gap sentence is frozen
  (21 November 2026). Remaining Phase A item: "Cited by"/"Times Cited"
  tracing inside WoS/Scopus.
- P03 analysis is prepared only and starts after P01 reaches Gate B.

See `SESSION_LOG.md` for the session-by-session changes.
