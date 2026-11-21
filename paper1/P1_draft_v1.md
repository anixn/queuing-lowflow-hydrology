# P1 — Working draft v1 (20 November 2026)

> **Status.** Revision of `P1_draft_v0.md` after the literature audit in
> `literature_audit.md`. The central change is that queueing is **not** new to
> hydrology: Langbein published "Queuing Theory and Water Storage" in the
> *Journal of the Hydraulics Division* in 1958. The review now reclaims and
> updates that lineage rather than claiming to discover it. Box 1 results are
> synthetic (`src/queue_core.py`), not observational. Items marked **[VERIFY]**
> still need checking (see audit §"Required before submission").

---

## Dams, queues and droughts: reclaiming storage theory for deficit-accumulation drought science

**Ankit Deshmukh**
Department of Civil Engineering, Pandit Deendayal Energy University, Gandhinagar, India

### Abstract (draft, 268 words)

Hydrological drought is conventionally diagnosed with standardized indices that
locate an anomaly relative to climatology. They describe *when* water is scarce
but not *how* unmet demand accumulates, how long a system takes to clear a
deficit, or which part of a shortage arose from arrival pressure rather than
constrained supply. These are mechanism-level questions, and queueing theory is
the mathematics built to answer them. The connection is older than the modern
index literature: Langbein's "Queuing Theory and Water Storage" appeared in the
*Journal of the Hydraulics Division* in 1958, Moran and Gani developed the
parallel theory of dams and storage, and Prabhu unified queues, insurance risk
and dams as stochastic storage processes. Hydrology nevertheless moved toward
conceptual rainfall–runoff models and standardized indices, leaving the
stochastic machinery to operations research and to a thin applied niche
(runoff generation, rainwater harvesting, high-flow forecasting, water-supply
reliability). This perspective synthesises that lineage and asks what it would
take to bring it back for drought. We set out the two dual representations —
stored water as the buffer, unmet demand as the backlog — and the state
variables they imply: backlog, utilisation, waiting time, first-passage recovery
time and abandoned demand. We distinguish stationary textbook limits from the
non-stationary formulation that a changing climate requires, and show with a
controlled synthetic experiment that a time-varying queue with the same mean
arrival and service rates as a stationary one can produce a 2.3-fold larger
peak backlog and a 17-fold larger probability of critical backlog: averaging
the climate signal hides risk. The novelty we claim is narrow and defensible —
not stochastic storage theory, and not time-varying queueing in general, but a
drought-specific, machine-learned parameterisation of a non-stationary deficit
queue whose indicators must earn their place against standard indices under
pre-specified tests.

---

## 1. Introduction

Drought is usually introduced as a hazard of *deficit*: precipitation below a
climatological norm, soil moisture below an expectation, streamflow below an
exceedance threshold. The index tradition — the Standardized Precipitation Index
(McKee et al., 1993), the Standardized Precipitation Evapotranspiration Index
(Vicente-Serrano et al., 2010), and their hydrological counterparts — made
drought comparable across places and time. It also fixed the intellectual frame:
a drought is an anomaly to be measured, and propagation is studied through lags
and correlations between anomaly series (van Loon, 2015).

That frame has a blind spot. Water scarcity becomes damaging not when an
anomaly is first detected but when **demand that cannot be met accumulates
faster than supply can clear it**. Two catchments with the same rainfall deficit
can diverge sharply: one has storage and reliable delivery, the other does not.
The difference is not an anomaly magnitude; it is a service-capacity constraint
and a backlog trajectory. Standardized indices do not represent that backlog,
do not give recovery time as a model output, and do not separate shortage caused
by unusually high demand pressure from shortage caused by degraded supply. They
can tell us that a drought is occurring; they cannot tell us how long the system
will need to dig itself out, or how much demand will be abandoned along the way.

