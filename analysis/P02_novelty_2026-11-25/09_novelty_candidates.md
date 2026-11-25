# 09 — Novelty candidates

Scores and statuses are in `11_novelty_assessment.csv`. These are research directions, not priority claims.

## C1 — Conservation-ledger deficit queue

**Problem:** Applied queue indicators can conflate backlog stock, exposure and abandoned demand, and the current Python engine omitted blocked demand.

**Idea:** Make the queue a demand-conservation process with separate served, blocked, reneged and terminal-backlog terms. Couple storage and backlog only through the served-water flux. Add claim-scale equivariance.

**Contribution:** A physically auditable indicator contract and a reproducible ledger test.

**Prior art:** Standard water balance and stochastic storage; no broad novelty claim.

**Falsification:** If equivalent conventions do not produce equivalent physical indicators, or the ledger cannot close, the framework fails.

**Feasibility:** High. Implemented in the shared Python core with three ledger tests; a fourth test anchors the Box 1 sensitivity script.

## C2 — Identifiability-first joint storage–backlog inference

**Problem:** A backlog trajectory can be produced by different demand and supply paths. Prediction accuracy does not establish attribution.

**Idea:** Jointly infer rates, latent backlog and structural parameters; use independent storage, delivery, restriction or impact observations; profile observational equivalence before interpreting indicators.

**Contribution:** A hydrological identification analysis and robust-indicator subsets when full identification fails.

**Prior art:** Asanjarani et al. (2021), hydrological data assimilation, Acosta et al. (2026) future-work statement.

**Falsification:** Materially different parameter sets remain observationally equivalent but imply different decisions; report non-identifiability rather than choose one silently.

**Feasibility:** Medium. Synthetic identification is feasible now; empirical inference needs independent observations.

## C3 — Time-varying recovery distributions

**Problem:** Current recovery is a stationary mean only.

**Idea:** Compute `Pr(T_Q→0 ≤ H | Q(0)=q, future rate path)`, quantiles and deadline-recovery probabilities using a time-dependent backward equation or absorbing-state calculation.

**Contribution:** Operational recovery probabilities that retain non-stationary history and rate uncertainty.

**Prior art:** First-passage/busy-period theory and time-varying queues are mature; the drought application and validation are open.

**Falsification:** Probabilities fail exact/DES checks or held-out calibration; report null.

**Feasibility:** High for synthetic validation.

## C4 — Zero-flow-aware intermittent service

**Problem:** Positive-rate estimators cannot represent exact zero service, while gauge 4026 has unresolved zero-flow days.

**Idea:** After resolving data semantics, use a hurdle occurrence/intensity model or a joint Markov regime for demand and supply availability.

**Contribution:** Explicit dry-spell occurrence, persistence and compound demand/supply failure.

**Prior art:** Markov-modulated service, zero-inflated hydrology and multi-source reliability queues.

**Falsification:** If zeros are fill values, correct the data instead; if real, the model must improve held-out dry-day and tail calibration over simpler alternatives.

**Feasibility:** Blocked before documentation; high afterwards.

## C5 — Dependence-aware uncertainty propagation

**Problem:** Independent-row bootstrap intervals ignore temporal and spatial dependence and are not propagated to indicators.

**Idea:** Moving-block or basin-level resampling, hierarchical uncertainty where justified, repeated queue solves and event-level calibration.

**Contribution:** Decision-relevant uncertainty for backlog, severe-state probability, abandonment and recovery.

**Prior art:** Block bootstrap, hydrological ensembles and conformal prediction.

**Falsification:** Nominal intervals fail held-out coverage or become uninformatively wide.

**Feasibility:** Medium–high.

## C6 — Pre-specified incremental and decision-value tests

**Problem:** Correlation with SPI/SPEI/SSI is not evidence of added value.

**Idea:** Pre-register one primary event-level endpoint, strongest baselines, held-out units, ablation ladder and null clause; add decision-value analysis only with declared costs.

**Contribution:** A credible test of whether queue indicators change forecasts or decisions.

**Prior art:** Forecast verification, ablation and decision-curve methods.

**Falsification:** No robust gain means a null result.

**Feasibility:** Medium; data exist but real evaluation is not implemented.

## C7 — Risk-sensitive rate estimation

**Problem:** Rate RMSE is not the same as preserving tail drought risk near congestion.

**Idea:** Weight or optimise service-rate errors by their effect on severe-state probability, abandonment or recovery, while retaining positivity and monotonicity.

**Contribution:** Estimation aligned with the actual drought-risk target.

**Prior art:** Queue parameter estimation and proper scoring rules.

**Falsification:** No held-out event-score improvement over rate-RMSE estimation.

**Feasibility:** Medium.

## C8 — Source-resolved networked drought queues

**Problem:** Aggregate `c * mu` can double-count supply and hides source co-failure.

**Idea:** Separate streamflow, canal, groundwater and emergency sources with availability, capacity and correlation; connect nodes with conservation constraints.

**Contribution:** Observable source-outage and downstream drought propagation.

**Prior art:** Al-Sifao et al. (2026), Yang et al. (2016, 2019), queueing-network control.

**Falsification:** No improvement over independent local queues or climatology while satisfying conservation.

**Feasibility:** Medium–low because operational source records are missing.

## C9 — Broad coupled drought state-space theory

**Problem:** A unified coupled human–water drought framework is attractive but already proposed.

**Idea:** Generalise storage, accessibility, demand, transfer and loss into a network state space.

**Decision:** **Reject as a broad novelty claim.** Acosta et al. (2026) already published this as a preprint, including unmet accessible demand, probabilistic risk, resilience and future assimilation plans.

**Possible role:** Background literature or a later network extension, not the headline contribution.
