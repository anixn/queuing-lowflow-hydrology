---
title: "P01 — WoS/Scopus forward-citation trace"
subtitle: "The last Phase A item: Times Cited / Cited by tracing of the seed list"
date: "21 November 2026"
status: "complete — all seeds traced or confirmed unindexed; 2 new prior-art records, 0 gap-changing"
---

# P01 — WoS/Scopus forward-citation trace (21 November 2026)

## 1. Purpose

Complete `../search_protocol.md` §2: trace who cited the seed
papers inside WoS "Times Cited" and Scopus "Cited by", where the OpenAlex
trace of 21 November 2026 (`../literature_audit.md` §3.3) was a
substitute. The four-part gap statement must be checked against every citing
record, not only keyword search hits.

## 2. Method

- **WoS Core Collection:** each seed was located by `DO=<doi>` in the Advanced
  Search Query Builder (or `TI=(...)` for Mouche & Harel 2016); the "In Web of
  Science Core Collection" citing set was opened from the Citation Network
  panel. Two exports are preserved in `exports/`:
  `wos_citing_harel_mouche2013.xls` and `wos_citing_yang2019_p2.xls`. The
  Harel–Mouche 2014 and first Yang-2019 exports are not present in the current
  workspace; those sets were screened on screen and this preservation gap is
  disclosed as a reproducibility limitation.
- **Scopus:** seeds not indexed in WoS CC were located by exact title in the
  basic search box; the "Cited by (n)" tab was read, and for Batabyal 1996 the
  full citing list was opened in "search results format" (page size 200).
  The Scopus Advanced Search textarea again rejected automated input
  (recorded in the run log on 21 November 2026); no export was needed because
  every citing set was read on screen.
- Screening basis: title + abstract + keywords of every citing record,
  keyword-scanned for `queue`, `queuing`, `waiting time`, `drought`,
  `deficit`, `unmet demand`, `backlog`.
- Discrepancy note: WoS citation panels reported one more citing record than
  the exported/screened list for Harel & Mouche 2013 (6 vs 5) and Harel & Mouche
  2014 (11 vs 10). The unresolved count differences are recorded as a limitation;
  the extra records were not inspected, so no duplicate explanation is claimed.

## 3. Seed-by-seed result

