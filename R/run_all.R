# =====================================================================
# R/run_all.R -- render every notebook in stage order, failing fast.
#
# Usage (from the project root):
#   Rscript R/run_all.R
#
# The notebooks are documentation-and-assertion wrappers around the files
# written by R/run_pipeline.R and R/analysis/*.R. They read only those
# outputs, so rendering them proves the written results are internally
# consistent and that the documented schema matches the data.
#
# The gated future-climate notebook (R/50_future/21_cmip6_extract.Rmd) is
# intentionally NOT rendered here; it stays closed until its own gate.
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/run_all.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  ensure_dir(OUTPUT_DIR)
  nb_dir <- file.path(OUTPUT_DIR, "notebooks")
  ensure_dir(nb_dir)

  files <- c(
    "R/10_data/01_inventory.Rmd",
    "R/10_data/02_zero_audit.Rmd",
    "R/10_data/03_catchment_table.Rmd",
    "R/20_rates/04_demand_model.Rmd",
    "R/20_rates/05_supply_model.Rmd",
    "R/20_rates/06_build_rates.Rmd",
    "R/30_queue/07_run_queue.Rmd",
    "R/30_queue/08_indicators.Rmd",
    "R/40_eval/09_targets.Rmd",
    "R/40_eval/10_design_matrices.Rmd",
    "R/40_eval/11_fit_compare.Rmd",
    "R/40_eval/12_meta_endpoint.Rmd",
    "R/40_eval/13_sensitivities.Rmd"
  )

  for (rel in files) {
    input <- file.path(root, rel)
    if (!file.exists(input)) stop("Missing notebook: ", rel, call. = FALSE)
    cat(sprintf("rendering %-42s ... ", rel))
    ok <- tryCatch({
      rmarkdown::render(
        input = input, output_dir = nb_dir, quiet = TRUE,
        envir = new.env(parent = globalenv()), knit_root_dir = root
      )
      TRUE
    }, error = function(e) {
      cat("\n  FAILED: ", conditionMessage(e), "\n", sep = "")
      FALSE
    })
    if (!ok) stop("Notebook failed: ", rel, call. = FALSE)
    cat("ok\n")
  }
  cat("\nAll notebooks rendered to ", nb_dir, "\n", sep = "")
})
