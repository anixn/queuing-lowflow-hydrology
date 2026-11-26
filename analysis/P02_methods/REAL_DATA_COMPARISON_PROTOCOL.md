# Real-data comparison protocol — locked before results (v1, SUPERSEDED)

> **Superseded 26 November 2026.** This is the v1 two-gauge protocol. The v2
> predeclared protocol is `../../protocol/PROTOCOL_v2.md`. Retained for
> provenance only.

Date: 25 November 2026. Amended after independent methodological review and **before any model-comparison results were examined**. This file is the analysis contract.

## 1. Objective and claim boundary

Test whether a finite-capacity deficit-queue indicator adds held-out information for observed district soil-moisture drought beyond a streamflow-index baseline on two Krishna-basin gauges:

- gauge 4026 Kurundwad → Sangli district, Maharashtra;
- gauge 4064 Yadgir → Yadgir district, Karnataka.

The confirmatory claim is limited to **lower nominally held-out Brier score when queue probability is added to SSI-3**. Model fitting is held out, but the supplied SMA target uses an external 1981-2020 climatology, so target construction is not strictly leakage-free. This is not a claim of forecasting, causation, crop-loss prediction or broad superiority.

This is **retrospective diagnosis**. Same-month observed streamflow is allowed. No ahead-of-event forecast is claimed.

## 2. Primary observed target

Use Drought Intelligence Explorer v2.0.0 district **Soil Moisture Anomaly (SMA) exactly as supplied**:

- drought month = SMA ≤ −15%;
- units = percent anomaly from the product's per-calendar-month climatology;
- product metadata labels `accumulation_months: 3`; this analysis applies no additional rolling transform;
- the supplied climatology is 1981-2020, which overlaps the nominal test years;
- source = `data/drought/soil_moisture.csv` in DOI `10.5281/zenodo.24444860`;
- source period used = January 1981–December 2020;
- missing target months are excluded, never imputed.

SPEI-3 is **not** a target. Using it as both target and predictor would be circular.

## 3. Queue construction

For each gauge and day:

- demand λ(t): the exact formula in `P02/R/01_build_rates.R`; generic 120-day Kharif season, sowing day 200, Kc peak 1.2, effective-rain fraction 0.7;
- area proxy: 45,000 ha for Sangli; 72,252 ha for Yadgir;
- claim depth: 20 mm; claim volume = area × 10 × depth;
- supply μ(t): recorded discharge × 86,400 × firm share 0.5 ÷ claim volume, capped at 3 claims/day;
- queue: K=20, c=1 aggregate supply, θ=8, α=1.5, η=0.02 per claim/day;
- primary severe state: Q ≥ 6 claims = 120 mm;
- monthly predictor: mean end-of-day Pr(Q ≥ q*) within the month;
- 1980 is used only for queue/rolling-window warm-up and is not a model-fitting year.

All demand, area, firm-share and structural parameters are `[assumption]`. Proxy-derived queue outputs are **illustrative, under the stated assumptions**. Discharge and district SMA are `[measurement]`, subject to the source caveats below.

The daily RK4 step is selected from the generator-rate bound and may not exceed 0.1 day.

## 4. Predictors and baselines

1. **Climatology:** training drought frequency separately for each calendar month; probabilities are clipped to [10⁻⁶, 1−10⁻⁶] only to keep log loss finite.
2. **SPI-3:** published district SPI-3 from Drought Intelligence Explorer.
3. **SPEI-3:** published district SPEI-3 from Drought Intelligence Explorer.
4. **SSI-3:** log1p of trailing 3-month mean gauge discharge, standardized per calendar month with 1981–2010 mean and population standard deviation. This is an SSI-style log anomaly, not a gamma/empirical-CDF SSI.
5. **Queue:** monthly mean Pr(Q ≥ q*).
6. **SSI + queue:** joint logistic model.

Every logistic model includes an intercept and 11 calendar-month indicators. Predictors are standardized with training means and population standard deviations. L2 strength is fixed at 1.0 on the summed log loss; the intercept is unpenalized. There is no class weighting or test-year tuning.

The supplied SMA target and published SPI/SPEI product use a **1981–2020 reference period**, which overlaps the test years. Raw soil-moisture/CHIRPS/ERA5 inputs are not present locally, so SMA is an **external, non-strict target** and SPI/SPEI are **external, non-strict benchmarks**. They do not determine the confirmatory decision. All model fitting, additional scaling, the climatology baseline and SSI construction use 1981–2010 only.

