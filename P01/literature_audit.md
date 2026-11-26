# Literature audit for P01 — 20–25 November 2026

## Protocol

The built-in web-search tool returned no results for any query in this session.
Verification was therefore done through two bibliographic APIs:

* **Crossref REST** (`api.crossref.org/works`), bibliographic and DOI lookups.
* **OpenAlex** (`api.openalex.org/works`), `title.search`, `abstract.search`,
  `fulltext.search` and DOI lookups. Free-tier shared budget; no API key used.

Searches were run on 20–21 November 2026. Web of Science Core Collection was
searched on 20–21 November 2026 and Scopus on 21 November 2026 (institutional
IP, no login; see below). This is a **scoping audit**, not a systematic review.
WoS records were screened from exported titles, abstracts and keywords;
Scopus records were screened at title level. Database citation tracing was
completed inside WoS/Scopus where the seeds are indexed, with OpenAlex retained
for unindexed seeds. Zero gap-changing records were retained. A supplementary
targeted search on 25 November 2026 is recorded below and did not change the
frozen sentence.

## Queries run (compact)

| # | Source | Query / filter | Hits | Useful? |
|---|---|---|---:|---|
| 1 | OpenAlex | `search=queueing drought` (title/abstract/fulltext) | 6,653 | No — noisy fulltext matches |
| 2 | OpenAlex | `title.search:queueing drought` | 0 | Yes — no titled paper |
| 3 | OpenAlex | `title.search:queuing drought` | 0 | Yes — no titled paper |
| 4 | OpenAlex | `abstract.search:queueing,title.search:drought` | 4 | Yes — none drought-quantitative |
| 5 | OpenAlex | `title.search:queueing water` | 38 | **Yes — key prior art** |
| 6 | OpenAlex | `title.search:queueing hydrology` | 1 | **Yes — Lefebvre 2019** |
| 7 | OpenAlex | `search="queueing theory" hydrology water` | 171 | **Yes — Harel & Mouche 2013** |
| 8 | OpenAlex | `search=nonstationary queueing time-varying arrival service rates` | 1,505 | Yes — mature OR field |
| 9 | OpenAlex | `abstract.search:queuing,title.search:water storage` | 3 | **Yes — Langbein 1958** |
| 10 | Crossref | DOI `10.1061/JYCEAJ.0000222` | 1 | **Yes — full metadata** |
| 11 | Crossref / OpenAlex | Six `[VERIFY]` DOIs and titles | — | **Yes — all resolved (below)** |
| 12 | OpenAlex | `search=groundwater drought recovery time first passage busy period` | 258 | No direct hit; gap survives |

## Web of Science Core Collection search — 20 November 2026

Interface: new WoS "Advanced search" / Fielded Search UI, Topic field, no
filters (all editions, all years, all document types), institutional login
(Pandit Deendayal Petroleum University). **Interface note:** the Topic field
rejected the `TS=(...)` prefix with "Invalid query"; the bare Boolean
expression must be pasted instead. The strings in `search_protocol.md`
should be used without `TS=` in this interface.

**Dated reconciliation (26 November 2026, v2 rebuild).** The two `TS=` notes in
this file are not a contradiction. The 20 November interface rejected
`TS=(...)`; the 21 November record-level pass used the interface where
`TS=(...)` was accepted (see the "WoS record-level screen" section below). Both
are recorded as run, on their dates. Separately, the frozen sentence keeps the
completed-screen count of **142** WoS records; a 25 November refresh returned
one additional record (143 in the live export), which was screened under the
same criteria and retained nothing. The frozen sentence is therefore **not**
reworded.