| Seed | WoS CC | Scopus | OpenAlex (prior trace) | Citing records screened | Gap-changing records |
|---|---|---|---:|---|---|
| Langbein (1958) | not indexed (pre-1970s ASCE) | not indexed (title + T-A-K searches = 0; the only "water storage + queuing" hit is the web-page-ranking paper from S1) | 70 citing, 64 titles sampled | 0 new | none — OpenAlex trace stands |
| Gamble, Eckstein & Edwards (1990a), *J. Hydrol.* 113, 1–25 | not indexed by DOI or AU/PY | **5 citing** (traced 21 Nov 2026) | 6 citing | 5 | none — transit-time hydrology (Bonell 2010; Howard 2010; Landon 2000; Lindström & Rodhe 1992) + companion 1990b |
| Gamble, Eckstein & Edwards (1990b), *J. Hydrol.* 113, 27–49 | not indexed | **6 citing** | 7 citing | 6 | none — same family (Bonell 2010; Howard 2010; Lentz 2008; Malone 2004; Landon 2000) + companion 1990a |
| Batabyal (1996), groundwater queueing | not indexed | **14 citing** (all 14 viewed in search-results format) | 13 citing | 14 | **one new prior-art record** (Yang 2016 CSAE, below); Al-Sifao et al. 2026 and Yang 2019 already known; remainder is ecology/economics (Batabyal's own line), a tsunami-DART queueing paper, a dictionary entry and a trade-invasions queueing paper |
| Harel & Mouche (2013), runoff queueing, *WRR* | **6 in panel / 5 exported** | — | 7 citing | 5 | **one new lineage record** (Jones, Lane & Sheridan 2016, below); Mouche & Harel 2016 already known; other three are connectivity/field hydrology with no queue content |
| Harel & Mouche (2014), runoff-runon connectivity, *ESPL* | **11 in panel / 10 exported** | — | 16 citing | 10 | none — connectivity literature + the two known records |
| Lefebvre (2019), M/M/1/c high flows | **1 citing** | — | 27 citing | 1 | none — citing record is the NACS 2017 conference introduction (*Atti Accad. Peloritana* 97) |
| Yang, Li & Huo (2019), canal-management queueing | **23 citing** (all 23 exported) | — | — | 23 | none — a sustained canal-operation lineage 2021–2026 (Agricultural Water Management, Irrigation & Drainage, Sci. Rep.): coupled canal/pool regulation and optimal water-distribution models with **no queue-state drought indicators**; one Yangtze waterway navigation queuing paper (2022, *Transportation Research Record* — inland-waterway queueing, known category) |
| Mouche & Harel (2016), B/D/1 overland flow | **1 citing** | — | 13 citing | 1 | none — Boxma & Mandjes (2022), *Queueing Systems* 102(1):69–86: queueing/risk with dependence — OR maturity, not drought |
| Prajamwong, Merkley & Allen (1997) | not indexed | not indexed (TITLE search = 0) | 1 | 0 | none — OpenAlex/Crossref verification stands |

## 4. New prior-art records found by tracing

1. **Yang, Gaiqiang; Guo, Ping; Li, Ruihuan; Li, Mo (2016)**, "Optimal
   allocation model of surface water and groundwater based on queuing theory
   in irrigation district", *Nongye Gongcheng Xuebao / Transactions of the
   Chinese Society of Agricultural Engineering* 32(6), DOI
   10.11975/j.issn.1002-6819.2016.06.016. Cited 11 times in Scopus; its
   descendants (11 records screened) are Chinese irrigation allocation and
   canal-seepage operation models, one of which is Yang 2019. **Consequence:**
   the irrigation-queueing line now includes conjunctive surface/groundwater
   allocation (2016). Still operational allocation, no drought deficit state,
   no learned rates. *(Found 21 November 2026 by Scopus Cited-by tracing of
   Batabyal 1996, not by keyword search.)*
2. **Jones, Owen D.; Lane, Patrick N. J.; Sheridan, Garry J. (2016)**, "The
   stochastic runoff-runon process: Extending its analysis to a finite
   hillslope", *Journal of Hydrology*, DOI 10.1016/j.jhydrol.2016.06.056.
   Extends the Harel–Mouche queue-based runoff-runon theory to finite
   hillslopes with Monte Carlo/asymptotic analysis. Cited 3 times in WoS CC;
   descendants screened: **Jones (2019), "Runoff on rooted trees",
   *Journal of Applied Probability* 56(4):1065–1085** (a further mathematical
   extension — the queue-runoff lineage is still active in probability
   theory), Dai, Qin & Guo (2018) and Chang & Yeh (2018), both *J. Hydrol.*,
   stochastic allocation/runoff papers without queue-state drought
   indicators. *(Found 21 November 2026 by WoS Times-Cited tracing of
   Harel & Mouche 2013.)*

Neither record changes the four-part gap statement; both are added to the
"Verified prior art" table in `../literature_audit.md`.

## 5. Verdict

**Phase A's last screening item is complete.** Every seed has been traced in
every database that indexes it, and every citing record whose title, abstract
or keywords could touch drought, deficit or unmet demand was screened. The
two direct checks in Scopus confirmed negative counts for the two
WoS-unindexed ASCE records (Langbein 1958; Prajamwong 1997). No citing
record anywhere combines drought-as-queue-backlog with queue-state drought
indicators, covariate-learned rates and exact validation. The frozen gap
sentence (`../../../AGENTS.md` §2, frozen 21 November 2026) is unchanged by this
trace.