Queueing theory is the mathematics of arrival streams, finite service capacity,
congestion and waiting. Its core objects — queue length, busy period, waiting
time, utilisation, loss probability — are the objects a drought manager is
implicitly asking for when they ask how severe a shortage is, when it will end,
and who will be cut off. The connection is not a metaphor imposed from outside,
and it is not new. Langbein (1958) set out "Queuing Theory and Water Storage" in
this journal's predecessor, the *Journal of the Hydraulics Division*, with a
discussion and closure following in 1959. In probability theory Moran (1954) and
Gani (1957, 1969) built the theory of dams as random storage systems; Prabhu
(1998) unified queues, insurance risk and dams as stochastic storage processes.
Hydrology then diverged: conceptual rainfall–runoff models, standardized
indices, distributed models. The queueing line survived in operations research
and in a small set of hydrological applications, discussed in Section 2.3.
What has not happened is the operationalisation of that machinery for drought
deficit accumulation with modern data, non-stationary rates and interpretable
risk indicators.

This perspective makes four contributions. First, it states the mapping between
queueing mechanisms and drought processes precisely enough to be implemented,
including the awkward cases — abandonment, blocked demand, state-dependent
emergency supply — that a naive analogy would mishandle. Second, it separates
the two dual state variables, stored water and unmet demand, and shows which
observational datasets constrain each. Third, it demonstrates with a controlled
synthetic experiment why stationarity is not a harmless simplification for
drought under climate change. Fourth, it sets out a falsifiable research
programme: if queue-derived indicators cannot beat standard indices under
pre-specified tests on held-out basins and events, the programme should report
that result rather than reinterpret it.

## 2. The mapping: from dams and queues to drought

### 2.1 Mechanism-level correspondence

The practical motivation comes from a queueing model of electric-vehicle
charging stations (Varshney et al., 2025): a finite-population, multi-server
continuous-time Markov chain with state-dependent service thresholds, balking,
reneging and feedback. Each mechanism has a drought analogue, and the analogy
is structural rather than decorative:

| Queueing mechanism | Drought-system interpretation |
|---|---|
| Arrival rate $\lambda$ | Crop water requirement, withdrawals, environmental-flow claims |
| Multi-server service $\mu$ | Streamflow release, canal delivery, groundwater — parallel supply sources |
| Finite capacity $K$ | Reservoir, soil profile, aquifer, conveyance or tolerance limit |
| State-dependent service threshold | Emergency releases, extra pumping, drought-mode operation |
| Reneging $\eta$ | Demand abandoned: crop failure, demand shedding, use migration |
| Balking | Irrigation skipped because supply is known to be absent |
| Feedback $\xi$ | Re-irrigation attempts; carry-over deficit into the next season |

### 2.2 Two dual representations

**Stored water as customers (the supply-buffer view).** Inflows and recharge
arrive; withdrawals and releases are service; storage is the buffer. An empty
buffer is supply starvation, the moment at which a hydrological drought begins
to bite. This is the classical dam problem (Moran, 1954; Prabhu, 1998) and it is
the right representation when the observations are reservoir levels,
soil-moisture anomalies or GRACE terrestrial-water-storage anomalies.
Queueing disciplines have already been used to interpret soil-water residence
time from water-budget data (e.g. the two 1990 *Journal of Hydrology* papers by
Mary and colleagues — **[VERIFY full author list and exact titles]**).

**Unmet demand as customers (the deficit view).** Demand claims arrive;
available supply clears them; the backlog is accumulated unmet demand. A
nonempty backlog is a drought state, its time integral is a severity measure,
and its excursion length is a duration. This representation is the right one
for agricultural drought, where the outcome is the portion of crop water
requirement that was never satisfied. Demand-as-arrivals also has hydrological
precedent in the Poisson pulse model of residential water demands (1997 —
**[VERIFY full record]**).

The two views are complementary. With $X(t)$ denoting storage and $Q(t)$ the
shortfall relative to a supply target, $Q$ is essentially the reflection of
$X$; the relationship is a change of reflection and capacity convention, not a
new model. Keeping both views is what allows a queue-derived deficit indicator
to be checked against an independent storage observation — a validation
strategy unavailable to an index with no state variable at all.

### 2.3 Prior art: the queueing niche in hydrology is thin, not empty

A scoping search of Crossref and OpenAlex (20 November 2026; protocol and
queries in the accompanying audit) found a small but real body of work. It must
be cited, both for accuracy and because it makes the contribution sharper.

