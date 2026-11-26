# What queueing can and cannot do for low-flow hydrology: a target-dependent deficit-queue signal, a verified engine, and a zero-flow warning

**Ankit Deshmukh**
Department of Civil Engineering, Pandit Deendayal Energy University, Gandhinagar, India

*Draft for Hydrology and Earth System Sciences (HESS). Date: 26 November 2026.*

---

## Abstract

A deficit queue reads drought as accumulated unmet demand: demand arrives at rate $\lambda(t)$, supply serves at $\mu(t)$, unmet demand accumulates as a backlog $Q$, a finite capacity $K$ bounds the state, and reneging represents abandoned demand. The formulation promises quantities that indices do not give — expected backlog, severe-state probability, unmet volume and recovery time — but its incremental information has not been tested under a predeclared, verified design.

We test it twice. In India, 15 endpoint gauges across 8 basins pass a V1 utilisation screen and a minimum design-event rule; the target is district soil-moisture drought. In the USA, 14 reservoir–catchment pairs inside the same utilisation window use measured ResOpsUS outflow and the US Drought Monitor. Both use one claim volume per unit, catchment-relative thresholds, an exactly verified finite-capacity queue (14/14 checks), and a paired held-out Brier contrast.

The results are target-dependent, and that is the paper's point. On the **external district soil-moisture target, the confirmatory Brier endpoint is null**: median paired improvement **+0.00204**, 95% CI **[−0.00187, +0.00415]**, 10/15, $p=0.151$. On a **leakage-clean training-only SPI-3 target**, the same contrast is **positive**: median **+0.00397**, CI **[+0.00013, +0.00949]**, **12/15**, $p=0.0176$, with AUC **+0.038** (14/15). The minimal detectable Brier effect at N=15 is **0.0037**, so the primary null is interpretable. Ranking improves (mean AUC 0.771 → 0.815; queue-alone 0.846), but the utilisation slope is positive and not significant (+0.0066, $p=0.188$). The US exploratory replication is null on both Brier and AUC once the window is applied.

The work therefore contributes four things: one honest null, one target-dependent positive signal, one verified reusable engine, and one data-quality warning. The zero-flow convention is the warning: feeding artifact zeros as real zeros can flip the sensitivity result, so CAMELS-IND users must audit zeros before interpreting any queue or deficit index. The practical rule is conditional, not universal: use queue indicators as a ranking and descriptive layer in stressed, well-audited basins, not as a replacement for calibrated SPI/SSI probabilities.

**Keywords:** hydrological drought; queueing theory; deficit accumulation; SSI; Brier score; target dependence; zero-flow audit; CAMELS-IND; Caravan; ResOpsUS; US Drought Monitor.

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

### 1.7 What this paper asks

The paper does not ask “does the queue beat SPI?” in the abstract. It asks **what a deficit queue can and cannot do for low-flow hydrology**, and answers with four pieces of evidence:

1. a **honest null** on the primary calibrated-probability endpoint;
2. a **target-dependent positive** on a leakage-clean target;
3. a **verified, reusable engine** that stands on its own;
4. a **zero-flow data-quality warning** for CAMELS-IND users.

That framing is deliberate. A single headline “the method lost” would bury the parts that are useful; a single headline “the method won” would overstate a fragile secondary result.

---

## 2. Design and hypotheses

### 2.1 Primary confirmatory endpoints

For unit $g$, let $\Delta_g = B_g(\text{SSI-3}) - B_g(\text{SSI-3}+\text{queue})$ be the paired Brier difference on identical held-out months; positive means the queue improves.

- **E1 (concurrent).** Predict the drought outcome at month $t$ from month-$t$ SSI-3 versus month-$t$ SSI-3 plus queue indicators.
- **E2 (prospective, 1-month lead).** Same contrast with all predictors at month $t-1$.

