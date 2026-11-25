# INPUT_OUTPUT_SPEC.md — What data I need, what goes in, what comes out, what I predict — with numbers

Companion to `AGENTS.md`, `DATA_GUIDE.md`, `WHY_THIS_APPROACH.md`.
All numbers below are computed from the actual pilot files in this repository
(gauge 4026) or verified from the CAMELS-IND publication (Mangukiya et al.
2025, ESSD 17:461–491). Script of record: `scripts/qdj_numbers.py`.
Prepared 21 November 2026.

---

## 0. The whole pipeline in one line

```
CAMELS-IND files  ──(unit conversions)──►  λ(t), μ(t)  ──(queue engine)──►
drought-state indicators  ──(learned estimators + CMIP6)──►  PREDICTIONS:
backlog & severe-state probability for held-out years, held-out basins,
and future SSP climates
```

## 1. The shopping list — exactly what you need (and have)

| # | File (CAMELS-IND v2.2, Zenodo 14999580) | What it contains | Role | Status |
|---|---|---|---|---|
| 1 | `camels_ind_forcings/catchment_mean_forcings/<gauge>.csv` | daily 1980–2020: `prcp(mm/day)`, `tmax(C)`, `tmin(C)`, `pet_gleam(mm/day)`, soil moisture (19 variables total) | **λ(t) demand covariates** | Have (472 files) |
| 2 | `streamflow_timeseries/streamflow_observed.csv` | 472 gauge columns, daily 1980–2020, m³/s | **μ(t) service rate** | Have; 242 streamflow-sufficient |
| 3 | `streamflow_timeseries/lstm_pred_streamflow.csv` | LSTM-predicted flow, all 472 | zero-flow cross-check; ungauged basins | Have |
| 4 | `attributes_csv/camels_ind_*.csv` (8 files) | 211 static attributes, incl. 25 anthropogenic (dams/canals/irrigation) | replace assumed command area; explain cross-basin differences | Have |
| 5 | IMD gridded P, Tmax, Tmin (1951–2025, NetCDF) | observational climate reference | **bias-correction target** for CMIP6; λ covariates | Have (75 files each) |
| 6 | CMIP6 historical (24 models, 1981–2014) + SSP (4 scenarios, 28 model/SSP combos ready) | daily pr, tasmax, tasmin | future λ, μ covariates | Have; download continuing |

**You do not need** GRACE (Topic 7 only), canal operations records (use the
sensitivity envelope), or a Python NetCDF reader (R reads everything).

**Eligible catchments:** the 242 streamflow-sufficient ones, minus any the
zero-flow check disqualifies. Pilot: **4026 Kurundwad** (Krishna,
15,190 km², 95.54% coverage); second: **4064 Yadgir** (69,863 km²).

## 2. What goes IN — the exact input table (gauge 4026, real numbers)

**Input file 1: forcing CSV** → 14,976 daily rows, 1980-01-01 to 2020-12-31.

**Input file 2: observed streamflow** (m³/s, same days): mean 336 m³/s,
median 0, max 10,092 m³/s; **9,710 zero-flow days (64.8%)** — open question;
668 missing days linearly interpolated and flagged (`q_imputed=TRUE`).

**Input file 3: the locked convention** `[assumption, not measurement]`:
command 50,000 ha; 1 claim = 10⁷ m³ = 20 mm; K = 20 claims; cap 3
claims/day; firm share 0.5; peff 0.7; kharif sowing DOY 200; season 120 d;
peak Kc 1.2.

### The conversion chain (where every rate comes from)

**Supply:** river flow → firm supply → claims per day

| Observed flow | × 86,400 s/day | × firm 0.5 | ÷ 10⁷ m³ | = μ(t) claims/day |
|---|---|---|---|---|
| 50 m³/s | 4.32 Mm³/day | 2.16 Mm³ | 0.216 | low service |
| 100 m³/s | 8.64 Mm³/day | 4.32 Mm³ | 0.432 | |
| 500 m³/s | 43.2 Mm³/day | 21.6 Mm³ | 2.160 | near cap |

Result on real data: μ mean **1.93** claims/day on the 5,266 days with
service, max **3.0** (cap binds), μ = 0 on 64.8% of days.

**Demand:** PET → crop water requirement → claims per day

| PET | × Kc 1.2 | × 50,000 ha | × peff 0.7 | = λ(t) claims/day |
|---|---|---|---|---|
| 2 mm/day | 2.4 mm | 1.20 Mm³/day | 0.84 Mm³ | 0.084 |
| 5 mm/day | 6.0 mm | 3.00 Mm³/day | 2.10 Mm³ | 0.210 |

Result on real data: λ mean **0.050**, p95 **0.146**, max **0.259**
claims/day; mean CWR 503,097 m³/day (max 2.59 Mm³/day).

### The seasonal anti-phase (the engine of the whole story)

| Month | mean λ (demand) | mean μ (supply) | Reading |
|---|---|---|---|
| Oct | **0.097** (peak demand) | 0.799 | post-monsoon irrigation, flow receding |
| Nov–Feb | 0.042–0.054 | 0.026–0.102 | **dry season: demand with almost no service** |
| Jul–Aug | 0.006–0.033 (min demand) | **2.225–2.513** (max supply) | monsoon: service abundant |
| Mar–May | 0.055–0.060 | 0.032–0.042 | summer shortage |

Demand peaks exactly when supply collapses — that is why the *rates*, not
their averages, must be modelled (the verified 2.3× averaging error).

