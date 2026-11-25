# 10 — Adversarial novelty audit

## C1 — Conservation-ledger deficit queue

- **Strongest support:** The current code has a verifiable blocked-demand omission and unit conflict; R and Python disagree.
- **Strongest counter-evidence:** Conservation accounting is standard hydrology, not new.
- **Closest prior:** Water-balance and stochastic storage theory.
- **Reviewer objection:** “This is bookkeeping, not a scientific advance.”
- **Revision:** Position it as the validity foundation for queue indicators, not as standalone novelty.
- **Decision:** **RETAIN_AS_FOUNDATION**.

## C2 — Identifiability-first inference

- **Strongest support:** Queue estimation is mature, but hydrological separation of demand and supply from latent backlog is not established; Acosta et al. explicitly call observational assimilation future work.
- **Strongest counter-evidence:** Hydrological data assimilation and drought attribution are mature fields.
- **Closest prior:** Asanjarani et al. (2021); Acosta et al. (2026); Zhao et al. (2018).
- **Reviewer objection:** “State estimation and attribution already exist.”
- **Required revision:** Demonstrate a queue-specific structural identification problem and robust indicators, not a generic filter.
- **Decision:** **RETAIN_AS_HEADLINE_DIRECTION**, evidence confidence MODERATE.

## C3 — Time-varying recovery distributions

- **Strongest support:** Current code is stationary-only despite a general manuscript claim; the extension is feasible and decision-relevant.
- **Strongest counter-evidence:** Hitting-time theory is old.
- **Closest prior:** Tan et al. (2013), Whitt (2018), stochastic storage first-passage literature.
- **Reviewer objection:** “Another application of known first-passage theory.”
- **Required revision:** Validate drought-specific recovery probabilities against held-out events and baselines.
- **Decision:** **RETAIN_AS_FIRST_IMPLEMENTATION_EXTENSION**.

## C4 — Intermittent service

- **Strongest support:** The real pilot has 68% zero-flow days and the estimator cannot represent zeros.
- **Strongest counter-evidence:** Zero semantics are unresolved; Markov-switching hydrology is established.
- **Closest prior:** MMPP/MMSP, zero-inflated hydrology, Al-Sifao et al. (2026).
- **Reviewer objection:** “Fix the data before modelling it.”
- **Decision:** **INVESTIGATE_AFTER_DATA_SEMANTICS**.

## C5 — Dependence-aware uncertainty

- **Strongest support:** Current bootstrap resamples rows independently and does not propagate to indicators.
- **Strongest counter-evidence:** Standard uncertainty methods already exist.
- **Closest prior:** Block bootstrap, hierarchical Bayes, conformal prediction.
- **Reviewer objection:** “Methodological hygiene, not novelty.”
- **Decision:** **RETAIN_AS_REQUIRED_VALIDATION**.

## C6 — Incremental and decision-value tests

- **Strongest support:** The project explicitly promises pre-specified tests and null reporting.
- **Strongest counter-evidence:** Ablation and forecast scoring are standard.
- **Closest prior:** Drought forecast verification and decision analysis.
- **Reviewer objection:** “Good design is not novelty.”
- **Decision:** **RETAIN_AS_REQUIRED_VALIDATION**.

## C7 — Risk-sensitive estimation

- **Strongest support:** Known μ-error near congestion directly affects tail risk.
- **Strongest counter-evidence:** Risk-sensitive learning and proper scores are mature.
- **Closest prior:** Asanjarani et al. (2021), Sherzer et al. (2024).
- **Reviewer objection:** “Change the loss function and rerun.”
- **Decision:** **PROMISING_UNVERIFIED**, secondary to C2/C3.

## C8 — Source-resolved networks

- **Strongest support:** Current server accounting can double-count aggregate supply.
- **Strongest counter-evidence:** Multi-source reliability and irrigation allocation queues already exist; operational data are missing.
- **Closest prior:** Al-Sifao et al. (2026), Yang et al. (2016, 2019).
- **Decision:** **DOWNGRADE_TO_LATER_EXTENSION**.

## C9 — Broad coupled state-space theory

- **Strongest support:** A unified framework is intellectually attractive.
- **Strongest counter-evidence:** Acosta et al. (2026) already propose the broad framework in a 36-page preprint.
- **Closest prior:** Acosta et al. (2026).
- **Decision:** **REJECT_AS_HEADLINE_NOVELTY**; retain as prior art.

## Cross-cutting reviewer questions

1. Does the contribution remain if the study location is removed? Yes only for the queue dynamics, identification and validation—not for India-specific data alone.
2. Does it remain if the ML algorithm is replaced? It must, because ML-for-queues is mature.
3. What falsifies it? Failure of conservation, parameter identification, exact recovery benchmarks or pre-specified incremental-value tests.
4. What is the strongest objection? “This is storage theory, state estimation or water-balance accounting under new names.” The answer must be empirical: queue-state indicators and identification tests must add value, or the paper reports a null.
