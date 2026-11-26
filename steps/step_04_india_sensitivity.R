# =====================================================================
# step_04_india_sensitivity.R -- predeclared one-factor-at-a-time grid (S8).
#
# This is the long step (~1-2 h for 14 configurations). Run it when the
# full sensitivity table is required for the manuscript. A quick check is
# available with --quick (baseline + V0 + V2 only).
# =====================================================================
source("steps/_helpers.R")
step_init()
args <- commandArgs(trailingOnly = TRUE)
extra <- if ("--quick" %in% args) "--quick" else character(0)
cat("\n=== India: sensitivity grid ===\n")
status <- system2("Rscript", c("--vanilla", "R/analysis/sensitivity_grid.R", extra))
if (!identical(status, 0L)) stop("Sensitivity grid failed.", call. = FALSE)