**Input file 4: CMIP6 extract (raw, gauge 4026, ACCESS-ESM1-5 ssp245):**
9,497 rows, 2015–2040; pr mean 3.31 mm/day (48.7% dry days), tasmax mean
32.7 °C, tasmin 21.7 °C, Hargreaves ET0 mean 11.58 mm/day — **UNCORRECTED,
pipeline check only, never publish** (AGENTS.md §3 rule 2).

## 3. What the engine DOES (settings, not numbers you interpret)

Finite-capacity birth–death CTMC, K = 20 states, RK4 propagation with
automatic dt cap (unstable when dt·|λmax| ≳ 2.78; generator reaches ~8.5/day),
one-year spin-up, evaluation 2001–2020. The engine consumes the daily CSV
(`date, lambda, mu, cwr_m3, q_m3s, q_imputed`) and produces the indicators.

## 4. What comes OUT — the indicator table (verified pilot outputs)

`rates_4026_indicators.csv`, 2001–2020 after spin-up — **illustrative under
the stated assumptions, not findings**:

| Output indicator | Plain meaning | Pilot value |
|---|---|---|
| E[Q] mean | average unmet-demand backlog | **1.43 claims** (≈ 14.3 Mm³ ≈ 29 mm over the command) |
| E[Q] peak | worst expected backlog | **3.60 claims** (≈ 36 Mm³ ≈ 72 mm) |
| Pr(Q ≥ 6) mean | share of days in severe state | **0.0231** (≈ 8.4 days/yr) |
| Pr(Q ≥ 6) peak | worst-day severe-state probability | **0.156** |
| ρ median (finite) | typical traffic intensity | 0.0096 (ρ = ∞ on zero-flow days by construction) |
| U (legacy label) | cumulative abandoned demand | **199.0 claims**; the R script incorrectly labels this `claim-days` |
| Recovery time | days to clear backlog after rains | computed per event (busy-period/first-passage) |

Daily output CSV adds `date, lambda, mu, cwr_m3, q_m3s, q_imputed`; every
regeneration is one Rscript run in order (READMEs list the commands).

## 5. What I am PREDICTING — the three prediction products

**P1. Nowcast/forecast the queue state from weather covariates (P3 core).**
Estimators learn λ(t) = fθ(covariates) and μ(t) = gφ(covariates) from P, T,
PET, flow — then the indicators are *predicted* for years held out of
training (and basins held out), against pre-registered baselines
(constant-rate, climatological seasonal, SPI/SSI).

What the prediction problem looks like, in real numbers (my layman
water-ledger demo on 2016–2020, 1,827 days — a deterministic daily
accounting, NOT the CTMC engine; illustrative only):

| Rates used | mean Q | peak Q | days Q≥6 | backlog exposure (claim-days) |
|---|---|---|---|---|
| **Oracle** (actual daily λ, μ) | 3.57 | 13.68 | **537 (29.4%)** | 57.2 |
| **Climatology** (monthly means from 1980–2015) | 2.50 | 9.81 | **335 (18.3%)** | 48.9 |

The gap between the rows — 202 fewer severe-state days, 8.3 claim-days of
unmet demand, a 30% lower mean backlog — is precisely what a good estimator
must recover from weather data, and what pre-registered skill metrics will
score (RMSE/Brier-type scores on E[Q], Pr(Q≥6), U, recovery time; the
honest possibility is a null result, which we then publish).

**P2. Future queue states under climate change.** Bias-corrected CMIP6 →
future λ(t) covariates + delta-change-scaled future μ(t) → future
E[Q], Pr(Q≥6), U for SSP1-2.6 / 2-4.5 / 3-7.0 / 5-8.5, quoted per scenario
with ensemble spread (28 model/SSP combinations ready). Reference anchor
today: Pr(Q≥6) peak 0.156, legacy U 199 claims under observed 2001–2020
(the R script's `claim-days` label is incorrect).

**P3. Cross-basin explanation (the large-sample product).** The same
pipeline over the eligible subset of 242 catchments → 242 × 211 attribute
matrix → regress queue indicators on anthropogenic attributes (dams,
irrigation) to explain why equal-SPI basins differ. Scale: 3,623,950
day-rows per variable; attribute matrix 51,062 cells.

## 6. Honesty ledger for every number above

| Tag | Numbers |
|---|---|
| `[measurement]` | all CAMELS-IND forcing/streamflow values (14,976 days; Q mean 336, max 10,092 m³/s; 64.8% zero days; 668 imputed) |
| `[assumption]` | command 50,000 ha; claim 10⁷ m³; K = 20; cap 3/day; firm 0.5; peff 0.7; Kc curve; sowing DOY 200 |
| `[derived, illustrative]` | λ 0.050/0.146/0.259; μ 1.93 mean, 3.0 cap; all indicator values (E[Q] 1.43/3.60; Pr(Q≥6) 0.023/0.156; U 199.0); ledger demo (mean Q 3.57 vs 2.50; days≥6 537 vs 335) |
| `[raw, unusable]` | CMIP6 extract numbers (pr 3.31 mm; ET0 11.58 mm/day) — bias-correction gate not passed |
| `[open question]` | zero-flow semantics (64.8% of days); regulation status of 4026 |

## 7. Minimum viable run (what to execute, in order)

```powershell
python paper1/src/test_queue_core.py          # 5 tests
python paper3/src/test_nonstationary_bench.py # 6 tests
python paper3/src/test_rate_estimators.py     # 7 tests
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R
```
