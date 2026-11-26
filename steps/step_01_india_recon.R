# =====================================================================
# step_01_india_recon.R -- one-time gauge profiling for the India study.
#
# Non-destructive: if output/_recon_gauge_stats.csv exists, the recon
# script is a no-op. Pass --force to regenerate and re-check the selection.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/analysis/recon.R", "India: gauge profiling (recon)")
