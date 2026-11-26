# =====================================================================
# step_06_usa_screen.R -- profile Caravan-US catchments.
# Writes output_us/caravan_us_screen.csv.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/us_pilot/01_screen_caravan.R", "USA: Caravan screening")
