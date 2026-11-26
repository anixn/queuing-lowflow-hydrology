# Does a deficit queue add drought information? Two independent multi-catchment tests and a utilisation diagnosis

**Ankit Deshmukh**
Department of Civil Engineering, Pandit Deendayal Energy University, Gandhinagar, India

*Draft for Hydrology and Earth System Sciences (HESS). Date: 26 November 2026.*

---

## Abstract

Hydrological drought is usually diagnosed as an anomaly relative to climatology. A deficit-queue formulation instead treats drought as accumulated unmet demand: demand arrives at rate $\lambda(t)$, supply serves at $\mu(t)$, unmet demand accumulates as a backlog $Q$, a finite capacity $K$ bounds the state, and reneging represents abandoned demand. The formulation promises quantities that indices do not give — expected backlog, severe-backlog probability, unmet volume and recovery time — but its incremental information has not been tested under a predeclared, powered design.

We test it twice, independently. In India, 24 CAMELS-IND gauges across 11 basins are screened into a predeclared utilisation window ($0.15 \le \rho \le 1.20$) and compared against district soil-moisture drought. In the USA, 50 reservoir–catchment pairs use measured ResOpsUS outflow as supply and the US Drought Monitor as target. Both studies use one claim volume per unit, catchment-relative thresholds, an exactly verified finite-capacity queue (14/14 checks), and a paired held-out Brier contrast on identical months.

Both confirmatory endpoints are null. In India the median paired Brier improvement from adding queue probability to SSI-3 is $+0.00085$ (95% CI $[-0.00111, +0.00172]$; sign test 15/24, $p=0.154$); the prospective endpoint is also null. In the USA the corresponding median is $+0.00079$ (95% CI $[-0.00465, +0.00774]$; 12/21, $p=0.332$). The minimal detectable Brier effect at 24 units is $0.0027$, several times the observed effect, so the nulls are interpretable rather than merely underpowered. The secondary AUC contrast is positive in both studies (India $+0.043$, USA $+0.011$), indicating a ranking gain without a calibrated-probability gain. A utilisation diagnosis shows that the queue helps more as $\rho$ rises in India but not in the USA, where the demand proxy dominates.

A deficit queue re-orders drought risk but does not, in these data, produce better-calibrated drought probabilities than SSI-3. That is a publishable methods and negative-result finding: it bounds the incremental skill, explains when the queue is informative, and specifies the measured-demand and operational data a positive test would require.

**Keywords:** hydrological drought; queueing theory; deficit accumulation; SSI; Brier score; negative result; CAMELS-IND; Caravan; ResOpsUS; US Drought Monitor.

---

## 1. Introduction

### 1.1 The index tradition and its blind spot

Drought is usually introduced as a hazard of deficit: precipitation below a climatological norm, soil moisture below an expectation, streamflow below an exceedance threshold. The index tradition — the Standardized Precipitation Index (McKee et al., 1993), the Standardized Precipitation Evapotranspiration Index (Vicente-Serrano et al., 2010), and their hydrological counterparts — made drought comparable across places and time. It also fixed the intellectual frame: a drought is an anomaly to be measured, and propagation is studied through lags and correlations between anomaly series (van Loon, 2015).

That frame has a blind spot. Water scarcity becomes damaging not when an anomaly is first detected but when demand that cannot be met accumulates faster than supply can clear it. Two catchments with the same rainfall deficit can diverge sharply: one has storage and reliable delivery, the other does not. The difference is not an anomaly magnitude; it is a service-capacity constraint and a backlog trajectory. Standardized indices do not represent that backlog, do not give recovery time as a model output, and do not separate shortage caused by unusually high demand pressure from shortage caused by degraded supply.

### 1.2 The queueing lineage in hydrology

Queueing theory is the mathematics of arrival streams, finite service capacity, congestion and waiting. Its core objects — queue length, busy period, waiting time, utilisation, loss probability — are the objects a drought manager is implicitly asking for when they ask how severe a shortage is, when it will end, and who will be cut off. The connection is not a metaphor imposed from outside, and it has a long hydrological lineage.

Langbein (1958) set out “Queuing Theory and Water Storage” in the *Journal of the Hydraulics Division*, explicitly linking reservoir storage to a queue. In probability theory, Moran (1954) and Gani (1957, 1969) built the theory of dams as random storage systems, and Prabhu (1998) unified queues, insurance risk and dams as stochastic storage processes. Klemeš (1987) reviewed a century of applied storage-reservoir theory. The queueing line survived in operations research and in a small but persistent set of hydrological applications.

### 1.3 Hydrological queue applications

Soil-water residence time was formulated with queueing disciplines applied to water-budget data by Gamble, Eckstein and Edwards (1990a, 1990b). Runoff–runon connectivity was represented as a queue by Harel and Mouche (2013, 2014), extended to a finite hillslope by Jones et al. (2016) and to rooted trees by Jones (2019), and formalised as a B/D/1 queue by Mouche and Harel (2016). Lefebvre (2019) applied an M/M/1/c continuous-time Markov chain to high river flows on the Delaware River — the closest direct methodological precedent, but for floods, not drought deficits.

