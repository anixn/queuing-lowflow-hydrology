# =====================================================================
# R/analysis/power_analysis.R -- POST HOC interpretability bound (not
# prospective power).
#
# Uses the OBSERVED per-gauge effect-size distribution (held-out deltas) to
# estimate the minimal detectable effect (MDE). This is circular as a power
# calculation: it tells us the size of effect the realised design could have
# resolved, not the probability of detecting an effect fixed in advance.
# It is reported as an interpretability bound ("any true Brier gain is below
# about X"), with the post-hoc nature disclosed.
#
# MDE = (z_{0.975} + z_{0.80}) * SD / sqrt(N),  two-sided alpha=0.05.
# A simulation-based sign-test power is also reported, for the same purpose.
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/analysis/power_analysis.R")
  root <- normalizePath(file.path(dirname(script), "..", ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(QDJ_ROOT, "R", "00_utils", u))
  suppressMessages(library(data.table))

  d1 <- fread(file.path(OUTPUT_DIR, "delta_e1.csv"))
  d2 <- fread(file.path(OUTPUT_DIR, "delta_e2.csv"))
  pe1 <- fread(file.path(OUTPUT_DIR, "paired_e1.csv"))
  pe2 <- fread(file.path(OUTPUT_DIR, "paired_e2.csv"))
  m1 <- fread(file.path(OUTPUT_DIR, "metrics_e1.csv"))
  m2 <- fread(file.path(OUTPUT_DIR, "metrics_e2.csv"))

  # Effect-size distribution uses the PAIRED per-gauge deltas (the
  # confirmatory statistic), not the year-averaged descriptive file.
  per_gauge_brier <- pe1$delta_brier[is.finite(pe1$delta_brier)]
  per_gauge_auc <- pe1$delta_auc[is.finite(pe1$delta_auc)]

  z <- stats::qnorm(0.975) + stats::qnorm(0.80)   # 2.802
  rows <- list()
  for (nm in c("brier", "auc")) {
    x <- if (nm == "brier") per_gauge_brier else per_gauge_auc
    x <- x[is.finite(x)]
    sdv <- stats::sd(x)
    for (N in c(10, 15, 20, 24, 30)) {
      mde <- z * sdv / sqrt(N)
      rows[[length(rows) + 1]] <- data.table::data.table(
        metric = nm, N = N, sd = sdv, mde = mde,
        observed_median = stats::median(x), observed_mean = mean(x),
        detectable = abs(stats::median(x)) >= mde,
        post_hoc = TRUE
      )
    }
  }
  power <- data.table::rbindlist(rows)
  data.table::setorder(power, metric, N)

  # Simulation-based sign-test power for the AUC effect at N = 24.
  set.seed(P$seed)
  sim_power <- function(effect, sdv, N, reps = 2000) {
    k <- vapply(seq_len(reps), function(r) {
      x <- stats::rnorm(N, mean = effect, sd = sdv)
      stats::binom.test(sum(x > 0), N, 0.5, alternative = "greater")$p.value < 0.05
    }, logical(1))
    mean(k)
  }
  auc_sd <- stats::sd(per_gauge_auc[is.finite(per_gauge_auc)])
  brier_sd <- stats::sd(per_gauge_brier[is.finite(per_gauge_brier)])
  grid <- data.table::rbindlist(list(
    data.table::data.table(
      metric = "auc", assumed_uplift = c(0.02, 0.05, 0.08),
      power_N15 = vapply(c(0.02, 0.05, 0.08),
                         function(e) sim_power(e, auc_sd, 15), numeric(1))),
    data.table::data.table(
      metric = "brier", assumed_uplift = c(0.001, 0.002, 0.003),
      power_N15 = vapply(c(0.001, 0.002, 0.003),
                         function(e) sim_power(e, brier_sd, 15), numeric(1)))
  ))

  write_csv_sidecar(power, file.path(OUTPUT_DIR, "power_analysis.csv"),
                    list(stage = "S4", seed = P$seed))
  write_csv_sidecar(grid, file.path(OUTPUT_DIR, "power_grid.csv"),
                    list(stage = "S4", seed = P$seed))
  cat("=== Minimal detectable effect (alpha=0.05, power=0.80) ===\n")
  print(power)
  cat("\n=== Sign-test power at N=15 ===\n")
  print(grid)
})
