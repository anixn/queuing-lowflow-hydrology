# =====================================================================
# R/verify/run_tests.R -- run the verification battery and exit nonzero
# on any failure. This is gate G1.
#
# Usage:  Rscript R/verify/run_tests.R
# =====================================================================

local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/verify/run_tests.R")
  root <- normalizePath(file.path(dirname(script), "..", ".."))
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R", "audit.R")) {
    source(file.path(QDJ_ROOT, "R", "00_utils", u))
  }
  source(file.path(QDJ_ROOT, "R", "verify", "verify_engine.R"))

  cat("Verification battery (gate G1)\n")
  cat("----------------------------------------\n")
  res <- run_verification(verbose = TRUE)
  cat("----------------------------------------\n")
  cat(sprintf("%d/%d passed\n", sum(res$pass), nrow(res)))
  if (!all(res$pass)) {
    cat("FAILED:", paste(res$id[!res$pass], collapse = ", "), "\n")
    quit(status = 1, save = "no")
  }
  invisible(TRUE)
})
