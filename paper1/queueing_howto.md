# How to use queueing theory for drought: a working note (v1, 21 Nov 2026)

Purpose: the technical core that Paper 1 explains and Paper 3 will implement.
Everything below is a *proposal*, not a published result. Numbers in Box 1 are
reproducible with `src/queue_core.py` and are synthetic, not observational.
Reference details were verified on 20–21 Nov 2026; see `literature_audit.md`.
Rate-construction code skeletons are in `src/data_pipeline.py`.

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
| Empty buffer | **supply starvation** = drought onset | $Q=0$ = no drought |
| Full buffer | spill / rejected recharge | $Q=K$ = demand shedding (balking) |
| Observable proxy | reservoir level, soil moisture, GRACE TWS | crop stress, failed demand, restriction events |
| Best for | storage validation (Topic 7) | drought indicators (Topics 1, 6) |

These are complementary views of the same water balance, related by a
reflection/capacity convention: $Q$ is essentially the *shortfall* relative to
the storage target, while $X$ is the *contents*. Paper 1 should make this
duality explicit — it is the cleanest way to connect the drought-indicator
literature (deficits) with the storage/GRACE literature (contents).

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

Let $Q(t)\in\{0,1,\dots,K\}$ be the backlog (in volume units, discretised for
the CTMC). Let $\lambda(t)$ be the admitted-demand arrival rate and $\mu(t)$
the per-server clearing rate. Define state-dependent rates

$$
\lambda_n(t)=\lambda(t)\,(1-\text{balk}(n)),\qquad
\mu_n(t)=\underbrace{\min(n,c)\,\mu(t)\,\big[1+(\alpha-1)\mathbf{1}(n\ge\theta)\big]}_{\text{supply / drought-mode service}}+\underbrace{n\,\eta}_{\text{reneging}},
$$

with $K$ = maximum trackable backlog, $c$ = parallel supply sources, $\theta$ =
backlog at which emergency service turns on, $\alpha$ = service multiplier,
$\eta$ = abandonment rate per waiting claim. At $n=K$ arrivals are blocked:
blocked and reneged claims are *abandoned demand*, not served demand.

Forward equation (row form): $\dot{\mathbf p}(t)=\mathbf p(t)\,A(t)$, where
$A(t)$ is the birth–death generator with births $\lambda_n(t)$ and deaths
$\mu_n(t)$.

**Critical bookkeeping rule.** In a conventional queue a reneging customer
leaves the system and is no longer anyone's problem. In drought science that
customer is a *failed irrigation, a shut-off user, a lost crop* — an impact.
Therefore report two separate loss totals:

* served demand $\int\sum_n \mu_n^{\text{service}}p_n(t)\,dt$
* abandoned/unmet demand $U=\int\big[\lambda(t)\,\text{balk}(K)p_K(t)+\eta\sum_n n\,p_n(t)\big]dt$

Collapsing these into one number is the fastest way to produce a physically
nonsensical drought indicator.

## 4. What queueing gives you that an index does not

