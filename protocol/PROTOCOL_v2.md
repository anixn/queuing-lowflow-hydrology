# PROTOCOL_v2 — predeclared protocol for the multi-catchment deficit-queue test

**Status:** LOCKED. Tag `protocol-v2-locked`. Date: 26 November 2026.

> **Timing disclosure.** The endpoints and rules were fixed by the governing
> plan, now committed at `protocol/REDESIGN_PLAN_v2_R.md`. The protocol document
> itself was finalised after the first execution. It is a retrospective
> documentation of a pre-specified design, not proof of prospective
> registration. All amendments are recorded in `protocol/CHANGELOG.md`.
**Governing plan:** `protocol/REDESIGN_PLAN_v2_R.md` §§3.1–3.12, Appendix A.

This protocol fixes the endpoints, contrasts, targets, variants, sensitivities,
exclusion rules, event definition, harm bound and power before any final result
is quoted. It is a formalisation of the plan's predeclared design; the endpoints
were fixed by that dated plan, not chosen after seeing a held-out metric.

Amendments after the tag are allowed only as logged entries in
`protocol/CHANGELOG.md` (date, reason, scope). Any amendment that touches an
endpoint forces a rerun of S7–S8 with both old and new results reported.

---

## 1. Data sources (read-only inputs)

| Input | Role | Path (via `R/config.R`) |
|---|---|---|
| CAMELS-IND catchment-mean forcings | daily precipitation, PET, temperature | `CAMELS_FORCING_DIR` |
| CAMELS-IND observed streamflow | daily `Q` (m^3/s) | `CAMELS_FLOW_FILE` |
| CAMELS-IND attributes | area, basin, CWC coordinates | `CAMELS_ATTR_DIR` |
| Drought Intelligence Explorer v2 | district SMA, SPI-3, SPEI-3, district polygons | `DROUGHT_ROOT` |

CAMELS-IND citation: Mangukiya et al. (2025), *Earth System Science Data*, 17,
461–491, doi:10.5194/essd-17-461-2025 (Zenodo 14999580, CC BY 4.0).

`[assumption]` GLEAM PET is the primary PET; Hargreaves with the 0.408
radiation conversion is the predeclared alternative (sensitivity axis).

## 2. Unit system (the unit wall)

For gauge `g` with command area `A_cmd = f_irr * A_catchment` (m^2):

```
V_claim      = d/1000 * A_cmd            [m^3]      (one per gauge)
need_mm(t)   = max(Kc(doy)*PET(t) - phi*P(t), 0)    [mm/day]
lambda(t)    = need_mm(t)/d              [claims/day]
S_mm(t)      = Q(t)*86400*s_firm / A_cmd * 1000     [mm/day]
mu(t)        = min(S_mm(t), cap_mm)/d   [claims/day]
```

`d = 20 mm`, `phi = 0.7`, `s_firm = 0.5`, `cap_mm = 10`, `f_irr = 0.10`
(default; swept). The queue engine receives **claims/day only**. Demand and
supply share the same `V_claim`; no other claim volume exists anywhere.

## 3. Gauge inclusion and exclusion

**As amended (26 November 2026).** Selection uses the V1 screen, not the V0
reconnaissance table, and the endpoint set is restricted to units with at least
5 training and 3 test DESIGN events. See `protocol/CHANGELOG.md`.

A gauge enters the analysis set only if **all** hold:

1. Profiled: >= 300 observed flow days and necessary forcings present.
2. Utilisation window under SUP-1: `0.15 <= rho = sum(lambda)/sum(mu) <= 1.20`.
3. Zero fraction `< 0.30` and longest interior gap `<= 30 days`.
4. Both-period coverage: `>= 3 years` of flow in 1981–2010 and `>= 2 years` in
   2011–2020.
5. At most **3 gauges per basin** (ranked by the smaller of the two period
   coverages), to limit within-basin dependence.

Gate G3 requires `>= 15` gauges in the window. The realised set is 24 gauges
across 11 basins. A gauge is never dropped or added after seeing E1/E2.

