# =====================================================================
# steps/run_all_steps.R -- run the full sequence in order.
#
# Usage:
#   Rscript steps/run_all_steps.R             # India baseline + USA + figures
#   Rscript steps/run_all_steps.R --full      # also the long India sensitivity grid
#
# Every step stops the run on failure.
# =====================================================================
source("steps/_helpers.R")
root <- step_init()
full <- "--full" %in% commandArgs(trailingOnly = TRUE)

steps <- c(
  "steps/step_00_setup.R",
  "steps/step_01_india_recon.R",
  "steps/step_02_india_pipeline.R",
  "steps/step_03_india_power.R",
  if (full) "steps/step_04_india_sensitivity.R",
  "steps/step_05_india_figures.R",
  "steps/step_06_usa_screen.R",
  "steps/step_07_usa_match.R",
  "steps/step_08_usa_target.R",
  "steps/step_09_usa_rates.R",
  "steps/step_10_usa_eval.R",
  "steps/step_13_common_comparison.R",
  "steps/step_11_manuscript_figures.R",
  "steps/step_12_verify.R"
)

cat("Queueing-drought pipeline\n")
cat("Root :", root, "\n")
cat("Steps:", length(steps), if (full) "(full sensitivity)" else "(baseline)", "\n")

for (s in steps) {
  run_script(s, s)
}
cat("\nAll steps completed.\n")
