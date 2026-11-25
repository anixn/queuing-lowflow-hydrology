# Novelty and plan report — "Dams, queues and droughts" (P01) and the methods paper (P02)

Prepared 20–21 November 2026. Plain-language version: no statistics training needed.
**New here?** Read `START_HERE.md` first — it is a short orientation to what has
been done, what is being done now, and which file to open next.

---

## 0. Read this first

This report does two jobs.

1. **It explains the idea** behind the two papers as simply as I can.
2. **It records what the literature hunt actually found**, and lists every step I plan to take next.

The honesty rule for this whole project: queueing theory and water storage have been connected since 1958. We are **not** claiming to invent that connection. Our claim is much smaller and much more specific. We will say **"we found no study, in the sources and strings listed below, that does X"** — never "no such study exists".

**Status of the novelty hunt:** complete as of 21 November 2026. All Scopus
searches are complete (295 records screened, no gap-changing study) and the
four Web of Science sets whose results page failed to render titles were
screened on 21 November 2026 by exporting every record set to Excel with
abstracts (93 records, zero retained; `analysis/P01_literature/wos_screening_2026-11-21.md`).
The forward-citation trace of all seeds inside WoS "Times Cited" / Scopus
"Cited by" is also complete — 76 citing records screened, two new
non-gap-changing prior-art records found
(`analysis/P01_literature/citation_trace_2026-11-21.md`). The dated gap sentence is
frozen (`AGENTS.md` §2). Phase A is closed; Gate A is passed.

---

## 1. The idea in one minute

Think of a reservoir serving farms.

- Water arriving in the river is like **customers arriving at a service desk**.
- Each irrigation request is like a **customer wanting to be served**.
- If requests arrive faster than water can serve them, a **queue builds up**. In our language that queue is **unmet demand** — the backlog of water that farmers wanted but did not get.
- The queue may eventually drain when wet weather returns. That is **recovery**.
- The queue can hit a ceiling — the reservoir empties and no more can be promised. That is **capacity**.

So a drought is not just "rainfall was low". It is a **state of a system**: a growing backlog of unmet demand, under a supply process that is itself driven by weather.

### Why bother?

Standard drought indices (SPI, SPEI, SSI) measure **how unusual the weather is**. They do not measure **how much water was actually missed, for how long, or how long recovery will take**. Two droughts with the same rainfall deficit can cause very different harm depending on when the demand arrives and how the supply is rationed.

A queue description gives us quantities that mean something physical:

- **E[Q]** — expected backlog (how much demand is typically outstanding);
- **Pr(Q ≥ 6)** — probability of being in a severe backlog state;
- **abandoned demand** — cumulative blocked and reneged claims;
- **backlog exposure** — the time integral of backlog, in claim-days;
- **recovery time** — how long the backlog takes to clear.

### The catch that makes it scientific

Real supply and demand rates **change with season and climate**. If you replace a seasonal signal by its yearly average, you badly understate peak risk. In our verified synthetic example, the true peak expected backlog is **2.13 claims** but the stationary-at-the-average calculation says **0.92 claims** — a 2.3× understatement. Peak severe-backlog probability is **0.073** versus **0.004**. That gap is the reason this project exists.

We already checked this three ways: an exact mathematical solution, a numerical ODE solver, and a discrete-event simulation. They agree.

---

## 2. The two papers

### P01 (P01) — the "why and what" paper

**Working title:** *Dams, queues and droughts: reclaiming storage theory for deficit-accumulation drought science*

**Target:** Water Resources Research.

**Its job:** make the case. It is a review/perspective, not a data paper. It says:

1. Storage theory originally **was** queueing theory — hydrology said so in 1958 (Langbein).
2. Over time drought science kept the bookkeeping of shortage but lost the mechanism. Indices replaced state variables.
3. The queue mapping restores backlog, waiting time, recovery time and abandonment as drought quantities.
4. There is a real prior-art niche — soil water, groundwater, runoff, irrigation capacity, canal management, water-supply reliability, high flows — and we cite all of it honestly.
5. Non-stationarity is not a detail: averaging produces wrong risk.
6. There is a research programme, with guardrails and a rule that null results must be published if that is what the tests show.