Irrigation and water-supply queueing also has a sustained line. Batabyal (1996) applied queueing to groundwater management; Buchberger and Schade (1997) modelled residential water demand as Poisson pulse arrivals; Prajamwong, Merkley and Allen (1997) used a queuing system to allocate water to command areas; Palková and Hennyeyová (2012) and Palková, Rodný and Kiedrowicz (2012) determined optimal irrigation-system capacity; Yang, Guo, Li and Li (2016) formulated conjunctive surface-water/groundwater allocation as a queue; Yang, Li and Huo (2019) built a canal-management decision-support system on queueing theory; Unami et al. (2015) modelled rainwater harvesting for irrigation during dry spells; Gordienko and Ruiz de Chávez (2012) analysed controlled release from a simple dam; and Al-Sifao et al. (2026) assessed well-field supply reliability with a finite-source multi-server queue.

The lesson is unambiguous: queueing in hydrology is not new, and neither is queueing for irrigation or water supply. The open question is narrower — whether a drought-specific, conservation-constrained deficit backlog, with identification, exact validation and pre-specified drought tests, adds information beyond standard indices.

### 1.4 Non-stationary and time-varying queues

Drought is non-stationary, and time-varying queueing is a mature field. Whitt (2018) synthesises the theory; Massey and Whitt (1997) analyse peak congestion under slowly varying arrival rates; Rothkopf and Oren (1979) give a closure approximation for non-stationary M/M/s; Tan, Knessl and Yang (2013) treat finite-capacity queues with time-dependent arrivals; and Bogachev et al. (2023, 2024) give waiting-time approximations for long-term correlated and cross-correlated arrival rates. Machine learning for queues is also mature: Asanjarani, Nazarathy and Taylor (2021) survey parameter and state estimation; Dai and Gluzman (2022) control queueing networks with deep reinforcement learning; Sherzer et al. (2024) approximate G(t)/GI/1 queues with deep learning; and Ojeda et al. (2021) learn deep generative models for queueing systems. We therefore do not claim machine learning for queues, nor time-varying queueing, as contributions.

### 1.5 Coupled storage–demand and state-space drought work

Two recent lines are close conceptual prior art. Acosta et al. (2026) propose a dynamical network theory of drought with storage, accessibility, demand, transfer and loss, define drought intensity as unmet accessible demand, and formulate probabilistic risk and a recovery timescale; they explicitly call real-world validation and observational assimilation future work. Zhao et al. (2018) integrate hydrological processes and water management to evaluate reservoir storage and supply reliability under non-stationary supply and demand. Neither is a finite-state stochastic deficit queue with exact queue validation and pre-specified drought tests.

### 1.6 The scoped gap

> “Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens
> (295 records), plus the citation traces, we found no study that puts all
> four of these together: (1) drought as an accumulated unmet-demand backlog
> with a finite-capacity state; (2) queue-state indicators reported as
> drought quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests.”

This is a scoping-review finding, not a claim that no such study exists. We reclaim the Langbein–Moran–Prabhu lineage rather than claim it, and we never describe the junction as “novel”, “first” or “unique”.

### 1.7 Contributions and question

We ask a single confirmatory question: **does adding queue-state indicators to SSI-3 improve calibrated drought probability on held-out data?** We answer it twice, in two independent data systems, under a predeclared protocol. The contributions are: (i) a per-unit claim convention that removes the unit-mixing defect of earlier work; (ii) catchment-relative queue thresholds; (iii) an exactly verified engine with a per-day conservation ledger; (iv) two independent multi-catchment tests with a paired statistic; (v) a utilisation diagnosis of when the queue is informative; and (vi) a quantitative bound on the incremental Brier skill.

---

## 2. Hypotheses and predeclared design

### 2.1 Confirmatory endpoints

For unit $g$ (a gauge in India, a reservoir in the USA), let $\Delta_g = B_g(\text{SSI-3}) - B_g(\text{SSI-3}+\text{queue})$ be the paired Brier difference on identical held-out months; positive means the queue improves.

- **E1 (concurrent, diagnostic).** Predict the drought outcome at month $t$ from month-$t$ SSI-3 versus month-$t$ SSI-3 plus queue indicators.
- **E2 (prospective, 1-month lead).** Same contrast with all predictors at month $t-1$.

**H1:** $\mathbb{E}[\Delta_g] > 0$ under E1 and E2. **H0:** no improvement. A confirmatory endpoint passes only if all four predeclared rules hold: (1) $\mathrm{median}(\Delta_g) > 0$; (2) the two-level bootstrap 95% CI of the median (resample units, then years within unit) excludes zero; (3) a one-sided sign test gives $p<0.05$ with improvement in at least 60% of units; (4) no unit has $\Delta_g < -0.005$ driven by calibration breakdown (harm bound).

### 2.2 Utilisation screen

A queue whose demand is far below supply cannot show a drought signal. We admit a unit only if its utilisation
$$\rho_g = \frac{\sum_t \lambda_g(t)}{\sum_t \mu_g(t)}$$
lies in the predeclared window $0.15 \le \rho_g \le 1.20$, among the other data-quality rules in §3.

