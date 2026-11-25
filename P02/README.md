# P02 working package — non-stationary queue methods

P02 is the methods paper for *Hydrology and Earth System Sciences*. It begins only after P01 reaches Gate B.

P01 establishes why drought can be read as a queue state. P02 supplies the methods: estimate time-varying demand/service rates, validate the queue against exact references, test identification and recovery, and evaluate incremental drought information on held-out data.

The shared engine is `../src/shared/queue_core.py`. The revisable working
convention uses a 45,000 ha Sangli canal-irrigated proxy and 9×10⁶ m³ per 20 mm
claim; source and envelope are in `../analysis/claim_convention_2026-11-25/`.

## Contents

| Path | Purpose |
|---|---|
| `../src/P02/nonstationary_bench.py` | Floquet periodic and MMPP/2 exact benchmarks |
| `../src/P02/rate_estimators.py` | NumPy-only GBDT/isotonic estimators, calibration and bootstrap intervals |
| `../src/P02/evaluate_estimators.py` | Synthetic held-out-year evaluation protocol |
| `../tests/test_nonstationary_bench.py` | Six benchmark acceptance tests |
| `../tests/test_rate_estimators.py` | Seven estimator acceptance tests |
| `R/01_build_rates.R` | CAMELS-IND forcings and streamflow to daily rate CSV |
| `R/02_run_queue.R` | Non-stationary CTMC solve and indicator summary |
| `R/03_extract_cmip6.R` | One CMIP6 model/SSP extraction and Hargreaves ET0; uncorrected pipeline check only |
| `data/generated/rates_4026.csv` | Generated daily rates for gauge 4026; never hand-edit |
| `data/README.md` | Generated-data policy |

The legacy raw-CMIP6 CSV and the stale indicator summary were removed during housekeeping. Regenerate outputs only from the R scripts after the P02 indicator-contract corrections are made.

## Run

```powershell
python src/P02/nonstationary_bench.py
python src/P02/rate_estimators.py
python src/P02/evaluate_estimators.py
python tests/test_nonstationary_bench.py
python tests/test_rate_estimators.py

# Real-data pipeline, in order
Rscript P02/R/01_build_rates.R
Rscript P02/R/02_run_queue.R
```

The R scripts are deliberately linear: edit BLOCK 1, then run top to bottom.

## Verified synthetic results

Illustrative, under the stated assumptions:

- Floquet peak `E[Q] = 2.1295` claims and peak `Pr(Q≥6) = 0.0733`, matching P01's periodic example.
- One MMPP setting raises `E[Q]` from 1.075 to 1.247 claims (1.16×); this is not a general result.
- The constant-rate baseline understates peak risk; climatology understates the warming scenario.
- μ error near congestion remains the dominant estimator weakness.

## Planned P02 sequence after Gate B

1. Correct R/Python unit labels, blocked-demand parity, server accounting, spin-up, leakage and adaptive stability; add golden tests.
2. Implement time-varying recovery distributions and identification experiments.
3. Fix μ estimation near congestion; complete Floquet convergence and MMPP sweeps.
4. Resolve zero-flow and regulation semantics; extend to multiple gauges.
5. Run the declared claim-scale envelope and replace the 45,000 ha proxy if gauge-specific records appear.
6. Bias-correct CMIP6 before any future-rate analysis.
7. Pre-register held-out validation, uncertainty propagation and SPI/SPEI/SSI ablation.

No raw CMIP6 number may be published. A null or non-identifiability result is an acceptable outcome.
