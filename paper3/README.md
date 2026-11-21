# Paper 3 working package — ML-assisted non-stationary queue methods

Target: **HESS, 2028 Q4** (per the GLM 5.3 roadmap). Starts after P1 is stable.

**Read `../START_HERE.md` first** for a plain-language summary of what has been
done and what is being done now. The full novelty verdict and ordered work plan
are in `../NOVELTY_AND_PLAN_REPORT.md` (Phases A–D). The key constraint for P3 is §3.4
there: ML-for-queues, learned arrival rates and non-stationary/correlated
arrivals are all mature fields, so the contribution must be hydrological
parameterisation, unmet-demand interpretation, exact validation and
pre-specified drought-event tests.

## Bridge from P1

P1 (`../paper1/`) establishes *why* drought can be read as a queue state and
audits the prior art. P3 supplies the *methods*: how to estimate the
time-varying rates λ(t), μ(t) from covariates, and how to prove the resulting
indicators are trustworthy. The shared model is `../paper1/src/queue_core.py`.

P1's Box 1 already showed that averaging a seasonal signal understates peak
backlog by 2.3×. P3 asks the follow-on question: can an estimator recover that
risk from noisy, incomplete covariate data, and does it beat simple baselines?

## What is here

| File | Purpose |
|---|---|
| `src/nonstationary_bench.py` | Exact benchmarks: periodic (Floquet) steady state and Markov-modulated arrivals (MMPP/2). NumPy only. |
| `src/test_nonstationary_bench.py` | 6 acceptance tests, including independent reproduction of P1's Box 1 numbers. |
| `src/rate_estimators.py` | NumPy-only gradient-boosted trees, monotone-μ isotonic component, log-link positivity, mass calibration, bootstrap intervals. |
| `src/test_rate_estimators.py` | 7 acceptance tests for the estimators. |
| `src/evaluate_estimators.py` | Held-out-year evaluation on periodic and warming synthetic scenarios; constant/climatology baselines. |
| `R/01_build_rates.R` | **Real data.** Reads CAMELS-India forcings + observed streamflow for one gauge, writes daily λ(t), μ(t) CSV. Base R only. |
| `R/02_run_queue.R` | **Real data.** Reads that CSV, RK4-solves the CTMC, writes E[Q], Pr(Q≥6), ρ and unmet demand. Base R only. |
| `R/03_extract_cmip6.R` | **Future data.** Extracts one CMIP6 model/SSP at the pilot gauge, converts units and computes Hargreaves ET0. Needs `ncdf4`. |
| `data/rates_4026.csv` | Generated daily rates for gauge 4026 (Kurundwad). |
| `data/rates_4026_indicators.csv` | Generated indicator summary. |

## Run

Use the existing `drought` Conda environment. The default `python` on this
machine has no NumPy.

```powershell
# Exact benchmarks (synthetic)
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/nonstationary_bench.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_nonstationary_bench.py

# Rate estimators (synthetic)
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/rate_estimators.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/evaluate_estimators.py
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper3/src/test_rate_estimators.py

# Real-data pilot, in this order (R 4.5.1 path shown)
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R

# CMIP6 SSP extraction (after the chosen model/SSP has finished downloading)
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/03_extract_cmip6.R
```

The R scripts are deliberately **linear**: edit the settings in BLOCK 1, then
run the blocks top to bottom. No packages, no functions except one small
generator helper in `02_run_queue.R`.

## Verified results (synthetic, illustrative only)

**Floquet benchmark** independently reproduces P1's RK4/DES results:
periodic peak E[Q] = 2.1295 and peak Pr(Q≥6) = 0.0733, versus
stationary-at-mean 0.9161 and 0.0043. Monodromy eigenvalue residual
1.5×10⁻¹⁵. This is a genuinely different solution method (left eigenvector of
the one-period propagator), so it validates the P1 solver.

**Burstiness test.** At the same mean arrival rate (0.9/day), replacing Poisson
arrivals with a two-regime Markov-modulated process (high 1.35, low 0.45,
switching every ~50 days on average) raises E[Q] from 1.075 to 1.247 — a 1.16×
amplification. Interpretation: arrival clustering matters, but less than the
seasonal rate variation (2.3×) in this parameterisation. This must be tested
across regimes before any general claim.

