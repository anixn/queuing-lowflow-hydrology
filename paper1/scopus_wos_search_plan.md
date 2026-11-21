# Scopus / Web of Science search plan — P1 prior-art completion

Prepared 21 November 2026. Web of Science was run on 20–21 November 2026;
Scopus was run on 21 November 2026 through the institutional IP address (no
login needed). WoS export files are still needed for the four searches whose
record cards would not render (see run log). Results are screened directly in
`literature_audit.md`; only a gap-changing finding triggers an edit to
`P1_draft_v2.md`.

## 1. Exact strings

### Scopus (Advanced Search syntax)

```
S1  TITLE-ABS-KEY ( ( queue* OR "queuing theory" OR "queueing theory" OR "mass service" ) AND ( drought OR "low flow" OR "water storage" OR "unmet demand" OR "water deficit" ) )

S2  TITLE-ABS-KEY ( ( "queue* theory" OR "queuing theory" OR "queueing theory" ) AND ( hydrolog* OR "water resource*" OR river* OR reservoir* OR irrigation OR groundwater ) )

S3  TITLE-ABS-KEY ( drought AND ( "recovery time" OR "first passage" OR "busy period" OR "return period" ) AND ( queue* OR congestion OR backlog ) )

S4  TITLE-ABS-KEY ( ( "non-stationary" OR nonstationary OR "time-varying" ) AND queue* AND ( hydrolog* OR drought OR water OR irrigation ) )

S5  TITLE-ABS-KEY ( ( "unmet demand" OR "deficit accumulation" OR "demand backlog" ) AND ( drought OR irrigation OR "water supply" ) )
```

### Web of Science (Core Collection, Advanced Search syntax)

```
S1  TS=( ( queue* OR "queuing theory" OR "queueing theory" OR "mass service" ) AND ( drought OR "low flow" OR "water storage" OR "unmet demand" OR "water deficit" ) )

S2  TS=( ( "queue* theory" OR "queuing theory" OR "queueing theory" ) AND ( hydrolog* OR "water resource*" OR river* OR reservoir* OR irrigation OR groundwater ) )

S3  TS=( drought AND ( "recovery time" OR "first passage" OR "busy period" ) AND ( queue* OR congestion OR backlog ) )

S4  TS=( ( "non-stationary" OR nonstationary OR "time-varying" ) AND queue* AND ( hydrolog* OR drought OR water OR irrigation ) )

S5  TS=( ( "unmet demand" OR "deficit accumulation" OR "demand backlog" ) AND ( drought OR irrigation OR "water supply" ) )
```

Notes: use `queue*` to catch queue/queues/queued/queuing; keep both spellings
(queueing, queuing). Do not add a language or year restriction on S1–S3.

**Web of Science interface correction (20 November 2026).** In the current WoS
"Advanced search" / Fielded Search UI the Topic field rejects the `TS=(...)`
prefix ("Invalid query"). Paste the **bare Boolean expression** inside the
parentheses instead. Verified works: S1 = 25 hits, S2 = 24 hits.

**Web of Science interface change (21 November 2026).** The Advanced Search
**Query Builder** textarea now accepts and requires the `TS=(...)` prefix; the
bare Boolean string returns "Search Error: Invalid field tag". All S4/S5/Extra
A/C runs on 21 November 2026 used `TS=(<bare Boolean>)`.

**Scopus interface note (21 November 2026).** Access works from the
institutional IP address without signing in (the header still shows "Sign in").
The **basic** search box on the Documents tab accepts a bare Boolean expression
and automatically wraps it in `TITLE-ABS-KEY ( ... )`. Do **not** type the field
code yourself: Scopus then wraps it a second time and returns zero hits. The
Advanced Search textarea did not accept automated input reliably, so all
searches below were run through the basic box with the bare text shown in the
run log. To display every record, set the **second** `<select>` on the results
page (page size) to `200`. Organization discovery lists "Pandit Deendayal
Energy University" (the renamed PDPU).

**Scopus S3 deviation.** As run, Scopus S3 omitted the plan's `OR "return
period"` clause, so that it matched the WoS S3 string exactly. The complete-null
result therefore applies to the narrower string.

## Run log