A confirmatory endpoint passes only if all four rules hold: (1) $\mathrm{median}(\Delta_g) > 0$; (2) the two-level bootstrap 95% CI (resample units, then years within unit) excludes zero; (3) a one-sided sign test gives $p<0.05$ with improvement in at least 60% of units; (4) no unit has $\Delta_g < -0.005$.

### 2.2 Secondary and sensitivity questions

- **Leakage-clean target.** Replace the external soil-moisture target with a training-only SPI-3 drought target and drop the matching predictor. This is the clean test of circularity.
- **Ranking.** Does the queue improve AUC and top-decile precision, even when Brier does not?
- **Conditional signal.** Does the incremental gain increase with utilisation $\rho$?
- **Data quality.** Does the zero-flow convention change the sensitivity result?

These are secondary or exploratory. They are reported in full and never upgraded post hoc.

### 2.3 The utilisation screen

A queue whose demand is far below supply cannot show a drought signal. We admit a unit only if
$$\rho_g = \frac{\sum_t \lambda_g(t)}{\sum_t \mu_g(t)}$$
lies in the predeclared window $0.15 \le \rho_g \le 1.20$. Selection uses the **V1** screen (zeros audited), computed before selection. A unit enters the endpoint set only with at least **5 training and 3 test design events**.

---

## 3. Data

### 3.1 India

**Streamflow and forcing.** CAMELS-IND provides daily streamflow, catchment-mean precipitation, temperature and PET for 472 gauges (Mangukiya et al., 2025). We profile gauges with at least 300 observed flow days and the necessary forcings (279), retain data-quality candidates (zero fraction $<0.30$, interior gap $\le30$ days; 43), screen them into the V1 utilisation window (39), apply both-period coverage and at most three gauges per basin (23 candidates), and require at least 5 training and 3 test design events. The endpoint set is **15 gauges across 8 basins**, with $\rho$ from 0.188 to 1.054.

**Drought target.** The Drought Intelligence Explorer (Deshmukh, 2026) provides monthly district soil-moisture anomaly (SMA, percent anomaly), SPI-3 and SPEI-3 for 1981–2026. The primary target is SMA $\le -15\%$. The product uses its own 1981–2020 climatology, which overlaps the test years; this leakage is disclosed. The leakage-clean sensitivity uses a training-only SPI-3 drought target and drops the matching predictor.

**Zero-flow audit.** Every zero day is classified as positive, real-zero, artifact, unknown or missing using same-basin peer gauges (proxy grade; no independent CWC/India-WRIS daily record was available). The primary treatment (V1) makes artifact and unknown zeros missing; V0 (as recorded) and V2 (verified-flow-only) are sensitivities.

### 3.2 USA (exploratory)

**Streamflow and forcing.** Caravan-US provides daily ERA5-Land forcing, streamflow and HydroATLAS attributes for 671 catchments (Kratzert et al., 2023). Of these, 310 have a nonzero irrigated fraction, 59 are regulated, and 24 have both.

**Reservoir operations.** ResOpsUS provides daily storage, inflow, outflow, elevation and evaporation for 678 US reservoirs, 1974–2020 (Steyaert et al., 2022). Only **2** reservoirs fall inside a Caravan catchment polygon; large reservoirs sit downstream of the small headwater basins. The gauge is therefore the wrong unit, and we make the **reservoir** the unit.

**Core sample.** We retain reservoirs with a usable outflow record and an irrigated Caravan catchment within 20 km: **50 reservoirs** (49 run; 45 with at least 120 months). The primary sample applies the same $\rho$ window as India: **14 paired reservoirs**. The full **21 paired** sample is a sensitivity. The command area is the nearest catchment's irrigated fraction times its area — a proxy, explicitly labelled.

**Target.** The US Drought Monitor (NDMC/NOAA/USDA) provides weekly county drought severity. We use the monthly mean Drought Severity and Coverage Index (DSCI) and define a drought month as DSCI $\ge 100$ (D1 or worse; 34.7% of reservoir-months).