**Estimator evaluation.** On held-out synthetic years, the constant-rate
baseline severely understates peak risk; climatology understates the warming
scenario. The GBDT estimators are closer, but μ error near ρ≈1 remains the
dominant weakness. No result should be reported until this is fixed.

**Numerical trap documented.** RK4 on the matrix propagator is unstable when
dt·|λ_max| exceeds ~2.78; the generator reaches |λ_max| ≈ 8.5/day. Both the
Python benchmark and `02_run_queue.R` cap dt automatically.

## Real-data pilot (pipeline check, NOT results)

Gauge **4026 Kurundwad** (Krishna, Maharashtra), 1980–2020 CAMELS-India
catchment forcings and observed streamflow. Settings assumed in
`01_build_rates.R` with the locked provisional convention: command area
50,000 ha, one claim = 10⁷ m³ = 20 mm over the command, K=20 claims = 400 mm,
firm-supply share 0.5, service cap 3 claims/day = 60 mm/day. See
`../START_HERE.md` §4. Over 2001–2020 after a one-year spin-up:

| Indicator | Value |
|---|---|
| E[Q] mean | 1.43 claims |
| E[Q] peak | 3.60 claims |
| Pr(Q≥6) mean | 0.0231 |
| Pr(Q≥6) peak | 0.1560 |
| Unmet demand U | 199.0 claim-days |

ρ is infinite on zero-flow days (68% of days for this gauge) by construction.
These numbers demonstrate that the data → rates → queue chain runs on real
files. They are **not** research findings: the area, claim volume and service
cap are locked provisional assumptions, not measurements (see
`../paper1/data_access_spec.md` §1 and `../START_HERE.md` §4).

## Planned structure of the paper

1. **Problem:** non-stationary λ(t), μ(t) estimated from covariates, with
   clustered arrivals and regime switching.
2. **Benchmarks:** exact stationary-at-mean, Floquet periodic, MMPP/2, and
   discrete-event simulation as ground truth.
3. **Estimators:** gradient-boosted trees and recurrent networks for
   λ(t)=fθ(x_t), μ(t)=gφ(z_t); physical constraints (positivity, monotone μ in
   upstream flow, seasonal mass calibration); quantile/conformal intervals.
4. **Baselines to beat:** constant-rate queue, stationary-at-mean queue,
   climatological seasonal rates, and SPI/SPEI/SSI indices.
5. **Validation:** held-out basins and drought events; pre-specified metrics;
   ablation showing incremental information; uncertainty propagation from rate
   estimates to indicators.
6. **Guardrails:** from `../paper1/queueing_howto.md` §7 — no unannounced
   Poisson/exponential/stationarity assumptions, no "new indicator correlates
   with old index" arguments, report null results. Note that variable and
   long-range-correlated arrival rates in queues are already studied
   (Bogachev et al., 2023, 2024, found in the WoS search); the contribution is
   the hydrological parameterisation and drought validation, not the queue
   mathematics.

## Not yet done

* **CMIP6 SSP download in progress** at `D:\Datasets\Download_CMIP\SSP` (four
  scenarios, 14 models). Several complete model/SSP combinations are already
  usable; `03_extract_cmip6.R` extracts one of them. Ensemble analysis should
  wait until more combinations finish.
* **Bias correction** of CMIP6 against IMD/CAMELS is not yet implemented.
  Raw Hargreaves ET0 from the extraction script is uncorrected and must not be
  used in a published rate estimate yet.
* **Future μ(t).** Extracted CMIP6 gives pr and temperature, not streamflow.
  A delta-change scaling of observed CAMELS streamflow (or a rainfall–runoff
  model) is still needed to build future supply rates.
* **Observational validation.** The R scripts are a single-gauge pilot. Held-out
  basins and drought events are not yet set up.
* **Crop-area / canal-command data** not found; the locked 50,000 ha / 10⁷ m³
  convention is provisional and must be replaced or given a sensitivity envelope
  before λ is interpreted physically.
* **Zero-flow interpretation** for gauge 4026 (68% of days) must be checked
  against the CAMELS-India documentation.
* Formal Floquet convergence study and MMPP parameter sweep.