| Date | Database | String | Hits | Screened | Retained | Status |
|---|---|---|---:|---:|---:|---|
| 20 Nov 2026 | WoS Core Collection | S1 | 25 | 25 | 0 | Done — no relevant prior art |
| 20 Nov 2026 | WoS Core Collection | S2 | 24 | 24 | 4 | Done — Yang 2019; Palková et al. 2010/2011/2012; Harel & Mouche 2014; Bogachev 2023/2024 for P3 |
| 21 Nov 2026 | WoS Core Collection | S3 | 0 | — | 0 | Done — complete null |
| 21 Nov 2026 | WoS Core Collection | S4 | 6 | 6 | 0 | Done 21 Nov 2026 — exported to Excel with abstracts; all telecom/OR, Bogachev 2024 already recorded |
| 21 Nov 2026 | WoS Core Collection | S5 | 66 | 66 | 0 | Done 21 Nov 2026 — exported to Excel with abstracts (2 pages); WEAP-type deficit modelling, no queueing |
| 21 Nov 2026 | WoS Core Collection | Extra A: `TS=(drought AND (queue* OR queu*))` | 8 | 8 | 0 | Done 21 Nov 2026 — exported; 2 institutional "queuing system" echoes (water rights), no gap change |
| 21 Nov 2026 | WoS Core Collection | Extra B: drought + first passage/busy period + reservoir/storage/deficit | 0 | — | 0 | Done — complete null |
| 21 Nov 2026 | WoS Core Collection | Extra C: `TS=(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 13 | 13 | 0 | Done 21 Nov 2026 — exported; production-inventory, healthcare, EV/transport queueing only |
| 21 Nov 2026 | OpenAlex | Forward-citation trace of 7 seed DOIs | 70 + 6 + 13 + 7 + 16 + 27 + 1 citing records | titles screened | 2 new prior art | Done — Mouche & Harel 2016; Yang 2019 descendant; no drought-backlog study |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | S1 | 38 | 38 | 0 | Done — no relevant prior art |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | S2 | 116 | 116 | 0 | Done — known hydrology-queue lines only; no gap-changing record |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | S3 | 0 | — | 0 | Done — complete null |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | S4 | 11 | 11 | 0 | Done — no gap-changing record |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | S5 | 98 | 98 | 0 | Done — no gap-changing record |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | Extra A: `drought AND (queue* OR queu*)` | 15 | 15 | 0 | Done — no gap-changing record |
| 21 Nov 2026 | Scopus (basic box, bare Boolean) | Extra C: `("water deficit" OR "unmet demand") AND (queue* OR queu*)` | 17 | 17 | 0 | Done — no gap-changing record |
| — | WoS Core Collection | Remaining forward-citation seeds | — | — | — | Pending |
| — | Scopus | Forward-citation tracing ("Cited by") | — | — | — | Pending — OpenAlex substitute used |

"Retained" means a new record that could change the gap statement. Known prior
art surfaced again in Scopus S2/S4/S5/Extra A/C (including Prajamwong et al.
1997); it is already in `literature_audit.md` and does not change the gap.

## 1b. Scopus screening summary (21 November 2026)
All seven Scopus searches were run with the bare Boolean strings and every
returned record was screened at title level (page size 200): 38 + 116 + 0 + 11
+ 98 + 15 + 17 = **295 records, zero gap-changing findings**. The hits echoed
the WoS results — telecom, transport and data-network queueing, operational
irrigation/water-supply queueing, and false matches where "deficit" or "low
flow" was unrelated to scarcity. Records from our already-known prior-art lines
(Yang 2019; Palková et al.; Prajamwong 1997; runoff/water-storage queueing)
appeared again, which is a useful cross-database check, but no study combined
drought-as-queue-backlog with covariate-learned rates and pre-specified
validation.

The two decisive direct tests are now complete in **both** databases: WoS
returned 8 (Extra A) and 13 (Extra C) hits but would not render the records;
Scopus returned 15 and 17 and they were fully screened. The Scopus results
therefore partly cover the WoS screening gap, but the WoS record-level screen
remains a separate, still-open task because the two databases do not index
identical records.

## 1c. WoS record-level screening summary (21 November 2026)

The record-card renderer stall was bypassed by exporting each result set with
WoS "Export → Excel" (Author, Title, Source, Abstract), without profile
sign-in. **All 93 WoS records were screened (S4 = 6, S5 = 66, Extra A = 8,
Extra C = 13); zero retained.** The per-record table lives in
`../analysis/P01/wos_screening_2026-11-21.md` §5 and the summary in
`literature_audit.md` ("WoS record-level screen"). With this, both databases
are fully screened at record level: **142 WoS + 295 Scopus = 437 records,
zero gap-changing findings**. The dated gap sentence is frozen in
`../field/README.md` §8. The still-open Phase A item is forward-citation
tracing inside WoS/Scopus (§2 below); the OpenAlex trace remains a substitute.

## 2. Forward-citation tracing

In WoS "Times Cited" / Scopus "Cited by", trace these five seeds and export the
citing articles:

| Seed | DOI | Why |
|---|---|---|
| Langbein (1958), "Queuing Theory and Water Storage" | 10.1061/JYCEAJ.0000222 | Founding hydrology record; who carried it forward? |
| Gamble, Eckstein & Edwards (1990a) | 10.1016/0022-1694(90)90164-S | Storage-as-queue in soil water |
| Batabyal (1996), groundwater queueing | 10.1016/0304-3800(94)00178-2 | Kills groundwater novelty claim; check descendants |
| Harel & Mouche (2013), runoff queueing | 10.1002/2013WR013596 | Kills runoff novelty claim |
| Lefebvre (2019), M/M/1/c high flows | 10.1478/aapp.97s2a18 | Closest methodological precedent |

For each seed record: number of citing articles, number that are hydrology/
water/resources, and any that mention drought, deficit or unmet demand.

## 3. What to record (for the methods section)

For every search, record:
- database and interface version
- exact string as run
- date run
- filters applied (years, document types, languages)
- raw hit count
- number of titles/abstracts screened
- number retained for full text
- reason for each exclusion of a seemingly relevant record

We will report this as a scoping review, not a systematic review, unless all
screens are completed — keep that wording in the manuscript.

## 4. Decision rule for updating the paper

- If a located study treats drought as an accumulated unmet-demand backlog with
  queue-state indicators, the "no located study" gap statement must be narrowed
  or removed.
- If a located study learns non-stationary λ(t), μ(t) from hydroclimatic
  covariates for drought, the P3 headline novelty must be narrowed.
- If nothing new appears, add one sentence to `literature_audit.md` recording
  the completed database search and keep `P1_draft_v2.md` unchanged.
