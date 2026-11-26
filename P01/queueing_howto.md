# How to use queueing theory for drought: a working note (v2, 26 Nov 2026)

Purpose: the technical core that the merged paper explains and the R pipeline
implements. Everything below is a *proposal*, not a published result. Numbers in
Box 1 are reproducible with the R engine (`R/00_utils/queue_engine.R`) and are
synthetic, not observational. Reference details were verified on 20–21 Nov 2026;
see `literature_audit.md`. The former Python implementation
(`src/shared/queue_core.py`, `src/P01/data_pipeline.py`) is preserved on branch
`legacy-python` and is superseded by the R code.

---

## 1. The one-sentence idea

A drought is a **service-system failure**: water-demand claims arrive through
time, a weather- and infrastructure-dependent supply process tries to clear
them, storage is a finite buffer, and the unmet part accumulates as a backlog.
Queueing theory is the mathematics of exactly that bookkeeping.

## 2. Two dual representations — use both, do not confuse them

| | (A) Supply-buffer queue | (B) Deficit queue |
|---|---|---|
| "Customers" | units of stored water | units of unmet demand |
| Arrival process | inflow / recharge $I(t)$ | demand claim $D(t)$ |
| Service process | withdrawal / release $R(t)$ | supply available to clear backlog $S(t)$ |
| Buffer occupancy | storage $X(t)$ | backlog $Q(t)$ |
| Empty buffer | **supply starvation** = drought onset | $Q=0$ = no represented deficit |
| Full buffer | spill / rejected recharge at physical capacity $K_s$ | $Q=K_q$ = new demand blocked; $K_q$ is backlog tolerance, not storage capacity |
| Observable proxy | reservoir level, soil moisture, GRACE TWS | crop stress, failed demand, restriction events |
| Best for | storage validation (Topic 7) | drought indicators (Topics 1, 6) |

These are complementary views of the same water system, but they are **not
generally reflections of one another**. Storage $X$ and backlog $Q$ are linked
by the served-water flux $S$:

$$\dot Q=D-S-A,\qquad D_{\rm total}=S_{\rm served}+A_{\rm abandoned}+[Q(T)-Q(0)].$$

An independent storage observation constrains $Q$ only if demand, releases and
losses are also observed or modelled. This is an identification problem: a
backlog trajectory alone need not separate demand pressure from supply
constraint.

**Historical anchor.** Moran's dam recursion and Lindley's waiting-time
recursion are the same equation under relabelling:

$$
\text{Lindley: } W_{n+1}=\max(0,\;W_n+B_n-A_n),\qquad
\text{Moran: } X_{n+1}=\min\!\big(K,\;\max(0,\;X_n+I_n-R_n)\big).
$$

Both are reflected random walks; queueing waiting time $W$ and dam storage $X$
are dual state variables. Gani (1957, 1969) and Prabhu (1998) made the
unification explicit. Crucially, hydrology made it explicit too: Langbein
(1958) published "Queuing Theory and Water Storage" in the *Journal of the
Hydraulics Division*. Later hydrological precedents include queueing disciplines
for soil-water residence time (Gamble, Eckstein & Edwards, 1990a, 1990b),
Poisson pulse arrivals for residential water demand (Buchberger & Schade, 1997),
a queueing approach to groundwater management (Batabyal, 1996), queue-based
runoff production (Harel & Mouche, 2013, *WRR*), controlled release in a dam
model (Gordienko & Ruiz de Chávez, 2012), irrigation-capacity design
(Palková & Hennyeyová, 2012), an M/M/1/c model of high river flows (Lefebvre,
2019), stochastic rainwater-harvesting control (Unami et al., 2015), and
well-field supply reliability (Al-Sifao et al., 2026).