| Work | Representation | What it leaves open |
|---|---|---|
| Langbein (1958), "Queuing Theory and Water Storage", *J. Hydr. Div.* 84(5) | Explicit queue–storage analogy in a hydraulics journal | Stationary framing; no drought indicators; no modern data |
| Harel & Mouche (2013), *Water Resources Research*, 1-D steady-state runoff production in light of queuing theory | Steady runoff–runon equation as single-server waiting time; heterogeneity and connectivity | Steady state, no temporal non-stationarity, no deficit accounting |
| Lefebvre (2019), *Atti della Accademia Peloritana dei Pericolanti*, M/M/1/c model of river flow above a threshold | Finite birth–death CTMC for **high** flows, Delaware River | High flow rather than low flow; stationary rates; no unmet-demand accounting |
| Unami et al. (2015), stochastic control of rainwater harvesting | Storage control for irrigation in dry spells | Small-system, stationarity typical |
| 2012 GI/D/1 dam-release control study **[VERIFY]** | State-dependent service in a simple dam model | No data-driven rate estimation; no drought validation |
| 2026 well-field reliability study **[VERIFY]** | Queueing for groundwater supply reliability | Reliability of supply, not multi-year deficit backlogs or GRACE validation |

Three conclusions follow. First, the *mathematics* is not novel, and neither is
its use in hydrology. Second, the existing applications cluster around runoff,
storage, high flows and supply reliability; we found no study in the searched
indexes that treats drought as an accumulated unmet-demand backlog with
queue-state indicators, and none that learns non-stationary arrival and service
rates from hydroclimatic covariates under physical constraints. Third, the
review's job is therefore synthesis plus a precise gap statement, not a claim
to have invented the junction.

### 2.4 The shared recursion

The historical claim rests on an identity. Lindley's waiting-time recursion for
the GI/G/1 queue and Moran's dam recursion are, up to notation and reflection,
the same equation:

$$W_{n+1}=\max(0,\;W_n+B_n-A_n),\qquad
X_{n+1}=\min\!\big(K,\;\max(0,\;X_n+I_n-R_n)\big).$$

Here $B_n$ is the work brought by the $n$th claim, $A_n$ the service opportunity
before the next claim, $I_n$ inflow and $R_n$ release. In continuous time the
corresponding fluid limit is $\dot Q=[\lambda(t)-\mu(t)]$ reflected at zero and,
with finite tolerance, at $K$. Everything that makes drought hard — episodic
supply, seasonal demand, finite storage, abandonment — is a term queueing theory
has already learned to put inside this recursion.

## 3. What the queue state gives you

For the stationary M/M/1 benchmark, with $\rho=\lambda/\mu<1$, the backlog has
geometric stationary distribution $\pi_n=(1-\rho)\rho^n$, mean
$\mathbb E[Q]=\rho/(1-\rho)$, exceedance $\Pr(Q>q)=\rho^{q+1}$, and mean waiting
time $\mathbb E[W]=1/(\mu-\lambda)$ by Little's law. These formulae are useful as
*unit tests and reference limits*, not as assumptions to impose on rivers.
Real demand is clustered rather than Poisson, supply is weather-driven and
non-exponential, and climate change makes both rates time-varying. The
programme's guardrails require testing those assumptions and reporting
departures.

The general finite-state formulation is a birth–death CTMC. For backlog
$n\in\{0,\dots,K\}$ let

$$\lambda_n(t)=\lambda(t)\,[1-\mathrm{balk}(n)],\qquad
\mu_n(t)=\min(n,c)\,\mu(t)\,[1+(\alpha-1)\mathbf 1(n\ge\theta)]+n\eta,$$

where $c$ is the number of parallel supply sources, $\theta$ and $\alpha$
parameterise drought-mode service, and $\eta$ is abandonment per waiting claim.
The forward equation $\dot{\mathbf p}=\mathbf p A(t)$ yields the full
distribution, from which the indicators in Table 3 follow.

