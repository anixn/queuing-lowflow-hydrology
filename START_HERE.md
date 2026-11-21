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
| **P1** — *Dams, queues and droughts* | Review/perspective: why the queue view is worth trying, what prior art exists, what the research programme is | Water Resources Research | Draft v2 exists; finishing the literature screen, then final wording |
| **P3** — ML-assisted non-stationary queue methods | Methods: estimate changing rates from data, check them against exact maths, test on held-out years/basins | Hydrology and Earth System Sciences | Code and single-gauge pilot exist; starts after P1 is stable |

P1 first, P3 second. That order is fixed.

## 3. What I have actually finished

**The engine.** `paper1/src/queue_core.py` solves the finite-capacity queue.
I checked it three independent ways and they agree: the exact formula and the
numerical solver both give E[Q] = 0.9161 claims, and a discrete-event simulation
gives 0.9129 (0.34% difference). In the seasonal example, the true peak backlog
is 2.13 claims but treating the year as one average gives 0.92 — a 2.3×
understatement. Peak severe-backlog probability is 0.073 versus 0.004. That gap
is the reason the project exists.

**The tests.** 5 P1 tests, 6 benchmark tests and 7 rate-estimator tests all pass
(18 in total). Every new feature should get a test.

**The literature hunt.** Crossref, OpenAlex, Web of Science and Scopus were all
searched with the same five strings plus direct tests. Scopus alone contributed
295 screened records and no study that changes the gap. Seven "seed" papers
were citation-traced. The prior-art table now honestly includes Langbein 1958,
soil-water, groundwater, runoff, irrigation, water-supply reliability and
high-flow queueing. Machine learning for queues and non-stationary queueing are
mature fields — we say so explicitly rather than claiming them.

**The real-data pilot.** `paper3/R/01_build_rates.R` and `02_run_queue.R` turn
CAMELS-India rainfall, temperature and streamflow for gauge 4026 (Kurundwad on
the Krishna) into daily arrival and service rates, then run the queue. Over
2001–2020 after one spin-up year: mean E[Q] = 1.43 claims, peak 3.60,
Pr(Q≥6) mean 0.023 and peak 0.156, unmet demand 199 claim-days. These demonstrate
that the data → rates → queue chain works. They are **not findings**, because
the area, claim volume and cap are assumptions.

**The future-data step.** `paper3/R/03_extract_cmip6.R` extracts one CMIP6 SSP
at the gauge and computes Hargreaves ET0: 9,497 daily rows, 2015–2040. This is
a pipeline check only. Bias correction is not done, so no future result may be
published yet.

**The documents.** This file plus the plan report, the audit trail, the search
log, the data inventory and the two READMEs. Together they record what was
searched, what was found and what remains.

## 4. The claim convention I selected for you

You asked me to choose. I chose the **bulk delivery** scale, because it matches
a real irrigation application depth and needs no canal records we do not have.

| Item | Selected value | What it means in plain language |
|---|---|---|
| Command area | **50,000 ha** | The nominal area served by the system in the pilot |
| One claim | **10⁷ m³** | One delivery of 10 million m³ — that is 20 mm of water spread over 50,000 ha, a normal single irrigation application |
| Capacity K | **20 claims** | 2×10⁸ m³, i.e. 400 mm over the command — about one season's cumulative supply |
| Service cap | **3 claims/day** | 60 mm/day, i.e. 3×10⁷ m³/day — the intake ceiling |
| Firm share | **0.5** | Half of river flow is treated as dependable dry-season supply |

Why this scale: one claim is a readable physical object (one field irrigation
across the command), and K=20 is a readable ceiling (one season of supply).
Smaller conventions — one hectare-day (100 m³) or one outlet turn (1,000–10,000
m³) — would be more operational but would require canal records we have not
found.

**Important honesty note:** this is a locked *provisional assumption*, not a
measurement. It is written in one place in each code package so it can be
changed. If real canal-command or crop-area records appear, we replace it and
re-run. If they do not, we run a sensitivity envelope and label every result
illustrative. This convention rescales λ, μ and K together; it does not change
the literature verdict or the novelty claim.

## 5. The narrow claim we are testing

Within Crossref, OpenAlex, the complete Web of Science S1–S5/Extra A/B/C
screens (142 records) and the completed Scopus S1–S5/Extra A/C screens
(295 records), plus the citation traces, we found no
study that puts all four of these together:

1. drought as an accumulated unmet-demand backlog with a finite-capacity state;
2. queue-state indicators (backlog, severe-state probability, unmet demand,
   recovery time) reported as drought quantities;
3. non-stationary rates estimated from hydroclimatic covariates;
4. validation against exact reference solutions and pre-specified drought tests.

We always write "we found no study in these sources", never "no such study
exists". That wording must not change without redoing the search.

**This sentence is frozen as of 21 November 2026**: both database screens are
complete (437 records in total), every record has a keep/drop reason, and the
frozen dated copy lives in `AGENTS.md` §2.

## 6. Which document to read, in what order

| Order | File | What it gives you |
|---|---|---|
| 1 | **`START_HERE.md`** (this file) | The whole situation in plain language |
| 2 | `NOVELTY_AND_PLAN_REPORT.md` | The full idea, the novelty verdict and every planned step, in order. Sections 3–6 are the literature hunt; section 4 is the work plan |
| 3 | `paper1/P1_draft_v2.md` | The actual P1 manuscript — sections 2, 5, 6 and 7 matter most |
| 4 | `paper1/literature_audit.md` | The evidence trail: which queries were run, which papers were found, which claims were rejected |
| 5 | `paper1/scopus_wos_search_plan.md` | The exact search strings and the run log with dates and hit counts |
| 6 | `paper1/data_access_spec.md` | What data is actually on disk, and the locked convention in §1 |
| 7 | `paper1/README.md`, `paper3/README.md` | File lists, run commands and the verified numbers for each package |
| 8 | `paper1/queueing_howto.md` | The technical mapping and the guardrails, if you want the equations |

Old drafts `P1_draft_v0.md` and `P1_draft_v1.md` are kept only for provenance.
Do not use them.

## 7. What we are doing right now

We are in **Phase A: finish the novelty hunt**. Scopus is finished. The last
database job is to screen four Web of Science searches whose record cards would
not render: S4 (6 hits), S5 (66), Extra A (8) and Extra C (13). After that we
full-text screen the retained prior art and freeze the gap sentence in section 5.

Then **Phase B: finish P1** — tighten the mapping section, add the guardrails
box, build the figures, check every novelty word, and prepare the WRR package.

Then **Phase C: build P3** — fix the μ-error near ρ≈1, finish the Floquet and
MMPP studies, extend the R pilot to more gauges, bias-correct CMIP6, set up
held-out validation, and only then write the HESS paper.

## 8. How to see it run

From the project root, in PowerShell. Use the existing `drought` Conda
environment: the default `python` on this machine has no NumPy, so the three
test commands fail with `ModuleNotFoundError`.

```powershell
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_nonstationary_bench.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_rate_estimators.py

& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R
```

The first three commands check the maths. The R commands rebuild the real-data
pilot and should be run in that order.