### 2.3 Multiplicity and reporting

E1 and E2 are the two protected tests. AUC, log loss, reliability, event timing, queue-alone, SPEI+queue and every sensitivity are secondary or exploratory, reported in full and never upgraded post hoc. Every sensitivity axis is reported regardless of direction.

---

## 3. Data

### 3.1 India

**Streamflow and forcing.** CAMELS-IND provides daily streamflow, catchment-mean precipitation, temperature and PET for 472 gauges (Mangukiya et al., 2025). We profile gauges with at least 300 observed flow days and the necessary forcings (279 gauges), screen them into the utilisation window (212), apply a strict data-quality screen (zero fraction $<0.30$, interior gap $\le 30$ days; 40 gauges), require at least 3 years in 1981–2010 and 2 years in 2011–2020, and retain at most three gauges per basin. The analysis set is **24 gauges across 11 basins**, with $\rho$ from 0.152 to 1.164.

**Drought target.** The Drought Intelligence Explorer (Deshmukh, 2026) provides monthly district soil-moisture anomaly (SMA, percent anomaly), SPI-3 and SPEI-3 for 1981–2026. The primary target is SMA $\le -15\%$ (7.4% of district-months). The product uses its own 1981–2020 climatology, which overlaps the test years; this leakage is disclosed. The leakage-clean sensitivity uses a training-only SPI-3 drought target (standardised on 1981–2010) and drops the matching `spi3` predictor.

**Zero-flow audit.** Every zero day is classified as positive, real-zero, artifact, unknown or missing using same-basin peer gauges (proxy grade; no independent CWC/India-WRIS daily record was available). The primary treatment (V1) makes artifact and unknown zeros missing; V0 (as recorded) and V2 (verified-flow-only) are sensitivities.

### 3.2 USA

**Streamflow and forcing.** Caravan-US provides daily ERA5-Land forcing, streamflow and HydroATLAS attributes for 671 catchments (Kratzert et al., 2023). Of these, 310 have a nonzero irrigated fraction (`ire_pc_sse`), 59 are regulated (`dor_pc_pva` or `rev_mc_usu` > 0), and 24 have both.

**Reservoir operations.** ResOpsUS provides daily storage, inflow, outflow, elevation and evaporation for 678 US reservoirs, 1974–2020 (Steyaert et al., 2022). Only **2** reservoirs fall inside a Caravan catchment polygon; large reservoirs sit downstream of the small headwater CAMELS basins. The gauge is therefore the wrong unit, and we make the **reservoir** the unit of analysis.

**Core sample.** We retain reservoirs with a usable outflow record and an irrigated Caravan catchment within 20 km: **50 reservoirs** (49 run; 45 with at least 120 months; 21 with paired test-window predictions). The command area is the nearest catchment's irrigated fraction times its area — a proxy, explicitly labelled.

**Target.** The US Drought Monitor (NDMC/NOAA/USDA) provides weekly county drought severity. We use the monthly mean Drought Severity and Coverage Index (DSCI) and define a drought month as DSCI $\ge 100$ (D1 or worse; 34.7% of reservoir-months). All 50 reservoirs map to 42 counties.

**OpenET.** OpenET field-scale ET is planned as a 2016–2020 validation of the crop coefficient. The account quota was exhausted during development and resets on 1 December 2026; the current results therefore use a declared constant $K_c = 0.8$. WaPOR and GLEAM are keyless alternatives.

---

## 4. Methods

### 4.1 The unit system

For a unit $g$ with catchment area $A_{\text{catch}}$ (m$^2$) and irrigated fraction $f_{\text{irr}}$,
$$A_{\text{cmd}} = f_{\text{irr}} A_{\text{catch}}, \qquad V_{\text{claim}} = \frac{d}{1000} A_{\text{cmd}},$$
where $d = 20$ mm is the claim depth. One claim is a physical volume of water over the command area and is used by **both** demand and supply. The queue engine receives only claims per day.

### 4.2 Demand and supply

Demand is a crop-water envelope:
$$\text{need}(t) = \max\!\big(K_c(t)\,\mathrm{PET}_0(t) - \phi P(t),\,0\big), \qquad \lambda(t) = \frac{\text{need}(t)}{d},$$
with $\phi = 0.7$ effective rain and $K_c$ a crop coefficient. In India $K_c$ follows a kharif seasonal curve; in the USA $K_c = 0.8$ (declared, a sensitivity axis).

Supply is a firm abstraction over the command area:
$$S_{\text{raw}}(t) = Q(t)\,86400\,s_{\text{firm}}, \qquad S_{\text{mm}}(t) = \frac{S_{\text{raw}}(t)}{A_{\text{cmd}}}\,1000, \qquad \mu(t) = \frac{\min(S_{\text{mm}}(t),\,\text{cap})}{d},$$
with $s_{\text{firm}} = 0.5$ and $\text{cap} = 10$ mm day$^{-1}$. The India study uses observed $Q$; the USA study uses measured reservoir outflow. SUP-2 (dependable flow) and SUP-3 (infrastructure-first) are sensitivities.