**Positioning after the 20 Nov 2026 audit (`literature_audit.md`):** the claim is
**not** that queueing is new to hydrology — it is not. It is that no located
study treats drought as accumulated unmet demand with queue-state indicators,
non-stationary rates learned from hydroclimatic covariates, and pre-specified
validation. Non-stationary queueing itself is mature in operations research
(Galliher & Wheeler 1958; Rothkopf & Oren 1979; Massey & Whitt 1997; Tan et al.
2013; Whitt 2018); we import it. Never write "no one has applied queueing to
water".

## 3. The model to actually fit

Let $Q(t)\in\{0,1,\dots,K_q\}$ be the backlog in claims, discretised for the
CTMC. Let $\lambda(t)$ be the demand-arrival rate and $\mu(t)$ the per-source
clearing rate. Define

$$
\lambda_n(t)=\begin{cases}\lambda(t),&n<K_q,\\0,&n=K_q,\end{cases}
\qquad
S_n(t)=\min(n,c)\,\mu(t)\,[1+(\alpha-1)\mathbf 1(n\ge\theta)],
\qquad
\mu_n(t)=S_n(t)+n\eta.
$$

Here $K_q$ is backlog tolerance, $c$ is the number of genuinely separate supply
sources, $\theta$ is the emergency-service threshold, $\alpha$ is the service
multiplier and $\eta$ is the abandonment rate per waiting claim. At $n=K_q$ all
arrivals are blocked. Blocked and reneged claims are *abandoned demand*, not
served demand.

Forward equation (row form): $\dot{\mathbf p}(t)=\mathbf p(t)\,A(t)$, where
$A(t)$ is the birth–death generator with births $\lambda_n(t)$ and deaths
$\mu_n(t)$.

**Critical bookkeeping rule.** In a conventional queue a reneging customer
leaves the system and is no longer anyone's problem. In drought science that
customer is a *failed irrigation, a shut-off user, a lost crop* — an impact.
Report four separate quantities:

* backlog stock $Q(t)$ [claims];
* backlog exposure $B=\int\mathbb E[Q(t)]dt$ [claim-days];
* served demand $S_{\rm served}=\int\sum_n S_n(t)p_n(t)dt$ [claims];
* abandoned demand $A_{\rm abandoned}=\int[\lambda(t)p_{K_q}(t)+\eta\sum_n n p_n(t)]dt$ [claims].

Then check the ledger
$D_{\rm total}=S_{\rm served}+A_{\rm abandoned}+[Q(T)-Q(0)]$. Collapsing these
quantities into one number is the fastest way to produce a physically
nonsensical drought indicator.

## 4. What queueing gives you that an index does not

