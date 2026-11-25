# Session log

## 25 November 2026 — P01 Gate B technical pass

I ran the P01 Gate B audit and closed the agent-fixable items. Three reproducible
PNG/SVG figures are embedded in the manuscript; the WRR abstract is 219 words;
the cover letter quotes the frozen sentence exactly; and the code/data statement,
number-provenance map and Gate B checklist are in `P01/`. I added missing prior
art (Jones 2016/2019, Palková & Rodný 2011, Klemeš 1987, first-passage,
attribution and ML/identification references), corrected μ units and fluid
drift, defined current recovery as backlog clearance including reneging, and
disclosed the ramp ledger residual.

I strengthened the claim-scale test so it actually rescales rates, capacity,
threshold and cap, and added `src/P01/validate_literature_counts.py` plus a test
for the 142/295/437/93/76 bibliometric totals. The full suite passes 25/25.
`P01/GATE_B_CHECKLIST.md` records a technical pass; author sign-off remains on
submission metadata, archive links, recovery/μ definitions and the disclosed
literature limitations.

## 25 November 2026 — P02 model and data protocol

I verified the local data holdings rather than starting a final indicator
analysis. CAMELS-IND has 472 forcing files, two streamflow files and eight
attribute files; IMD has 75 annual files per variable; raw CMIP6 historical/SSP
forcing is present. CAMELS-IND-Proj adds 13 models × historical plus four SSPs
of daily projected streamflow, with gauge 4026 complete in all 65 files from
1980–2100. This makes projected streamflow the primary conditional future μ
route after historical/provenance validation, not raw-CMIP6 delta-change.

I wrote `analysis/P02_methods/MODELLING_PLAN.md`, `DATA_REQUIREMENTS.md` and a
verified inventory CSV. The plan uses process-based λ until demand labels exist,
aggregate μ with c=1 for the current pilot, a zero-aware hurdle μ nowcast only
after zero-flow/regulation semantics are resolved, exact solver verification,
simulation-based identification, time-dependent recovery probabilities and
blocked held-out validation. Missing requirements are crop area/calendar,
Drought Intelligence Explorer v2, zero-flow/regulation evidence and CAMELS-IND-Proj
LSTM provenance. No final P02 result is claimed.

## 25 November 2026 — repository cleanup, P01/P02 naming and claim-convention refresh

I created a safety checkpoint commit (`cb76835`) before restructuring the
repository. The active papers are now P01 and P02; folders, imports, tests, R
paths and documentation were updated together. Shared code lives in
`src/shared/`, paper code in `src/P01/` and `src/P02/`, tests in `tests/`, current
documents in `docs/`, source references in `references/`, and generated R data in
`P02/data/generated/`. Superseded drafts, stale HTML, outdated planning notes,
Python caches, the buggy one-off table builder and stale generated outputs were
deleted. The full Python suite passes 25/25 and all three R scripts parse.

The claim convention was unlocked and revised using official Sangli evidence:
45,000 ha is the district canal-irrigated proxy, one claim is 9×10⁶ m³ = 20 mm,
K=20 remains 400 mm, and the 60 mm/day cap is 3 claims/day. This is explicitly
a district proxy, not a gauge measurement. Source evidence and the
45,000/174,000/190,000 ha envelope are in
`analysis/claim_convention_2026-11-25/`. I regenerated the gauge-4026 rate CSV
with the revised convention (μ max 3.0 claims/day) and added a 30-case scale
check: exact fluid results are invariant to area/depth, while finite-claim peak
backlog ranges from 389.98 to 397.52 mm for 10–40 mm claims.

I reopened WoS through the institutional IP session. S1 stayed at 25, Extra A at
8, S5 at 66, and S4 rose from 6 to 7. The single new S4 record is a wireless-QoS
paper and was dropped as irrelevant; the frozen novelty sentence is unchanged.
Scopus displayed an intermittent-service notice and returned no records even for
an exact known title, so no new Scopus screen is claimed.

## 25 November 2026 — novelty strengthening and conservation contract

I applied the attached evidence-driven novelty workflow without changing the
frozen 21 November gap sentence. A supplementary OpenAlex/web search found
Acosta et al. (2026) and Zhao et al. (2018) as important prior art; neither
contains the full four-part queue-specific combination. I packaged the search,
screening, candidate ranking and adversarial audit in
`analysis/novelty_2026-11-25/`. The recommended direction is an
identifiability-first, conservation-constrained deficit-state model, with
time-varying recovery distributions as the first P02 extension after Gate B.