### 4.3 The finite-capacity deficit queue

States $n = 0,\dots,K$ count accumulated unmet demand in claims. With $\lambda$ the arrival rate and $\mu$ the service rate,
$$b_n = \begin{cases}\lambda, & n<K,\\ 0, & n=K,\end{cases}
\qquad
s_n = \min(n,c)\,\mu\,\big(\alpha\,\mathbb{1}[n\ge\theta]+1\big),$$
$$d_n = s_n + n\eta,$$
where $c$ servers, $\alpha$ is a service boost above the severe state $\theta$, and $\eta$ is the reneging rate. The generator is tridiagonal:
$$A_{n,n+1}=b_n,\qquad A_{n,n-1}=d_n,\qquad A_{n,n}=-(b_n+d_n).$$

The stationary distribution follows the product form
$$\pi_n = \pi_0 \prod_{i=0}^{n-1}\frac{b_i}{d_{i+1}},\qquad \pi_0 = \Big(1+\sum_{n=1}^{K}\prod_{i=0}^{n-1}\frac{b_i}{d_{i+1}}\Big)^{-1}.$$

The transient is solved by classical RK4 on $\dot p = pA$ with daily piecewise-constant rates:
$$p_{t+h} = p_t + \frac{h}{6}(k_1+2k_2+2k_3+k_4),$$
with the automatic stability cap $h \le \min(0.5,\,0.5/\max|\text{eigenvalue}|)$, renormalisation after every step, and a per-day conservation ledger
$$\text{offered} = \text{served} + \text{reneged} + \text{blocked} + \Delta \mathbb{E}[Q],$$
which stops the pipeline if the residual exceeds $10^{-6}$.

### 4.4 Thresholds and indicators

Thresholds are catchment-relative:
$$q^* = \lceil q_{\text{days}}\bar\lambda\rceil,\qquad K = \min\!\big(80,\max(25,\lceil K_{\text{days}}\bar\lambda\rceil)\big),\qquad \theta = \lceil \theta_{\text{mult}}q^*\rceil,$$
with $q_{\text{days}}=60$, $K_{\text{days}}=365$, $\theta_{\text{mult}}=1.5$. The USA study replaces $K$ by reservoir storage in claims, capped at 80. Daily indicators are
$$\mathbb{E}[Q]=\sum_{n=0}^{K} n\,p_n,\qquad \Pr(Q\ge q^*)=\sum_{n=q^*}^{K}p_n,\qquad \Pr(Q=K)=p_K.$$
Recovery time is the mean first passage from $q^*$ to $0$, obtained from the negative generator on states $1,\dots,K$; the blocking guard requires $\max_t \Pr(Q=K)<10^{-3}$.

### 4.5 Statistical evaluation

For each unit, features are standardised on training rows only. A ridge logistic model is fitted:
$$\min_{\beta}\ -\sum_i\big[y_i\log p_i+(1-y_i)\log(1-p_i)\big]+\frac{\lambda_{\text{L2}}}{2}\|\beta\|_2^2,\qquad p_i=\sigma(x_i^\top\beta),$$
with the intercept unpenalised and $\lambda_{\text{L2}}=1.0$. Calendar-month dummies are included.

The Brier score is $B=\frac{1}{N}\sum_i(p_i-y_i)^2$; AUC is the Mann–Whitney statistic. The confirmatory statistic is the **paired** per-unit difference $\Delta_g=B_g(\text{SSI-3})-B_g(\text{SSI-3}+\text{queue})$ on identical held-out months. Its uncertainty uses a two-level bootstrap: resample units, then years within unit, recomputing the pooled per-unit Brier difference. The sign test uses $\mathrm{Binomial}(n,0.5)$. The minimal detectable effect is
$$\mathrm{MDE}= (z_{0.975}+z_{0.80})\,\frac{\mathrm{SD}(\Delta_g)}{\sqrt{N}},$$
with $\alpha=0.05$ and power $0.80$. The harm bound is $\Delta_g<-0.005$.

### 4.6 Software and reproducibility

Everything is R (base R plus `data.table`, `ggplot2`, `sf`, `rmarkdown`). The engine is verified by a 14-check battery: M/M/1/K and M/M/c/K closed forms, RK4 convergence to stationarity, RK4 versus thinning discrete-event simulation, the conservation ledger, first passage versus simulation, the blocking guard, the unit wall, the Hargreaves 0.408 conversion, catchment-relative thresholds, the index helpers, the metrics on hand cases, the zero classifier, and the gap rule. Every output CSV has a JSON sidecar with the git hash, parameters, seed and R session. The seed is 20261125.

---

## 5. Results

### 5.1 India: screening and regime

| Step | Count |
|---|---:|
| CAMELS-IND gauges | 472 |
| Profiled | 279 |
| Inside $\rho$ window (SUP-1) | 212 |
| Strict data-quality screen | 40 |
| Both-period coverage and $\le 3$ per basin | **24** |
| Basins | **11** |

