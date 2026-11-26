# =====================================================================
# step_12_verify.R -- the 14-check engine and unit battery (gate G1).
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/verify/run_tests.R", "Verification battery (G1)")
