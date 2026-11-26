# Data and methods

We read agricultural water shortage as a queue: irrigation demand arrives as
customers, river or reservoir supply serves them, unmet demand accumulates as a
backlog $Q$ in *claims*, capacity $K$ bounds the backlog, and long-waiting demand
abandons the system (reneging). The queue yields quantities that standard indices
do not report, and those quantities are tested against an established streamflow
drought index on identical held-out months. All
parameters below are fixed in the predeclared protocol (tag
`protocol-v2-locked`, 26 November 2026) before any held-out result was computed.

## 1. Study design and hypotheses

### 1.1 Two confirmatory endpoints

**E1 (concurrent)** asks whether queue indicators from month $m$ improve the
probabilistic prediction of a drought state in the same month $m$. **E2
(prospective)** asks the same with a one-month lead: predictors at month $m-1$,
outcome at month $m$. For outcome $y_m \in \{0,1\}$ and predicted probability
$p_m \in [0,1]$, skill is scored by the Brier score

$$
B = \frac{1}{M}\sum_{m=1}^{M}\left(p_m - y_m\right)^{2}
$$

over $M$ scored months (dimensionless; lower is better). For each site $g$ the
confirmatory statistic is the **paired** per-site difference

$$
\Delta_g = B_g\left(\text{SSI-3}\right) - B_g\left(\text{SSI-3} + \text{queue}\right),
$$

evaluated on the *same* held-out months for both families, so $\Delta_g > 0$
means the queue helps at that site. The hypotheses are

$$
H_0:\ \operatorname{median}_g \Delta_g \le 0,
\qquad
H_1:\ \operatorname{median}_g \Delta_g > 0 ,
$$

and $H_0$ is rejected only if all four predeclared rules hold: (i)
$\operatorname{median}_g \Delta_g > 0$; (ii) the 95 % two-level bootstrap
interval of that median excludes zero; (iii) a one-sided sign test gives
$p < 0.05$ with improvement in at least 60 % of sites; and (iv) no site breaches
the harm bound $\Delta_g < -0.005$ through calibration breakdown. E2 applies the
same four rules to the lagged contrast. Because the statistic is paired, no two
families are ever compared on different samples; per-family metrics on
family-specific complete-case samples are descriptive only.

### 1.2 The utilisation screen

A queue informs only when it is neither always empty nor always full. For each
site we compute the utilisation ratio over verified days,

$$
\rho = \frac{\sum_t \lambda_t}{\sum_t \mu_t},
$$

with $\lambda_t$ and $\mu_t$ the demand and supply rates in claims per day (§3).
A site enters only if $0.15 \le \rho \le 1.20$. The lower bound removes the
degenerate regime where the backlog is almost always empty and a null is
guaranteed; the project's earlier single-catchment pilot sat at
$\rho \approx 0.02$–$0.08$ and was uninformative for this reason.
The upper bound removes sites pinned near capacity, where the queue adds no state
information. Screening precedes endpoint evaluation; no site is added or dropped
afterwards.

### 1.3 Splits and events

For the Indian catchments, train is 1981–2010 and test 2011–2020, with features
standardised on training rows only. For the US pilot, train is 2000–2012 and test
2013–2020. A drought *event* is at least two consecutive target months below
threshold; isolated monthly hits are still scored and reported separately.

## 2. Data

### 2.1 India: CAMELS-IND catchments and district drought indices

Daily catchment-mean forcings (precipitation, potential evapotranspiration and
minimum, maximum and mean temperature), observed daily streamflow $Q$
(m$^3$ s$^{-1}$) and attributes (area, river basin, CWC coordinates) come from
CAMELS-IND (Mangukiya et al., 2025, *Earth System Science Data*, 17, 461–491,
doi:10.5194/essd-17-461-2025; Zenodo record 14999580, CC BY 4.0). The working
grid is daily, 1 January 1981 to 31 December 2020. `[assumption]` GLEAM potential
evapotranspiration is primary; Hargreaves–Samani PET with the FAO-56 0.408
radiation conversion is the predeclared alternative (sensitivity axis).
District-scale soil-moisture anomaly, SPI-3, SPEI-3 and district polygons come
from the Drought Intelligence Explorer v2; gauges are assigned to districts by
point-in-polygon matching of their CWC coordinates.