Utilisation ranges 0.152–1.164. Catchment-relative thresholds give $q^*=3$–$5$ claims and $K=25$–$26$; peak $\mathbb{E}[Q]$ ranges 2.4–6.6 claims and peak $\Pr(Q\ge q^*)$ ranges 0.29–0.89. The largest $\Pr(Q=K)$ is $4.8\times10^{-8}$, far below the guard, and the ledger residual is about $10^{-15}$.

### 5.2 India: confirmatory endpoints

| Endpoint | median $\Delta_g$ | 95% CI | sign | $p$ | harm | pass |
|---|---:|---|---:|---:|---:|---|
| E1 concurrent | $+0.000847$ | $[-0.001115, +0.001716]$ | 15/24 | 0.154 | 4 | no |
| E2 prospective | $-0.000331$ | $[-0.001667, +0.000574]$ | 12/24 | 0.581 | 3 | no |

Both endpoints fail the confirmatory rules. The secondary AUC contrast is positive: median $+0.0428$ (19/23) concurrently and $+0.0156$ (15/23) prospectively. The fair demand-side competitor (SPEI-3 + queue) is also null (E1 median $-0.000292$, 11/24).

### 5.3 India: power and sensitivity

Using the paired per-unit distribution, the Brier SD is 0.004661, the MDE at $N=24$ is **0.002666**, and the observed median is 0.000847. The AUC SD is 0.078637, the MDE is 0.044970, and the observed median is 0.042763. The AUC MDE is at the predeclared $+0.05$ grid point, so the study is powered for the secondary endpoint; the observed Brier effect is below the Brier MDE, so the null is interpretable. Simulation sign-test power at $N=24$ is 0.722 for $+0.05$ AUC and 0.983 for $+0.08$. The training-only SPI-3 target sensitivity preserves the null.

### 5.4 USA: sample and regime

Caravan-US contributes 671 catchments (310 irrigated, 59 regulated, 24 both), but only 2 reservoirs fall inside a catchment polygon. The reservoir-centric core has 50 reservoirs; 49 run, 45 have at least 120 months, and 21 have paired test-window predictions. Utilisation ranges 0.103–25.44 (27 reservoirs inside the window); $q^*=3$–$8$ and $K=25$–$80$. The largest $\Pr(Q=K)$ is $1.7\times10^{-6}$ and the ledger residual is $3.5\times10^{-15}$. The target has 10,681 complete reservoir-months across 48 reservoirs, with a 34.7% D1+ event rate.

### 5.5 USA: confirmatory endpoints

| Endpoint | $n$ | median $\Delta_g$ | 95% CI | sign | $p$ | median $\Delta$AUC |
|---|---:|---:|---|---:|---:|---:|
| E1 concurrent | 21 | $+0.000793$ | $[-0.004651, +0.007736]$ | 12/21 | 0.332 | $+0.0105$ |
| E2 prospective | 21 | $-0.000187$ | $[-0.004643, +0.011411]$ | 10/21 | 0.668 | $+0.0296$ |

Mean held-out E1 metrics are SSI-3 Brier 0.2094 / AUC 0.631, SSI-3 + queue Brier 0.2074 / AUC 0.646, queue alone Brier 0.2479 / AUC 0.583, and climatology Brier 0.2550 / AUC 0.530. The USA pilot reproduces the India pattern: no calibrated-probability gain, a small ranking gain.

### 5.6 India and USA together

The two independent tests agree in sign and magnitude. Both Brier intervals include zero; both sign tests are non-significant; both AUC contrasts are positive. The utilisation diagnosis (Figure 10) shows a positive slope in India — the queue helps more as $\rho$ rises — but a flat relationship in the USA, where the demand proxy and the command-area attribution dominate. The result is not a failure of the queue concept; it is a statement about the data and the regime.

---

## 6. Discussion

### 6.1 Why the calibrated-probability gain is absent

Three mechanisms are consistent with the results. First, the queue state is strongly driven by the same supply signal that SSI-3 already encodes; the incremental information is a demand-side adjustment that is small relative to the interannual variance of drought. Second, Brier score penalises calibration, and both models over-predict low-probability drought; the queue improves ordering (AUC) without repairing calibration. Third, the target is a drought state (soil moisture or USDM category), not unmet demand itself; the queue's natural output — unmet volume and recovery time — is not what the target measures.

### 6.2 The utilisation diagnosis is the transferable result

The India panel shows that the queue's incremental Brier gain increases with $\rho$: the queue is more useful when demand approaches supply. The USA panel is flat, and several reservoirs have extreme $\rho$ because the command-area proxy and the constant $K_c$ dominate. The practical lesson is that a queue analysis must report the utilisation regime before interpreting a null or a positive. A null at $\rho\approx0.05$ is not evidence about the queue; it is evidence about the regime.

### 6.3 What the work adds

1. **A per-unit claim convention.** One claim volume scales demand and supply, removing the unit-mixing defect that made earlier pilots uninterpretable.
2. **An exactly verified engine.** Fourteen checks, including closed forms, RK4 versus discrete-event simulation, and a per-day conservation ledger.
3. **Two independent nulls.** India gauges and US reservoirs, with different targets and different supply data, give the same qualitative answer.
4. **A quantitative bound.** The incremental Brier skill is below about 0.003 at 24 units; future studies can use this as a design target.
5. **A regime diagnosis.** The queue is informative in the utilisation window and when the demand signal is measured, not proxied.