| Indicator | Expression | Management question |
|---|---|---|
| Utilisation | $\rho(t)=\lambda(t)/\mu(t)$ | How close is the system to chronic congestion? |
| Occurrence | $\Pr(Q>0)$ | How likely is a shortage state? |
| Severity | $\mathbb E[Q]$, $\Pr(Q\ge q^*)$ | How much demand is unmet; is a tolerance exceeded? |
| Delay | $\mathbb E[W]=\mathbb E[Q]/\lambda_{\rm eff}$ | How long before demands are served? |
| Recovery | $\mathbb E[T_{q\to0}]$ | How long after a severe deficit until normal service? |
| Impact | $U=\int$[blocked + abandoned demand]$dt$ | How much demand was never met? |

One bookkeeping rule deserves emphasis. In operations research, a customer who
reneges leaves the system and ceases to be a performance concern. In drought
science that customer is a failed irrigation or a shut-off user: an *impact*.
Served demand and abandoned demand must therefore be reported separately, and
the abandonment flux is part of the drought severity accounting. Conflating
them produces an indicator that can improve while the harm it is meant to
measure worsens.

## 4. Why non-stationarity is not a detail

Time-varying queueing is itself a mature subject: early work on non-stationary
landing congestion (Galliher & Wheeler, 1958), closure approximations for
non-stationary M/M/s (Rothkopf & Oren, 1979), peak congestion under slowly
varying arrival rates (Massey & Whitt, 1997), finite-capacity queues with
time-dependent arrivals (Tan et al., 2013), and the modern synthesis of
time-varying queues (Whitt, 2018). We import that machinery; we do not claim to
invent it. The hydrological contribution is to estimate the time-varying rates
from physical covariates and to interpret the resulting state as drought risk.

When $\lambda$ and $\mu$ vary, the stationary formulae no longer apply. For
piecewise-constant rates the solution can be assembled phase by phase; for
general time-varying rates we solve $\dot{\mathbf p}=\mathbf p A(t)$ numerically
and verify against an independent discrete-event simulation. The instantaneous
ratio $\rho(t)$ is a useful local warning signal, but it is not a complete
description: backlog depends on the integrated history $\int(\lambda-\mu)\,dt$,
so the same $\rho$ can correspond to different backlogs on the rising and
falling limbs of a seasonal cycle. Non-stationary queues have hysteresis.

### Box 1. A synthetic demonstration of the averaging error

We solved the finite queue with $K=20$, $c=2$, $\theta=8$, $\alpha=1.5$ and
$\eta=0.02\,\mathrm{d}^{-1}$. The solver was checked three ways: exact stationary
product form $\mathbb E[Q]=0.91607$, RK4 integration of the forward equations
$0.91607$, and an independent Gillespie simulation $0.91295$ (0.34% error; L1
distance between RK4 and exact distribution $<10^{-5}$).

Two runs shared the same time-mean rates, $\bar\lambda=0.8$ and $\bar\mu=1.0$.
The stationary run held those rates constant. The non-stationary run imposed a
seasonal demand peak and a lagging dry-season service dip,
$\lambda(t)=0.8+0.35\sin(2\pi t/365)$ and
$\mu(t)=1.0-0.28\sin(2\pi(t-75)/365)$.

| Quantity | Stationary | Non-stationary | Ratio |
|---|---:|---:|---:|
| Peak $\mathbb E[Q]$ | 0.916 | 2.130 | 2.3× |
| Peak $\Pr(Q\ge6)$ | 0.0043 | 0.0733 | 17× |
| Unmet demand $U$ (3 yr) | 15.05 | 16.79 | +11.6% |
| Peak $\rho$ | 0.80 | 1.39 | — |

A further ramp experiment with $\lambda$ rising from 0.70 to 1.15 across
$\rho=1$ reproduced the expected critical transition: mean backlog rose to 1.56
and cumulative unmet demand to 24.78. Averaging a time-varying climate signal
therefore understates peak congestion and critical-risk probability, sometimes
dramatically. These are synthetic proof-of-concept numbers; establishing the
effect in real basins is an empirical task for the accompanying papers.

## 5. A research programme built on the mapping