`[measurement]` Gauges are admitted under five rules, all required: (1) profiled,
i.e. at least 300 observed flow days with the necessary forcings; (2)
$0.15 \le \rho \le 1.20$ under the primary supply variant; (3) zero-flow fraction
below 0.30 and longest interior gap at most 30 days; (4) at least 3 years of flow
in 1981–2010 *and* at least 2 years in 2011–2020; and (5) at most three gauges
per basin, ranked by the smaller of the two period coverages, to limit
within-basin dependence. Applied in that order to the 472 CAMELS-IND gauges
carrying a streamflow column, the funnel is Table 1.

**Table 1.** Screening funnel for the Indian analysis set.

| Step | Gauges |
|---|---:|
| CAMELS-IND gauges with a streamflow column | 472 |
| Profiled (≥ 300 flow days and forcings present) | 279 |
| Inside the utilisation window (SUP-1) | 212 |
| Data-quality screen (zero fraction, interior gap) | 40 |
| Both-period coverage, ≤ 3 gauges per basin | 24 |

`[measurement]` The 24 gauges span 11 basins: Brahmani-Baitarani (3), Cauvery
(2), EFRN (Eastern Flowing Rivers North, 1), Godavari (3), Krishna (3), Mahanadi
(2), Mahi (3), Narmada (1), Pennar (1), Subernarekha (2) and WFRS (Western
Flowing Rivers South, 3); their $\rho$ ranges 0.152–1.164. The predeclared gate
required at least 15 gauges in the window, which 24 satisfy.

**Targets.** The primary target (T1) is the district soil-moisture anomaly, a
drought month being an anomaly at or below $-15\,\%$. `[measurement]` The
external product anomalies against its own 1981–2020 climatology, which overlaps
the test years; this leakage is disclosed, not hidden. The leakage-clean
sensitivity (T1-strict) instead uses a training-only SPI-3 target,
$\text{SPI-3} \le -1$ standardised on 1981–2010, and drops the `spi3` predictor
from every family so the target cannot be rebuilt from a covariate.

**Zero flows and gaps.** `[measurement]` Each zero-flow day is classified
`positive`, `real-zero`, `artifact`, `unknown` or `missing` against same-basin
peers, at *proxy* match grade, since no independent CWC or India-WRIS daily
record was available. Primary treatment V1 converts `artifact` and `unknown`
zeros to missing; sensitivity V0 takes zeros as recorded, and V2 keeps positive
and real-zero days then discards every day of any month whose verified fraction
is below 90 %. Nothing is interpolated. A gap of at most 7 days pauses the queue
(no arrival, no service, state carried forward and flagged); a month containing a
longer gap is excluded from aggregation and fitting. All flags are written out.

### 2.2 United States: reservoir-centric pilot

The US component is a **pilot, not a confirmatory test**. Its unit is the
reservoir, because only two ResOpsUS reservoirs fall inside a Caravan catchment
polygon, which makes the gauge the wrong unit. Inputs are Caravan-US
(meteorology, attributes), ResOpsUS (Zenodo record 6612040: storage and outflow)
and the U.S. Drought Monitor county-level Drought Severity and Coverage Index
(DSCI). `[measurement]` The core sample is 50 reservoirs with a ResOpsUS outflow
record and an irrigated Caravan catchment within 20 km; 49 run through the queue,
45 yield design matrices of at least 120 months, and 21 have paired test-window
predictions, contributing 10 681 complete reservoir-months at a target event rate
of 34.7 % (DSCI ≥ 100, D1 or worse). Utilisation spans $\rho = 0.103$–$25.44$,
with 27 reservoirs inside 0.15–1.20; the wider spread is kept, since the pilot
is descriptive. `[measurement]` OpenET evapotranspiration is not used: the
account quota was exhausted before the 2016–2020 validation slice could be
computed, so the pilot uses FAO-56 Penman–Monteith ET$_0$ with a declared crop
coefficient.

## 3. The unit system