### 6.4 Utility for drought management

The queue is valuable as a **descriptive and communication tool**: expected backlog, unmet volume, severe-state probability and recovery time are quantities a manager can use even when the incremental probability gain is small. It is not, in these data, a replacement for SSI-3 as a calibrated drought probability model. The honest recommendation is to use queue indicators alongside indices, report the utilisation regime, and avoid claiming superiority.

### 6.5 What would change the verdict

A positive result requires new data, not more tuning: measured irrigation deliveries or canal releases; reservoir and delivery capacity as an operational constraint; a leakage-free external benchmark; daily or event-based scoring; and a finer target (HUC8, field scale, or crop loss). The US reservoir-centric design is the right direction because it uses measured operations; it needs a measured command area and a calibrated crop coefficient to be conclusive.

---

## 7. Limitations

- Demand is a crop-water envelope, not measured irrigation; `K_c = 0.8` in the USA is a declared constant.
- The India target uses an external 1981–2020 climatology (leakage disclosed); the training-only SPI-3 sensitivity is the clean check.
- Zero-flow classification in India is proxy-grade; no independent CWC/India-WRIS record was available.
- The USA paired sample is 21 reservoirs; many ResOpsUS records end before 2013.
- The US command area is a nearest-catchment proxy, not a measured service area.
- OpenET validation is pending the 1 December quota reset; WaPOR/GLEAM are keyless alternatives.
- The USDM county DSCI is a coarse target.
- `renv` is not installed; no lockfile is shipped.

---

## 8. Conclusion

A finite-capacity deficit queue re-orders drought risk but does not, in two independent multi-catchment tests, improve calibrated drought probability beyond SSI-3. The result is robust to the choice of data system, target and supply source, and it is interpretable because the detectable effect is several times the observed effect. The queue remains useful for the descriptive quantities it uniquely provides — unmet volume, severe-state probability and recovery time — and for the utilisation diagnosis it enables. A positive test requires measured demand and operational data; until then, the honest claim is a methods and negative-result contribution, not a superiority claim.

---

## Data and code availability

Code, configuration, protocol and generated outputs are in the repository. The engine and the 14-check battery are in `R/00_utils` and `R/verify`. The India pipeline is `R/run_pipeline.R`; the USA pipeline is `R/us_pilot`. The numbered sequence is in `steps/`, with `HELP.md` as the operator's manual. Every output carries a JSON sidecar. Extended versions of the literature review and the data-and-methods text are in `manuscript/SUPPLEMENT_LITERATURE.md` and `manuscript/SUPPLEMENT_METHODS.md`.

## Figures

**Figure 1.** Analysis workflow: data, unit wall, rates, deficit queue, indicators, paired evaluation, utilisation diagnosis and outcome. `figures/fig_workflow.png`.

**Figure 2.** Study sites. Left: 24 CAMELS-IND gauges across 11 basins. Right: 50 US reservoir–catchment pairs. Colour is utilisation $\rho$. `figures/fig_study_map.png`.

**Figure 3.** India utilisation screen (SUP-1). Shaded band is the predeclared window $0.15$–$1.20$. `figures/fig01_utilization_screen.png`.

**Figure 4.** India queue regime: peak probability of a severe backlog state (left) and peak expected backlog (right). `figures/fig02_regime_pq.png`, `figures/fig02_regime_eq.png`.

**Figure 5.** India E1 Brier delta by gauge, with paired year-block bootstrap intervals. `figures/fig03_brier_forest_e1.png`.

**Figure 6.** Secondary endpoint: AUC delta for E1 and E2. `figures/fig04_auc_forest.png`.

**Figure 7.** Example monthly series (gauge 5018): queue state and district drought months. `figures/fig05_example_series_5018.png`.

**Figure 8.** Pooled E1 reliability for SSI-3 and SSI-3 + queue. `figures/fig06_reliability.png`.

**Figure 9.** India and USA paired contrasts: Brier (left) and AUC (right). Bars are two-level bootstrap 95% intervals. `figures/fig_india_us_comparison.png`.

**Figure 10.** Utilisation diagnosis: incremental Brier gain versus $\rho$ for India and the USA. Shaded band is the admissible window. `figures/fig_utilisation_diagnosis.png`.

## Competing interests

The author declares no competing interests.

## Acknowledgements

The author thanks the CAMELS-IND, Caravan, ResOpsUS and US Drought Monitor teams for open data, and the Drought Intelligence Explorer for the district drought product.

---

## References

Acosta, G. A. J. G., Colili, J. V. C., Abalus Jr., R. O., & Malolos, J. V. (2026). Toward a dynamical network theory of drought: Functional water accessibility in coupled human–water systems. *SSRN Electronic Journal* [Preprint]. https://doi.org/10.2139/ssrn.6835758