| # | Query as run (Topic field) | Hits | Titles/abstracts screened | Retained for full text |
|---|---|---:|---:|---:|
| S1 | `((queue* OR "queuing theory" OR "queueing theory" OR "mass service") AND (drought OR "low flow" OR "water storage" OR "unmet demand" OR "water deficit"))` | 25 | 25 | 0 |
| S2 | `(("queuing theory" OR "queueing theory" OR "mass service") AND (hydrolog* OR "water resource*" OR river* OR reservoir* OR irrigation OR groundwater))` | 24 | 24 | 0 |
| S3 | `(drought AND ("recovery time" OR "first passage" OR "busy period") AND (queue* OR congestion OR backlog))` | 0 | — | 0 |
| S4 | `(("non-stationary" OR nonstationary OR "time-varying") AND queue* AND (hydrolog* OR drought OR water OR irrigation))` | 6 | 6 | 0 |
| S5 | `(("unmet demand" OR "deficit accumulation" OR "demand backlog") AND (drought OR irrigation OR "water supply"))` | 66 | 66 | 0 |
| Extra A | `(drought AND (queue* OR queu*))` | 8 | 8 | 0 |
| Extra B | `(drought AND ("first passage" OR "busy period") AND (reservoir* OR storage OR deficit))` | 0 | — | 0 |
| Extra C | `(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 13 | 13 | 0 |

**Record-level screening limitation (21 November 2026) — RESOLVED 21
November 2026.** For S4, S5 and Extra A/C the WoS results page initially
returned hit counts but the record cards never left the `loading-cover`
state. The limitation was bypassed the same day by exporting every result set
with WoS "Export → Excel" (record content: Author, Title, Source, Abstract)
without any profile sign-in; all 93 records were then screened at
title/abstract level. See "WoS record-level screen" below and
`../analysis/P01_literature/wos_screening_2026-11-21.md`.

**S1 screening result.** No hydrology-drought queue study. The hits were
mostly telecommunications, transport and healthcare queueing that matched
"low flow" or "water storage" in an unrelated sense; plant drought-memory,
bird ecology and a GRACE review contained no queueing. One cross-domain paper
(Zin, Tin & Toriu, 2015, *ICGEC*) borrows both queueing theory and stochastic
water storage theory for web-page ranking — further evidence that the analogy
is known outside hydrology, not a drought study.

**S2 screening result.** Confirms the hydrological niche and adds four records
not in the earlier Crossref/OpenAlex audit: Yang et al. (2019) on irrigation
canal management, Palková et al. (2012) and Palková & Rodný (2010/2011) on
irrigation-system control and capacity, and Harel & Mouche (2014) on runoff
connectivity. It also surfaced Bogachev et al. (2023, 2024) on waiting times in
queues with variable, long-range-correlated arrival rates — relevant to P02's
non-stationary benchmark, not to drought prior art. All other hits were port,
inland-waterway, railway or data-network queueing.

DOI verification: Crossref and OpenAlex, 20 November 2026. Yang et al. 2019 =
10.1007/s11269-019-02372-y; Harel & Mouche 2014 = 10.1002/esp.3604; Bogachev
et al. 2024 = 10.1016/j.physa.2024.130152; Bogachev et al. 2023 =
10.1016/j.physa.2023.128513. The Palková records have no DOI (National Library
of Serbia / Rocznik Ochrona Środowiska and Technical Sciences proceedings).

## Scopus search — 21 November 2026

Interface: Scopus Documents, **basic** search box, institutional IP address
(no login required; the header still shows "Sign in"). Scopus wraps the entered
text in `TITLE-ABS-KEY ( ... )` automatically, so the strings below were run as
bare Boolean text; adding the field code manually double-wraps the query and
returns zero hits. The Advanced Search textarea did not accept automated input
reliably and was not used. Page size was set to 200 so all records appeared on
one page. No year, language or document-type filters were applied.

| # | Query as run (bare Boolean, wrapped by Scopus) | Hits | Titles screened | Retained |
|---|---|---:|---:|---:|
| S1 | `(queue* OR "queuing theory" OR "queueing theory" OR "mass service") AND (drought OR "low flow" OR "water storage" OR "unmet demand" OR "water deficit")` | 38 | 38 | 0 |
| S2 | `("queue* theory" OR "queuing theory" OR "queueing theory") AND (hydrolog* OR "water resource*" OR river* OR reservoir* OR irrigation OR groundwater)` | 116 | 116 | 0 |
| S3 | `drought AND ("recovery time" OR "first passage" OR "busy period") AND (queue* OR congestion OR backlog)` | 0 | — | 0 |
| S4 | `("non-stationary" OR nonstationary OR "time-varying") AND queue* AND (hydrolog* OR drought OR water OR irrigation)` | 11 | 11 | 0 |
| S5 | `("unmet demand" OR "deficit accumulation" OR "demand backlog") AND (drought OR irrigation OR "water supply")` | 98 | 98 | 0 |
| Extra A | `(drought AND (queue* OR queu*))` | 15 | 15 | 0 |
| Extra C | `(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 17 | 17 | 0 |

**Total screened: 295 records; zero gap-changing findings.** S3 was run without
the plan's `OR "return period"` clause so that it matched the WoS S3 string.
Across all searches the hits echoed the WoS results — mostly telecom, transport
and data-network queueing, plus operational irrigation/water-supply queueing.
Known prior-art lines surfaced again (including Yang 2019, the Palková records,
Harel & Mouche, and Prajamwong et al. 1997). That is a useful cross-database
check, but no study combined drought-as-queue-backlog with covariate-learned
rates and pre-specified validation.

The two decisive direct tests (Extra A and Extra C) are fully screened in
Scopus at 15 and 17 records. The corresponding WoS sets were also screened by
export on 21 November 2026; the two databases do not index identical sets, and
both screens are complete.

## Verified prior art that changes the framing

| Work | Record | What it does | Consequence for P01 |
|---|---|---|---|
| **Langbein (1958)**, "Queuing Theory and Water Storage", *J. Hydr. Div.* 84(5), 1–24, DOI 10.1061/JYCEAJ.0000222 | Crossref verified; 9 citations; discussion/closure 1959 (DOIs 10.1061/jyceaj.0000296, .0000337) | Explicit queue–storage analogy in a hydraulics journal | Roadmap implication that the junction is unclaimed is wrong. Review must **reclaim and update**, not discover. |
| **Harel & Mouche (2013)**, *WRR*, DOI 10.1002/2013WR013596 | OpenAlex verified | Steady runoff–runon equation as single-server waiting time | Kills novelty claim for "queueing applied to runoff generation" (roadmap candidate 2). |
| **Lefebvre (2019)**, DOI 10.1478/aapp.97s2a18 | OpenAlex verified | M/M/1/c CTMC for **high** river flows, Delaware River | Same machinery as our prototype but high-flow; strongest direct methodological precedent. |
| **Gamble, Eckstein & Edwards (1990a)**, *J. Hydrol.* 113, 1–25, DOI 10.1016/0022-1694(90)90164-S; **(1990b)**, 113, 27–49, DOI 10.1016/0022-1694(90)90165-T | Crossref + OpenAlex verified | Queueing disciplines applied to soil-water residence time from water-budget data | Storage-as-queue has deep hydrological precedent; cite in dual-representation section. |
| **Buchberger & Schade (1997)**, "Poisson Pulse Queueing Model for Residential Water Demands", in *Managing Water: Coping with Scarcity and Abundance*, pp. 488–493 (ASCE); no DOI | OpenAlex W2464114327 | Poisson pulse arrivals for residential water demand | Precedent for demand-as-arrivals; cite without DOI. |
| **Gordienko & Ruiz de Chávez (2012)**, *Proc. 9th ICINCO*, DOI 10.5220/0004012603090312 | OpenAlex verified | Controlled GI/D/1/∞ queue and water release in a simple dam model | Precedent for state-dependent service / drought-mode release. |
| **Batabyal (1996)**, "The queuing theoretic approach to groundwater management", *Ecological Modelling* 85, 219, DOI 10.1016/0304-3800(94)00178-2 | OpenAlex verified | Queueing for groundwater management | Groundwater queueing is **not** novel. Topic 7 must be about multi-year drought deficit + GRACE, not "first groundwater queue". |
| **Palková & Hennyeyová (2012)**, "Determination of optimal capacity of irrigation system using queuing theory", *Acta Univ. Bohem. Merid.* 11, 67, DOI 10.32725/acta.2008.011 | OpenAlex verified | Queueing for irrigation-system capacity | Precedent for agricultural/irrigation queueing; narrow the Topic 1 gap carefully. |
| **Al-Sifao et al. (2026)**, *Applied Sciences* 16(3), 1608, DOI 10.3390/app16031608 | Crossref verified (full abstract) | M/M/c//N/Y finite-source multi-server queue with spares for well-field pump reliability, Jabal Hasouna, Libya | Groundwater *supply reliability* queueing exists. Not drought deficits. |
| **Whitt (2018)**, "Time-varying queues", *Queueing Models and Service Management* 1(2), open access | OpenAlex W3170396656 | Modern synthesis of non-stationary queues | Correct venue (v1 wrongly said Springer "Queueing Theory and Network Applications"). |
| **Yang, Li & Huo (2019)**, *Water Resources Management* 33(12), 4367–4384, DOI 10.1007/s11269-019-02372-y | WoS S2 + Crossref verified | Queueing-based irrigation water allocation with groundwater-utilisation uncertainty; canal-management decision support | **New.** Irrigation queueing with uncertainty exists; narrow Topic 1 further. Not drought deficit accounting or learned rates. |
| **Palková, Rodný & Kiedrowicz (2012)**, *Rocznik Ochrona Środowiska* 14, 161–171; **Palková & Rodný (2010/2011)**, *Scientific Papers / Technical Sciences* 10(1) / 11(1) | WoS S2 + OpenAlex verified; no DOI | Queueing for irrigation-system process control and optimal capacity | **New.** Confirms a sustained irrigation-queueing line, not a one-off. Design/control focus, no drought indicators. |
| **Harel & Mouche (2014)**, *Earth Surface Processes and Landforms* 39(11), 1514–1525, DOI 10.1002/esp.3604 | WoS S2 + OpenAlex verified | Queueing-based runoff–runon connectivity on 2-D slopes | **New.** Extends the runoff queueing precedent; still steady state, no deficit accounting. |
| **Mouche & Harel (2016)**, "Overland flow as a queueing process: The B/D/1 queue with an arbitrary service time", *Performance Evaluation*, DOI 10.1016/j.peva.2016.10.001 | OpenAlex forward-citation trace from Harel & Mouche 2013/2014 and Langbein 1958 | Overland flow represented as a B/D/1 queue | **New (found 21 Nov 2026 by citation tracing, not by keyword search).** Shows keyword searches alone undercount the hydrology-queue niche. Still no drought deficit state. |
| **Prajamwong, Merkley & Allen (1997)**, "Decision Support Model for Irrigation Water Management", *J. Irrigation and Drainage Engineering* 123(2), 106, DOI 10.1061/(ASCE)0733-9437(1997)123:2(106) | OpenAlex `abstract.search:water deficit + queue` screen, 21 Nov 2026; not indexed in WoS CC or Scopus (checked 21 Nov 2026) | CADSM uses a queuing system to allocate available water to command areas and fields; root-zone water deficit in yield response | **New.** Pushes irrigation-queueing precedent back to 1997. Operational allocation, not drought state or learned rates. |
| **Yang, Gaiqiang; Guo, Ping; Li, Ruihuan; Li, Mo (2016)**, "Optimal allocation model of surface water and groundwater based on queuing theory in irrigation district", *Nongye Gongcheng Xuebao / Transactions of the Chinese Society of Agricultural Engineering* 32(6), DOI 10.11975/j.issn.1002-6819.2016.06.016 | Scopus Cited-by trace of Batabyal 1996, 21 Nov 2026 (11 citing records screened, `../analysis/P01_literature/citation_trace_2026-11-21.md`) | Conjunctive surface-water/groundwater allocation of an irrigation district formulated as a queueing model | **New (found by citation tracing, not keyword search).** Extends the irrigation-queueing line to conjunctive-use allocation. Operational optimisation; no drought deficit state, indicators or learned rates. |
| **Jones, Owen D.; Lane, Patrick N. J.; Sheridan, Garry J. (2016)**, "The stochastic runoff-runon process: Extending its analysis to a finite hillslope", *Journal of Hydrology*, DOI 10.1016/j.jhydrol.2016.06.056 | WoS Times-Cited trace of Harel & Mouche 2013, 21 Nov 2026 (3 citing records screened, `../analysis/P01_literature/citation_trace_2026-11-21.md`) | Extends the Harel–Mouche queue-based stochastic runoff-runon theory to finite hillslopes (asymptotics + Monte Carlo) | **New (found by citation tracing, not keyword search).** The runoff-runon queue lineage is still active mathematically (see also Jones 2019, *J. Applied Probability* 56(4):1065–1085, "Runoff on rooted trees"). Still runoff generation, not drought deficit accounting. |

Full bibliographic detail for all resolved records is in `P01_draft_v2.md` References.

## Supplementary targeted novelty search — 25 November 2026

This search tests the proposed stronger framing around conservation,
identifiability, coupled storage–backlog states and recovery. It is
exploratory and does not reopen or reword the frozen 21 November sentence.
Exact logs and candidate assessments are in
`../analysis/novelty_2026-11-25/`.

| Source | Exact query / filter | Hits | Decision |
|---|---|---:|---|
| OpenAlex | `title_and_abstract.search:drought queueing` | 40 | No full four-part match; mostly false positives |
| OpenAlex | `title_and_abstract.search:drought backlog` | 25 | No full four-part match |
| OpenAlex | `title_and_abstract.search:drought "unmet demand"` | 25 | Supply–demand and deficit studies; no queue-state validation |
| OpenAlex | `title_and_abstract.search:drought "first passage"` | 13 | Reservoir/storage first-passage precedents; no learned deficit-queue recovery diagnostic |
| OpenAlex | `title_and_abstract.search:reservoir demand deficit queue` | 0 | No direct record |
| OpenAlex | `title_and_abstract.search:drought storage demand state space` | 42 | **Retained Acosta et al. (2026)** as closest conceptual prior art |
| OpenAlex | `title_and_abstract.search:coupled storage demand drought` | 179 | **Retained Zhao et al. (2018)** as closest non-stationary supply–demand prior art |
| OpenAlex | `title_and_abstract.search:drought "water debt"` | 6 | No stochastic backlog record |
| OpenAlex | `title_and_abstract.search:drought "recovery time" queue` | 0 | No direct record |
| Crossref | Seven bibliographic queries mirroring the above | API returned HTTP 429 | No records exported; limitation recorded |

Two records were inspected beyond title/abstract metadata:

1. **Acosta, G. A. J. G., Colili, J. V. C., Abalus Jr., R. O., & Malolos, J. V.
   (2026). "Toward a Dynamical Network Theory of Drought: Functional Water
   Accessibility in Coupled Human–Water Systems." SSRN preprint,
   DOI 10.2139/ssrn.6835758.** Full 36-page preprint inspected. It proposes a
   coupled state-space framework with storage, accessibility, demand, transfer
   and loss, defines drought intensity as unmet accessible demand, formulates
   probabilistic risk and a recovery timescale, and calls real-world validation
   and observational assimilation future work. It contains no queue-state
   backlog model, learned non-stationary arrival/service rates, exact queue
   benchmarks or empirical validation. **Decision: retain as conceptual prior
   art; not gap-changing.**
2. **Zhao, G., Gao, H., Kao, S.-C., Voisin, N., & Naz, B. S. (2018). "A modeling
   framework for evaluating the drought resilience of a surface water supply
   system under non-stationarity." *Journal of Hydrology*, 563, 22–32,
   DOI 10.1016/j.jhydrol.2018.05.037.** Abstract and accepted-manuscript metadata
   inspected. It integrates hydrological processes and water management to
   evaluate reservoir storage and supply reliability under changing supply and
   demand. It is not a finite-state stochastic deficit queue and does not
   provide exact queue validation. **Decision: retain as supply–demand prior
   art; not gap-changing.**

The frozen sentence is unchanged. The main consequence is narrower wording:
coupled state-space drought modelling and non-stationary supply–demand
modelling are established; the proposed contribution must remain the
queue-specific backlog dynamics, identification, exact validation and
pre-specified drought tests.

## WoS IP-access refresh — 25 November 2026

The institutional WoS session was reopened on 25 November 2026. S1 remained
at 25 records, Extra A at 8, S5 at 66, and S4 increased from 6 to 7. The new S4
record is **Markov Chain-Based Joint Queue-and-Channel-Aware QoS Assurance for
Emergency Networks** (2026), DOI `10.1109/ISWCS69382.2026.11713729`. Its OpenAlex
topics are wireless-network optimisation, traffic/congestion control and
wireless communications. **Decision: drop as irrelevant to drought hydrology;
not gap-changing.** The S1 and S4 refresh exports are preserved in
`../analysis/P01_literature/exports/`.

Scopus was accessed through the institutional browser session, but its current
search UI returned no documents even for the exact known title “Queuing Theory
and Water Storage” and displayed an intermittent-service notice. No new Scopus
screen is claimed; the last complete Scopus screen remains the 295-record
screen of 21 November 2026. Exact queries and counts are in
`../analysis/claim_convention_2026-11-25/wos_refresh_2026-11-25.csv`.

The frozen sentence is unchanged. The numerical claim convention was revised
separately using official Sangli irrigation-area evidence; that revision is an
implementation-scale change, not a literature-gap change. See
`../analysis/claim_convention_2026-11-25/README.md`.

## WoS record-level screen — 21 November 2026

The four pending WoS sets were run with the `TS=(...)` prefix the interface now
requires, and every result set was exported to Excel with abstracts
(`../analysis/P01_literature/exports/wos_extraA_2026-11-21.xls`,
`wos_s4_2026-11-21.xls`, `wos_s5_2026-11-21.xls`, `wos_s5_p2_2026-11-21.xls`,
`wos_extraC_2026-11-21.xls`). All **93 records (S4 = 6, S5 = 66, Extra A = 8,
Extra C = 13) were screened at title/abstract level; zero records retained**.
Per-record decisions and one-line reasons are in
`../analysis/P01_literature/wos_screening_2026-11-21.md` §5. The titles + abstracts +
keywords of all four exports were additionally keyword-scanned for `queue`,
`queing`, `waiting time`, `backlog`, `service rate`, `arrival rate` and
`backlogged`; the only match is the healthcare logistics paper also listed in
Extra C (record 5).

Result: the WoS record-level screen confirms the Scopus finding — no located
study combines drought-as-queue-backlog, queue-state drought indicators,
covariate-learned non-stationary rates and exact validation. Two institutional
echoes are recorded but do not change the gap:

1. Water-rights allocation described as a priority "queuing system" (Extra A:
   the 2006 water-markets review and the 2018 Tunisia allocation study) — an
   institutional rule, not a stochastic queue state with drought indicators.
2. Healthcare emergency-care queueing for capacity (S5 record 50 / Extra C
   record 5) — same service-capacity machinery, applied to patients.

**Database screens are now complete in both WoS (142 records screened:
25 + 24 + 0 + 6 + 66 + 8 + 0 + 13) and Scopus (295 records); 437 records in
total, zero gap-changing findings.**

**Count note (26 November 2026, v2 rebuild).** The frozen sentence quotes 142,
the completed 21 November screen. A 25 November refresh returned one additional
WoS record (143 in the live export); it was screened with the same criteria and
retained nothing, so the gap is unchanged and the frozen sentence remains
verbatim at 142.

**Frozen gap sentence (21 November 2026):** "Within Crossref, OpenAlex, the
complete WoS S1–S5 / Extra A/B/C screens (142 records) and the completed
Scopus S1–S5 / Extra A/C screens (295 records), plus the citation traces, we
found no study that puts all four of these together: (1) drought as an
accumulated unmet-demand backlog with a finite-capacity state; (2) queue-state
indicators reported as drought quantities; (3) non-stationary rates estimated
from hydroclimatic covariates; (4) validation against exact reference
solutions and pre-specified drought tests." Canonical copies: `../AGENTS.md`
§2, `../START_HERE.md` §5, `P01_draft_v2.md` §6.

## WoS/Scopus forward-citation trace — 21 November 2026

The seed list of `search_protocol.md` §2 was traced inside WoS "Times
Cited" and Scopus "Cited by" on 21 November 2026, replacing the OpenAlex
substitute for every seed the databases index. Full seed-by-seed result,
export files and the screening basis are in
`../analysis/P01_literature/citation_trace_2026-11-21.md`. Summary:

- Traced with citing records screened: Gamble 1990a (5, Scopus), Gamble 1990b
  (6, Scopus), Batabyal 1996 (14, Scopus), Harel & Mouche 2013 (5, WoS CC),
  Harel & Mouche 2014 (10, WoS CC), Lefebvre 2019 (1, WoS CC), Yang 2019
  (23, WoS CC), Mouche & Harel 2016 (1, WoS CC), Yang 2016 CSAE (11, Scopus).
- Confirmed not indexed in either subscription database: Langbein 1958 and
  Prajamwong 1997; the OpenAlex trace remains their source.
- **Two new prior-art records** (both added to the table above, both
  found by tracing, neither gap-changing): Yang, Guo, Li & Li (2016) on
  queueing-based conjunctive irrigation allocation, and Jones, Lane &
  Sheridan (2016) extending the queue-based runoff-runon theory to finite
  hillslopes (with the 2019 *J. Applied Probability* descendant).
- **Preservation limitation:** two citing-set exports are absent from the
  current workspace, and the Harel–Mouche 2013/2014 panel-versus-list count
  differences (6 vs 5; 11 vs 10) are unreconciled. The screened lists are
  preserved in the trace note; the missing records were not inspected.
- **No inspected citing record combines drought-as-queue-backlog with
  queue-state indicators, covariate-learned rates and exact validation.** The
  frozen gap sentence is unchanged.

## Non-stationary queueing is mature in operations research

Verified works include Galliher & Wheeler (1958, DOI 10.1287/opre.6.2.264),
Rothkopf & Oren (1979, DOI 10.1287/mnsc.25.6.522), Massey & Whitt (1997,
DOI 10.1023/a:1019156418862), Tan et al. (2013,
DOI 10.1016/j.spa.2013.02.002), Whitt (2018), and — found in the WoS search —
Bogachev et al. (2023, DOI 10.1016/j.physa.2023.128513; 2024,
DOI 10.1016/j.physa.2024.130152) on waiting times with variable,
long-range-correlated arrival rates. **Implication:** do not present
time-varying-rate queueing, or correlated/non-Poisson arrivals, as new.
Defensible novelty is the hydrological parameterisation, the
deficit-accumulation interpretation, and pre-specified drought validation.

**Machine learning for queues is also mature (screened 21 November 2026).**
Verified via OpenAlex DOI lookup: Asanjarani, Nazarathy & Taylor (2021),
*A survey of parameter and state estimation in queues*, Queueing Systems, DOI
10.1007/s11134-021-09688-w (62 citations); Ojeda et al. (2021), *Learning Deep
Generative Models for Queuing Systems*, AAAI, DOI 10.1609/aaai.v35i10.17112;
Dai & Gluzman (2022), *Queueing Network Controls via Deep Reinforcement
Learning*, Stochastic Systems, DOI 10.1287/stsy.2021.0081 (134 citations);
Sherzer et al. (2024), *Approximating G(t)/GI/1 queues with deep learning*,
EJOR, DOI 10.1016/j.ejor.2024.12.030; Chen, Hong & Liu (2026), *Online Learning
and Optimization for Queues with Unknown Arrival Rate and Service
Distribution*, Operations Research, DOI 10.1287/opre.2023.0304; Garyfallos
(2026), doctoral thesis on deep learning for non-Markovian nonstationary
queueing systems, DOI 10.5821/dissertation-2117-457092; Bae & Lee (2026),
contextual queueing bandits, DOI 10.48550/arxiv.2606.09668. **Implication for
P02:** "ML + queues", "learned arrival rates" and "non-stationary queueing" are
all occupied. The contribution must be the hydrological covariates, the
unmet-demand interpretation, exact reference validation and pre-specified
drought-event tests.

**False positive to record.** Hamza, Ouarda, Durrans & Bobée (2001),
*Développement de modèles de queues et d'invariance d'échelle pour l'estimation
régionale des débits d'étiage*, Canadian Journal of Civil Engineering, DOI
10.1139/l00-121, appears in "queue + low flow" searches. Its abstract shows
that *queues* means statistical distribution tails (French *queue de
distribution*), not queueing theory. It is low-flow regional frequency
analysis and must **not** be cited as queueing prior art.

## Verdict on novelty claims

| Roadmap claim | Audit verdict | Action |
|---|---|---|
| "Storage theory was queueing theory" | True and understated — hydrology said so in 1958 | Lead with Langbein |
| "Queueing view of water systems exists only in isolated niches" | Partly true — real but thin niche, now enumerated | Cite it; call it thin, not absent |
| "Service-congestion view of low-flow hydrology: none found" | Still plausible — no drought/low-flow queue-state indicator located | Word as "we found no..." with scope stated |
| Candidate 2 (runoff generation queues) | Rejected as novel — Harel & Mouche 2013 | Reframe as spatial non-stationarity extension |
| Topic 1 irrigation queues | Weakened further — Palková & Hennyeyová 2012; Palková et al. 2010/2011/2012; Yang et al. 2016, 2019 | Gap = unmet-demand indicators + non-stationarity + learned rates |
| Topic 7 groundwater queues | Rejected as novel — Batabyal 1996; Al-Sifao et al. 2026 | Gap = multi-year deficit backlog + GRACE validation |
| Broad coupled drought state-space framework | Already established conceptually — Acosta et al. 2026 preprint | Do not claim the broad framework; distinguish queue dynamics, identification and exact validation |
| Non-stationary supply–demand resilience modelling | Already established — Zhao et al. 2018 | Cite as closest system-modelling precedent |
| ML-parameterised non-stationary queue for drought | No hits in Crossref/OpenAlex, WoS S1–S5/Extra A/B/C (142 records) or Scopus S1–S5/Extra A/C (295 records): 437 records screened in total; plausible gap | Keep as headline, with scope caveat |

## Still required before submission

1. ~~WoS record-level screening of S4 (6), S5 (66), Extra A (8) and Extra C
   (13)~~ **Done 21 November 2026** — 93/93 records exported and screened,
   zero retained (`../analysis/P01_literature/wos_screening_2026-11-21.md`).
2. ~~Forward-citation tracing inside WoS/Scopus ("Times Cited" / "Cited by")
   for the seed list in `search_protocol.md`~~ **Done 21 November
   2026** — all seeds traced or confirmed unindexed; two new prior-art
   records found, neither gap-changing
   (`../analysis/P01_literature/citation_trace_2026-11-21.md`).
3. Known prior-art records have been checked individually; the gap-changing
   retained set is empty. Full-text screening of every hit was never claimed.
4. Supplementary targeted searches for recovery, first passage, state-space and
   identifiability were run on 25 November 2026; see
   `../analysis/novelty_2026-11-25/`. Repeat them immediately before
   submission because the field is moving.
5. The claim-volume convention is revisable and must be replaced by documented
   canal/crop records or covered by a declared sensitivity envelope before
   physical interpretation.
