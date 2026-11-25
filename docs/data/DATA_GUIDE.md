# docs/data/DATA_GUIDE.md — Is my data sufficient? What feeds what, and what is still missing

Companion to `AGENTS.md`. Prepared 21 November 2026 after verifying the
CAMELS-IND publication record (ESSD 2025 / Zenodo v2.2).

---

## 1. The verdict in one table

| Dataset | What it is (verified) | Feeds | Verdict |
|---|---|---|---|
| **CAMELS-IND** (Mangukiya et al. 2025, ESSD 17:461–491; Zenodo 14999580, CC BY 4.0) | 472 Peninsular-India catchments, daily **1980–2020**; 19 forcing variables (rainfall, temperatures, GLEAM PET/AET, soil moisture, radiation, wind, humidity); **211 catchment attributes** incl. **25 anthropogenic**; observed streamflow (242 streamflow-sufficient catchments in v2.2; the ESSD title's 228 refers to v2.1) + LSTM-predicted streamflow for all 472 | **μ(t) service** (observed streamflow → firm supply), demand covariates for **λ(t)**, basin comparison, attribute-conditioned analysis | **Sufficient — the observational backbone of P02.** Exactly the large-sample design the roadmap wanted; better than hand-assembled CWC basins |
| **CMIP6 historical** (24 models, 1981–2014, on disk) + **SSP** (4 scenarios, 14-model hybrid list; 28 model/SSP combos already complete, download continuing) | Daily pr / tasmax / tasmin at catchment scale | **Future forcing** for climate-change non-stationarity: future λ(t) covariates, delta-change scaling for future μ(t) | **Sufficient for the P02 climate angle** — with two gates: bias correction, and the μ(t) construction step (models give weather, not streamflow) |
| **IMD gridded** (1951–2025, daily P, Tmax, Tmin) | The observational reference climate record for India | Bias-correction target; λ(t) covariates; long pre-1980 context | **Sufficient** |

**Bottom line: yes — your three datasets are sufficient for the P02 paper as
designed, and for the P01 illustrations.** The real gaps are not "more
weather data"; they are (a) demand-side records, (b) two data-interpretation
questions, (c) two processing steps you have not built yet.

## 2. The demand side — the one true data gap

Nobody's archive hands you "daily water demand claims". The revisable proxy
convention (45,000 ha; 1 claim = 9×10^6 m³ = 20 mm; K = 20; cap 3
claims/day; firm share 0.5) stands in for it. Three routes to do better, in order:

1. **CAMELS-IND anthropogenic attributes first** (`camels_ind_anth.csv`, 25
   variables). Check for dams (count/capacity upstream), canals, irrigated
   area, population. Whatever is found can replace its assumed counterpart
   *per gauge* — this is the cheapest real-data upgrade available to you.
2. **District agricultural statistics** (cropped area, cropping calendar) —
   from public district-level compilations; replaces the generic Kc curve
   and the 45,000 ha district proxy with gauge-district reality.
3. **If both fail** — the plan's stated fallback: run the pre-registered
   **sensitivity envelope** (repeat the pilot across 45,000 / 174,000 /
   190,000 ha and firm-share 0.3 / 0.5 / 0.7) and keep every result labelled
   illustrative. This is a publishable, honest design; do not treat it as a
   consolation prize.

## 3. Two interpretation questions to close (before P02 results)

| Question | Why it matters | How to close it |
|---|---|---|
| **Gauge 4026 zero-flow days (68%)** | ρ is meaningless on zero-flow days; if the zeros are a fill value, every downstream number changes | Read `CAMELS_IND_Data_Description.pdf` (in the Zenodo record) for zero-discharge semantics; cross-check the LSTM-predicted series on the same days; check upstream Krishna regulation. If fill → impute or switch to 4064 |
| **Regulation status of the pilot gauges** | If flows are dam-released, μ(t) is *managed* supply, and the paper must say so (it changes the interpretation, not the maths) | CWC/India-WRIS basin notes; CAMELS-IND anth attributes (dam counts upstream) |

## 4. Two processing steps to build (CMIP6 gates)

1. **Bias correction** of CMIP6 against IMD (quantile mapping is the
   standard first choice; do it per variable, per catchment, using the
   historical overlap 1981–2014). Gate: corrected model climatology matches
   IMD within stated tolerance before any future rate is computed.
2. **Future μ(t):** models provide weather, not streamflow. Two accepted
   routes — (a) **delta-change**: scale observed CAMELS-IND streamflow by
   monthly model-vs-historical precipitation/ET change factors; or (b) run a
   simple rainfall–runoff model driven by corrected CMIP6. Route (a) is
   simpler and defensible for P02; write the choice down before computing.

## 5. What you do NOT need (and should not chase now)

- **GRACE/GRACE-FO** — only Topic 7 (groundwater, P4, 2029) needs it.
- **More CMIP6 scenarios/models** — 28 complete combinations is already an
  ensemble; wait for the download rather than blocking P02 on it.
- **A Python NetCDF reader** — R (`ncdf4`, `terra`) already reads
  everything; the Python loaders can stay stubs until the package (P5) stage.
- **Canal operations records** — genuinely hard to obtain; the sensitivity
  envelope is the designed answer, not a failure.

## 6. Small corrections to make in the repo's data doc

1. `P01/data_access_spec.md` says "CAMELS-India"; the published name is
   **CAMELS-IND** — use the official name and citation in the README and P01:
   Mangukiya, N. K., Kumar, K. B., Dey, P., Sharma, S., Bejagam, V.,
   Mujumdar, P. P., & Sharma, A. (2025). CAMELS-IND. *Earth System Science
   Data*, 17, 461–491, doi:10.5194/essd-17-461-2025.
2. Note the version nuance once: 472 catchments total; **242**
   streamflow-sufficient in v2.2 (228 in v2.1, which the ESSD title cites).
   Quote the version you actually use.
3. When the zero-flow question is answered, write the answer (with the
   page/section of the PDF that answers it) into `data_access_spec.md` §3 —
   that entry then becomes a `[measurement]` instead of an open question.

## 7. Data → queue mapping (the one diagram, in words)

```
CAMELS-IND forcing CSV (rain, temp, GLEAM PET)  ──►  demand covariates ──► λ(t) [claims/day]
CAMELS-IND observed streamflow (firm share 0.5)  ──►  service capacity  ──► μ(t) [claims/day]
Locked convention (command area, claim volume)   ──►  units for λ, μ, K ──► the queue engine
CMIP6 SSP (bias-corrected) + delta-change        ──►  future λ, μ        ──► future queue states
IMD gridded (1951–2025)                          ──►  bias-correction target, pre-1980 context
```

Every arrow above is a line of `01_build_rates.R` today, except the last two
(bias correction and delta-change), which are the next code to write.
