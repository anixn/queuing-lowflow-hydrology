# PIVOT.md — Pivot decision and redesign specification

**Version 1.0, 26 November 2026.** Companion to `AGENTS.md` v2.0 (operating rules) and
`STUDY.Rmd` (current study record). Written from an external expert review
(queuing theory + water resources hydrology) of the repository as cloned on
26 November 2026; the full review with page-level detail is
`Queuing_LowFlow_Expert_Review_and_Pivot.docx/.pdf`.

**Status: DECIDED.** Gate G2 (corrected re-run, 2 weeks) → Study P1 (headline,
12-week roadmap) → Study P3 (second paper). P2/P4 are recorded future options.

This document is the **change record** that `AGENTS.md` §3.8 and §3.9 require
before the claim convention, the target or the confirmatory endpoint may change.
It supersedes the study design in `README.md` / `STUDY.Rmd` §"Methods" for all
work started after 26 November 2026; it does **not** weaken any rule in
`AGENTS.md` — the never-list, the always-list, the unit wall, the provenance
sidecars and the frozen-sentence discipline all remain in force.

---

## 0. How to use this document

| You are… | Read first | Then |
|---|---|---|
| An AI coding agent | `AGENTS.md` fully, then §0–§3 here | §7 (surgery plan) for the task you were given |
| The project owner | §1–§2 (why and what) | §4 (the new design) and §8 (roadmap) |
| A reviewer of the pivot | §1, §4.10, §9 | §12 (references, verified URLs) |

Session ritual from `AGENTS.md` §9 is unchanged, with one addition: state which
**gate** you are working in (G2 or P1) — the gates are defined in §3 and §4.10,
and no work may start on a later gate before the earlier gate's decision is
recorded in this file.

---

## 1. Why we pivot (audit verdict, one page)

The v2 study is **engineering-grade and question-mis-wired**. The verified
engine, the unit wall, the conservation ledger, the training-year-only index
standardisation and the pre-registered paired statistics are all better than
typical practice and must survive. But the published confirmatory numbers —

| Target | Region | n | median ΔBrier | 95% CI | sign p |
|---|---|---:|---|---|---:|
| SPEI-3 (primary) | India | 12 | +0.0019 | −0.0006 to +0.0051 | 0.194 (k=8/12) |
| SPEI-3 (primary) | USA | 58 | +0.0021 | +0.0003 to +0.0035 | 0.024 (k=37/58) |
| SPI-3 (sens.) | India | 12 | +0.0010 | −0.0014 to +0.0032 | 0.613 |
| SPI-3 (sens.) | USA | 58 | +0.0011 | +0.0000 to +0.0028 | 0.024 |

— are a 1–3 percent relative effect for the USA and an unresolved interval for
India (472 gauges screened to 12), with the USA-minus-India contrast including
zero for both targets. Three design decisions, not data limitations, produced this.

### 1.1 The three root causes

**FQ1 — The queue contains no information the benchmark lacks.**
`lambda(t) = max(Kc·ET0 − φ·P, 0)/d` is built from the same P and ET0 that
define the SPEI-3 target; `mu(t)` is a transform of the same Q that defines the
SSI-3 benchmark (`R/functions/pipeline.R` `common_rates`, lines 167–195). The
queue state is therefore a deterministic filter of the predictor set's own
information, and its only possible contribution is temporal smoothing — the
effect a 6-month index or an antecedent precipitation index reproduces at zero
modelling cost. Neither baseline is in `FAMILY_FEATURES`
(`R/functions/pipeline.R` lines 232–241).

**FQ2 — The wrong queue class.** Reservoir/dam storage is a *fluid* process
(Moran 1954; Kendall 1957; Gani 1969 — the dam-as-queue equivalence is 70-year-old
settled theory). The engine instead uses a single-server M/M/1/K with Poisson
arrivals of indivisible 20 mm claims and three mechanisms that have no
hydrological referent: reneging `eta = 1/60` (`queue_engine.R` line 57), the
service boost `alpha = 1.5` above `theta` (lines 53–55), and blocking at `K`
(line 51). Unmet demand does not abandon a catchment (it becomes pumping or crop
stress); a river does not serve faster because the backlog is large; deficit
beyond `K` carries over. Each mechanism is an unidentifiable parameter that
blurs the signal.

**FQ3 — The utilisation screen is selection on an assumption.**
`rho = Σlambda/Σmu` (`pipeline.R` line 200) is a function of five assumed
constants (`Kc = 0.8`, `phi = 0.7`, `f_irr = 0.10`, `s_firm = 0.5`,
`cap_mm = 10` — `R/config.R` §P). Screening `rho ∈ [0.15, 1.20]`
(`config.R` line 101, `pipeline.R` lines 210–211) keeps exactly the catchments
where those constants self-agree. `output/india_screen.csv` shows rejected
Indian gauges with `rho` of 2.5, 5.9, 6.6, 7.6 and zero-flow fractions up to
0.78; 472 gauges shrink to 12. The retained set excludes precisely the
intermittent, water-stressed catchments the deficit story is about.

### 1.2 Secondary findings (fix inside the pivot, not separately)

