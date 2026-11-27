# P1 prior-art screen — 27 November 2026

**Status: COMPLETE (rapid screen; scope-limited, not a WoS/Scopus exhaustive
screen).** This is the Phase-A-style check required by `PIVOT.md` §9 before a
P1 manuscript claims a gap. Script: `R/novelty_p1_screen.R`. Date: 27 November
2026. No year, language or document-type filter. Interfaces: Crossref REST API
(`api.crossref.org/works`, `query.bibliographic`) and OpenAlex REST API
(`api.openalex.org/works`, `search`; forward-citation filter `cites`). Scope:
top 100 relevance-ranked records per database/query and top 100 OpenAlex
citing records per seed by citation count; titles and available abstracts
screened.

## 1. Exact queries and run log

| ID | Database | Exact query | Raw API hits | Retrieved/screened |
|---|---|---|---:|---:|
| P1-S1 | OpenAlex | `(storage deficit OR storage state OR recession OR baseflow) AND (drought forecast OR low flow forecast) AND (India OR large sample OR CAMELS)` | 267,876 | 100 |
| P1-S1 | Crossref | same | 35,445 | 100 |
| P1-S2 | OpenAlex | `catchment memory AND drought AND forecast` | 8,500 | 100 |
| P1-S2 | Crossref | same | 685,235 | 100 |
| P1-S3 | OpenAlex | `(SPEI OR SSI OR flow duration OR Q90) AND (sub-seasonal OR seasonal) AND (forecast OR prediction) AND India` | 43,839 | 100 |
| P1-S3 | Crossref | same | 169,345 | 100 |
| P1-S4 | OpenAlex | `(hydrological drought OR streamflow drought OR low flow) AND India AND (forecast OR prediction)` | 434,046 | 100 |
| P1-S4 | Crossref | same | 4,253,715 | 100 |
| CITES-Sutanto | OpenAlex | forward citations of `10.1038/s41598-022-06553-5` | 97 | 97 |
| CITES-Hammond | OpenAlex | forward citations of `10.3389/frwa.2025.1709138` | 6 | 6 |

P1-S4 was added on 27 November 2026 as a direct India hydrological-forecast
check. P1-S1 to P1-S3 are the `PIVOT.md` §9 strings.

**Aggregate:** 903 retrieved records (OpenAlex 503; Crossref 400), 822 unique
DOI/title records after deduplication. A deterministic title/abstract filter
surfaced 21 candidates; all 21 were manually reviewed. Sixteen were adjacent
prior art; five were irrelevant false matches (three economic-recession
records, one California non-perennial stream-network monitoring record, one
DOC/chemistry record). **Retained gap-changing findings: 0.**

Machine-readable evidence:

- `p1_novelty_screen_2026-11-27.csv` + JSON — query log and hit counts.
- `p1_novelty_records_2026-11-27.csv` + JSON — 822 deduplicated records,
  relevance flags, manual decisions and `gap_changing` field.
- `p1_novelty_summary_2026-11-27.csv` + JSON — aggregate counts.

## 2. Manual decisions on the 21 candidates

### Adjacent prior art (16; none contains all P1 criteria)

