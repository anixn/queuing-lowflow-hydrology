# P02 working package — non-stationary queue methods

P01 establishes why drought can be read as a queue state. P02 supplies the methods: estimate time-varying demand/service rates, validate the queue against exact references, test identification and recovery, and evaluate incremental drought information on held-out data.

The first predeclared real-data comparison is complete. It found **no held-out Brier improvement from adding queue probability to SSI in either pilot gauge**. The result is retained unchanged in `../analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`. The recommended single-paper framing is a methods and negative-result evaluation, not a superiority claim (`../docs/project/MERGED_PAPER_PLAN.md`).

The shared engine is `../src/shared/queue_core.py`. The revisable working convention uses a 45,000 ha Sangli proxy (9×10⁶ m³ per 20 mm claim) and a 72,252 ha Yadgir proxy (1.44504×10⁷ m³ per claim); both are assumptions, not gauge command areas. Sources are in `../analysis/claim_convention_2026-11-25/`. The broader model and data protocol is in `../analysis/P02_methods/MODELLING_PLAN.md`.

## Contents

| Path | Purpose |
|---|---|
| `../src/P02/nonstationary_bench.py` | Floquet periodic and MMPP/2 exact benchmarks |
| `../src/P02/rate_estimators.py` | NumPy-only GBDT/isotonic estimators, calibration and bootstrap intervals |
| `../src/P02/evaluate_estimators.py` | Synthetic held-out-year evaluation protocol |
| `../src/P02/real_data_comparison.py` | Predeclared two-gauge retrospective comparison |
| `../src/P02/make_comparison_figure.py` | PNG/SVG Brier-skill and reliability figure |
| `../tests/test_nonstationary_bench.py` | Six benchmark acceptance tests |
| `../tests/test_rate_estimators.py` | Seven estimator acceptance tests |
| `../tests/test_real_data_comparison.py` | Seventeen real-data pipeline acceptance tests |
| `../analysis/P02_methods/REAL_DATA_COMPARISON_PROTOCOL.md` | Locked target, split, models, decision rule and sensitivities |
| `../analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md` | Generated results and negative-result interpretation |
| `../analysis/P02_methods/data/real_data_*.csv` | Reproducible daily/monthly data, predictions, metrics, events and sensitivities |
| `R/01_build_rates.R` | Legacy one-gauge CAMELS-IND rate CSV |
| `R/02_run_queue.R` | Legacy non-stationary CTMC solve |
| `R/03_extract_cmip6.R` | One raw CMIP6 extraction; pipeline check only |
| `data/generated/rates_4026.csv` | Legacy generated daily rates; never hand-edit |
| `data/README.md` | Generated-data policy |

## Run the real-data comparison

Use the existing `drought` Conda environment (NumPy, pandas and SciPy):

```powershell
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' src/P02/real_data_comparison.py --audit-only
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' src/P02/real_data_comparison.py
python src/P02/make_comparison_figure.py
```

The default source paths are recorded in `ComparisonConfig`. Use `--camels-root`, `--die-root` and `--output-dir` to relocate them. Output CSVs carry provenance columns; `real_data_run_metadata.json` records settings and source SHA-256 hashes.

## Locked comparison design

- Target: district 3-month soil-moisture anomaly ≤ −15%.
- Training: 1981–2010.
- Nominal test: 2011–2020; actual usable test is 98 complete months per gauge (2011–2018 plus January–February 2019).
- Gauge 4026 has a 611-day interior discharge gap; gaps longer than seven days are not interpolated.
- Confirmatory comparison: SSI+queue versus SSI alone at q*=6, using Brier score.
- Both gauges are co-primary; overall support requires improvement in both.
- q*=4/8, AUC, calibration, event timing and missing-flow checks are secondary/exploratory.
- Published SPI/SPEI use a 1981–2020 reference period and are external, non-strict benchmarks.
- Same-month observed flow makes this retrospective diagnosis, not forecasting.

## Primary observed result

All queue outputs are **illustrative, under the stated assumptions**.

| Gauge | SSI Brier | SSI+queue Brier | ΔBrier | ΔAUC | Rule met |
|---:|---:|---:|---:|---:|---|
| 4026 | 0.041008 | 0.041279 | +0.000271 | −0.0678 | no |
| 4064 | 0.044246 | 0.044836 | +0.000590 | −0.0080 | no |

Queue-only Brier skill over climatology is 0.0347 and 0.0320, respectively; external SPEI-3 has lower Brier scores (0.029799 and 0.033204). All q*=4/6/8 and missing-flow sensitivities preserve the no-improvement result. Source: `../analysis/P02_methods/REAL_DATA_COMPARISON_RESULTS.md`.

## Verified synthetic results

Illustrative, under the stated assumptions:

- Floquet peak `E[Q] = 2.1295` claims and peak `Pr(Q≥6) = 0.0733`, matching P01's periodic example.
- One MMPP setting raises `E[Q]` from 1.075 to 1.247 claims (1.16×); this is not a general result.
- The constant-rate baseline understates peak risk; climatology understates the warming scenario.
- μ error near congestion remains the dominant estimator weakness.

## Remaining methods programme after author sign-off

1. Expand to more gauges and held-out drought events.
2. Replace or envelope proxy demand with measured canal/crop evidence.
3. Resolve zero-flow and regulation semantics with CWC/India-WRIS records.
4. Rebuild strict training-only SPI/SPEI from raw gridded inputs.
5. Correct remaining R/Python unit and indicator-contract issues.
6. Implement time-varying recovery distributions and identification experiments.
7. Fix μ estimation near congestion; complete Floquet convergence and MMPP sweeps.
8. Validate CAMELS-IND-Proj historical skill/provenance before conditional future μ.

No raw CMIP6 number may be published. A null or non-identifiability result is an acceptable outcome.
