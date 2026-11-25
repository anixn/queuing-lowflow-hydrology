# P02 modelling plan — design protocol, not final analysis

Date: 25 November 2026. Status: **design/preparation only**. P02 implementation starts after P01 reaches Gate B.

## 1. Scientific target

Estimate a non-stationary finite-capacity drought queue from hydroclimatic data, test whether its states and parameters are identifiable, and evaluate whether queue indicators add information beyond climatology, SPI/SPEI/SSI and storage-based baselines on held-out years, basins and drought events.

The primary prediction product is an event-level probability:

\[
\Pr(Q(t)\ge q^* \mid \text{information available at forecast issue time}).
\]

Secondary products are expected backlog, backlog exposure, abandoned demand and probability of recovery by a management deadline.

## 1.1 Design decisions for the first P02 cycle

1. **Current pilot uses aggregate supply with c = 1.** The real-data μ already
   aggregates firm streamflow. Use c = 2 only after streamflow and canal supply
   are split into genuinely separate per-source rates; otherwise the service cap
   can be applied twice.
2. **λ is a process/scenario reconstruction until demand labels exist.** Do not
   fit a residual demand model or treat seasonal-mass calibration as validation
   when both sides come from the same crop/CWR assumptions.
3. **Separate reconstruction, nowcasting and projection.** Same-day observed
   discharge is a reconstruction input, not an ahead-of-event predictor. No
   test-year totals, future interpolation or fold-aware climatology may leak
   into training.
4. **CAMELS-IND-Proj is a conditional projection input.** Do not double bias
   correct its documented bias-corrected forcing. Validate historical streamflow
   and obtain the upstream LSTM training/validation split before calling it
   out-of-sample.
5. **Exact benchmarks verify solver mathematics, not hydrological truth.**
   Empirical claims require independent observations and held-out events.

## 2. What is already available

| Data | Local status | Role |
|---|---|---|
| CAMELS-IND forcings, observed and LSTM streamflow, attributes | 472 forcing files, 2 streamflow files, 8 attribute files | Historical covariates, supply observations and catchment controls |
| IMD gridded P/Tmax/Tmin | 75 annual files per variable, 1951–2025 | Observational reference and bias-correction target |
| Raw CMIP6 historical | 816 pr, 748 tasmax, 748 tasmin files | Historical climate-model comparison/fallback |
| Raw CMIP6 SSP | 3,564 files per variable across SSP126/245/370/585 | Fallback/sensitivity forcing |
| CAMELS-IND-Proj streamflow | 13 models × historical + 4 SSPs; gauge 4026 complete in all 65 files | Primary future μ(t) ensemble |
| CAMELS-IND-Proj forcing archive | Full ZIP present; standard Python/bsdtar extraction of the forcing subset failed | Preferred future λ(t) forcing if extraction is recovered; otherwise bias-correct raw CMIP6 |
| Drought Intelligence Explorer v2 | Available from Zenodo, not yet local | District SPI/SPEI/soil-moisture/VCI baselines and event context |

CAMELS-IND-Proj supplies daily projected streamflow from a regional LSTM for 2015–2100 and historical 1980–2014. Its forcing is described as bias-corrected CMIP6. This changes the future plan: **use projected streamflow as the primary future service input**, subject to historical validation, instead of making delta-change μ(t) the default.

## 3. Model stack

### 3.1 Demand rate λ(t): process first, learning second

**Primary reconstruction model**

\[
\lambda_{\rm process}(t)=\frac{A_{\rm crop}\,K_c(doy)\,ET_0(t)\,f_{\rm eff}}{V_{\rm claim}}.
\]

Use crop-area/calendar data when available. Until then, use the documented 45,000 ha proxy and declare it as an assumption. Keep the physical calculation transparent and auditable.

**Learned correction**

Do not train a supervised demand model without demand labels. In the first
cycle, report the process model and its declared area/calendar/efficiency
envelope only. If independent district seasonal totals or delivery records later
become available, fit a small log-link residual/calibration model, restricted to
active crop seasons or made explicitly zero-aware:

\[
\lambda(t)=\lambda_{\rm process}(t)\exp(r_\theta(x_t)),
\]

with seasonal mass calibration and block cross-validation. Candidate learners are regularised regression or gradient-boosted trees; a recurrent network is not justified by the current data alone.

**Forecast rule**

Use only information available at issue time: lagged/forecast rainfall, temperature, PET, soil moisture, day-of-year and crop calendar. Same-day PET or flow may be used for retrospective reconstruction, not advertised as ahead-of-event prediction. Imputation, climatology and seasonal-mass targets must be estimated inside each training fold; never use test-year totals or full-series interpolation before splitting.

### 3.2 Service rate μ(t): deterministic reconstruction plus hurdle forecasting

**Primary reconstruction**

\[
\mu_{\rm process}(t)=\min\!\left(\frac{f_{\rm firm}\,Q_{\rm obs}(t)\,86{,}400}{V_{\rm claim}},\;\mu_{\rm cap}\right).
\]

For the current pilot, set c = 1 because μ is aggregate firm streamflow. Add a canal term and c = 2 only when canal supply is genuinely separate and documented. Do not multiply an aggregate supply rate by a server count.