| DOI | Study | Why it does not close the gap |
|---|---|---|
| 10.5194/hess-21-707-2017 | Shah et al. (2017), short/sub-seasonal hydrologic forecasts in India | India and forecasting, but VIC/meteorological-ensemble forecasts at 7–45 days; no recession-derived storage feature, memory-baseline contrast, mass-balance-verified state or pre-registered H1/H2. |
| 10.1029/2021jd035737 | Sub-seasonal prediction of drought and streamflow anomalies in India (2022) | India and streamflow forecasting, but SubX/ERFS + VIC at 1–30 days and five reservoir basins; no storage-feature benchmark at 1/3/6 months. |
| 10.1175/jhm-d-20-0235.1 | Bias correction and hydrological prediction in India (2021) | VIC/bias-correction forecast in the Narmada basin at 1–3 days; no seasonal storage-feature test. |
| 10.1175/jhm-d-15-0050.1 | GEFS reforecast for medium-range drought prediction in India (2016) | India and drought prediction, but medium-range meteorological/hydrologic forecasting; no storage state. |
| 10.1002/clen.202300430 | Deep-learning hydrological drought prediction in Wardha, India (2025) | India, SSI and 6/12-month leads, but one basin, LSTM/MLP with lagged SSI; no recession-derived storage, pre-specified memory-baseline contrast or verified fluid state. |
| 10.54302/mausam.v31i1.4279 | Sacramento model on an Indian catchment (1980) | Single-catchment conceptual runoff modelling; no probabilistic drought benchmark. |
| 10.5194/egusphere-egu2020-10208 | Drought propagation in major Indian basins (2020) | 224 stations and drought propagation/run theory; not a storage-feature forecasting test. |
| 10.1038/s41598-022-06553-5 | Sutanto & Van Lanen (2022), catchment memory and forecast skill | Europe; BFI and groundwater recession coefficient correlated with forecast skill. It motivates the memory mechanism but does not evaluate an Indian recession-derived storage state as a feature against memory baselines. |
| 10.5194/egusphere-egu26-9100 | Global baseflow recession timescales (2026) | Large-sample recession-process analysis; no forecasting. |
| 10.5194/egusphere-egu2020-5509 | CAMELS-GB baseflow controls (2020) | Baseflow/BFI controls in Great Britain; no forecasting. |
| 10.1002/hyp.70106 | Dynamic baseflow storage in Neversink, USA (2025) | Recession-derived storage estimates in seven US catchments; process study, no forecasting contrast. |
| 10.5194/hess-2019-590 | GRACE water-storage deficit and drought recovery (2019) | GRACE storage deficit and recovery-time estimation; not an Indian catchment index-forecast benchmark. |
| 10.1016/j.scitotenv.2020.141220 | Aquifer eigenmodels during flow recession (2020) | Aquifer-level groundwater forecasting; no India large-sample hydrological-index contrast. |
| 10.5194/hess-2019-311 | Catchment-scale drought indicators in Australia (2019) | Multiple-indicator drought propagation in one catchment; no seasonal forecasting comparison. |
| 10.5194/hess-2018-248 | Groundwater-baseflow drought in 338 German catchments (2018) | Baseflow-drought trends/projections; not probabilistic index forecasting with recession-state features. |
| 10.5194/egusphere-2026-5964 | Drought-propagation modes across US catchments (2026) | CAMELS-US propagation/methodological uncertainty; not India and not a storage-feature forecast test. |

### Irrelevant false matches (5)

- 10.2139/ssrn.1138371 — economic recession forecast.
- 10.20955/es.2018.30 — yield curve/economic recession.
- 10.2139/ssrn.3422278 — business-cycle/economic recession.
- 10.1002/hyp.70413 — California non-perennial stream-network monitoring; no forecasting.
- 10.5194/hess-2021-89 — dissolved-organic-carbon study; no drought forecast benchmark.

## 3. Targeted web cross-check (27 November 2026)

A targeted web search using the P1 concepts returned and confirmed additional
adjacent studies outside the API candidate set: García-Gamero et al. (2026),
global CEMS seasonal hydrological-drought forecasts; Sutanto et al. (2020),
large-scale seasonal drought-impact forecasts; and Sutanto and Van Lanen
(2021), streamflow-drought definitions and forecasting. These are global or
European benchmark studies, not Indian recession-state feature tests, and do
not change the decision. Shah et al. (2017) and the India SubX/ERFS and Wardha
studies were already among the 21 API candidates.

## 4. Frozen P1 novelty sentence (Sentence B)

> "Within rapid Crossref and OpenAlex title/abstract screens run on
> 27 November 2026 (four PIVOT queries and two OpenAlex forward-citation
> traces; 903 relevance-ranked records retrieved, 822 deduplicated records
> screened, 21 candidates manually reviewed; 103 citing records included),
> we found no large-sample study for Indian catchments that evaluates
> recession-derived storage-deficit states as forecasting features for
> hydrological drought and low-flow events at 1-, 3-, and 6-month leads
> against pre-specified memory baselines, with mass-balance-verified state
> estimation and pre-registered confirmatory tests."

**Scope note (binding).** This sentence says *within these screens*, not
*no such study exists*. The P1 search was deliberately rapid and used
Crossref/OpenAlex rather than the complete WoS/Scopus record-level protocol
used for Sentence A. No stronger claim is permitted without an exhaustive
WoS/Scopus follow-up. The screen supports finalising the current P1 title and
the scoped benchmark statement in the manuscript; it does not turn the
negative confirmatory result into a positive storage-state claim.

## 4. Manuscript consequence

- Finalise the P1 title: the paper is a **large-sample test plus lead-time
  skill benchmark**, not a claim that storage states add seasonal skill.
- Replace the stale "novelty screen still needed" note in `paper01/README.md`
  with the completed screen scope and evidence path.
- Cite the adjacent studies where their mechanisms are discussed (Shah et
  al., 2017; Sutanto & Van Lanen, 2022; the India SubX/ERFS study; the Wardha
  LSTM study) rather than claiming their questions are absent.