I corrected the shared Python indicator contract: blocked demand is now
counted, served/abandoned/backlog-exposure quantities are separate, and a
demand-conservation residual is returned. I added three tests and corrected the
Box 1 spin-up from a fractional-year cut to one full year. P01 now distinguishes
physical storage from backlog, replaces the stale search-status paragraph,
adds the identification gate and pre-specified test table, and incorporates the
new prior art. The frozen sentence is unchanged.

Tests: **22/22 pass** (9 P01, 6 benchmark, 7 estimator). New tests cover blocked
demand, ledger closure, stock/flux separation and the Box 1 sensitivity baseline. Synthetic anchors remain
0.91607 claims exact/RK4 and 0.91295 claims DES; the non-stationary peak is
2.12950 claims. The two-year post-spin-up abandoned-demand totals are 13.37 and
15.90 claims, not claim-days. I added `src/P01/box1_sensitivity.py` and a
44-case synthetic grid: peak-backlog ratios range from 1.20 to 5.33 and
critical-probability ratios from 2.06 to 92.9, with the direction preserved in
every case. The largest absolute ledger residual is `1.7e-6` claims. P02 R-code
unit/server/spin-up corrections remain blocked until Gate B. Exact next action:
build the reproducible P01 figures and prepare the WRR package.

## 21 November 2026 — approach preparation

I read the project orientation, phase plan, current P01 draft, literature audit,
search log, data contract and both package READMEs, then prepared a phase-aware
approach later consolidated into `docs/novelty/NOVELTY_AND_PLAN_REPORT.md`. No scientific code, manuscript
argument or frozen gap sentence was changed. The 18 required tests failed with
the default `python` because that interpreter has no NumPy; they passed 5/5,
6/6 and 7/7 with the existing `drought` Conda environment, so I recorded that
interpreter in `START_HERE.md:141-148`, `P01/README.md:28-34` and
`P02/README.md:41-52`. I did this so the documented commands reproduce the
checks on this machine. The new approach note records the numbers trusted
today, the 93-record WoS screen that is the single next action, the P01 work
sequence through Gate B, and the P02 work packages to hold until Gate B. No new
test was added.

After the naming confirmation, I changed the human-facing labels to P01 and
P02. The folder/import restructure was completed on 25 November 2026; see the
housekeeping entry above. I created `docs/project/RESEARCH_PROTOCOL.md` as the
organising protocol. Rendered HTML views were generated at the time and later
removed during housekeeping because they were stale duplicates of the Markdown.

I then started the actual Phase A analysis. The browser reached the Clarivate
sign-in page but had no institutional session, so the 93 WoS records could not
be read; this is recorded as an access blocker in
`analysis/P01_literature/wos_screening_2026-11-21.md`. I created the `analysis/` workspace
with P01 and P02 folders, added a record-level screening sheet with the four
search sets and decision rule, and linked it from `docs/project/RESEARCH_PROTOCOL.md` §8. I
did this so the screening can continue in an organised file as soon as the
institutional login is available. No records or results were invented.

To make the field-level framing explicit, I added `docs/project/RESEARCH_PROTOCOL.md` as an
initial-state note. It states the field aim, current state, formulated
objectives for P01 and P02, non-objectives, blockers and file map. This is a
plain-language organising document, not a manuscript edit and not a scientific
result. I linked it from `docs/project/RESEARCH_PROTOCOL.md` §8 so the field-level state and
the screening work are now indexed together.

I prepared the repository for GitHub transfer. I added `.gitignore` and
`README.md`, then initialised Git and committed the full working state. The
purpose is to make the repository pullable on another machine without losing
the current document structure, code, screening sheet or test state. The local
history was then pushed to
`https://github.com/anixn/queuing-lowflow-hydrology.git`, and branch `main` now
tracks `origin/main`.

The repository is now consolidated on `master`. I merged the earlier `main`
history into `master`, pushed `master`, and deleted `main` locally and on
GitHub. The purpose is to keep one canonical branch and avoid confusion when
the repository is pulled on another computer. The merge preserves the complete
P01/P02 documentation, code and screening workspace; only the old branch name
changed.

## 21 November 2026 — WoS 93-record screen complete, gap sentence frozen

I resumed the blocked WoS screen. The session browser was IP-entitled
(Clarivate splash "Register to personalize your Web of Science experience",
IP 14.139.122.139), so **no institutional profile sign-in was needed**: search,
results and Export all worked without a profile. Two interface facts changed
since 20 November and are recorded in `P01/search_protocol.md`: the
Advanced Search Query Builder now **requires** the `TS=(...)` prefix (the bare
Boolean returns "Invalid field tag"), and the earlier record-card
`loading-cover` stall was bypassed entirely by exporting each result set with
**Export → Excel** (record content "Author, Title, Source, Abstract"). S5
exceeded the page size of 50, so it was exported in two pages (1–50, 51–66);
the "Records from 1 to 66" range option did not take.

