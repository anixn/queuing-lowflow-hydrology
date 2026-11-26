# =====================================================================
# step_10_usa_eval.R -- paired SSI-3 vs SSI-3+queue comparison.
# Writes output_us/us_metrics.csv, us_paired_*.csv, us_meta.csv.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/us_pilot/08_run_us_eval.R", "USA: paired evaluation")