The queueing object becomes useful when $\lambda(t)$ and $\mu(t)$ are estimated
from data and projected under climate change. The historical baseline can use
IMD gridded rainfall and temperature (0.25°), district crop-area and cropping-
calendar statistics, FAO-56 crop coefficients and reference evapotranspiration
to construct $\lambda(t)$, and CWC/India-WRIS streamflow, baseflow separation and
canal records to construct $\mu(t)$. Public reanalysis, remote sensing and
catchment attributes supply covariates: ERA5/ERA5-Land, GLDAS soil moisture,
MODIS vegetation indices and physiographic attributes from the comparative
hydrology tradition (Deshmukh & Singh, 2016, 2019). Future rates come from
CMIP6 historical and SSP scenarios, bias-corrected against the IMD baseline,
with ensemble spread carried through as uncertainty.

The estimation strategy is deliberately not "predict the index". Gradient-
boosted trees and recurrent networks estimate the *parameters of an
interpretable stochastic process*, $\lambda(t)=f_\theta(\mathbf x_t)$ and
$\mu(t)=g_\phi(\mathbf z_t)$, subject to physical constraints: positive rates,
monotone dependence of $\mu$ on upstream flow, and calibration of $\lambda$
against observed seasonal demand totals. Quantile or conformal variants give
prediction intervals. The resulting queue state is read as a drought-risk
object, and the indicators are tested against SPI/SPEI/SSI, low-flow duration
statistics and the event catalogue of the Drought Intelligence Explorer
(Deshmukh, 2026).

Three applications follow. Agricultural drought is accumulated unmet crop-water
demand under constrained irrigation supply. Low-flow hydrological drought is a
streamflow-mediated service-capacity problem, with baseflow as the dry-season
workhorse and catchment attributes controlling queue behaviour (Deshmukh &
Singh, 2016, 2019). Groundwater drought is the slow queue: episodic recharge
arrivals, continuous extraction claims and a service rate that degrades as
heads fall, where GRACE/GRACE-FO storage anomalies provide an independent check
on the storage-state representation. Operational allocation queues — irrigation
scheduling and reservoir rule curves — are related but physically different
objects and are kept in a separate strand.

## 6. Guardrails and falsifiability

This programme pre-commits to six rules. Do not assume Poisson arrivals,
exponential service or stationarity without testing and reporting. Account for
temporal dependence and spatial autocorrelation in estimation and validation.
Compare queue-derived indicators with established indices under pre-specified
metrics on held-out events and basins, and demonstrate incremental information
by ablation. Quantify uncertainty in both estimated rates and all derived
indicators. Keep physical-process queues and operational allocation queues
visibly separate. Never claim a new indicator is superior on the basis of
correlation with an existing index alone.

The last rule is the most important, because indicator literature makes it easy
to produce a new quantity that merely re-labels an old one. The queueing
formulation is only worth publishing if it changes a decision: earlier warning,
a better estimate of recovery time, or an attributable split between demand
pressure and supply constraint. If the ablation shows no such gain, the correct
result is a null result, and the review should say so. **[VERIFY: complete
Scopus/Web of Science search and forward-citation tracing of Langbein 1958,
Harel & Mouche 2013 and Lefebvre 2019 before submission.]**

## 7. Conclusion

Storage theory was queueing theory before the two disciplines drifted apart —
and hydrology said so explicitly in 1958. Drought science has kept the
bookkeeping of shortage but lost the mechanism: indices measure anomalies, not
the accumulation of unmet demand under a finite, weather-driven service process.
Rejoining the two lets drought be described as a queue state with interpretable
backlog, waiting time, recovery time and abandoned-demand quantities, and lets
machine learning estimate the parameters of that process rather than replace it
with a black-box forecast. The claim is deliberately narrow: the mathematics is
old, the hydrological niche is real but thin, and the value of extending it to
non-stationary, data-driven drought risk must be demonstrated with pre-specified
tests on independent data. That is the work the accompanying papers undertake.

---

## References (draft; all DOIs below verified via Crossref/OpenAlex on 20 Nov 2026 unless marked)

Deshmukh, A. (2026). Drought Intelligence Explorer: a 45-year district-level
dataset of ten drought indicators for India and an open analytical platform.
*EarthArXiv*. [from `../citations.txt`; verify venue/DOI]

