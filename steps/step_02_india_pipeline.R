# =====================================================================
# step_02_india_pipeline.R -- India stages S2-S7.
#
# Inventory, zero audit, catchment table, utilisation screen, queue,
# indices, targets, design, fit and meta endpoints.
# Writes output/*.csv and .json sidecars.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/run_pipeline.R", "India: S2-S7 pipeline")
