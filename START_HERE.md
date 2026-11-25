# START HERE — what I did, what we are doing, and which file to open

Prepared 21 November 2026. Plain language; no statistics training needed.
Read this file first, then follow the reading order in section 6.

---

## 1. The project in one paragraph

We are testing one idea: a drought can be read as a **queue**, the same way
customers queue at a service desk. Water demand arriving from farms is the
arrival stream; water available from the river is the service; water that was
asked for but not supplied is the **backlog** (unmet demand). When wet weather
returns, the backlog drains — that is recovery. Standard drought indices such
as SPI measure unusual weather; they do not directly measure how much water was
missed, for how long, or how long recovery will take. Our queue description
adds those quantities. We are **not** claiming that linking queues to water is
new — hydrology published that link in 1958. Our claim is much narrower and is
written down in section 5.

## 2. The two papers

| Paper | Job | Target | Status |
|---|---|---|---|
| **P01** — *Dams, queues and droughts* | Review/perspective: why the queue view is worth trying, what prior art exists, what the research programme is | Water Resources Research | Draft v2 revised; Phase B figures and WRR package remain |
| **P02** — ML-assisted non-stationary queue methods | Methods: estimate changing rates from data, check them against exact maths, test on held-out years/basins | Hydrology and Earth System Sciences | Code and single-gauge pilot exist; starts after P01 is stable |

P01 first, P02 second. That order is fixed.

## 3. What I have actually finished

**The engine.** `src/shared/queue_core.py` solves the finite-capacity queue.
I checked it three independent ways and they agree: the exact formula and the
numerical solver both give E[Q] = 0.9161 claims, and a discrete-event simulation
gives 0.9129 (0.34% difference). In the seasonal example, the true peak backlog
is 2.13 claims but treating the year as one average gives 0.92 — a 2.3×
understatement. Peak severe-backlog probability is 0.073 versus 0.004. That gap
is the reason the project exists.

**The tests.** 12 P01 tests, 6 benchmark tests and 7 rate-estimator tests all pass
(25 in total). Every new feature should get a test.

**The literature hunt.** Crossref, OpenAlex, Web of Science and Scopus were all
searched with the same five strings plus direct tests. Scopus alone contributed
295 screened records and no study that changes the gap. Seven "seed" papers
were citation-traced. The prior-art table now honestly includes Langbein 1958,
soil-water, groundwater, runoff, irrigation, water-supply reliability and
high-flow queueing. Machine learning for queues and non-stationary queueing are
mature fields — we say so explicitly rather than claiming them.

**The real-data pilot.** `P02/R/01_build_rates.R` turns CAMELS-IND rainfall,
temperature and streamflow for gauge 4026 (Kurundwad on the Krishna) into a
daily rate file at `P02/data/generated/rates_4026.csv`. `02_run_queue.R` can run
the queue, but its legacy indicator summary was removed during housekeeping
because the unit and server-accounting contract still needs correction. No
pilot indicator number is currently trusted as a finding.

**The future-data step.** CAMELS-IND-Proj is present with daily projected
streamflow for 13 CMIP6 models and four SSPs, 2015–2100; gauge 4026 is complete
in all 65 files. It is the primary conditional future μ input after historical
and LSTM-provenance validation; its documented bias-corrected forcing must not be
corrected twice. `P02/R/03_extract_cmip6.R` and the raw SSP files remain a gated
fallback. No future queue result may be published before those validation gates.

**The documents.** This file plus the plan report, the audit trail, the search
log, the data inventory and the two READMEs. Together they record what was
searched, what was found and what remains.

## 4. The revisable working claim convention

You asked me to choose. I chose the **bulk delivery** scale, because it matches
a real irrigation application depth and needs no canal records we do not have.

| Item | Selected value | What it means in plain language |
|---|---|---|
| Command area | **45,000 ha** | District canal-irrigated area in Sangli, used as a proxy; not a gauge-specific measurement |
| One claim | **9×10⁶ m³** | 20 mm over 45,000 ha — a modelling delivery unit, not a measured canal release |
| Capacity K | **20 claims** | 1.8×10⁸ m³, i.e. 400 mm over the proxy command — about one season's cumulative supply |
| Service cap | **3 claims/day** | 60 mm/day, i.e. 2.7×10⁷ m³/day — the intake ceiling |
| Firm share | **0.5** | Half of river flow is treated as dependable dry-season supply |

