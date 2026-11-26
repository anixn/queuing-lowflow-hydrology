# =====================================================================
# step_07_usa_match.R -- match ResOpsUS reservoirs to Caravan catchments
# and build the reservoir-centric core sample.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/us_pilot/02_match_resops.R", "USA: reservoir-catchment match")
run_script("R/us_pilot/03_reservoir_sample.R", "USA: reservoir core sample")
