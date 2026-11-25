# Input/output specification — data contracts and queue pipeline

Companion to `AGENTS.md` and `DATA_GUIDE.md`. Prepared 21 November 2026; housekeeping revision 25 November 2026.

## 0. Pipeline

```text
CAMELS-IND forcings + streamflow
    -> daily lambda(t), mu(t)
    -> src/shared/queue_core.py
    -> backlog, severe-state probability, served/abandoned demand and recovery
    -> P02 held-out validation and, after historical validation, CAMELS-IND-Proj future scenarios
```

## 1. Input inventory

| Input | Contract | Role | Status |
|---|---|---|---|
| CAMELS-IND catchment forcings | Daily 1980–2020; rainfall, temperature, PET and soil-moisture covariates | Demand covariates and data-quality checks | Available locally |
| CAMELS-IND observed streamflow | Daily m³/s; gauge-ID headers preserved | Service-rate construction | Available; zero-flow semantics unresolved |
| CAMELS-IND LSTM streamflow | Daily predicted flow for all catchments | Zero-flow cross-check and ungauged-basin comparison | Available |
| CAMELS-IND attributes | 211 attributes, including 25 anthropogenic variables | Cross-basin explanation and convention replacement | Available |
| IMD gridded climate | Daily P, Tmax, Tmin, 1951–2025 | Observational reference and CMIP6 bias-correction target | Available |
| CMIP6 historical/SSP | Daily pr, tasmax, tasmin | Fallback/sensitivity future covariates | Available; bias correction not implemented |
| CAMELS-IND-Proj | 13 models × historical + four SSPs; daily projected streamflow 1980–2100 | Primary conditional future μ ensemble and preferred future λ forcing | Streamflow CSV complete for gauge 4026; forcing recovery, LSTM provenance and historical validation pending; no double bias correction |

Pilot gauge: **4026 Kurundwad**. Second planned gauge: **4064 Yadgir**.

## 2. Locked provisional convention

`[assumption, not measurement]`

- Command area: 45,000 ha, the Sangli district canal-irrigated proxy.
- One claim: 9×10⁶ m³ = 20 mm over the proxy command.
- Backlog tolerance: 20 claims = 400 mm.
- Service cap: 3 claims/day = 60 mm/day = 2.7×10⁷ m³/day.
- Firm-supply share: 0.5.
- Effective-rain fraction: 0.7.
- Kharif sowing day: 200; season length: 120 days; peak Kc: 1.2.

The 45,000 ha value comes from the official Sangli agriculture contingency
plan; it is a district proxy, not a gauge-specific command measurement. Source
and envelope: `../../analysis/claim_convention_2026-11-25/`.

The convention is defined in `P02/R/01_build_rates.R` BLOCK 1 and `src/P01/data_pipeline.py`. Replace it with measured canal/crop records or run a documented sensitivity envelope before physical interpretation.

## 3. Rate construction

Supply:

```text
observed flow [m³/s] x 86,400 [s/day] x firm share / claim volume [m³]
    -> mu(t) [claims/day], capped at the service ceiling
```

Demand:

```text
PET [mm/day] x Kc x command area [ha] x effective fraction
    -> crop water requirement [m³/day] / claim volume [m³]
    -> lambda(t) [claims/day]
```

Missing streamflow days are linearly interpolated and flagged with `q_imputed=TRUE`. Zero-flow days are not interpreted until the CAMELS-IND documentation question is resolved.

## 4. Generated rate file

`P02/data/generated/rates_4026.csv` is produced by `P02/R/01_build_rates.R` and consumed by `P02/R/02_run_queue.R`.

Required columns:

- `date`
- `lambda`
- `mu`
- `cwr_m3`
- `q_m3s`
- `q_imputed`

Never hand-edit this file. The legacy raw-CMIP6 CSV and stale indicator summary were removed during housekeeping; regenerate outputs only from the R scripts after the P02 indicator-contract corrections.

## 5. Queue output contract

| Quantity | Unit | Meaning |
|---|---|---|
| `Q` / `E[Q]` | claims | Backlog stock |
| `∫E[Q]dt` | claim-days | Backlog exposure |
| `Pr(Q ≥ q*)` | probability | Severe-state risk |
| Served demand | claims | Demand actually met |
| Blocked demand | claims | Arrivals rejected at backlog tolerance |
| Reneged demand | claims | Demand abandoned while waiting |
| Abandoned demand | claims | Blocked + reneged demand |
| Recovery time | days | First passage to empty; current implementation is stationary-only |
| Conservation residual | claims | `total arrivals - served - abandoned - change in backlog` |

The R indicator summary must be regenerated with these units before any pilot number is quoted in a manuscript.

## 6. Prediction products

1. **P02 nowcast/forecast:** estimate rates from covariates and score backlog/severe-state forecasts on held-out years and basins.
2. **Future scenarios:** after historical/provenance validation, use the CAMELS-IND-Proj 13-model/four-SSP streamflow ensemble as a conditional projection; no raw CMIP6 number may be published.
3. **Cross-basin explanation:** compare queue indicators across eligible catchments and relate differences to catchment/anthropogenic attributes.

Primary proposed endpoint: event-level Brier score for `Pr(Q ≥ q*)` by a declared deadline. A null result is acceptable.

## 7. Minimum reproducible run

```powershell
python tests/test_queue_core.py
python tests/test_nonstationary_bench.py
python tests/test_rate_estimators.py

Rscript P02/R/01_build_rates.R
Rscript P02/R/02_run_queue.R
```

Current Python baseline: **23 tests** (10 shared/P01, 6 benchmark, 7 estimator).