**OpenET.** OpenET is planned as a 2016–2020 validation of the crop coefficient. The account quota was exhausted during development and resets on 1 December 2026; the current results use a declared constant $K_c = 0.8$.

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
with $s_{\text{firm}} = 0.5$ and $\text{cap} = 10$ mm day$^{-1}$ in India. The US study uses measured reservoir outflow with $s_{\text{firm}} = 1$, a stated design difference.

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
Recovery time is the mean first passage from $q^*$ to $0$, obtained from the negative generator on states $1,\dots,K$; the blocking guard requires $\max_t \Pr(Q=K)<10^{-3}$ and is enforced, not merely recorded.

### 4.5 Statistical evaluation

For each unit, features are standardised on training rows only. A ridge logistic model is fitted:
$$\min_{\beta}\ -\sum_i\big[y_i\log p_i+(1-y_i)\log(1-p_i)\big]+\frac{\lambda_{\text{L2}}}{2}\|\beta\|_2^2,\qquad p_i=\sigma(x_i^\top\beta),$$
with the intercept unpenalised and $\lambda_{\text{L2}}=1.0$. Calendar-month dummies are included.

The Brier score is $B=\frac{1}{N}\sum_i(p_i-y_i)^2$; AUC is the Mann–Whitney statistic. The confirmatory statistic is the **paired** per-unit difference $\Delta_g=B_g(\text{SSI-3})-B_g(\text{SSI-3}+\text{queue})$ on identical held-out months. Its uncertainty uses a two-level bootstrap: resample units, then years within unit, recomputing the pooled per-unit Brier difference. The sign test uses $\mathrm{Binomial}(n,0.5)$.

The minimal detectable effect is
$$\mathrm{MDE}= (z_{0.975}+z_{0.80})\,\frac{\mathrm{SD}(\Delta_g)}{\sqrt{N}},$$
with $\alpha=0.05$ and power $0.80$. **The MDE is post hoc**: it is computed from the held-out deltas and is reported as an interpretability bound, not as prospective power. The harm bound is $\Delta_g<-0.005$.

### 4.6 Software and reproducibility

Everything is R. The engine is verified by a 14-check battery: M/M/1/K and M/M/c/K closed forms, RK4 convergence to stationarity, RK4 versus thinning discrete-event simulation, the conservation ledger, first passage versus simulation, the blocking guard, the unit wall, the Hargreaves 0.408 conversion, catchment-relative thresholds, the index helpers, the metrics on hand cases, the zero classifier, and the gap rule. Every output CSV has a JSON sidecar with the git hash, a **code hash**, parameters, seed and R session. The seed is 20261125.

---

## 5. Results

### 5.1 The primary test is null

| Endpoint | median $\Delta_g$ | 95% CI | sign | $p$ | harm |
|---|---:|---|---:|---:|---:|
| E1 concurrent | $+0.002044$ | $[-0.001866, +0.004154]$ | 10/15 | 0.151 | 2 |
| E2 prospective | $-0.000662$ | $[-0.003515, +0.001296]$ | 7/15 | 0.696 | 3 |

Both endpoints fail the confirmatory rules. The Brier MDE at N=15 is 0.003706, so the primary null is interpretable: any true gain is below about 0.004.

### 5.2 The leakage-clean target is positive

| Quantity | Value |
|---|---:|
| n | 15 |
| median $\Delta_g$ | $+0.003974$ |
| 95% CI | $[+0.000134, +0.009486]$ |
| sign | 12/15 ($p=0.0176$, 80%) |
| harm | 0 |
| median $\Delta$AUC | $+0.037879$ (14/15) |

This is the clearest positive signal in the work. On a target that does not use test-period climatology and with the circular predictor dropped, the queue+SSI improves both calibrated probability and ranking. It is a **secondary sensitivity**, not a confirmatory win, and the CI lower bound is close to zero.

### 5.3 Ranking improves, modestly

