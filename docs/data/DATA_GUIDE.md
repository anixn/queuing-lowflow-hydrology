# docs/data/DATA_GUIDE.md — Is my data sufficient? What feeds what, and what is still missing

Companion to `AGENTS.md`. Prepared 21 November 2026 after verifying the
CAMELS-IND publication record (ESSD 2025 / Zenodo v2.2).

---

## 1. The verdict in one table

| Dataset | What it is (verified) | Feeds | Verdict |
|---|---|---|---|
| **CAMELS-IND** (Mangukiya et al. 2025, ESSD 17:461–491; Zenodo 14999580, CC BY 4.0) | 472 Peninsular-India catchments, daily **1980–2020**; 19 forcing variables (rainfall, temperatures, GLEAM PET/AET, soil moisture, radiation, wind, humidity); **211 catchment attributes** incl. **25 anthropogenic**; observed streamflow (242 streamflow-sufficient catchments in v2.2; the ESSD title's 228 refers to v2.1) + LSTM-predicted streamflow for all 472 | **μ(t) service** (observed streamflow → firm supply), demand covariates for **λ(t)**, basin comparison, attribute-conditioned analysis | **Sufficient — the observational backbone of P02.** Exactly the large-sample design the roadmap wanted; better than hand-assembled CWC basins |
| **CMIP6 historical** (24 models, 1981–2014, on disk) + **SSP** (four scenarios, raw forcing present) | Daily pr / tasmax / tasmin | Fallback/sensitivity future forcing | Present; bias correction required before published use |
| **CAMELS-IND-Proj** | 13 CMIP6 models × historical + four SSPs; daily projected streamflow 1980–2100; bias-corrected forcing archive | **Primary conditional future μ(t) ensemble** and preferred future λ(t) forcing | Present; gauge 4026 complete in all 65 streamflow files; historical/provenance validation required; no double bias correction |
| **IMD gridded** (1951–2025, daily P, Tmax, Tmin) | The observational reference climate record for India | Bias-correction target; λ(t) covariates; long pre-1980 context | **Sufficient** |

**Bottom line: yes — the local observational and projected datasets are sufficient
to start P02 method development.** The real gaps are not "more
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
| **Regulation status of the pilot gauges** | If flows are dam-released, μ(t) is *managed* supply, and the paper must say so | CAMELS-IND already shows 86 dams at 4026 and 271 at 4064; obtain CWC/India-WRIS release/diversion records for operating rules |

## 4. Future-data gates

1. **Validate CAMELS-IND-Proj historical streamflow** against observed and
   CAMELS-IND LSTM flow over 1980–2014 before using its 2015–2100 ensemble.
2. **Recover the CAMELS-IND-Proj forcing subset** for gauges 4026/4064. Its
   description says the forcing is bias-corrected; standard archive extraction
   failed locally. If recovery fails, bias-correct raw SSP forcing against IMD.
3. **Future μ(t):** use CAMELS-IND-Proj projected streamflow as the primary
   scenario input. Raw CMIP6 remains pipeline-check-only; any bias-corrected
   delta-change comparison is a secondary methodological check.

## 5. What you do NOT need (and should not chase now)

- **GRACE/GRACE-FO** — only the later groundwater-storage extension needs it.
- **More CMIP6 scenarios/models** — CAMELS-IND-Proj already provides 13 models
  and four SSPs; do not block P02 on downloading more.
- **A Python NetCDF reader** — R (`ncdf4`, `terra`) is available for raw forcing.
- **Canal operations records** — not required to start, but required for strong
  operational or demand-versus-supply attribution claims.

## 6. Data documentation rules

1. Use the official name **CAMELS-IND** and cite Mangukiya et al. (2025),
   *Earth System Science Data*, 17, 461–491, doi:10.5194/essd-17-461-2025.
2. State the version: 472 catchments total and 242 streamflow-sufficient in
   v2.2; the ESSD title's 228 refers to v2.1.
3. When zero-flow semantics are resolved, record the evidence in
   `P01/data_access_spec.md` §3 and change the entry from unknown to measurement.

## 7. Data → queue mapping (the one diagram, in words)

```
CAMELS-IND forcing + crop calendar          ──►  process demand ──► λ(t) [claims/day]
CAMELS-IND observed streamflow + firm share  ──►  service capacity ──► μ(t) [claims/day]
Revisable convention (area, claim volume)   ──►  units for λ, μ, K ──► the queue engine
CAMELS-IND-Proj streamflow ensemble          ──►  conditional future μ(t)
CAMELS-IND-Proj/raw SSP forcing + PET0        ──►  future λ(t)
IMD gridded (1951–2025)                       ──►  observational/bias-correction reference
```

This is the target data-flow design. Historical reconstruction exists; future
queue products remain gated by CAMELS-IND-Proj historical/provenance validation.