## 5. Common analysis sample and split

- Training: 1981–2010.
- Nominal testing window: 2011–2020.
- Whole years are held out; no random daily split.
- Observed discharge ends on 5 November 2020 for 4026 and 11 March 2019 for 4064. Gauge 4026 also has a 611-day interior gap beginning 1 March 2019. With the seven-day interpolation cap below, the usable record for **both gauges ends on 28 February 2019**, the last complete month before an unfillable gap or record end. Trailing incomplete months are excluded, not extrapolated.
- A month enters the analysis only if the SMA target and all candidate predictors are finite.
- Exactly the same complete-case months are scored for every model within a gauge.
- Expected, available, excluded and common complete-case months are reported by gauge and split. Training has 360 target/flow-available months but 358 common complete cases because January-February 1981 lack SPI/SPEI. Each gauge has 98 test months (2011–2018 plus January–February 2019); the bootstrap resamples those nine available test years.

## 6. Missing and zero streamflow

- Primary reconstruction uses time-linear interpolation only for interior gaps of **seven days or less**, with every filled day flagged. Longer gaps are not interpolated.
- This interpolation is retrospective and may use the later side of a short internal gap; it is not a forecasting operation.
- A long gap ends the usable record at the preceding complete month, as specified in §5; no trailing values are extrapolated.
- A predeclared **causal forward-fill sensitivity** repeats the primary q*=6 analysis.
- A second predeclared sensitivity excludes months containing any imputed-flow day.
- Zero entries are retained as recorded but their semantics remain unresolved. No ρ interpretation is made on zero-flow days.

## 7. Metrics and decision rule

### Confirmatory

- Primary metric: held-out **Brier score** for SMA drought occurrence.
- Primary comparison: SSI + queue versus SSI alone at q*=6.
- Each gauge is a separate co-primary analysis. Overall support requires lower Brier score in **both** gauges.
- A paired year-block bootstrap (2,000 resamples of the available test years; base seed 20261125 plus the gauge ID, giving 20265151 and 20265189) reports a 95% percentile interval for the Brier-score difference. The interval is descriptive; the point-estimate rule above is unchanged.

### Secondary and exploratory

- Brier skill relative to climatology.
- AUC and log loss.
- Held-out calibration intercept and slope, reported as diagnostics without recalibrating predictions; all plotted/scored probabilities remain uncalibrated model outputs.
- Event-month mean predicted probability.
- q*=4 and q*=8; all outcomes are reported and none may replace q*=6.
- Comparisons with published SPI/SPEI and with the lowest-Brier conventional model are descriptive external benchmarks. The lowest-Brier model is not selected for a confirmatory claim.

Negative Brier differences are improvements; positive AUC differences are improvements.

## 8. Events and temporal description

An SMA event is a run of consecutive months with SMA ≤ −15%. Missing months break runs. Events beginning in 2011–2020 are summarized; boundary-censored events are flagged.

The optional timing quantity is the first uncalibrated SSI+queue predicted probability >0.5 within six months before/on event onset, using held-out predictions only. It is named **retrospective onset offset**, not lead time. Zero means concurrent threshold exceedance. No forecasting interpretation is allowed.

## 9. Required outputs

- `analysis/P02_methods/data/real_data_comparison_monthly.csv`
- `analysis/P02_methods/data/real_data_comparison_metrics.csv`
- `analysis/P02_methods/data/real_data_comparison_events.csv`
- `analysis/P02_methods/data/real_data_bootstrap.csv`
- `analysis/P02_methods/data/real_data_imputation_sensitivity.csv`
- `analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`
- one reproducible six-panel figure showing observed SMA, model-predicted probabilities, Brier skill and reliability

## 10. Interpretation limits regardless of outcome

- λ is a process scenario, not measured irrigation demand.
- District area proxies are assumptions, not gauge command areas.
- Gauge and district spatial scales differ.
- Same-month flow makes this retrospective diagnosis only.
- Supplied SMA and published SPI/SPEI have a non-strict external 1981–2020 reference period; target construction is not strictly held-out.
- Two gauges are a pilot; no population-general significance is claimed.
- Soil moisture is a land-state target, not a direct crop-loss measure.
- Gauge 4026/4064 zero-flow semantics and regulation remain unresolved.
- CAMELS attributes show substantial dam presence but do not establish station operating rules.
- A null or negative result is retained unchanged.