**What P01 does not claim:** that queueing in hydrology is new; that we invented the storage–queue analogy; that we have a new drought index better than SPI.

### P02 (P02) — the "how and does it work" paper

**Target:** Hydrology and Earth System Sciences, later (roughly 2028 Q4 in the current roadmap). Starts once P01 is stable.

**Its job:** supply the methods and test them. It asks:

1. Can we **estimate** the changing rates from data? Arrival rate `λ(t) = fθ(x)` from demand/weather covariates; service rate `μ(t) = gφ(z)` from upstream flow and climate.
2. Can we **prove** the estimator is right? We compare it against exact reference solutions: a stationary-at-mean queue, a periodic (Floquet) solution, a Markov-modulated arrival process, and discrete-event simulation.
3. Does it **beat simple baselines**? Constant rate, climatological seasonal rate, and the existing drought indices.
4. Does it add **pre-specified drought information** beyond those baselines, on held-out years and held-out basins?

**What P02 does not claim:** "ML plus queues" (a mature field); time-varying or correlated arrivals as a novelty (also mature — see Bogachev et al. below); or that correlation beats old indices without a pre-specified test.

---

## 3. The literature survey and novelty hunt

### 3.1 Exactly what was searched

| Source | When | What was done | Search scope wording to use |
|---|---|---|---|
| Crossref REST | 20 Nov 2026 | DOI/title verification, prior-art checks | Bibliographic lookup, not a database review |
| OpenAlex API | 20–21 Nov 2026 | Title, abstract and fulltext searches; 8 broad queries plus ~20 narrow ones; citation tracing of 7 seed papers | Scoping search, free-tier API |
| Web of Science Core Collection | 20–21 Nov 2026 | Institutional login; Topic-field Boolean searches S1, S2, S3, S4, S5 plus three extra direct tests | Scoping search, all editions/years/document types |
| Scopus | 21 Nov 2026 | Institutional IP access (no login); basic search box with bare Boolean, page size 200; S1–S5 + Extra A/C | Scoping search, `TITLE-ABS-KEY` applied by Scopus; no filters |

**Important interface note (updated 21 November 2026):** on 20 November the
WoS Topic field rejected `TS=(...)` with "Invalid query" and the bare Boolean
expression had to be pasted. On 21 November the interface changed: the
Advanced Search **Query Builder** textarea accepts and requires the `TS=(...)`
prefix, and the bare Boolean string returns "Invalid field tag". The S4/S5/
Extra A/C runs on 21 November used `TS=(<bare Boolean>)`.

**What was NOT done, and must be said out loud:** this was a scoping audit, not
a systematic review. WoS records were screened from exported titles, abstracts
and keywords; Scopus records were screened at title level. Not every hit
received full-text screening, and no language restrictions were applied, so
non-English records may be missed by indexing. Database citation tracing was
completed inside WoS/Scopus where the seeds are indexed; OpenAlex remains the
trace for unindexed seeds. All WoS result sets were screened by export on
21 November 2026 (`analysis/P01_literature/wos_screening_2026-11-21.md`).

### 3.2 Search results, with numbers

