# Literature audit for Paper 1 — 20–21 November 2026

## Protocol

The built-in web-search tool returned no results for any query in this session.
Verification was therefore done through two bibliographic APIs:

* **Crossref REST** (`api.crossref.org/works`), bibliographic and DOI lookups.
* **OpenAlex** (`api.openalex.org/works`), `title.search`, `abstract.search`,
  `fulltext.search` and DOI lookups. Free-tier shared budget; no API key used.

Searches were run on 20–21 November 2026. Web of Science Core Collection was
searched on 20–21 November 2026 and Scopus on 21 November 2026 (institutional
IP, no login; see below). This is a **scoping audit**, not a systematic review:
forward-citation tracing was done through OpenAlex rather than the database
"Cited by" tools, and there has been no full-text screening of all hits. Four
WoS record-level screens are also still open. Those steps are required before
submission.

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
expression must be pasted instead. The strings in `scopus_wos_search_plan.md`
should be used without `TS=` in this interface.

| # | Query as run (Topic field) | Hits | Titles/abstracts screened | Retained for full text |
|---|---|---:|---:|---:|
| S1 | `((queue* OR "queuing theory" OR "queueing theory" OR "mass service") AND (drought OR "low flow" OR "water storage" OR "unmet demand" OR "water deficit"))` | 25 | 25 | 0 |
| S2 | `(("queuing theory" OR "queueing theory" OR "mass service") AND (hydrolog* OR "water resource*" OR river* OR reservoir* OR irrigation OR groundwater))` | 24 | 24 | 4 |
| S3 | `(drought AND ("recovery time" OR "first passage" OR "busy period") AND (queue* OR congestion OR backlog))` | 0 | — | 0 |
| S4 | `(("non-stationary" OR nonstationary OR "time-varying") AND queue* AND (hydrolog* OR drought OR water OR irrigation))` | 6 | hit count only — renderer stalled | pending |
| S5 | `(("unmet demand" OR "deficit accumulation" OR "demand backlog") AND (drought OR irrigation OR "water supply"))` | 66 | hit count only — renderer stalled | pending |
| Extra A | `(drought AND (queue* OR queu*))` | 8 | hit count only — renderer stalled | pending — **highest priority** |
| Extra B | `(drought AND ("first passage" OR "busy period") AND (reservoir* OR storage OR deficit))` | 0 | — | 0 |
| Extra C | `(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 13 | hit count only — renderer stalled | pending — **highest priority** |

**Record-level screening limitation (21 November 2026).** For S4, S5 and Extra
A/C the WoS results page returned hit counts but the record cards never left
the `loading-cover` state (cookie consent, page-size change, sort change and
reload were all tried). OpenAlex title/abstract cross-checks were substituted
but are not equivalent. These four sets must be exported or re-screened before
the gap statement is frozen. This limitation is recorded in
`NOVELTY_AND_PLAN_REPORT.md` §3.2.

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
queues with variable, long-range-correlated arrival rates — relevant to P3's
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

The two decisive direct tests (Extra A and Extra C) are now fully screened in
Scopus at 15 and 17 records. This partly offsets the WoS renderer failure,
though the WoS record-level screen remains open because the two databases do
not index identical sets.

## Verified prior art that changes the framing

| Work | Record | What it does | Consequence for P1 |
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
| **Prajamwong, Merkley & Allen (1997)**, "Decision Support Model for Irrigation Water Management", *J. Irrigation and Drainage Engineering* 123(2), 106, DOI 10.1061/(ASCE)0733-9437(1997)123:2(106) | OpenAlex `abstract.search:water deficit + queue` screen, 21 Nov 2026 | CADSM uses a queuing system to allocate available water to command areas and fields; root-zone water deficit in yield response | **New.** Pushes irrigation-queueing precedent back to 1997. Operational allocation, not drought state or learned rates. |

Full bibliographic detail for all resolved records is in `P1_draft_v2.md` References.

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
P3:** "ML + queues", "learned arrival rates" and "non-stationary queueing" are
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
| Topic 1 irrigation queues | Weakened further — Palková & Hennyeyová 2012; Palková et al. 2010/2011/2012; Yang et al. 2019 | Gap = unmet-demand indicators + non-stationarity + learned rates |
| Topic 7 groundwater queues | Rejected as novel — Batabyal 1996; Al-Sifao et al. 2026 | Gap = multi-year deficit backlog + GRACE validation |
| ML-parameterised non-stationary queue for drought | No hits in Crossref/OpenAlex, WoS S1–S3 or Scopus S1–S5/Extra A/C (295 records screened); plausible gap | Keep as headline, with scope caveat |

## Still required before submission

1. WoS record-level screening of S4 (6), S5 (66), Extra A (8) and Extra C (13);
   export the records or reopen in a session where the cards render. The
   Scopus equivalents are complete, but WoS indexes different records.
2. Forward-citation tracing inside WoS/Scopus ("Times Cited" / "Cited by") for
   the seed list in `scopus_wos_search_plan.md`. The OpenAlex trace is a
   substitute, not an equivalent.
3. Full-text screen of the retained prior-art set (not every hit).
4. Targeted search for "recovery time", "first passage" and "busy period" in
   hydrological drought (S3 returned zero in both WoS and Scopus).
5. Decision on claim-volume convention (one claim/event per day vs per
   irrigation event) — affects every rate interpretation.