**Meteorological nowcast/forecast**

Only after zero-flow and regulation semantics are resolved, use a two-part model because zero flow is common:

1. occurrence model: \(p_t=P(Q_t>0\mid z_t)\), logistic/GBDT classifier;
2. positive-magnitude model: Gamma/Tweedie or log-link GBDT for \(Q_t^+\);
3. transform predicted flow to μ with the same physical cap and firm-share rule.

Validation must score dry-day occurrence, dry-spell duration, positive-flow error and queue-tail indicators. If zeros are fill values, correct the data before fitting.

**Future μ(t)**

Use CAMELS-IND-Proj `Streamflow_projected.csv` for 13 models × four SSPs. Treat each member as a conditional projection from a shared LSTM structure, not an independent probabilistic draw. Validate historical simulations against observed/LSTM streamflow for seasonal volume, zero occurrence, low-flow duration and extremes; obtain the upstream training/validation split. Do not double bias correct its documented bias-corrected forcing. Raw CMIP6 remains pipeline-check-only under the repository rule; delta-change may be shown only as a clearly labelled methodological sensitivity after its own bias-correction gate.

### 3.3 Queue state: finite-capacity birth–death CTMC

Keep the shared engine in `src/shared/queue_core.py`:

- states \(n=0,\ldots,K_q\);
- arrivals λ(t), blocked at \(K_q\);
- service \(S_n(t)=\min(n,c)\mu(t)[1+(\alpha-1)1(n\ge\theta)]\);
- reneging \(n\eta\);
- forward equation \(\dot p=pA(t)\).

Report backlog stock, backlog exposure, served demand, blocked demand, reneged demand, abandoned demand and the conservation residual separately.

### 3.4 Identification, not just prediction

Exact forward solutions do not prove that real demand and supply can be recovered. Use:

- synthetic parameter-recovery experiments;
- profile likelihood or simulation-based calibration;
- posterior predictive checks against independent storage/delivery/impact observations where available;
- observational-equivalence analysis for \(K_q,\eta,\theta,\alpha,\lambda,\mu\).

If materially different parameter sets produce the same observations but different decisions, report non-identifiability and identify which dimensionless indicators remain robust.

### 3.5 Recovery probabilities

Implement the time-dependent backward equation or absorbing-state calculation for:

\[
\Pr(T_{Q\to0}\le H\mid Q(0)=q,\{\lambda(t),\mu(t)\}).
\]

Validate against exact piecewise-constant solutions and DES first-passage simulations. Compare with persistence, climatology and the stationary recovery formula.

## 4. Validation ladder

| Level | Question | Reference/baseline | Pass or report rule |
|---|---|---|---|
| Solver verification | Is the forward mathematics correct under stated assumptions? | Exact stationary, Floquet, MMPP, DES | Probability/ledger residuals within declared tolerance; not empirical validation |
| Synthetic identification | Can known parameters be recovered? | Oracle parameters and synthetic observations | Report recovery failure or equivalence classes |
| Historical reconstruction | Can observed flow/demand proxies be reproduced? | LSTM streamflow, process rates, climatology | No target leakage; report bias and calibration |
| Nowcast | Does the model predict unseen years/basins? | Persistence, climatology, SPI/SPEI/SSI, storage anomaly | Primary Brier score/skill/reliability plus MAE/interval score |
| Recovery | Are deadline-recovery probabilities calibrated? | Persistence, climatology, stationary formula | Brier/reliability and recovery-time MAE |
| Future scenarios | Are projected queue states credible? | CAMELS-IND-Proj ensemble; bias-corrected delta-change methodological check only | Historical validation first; ensemble spread mandatory |

Use whole-year, whole-basin and whole-event holdouts. Pre-register one primary endpoint before examining P02 outputs. A null result is a valid outcome.

## 5. Uncertainty

Carry uncertainty from:

- crop area/calendar and claim convention;
- rate estimates and structural parameters;
- temporal dependence and spatial dependence;
- CMIP6 model/scenario spread.

Use moving-block, year or basin-cluster resampling nested inside validation folds, hierarchical uncertainty where justified, and repeated queue solves. Keep rate, physical-parameter and GCM/scenario uncertainty separate. Report interval coverage, Brier skill/reliability and calibration, not only rate-level intervals.

## 6. Immediate work packages after Gate B

1. Correct R/Python indicator units, set aggregate μ to c = 1, and fix spin-up, fold leakage and adaptive stability; add golden tests.
2. Implement time-varying recovery and synthetic identification experiments.
3. Build the process λ baseline now; implement the hurdle μ nowcast only after zero-flow/regulation semantics are resolved. Compare with climatology and CAMELS-IND LSTM.
4. Add gauges 4026 and 4064, then a stratified multi-gauge sample.
5. Acquire crop calendar/area and Drought Intelligence Explorer v2; resolve zero-flow/regulation semantics.
6. Validate CAMELS-IND-Proj historical streamflow before future μ use.
7. Pre-register held-out metrics and run the ablation ladder.

No final indicator result is claimed in this plan.