| ID | Finding | Location | Required change |
|---|---|---|---|
| FQ4 | `lam_bar` → `q*`, `K`, `theta` computed over the **full** 1981–2020 record including test years; screen statistics likewise | `pipeline.R` `stage5_queue` lines 51–58; `common_screen` lines 198–213 | All thresholds, screens, standardisation and tuning on training years (1981–2010) only |
| FQ5 | Features are monthly means of `E[Q]` and `P(Q≥q*)`, near-collinear; `first_passage_mean` computed but never used; E2 lead is 1 month (nowcasting) | `pipeline.R` lines 141–145, 232–250 | Evaluate 1/3/6-month leads; use state-trajectory features; or drop the CTMC for the fluid model (chosen, §4.4) |
| FQ6 | Hargreaves ET0, fixed `Kc`, fixed `phi`, uniform `f_irr = 0.10` misrepresent monsoon demand; dataset PET and land-cover attributes unused | `units.R` Hargreaves; `config.R` §P | Dataset PET where available; attribute-derived irrigated fraction; seasonal `Kc`; PET choice becomes a declared sensitivity axis |
| FH1 | Meteorological target (SPEI-3), agricultural mechanism, hydrological benchmark (SSI-3) — three drought types on one causal chain conflated | `STUDY.Rmd` target sections | Retarget to hydrological drought / low-flow endpoints |
| FH2 | Repository is named *queuing-lowflow-hydrology* but contains no low-flow definition (no Q90/Q95, no annual minima, no recession) | whole pipeline | Flow-threshold and low-flow targets (§4.5) |
| FH3 | Concurrent + 1-month-lag endpoints test the queue where storage states are most redundant and never where memory pays | `stage6_design` E1/E2 | 1/3/6-month leads (§4.5) |
| FH4 | `zero_frac < 0.30` screen deletes intermittent rivers — the most relevant catchments | `pipeline.R` line 211 | Censoring treatment + explicit reporting (§4.2) |
| FH5 | Identical constants across two opposite climates; region contrast CI includes zero | `config.R` §P | India-primary design; US becomes a transfer check (§4.2) |
| FS1 | Median ΔBrier on base 0.057–0.175 is 1–3% relative; no skill score vs climatology | `eval.R`, outputs | BSS vs climatology as headline (§4.8) |
| FS2 | n = 12 cannot resolve the contrast; no power analysis preceded the screen | `output/india_screen.csv` | Completeness-only screens + power analysis from gate variance (§4.2) |
| FS3 | Fixed ridge `lambda = 1` for all families shrinks the added features | `eval.R` `fit_ridge_logistic` | Per-family CV-tuned penalty within training years (§4.7) |
| FS4 | 32 fits surround one confirmatory contrast; harm bound 0.005 arbitrary | `stage7_*` | Multiplicity discipline + declared harm derivation (§4.8) |

### 1.3 What is frozen and survives, what is deleted

**Survives unchanged:** `R/functions/queue_engine.R` (verified CTMC — kept as a
frozen asset for P3/P2), `R/functions/units.R` (unit wall, extended not
rewritten), `R/functions/eval.R` metrics, `R/functions/io.R` provenance
sidecars, `verify.R` three-way-agreement principle, the split 1981–2010 / 
2011–2020, the paired two-level bootstrap machinery, `AGENTS.md` discipline,
and the entire literature audit record under `P01/` and `analysis/P01_literature/`.

**Deleted from the P1 study path** (kept in git history; `AGENTS.md` §8
convention of deleting superseded analyses): `rho_window` screening, 
`thresholds_from_lambda`, `alpha`/`eta`/`theta_mult`/`blocking` in the P1
feature path, Hargreaves-only PET (demoted to sensitivity arm), 
`FAMILY_FEATURES` / `FAMILY_FEATURES_E2` as written, the "one method, two
regions" framing, and the SPEI-3 primary target.

---

## 2. The pivot decision

Five options were assessed against the assets in hand (CAMELS-IND forcings and
attributes, IMD gridded observations, the verified engine, the screening and
evaluation harness). "CAEVAN" in the project notes is read as the **Caravan**
family (Caravan / CAMELS-IND extension); nothing below changes with either
forcing source.

| Option | Core question | New data | Benchmark to beat | Verdict |
|---|---|---|---|---|
| **P1. Seasonal low-flow / hydrological-drought forecasting with storage states** | Does a recession-calibrated storage-deficit state improve probabilistic drought forecasts at 1–6 month leads? | None | Persistence, API, SSI-6, climatology; BSS | **ADOPTED (headline)** |
| P2. Groundwater deficit queue, measured backlog | Can a queue with observed water-table storage forecast groundwater drought? | CGWB levels (NWDP), optional GRACE | SGI / persistence on observed levels | Future (record §6) |
| P3. Climate-projection queue reliability | How do backlog probability, recovery time and reliability evolve under SSPs? | CAMELS-IND-Proj (2026) | None — queue quantities are the product | **ADOPTED (second paper)** |
| P4. Identifiability of queue indicators | Which queue indicators are identifiable from gauged records? | None (synthetic + gauged) | Observational-equivalence analysis | Future (record §6) |
| P5. Fix-in-place corrected re-run | Does the queue survive honest memory baselines? | None | SSI-6 / API / persistence added | **ADOPTED (2-week gate G2)** |

**Decision:** execute P5 as gate G2, then commit to P1 as the headline study,
with P3 as the second paper reusing the frozen CTMC engine unchanged. Rationale:
P5 is the cheap falsification test that makes any subsequent null trustworthy;
P1 reuses ~90% of the harness, moves the question to leads where storage memory
is known to carry skill (Sutanto & Van Lanen 2022), restores the sample to the
full CAMELS-IND large sample, fills a real gap (no India-wide equivalent of the
US 1–13-week streamflow-drought forecasting benchmark of Hammond et al. 2025),
and requires no new data. P3 publishes the one quantity class only this project
can produce — transient backlog probabilities and recovery-time distributions —
under four SSPs on the same 472 catchments.

---

## 3. Gate G2 — corrected re-run of the current study (weeks 1–2)