## 4. Zero-flow semantics

Every zero day is classified as `positive`, `real-zero`, `artifact`, `unknown`
or `missing` using same-basin peers (`match_grade = "proxy"`; no independent
CWC/India-WRIS daily record was available).

- **V1 (primary):** artifact and unknown zeros become missing.
- **V0 (sensitivity):** zeros as recorded (quantifies the artifact).
- **V2 (sensitivity):** keep positive and real-zero days, then drop every day of
  a calendar month whose verified fraction is below 90%.

## 5. Gap rules

**Implemented rule (amended 26 November 2026).** Every missing day pauses the
queue state, and any month containing a missing day is excluded from monthly
aggregation and model fitting. This is stricter than the original 7-day / 30-day
plan; the divergence is recorded in `protocol/CHANGELOG.md`. Nothing is
interpolated silently.

## 6. Supply variants

- **SUP-1 (primary):** firm share `s_firm` of observed flow, capped at `cap_mm`.
- **SUP-2:** flow clipped at its 5th percentile (dependable flow), then capped.
- **SUP-3:** full `cap_mm` above an ecological floor (`eco_frac` of mean flow),
  otherwise SUP-1.

## 7. Queue parameters (catchment-relative)

```
q*    = ceil(q_days * lam_bar)                        q_days = 60
K     = min(80, max(25, ceil(K_days * lam_bar)))       K_days = 365
theta = ceil(theta_mult * q*)                          theta_mult = 1.5
alpha = 1.5,  eta = 1/60 per day,  c = 1
```

Kernel: finite-capacity birth-death CTMC, RK4 with automatic step cap
(`dt <= 0.5`, `dt*maxrate <= 0.5`), renormalisation each step, and a per-day
conservation ledger (`offered = served + reneged + blocked + Delta_backlog`)
that stops the pipeline if it fails. Blocking guard: `max P(Q=K) < 1e-3`.

## 8. Target and event definition

- **Primary (T1, external SMA):** district soil-moisture anomaly `<= -15%`.
  The product uses its own 1981–2020 climatology, which overlaps the test years;
  this leakage is **disclosed**, not hidden.
- **Leakage-clean sensitivity (T1-strict):** training-only SPI-3 drought
  (`spi3 <= -1`, standardized on 1981–2010), with the `spi3` predictor dropped.
- **Event definition:** a drought event is >= 2 consecutive target months below
  threshold; isolated monthly hits are scored but reported separately.
- **Splits:** train 1981–2010; test 2011–2020. Features standardized on training
  rows only.

## 9. Endpoints and decision rules (confirmatory)

### E1 — concurrent diagnostic

Per gauge `g`, on the **same** held-out months for both families:

```
Delta_g = Brier_g(SSI-3) - Brier_g(SSI-3 + queue)
```

Cross-gauge success requires **all**:

1. `median(Delta_g) > 0`.
2. two-level bootstrap 95% CI (resample gauges, then years within gauge,
   recomputing the pooled per-gauge Brier difference) excludes 0.
3. one-sided sign test `p < 0.05` with improvement in `>= 60%` of gauges.
4. harm bound: no gauge with `Delta_g < -0.005` driven by calibration breakdown.

### E2 — prospective (1-month lead)

Identical rules, with all predictors at month `t-1` (`ssi3_lag`,
`p_ge_q_lag`, `p_ge_q_inc`) predicting the outcome at month `t`.

### Multiplicity

E1 and E2 are the two protected confirmatory tests. Everything else — AUC,
log loss, reliability, event timing, queue-alone, SPEI+queue, all sensitivities
— is **secondary/exploratory**, reported in full, and never upgraded post hoc.

## 10. Harm bound

`Delta_g < -0.005` on a gauge triggers a calibration investigation before any
claim. A breached bound is reported; it is not a licence to change the endpoint.

## 11. Power (gate G4)

> **Post hoc.** The MDE below is computed from the held-out per-unit deltas. It
> is an **interpretability bound**, not prospective power, and the observed
> columns were added after execution.