Median paired $\Delta$AUC is **+0.0222** (12/15) concurrently and **+0.0156** (11/15) prospectively. Mean held-out AUC (E1) is 0.771 for SSI-3, 0.815 for SSI-3+queue, and 0.846 for queue alone; SPI-3 (0.823) and SPEI-3 (0.813) sit between. At a top-decile monitoring budget, precision rises from **11.5% (SSI-3) to 14.9% (SSI-3+queue)** at a 3.9% event rate.

### 5.4 The conditional signal is a hypothesis

Regressing $\Delta_g$ on $\rho$ gives a positive India slope of **+0.00664** (95% CI $[-0.00369, +0.01697]$, $p=0.188$, $r=+0.359$). The US in-window slope is negative and not significant ($-0.01567$, $p=0.409$). The direction is consistent with “the queue helps when the system is stressed”, but the evidence does not establish it.

### 5.5 The engine is verified and reusable

The 14/14 battery passes. The ledger closes to $1.5\times10^{-15}$ on the India runs and $3.5\times10^{-15}$ on the USA runs; the blocking guard is $6.6\times10^{-9}$ (India) and $1.7\times10^{-6}$ (USA), far below $10^{-3}$. The engine is a standalone R library (`R/00_utils/queue_engine.R`, `units.R`) and can be reused for reservoir/yield simulation or teaching without the paper's empirical claims.

### 5.6 The zero-flow warning

The audit's V0/V1 check is the warning: when artifact zeros are fed in as real
zeros (V0), the sensitivity result can change sign or significance relative to
the audited V1 treatment. On the 15-gauge endpoint set, V0 gives a larger
apparent gain and a significant sign test (12/15, $p=0.0176$), while the V1
baseline does not. The full grid is in `RESULTS_v2.md` §9. Two other axes are
worth naming: **SUP-2** (dependable flow) is the strongest positive
(+0.00717, 13/15, CI excludes zero), while **SUP-3** is null; and **`K_days`
180 is identical to 365** because `K` hits the 25 floor, so that axis is not
identifiable in this sample. The lesson for CAMELS-IND users is independent of
the queue: **audit zeros before interpreting any deficit index**.

### 5.7 The US replication is null

With the same $\rho$ window, the US primary sample (14 paired reservoirs) gives E1 median **+0.000388** (CI $[-0.010481, +0.009345]$; 7/14, $p=0.605$; $\Delta$AUC $+0.0077$) and E2 median $-0.002387$. The full 21-reservoir sample is also null on Brier ($+0.000793$, 12/21, $p=0.332$). The India ranking signal does not replicate. The US arm is exploratory, not a second confirmatory test.

---

## 6. Discussion

### 6.1 What the queue can do

The queue gives four things that indices do not: an explicit backlog state, a severe-state probability, an unmet-volume accounting identity, and a recovery time. It improves ranking in the India data (AUC 0.771 → 0.815; top-decile precision 11.5% → 14.9%), and on the leakage-clean target it improves calibration as well (+0.004 Brier, 12/15). Those are real, if modest, benefits.

### 6.2 What it cannot do

It does not beat SSI-3 on the primary external target. It does not replicate in the US reservoir sample. It does not repair the over-prediction at low probabilities. And it does not establish the conditional “stressed basins only” rule: the India slope is positive but not significant. A paper that claimed a general calibrated-probability win would be wrong.

### 6.3 Why the result is target-dependent

The primary target is a district soil-moisture anomaly built on an external 1981–2020 climatology. The leakage-clean target is a training-only SPI-3 drought. The queue's demand-side state is closer to the latter: it integrates precipitation and PET deficits over the same growing season, whereas the soil-moisture product carries its own land-surface memory and a climatology that overlaps the test years. The contrast is therefore informative: it says the queue adds information where the target is a growing-season water deficit, and not where the target is a different land-surface state. This is a hypothesis about mechanism, consistent with the data but not proven by them.

### 6.4 The engine is a contribution in its own right

The 14-check battery, the per-day ledger, the unit wall and the catchment-relative thresholds are reusable. They fix a real reproducibility trap (unit mixing) and give a verified baseline for anyone building a deficit queue. That contribution does not depend on the empirical null.

