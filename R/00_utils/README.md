# Function library (`R/00_utils`)

These files are the only place where scientific logic lives. The numbered
scripts in `steps/` are drivers; the analysis scripts in `R/analysis` and
`R/us_pilot` assemble calls to these functions.

## Source order

```r
source("R/config.R")
for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R",
            "io.R", "audit.R", "pipeline.R")) {
  source(file.path(QDJ_ROOT, "R", "00_utils", u))
}
```

`notebook_setup.R` does this automatically for R Markdown.

## Files

| File | Functions | Role |
|---|---|---|
| `units.R` | `claim_volume_m3`, `demand_claims`, `crop_need_mm`, `q_m3s_to_mm_day`, `firm_abstraction_m3_day`, `supply_mm_day`, `supply_claims`, `claims_to_mm`, `extraterrestrial_radiation`, `hargreaves_et0` | The unit wall. One claim volume per gauge/reservoir; all conversions here. |
| `queue_engine.R` | `queue_config`, `thresholds_from_lambda`, `birth_n`, `service_n`, `death_n`, `generator_matrix`, `stationary`, `rk4_step`, `rk4_day`, `indicators`, `run_queue`, `check_blocking`, `first_passage_mean`, `des_run` | Finite-capacity CTMC, exact stationary solution, RK4, discrete-event simulation, first passage, blocking guard. |
| `indices.R` | `rolling_sum`, `standardize_normal_month`, `gamma_spi_month`, `spi3`, `spei3`, `ssi3` | Standardized indices with training-only standardization. |
| `eval.R` | `brier_score`, `log_loss`, `auc_score`, `brier_skill`, `reliability_table`, `calibration_slope`, `fit_ridge_logistic`, `predict_ridge_logistic`, `month_dummies`, `year_block_bootstrap`, `two_level_bootstrap`, `sign_test` | Scoring, calibration, ridge logistic and resampling. |
| `io.R` | `git_hash`, `write_csv_sidecar`, `read_camels_attributes`, `read_camels_forcing`, `read_camels_flow`, `read_drought_long`, `read_districts`, `assign_gauge_district`, `monthly_complete` | Data access and provenance sidecars. |
| `audit.R` | `classify_zeros`, `peer_positive_fraction`, `mark_gaps`, `zeros_to_missing` | Zero-flow classification and gap rules. |
| `pipeline.R` | `load_flow`, `kc_curve`, `gauge_meta`, `map_gauges_to_districts`, `stage2_inventory`, `stage2_zero_audit`, `stage3_catchment`, `stage3_rates`, `stage3_screen`, `stage5_queue`, `stage6_indices`, `load_sma_long`, `stage6_design`, `standardize_train`, `stage7_fit`, `stage7_deltas`, `stage7_meta`, `stage7_paired_stats`, `stage7_paired_bootstrap` | India stages S2–S7, plus the paired confirmatory statistic. |
| `notebook_setup.R` | `nb_assert`, `nb_require`, `nb_assert_cols`, `nb_assert_finite` | R Markdown bootstrap and assertion helpers. |

## Invariants

1. **The queue engine never sees m³, hectares or mm.** It receives claims/day.
2. **The conservation ledger stops the pipeline** if the per-day residual exceeds
   `1e-6`. Do not weaken this.
3. **The confirmatory statistic is paired** on identical held-out months
   (`stage7_paired_stats`). Per-family metrics on different samples are
   descriptive only.
4. **Thresholds are catchment-relative** (`q*`, `K`, `theta` from `lam_bar`).
5. **No parameter is hardcoded outside `R/config.R`.**
6. **Every output goes through `write_csv_sidecar()`.**

## Adding a new stage

1. Add the function to the appropriate file, with units in the first docstring line.
2. Add a test to `R/verify/verify_engine.R` if it touches the engine, units or metrics.
3. Add a numbered driver in `steps/` and a matching Rmd in `steps/rmd/`.
4. Document the inputs, outputs and assumptions in the driver header.