Using the paired per-gauge effect-size distribution (from held-out deltas),
`alpha = 0.05`, power `= 0.80`, `MDE = (z_0.975 + z_0.80) * SD / sqrt(N)`:

| Metric | SD | MDE at N=15 | Observed median |
|---|---:|---:|---:|
| Brier Delta | 0.005123 | **0.003706** | +0.002044 |
| AUC Delta | 0.081892 | **0.059238** | +0.022222 |

Simulation sign-test power at N=15 (2,000 reps):

| Metric | Assumed uplift | Power |
|---|---:|---:|
| AUC | +0.02 | 0.090 |
| AUC | +0.05 | 0.394 |
| AUC | +0.08 | 0.759 |
| Brier | +0.001 | 0.063 |
| Brier | +0.002 | 0.165 |
| Brier | +0.003 | 0.352 |

**Interpretation (not a G4 pass).** The primary Brier null is interpretable:
the observed +0.0020 is below the MDE of 0.0037. But the study is **not well
powered** for the AUC secondary at N=15 (power 0.394 for a +0.05 uplift), so the
ranking signal is secondary and hypothesis-generating, not a powered
confirmatory result. The strict-target positive is a sensitivity, not a powered
win.

## 12. Predeclared sensitivity axes (one factor at a time)

| Axis | Levels (baseline in bold) |
|---|---|
| Zero variant | V0 / **V1** / V2 |
| Demand `f_irr` | 0.03 / **0.10** / 0.25 |
| Supply variant | **SUP-1** / SUP-2 / SUP-3 |
| Intake cap (mm/day) | 5 / **10** / 20 |
| `q_days` | 45 / **60** / 90 |
| `K_days` | 180 / **365** |
| PET source | **GLEAM** / Hargreaves |
| Target | **T1 external SMA** / T1-strict SPI-3 |

Interactions are **not** swept (full cross = 432 runs, explicitly out of scope).
Every level is reported regardless of direction.

## 13. Parameter defaults (Appendix A of the plan)

All live in `R/config.R`. Key values: `d_mm=20`, `phi=0.7`, `sowing_doy=200`,
`season_length=120`, `Kc=0.4/1.2/0.35`, `f_irr=0.10`, `s_firm=0.5`,
`cap_mm=10`, `q_days=60`, `K_days=365`, `theta_mult=1.5`, `alpha=1.5`,
`eta=1/60`, `c=1`, `L2=1.0`, train 1981–2010, test 2011–2020,
`max_short_gap=7`, `long_gap_exclusion=30`, `rk4_dt=0.5`,
`rk4_maxrate=0.5`, `block_guard=1e-3`, `rho_window=c(0.15,1.20)`,
`seed=20261125`.

## 14. Outcome routing (fixed in advance)

> **Recorded after execution.** The route below is the outcome observed on
> 26 November 2026; it is not a pre-registered prediction.

- **Path A:** both E1 and E2 pass -> positive multi-catchment evaluation.
- **Path B:** rules fail, test powered and clean -> predeclared evaluation +
  utilisation diagnosis (honest null).
- **Path C:** power inadequate and utilisation window cannot be populated ->
  verification + design-requirements paper; confirmatory question withdrawn.

**Current route: Path B.** E1 and E2 fail rules 1–4; the test is powered and the
engine is verified. No v1 number is cited as a v2 result.

## 15. Known gaps and disclosures

- `renv` is not installed in this environment; no lockfile is shipped. This is a
  reproducibility gap to close before submission. `R/install_packages.R` is the
  documented fallback and prints the exact installed versions.
- Zero-flow classification is proxy-grade (basin peers), not an independent
  CWC/India-WRIS record.
- Stage-B measured irrigation demand was unavailable; demand is the Stage-A
  envelope with an `f_irr` sweep.
- The primary external SMA target is not strictly leakage-free; the
  training-only SPI-3 sensitivity is the clean check.
- No future-climate (CMIP6) result is produced; that stage is gated and no raw
  CMIP6 number may be published.