For the stationary M/M/1 limit ($\eta=0$, $c=1$, $K\to\infty$, constant rates,
$\rho=\lambda/\mu<1$): $\pi_n=(1-\rho)\rho^n$, $\mathbb E[Q]=\rho/(1-\rho)$,
$\Pr(Q>q)=\rho^{q+1}$, $\mathbb E[W]=1/(\mu-\lambda)$ (Little's law). These are
*baseline references*, not assumptions to impose on data.

| Quantity | Definition | Drought meaning |
|---|---|---|
| $\rho_{\rm nom}(t)=\lambda(t)/(c\mu(t))$ | nominal offered load | proximity to congestion; not exact utilisation when service is state-dependent |
| $\Pr(Q>0)$ | busy probability | drought occurrence probability |
| $Q(t)$ / $\mathbb E[Q]$ | backlog stock [claims] | current deficit severity |
| $B=\int\mathbb E[Q]dt$ | backlog exposure [claim-days] | duration-weighted deficit severity |
| $\mathbb E[W]=1/(\mu-\lambda)$ | stationary M/M/1 mean wait [days] | reference delay; transient waiting-time distribution not yet implemented |
| $T_{q\to0}$ | first-passage time to empty [days] | **recovery time**; current implementation is stationary-only |
| $\Pr(Q\ge q^\*)$ | critical exceedance | failure risk against a tolerance threshold |
| $A_{\rm abandoned}$ | cumulative blocked + reneged demand [claims] | agricultural/ecological impact proxy |

Important caveat: nominal load is a *local* diagnostic. When rates vary in
time, backlog depends on the **history** $\int(\lambda-\mu)\,dt$, so the same
nominal load can imply different $Q$ on the rising and falling limbs of a cycle
(hysteresis). Never use stationary formulae to interpret a transient state.

## 5. Non-stationary solution and verification strategy

1. **Piecewise-constant phases** (seasonal blocks): matrix exponential / exact
   generator solving; good for interpretability.
2. **General time-varying rates**: RK4 or uniformisation on $\dot{\mathbf p}=\mathbf p A(t)$
   (`solve_transient` in the prototype).
3. **Independent check**: Gillespie/thinning discrete-event simulation
   (`simulate_des`); must compute *dwell-time-weighted* means, not means over
   jump epochs (jump-epoch averages are biased toward high-rate states — the
   prototype shows 1.41 vs the correct 0.92).
4. **Analytical limits**: stationary product form and mean first-passage time
   (`stationary`, `mean_recovery_time`) as unit tests.

Solver acceptance criteria for this programme: L1 distance between RK4 and
exact stationary distribution $<10^{-3}$; DES time-average within 2% of exact
over a long run; all probability vectors sum to 1 at every step.

## 6. Estimating $\lambda(t)$ and $\mu(t)$ from CMIP6 + IMD (P02 recipe)

**Historical baseline (IMD, 0.25°):**

* Demand $\lambda$: district crop area × cropped calendar × FAO-56 $K_c$ ×
  reference ET$_0$ (Hargreaves from IMD $T_{\max},T_{\min}$), plus urban/industrial
  withdrawal proxies where available.
* Supply $\mu$: CWC/India-WRIS observed streamflow; baseflow separation from the
  in-development R package; low-flow service capacity referenced to a
  $Q_{95}$/environmental-flow threshold; canal deliveries where recorded.
* Covariates: IMD rain/temperature, GLDAS/ERA5 soil moisture, MODIS VCI,
  catchment attributes (geology, storage, land cover).

**Future (CMIP6):** historical + SSP2-4.5 and SSP5-8.5; variables `pr`, `tas`,
possibly `mrso`/`mrro`; quantile-map/downscale against the IMD baseline;
derive ET$_0$ and demand with the same FAO-56 routine; translate GCM runoff to
$\mu(t)$ either by an offline hydrological model or a transfer function trained
on the historical $\mu$. Propagate GCM and scenario spread as parameter uncertainty.

**Estimators:** gradient-boosted trees (tabular) and recurrent networks
(sequences) with softplus/positive outputs; physical constraints —
$\mu(t)$ monotone non-decreasing in upstream flow, $\lambda(t)$ scaled to match
observed seasonal demand totals; uncertainty by quantile regression or
conformal prediction. Hold out whole drought years and whole basins
(block cross-validation), never random rows.

**Non-stationarity tests before modelling:** time-varying mean/variance of
$\lambda,\mu$; Mann–Kendall/Sen trends on $\rho(t)$; change-point tests; report
departures rather than assuming stationarity. Test Poisson/exponential
assumptions (inter-event times, ACF, overdispersion); if clustered arrivals are
found, move to a Markov-modulated Poisson or phase-type arrival process.

## 7. Guardrails (pre-commit these in the manuscript design section)

1. No assumption of Poisson arrivals, exponential service or stationarity
   without a test and a reported result.
2. Label $K_q$, $\theta$, $\alpha$, $\eta$, claim volume and server structure as
   assumptions until measured or identified.
3. Keep backlog stock, backlog exposure and abandoned demand separate; test the
   conservation ledger.
4. Account for temporal dependence and spatial autocorrelation in estimation
   and validation.
5. Compare against SPI/SPEI/SSI, low-flow duration statistics and the DIE event
   catalogue using **pre-specified** metrics (Brier, lead time, CRPS, MAE).
6. Demonstrate incremental information with ablation; a correlation with an
   existing index is not evidence of superiority.
7. Quantify uncertainty in rates, structural parameters and derived indicators;
   exact solver agreement is not empirical validation.
8. Keep physical-process queues separate from operational allocation queues,
   never publish raw CMIP6 output, and report null or non-identifiable results.

## 8. Box 1 — synthetic demonstration already computed (from `queue_core.py`)

Config: $K_q=20$, $c=2$, $\theta=8$, $\alpha=1.5$, $\eta=0.02$ d$^{-1}$.
**Illustrative, under the stated assumptions.**

* Solver check: exact $\mathbb E[Q]=0.91607$ claims; RK4 $=0.91607$ claims;
  DES time-average $=0.91295$ claims (0.34% error); L1(RK4, exact) $<10^{-5}$.
* Stationary ($\lambda=0.8$, $\mu=1.0$ claims/day): peak $\mathbb E[Q]=0.916$
  claims, $\Pr(Q\ge6)_{\max}=0.0043$, backlog exposure $=668.73$ claim-days,
  abandoned demand $=13.37$ claims.
* Non-stationary with the **same time-mean** rates
  ($\lambda=0.8+0.35\sin(2\pi t/365)$, $\mu=1.0-0.28\sin(2\pi(t-75)/365)$):
  peak $\mathbb E[Q]=2.130$ claims (2.3×), $\Pr(Q\ge6)_{\max}=0.0733$ (17×),
  backlog exposure $=795.01$ claim-days, abandoned demand $=15.90$ claims
  (+18.9%), peak $\lambda/\mu=1.39$. Evaluation is two years after a one-year
  spin-up; $q^*=6$ is illustrative.
* Demand-ledger residual for the non-stationary run: $2.2\times10^{-7}$ claims.
* Mean recovery time from backlog 6 to empty (stationary case): 5.41 days.
* Ramp $\lambda:0.70\to1.15$: peak $\mathbb E[Q]=1.56$ claims, mean
  $\mathbb E[Q]=1.13$ claims, abandoned demand $=24.78$ claims. With $c=2$,
  crossing $\lambda/\mu=1$ is not a universal critical threshold.

**Interpretation for the paper:** averaging a time-varying climate signal can
understate peak congestion by more than a factor of two and critical-risk
probability by more than an order of magnitude in this controlled example.
The documented 44-case grid in `src/P01/box1_sensitivity.py` preserves the direction
of the effect in every case: peak-backlog ratios range from 1.20 to 5.33 and
critical-probability ratios from 2.06 to 92.9, with medians 2.32 and 16.78. The
largest absolute ledger residual is $1.7\times10^{-6}$ claims. This is a
mechanistic reason to test non-stationary queueing for drought, not evidence
about real basins; conclusions outside the declared grid remain untested.

## 9. Open decisions before writing continues

* **Resolved:** P01 is the review/perspective paper; P02 follows (user decision,
  20 Nov 2026). Phase A is complete and Phase B is current.
* **Resolved:** Crossref/OpenAlex, WoS, Scopus and database citation tracing are
  complete; the 25 Nov supplementary search did not change the frozen sentence.
* **Revisable proxy:** one claim = $9\times10^6$ m³ = 20 mm over the 45,000 ha
  Sangli canal-irrigated proxy. Replace it with gauge-specific canal/crop records
  or run the documented sensitivity envelope before physical interpretation.
* Confirm which CMIP6 models, SSPs and IMD products are accessible locally; raw
  CMIP6 output remains unusable until bias correction.
* Broad coupled drought state-space modelling is prior art (Acosta et al. 2026),
  as are non-stationary supply–demand resilience models (Zhao et al. 2018). The
  proposed contribution must stay with queue dynamics, identification, exact
  validation and pre-specified drought tests.
