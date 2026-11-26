# =====================================================================
# steps/_helpers.R -- shared helpers for the numbered step scripts.
#
# Every step is a thin, linear driver around the verified function library
# in R/00_utils and the analysis scripts in R/analysis and R/us_pilot.
# Run steps from the repository root, or use Rscript steps/run_all_steps.R.
# =====================================================================

qdj_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  if (length(f)) {
    normalizePath(file.path(dirname(sub("^--file=", "", f[1])), ".."))
  } else {
    normalizePath(".")
  }
}

step_init <- function() {
  root <- qdj_root()
  setwd(root)
  Sys.setenv(QDJ_ROOT = root)
  if (!file.exists(".qdj_root")) {
    stop("Not at the project root: .qdj_root marker not found.", call. = FALSE)
  }
  invisible(root)
}

run_script <- function(rel, label = rel) {
  cat(sprintf("\n=== %s ===\n", label))
  status <- system2("Rscript", c("--vanilla", rel))
  if (!identical(status, 0L)) {
    stop(sprintf("Step failed: %s (exit %s)", rel, status), call. = FALSE)
  }
  invisible(TRUE)
}

require_file <- function(path, hint = "") {
  if (!file.exists(path)) {
    stop(sprintf("Missing %s. %s", path, hint), call. = FALSE)
  }
  invisible(TRUE)
}