| # | Search (WoS Topic, bare Boolean) | Hits | Screened | Finding |
|---|---|---:|---:|---|
| S1 | queue terms AND drought/low flow/water storage/unmet demand/water deficit | 25 | 25 | No hydrology-drought queue study. Mostly telecom, transport, healthcare. |
| S2 | queueing theory AND hydrology/water/river/reservoir/irrigation/groundwater | 24 | 24 | 4 new prior-art records + 2 P02-relevant records. |
| S3 | drought AND recovery time/first passage/busy period AND queue/congestion/backlog | **0** | — | Complete null. |
| S4 | non-stationary/time-varying AND queue AND hydrology/drought/water/irrigation | 6 | 6 | All telecom/OR; Bogachev 2024 already recorded for P02. Screened 21 Nov 2026 by export. |
| S5 | unmet demand/deficit accumulation/demand backlog AND drought/irrigation/water supply | 66 | 66 | WEAP-type deficit modelling throughout; no queueing. Screened 21 Nov 2026 by export. |
| Extra A | drought AND queue/queu | 8 | 8 | Decisive direct test — **screened 21 Nov 2026: zero retained**; two institutional "queuing system" echoes (water rights). |
| Extra B | drought AND first passage/busy period AND reservoir/storage/deficit | **0** | — | Complete null. |
| Extra C | water deficit/unmet demand AND queue/queu | 13 | 13 | Decisive direct test — **screened 21 Nov 2026: zero retained**; production-inventory/healthcare/transport queueing only. |

The same strings were then run in Scopus (21 November 2026). Scopus accepted
the bare Boolean in its basic search box and applied `TITLE-ABS-KEY` itself;
all records were displayed at page size 200 and screened at title level.

