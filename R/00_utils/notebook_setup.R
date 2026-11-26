# =====================================================================
# R/00_utils/notebook_setup.R -- shared R Markdown bootstrap.
#
# Sourced at the top of every notebook. It locates the project root,
# loads config + utilities, sets chunk defaults, and provides small
# assertion helpers so each notebook can enforce its contract (schema,
# ranges, no-NaN, row counts) and stop rendering on any failure.
# =====================================================================

.qdj_root_here <- function(start) {
  d <- normalizePath(start, winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, ".qdj_root"))) return(d)
    p <- dirname(d)
    if (identical(p, d)) {
      stop("No .qdj_root marker found above ", start, call. = FALSE)
    }
    d <- p
  }
}

if (!nzchar(Sys.getenv("QDJ_ROOT"))) {
  Sys.setenv(QDJ_ROOT = .qdj_root_here(getwd()))
}
QDJ_ROOT <- Sys.getenv("QDJ_ROOT")
source(file.path(QDJ_ROOT, "R", "config.R"))
for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
            "audit.R", "pipeline.R")) {
  source(file.path(QDJ_ROOT, "R", "00_utils", u))
}
suppressMessages(library(data.table))
suppressMessages(library(ggplot2))

knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE,
                      fig.width = 7, fig.height = 4.5, dpi = 120)

# --- Assertion helpers ------------------------------------------------
nb_assert <- function(cond, msg) {
  if (!isTRUE(cond)) stop(msg, call. = FALSE)
  invisible(TRUE)
}

# Load an upstream output, stopping with the stage to run first if absent.
nb_require <- function(name, stage) {
  p <- file.path(OUTPUT_DIR, name)
  if (!file.exists(p)) {
    stop(sprintf("Missing output/%s -- run stage %s first (Rscript R/run_pipeline.R).",
                 name, stage), call. = FALSE)
  }
  data.table::fread(p)
}

nb_assert_cols <- function(d, cols, what) {
  miss <- setdiff(cols, names(d))
  nb_assert(length(miss) == 0,
            sprintf("%s: missing required column(s): %s", what,
                    paste(miss, collapse = ", ")))
}

nb_assert_finite <- function(x, what) {
  nb_assert(all(is.finite(x)), sprintf("%s contains non-finite values", what))
}