Deshmukh, A., & Singh, R. (2016). Physio-climatic controls on vulnerability of
watersheds to climate and land use change across the United States. *Water
Resources Research*, 52(11), 8775–8793. https://doi.org/10.1002/2016WR019189

Deshmukh, A., & Singh, R. (2019). A Whittaker biome-based framework to account
for the impact of climate change on catchment behavior. *Water Resources
Research*, 55(12), 11208–11224. https://doi.org/10.1029/2018WR023113

Galliher, H. P., & Wheeler, R. C. (1958). Nonstationary queuing probabilities for
landing congestion of aircraft. *Operations Research*, 6(2), 264–277.
https://doi.org/10.1287/opre.6.2.264

Gani, J. (1957). Problems in the probability theory of storage systems. *Journal
of the Royal Statistical Society: Series B*, 19.

Gani, J. (1969). Recent advances in storage and flooding theory. *Advances in
Applied Probability*, 1.

Harel, M.-A., & Mouche, E. (2013). 1-D steady state runoff production in light of
queuing theory: Heterogeneity, connectivity, and scale. *Water Resources
Research*. https://doi.org/10.1002/2013WR013596

Langbein, W. B. (1958). Queuing theory and water storage. *Journal of the
Hydraulics Division*, 84(5), 1–24. https://doi.org/10.1061/JYCEAJ.0000222

Lefebvre, M. (2019). An application of queueing theory in hydrology. *Atti della
Accademia Peloritana dei Pericolanti*, 97(S2).
https://doi.org/10.1478/aapp.97s2a18

Massey, W. A., & Whitt, W. (1997). Peak congestion in multi-server service
systems with slowly varying arrival rates. *Queueing Systems*, 25.
https://doi.org/10.1023/a:1019156418862

McKee, T. B., Doesken, N. J., & Kleist, J. (1993). The relationship of drought
frequency and duration to time scales. In *Proceedings of the Eighth Conference
on Applied Climatology* (pp. 179–184). AMS.

Moran, P. A. P. (1954). A probability theory of dams and storage systems.
*Australian Journal of Applied Science*, 5, 116–124.

Prabhu, N. U. (1998). *Stochastic storage processes: Queues, insurance risk, and
dams* (2nd ed.). Springer.

Rothkopf, M. H., & Oren, S. S. (1979). A closure approximation for the
nonstationary M/M/s queue. *Management Science*, 25(6), 522–534.
https://doi.org/10.1287/mnsc.25.6.522

Tan, X., Knessl, C., & Yang, Y. P. (2013). On finite capacity queues with time
dependent arrival rates. *Stochastic Processes and their Applications*.
https://doi.org/10.1016/j.spa.2013.02.002

Unami, K., Mohawesh, O., Sharifi, E., et al. (2015). Stochastic modelling and
control of rainwater harvesting systems for irrigation during dry spells.
*Journal of Cleaner Production*, 88, 185–195.

van Loon, A. F. (2015). Hydrological drought explained. *Water Resources
Research*, 51(6), 4067–4092. https://doi.org/10.1002/2015WR017141

Varshney, S., Panda, K. P., Shah, M., Srinivas, B. A., Deshmukh, A., Choudhary,
K. K., Bajaj, M., Prokop, L., & Rubanenko, O. (2025). Novel control strategies
for electric vehicle charging stations using stochastic modeling and queueing
analysis. *Scientific Reports*, 15, 21391.
https://www.nature.com/articles/s41598-025-04725-7

Vicente-Serrano, S. M., Beguería, S., & López-Moreno, J. I. (2010). A multiscalar
drought index sensitive to global warming: The Standardized Precipitation
Evapotranspiration Index. *Journal of Climate*, 23(7), 1696–1718.
https://doi.org/10.1175/2009JCLI2909.1

Whitt, W. (2018). Time-varying queues. In *Queueing Theory and Network
Applications* (Springer). [OpenAlex record W3170396656; verify exact venue]

**Still to verify:** the 1990 soil-water residence-time papers, the 1997
residential water-demand paper, the 2012 dam-release control paper, the 2026
well-field reliability paper, and recovery-time/first-passage literature in
hydrology. See `literature_audit.md`.
