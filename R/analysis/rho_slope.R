# =====================================================================
# R/analysis/rho_slope.R -- does the queue's incremental skill increase
# with utilisation? Reports the regression and correlation for Brier and
# AUC, per study and per sample.
#
# Inputs:
#   output/selected_gauges.csv, output/paired_e1.csv          (India)
#   output_us/reservoir_queue_meta.csv,
#   output_us/us_paired_in_window_e1.csv,
#   output_us/us_paired_full_e1.csv                           (USA)
# Output:
#   output/rho_slope.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  setwd(root)
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(data.table))

  one <- function(x, study, sample) {
    x <- x[is.finite(rho) & is.finite(dBrier)]
    if (nrow(x) < 4) return(NULL)
    f_b <- stats::lm(dBrier ~ rho, data = x)
    f_a <- stats::lm(dAUC ~ rho, data = x)
    cb <- summary(f_b)$coefficients
    ca <- summary(f_a)$coefficients
    cib <- stats::confint(f_b)["rho", ]
    cia <- stats::confint(f_a)["rho", ]
    ct <- stats::cor.test(x$rho, x$dBrier)
    data.table(
      study = study, sample = sample, n = nrow(x),
      slope_brier = cb["rho", "Estimate"],
      se_brier = cb["rho", "Std. Error"],
      p_brier = cb["rho", "Pr(>|t|)"],
      ci_brier_lo = cib[1], ci_brier_hi = cib[2],
      r_brier = unname(ct$estimate), p_cor = ct$p.value,
      slope_auc = ca["rho", "Estimate"],
      se_auc = ca["rho", "Std. Error"],
      p_auc = ca["rho", "Pr(>|t|)"],
      ci_auc_lo = cia[1], ci_auc_hi = cia[2]
    )
  }

  # India: endpoint set only
  sel <- fread(file.path(OUTPUT_DIR, "selected_gauges.csv"))
  sel <- sel[in_endpoint == TRUE]
  pe <- fread(file.path(OUTPUT_DIR, "paired_e1.csv"))
  ind <- merge(sel[, .(id = gauge_id, rho)],
               pe[, .(id = gauge_id, dBrier = delta_brier, dAUC = delta_auc)],
               by = "id")

  # USA: in-window primary and full sensitivity
  usq <- fread(file.path(root, "output_us", "reservoir_queue_meta.csv"))[
    , .(id = DAM_ID, rho)]
  us_in <- merge(usq,
                 fread(file.path(root, "output_us", "us_paired_in_window_e1.csv"))[
                   , .(id = gauge_id, dBrier = delta_brier, dAUC = delta_auc)],
                 by = "id")
  us_full <- merge(usq,
                   fread(file.path(root, "output_us", "us_paired_full_e1.csv"))[
                     , .(id = gauge_id, dBrier = delta_brier, dAUC = delta_auc)],
                   by = "id")

  out <- rbind(
    one(ind, "India", "endpoint"),
    one(us_in, "USA", "in_window"),
    one(us_full, "USA", "full")
  )
  fwrite(out, file.path(OUTPUT_DIR, "rho_slope.csv"))
  print(out)
  cat("\nwrote", file.path(OUTPUT_DIR, "rho_slope.csv"), "\n")
})
