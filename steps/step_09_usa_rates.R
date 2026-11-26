# =====================================================================
# step_09_usa_rates.R -- daily lambda/mu and queue run for the US core.
# Writes output_us/reservoir_daily.csv, reservoir_monthly.csv and
# reservoir_queue_meta.csv.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/us_pilot/07_build_reservoir_rates.R", "USA: reservoir rates and queue")