**Purpose:** convert the current manuscript's implicit null into a *trustworthy*
null (or an unexpected positive) before the design is retired. This is the
acceptance gate for the current manuscript and the variance estimate source for
the P1 power analysis (§4.2).

**Change list (all seven, one commit per `AGENTS.md` §3.8/§3.9, both regions rerun,
old and new results reported side by side in `STUDY.Rmd`):**

1. **PET:** use dataset PET where the shipped forcings contain it
   (`unknown, action: check CAMELS-IND forcing file fields for a PET/PET0
   column; Caravan-US carries GLEAM PET via ERA5`). If India ships none, keep
   Hargreaves for the gate only and record PET as the first sensitivity axis of
   P1 (§4.4). 
2. **Demand envelope:** `f_irr` per catchment from CAMELS-IND land-cover
   attributes (cropland/irrigated fraction), `Kc` monthly with a two-season
   kharif/rabi curve `[assumption: FAO-56 stage coefficients, simplified]`,
   `phi` monthly effective-rainfall fraction `[assumption]`. All in `config.R`.
3. **Leakage fixes (FQ4):** `lam_bar`, thresholds, screen statistics computed on
   training years only.
4. **Screen (FQ3 probe):** rerun with `rho_window` removed and completeness
   criteria only, so the gate reports what the sample *could* have been (report
   n and the per-basin distribution; do not change the gate's confirmatory
   sample yet).
5. **Baselines (FQ1 probe):** add families `ssi6`, `api` (API with decay
   `k = 0.95`, 90-day window `[assumption]`), `persistence` (lag-1 SSI-3) to
   `FAMILY_FEATURES`.
6. **Tuning (FS3):** ridge penalty tuned per family by 5-fold CV within
   training years, fold structure frozen in `config.R`.
7. **Reporting (FS1):** add BSS vs the climatology family and relative deltas
   to `region_summary.csv`.

**Decision rule (frozen now, before the gate runs):**
- If median paired ΔBrier of `ssi3_plus_queue` over **the best of the new
  baselines** on the SPEI-3 target is ≥ +0.010 with the 95% interval excluding
  zero in **both** regions at the current screens → the queue survives; schedule
  a decision meeting before touching P1.
- Otherwise → record the null as final for the concurrent design (per
  `AGENTS.md` §3.4), submit/retire the current manuscript as a negative-result
  methods note if the owner chooses, and start P1.

> **RESOLVED 26 November 2026 (same day as freezing — the gate ran within the
> pivot session).** The gate ran after all seven changes were implemented and
> the battery was green. Result (`output/gateG2_summary.csv`): median paired
> ΔBrier of `ssi3_plus_queue` over the frozen best-of baseline — India n = 5:
> −0.0250 [−0.0947, +0.0308], sign 1/5; USA n = 58: −0.0059 [−0.0187, +0.0026],
> sign 25/60 (SPI-3 sens.: −0.0077 [−0.0216, +0.0016]). **NULL RECORDED**: the
> queue does not clear the bar — it is *worse* than the honest memory
> baselines once the ridge penalty is tuned and API/persistence exist. The
> null is final for the concurrent design; the retired manuscript is retired
> as a negative-result methods note; **Study P1 starts**. The frozen best-of
> selection chose `api` for 64/65 gauges (`output/gateG2_bestof_cv.csv`) —
> the antecedent index is the honest concurrent-lead memory baseline. The
> sign-test power at the G2 effect size is near zero for all n ≤ 300
> (`output/p1_power.csv`), confirming FS2: no screen size could have
> resolved the concurrent design.

**Outputs:** `output/gateG2_summary.csv` (+ sidecar), a decision paragraph
appended to `STUDY.Rmd`, gate variance table for §4.2.

---

## 4. Study P1 specification — storage states for seasonal low-flow and hydrological-drought forecasting

**Working title:** *Storage-deficit states for seasonal hydrological drought and
low-flow forecasting in 472 Indian catchments*.
**Repository name stays** `queuing-lowflow-hydrology` — after this pivot the name
is finally accurate.

### 4.1 Research question, hypotheses, confirmatory contrasts

**Question.** Does a physically-shaped storage-deficit state — estimated from
the catchment's own recession behaviour and driven by a water balance — improve
probabilistic forecasts of hydrological drought and low-flow events at 1, 3 and
6-month leads, beyond what lagged standard indices and persistence already carry?

**Hypotheses (pre-registered before any test-year scoring):**

- **H1 (confirmatory, primary).** At lead **h = 3 months**, the storage-feature
  family achieves higher Brier skill score than the **best lagged-index baseline
  family** for the SSI-3 ≤ −1 target, evaluated per gauge as a paired delta on
  identical held-out months, summarised by the median across gauges with the
  two-level block bootstrap; positive sign in ≥ 60% of gauges.
- **H2 (confirmatory, secondary).** Same as H1 at lead **h = 6 months**.
- **H0 (descriptive, declared in advance).** At lead h = 1 month the storage
  family is expected to reach **parity**, not superiority, with fresh indices —
  a null here is the predicted outcome and must be reported as such.
- **Descriptive endpoints.** Q90 flow-threshold exceedance; annual minimum
  7-day flow class; reliability diagrams; basin-level and climate-class skill
  structure; US transfer arm.

**Announced limitation (goes in the paper, not a footnote).** The storage state
is estimated from P, ET and Q of the same catchment record that builds the
indices; it is therefore a *different transform with different memory
properties*, not independent information. The confirmatory question is exactly
whether the physically-shaped transform (recession constants, storage capacity,
mass-balance dynamics) out-predicts the standardised 3-month boxcar that SSI-3
applies. Independent-information variants (P2 groundwater levels, P3
projections) are named as the follow-ups. `AGENTS.md` §3.3 (no unannounced
assumptions) applies with full force here.

