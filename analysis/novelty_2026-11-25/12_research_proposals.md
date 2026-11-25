# 12 — Research proposals

## Proposal A (recommended): Identifiable drought backlogs under conservation

**Working title:** *Identifiable drought backlogs: a conservation-constrained queue-state framework*

**Background:** Standardised indices locate anomalies but do not directly represent unmet-demand backlog. Queueing and stochastic storage theory are old; coupled drought state-space and non-stationary supply–demand models also exist.

**Gap:** The queue-specific combination of latent deficit dynamics, explicit conservation, identification analysis, exact reference validation and pre-specified drought tests has not been identified in the documented searches.

**Hypotheses:**

- H1: Demand and service rates are not both structurally identifiable from backlog observations alone.
- H2: Independent storage/delivery/impact observations improve identification and held-out backlog/recovery forecasts.
- H3: Queue indicators add event-level information beyond climatology, SPI/SPEI/SSI and storage anomaly only in regimes where demand and supply are separately constrained.
- H4: Some dimensionless indicators remain robust even when structural parameters are non-identifiable.

**Methods:** Finite-state CTMC; conservation ledger; simulation-based/profile-likelihood identification; constrained rate estimation; time-dependent backward recovery solver; exact stationary/Floquet/DES checks; blocked held-out validation.

**Baselines:** Climatological queue, stationary-at-mean queue, persistence, SPI/SPEI/SSI, storage anomaly, stationary recovery formula.

**Primary endpoint:** Event-level Brier score for `Pr(Q ≥ q*)` by a declared deadline.

**Data:** CAMELS-IND/IMD/catchment attributes; crop/calendar and delivery records where available; independent storage or impact observations; regulation and zero-flow metadata.

**Falsification:** If independent observations do not improve identification or forecasts, or if no indicator adds information, report the null/non-identifiability result.

**P01 role:** Perspective and pre-specified programme.

**P02 role:** Methods and held-out tests after Gate B.

## Proposal B: Recovery-by-deadline probabilities for non-stationary drought queues

**Working title:** *Will the backlog clear in time? Non-stationary drought recovery probabilities*

**Question:** Can a queue model provide calibrated recovery-by-deadline probabilities that outperform persistence, climatology, standard indices and stationary recovery formulas?

**Method:** Time-dependent backward equation with absorbing state `Q=0`; exact piecewise-constant and DES references; ensemble propagation from uncertain future rates.

**Validation:** Synthetic convergence, then held-out drought events with Brier score, reliability and recovery-time MAE.

**Risk:** Hitting-time theory is mature; contribution must be the drought parameterisation and empirical validation.

## Proposal C: Intermittent service and compound demand–supply failure

**Working title:** *When the service desk closes: intermittent supply in drought queue models*

**Question:** After resolving zero-flow semantics, does a hurdle or Markov-regime service model improve dry-spell and backlog-tail forecasts?

**Method:** Joint demand/supply regime chain or hurdle occurrence/intensity estimator; exact finite-state benchmark.

**Risk:** Blocked until gauge 4026 zero semantics and regulation status are known.

## Publication positioning

- **P01 / WRR:** Synthesis, conservation contract, identification problem and falsifiable programme.
- **P02 / HESS:** Exact methods, identification experiments, recovery distributions and held-out validation.
- Do not position any proposal as a broad new drought theory or as ML-for-queues novelty.
