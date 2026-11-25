# P02 data requirements — what is needed and when

Date: 25 November 2026. This separates data needed to start method development from data needed for final physical or operational claims.

## 1. Enough to start now

| Dataset | Status | Use |
|---|---|---|
| CAMELS-IND forcings | Have: 472 daily catchment CSVs | Historical climate, PET and soil-moisture covariates |
| CAMELS-IND observed/LSTM streamflow | Have: 2 daily files | Observed μ reconstruction and LSTM comparator |
| CAMELS-IND attributes | Have: 8 CSVs | Area, dams, irrigation fraction, crop fraction, soils, geology and catchment controls |
| CAMELS-IND data description | Have: PDF | Variable definitions and provenance |
| IMD gridded P/Tmax/Tmin | Have: 75 files per variable | Observational climate reference |
| CAMELS-IND-Proj streamflow | Have: 65 model/scenario files; gauge 4026 complete | Primary future μ ensemble |
| Raw CMIP6 historical/SSP | Have | Fallback/sensitivity forcing |

No new download is required to begin solver, synthetic identification, hurdle-model and historical reconstruction work.

## 2. Required before real-data validation

### 2.1 Crop area and calendar

Needed fields:

```text
year, district, crop, area_ha, sowing_doy, harvest_doy
```

Purpose: replace the generic Kc curve and the 45,000 ha district proxy with a crop-mix demand model. Possible sources: district agricultural statistics, state agriculture departments, ICAR crop calendars and India-WRIS/CWC command-area records.

Status: not found locally. This is the most important missing demand-side dataset.

### 2.2 Drought-event and baseline product

Use **Drought Intelligence Explorer v2**, Zenodo DOI `10.5281/zenodo.24444860`, which provides district SPI, SPEI, soil-moisture anomaly, VCI, an IMD benchmark and CMIP6 projections for 724 districts. It is available as a 39.4 MB software/data ZIP but is not yet local.

Use it for:

- SPI/SPEI and vegetation/soil-moisture baselines;
- named drought-event context;
- district-scale validation and cross-checks.

SSI can be computed from CAMELS-IND streamflow if not included.

### 2.3 Zero-flow semantics

The CAMELS-IND description defines `q_zero` but does not establish whether gauge 4026's zeros are true intermittency, regulation or a fill convention. Required action: check India-WRIS/CWC metadata and, if needed, ask the dataset authors. Do not interpret ρ or fit a zero-inflated supply model until this is resolved.

### 2.4 Regulation and release metadata

CAMELS-IND attributes already show substantial dam presence:

- gauge 4026: 86 dams in `num_dams`, total storage about 6.26×10⁹ m³, irrigation fraction 0.867;
- gauge 4064: 271 dams, total storage about 1.51×10¹⁰ m³, irrigation fraction 0.927.

These are useful covariates, but not operating records. For operational μ claims, obtain release/diversion/canal-delivery data or state explicitly that μ is managed/natural supply inferred from streamflow.

### 2.5 CAMELS-IND-Proj provenance and historical skill

Before future use, obtain or document:

- the upstream LSTM training/validation split and model configuration;
- compatibility of the projected streamflow with the observed gauge record;
- historical performance for seasonal volume, zero occurrence, low-flow duration and extremes.

The forcing is described as bias-corrected, so do not bias-correct it a second time. Future PET0/crop demand can be derived from temperature with a documented Hargreaves/FAO-56 method; PET0 is not supplied as a separate Proj variable.

## 3. Required only for stronger attribution or decision claims

| Dataset | Why needed | Priority |
|---|---|---|
| Reservoir/canal release and delivery records | Identify served water and demand-versus-supply interventions | High for attribution, optional for initial methods |
| Reservoir levels, soil moisture or groundwater observations | Independent state constraint and data assimilation | High for identification claims |
| Crop loss, irrigation failure or restriction records | Impact validation and decision-value analysis | Medium |
| GRACE/GRACE-FO TWSA | Groundwater-storage validation | Optional; not needed for first P02 |
| Actual command-area boundaries | Replace district proxy with gauge/system-specific area | High for physical deployment |

If these are unavailable, the paper must report the resulting non-identifiability or proxy limitation rather than imply measured attribution.

## 4. Not required

- More CMIP6 models before method development: CAMELS-IND-Proj already provides 13 models × four SSPs.
- A Python NetCDF reader: R `ncdf4`/`terra` is available; projected streamflow is already CSV.
- GRACE for the first P02: only needed for the groundwater-storage extension.
- Deep learning for its own sake: the current data support transparent process and small constrained models first.

## 5. Acquisition order

1. Download Drought Intelligence Explorer v2 from Zenodo.
2. Obtain district crop area/calendar for Sangli and Yadgir districts.
3. Resolve zero-flow and regulation semantics for gauges 4026/4064.
4. Document CAMELS-IND-Proj LSTM provenance and historical skill; recover its bias-corrected forcing for the two gauges, otherwise bias-correct raw CMIP6 against IMD.
5. Seek canal/release/storage observations only if the identification or decision-value claims require them.