**Multiplicity discipline.** Exactly two confirmatory contrasts (H1, H2).
Everything else is descriptive and labelled as such. The harm bound is declared
`[assumption: a per-gauge degradation of 0.005 Brier ≈ the smallest
season-scale change an operator would act on; derivation to be confirmed
against the gate-G2 variance table]`.

### 4.2 Sample — screens, intermittent rivers, power

**Screens (completeness and event-count only; the utilisation window is gone):**

1. `in_window` 1981–2020 record present (`pipeline.R` `common_screen` keeps this).
2. ≥ 30 complete training months and ≥ 10 complete test months per gauge
   (month complete = no missing day, as today).
3. ≥ 8 target events in the training years per gauge per target (else the gauge
   is dropped for that target, and the dropped set is reported).
4. Recession-analysis quality flag: ≥ 20 recession segments of ≥ 10 days
   identified in training years (§4.4); gauges failing this are excluded from
   the storage families only, not from the baselines, and the asymmetry is
   reported.
5. **Zero-flow / intermittent rivers (FH4):** zeros are kept as recorded
   (`AGENTS.md` §7 rule unchanged). For the supply/recession path, zero-flow
   days are treated as **censored** observations: recession segments start after
   the last zero-flow day, and the storage state is defined to sit at its floor
   `S = 0` through a zero-flow spell. No gauge is dropped for a high
   zero-flow fraction alone; the fraction is reported per gauge and enters a
   sensitivity analysis.

**Expected n:** all 472 CAMELS-IND gauges enter screen (1)–(2); with the
event-count and recession-quality screens the working sample is expected to be
≈ 200–300 gauges — **to be computed, not guessed** (`unknown, action: run
screens in week 3-4 and write n per stage to output/sample_report.csv`).

**Power (FS2 fix).** After gate G2, take the empirical gauge-level SD of paired
deltas, and compute the sign-test power curve for n ∈ {50, 100, 150, 200, 300}
at consistency 0.60 and the G2 effect size. If the projected power at the
achieved n is < 0.80 for H1's declared effect, the design document must say so
**before** scoring, and H1's wording stays pre-registered anyway
(negative results remain publishable per `AGENTS.md` §3.4).

**Regional framing (FH5 fix).** India is the study. Caravan-US runs the
identical protocol as a **transfer check** (same code path, `QDJ_REGION=us`),
reported in one table — no cross-region difference test is planned, because the
gate-G2 evidence says the contrast is not resolvable and the constants are not
transferrable.

### 4.3 Data contract

```text
India (CAMELS-IND), primary:
  forcings : date, prcp_mm, tmax_c, tmin_c, tavg_c  [as used today]
             PET field: unknown, action: check shipped forcing columns;
             if absent, PET arm = Penman-Monteith via Caravan-India-extension
             ERA5 forcing, Hargreaves kept as sensitivity arm only
  flow     : streamflow_observed.csv (as used today)
  attributes: land-cover fractions (irrigated/cropland), climate indices,
              geology/topography — for f_irr, Kc seasonality, and as
              catchment attributes in the descriptive pooled model
  IMD      : 0.25° daily rainfall and 1° tmax/tmin — catchment means are
             already inside CAMELS-IND; IMD grids are used for (a) validation
             of CAMELS-IND means on a 5-gauge subsample, (b) gap sanity checks,
             (c) any future district-level demand work. No new extraction in P1.
USA (Caravan-US), transfer arm:
  date, total_precipitation_sum, temperature_2m_{max,min,mean},
  streamflow, GLEAM PET  [same columns as today]
Climate projections (P3 only, not P1): CAMELS-IND-Proj daily streamflow,
  472 catchments, 4 SSPs (Singh et al. 2026).
```

`config.R` remains the only place paths and parameters live; add
`QDJ_PET_SOURCE = {shipped|pm_era5|hargreaves}` and
`QDJ_TRANSFER_ARM = {on|off}`.

### 4.4 The storage engine v2 (`R/functions/storage_engine.R`, new)

Replaces the CTMC **on the P1 feature path** (the CTMC file itself is frozen,
still verified, and reused unchanged by P3 and P2). One fluid state, three
fitted quantities, no reneging/boost/blocking — each old parameter is either
measured or deleted:

| Old (`config.R` §P) | Fate in P1 | Replacement and source |
|---|---|---|
| `d_mm = 20`, `f_irr = 0.10`, `Kc = 0.8`, `phi = 0.7` | **deleted from the state** | demand modelling leaves P1; re-enters only in P2/P3 where a measured demand record exists |
| `s_firm = 0.5`, `cap_mm = 10` | **deleted** | no abstraction model on the P1 path |
| `q_days = 60`, `K_days = 365`, `theta_mult = 1.5` | **replaced** | `q*` and `S_cap` from recession analysis (below), training years only |
| `alpha = 1.5`, `eta = 1/60`, `c = 1` | **deleted** | no queue artefacts on the P1 path |
| `rho_window = c(0.15, 1.20)` | **deleted** | completeness screens only (§4.2) |
| `rk4_dt`, `rk4_maxrate`, `block_guard` | **kept concept** | the fluid propagator keeps an automatic stability cap and a mass-balance ledger (§4.9) |

**Fitted per gauge from training years only:**

1. **Baseflow index (BFI).** Lyne–Hollick digital filter, `alpha = 0.925`
   `[assumption: standard value]`, baseflow `b(t)` and quickflow separated.