Why this scale: 45,000 ha is the canal-irrigated area reported for Sangli in
the official agriculture contingency plan, so it is a documented district-level
proxy rather than a round guess. It is still not the command area of gauge 4026.
Keeping a 20 mm delivery unit makes one claim readable and preserves the 400 mm
backlog tolerance and 60 mm/day service cap when the proxy area changes.

**Important honesty note:** this is a *provisional assumption*, not a
measurement, and it is unlocked as of 25 November 2026. It is written in one
place in each code package so it can be changed coherently. If real
canal-command or crop-area records appear, we replace it and re-run. If they do
not, we run a sensitivity envelope and label every result illustrative. The
source record and envelope are in `analysis/claim_convention_2026-11-25/`.
This convention rescales λ, μ and K together; it does not change the literature
verdict or the frozen novelty sentence.

## 5. The narrow claim we are testing

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens (295
> records), plus the citation traces, we found no study that puts all four of
> these together: (1) drought as an accumulated unmet-demand backlog with a
> finite-capacity state; (2) queue-state indicators reported as drought
> quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

We always write "we found no study in these sources", never "no such study
exists". That wording must not change without redoing the search.

**This sentence is frozen as of 21 November 2026**: both database screens are
complete (437 records in total), every record has a keep/drop reason, and the
frozen dated copy lives in `AGENTS.md` §2.

## 6. Which document to read, in what order

| Order | File | What it gives you |
|---|---|---|
| 1 | **`START_HERE.md`** (this file) | The whole situation in plain language |
| 2 | `docs/novelty/NOVELTY_AND_PLAN_REPORT.md` | The full idea, the novelty verdict and every planned step, in order. Sections 3–6 are the literature hunt; section 4 is the work plan |
| 3 | `P01/P01_draft_v2.md` | The actual P01 manuscript — sections 2, 5, 6 and 7 matter most |
| 4 | `P01/literature_audit.md` | The evidence trail: which queries were run, which papers were found, which claims were rejected |
| 5 | `P01/search_protocol.md` | The exact search strings and the run log with dates and hit counts |
| 6 | `P01/data_access_spec.md` | What data is actually on disk, and the revisable convention in §1 |
| 7 | `P01/README.md`, `P02/README.md` | File lists, run commands and the verified numbers for each package |
| 8 | `P01/queueing_howto.md` | The technical mapping and the guardrails, if you want the equations |

## 7. What we are doing right now

We are in **Phase B: finish P01**. Phase A is complete: all 142 WoS and 295
Scopus records were screened, the database citation traces are complete, and
the gap sentence in section 5 is frozen. The 25 November 2026 supplementary
search added Acosta et al. (2026) and Zhao et al. (2018) as prior art without
changing that sentence.

The reproducible P01 figures and WRR package drafts are complete. The technical
Gate B checklist passes (`P01/GATE_B_CHECKLIST.md`); author sign-off is pending
on submission metadata, archive links, the recovery definition, the μ convention
and the disclosed literature limitations. The single next action is author
review of that checklist.

**Phase C: build P02** comes only after Gate B sign-off — fix the μ-error near ρ≈1,
finish the Floquet and MMPP studies, extend the R pilot to more gauges,
bias-correct CMIP6, set up held-out validation, and only then write the HESS
paper.

## 8. How to see it run

From the project root, in PowerShell. Use the existing `drought` Conda
environment: the default `python` on this machine has no NumPy, so the three
test commands fail with `ModuleNotFoundError`.

```powershell
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_queue_core.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_nonstationary_bench.py
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' tests/test_rate_estimators.py

& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' P02/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' P02/R/02_run_queue.R
```

The first three commands check the maths. The R commands rebuild the real-data
pilot and should be run in that order.