Al-Sifao, A. A., Petrović, N. V., Jovanović, R. Ž., & Bugarić, U. S. (2026). Application of queuing theory in the reliability and risk assessment of the water supply system: Case study of the Jabal Hasouna well-field. *Applied Sciences*, 16(3), 1608. https://doi.org/10.3390/app16031608

Asanjarani, A., Nazarathy, Y., & Taylor, P. (2021). A survey of parameter and state estimation in queues. *Queueing Systems*, 97(1–2), 39–80. https://doi.org/10.1007/s11134-021-09688-w

Batabyal, A. A. (1996). The queuing theoretic approach to groundwater management. *Ecological Modelling*, 85, 219–224. https://doi.org/10.1016/0304-3800(94)00178-2

Bogachev, M. I., Kuzmenko, A. S., Markelov, O. A., et al. (2023). Approximate waiting times for queuing systems with variable long-term correlated arrival rates. *Physica A*, 614, 128513. https://doi.org/10.1016/j.physa.2023.128513

Bogachev, M. I., Pyko, N. S., Tymchenko, D. A., et al. (2024). Approximate waiting times for queuing systems with variable cross-correlated arrival rates. *Physica A*, 654, 130152. https://doi.org/10.1016/j.physa.2024.130152

Buchberger, S. G., & Schade, T. (1997). Poisson pulse queueing model for residential water demands. In *Managing Water: Coping with Scarcity and Abundance* (pp. 488–493). American Society of Civil Engineers.

Dai, J. G., & Gluzman, M. O. (2022). Queueing network controls via deep reinforcement learning. *Stochastic Systems*, 12(1), 30–67. https://doi.org/10.1287/stsy.2021.0081

Deshmukh, A. (2026). Drought Intelligence Explorer: a multi-era district drought record and analytics platform for India. *Zenodo*. https://doi.org/10.5281/zenodo.24444860

Gamble, B. F., Eckstein, Y., & Edwards, W. M. (1990a). Principles of evaluation of soil water residence time using queueing disciplines with water budget data (Theoretical background—I). *Journal of Hydrology*, 113(1–4), 1–25. https://doi.org/10.1016/0022-1694(90)90164-S

Gamble, B. F., Eckstein, Y., & Edwards, W. M. (1990b). Evaluation of soil water residence time in a monolith lysimeter from the application of queueing disciplines to water budget data (Demonstration—II). *Journal of Hydrology*, 113(1–4), 27–49. https://doi.org/10.1016/0022-1694(90)90165-T

Gani, J. (1957). Problems in the probability theory of storage systems. *Journal of the Royal Statistical Society: Series B*, 19.

Gani, J. (1969). Recent advances in storage and flooding theory. *Advances in Applied Probability*, 1.

Gordienko, E. I., & Ruiz de Chávez, J. (2012). Quantitative estimates of stability in controlled GI/D/1/∞ queueing systems and in control of water release in a simple dam model. In *Proceedings of the 9th International Conference on Informatics in Control, Automation and Robotics (ICINCO)*. https://doi.org/10.5220/0004012603090312

Harel, M.-A., & Mouche, E. (2013). 1-D steady state runoff production in light of queuing theory: Heterogeneity, connectivity, and scale. *Water Resources Research*. https://doi.org/10.1002/2013WR013596

Harel, M.-A., & Mouche, E. (2014). Is the connectivity function a good indicator of soil infiltrability distribution and runoff flow dimension? *Earth Surface Processes and Landforms*, 39(11), 1514–1525. https://doi.org/10.1002/esp.3604

Jones, O. D. (2019). Runoff on rooted trees. *Journal of Applied Probability*, 56(4), 1065–1085. https://doi.org/10.1017/jpr.2019.61

Jones, O. D., Lane, P. N. J., & Sheridan, G. J. (2016). The stochastic runoff-runon process: Extending its analysis to a finite hillslope. *Journal of Hydrology*, 541, 677–688. https://doi.org/10.1016/j.jhydrol.2016.06.056

Klemeš, V. (1987). One hundred years of applied storage reservoir theory. *Water Resources Management*, 1(3), 159–175. https://doi.org/10.1007/BF00429941

Kratzert, F., Gauch, M., Klotz, D., & Nearing, G. (2023). Caravan — A global community dataset for large-sample hydrology. *Scientific Data*, 10, 225. https://doi.org/10.1038/s41597-023-01975-w

Langbein, W. B. (1958). Queuing theory and water storage. *Journal of the Hydraulics Division*, 84(5), 1–24. https://doi.org/10.1061/JYCEAJ.0000222

Lefebvre, M. (2019). An application of queueing theory in hydrology. *Atti della Accademia Peloritana dei Pericolanti*, 97(S2). https://doi.org/10.1478/aapp.97s2a18

Mangukiya, N. K., Kumar, K. B., Dey, P., Sharma, S., Bejagam, V., Mujumdar, P. P., & Sharma, A. (2025). CAMELS-IND. *Earth System Science Data*, 17, 461–491. https://doi.org/10.5194/essd-17-461-2025

Massey, W. A., & Whitt, W. (1997). Peak congestion in multi-server service systems with slowly varying arrival rates. *Queueing Systems*, 25. https://doi.org/10.1023/a:1019156418862