For the stationary M/M/1 limit ($\eta=0$, $c=1$, $K\to\infty$, constant rates,
$\rho=\lambda/\mu<1$): $\pi_n=(1-\rho)\rho^n$, $\mathbb E[Q]=\rho/(1-\rho)$,
$\Pr(Q>q)=\rho^{q+1}$, $\mathbb E[W]=1/(\mu-\lambda)$ (Little's law). These are
*baseline references*, not assumptions to impose on data.

| Quantity | Definition | Drought meaning |
|---|---|---|
| $\rho(t)=\lambda(t)/\mu(t)$ | traffic intensity | proximity to chronic congestion; **warning signal** |
| $\Pr(Q>0)$ | busy probability | drought occurrence probability |
| $\mathbb E[Q]$ | mean backlog | deficit severity |
| $\mathbb E[W]=\mathbb E[Q]/\lambda_{\text{eff}}$ | mean wait | delay to demand satisfaction |
| $T_{q\to0}$ | first-passage time to empty | **recovery time** |
| $\Pr(Q\ge q^\*)$ | critical exceedance | failure risk against a tolerance threshold |
| $U$ | cumulative abandoned demand | agricultural/ecological impact proxy |

Important caveat: $\rho(t)$ is a *local* diagnostic. When rates vary in time,
backlog depends on the **history** $\int(\lambda-\mu)\,dt$, so the same
$\rho$ can imply different $Q$ on the rising and falling limbs of a cycle
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

## 6. Estimating $\lambda(t)$ and $\mu(t)$ from CMIP6 + IMD (P3 recipe)

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
2. Account for temporal dependence and spatial autocorrelation in estimation
   and validation.
3. Compare against SPI/SPEI/SSI, low-flow duration statistics and the DIE event
   catalogue using **pre-specified** metrics (AUC, Brier, lead time, CRPS).
4. Demonstrate incremental information with ablation; a correlation with an
   existing index is not evidence of superiority.
5. Quantify uncertainty in $\lambda(t)$, $\mu(t)$ and every derived indicator.
6. Keep physical-process queues (Topics 1, 6, 7) separate from operational
   allocation queues (deferred Topics 3, 4).
7. Cite the prior art — Langbein (1958), Harel & Mouche (2013), Lefebvre (2019),
   Unami et al. (2015) — and state the gap relative to it, never in ignorance
   of it.

## 8. Box 1 — synthetic demonstration already computed (from `queue_core.py`)

Config: $K=20$, $c=2$, $\theta=8$, $\alpha=1.5$, $\eta=0.02$ d$^{-1}$.

* Solver check: exact $\mathbb E[Q]=0.91607$; RK4 $=0.91607$; DES time-average
  $=0.91295$ (0.34% error); L1(RK4, exact) $=0.00000$.
* Stationary ($\lambda=0.8$, $\mu=1.0$, $\rho=0.8$): peak $\mathbb E[Q]=0.916$,
  $\Pr(Q\ge6)_{\max}=0.0043$, unmet $U=15.05$.
* Non-stationary with the **same time-mean** rates
  ($\lambda=0.8+0.35\sin(2\pi t/365)$, $\mu=1.0-0.28\sin(2\pi(t-75)/365)$):
  peak $\mathbb E[Q]=2.13$ (2.3×), $\Pr(Q\ge6)_{\max}=0.073$ (17×),
  $U=16.79$ (+11.6%), peak $\rho=1.39$.
* Mean recovery time from backlog 6 to empty (stationary case): 5.41 days.
* Critical-transition ramp $\lambda:0.70\to1.15$: $\mathbb E[Q]$ rises to 1.56
  and $U$ to 24.78 as the system crosses $\rho=1$.

**Interpretation for the paper:** averaging a time-varying climate signal can
understate peak congestion by more than a factor of two and critical-risk
probability by more than an order of magnitude. That is the mechanistic reason
non-stationary queueing matters for drought under climate change. It is a
synthetic proof of concept, not evidence about real basins.

## 9. Open decisions before writing continues

* **Resolved:** P1 is the review/perspective paper; P3 follows (user decision,
  20 Nov 2026).
* **Partly resolved:** a Crossref/OpenAlex audit found the prior art and
  narrowed the novelty claim (see `literature_audit.md`). Scopus/WoS,
  forward-citation tracing and full-text screening are still required.
* Decide the unit of the claim (one claim/event per day vs per irrigation
  event); it affects every rate interpretation.
* Confirm which CMIP6 models, SSPs and IMD products are already accessible locally.
* Revise the roadmap's own screening claims: candidate 2 (runoff queueing) has
  prior art (Harel & Mouche 2013), and groundwater queueing has a 2026 well-field
  reliability precedent. Re-entry conditions should reflect this.