All queue arithmetic happens in one volumetric unit, the **claim**. For
catchment area $A$ (m$^2$) and irrigated fraction $f_{irr}$ (dimensionless),

$$
A_{cmd} = f_{irr}\,A \quad [\mathrm{m^2}],
\qquad
V_{claim} = \frac{d}{1000}\,A_{cmd} \quad [\mathrm{m^3}],
\qquad d = 20\ \mathrm{mm},\ f_{irr} = 0.10 .
$$

$V_{claim}$ is computed once per gauge and used for both demand and supply; no
other claim volume exists. Rates follow as

$$
\lambda_t = \frac{\text{need}_t}{d}, \qquad \mu_t = \frac{S_t}{d}
\quad [\mathrm{claims\,day^{-1}}],
$$

where $\text{need}_t$ and $S_t$ are in mm day$^{-1}$. Since both are divided by
the same $d$, area cancels in $\rho$, and the queue engine receives claims per
day only — never cubic metres, hectares or millimetres. Worked check: for
$A_{cmd} = 45\,000$ ha $= 4.5\times10^{8}$ m$^2$ and
$d = 20$ mm, one claim is $9.0\times10^{6}$ m$^3$; with $Q = 500$ m$^3$ s$^{-1}$
and firm share $s_{firm} = 0.5$ the gross depth is
$0.5\times500\times86\,400/4.5\times10^{8}\times1000 = 48$ mm day$^{-1}$, capped
at 10, so $\mu = 0.5$; a need of 2 mm day$^{-1}$ gives $\lambda = 0.1$ and
$\rho = 0.2$, inside the window.

`[assumption]` $f_{irr} = 0.10$ is a Stage-A envelope, not a measured command
area, because measured irrigation demand (Stage B) was unavailable. The declared
envelope is the sweep $f_{irr} \in \{0.03, 0.10, 0.25\}$. Queue magnitudes are
therefore illustrative under the stated assumptions, never observations of
unmet demand; the indicators serve as predictors, so the label stays.

## 4. Demand and supply

### 4.1 Crop-water demand

With day-of-year $j$, sowing day $j_0 = 200$, season length $L = 120$ days and
$phase_j = ((j - j_0) \bmod 365)/L$,

$$
K_c(j) =
\begin{cases}
K_{c,base} + \left(K_{c,peak} - K_{c,base}\right)\sin\!\left(\pi\,\mathrm{clamp}(phase_j,0,1)\right), & phase_j \le 1,\\
K_{c,off}, & phase_j > 1,
\end{cases}
$$

$$
\text{need}_t = \max\left(K_c(j_t)\,\mathrm{PET}_t - \phi\,P_t,\ 0\right)
\quad [\mathrm{mm\,day^{-1}}],
$$

with $K_{c,base} = 0.4$, $K_{c,peak} = 1.2$, $K_{c,off} = 0.35$, and effective
rainfall fraction $\phi = 0.7$. Demand exists only where PET and rainfall are
both present; otherwise the day is missing and the gap rules apply.
`[assumption]` The queue then reads this rate as a birth–death process: arrivals
Poisson with rate $\lambda_t$, service exponential with rate $\mu_t$, reneging
exponential with rate $\eta$. These describe unobserved within-month timing and
set the dispersion of $Q$ around its mean; they are assumptions, not
measurements.

### 4.2 Supply variants

**SUP-1 (primary)** takes a firm share of observed flow, capped at intake
capacity:

$$
S^{SUP1}_t = \min\left(s_{firm}\,\frac{86\,400\,Q_t}{A_{cmd}}\,1000,\ cap_{mm}\right),
\qquad s_{firm} = 0.5,\ cap_{mm} = 10 ,
$$

where 86 400 converts m$^3$ s$^{-1}$ to m$^3$ day$^{-1}$ and 1000 converts
m day$^{-1}$ to mm day$^{-1}$. The cap represents intake and conveyance and is
swept at 5, 10 and 20 mm day$^{-1}$. **SUP-2** uses dependable flow, clipping at
the 5th percentile $Q_5$ and dropping the firm-share discount:

$$
S^{SUP2}_t = \min\left(\frac{86\,400\,\min(Q_t,Q_5)}{A_{cmd}}\,1000,\ cap_{mm}\right).
$$

