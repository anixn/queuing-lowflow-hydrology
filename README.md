# Queueing–Drought Junction

This repository contains the working files for two papers that read drought
and low-flow behaviour as a queueing problem:

- **P01** — review/perspective paper for *Water Resources Research*.
- **P03** — methods paper for *Hydrology and Earth System Sciences*.

There is no P02/Paper 02 in this project. `analysis/P02_novelty_2026-11-25/`
is an investigation label, not a paper. The physical paper folders remain
`paper1/` and `paper3/` because the code and tests depend on those paths.

## Start here

1. Read `START_HERE.md` for the plain-language project overview.
2. Read `RESEARCH_PROTOCOL.md` for the current phase, gates and analysis plan.
3. Read `field/README.md` for the field-level objectives of P01 and P03.
4. Read `analysis/P01/wos_screening_2026-11-21.md` for the completed Web of Science
   record-level screening sheet.
5. Read `analysis/P02_novelty_2026-11-25/README.md` for the 25 November
   novelty-strengthening investigation.

## Folder map

| Folder | Purpose |
|---|---|
| `paper1/` | P01 manuscript, literature audit, data spec, Python core engine. |
| `paper3/` | P03 methods code, R real-data pipeline, generated pilot outputs. |
| `analysis/` | Completed Phase-A screens and the dated P02 novelty-strengthening investigation. |
| `field/` | Field-level objectives and initial state. |
| `RESEARCH_PROTOCOL.md` | Current protocol, phase and gates. |
| `APPROACH_P01_P03.md` | Ordered work plan for P01 and P03. |

## Run the tests

Use the existing `drought` Conda environment:

```powershell
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper3/src/test_nonstationary_bench.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper3/src/test_rate_estimators.py
```

All 22 tests should pass. See `RESEARCH_PROTOCOL.md` §9 for the exact command
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

- Phase A is closed (21 November 2026): the record-level screens (Scopus 295
  + WoS 93 records; zero retained) and the forward-citation trace (76 citing
  records; two new prior-art records) are complete, and the gap sentence is
  frozen (`AGENTS.md` §2). Gate A is passed; Phase B (finish P1) is current.
- P03 analysis is prepared only and starts after P01 reaches Gate B.

See `SESSION_LOG.md` for the session-by-session changes.
