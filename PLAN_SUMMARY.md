# Plan summary — one merged drought-queue methods paper (v2 rebuild)

Date: 26 November 2026. Supersedes the 25 November v1 summary.

## Bottom line

We asked whether a queue of unmet water demand adds drought information beyond
climatology, SPI, SPEI and SSI.

The **v1 two-gauge answer is not usable**: it mixed units, sat in a regime where
a null was guaranteed, and had almost no held-out drought events. v2 rebuilds
the test in R with one unit system, a predeclared utilisation screen, 24 gauges
across 11 basins, and a locked protocol.

The v2 predeclared confirmatory Brier endpoint is **null**: adding queue
probability to SSI-3 does not lower the held-out Brier score by a detectable
amount. The secondary AUC contrast is positive and is reported as **secondary
only**. The paper is therefore **one HESS-style methods + negative-result
evaluation with a utilisation diagnosis** — Path B in the redesign plan, not a
superiority claim.

## 1. Objective

Represent drought as a finite-capacity queue:

- water demand arrives at rate `lambda(t)`;
- available firm supply serves demand at rate `mu(t)`;
- unmet demand accumulates as backlog `Q(t)`;
- backlog indicators describe drought state, exposure, abandonment and recovery.

The paper must (1) prove the queue calculations against exact references and
(2) test whether the indicators add information on observed drought, with
adequate power.

## 2. The gap we are testing (unchanged, frozen 21 November 2026)

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens
> (295 records), plus the citation traces, we found no study that puts all
> four of these together: (1) drought as an accumulated unmet-demand backlog
> with a finite-capacity state; (2) queue-state indicators reported as
> drought quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

We do not claim that no such study exists anywhere.

## 3. Data and design (v2)

| Element | v2 choice |
|---|---|
| Streamflow / forcing | CAMELS-IND, 472 gauges |
| Target | District soil-moisture anomaly `<= -15%` (external product; leakage disclosed) |
| Clean-target sensitivity | Training-only SPI-3 drought, matching predictor dropped |
| Screening | `rho` window 0.15–1.20, zero fraction < 0.30, interior gap <= 30 d |
| Coverage | >= 3 y train (1981–2010), >= 2 y test (2011–2020) |
| Clustering | at most 3 gauges per basin |
| Analysis set | **24 gauges across 11 basins** |
| Unit system | one claim = 20 mm over `f_irr * catchment area` |
| Supply | SUP-1 primary; SUP-2/SUP-3 predeclared sensitivities |
| Zero semantics | V1 primary; V0/V2 sensitivities; basin-peer proxy grade |
| Verification | 14/14 battery (closed forms, RK4 vs DES, ledger, units, gaps) |

## 4. What the v2 data showed

Use **paired** per-gauge deltas on identical held-out months; lower Brier is
better. Exact values are produced only by `R/run_pipeline.R` and recorded in
`analysis/P02_methods/RESULTS_v2.md`.

- **E1 (concurrent Brier, confirmatory):** median improvement about `+0.0008`
  with a two-level bootstrap interval that **includes zero**; the sign test does
  not reach significance. **Null.**
- **E2 (1-month prospective Brier, confirmatory):** also **null**.
- **Secondary AUC:** positive (the queue improves ranking), reported as
  secondary and not upgraded.
- **Power:** the Brier minimal detectable effect at N = 24 is several times the
  observed effect, so the null is interpretable rather than underpowered.
- **Harm bound:** a few gauges show a small negative Brier delta; this is
  investigated (calibration breakdown) and disclosed.

`[assumption]` Queue outputs are illustrative under the Stage-A demand envelope
and SUP-1 supply; they are not observed unmet demand.

## 5. Why v2 is more trustworthy than v1

1. Demand and supply share one claim volume, so units cannot silently diverge.
2. Thresholds are catchment-relative, so gauges are comparable.
3. The utilisation screen removes the guaranteed-null regime.
4. 24 gauges and 11 basins replace two gauges.
5. The protocol, endpoints, harm bound and power are locked before unblinding.
6. Every sensitivity axis is reported, including the leakage-clean target.
7. The confirmatory statistic is paired on identical held-out months.

## 6. What we did not do

- No measured irrigation-demand series; `lambda` is a process envelope.
- No resolved zero-flow/regulation semantics (proxy grade only).
- No strictly leakage-free external SMA climatology (disclosed; clean
  sensitivity provided).
- No future-climate result; the CMIP6 stage is gated. No raw CMIP6 number.
- No claim that queue indicators outperform SPI/SPEI/SSI.

## 7. Exact next actions

1. Author sign-off on the Path-B framing and submission metadata.
2. Archive link / DOI and licence.
3. Accept or authorize resolution of the disclosed literature limitations.
4. If a stronger test is wanted: measured demand, independent zero-flow/regulation
   records, and a strict training-only external benchmark reconstruction.

## 8. Where to look

- Plain orientation: `START_HERE.md`
- Locked protocol: `protocol/PROTOCOL_v2.md`
- Results with sources: `analysis/P02_methods/RESULTS_v2.md`
- Figures: `figures/`
- Pipeline: `R/run_pipeline.R`, sensitivity: `R/analysis/sensitivity_grid.R`
- Tests: `Rscript R/verify/run_tests.R` (14/14)
- Merged-paper strategy: `docs/project/MERGED_PAPER_PLAN.md`