2. **Recession constant `k`.** On recession segments (≥ 10 consecutive days with
   negative daily flow change, no rain-day in segment): fit
   `ln Q(t+1) − ln Q(t) = −1/k` per segment, take the median across segments;
   also fit the low-flow nonlinearity exponent `b` from
   `−dQ/dt = a·Q^b` `[assumption: b ∈ [0.5, 1] checked, clipped to that range]`.
3. **Storage scale `S_cap` (mm).** Low-flow storage-outflow inversion
   (Brutsaert-type): with `Q_g(t) = (K_a·S(t))^b`, estimate `K_a` and the
   active storage scale from the low-flow envelope of training recessions;
   `S_cap` = the 95th percentile of implied `S` over training years.
   Regional fallback: if a gauge's segments < 20, borrow the basin-median
   `(k, b, K_a)` and flag the gauge `borrowed_parameters = TRUE`.
   `[assumption: linear storage (b = 1) is the fallback default]`.

**Propagated daily (fluid balance, no queue artefacts):**

```text
S(t+1) = clip( S(t) + Pe(t) − Ea(t) − Q_g(t), 0, S_cap )
Pe(t)  = max( P(t) − φm(month)·P(t), 0 )        # effective input, seasonal φm [assumption]
Ea(t)  = min( PET(t)·Kc_m(month), S(t) + Pe(t) ) # actual ET, supply-limited
Q_g(t) = ( K_a · S(t) )^b                        # recession release, fitted
```