**SUP-3** is infrastructure-first, offering full capacity above an ecological
floor $Q_{eco} = eco_{frac}\,\overline{Q}$ and SUP-1 below it:

$$
S^{SUP3}_t =
\begin{cases}
cap_{mm}, & Q_t \ge Q_{eco},\\
S^{SUP1}_t, & Q_t < Q_{eco}.
\end{cases}
$$

The variants bracket a conservative firm allocation and an optimistic "all
infrastructure usable" reading.

### 4.3 Reservoir-centric variant (United States)

Service is set by managed outflow, and demand uses one declared coefficient:

$$
\text{need}_t = \max\left(K_c\,\mathrm{ET_0}_t - \phi\,P_t,\ 0\right), \quad K_c = 0.8,
$$

$$
\mu_t = \frac{1}{d}\min\left(\frac{86\,400\,R_t}{A_{cmd}}\,1000,\ cap_{mm}\right),
$$

where $R_t$ is ResOpsUS outflow (m$^3$ s$^{-1}$) and $\mathrm{ET_0}_t$ is FAO-56
Penman–Monteith reference evapotranspiration. `[assumption]` $K_c = 0.8$ is a
declared constant requiring a sensitivity test before any US claim, and $A_{cmd}$
is the nearest irrigated Caravan catchment within 20 km, a proxy for a measured
service area. Capacity comes from reservoir storage expressed in claims, capped
to $25 \le K \le 80$ (realised range 25–80).

## 5. The finite-capacity deficit queue

### 5.1 States and rates

The backlog is the number of claims of unmet demand outstanding,
$n \in \{0,\dots,K\}$, with $K$ the capacity in claims. For daily rates
$\lambda, \mu$ (claims day$^{-1}$),

$$
b_n =
\begin{cases}
\lambda, & n < K,\\
0, & n = K,
\end{cases}
\qquad
s_n = \min(n,c)\,\mu\left(\alpha\,\mathbf{1}\{n \ge \theta\} + \mathbf{1}\{n < \theta\}\right),
\qquad
d_n = s_n + \eta\,n ,
$$

with $b_n$ the birth rate, $s_n$ the service rate, $d_n$ the total death rate,
$c = 1$ the number of channels, $\alpha = 1.5$ the service acceleration above the
severe threshold $\theta$, and $\eta = 1/60$ day$^{-1}$ the per-claim reneging
rate, i.e. a mean patience of 60 days. Setting $b_K = 0$ makes capacity a hard
wall: an arrival at $n = K$ is *blocked* and lost, while reneging is abandonment
of demand.

### 5.2 Generator and stationary solution

With $p(t)$ the row vector of state probabilities, $\mathrm{d}p/\mathrm{d}t = p\,Q$
for the generator (units day$^{-1}$)

$$
Q_{n,n} = -(b_n + d_n), \qquad Q_{n,n+1} = b_n, \qquad Q_{n,n-1} = d_n .
$$

For constant rates the stationary distribution is the exact product form

$$
\pi_n = \pi_0\prod_{i=1}^{n}\frac{b_{i-1}}{d_i},
\qquad
\pi_0 = \left(1 + \sum_{n=1}^{K}\prod_{i=1}^{n}\frac{b_{i-1}}{d_i}\right)^{-1},
$$

which serves as the reference solution. Because $\lambda_t$ and $\mu_t$ change
daily, the operational solution is the transient one.

### 5.3 Transient propagation

The transient uses classical fourth-order Runge–Kutta on the generator with an
automatic step cap,

$$
\Delta t = \min\left(0.5,\ \frac{0.5}{\lambda + c\,\mu\,\alpha + K\,\eta}\right)
\quad [\mathrm{days}],
$$

so no step exceeds half a day and the step times the maximum exit rate stays at
or below 0.5. The vector is renormalised after each substep and negative
round-off is clipped to zero. Initialisation is $p_0(0) = 1$: the system starts
empty, the conservative choice for a drought-onset question.

### 5.4 The conservation ledger