All 93 records were screened at title/abstract level: **S4 = 6, S5 = 66,
Extra A = 8, Extra C = 13, zero retained.** The full record table with a
one-line reason per record is in `analysis/P01_literature/wos_screening_2026-11-21.md`
§5; the five raw export files and the row-building script are kept in
`analysis/P01_literature/exports/`. The exports were additionally keyword-scanned for
`queue`, `queing`, `waiting time`, `backlog`, `service rate`, `arrival rate`
and `backlogged`; the only match is a healthcare logistics paper (S5 record 50
/ Extra C record 5). Two institutional echoes are noted but not gap-changing:
water-rights allocation described as a priority "queuing system" (Extra A
records 5 and 6).

I transferred the result to the audit trail: `P01/literature_audit.md` now
records the resolved renderer limitation, the completed WoS screen (142 WoS +
295 Scopus = 437 records, zero gap-changing findings) and the frozen sentence;
`P01/search_protocol.md` has a new §1c and updated run-log rows;
`docs/novelty/NOVELTY_AND_PLAN_REPORT.md` §3 and §5 were updated; `AGENTS.md` §2 now holds
the **frozen, dated gap sentence** ("Frozen 21 November 2026"), §8 marks the
Phase A record-level screens done; `START_HERE.md` §5 and `docs/project/RESEARCH_PROTOCOL.md`
§2/§6/§8 carry the same frozen sentence and resolved blocker. The four-part
enumeration in the sentence is unchanged; only the completed-scope clause was
updated, which is the Phase A freeze action.

Tests: 18/18 pass (5 + 6 + 7; `python tests/test_queue_core.py`,
`python tests/test_nonstationary_bench.py`,
`python tests/test_rate_estimators.py`). No new test was added — this
session changed only documents and WoS exports, no solver code. Next action:
forward-citation tracing inside WoS/Scopus (`search_protocol.md` §2),
then Phase B (finish P01).

## 21 November 2026 — seed citation trace complete; Phase A closed (Gate A passed)

I completed the last Phase A screening item: forward-citation tracing of the
seed list inside WoS "Times Cited" and Scopus "Cited by", replacing the
OpenAlex substitute for every seed the subscription databases index. In WoS CC
(export → Excel with abstracts): Harel & Mouche 2013 (5 citing), Harel &
Mouche 2014 (10), Lefebvre 2019 (1), Yang 2019 (23), Mouche & Harel 2016 (1).
In Scopus (title search → "Cited by" tab, read on screen): Gamble 1990a (5),
Gamble 1990b (6), Batabyal 1996 (14), and the newly found Yang 2016 CSAE
record (11). Langbein 1958 and Prajamwong 1997 are confirmed unindexed in
both WoS CC and Scopus; the OpenAlex trace remains their source. Total: 76
citing records screened (40 WoS + 36 Scopus); every record was scanned at
title/abstract/keyword level for queue, waiting time, drought, deficit, unmet
demand and backlog.

Result: no gap-changing citing record anywhere. Two new prior-art records,
both added to the audit's verified table: Yang, Guo, Li & Li (2016,
*Nongye Gongcheng Xuebao / Trans. CSAE* 32(6), DOI 10.11975/j.issn.1002-6819.
2016.06.016) — queueing-based conjunctive surface/groundwater allocation of an
irrigation district; and Jones, Lane & Sheridan (2016, *J. Hydrol.*, DOI
10.1016/j.jhydrol.2016.06.056) — extending the Harel–Mouche queue-based
runoff-runon theory to finite hillslopes, with the 2019 *Journal of Applied
Probability* descendant ("Runoff on rooted trees") showing the lineage is
still mathematically active. Yang 2019's citing set shows a sustained
canal-operation lineage (2021–2026) with no drought indicators.

I recorded the trace in `analysis/P01_literature/citation_trace_2026-11-21.md` (with
four citing-article exports in `analysis/P01_literature/exports/`), updated
`P01/literature_audit.md` (new prior-art rows + a trace summary section +
"still required" item 2 done), `P01/search_protocol.md` (§2 marked
done, run-log rows updated, 76-record total), `AGENTS.md` §8 (Phase A closed,
Gate A passed, Phase B current), `docs/novelty/NOVELTY_AND_PLAN_REPORT.md`, `README.md`,
`docs/project/RESEARCH_PROTOCOL.md`, `docs/novelty/NOVELTY_AND_PLAN_REPORT.md`, `docs/project/RESEARCH_PROTOCOL.md`,
`analysis/` READMEs and `docs/project/RESEARCH_PROTOCOL.md`. The frozen gap sentence needed no
edit. Tests: 18/18 pass. No new test — documents and database exports only.