| # | Scopus search | Hits | Screened | Finding |
|---|---|---:|---:|---|
| S1 | queue terms AND drought/low flow/water storage/unmet demand/water deficit | 38 | 38 | No relevant prior art. |
| S2 | queueing theory AND hydrology/water/river/reservoir/irrigation/groundwater | 116 | 116 | Known hydrology-queue lines only; no gap-changing record. |
| S3 | drought AND recovery time/first passage/busy period AND queue/congestion/backlog | **0** | — | Complete null (run without the plan's "return period" clause). |
| S4 | non-stationary/time-varying AND queue AND hydrology/drought/water/irrigation | 11 | 11 | No gap-changing record. |
| S5 | unmet demand/deficit accumulation/demand backlog AND drought/irrigation/water supply | 98 | 98 | No gap-changing record. |
| Extra A | drought AND queue/queu | 15 | 15 | Decisive direct test — **screened, no gap-changing record**. |
| Extra C | water deficit/unmet demand AND queue/queu | 17 | 17 | Decisive direct test — **screened, no gap-changing record**. |

**295 Scopus records screened, zero gap-changing findings.** Known prior art
surfaced again (Yang 2019, Palková et al., Harel & Mouche, Prajamwong et al.
1997); nothing combined drought-as-queue-backlog with covariate-learned rates
and pre-specified validation.

OpenAlex cross-checks: `title.search` for queueing + drought returned **0** in every spelling tried (queueing, queuing, queue). `title.search:drought, abstract.search:queue` returned 4, all irrelevant (plant drought memory, bird ecology, water collection, emergency response). `abstract.search:drought, abstract.search:queueing` returned 41, dominated by false matches where "queue" means a waiting line of people, not a stochastic queue.

**Reading of the numbers (updated 21 November 2026):** the decisive direct
tests are complete in **both** databases — Scopus (15 and 17 records) and WoS
(8 and 13 records, screened by export the same day). Across 437 screened
records, zero gap-changing findings. The WoS sets echo the Scopus verdict:
telecom/transport/healthcare/production queueing plus WEAP-type deficit
modelling; the only drought-adjacent "queuing" language found at record level
is institutional water-rights priority (Extra A records 5 and 6), which is an
allocation rule, not a stochastic queue state. The gap statement is frozen
(`AGENTS.md` §2); the WoS/Scopus "Cited by"/"Times Cited" trace of every seed
was completed the same day
(`analysis/P01_literature/citation_trace_2026-11-21.md`), closing Phase A.

### 3.3 Forward-citation trace (what happened to the seed papers)

We traced who cited the founding and closest papers inside WoS "Times Cited"
and Scopus "Cited by" where the seeds are indexed. OpenAlex citation links are
retained for Langbein (1958) and Prajamwong et al. (1997), which are not indexed
in the subscription databases. The database trace screened 76 citing records
and found Yang et al. (2016) and Jones et al. (2016), neither gap-changing.

| Seed | Times cited | What the citing literature does |
|---|---:|---|
| Langbein 1958, "Queuing Theory and Water Storage" | 70 | 64 citing titles sampled. Storage/reservoir theory, reliability, non-stationary aquifer storage, "Drought Management of Reservoirs" (Stephenson, 1998). **No drought-as-queue-backlog study.** |
| Gamble et al. 1990a (soil-water residence time as queue) | 6 | Only its companion demonstration paper. |
| Gamble et al. 1990b | 7 | No relevant descendants. |
| Batabyal 1996 (groundwater queueing) | 13 | Includes Yang et al. 2019 (canal management) and a 2026 water-supply reliability case study. No drought deficit state. |
| Harel & Mouche 2013 (runoff queueing) | 7 | Leads to Mouche & Harel 2016 (below). |
| Harel & Mouche 2014 (runoff connectivity) | 16 | Same 2016 paper. |
| Lefebvre 2019 (M/M/1/c for high river flows) | 1 | No descendants. |
| Yang et al. 2019 (canal management) | 27 | Navigation, irrigation scheduling, waterway modelling. No deficit queue state. |

**Verdict from citation tracing:** the queueing-in-water literature is a small, persistent family that repeatedly rediscovers capacity and residence-time questions. It does not appear to have moved into drought backlog accounting. That supports — but does not prove — our gap.

### 3.4 What is already known — do not claim any of this

This is the "do not embarrass yourself" list. Each item is established prior art.

**Storage theory and queueing are the same mathematical ancestor.**
- Langbein (1958), "Queuing Theory and Water Storage" — the founding record, in a hydraulics journal.
- Gani (1957, 1969), Prabhu (1998), Klemeš (1987, "One hundred years of applied storage reservoir theory").

**Queueing has already been applied across hydrology and water.**
- Gamble et al. (1990a, 1990b) — soil-water residence time as queueing disciplines.
- Batabyal (1996) — groundwater management.
- Buchberger & Schade (1997) — residential water demand as Poisson pulses.
- Harel & Mouche (2013, 2014) and **Mouche & Harel (2016)** — runoff and overland flow as queues. The 2016 paper, *Overland flow as a queueing process: The B/D/1 queue with an arbitrary service time* (Performance Evaluation, DOI 10.1016/j.peva.2016.10.001), is **new to our audit** and was found only through citation tracing.
- **Prajamwong, Merkley & Allen (1997)** — *Decision Support Model for Irrigation Water Management* (ASCE J. Irrigation and Drainage Engineering), uses a queuing system to allocate water to command areas and fields. **New to our audit**, found through the "water deficit + queue" screen. DOI 10.1061/(ASCE)0733-9437(1997)123:2(106).
- Palková and colleagues (2010, 2011, 2012) — irrigation capacity and process control.
- Yang et al. (2016) — queueing-based conjunctive surface-water/groundwater allocation.
- Yang, Li & Huo (2019) — irrigation canal management with groundwater uncertainty.
- Lefebvre (2019) — M/M/1/c for **high** river flows, Delaware River.
- Al-Sifao et al. (2026) — queueing for water-supply reliability and risk assessment.
- Jones, Lane & Sheridan (2016) and Jones (2019) — mathematical extensions of the runoff–runon queue lineage.
- Acosta et al. (2026 preprint) — coupled human–water drought state space with unmet accessible demand.
- Zhao et al. (2018) — non-stationary supply–demand reservoir reliability modelling.

**Non-stationary and correlated queueing is mature.**
- Galliher & Wheeler (1958), Rothkopf & Oren (1979), Massey & Whitt (1997), Tan et al. (2013), Whitt (2018).
- Bogachev et al. (2023, 2024) — waiting times under variable, long-range- and cross-correlated arrival rates. This means P02 cannot claim novelty for correlated arrivals.

**Machine learning for queues is a live, crowded field.**
- Asanjarani, Nazarathy & Taylor (2021), *A survey of parameter and state estimation in queues* — 62 citations.
- Ojeda et al. (2021), *Learning Deep Generative Models for Queuing Systems* (AAAI).
- Dai & Gluzman (2022), *Queueing Network Controls via Deep Reinforcement Learning* — 134 citations.
- Sherzer et al. (2024), *Approximating G(t)/GI/1 queues with deep learning*.
- Chen, Hong & Liu (2026), *Online Learning and Optimization for Queues with Unknown Arrival Rate and Service Distribution* (Operations Research).
- Garyfallos (2026), thesis on deep learning for non-Markovian nonstationary queueing systems.
- Bae & Lee (2026), contextual queueing bandits.

**Implication:** P02's novelty cannot be "we used ML on a queue". It has to be the hydrological parameterisation, the unmet-demand interpretation, the exact benchmark validation, and the pre-specified drought test.

### 3.5 A false positive worth recording

A 2001 paper — Hamza, Ouarda, Durrans & Bobée, *Développement de modèles de queues et d'invariance d'échelle pour l'estimation régionale des débits d'étiage* (Canadian Journal of Civil Engineering, DOI 10.1139/l00-121) — appears in "queue + low flow" searches. Reading its abstract shows that *queues* here means **statistical distribution tails** (French *queue de distribution*), not queueing theory. It is a low-flow regional frequency analysis. **Do not cite it as prior art.** Recording it prevents a future reviewer or co-author from making that mistake.

### 3.6 What still appears open — the narrow novelty claim

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens (295
> records), plus the citation traces, we found no study that puts all four of
> these together: (1) drought as an accumulated unmet-demand backlog with a
> finite-capacity state; (2) queue-state indicators reported as drought
> quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

This sentence is frozen as of 21 November 2026 (`AGENTS.md` §2). The 25 November
supplementary search found Acosta et al. (2026) and Zhao et al. (2018), neither
of which contains the full four-part combination, so the sentence is unchanged.

### 3.7 What could kill the novelty claim

These are the honest failure modes. I am writing them down now so we cannot quietly ignore them later.

| Risk | What would trigger it | What we do |
|---|---|---|
| **A real prior study exists** | A pre-submission refresh finds a study combining drought + queue backlog + learned rates + exact/pre-specified validation | Reopen Phase A, narrow the claim to the surviving contribution, or reposition P01 as a teaching synthesis |
| **"This is just old storage theory with new names"** | Reviewer says the queue mapping adds nothing over the standard reservoir mass-balance equation | The ablation in P01 §5 must show incremental information: the queue indicators must say something about drought harm that SPI/SPEI/storage anomaly does not. If it does not, publish the null result |
| **"ML + queue is not new"** | Reviewer cites Asanjarani 2021 or Sherzer 2024 | Pre-empt it in the introduction. Our contribution is hydrological covariates, deficit interpretation and exact drought validation |
| **Estimates are not trustworthy** | μ error near ρ ≈ 1 remains large after fixes; rate intervals do not cover truth | Fix before reporting. If unfixable, P02 becomes a negative methods result about identifiability — still publishable, but a different paper |
| **No added drought information** | Pre-specified tests show no gain over climatology + SPI | Report the null result explicitly, as already promised in P01 §6 |
| **Assumptions drive the result** | The revisable proxy convention (45,000 ha, 9×10⁶ m³ = 20 mm per claim, 3 claims/day cap) is district-level, not gauge-specific | Replace with gauge-specific canal/crop records if found; otherwise run the documented sensitivity envelope and label every pilot number illustrative |

---

## 4. All the steps I will perform

Everything below is in the order I intend to do it. Each phase ends with a decision gate.

### Phase A — Finish the novelty hunt (COMPLETE 21 November 2026; historical task list)

1. **Screen the decisive WoS hits.** Re-export or fix the renderer for Extra A (8 hits), Extra C (13 hits), S4 (6 hits) and S5 (66 hits). Record title, year, DOI and a one-line keep/drop reason for each. This is the highest-priority task: Scopus equivalents are clean, but WoS indexes different records.
2. **Scopus S1–S5 and Extra A/C are complete** (21 November 2026, institutional IP, no login; 295 records screened, no gap-changing study). Strings, interface notes and results are logged in `P01/search_protocol.md` and `P01/literature_audit.md`. No further Scopus work is needed for Gate A.
3. **Complete forward-citation tracing** by adding Yang 2019, Harel & Mouche 2014, Mouche & Harel 2016 and Prajamwong 1997 as seeds, and by checking the 2016 overland-flow paper's references.
4. **Full-text screen the retained set**, not just titles and abstracts. Apply the decision rule already written in the search plan: if any study does all four elements in §3.6, narrow or remove the gap statement.
5. **Update the audit and manuscript** only if something gap-changing appears. Add Mouche & Harel 2016 and Prajamwong et al. 1997 to the prior-art table either way — they are genuinely relevant and currently missing.
6. **Freeze the wording of the gap statement** with the final search scope, so P01 and P02 say exactly the same thing.

**Gate A:** write one sentence — "As of [date], we found no study in [sources] that does [four elements]" — and do not change it later without redoing this phase.

### Phase B — Finish P01

7. **Claim-volume convention — REVISED 25 November 2026.** One claim = 9×10⁶ m³ = 20 mm over a 45,000 ha Sangli canal-irrigated proxy; K = 20 claims = 400 mm; service cap 3 claims/day = 60 mm/day. The area is documented district evidence, not a gauge-specific measurement. Source and envelope: `analysis/claim_convention_2026-11-25/`.
8. **Tighten the mapping section — DONE 25 November 2026.** P01 §2 now separates physical storage capacity from backlog tolerance and couples storage/backlog through the served-water flux and conservation ledger.
9. **Expand prior art — DONE 25 November 2026.** P01 now includes Yang et al. (2016), Jones et al. (2016), Jones (2019), Acosta et al. (2026) and Zhao et al. (2018), and states that variable/correlated queueing and ML-for-queues are mature.
10. **Strengthen non-stationarity — DONE 25 November 2026.** Box 1 now has corrected units, one-year spin-up, Floquet verification, conservation residual and a 44-case sensitivity grid. The direction of the averaging effect persists across the declared grid; real-basin evidence remains outstanding.
11. **Write a falsifiable programme — DONE 25 November 2026.** P01 §5 now begins with an identification gate and a table of metrics, baselines, held-out units and null clauses.
12. **Add guardrails — DONE 25 November 2026.** P01 §6 now includes assumptions, conservation, dependence, uncertainty, raw-CMIP6 and null/non-identifiability rules.
13. **Build the figures/tables — DONE 25 November 2026.** Three reproducible PNG/SVG figures and five numbered tables are embedded in P01; generation scripts and captions are in `P01/figures/`.
14. **Internal read-through for novelty language — DONE 25 November 2026.** The draft uses the exact frozen sentence and avoids prohibited priority language.
15. **Prepare the WRR submission package — DONE AS DRAFT 25 November 2026.** The 219-word abstract, cover letter and code/data statement are in `P01/submission/`.

**Gate B:** the technical checklist passes (`P01/GATE_B_CHECKLIST.md`). Author sign-off remains on submission metadata, archive links, recovery/μ definitions and disclosed literature limitations. Then P02 starts.

### Phase C — Build and test P02

16. **Fix the μ-estimation weakness near ρ ≈ 1.** This is the known dominant error in the current estimator. Try monotone constraints, better features, and calibration; report what works.
16a. **Correct the P02 indicator contract and evaluation plumbing.** Fix R/Python unit labels, blocked-demand parity, server accounting, spin-up, mass-calibration leakage and adaptive stability; add golden tests.
16b. **Implement time-varying recovery distributions and identification experiments.** Validate recovery probabilities against exact/DES references, then test parameter separation with independent storage or impact observations. Report robust indicators if full identification fails.
17. **Do the formal Floquet convergence study** — how fine the time discretisation must be for the periodic reference solution to be trusted.
18. **Do the MMPP parameter sweep** — the current 1.16× burstiness amplification is a single parameter setting and must be tested across regimes before any general statement.
19. **Convert the R pilots into a multi-gauge pipeline.** Keep the linear style the user prefers: BLOCK 1 settings at the top, then blocks run top to bottom, no hidden functions, no package dependencies beyond base R. Add gauge 4064 Yadgir as the second gauge.
20. **Resolve the zero-flow question** for gauge 4026: are the 9,710 zero-flow days real zeros or a fill value? Check CAMELS-India documentation before interpreting ρ.
21. **Test the revisable command-area proxy and claim volume.** Search for gauge-specific canal/crop records; if found, replace the 45,000 ha / 9×10⁶ m³ proxy and re-run. If not, run the documented 45,000 / 174,000 / 190,000 ha envelope and keep every output labelled illustrative.
22. **Implement CMIP6 bias correction** against IMD/CAMELS before using any future rate. The current Hargreaves ET0 output is uncorrected and must not be published.
23. **Build future service rates μ(t).** Validate CAMELS-IND-Proj historical streamflow and LSTM provenance, then use its 13-model/four-SSP ensemble as the primary conditional projection. Raw CMIP6 remains pipeline-check-only; any bias-corrected delta-change comparison is secondary.
24. **Set up held-out validation:** held-out years, held-out basins, and named drought events. Write the metrics and the baseline comparisons **before** looking at results (pre-registration in the project notes).
25. **Propagate uncertainty** from rate estimates into backlog indicators using the bootstrap intervals already built into the estimator code.
26. **Run the ablation that matters:** does the queue state add drought information beyond SPI/SPEI/SSI and a climatological queue? If not, record the null result.
27. **Write P02** with the structure already in `P02/README.md`, and prepare the HESS submission.

**Gate C:** P02 is ready only when the estimator beats the climatological baseline on held-out data, or when a solid null result is written up honestly.

### Phase D — Cross-cutting hygiene

28. **Keep the test suites green** — 12 P01 tests, 6 benchmark tests, 7 estimator tests (25 total) — and add a test for every new feature.
29. **Version control — resolved.** The workspace is a Git repository; continue committing coherent paper/analysis changes.
30. **Write one reproducibility page per paper** with exact run commands (including the Rscript path), file names, and the order to run them. The P02 investigation report is complete; paper-specific pages remain a Gate-B/C task.

---

## 5. The five things I will do first, in order

1. ~~Screen WoS Extra A (8 hits), Extra C (13 hits), S4 (6) and S5 (66).~~
   **Done 21 November 2026** — 93/93 screened by export, zero retained
   (`analysis/P01_literature/wos_screening_2026-11-21.md`).
2. ~~Freeze the gap sentence using the completed WoS/Scopus scope.~~
   **Done 21 November 2026** — frozen and dated in `AGENTS.md` §2,
   `START_HERE.md` §5 and `P01/P01_draft_v2.md` §6.
3. Claim convention is revised and documented (45,000 ha proxy; 9×10⁶ m³ = 20 mm per claim; K=20 = 400 mm). Gauge-specific replacement or the sensitivity envelope remains a P02 task.
4. Full-text screen the retained prior-art set: nothing was retained, so this
   step is empty; the already-verified prior-art records remain cited as is.
5. ~~Build the reproducible P01 figures and WRR package drafts.~~ **Done 25 November 2026**; the technical Gate B checklist passes and awaits author sign-off.

---

## 6. What I need from you

- Sign the P01 Gate B checklist: final title/abstract/keywords, corresponding-author details and declarations.
- Provide the public repository URL, archived release/DOI and software licence.
- Confirm recovery means backlog clearance including reneging, or request a service-only redefinition.
- Confirm aggregate μ uses c=1 unless separate supply sources are documented.
- Accept the disclosed literature limitations or authorize retrieval of missing restricted records.
- Confirm that WRR (P01) then HESS (P02) remains the order of work.

Everything else — searches, screening, code, drafts, tests and figures — is complete for the technical Gate B pass.