A scheme that silently loses probability is indistinguishable from a physical
result, so every day carries a ledger built from the same Runge–Kutta stages as
the state update:

$$
\underbrace{\lambda\,\Delta t}_{\text{offered}} =
\underbrace{\text{served}} + \underbrace{\text{reneged}} +
\underbrace{\text{blocked}} + \underbrace{\Delta\mathbb{E}[Q]} .
$$

Each term is the same quadrature of the corresponding flux, so the identity holds
to floating-point precision rather than approximately. A per-day residual above
$10^{-6}$ claims stops the pipeline; it is never patched.

### 5.5 Catchment-relative thresholds

Thresholds are expressed in days of the site's own mean demand $\bar\lambda$, so
"severe" means the same in a small and a large command area:

$$
q^{*} = \max\left(1,\left\lceil q_{days}\bar\lambda\right\rceil\right),
\quad
K = \min\left(80,\max\left(25,\left\lceil K_{days}\bar\lambda\right\rceil\right)\right),
\quad
\theta = \min\left(K,\left\lceil \theta_{mult}q^{*}\right\rceil\right),
$$

with $q_{days} = 60$ days, $K_{days} = 365$ days and $\theta_{mult} = 1.5$; if
$q^{*} \ge K$ then $q^{*} = K-1$. Thus $q^{*}$ is about two months of mean demand,
$K$ about one year bounded to 25–80 claims, and acceleration starts 50 % above
$q^{*}$.

### 5.6 Indicators, first passage and the blocking guard

Four indicators are extracted daily and aggregated monthly: expected backlog
$\mathbb{E}[Q] = \sum_{n=0}^{K} n\,p_n$ [claims], severe-backlog probability
$P(Q \ge q^{*}) = \sum_{n=q^{*}}^{K} p_n$, accelerated-service probability
$P(Q \ge \theta)$, and capacity mass $P(Q = K)$. $P(Q \ge q^{*})$ is the quantity
taken into the models of §6. Recovery time is a first-passage quantity: with
state 0 absorbing, the mean time to empty the backlog from $q^{*}$ solves

$$
A\,m = -\mathbf{1},
\qquad
m_{q^{*}} = \left(-A^{-1}\mathbf{1}\right)_{q^{*}}\ \text{days},
$$

where $A$ is the sub-generator on transient states $1,\dots,K$; this answers "how
long until the deficit clears?" conditional on being at the severe threshold.
Finally, if at any time $P(Q = K) \ge 10^{-3}$ the capacity is too tight, the
configuration is doubled (up to 200) and the run repeated, with the decision
logged. The guard is evaluated at every time step in every run.

## 6. Statistical evaluation

### 6.1 Model families

All probabilistic models are ridge-penalised logistic regressions fitted by
iteratively reweighted least squares on training rows only:

$$
\Pr(y=1\mid x) = \sigma\left(\beta_0 + x^{\top}\beta\right),
\quad
\hat\beta = \arg\min_{\beta}\left[-\sum_i\left\{y_i\log p_i + (1-y_i)\log(1-p_i)\right\}
+ \frac{L_2}{2}\sum_{j\ge1}\beta_j^{2}\right],
$$

with $\sigma(z) = 1/(1+e^{-z})$ and $L_2 = 1.0$; the intercept is unpenalised and
eleven calendar-month indicators (January as reference) enter every family, so
seasonality is shared rather than credited to a predictor. Predictors are
standardised with training means and standard deviations. A family is marked
missing if a site has fewer than 40 training rows, fewer than 10 test rows, or a
single outcome class. Eight families are fitted per site and endpoint:
climatology, SPI-3, SPEI-3, SSI-3, queue alone ($\mathbb{E}[Q]$ and
$P(Q\ge q^{*})$), SSI-3 + queue, SPEI-3 + queue, and SSI-3 + SPEI-3 + queue.
SSI-3, computed from monthly mean flow and standardised on the training period,
is the incumbent to beat; the SPEI-3 contrast is the fair demand-side comparison.
In E2 every predictor is lagged one month, and the queue family also carries the
increment $\Delta P = P(Q\ge q^{*})_{t-1} - P(Q\ge q^{*})_{t-2}$, so both level
and direction of travel are available.