McKee, T. B., Doesken, N. J., & Kleist, J. (1993). The relationship of drought frequency and duration to time scales. In *Proceedings of the Eighth Conference on Applied Climatology* (pp. 179–184). American Meteorological Society.

Moran, P. A. P. (1954). A probability theory of dams and storage systems. *Australian Journal of Applied Science*, 5, 116–124.

Mouche, E., & Harel, M.-A. (2016). Overland flow as a queueing process: The B/D/1 queue with an arbitrary service time. *Performance Evaluation*. https://doi.org/10.1016/j.peva.2016.10.001

National Drought Mitigation Center, USDA, & NOAA (2026). U.S. Drought Monitor. https://droughtmonitor.unl.edu

Ojeda, C., Cvejoski, K., Georgiev, B., Bauckhage, C., Schuecker, J., & Sánchez, R. J. (2021). Learning deep generative models for queuing systems. *Proceedings of the AAAI Conference on Artificial Intelligence*, 35(10), 9214–9222. https://doi.org/10.1609/aaai.v35i10.17112

Palková, Z., & Hennyeyová, K. (2012). Determination of optimal capacity of irrigation system using queuing theory. *Acta Universitatis Bohemiae Meridionalis*, 11, 67–72. https://doi.org/10.32725/acta.2008.011

Palková, Z., & Rodný, T. (2010). Analytical model of the optimal capacity of an irrigation system. *Scientific Papers—Series Management, Economic Engineering in Agriculture and Rural Development*, 10(1), 155–158.

Palková, Z., & Rodný, T. (2011). Analytical model of the optimal capacity of an irrigation system. *Scientific Papers—Series Management, Economic Engineering in Agriculture and Rural Development*, 14(1).

Palková, Z., Rodný, T., & Kiedrowicz, M. (2012). Principles of process controlling of irrigation systems using queuing theory. *Rocznik Ochrona Środowiska*, 14, 161–171.

Prabhu, N. U. (1998). *Stochastic storage processes: Queues, insurance risk, and dams* (2nd ed.). Springer.

Prajamwong, S., Merkley, G. P., & Allen, R. G. (1997). Decision support model for irrigation water management. *Journal of Irrigation and Drainage Engineering*, 123(2), 106. https://doi.org/10.1061/(ASCE)0733-9437(1997)123:2(106)

Rothkopf, M. H., & Oren, S. S. (1979). A closure approximation for the nonstationary M/M/s queue. *Management Science*, 25(6), 522–534. https://doi.org/10.1287/mnsc.25.6.522

Sherzer, E., Baron, O., Krass, D., & Resheff, Y. S. (2024). Approximating G(t)/GI/1 queues with deep learning. *European Journal of Operational Research*, 322(3), 889–907. https://doi.org/10.1016/j.ejor.2024.12.030

Steyaert, J. C., Condon, L. E., Turner, S. W. D., & Voisin, N. (2022). ResOpsUS, a dataset of historical reservoir operations in the contiguous United States. *Scientific Data*, 9, 147. https://doi.org/10.1038/s41597-022-01134-7

Tan, X., Knessl, C., & Yang, Y. P. (2013). On finite capacity queues with time dependent arrival rates. *Stochastic Processes and their Applications*. https://doi.org/10.1016/j.spa.2013.02.002

Unami, K., Mohawesh, O., Sharifi, E., et al. (2015). Stochastic modelling and control of rainwater harvesting systems for irrigation during dry spells. *Journal of Cleaner Production*, 88, 185–195. https://doi.org/10.1016/j.jclepro.2014.03.100

van Loon, A. F. (2015). Hydrological drought explained. *Water Resources Research*, 51(6), 4067–4092. https://doi.org/10.1002/2015WR017141

Vicente-Serrano, S. M., Beguería, S., & López-Moreno, J. I. (2010). A multiscalar drought index sensitive to global warming: The Standardized Precipitation Evapotranspiration Index. *Journal of Climate*, 23(7), 1696–1718. https://doi.org/10.1175/2009JCLI2909.1

Whitt, W. (2018). Time-varying queues. *Queueing Models and Service Management*, 1(2). http://qmsm.nchu.edu.tw/index.php/qmsm/article/view/33

Yang, G., Guo, P., Li, R., & Li, M. (2016). Optimal allocation model of surface water and groundwater based on queuing theory in irrigation district. *Transactions of the Chinese Society of Agricultural Engineering*, 32(6). https://doi.org/10.11975/j.issn.1002-6819.2016.06.016

Yang, G., Li, M., & Huo, L. (2019). Decision support system based on queuing theory to optimize canal management. *Water Resources Management*, 33(12), 4367–4384. https://doi.org/10.1007/s11269-019-02372-y

Zhao, G., Gao, H., Kao, S.-C., Voisin, N., & Naz, B. S. (2018). A modeling framework for evaluating the drought resilience of a surface water supply system under non-stationarity. *Journal of Hydrology*, 563, 22–32. https://doi.org/10.1016/j.jhydrol.2018.05.037