### 6.5 The zero-flow warning is the most transferable result

Recorded zero-flow days in CAMELS-IND are not all real. Feeding them in as real zeros can flip a sensitivity result. That warning matters to anyone using the dataset, not just to queueing. It is the kind of negative result that saves other people time.

### 6.6 Utility and value

The practical rule is conditional:

- **Use** queue indicators as a ranking and descriptive layer in stressed, well-audited basins: they improve event ordering and give unmet volume and recovery time.
- **Do not** use them as a replacement for calibrated SPI/SSI probabilities, and do not assume the ranking gain replicates in every data system.
- **Audit** zeros and demand assumptions before interpreting any deficit result.

That is a narrower claim than “a new index beats SPI”, and a more useful one.

### 6.7 What would change the verdict

A general positive result needs measured irrigation deliveries, reservoir/delivery capacity as an operational constraint, a leakage-free target, and daily or event-based scoring. The US reservoir-centric design is the right direction; it needs a measured command area and a calibrated crop coefficient. The target-dependent positive suggests that a cleaner target, not a more complex queue, is the first thing to fix.

---

## 7. Limitations

- Demand is a crop-water envelope, not measured irrigation; `K_c = 0.8` in the USA is a declared constant.
- The India primary target uses an external 1981–2020 climatology; the training-only SPI-3 sensitivity is positive but is a secondary result with a CI close to zero.
- The India utilisation slope is not significant ($p=0.188$); the conditional rule is a hypothesis.
- The endpoint set is 15 gauges across 8 basins; the 23-candidate set is larger but includes units with too few design events.
- Zero-flow classification is proxy-grade; no independent CWC/India-WRIS record was available.
- The US arm is exploratory, with 14 paired reservoirs in the window and a command-area proxy.
- OpenET validation is pending the 1 December quota reset.
- `renv` is not installed; no lockfile is shipped.

---

## 8. Conclusion

A deficit queue is useful for what it uniquely provides — backlog, unmet volume, severe-state probability, recovery time — and for event ranking in the India data. It is not a general replacement for calibrated SPI/SSI probabilities: the primary external-target test is null, and the US replication is null. The positive signal is target-dependent and appears on a leakage-clean SPI-3 target. The verified engine and the zero-flow warning are contributions that stand independently of the empirical result. Framed this way, the work is “what queueing can and cannot do for low-flow hydrology”, not a failed attempt to beat an index.

---

## Data and code availability

The governing plan is `protocol/REDESIGN_PLAN_v2_R.md`. The engine and the 14-check battery are in `R/00_utils` and `R/verify`. India is `R/run_pipeline.R`; the USA is `R/us_pilot`. The numbered sequence is `steps/`, with `HELP.md` as the operator's manual. Extended literature and methods are `manuscript/SUPPLEMENT_LITERATURE.md` and `manuscript/SUPPLEMENT_METHODS.md`. Every output carries a JSON sidecar with the git hash, code hash, parameters, seed and session.

## Figures

**Figure 1.** Analysis workflow. `figures/fig_workflow.png`.

**Figure 2.** Study sites: 15 India endpoint gauges (8 basins) and 50 US reservoir–catchment pairs, coloured by $\rho$. `figures/fig_study_map.png`.

**Figure 3.** India V1 utilisation screen and queue regime. `figures/fig01_utilization_screen.png`, `figures/fig02_regime_pq.png`.

**Figure 4.** India E1 Brier delta and AUC delta. `figures/fig03_brier_forest_e1.png`, `figures/fig04_auc_forest.png`.

**Figure 5.** Example monthly series and reliability. `figures/fig05_example_series_5018.png`, `figures/fig06_reliability.png`.

**Figure 6.** India–USA paired contrasts. `figures/fig_india_us_comparison.png`.

**Figure 7.** Utilisation diagnosis. `figures/fig_utilisation_diagnosis.png`.

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