### 6.2 Scores, paired differences and intervals

Discrimination is scored by the Mann–Whitney AUC with tie handling, calibration
by the Brier score, sharpness by log loss, and reliability by ten fixed
probability bins plus a calibration slope from regressing $y$ on
$\mathrm{logit}(p)$. Confirmatory inference uses only the paired difference
$\Delta_g$ of §1.1. Its interval comes from a two-level bootstrap that resamples
sites with replacement, then years with replacement within each drawn site,
recomputing the pooled per-site Brier difference each time (2000 replicates, seed
20261125); resampling years inside sites is what makes the interval reflect
temporal as well as spatial variability. The sign test is the exact one-sided
binomial test of $\Pr(\Delta_g > 0) = 0.5$, reported with the share improved.

### 6.3 Power, minimal detectable effect and harm bound

For a paired design at significance $\alpha$ and power $1-\beta$,

$$
\mathrm{MDE} = \frac{\left(z_{0.975} + z_{0.80}\right)\mathrm{SD}}{\sqrt{N}},
$$

with $\mathrm{SD}$ the across-site standard deviation of the paired difference and
$N$ the number of sites. `[measurement]` At $N = 24$ this gives 0.0027 Brier
units ($\mathrm{SD} = 0.004661$) and 0.0450 AUC units
($\mathrm{SD} = 0.078637$); the AUC figure sits at the predeclared +0.05 grid
point, so the design is powered for a moderate discrimination gain, with
simulated sign-test power 0.722 for +0.05 AUC and 0.983 for +0.08, so a null
Brier result is interpretable rather than underpowered. The harm bound
$\Delta_g < -0.005$ on any site triggers a calibration investigation before any
claim, and the breach itself is reported.

### 6.4 Multiplicity

E1 and E2 are the only protected confirmatory tests. AUC, log loss, reliability,
event timing, the queue-alone and SPEI-3 + queue families, and every sensitivity
axis are secondary or exploratory: reported in full whatever their direction, and
never upgraded post hoc. Predeclared sensitivity axes, one factor at a time, are
the zero-flow variant (V0/V1/V2), $f_{irr}$ (0.03/0.10/0.25), supply variant
(SUP-1/2/3), intake cap (5/10/20 mm day$^{-1}$), $q_{days}$ (45/60/90),
$K_{days}$ (180/365), PET source (GLEAM/Hargreaves) and target (T1/T1-strict);
the full cross of 432 runs is explicitly out of scope.

## 7. Software and reproducibility

The analysis is R with base R and `data.table` for data handling and `sf` for the
gauge-to-district match; there is no compiled code and no hidden state between
stages. One runner executes stages S2–S7 (inventory and zero audit; catchment
table, rates and utilisation screen; queue propagation; indices, targets and
design matrices; fitting and endpoints) and writes every output as a CSV with a
JSON sidecar holding the git hash, parameter set, seed and R session
information. Outputs are regenerated, never hand-edited.

Correctness is guarded by a 14-check verification battery that must pass in full
before any result is quoted. Its anchors are three-way agreement between the exact
product-form stationary solution, the RK4 transient and a Gillespie/thinning
discrete-event simulation of the same chain, plus checks on the unit wall, the
ledger identity, the first-passage solver and the scoring functions. Any new solver path must keep the §5.3 step cap, because RK4
on this generator becomes unstable once $\Delta t$ times the largest eigenvalue
magnitude exceeds about 2.78. Randomness enters only in the two-level bootstrap
(2000 replicates), the power simulation and the discrete-event verification run,
all seeded 20261125; everything else is deterministic. `[measurement]` The
environment has no `renv`, so no lockfile is shipped; the documented fallback
installs the package set and prints exact versions, and the gap is disclosed as
an item to close before submission.

`[assumption]` Two limits apply throughout. Demand is a crop-water envelope with
a declared irrigated fraction, not measured abstraction, so queue magnitudes are
illustrative. Second, zero-flow classification for the Indian gauges is proxy-grade
(same-basin peers), not an independent gauge-by-gauge record. Neither affects the
paired contrast, but both bound what the queue numbers can mean.