Initialised at `S(0) = S_cap/2` with a 2-year warm-up excluded from features
`[assumption]`. The state is **S in mm of depth over the catchment** — no
claims, no hectares; the unit wall gains exactly two conversions
(`mm` ↔ `m³` already there) and the engine never sees m³/s (Q enters only
through the fitted recession law, not as a daily input — this is what keeps the
state's memory different from a smoothed Q).

### 4.5 Targets and leads

All targets are computed per gauge from the **training** flow record only:

1. **T1 (confirmatory):** monthly `SSI-3 ≤ −1`, where SSI-3 is standardised
   per calendar month on training years (existing `stage6_indices` code,
   leakage rules unchanged). Event definitions: **onset** (first month of a
   spell) and **persistence** (all months in a spell) scored separately and
   jointly; the joint series is the confirmatory target.
2. **T2 (descriptive):** monthly mean flow below the gauge's training-period
   **Q90** flow-duration threshold (recession-season months Oct–Jun for
   peninsular gauges; all months retained elsewhere, mask recorded per gauge).
3. **T3 (descriptive):** annual minimum 7-day flow class (below/above the
   training-period 10-year Q710 estimate) — the low-frequency low-flow endpoint
   that gives the repository its name.

**Leads:** h ∈ {1, 3, 6} months. Predictors are lagged so that a forecast issued
at month t uses information available at t; the target month is t+h. The E1/E2
distinction is retired; all evaluation is prospective in this sense.

### 4.6 Features and baselines

**Storage-family features (from §4.4 state and fits):**
`S_anom = (S(t) − S̄_month(t))/σ_month` (storage anomaly, month-of-year
climatology from training years); `ΔS_h` for h ∈ {1, 3}; `k` (recession
constant, time-invariant per gauge — a conditioning attribute, not a daily
feature); `BFI`; `S_cap`; `days_since_high_flow` (days since flow last exceeded
the gauge's Q10, capped at 365); and, if the G2 gate shows the CTMC's
severe-state probability carried signal, `P(S < q*)` from the fluid state with
`q* = ceil(60·λ̄)` **redefined on the training record only** — otherwise dropped.

**Baseline families (each gets the same ridge machinery and CV tuning):**

| Family | Predictors | Role |
|---|---|---|
| `climatology` | intercept + 11 month dummies | skill-score reference |
| `persistence` | target index at issue time (t, not t+h) | what an operator does today |
| `lagged_indices` | SPI-3, SSI-3, SSI-6, SPI-6 at lag h | standard practice |
| `api` | API(t) = Σ_{s=0..90} 0.95^s · P(t−s), plus PET accumulation | memory without storage physics |
| `storage` | storage-family features only | the mechanism, isolated |
| `storage_plus_indices` | storage features + lagged_indices | **the confirmatory family (H1/H2)** |

`storage_plus_indices` vs `best-of {persistence, lagged_indices, api}` is the
confirmatory contrast; "best-of" is selected on **training-year** CV only and
frozen before scoring, so the contrast is not chosen after seeing test skill.

### 4.7 Fitting protocol

- **Model:** the existing `fit_ridge_logistic` (IRLS, unpenalised intercept,
  11 month dummies in every family) with **one change**: the ridge penalty is
  tuned per family per gauge by 5-fold CV **inside the training years**,
  folds defined by calendar-blocks (contiguous year-blocks, not random
  months), fold structure and candidate grid `λ ∈ {0.1, 0.3, 1, 3, 10}`
  frozen in `config.R` before scoring (FS3 fix).
- **Standardisation:** features standardised on training rows only (existing
  rule); month dummies untouched.
- **Class balance:** reported per gauge per target per lead; if the positive
  rate is < 2% or > 98% the gauge-target-lead cell is flagged and scored with
  AUC-only `[rule: Brier is unstable at extreme rates]`.
- **No model sees a test year** until §4.8 scoring, once, at the end.

### 4.8 Evaluation protocol

- **Headline metric: Brier skill score vs `climatology`**, per gauge per
  family per lead: `BSS = 1 − B/B_clim`. Paired deltas between
  `storage_plus_indices` and the frozen best baseline are the confirmatory
  statistics. Brier, ROC AUC (existing tie-handling code), and reliability
  slope/intercept (existing `calibration_slope`) are secondary.
- **Uncertainty:** the existing two-level block bootstrap, unchanged design —
  resample years within gauge, then gauges — with `B = 2000`, seed from
  `config.R`; applied to the paired deltas and to BSS.
- **Spatial generalisation:** per-gauge design keeps the paired bootstrap;
  basin-level medians (the 22 CAMELS-IND river basins / Caravan HUC-2 units)
  and the US transfer arm carry the generalisation claim. A **pooled ridge
  model with catchment attributes** (one model across gauges) is descriptive
  only, evaluated with leave-one-basin-out CV — this is where a future
  ungauged-basin claim would start.
- **Multiplicity:** two confirmatory contrasts (§4.1); descriptive results are
  reported in a fixed table layout decided before scoring, with no
  post-hoc selection.
- **Harm bound:** as declared in §4.1; gauges beyond it are listed individually
  in the outputs, never hidden behind a median.

### 4.9 Verification battery changes (`R/verify.R`)

The 15-check battery is rebuilt as a **new battery with the same rigidity**
(target: 15/15 again before any scoring run):

- **Kept (adapted):** exact stationary/product-form checks where they still
  apply (CTMC checks stay attached to the frozen `queue_engine.R`); RK4
  stability cap; ledger identity for the **fluid balance** — new per-day
  identity `S(t+1) − S(t) = Pe − Ea − Q_g` (± 1e−9) holds to floating-point
  precision, the direct successor of the conservation ledger
  (`AGENTS.md` §4.2 three-way agreement becomes: analytic recession solution ↔
  fluid propagator ↔ daily ledger).
- **New:** recession-fit checks (recover a known `k` from a synthetic
  exponential recession to within 2%); `S_cap` inversion check (synthetic
  catchment with known storage → recovered `S_cap` within 10%);
  censoring check (zero-flow spells pin `S` to 0); leakage tripwire —
  a check that fails if any fitted object's data range crosses the
  2011-01-01 boundary.
- **Kept as-is:** unit-assertion checks in `units.R`; provenance sidecar
  integrity; paired-statistic toy case (V12).

### 4.10 Success criteria and falsification (frozen before scoring)

| Gate | Criterion | If passed | If failed |
|---|---|---|---|
| G2 (existing study) | see §3 decision rule | queue survives → decision meeting | null recorded; current manuscript retired/limited |
| P1-fit | storage engine verified 15/15; sample n ≥ 150 after screens, power reported | proceed to scoring | engine or sample fixed first; no scoring |
| P1-H1 | BSS(delta) median > 0, CI excludes 0, sign ≥ 60% gauges, 3-month lead | headline result; manuscript as §4.11 | H0-parity result reported honestly; paper reframed around the lead-time structure (1-month parity, 3/6-month gains) if present, else around the verified null + P3 |
| P1-H2 | same at 6-month lead | strengthens H1 | reported; does not gate the manuscript |

**Absolute falsifier:** if the storage family does not beat the frozen
best baseline at any lead ≥ 3 months on the primary target, the claim
"storage states add seasonal skill" is dead in this data and the project's
centre of gravity moves to P3 (where no ML benchmark exists) — this is stated
now so that it cannot be negotiated later.

### 4.11 Manuscript plan

Target: **HESS** (methods + large-sample result) or **Journal of Hydrology**
short communication; the verified null from G2 is either folded in as the
"why indices are not enough at seasonal leads" motivation or submitted
separately as a negative-result note. Repository artefacts: `STUDY.Rmd`
(rewritten around P1), `MANUSCRIPT.Rmd`, figures regenerated by `R/figures.R`
(lead-time skill curves per basin/climate class as the centrepiece figure),
one reproducibility page per `AGENTS.md` §8 Phase D.

---

## 5. Study P3 specification — climate-projection queue reliability (second paper)

**Working title:** *Deficit-queue reliability and recovery times for 472 Indian
catchments under four SSPs*. **Engine:** the frozen, verified CTMC — used
unchanged, exactly as its 15-check battery validates it. **Inputs:**
CAMELS-IND-Proj daily streamflow (Singh et al. 2026) plus projected P/ET
forcing; historical parameters (`Kc`, `phi`, `f_irr` from attributes — the G2
calibrated envelope, not the flat 0.10) projected forward.

**Outputs (the product):** per catchment per decade per SSP —
`P(backlog ≥ q*)` (transient, not stationary), recovery-time quantiles
(`first_passage_mean` machinery, already coded), and the reliability–
resilience–vulnerability triple in the McMahon–Adeloye sense. **No machine
learning benchmark exists for these quantities** — standard drought indices
cannot produce them — so the validation story is the verification battery
itself plus sensitivity analysis of the demand envelope, not a skill contest.

**Rules that bind:** `AGENTS.md` §3.2 (no raw CMIP6 numbers; the gate
discipline extends to CAMELS-IND-Proj — cite the published product, never a
raw model output), §3.1 (every queue number remains *illustrative under the
stated assumptions*), §3.3 (every assumption labelled). This paper is also the
natural home of the project's own novelty candidate C3 (time-varying recovery
distributions).

---

## 6. Future options (recorded, not scheduled)

- **P2 — groundwater deficit queue with measured backlog.** Arrivals = net
  irrigation requirement (IMD P/PET + crop calendars); buffer = aquifer
  storage; **backlog = observed water-table anomaly** (CGWB National Water Data
  Portal, quarterly + 6-hourly telemetry; GRACE/TWSA downscaling per Bhanja et
  al. 2020 for all 22 basins). Here reneging becomes pumping substitution and
  blocking becomes aquifer exhaustion — the two deleted artefacts come back as
  *measured* processes. Target: groundwater drought (SGI) and well-failure
  risk. Highest impact, heaviest data engineering; the natural third paper.
- **P4 — identifiability study.** The project's own candidate C2: on synthetic
  systems with known parameters and on gauged catchments, establish which
  queue/storage indicators are observationally equivalent under different
  demand–supply paths. Publishable as a HESS methods paper and the formal
  justification for why P1 uses recession-derived storage instead of assumed
  envelopes.

---

## 7. Repository surgery plan (file-by-file)

| File | Action | Notes |
|---|---|---|
| `R/config.R` | **edit** | delete `rho_window`, `q_days/K_days/theta_mult`, `alpha/eta/c` from the P1 path (keep under a `P3_CTMC` block for P3); add `PET_SOURCE`, `TRANSFER_ARM`, ridge CV grid/folds, API decay `k`, Lyne–Hollick `alpha`, BFI parameters, screen criteria, leads `c(1,3,6)`, targets list |
| `R/functions/storage_engine.R` | **new** | BFI filter, recession fits, `S_cap` inversion, fluid propagator with ledger; docstring carries units in line 1 (`AGENTS.md` §6) |
| `R/functions/units.R` | **extend** | add `phi_m(month)`, `Kc_m(month)` seasonal curves; Hargreaves retained but wrapped so PET source is explicit; every new conversion asserted |
| `R/functions/pipeline.R` | **rewrite stages** | `common_rates` → drop `A_cmd`/`mu` on the P1 path (keep for P3); `common_screen` → completeness-only (FQ3/FQ4); new `stage5_storage()` replaces `stage5_queue()` on the P1 path; `stage6_indices` unchanged; `stage6_design` → new family table (§4.6) and h-lagged design; `stage7_*` unchanged except BSS |
| `R/functions/eval.R` | **extend** | add `brier_skill()`; CV-tuned ridge wrapper (grid + folds from config) |
| `R/study.R` | **edit** | gates: G2 block (both regions, old+new side by side) then P1 block (India primary, US transfer arm behind `QDJ_TRANSFER_ARM`) |
| `R/verify.R` | **rebuild** | new 15-check battery per §4.9; gate G1 redefined to the new battery |
| `R/figures.R` | **edit** | centrepiece: lead-time BSS curves by basin/climate class; keep map; drop queue figures from the P1 path |
| `STUDY.Rmd` / `MANUSCRIPT.Rmd` / `README.md` / `HELP.md` | **rewrite** | same commit as the code change (`AGENTS.md` §3.8/§3.9 protocol); G2 decision paragraph appended to `STUDY.Rmd` |
| `AGENTS.md` | **edit** | §1 and §8 updated to P1/P3 framing; frozen sentence pointer → §9 of this file; never-list items 8–9 satisfied by this document |
| `PIVOT.md` | **add** | this file, at repository root |

---

## 8. Roadmap — 12 weeks, with acceptance criteria

| Weeks | Work package | Concrete outputs | Acceptance |
|---|---|---|---|
| 1–2 | **Gate G2** (§3): PET, calibrated envelope, leakage fixes, new baselines, tuned ridge, BSS | `output/gateG2_summary.csv` + sidecar; decision paragraph in `STUDY.Rmd`; variance table | decision rule applied as written; both regions rerun; 15/15 on old battery |
| 3–4 | Sample reconstruction: completeness screens, intermittent-river censoring, power analysis; recession analysis per catchment | `output/sample_report.csv`; per-gauge `(k, b, K_a, S_cap, BFI)` table; power curve | screens documented; n reported per stage; ≥ 20 segments rule enforced or flagged |
| 5–6 | `storage_engine.R` + new verification battery; targets T1–T3 at leads 1/3/6; design matrices; CV-tuned ridge wrapper | verified engine; frozen evaluation protocol (pre-registration text committed) | new battery 15/15; leakage tripwire green; families frozen |
| 7–8 | Fitting and scoring: per-gauge BSS, paired deltas, two-level bootstrap; confirmatory contrasts H1/H2 | `output/p1_paired.csv`, `output/p1_summary.csv` + sidecars | scored once; contrast identities match §4.1 exactly |
| 9–10 | Diagnostics: reliability diagrams, basin/climate-class skill curves, zero-flow and PET-source sensitivities, US transfer arm | robustness appendix; all figures | no table cell without a script (`AGENTS.md` §4.3) |
| 11–12 | Manuscript + reproducibility page; HESS/JH/WRR short article; G2 null folded in or split | submission-ready draft + green battery | `STUDY.Rmd` knits; every number sourced; session log closed |

Weeks 1–2 and 3–4 may overlap only after the G2 decision rule has been applied
in writing.

---

## 9. Novelty record for the pivot

**Constraint:** `AGENTS.md` §2 forbids agents from rewording the frozen
sentence. That sentence remains attached to the **retired study**. P1 requires
a **new frozen sentence**, to be produced by a Phase-A-style screen run *before*
the P1 manuscript is drafted. Draft to be confirmed by that screen (not a claim):

> "Within [databases and screens to be run], we found no large-sample study for
> Indian catchments that evaluates recession-derived storage-deficit states as
> forecasting features for hydrological drought and low-flow events at
> sub-seasonal to seasonal leads against pre-specified memory baselines, with
> mass-balance-verified state estimation and pre-registered confirmatory tests."

**Search queries to run (screen protocol as in `P01/search_protocol.md`):**
`(storage deficit OR "storage state" OR recession OR baseflow) AND (drought forecast* OR "low flow" forecast*) AND (India OR "large sample" OR CAMELS)`; 
`("catchment memory" AND drought AND forecast)`; 
`(SPEI OR SSI OR "flow duration" OR Q90) AND (sub-seasonal OR seasonal) AND (forecast* OR prediction) AND India`; 
plus forward-citation traces from Sutanto & Van Lanen (2022) and Hammond et al. (2025).

**Anchors already verified in the external review** (URLs consulted):
Kendall 1957 (JSTOR 2983815); Sutanto & Van Lanen 2022 (Sci Rep
s41598-022-06553-5); Hammond et al. 2025 (Front Water 10.3389/frwa.2025.1709138);
CAMELS-IND-Proj 2026 (Sci Data s41597-026-08858-w); CGWB NWDP (nwdp.nwic.gov.in);
Bhanja et al. 2020 (PMC7526560); Hameed et al. 2025 (J Hydrol Reg Stud
S221458182500775X). Standard references named without URL: Moran 1954; Gani
1969; Wilhite & Glantz 1985; Van Loon 2015; Brutsaert 2008; McMahon & Adeloye
2005. Dataset citations per `AGENTS.md` §7.

---

## 10. Additional agent rules for the pivot (extends `AGENTS.md`)

**Never:**

1. Never start P1 scoring before the G2 decision is recorded in `STUDY.Rmd`.
2. Never fit, screen, threshold, standardise or tune on test years — this
   includes "just checking" (FQ4 was found by exactly such a line).
3. Never let the fluid storage state consume daily observed Q as an input
   (§4.4: Q enters only through the fitted recession law).
4. Never describe storage features as independent information (§4.1
   limitation is binding wording, not optional).
5. Never reintroduce `alpha`, `eta`, `theta_mult`, blocking or the utilisation
   window on the P1 path; they exist only inside the frozen CTMC file and the
   P3/P2 studies.
6. Never report a pooled-model, leave-one-basin-out number as confirmatory (§4.8).

**Always:**

1. Every new feature ships with a verify test *before* the first run that uses
   it; the fluid ledger identity is checked per day, per gauge.
2. Every gate decision is written down *before* the gate runs (this file, §3
   and §4.10, is that writing).
3. Every output CSV keeps its JSON provenance sidecar (`AGENTS.md` §4.6).
4. Report with file + line, in the `AGENTS.md` §4.4 style.

**Session ritual addition:** state the current gate (G2 / P1 / P3) and the
battery status (`Rscript R/verify.R`) in the first line of every session
summary.

---

## 11. Assumptions and placeholders

Marked `[assumption]` inline above; consolidated:

1. PET source for CAMELS-IND — `unknown, action: check shipped forcing columns`
   (§4.3); fallback chain declared.
2. Seasonal `phi_m`/`Kc_m` curves — FAO-56-style two-season simplification
   `[assumption]`; sensitivity axis, not a claim.
3. Lyne–Hollick `alpha = 0.925`, API decay `0.95`/90-day, ridge grid and
   5-fold year-block CV, `b ∈ [0.5, 1]`, `S(0) = S_cap/2` with 2-year warm-up —
   standard or declared defaults, all frozen in `config.R` before scoring.
4. Harm bound derivation pending the G2 variance table (§4.1).
5. n after screens, power at achieved n — computed in weeks 3–4, never guessed
   (§4.2).
6. CAEVAN read as the Caravan family (§2 preamble); if it is a distinct
   dataset, `unknown, action: list its exact columns and gauges`.

---

## 12. References (as verified 26 November 2026)

- Kendall, D. G. (1957). Some Problems in the Theory of Dams. *JRSS A*.
  https://www.jstor.org/stable/2983815
- Gani, J. (1969). Recent advances in storage and flooding theory. *Adv. Appl.
  Probab.* (Moran 1954 founded stochastic storage). (standard reference)
- Sutanto, S. J., & Van Lanen, H. A. J. (2022). Catchment memory explains
  hydrological drought forecast skill. *Scientific Reports*, 12.
  https://www.nature.com/articles/s41598-022-06553-5
- Hammond, J., et al. (2025). ML generated streamflow drought forecasts
  1–13 weeks ahead, 3,219 US gauges. *Frontiers in Water*.
  https://www.frontiersin.org/journals/water/articles/10.3389/frwa.2025.1709138/full
- Singh, A., et al. (2026). CAMELS-IND-Proj: daily streamflow projections for
  472 catchments under four SSPs. *Scientific Data*.
  https://www.nature.com/articles/s41597-026-08858-w
- Mangukiya, N. K., et al. (2025). CAMELS-IND. *ESSD*, 17, 461–491.
  https://doi.org/10.5194/essd-17-461-2025
- Kratzert, F., et al. (2023). Caravan. *Scientific Data*.
  https://doi.org/10.1038/s41597-023-01975-w
- CGWB National Water Data Portal (groundwater levels, incl. 6-hourly
  telemetry). https://nwdp.nwic.gov.in/dataset/?organization=cgwb
- Bhanja, S. N., et al. (2020). Groundwater storage change, all 22 Indian river
  basins (in situ + GRACE). https://pmc.ncbi.nlm.nih.gov/articles/PMC7526560
- Hameed, M., et al. (2025). Baseflow recession analysis as a groundwater
  storage proxy. *J. Hydrol.: Reg. Stud.*
  https://www.sciencedirect.com/science/article/pii/S221458182500775X
- Margreth, M., et al. (2024). Applying recession models for low-flow
  prediction. (standard reference, via search record)
- Wilhite, D. A., & Glantz, M. H. (1985); Van Loon, A. F. (2015); Brutsaert,
  W. (2008); McMahon, T. A., & Adeloye, A. J. (2005). (standard references)

*End of PIVOT.md — the living change record. Update §3/§4.10 gate tables in
place as gates resolve; never by silent edit.*
