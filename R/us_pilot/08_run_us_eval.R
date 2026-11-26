# =====================================================================
# R/us_pilot/08_run_us_eval.R -- paired SSI-3 vs SSI-3+queue comparison
# for the reservoir-centric US pilot.
#
# Primary sample: reservoirs inside the predeclared utilisation window
# (0.15 <= rho <= 1.20), matching the India rule. The full sample is
# reported as a sensitivity (the audit found 7/21 paired reservoirs outside
# the window, up to rho = 25.44).
#
# Target: USDM monthly mean DSCI >= 100 (D1 or worse).
# Baseline: SSI-3 on monthly firm supply (mean mu).
# Queue: mean E[Q] and mean P(Q >= q*).
# Split: train 2000-2012, test 2013-2020.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(root, "R", "00_utils", u))
  suppressMessages(library(data.table))

  mon <- fread(file.path(out_dir, "reservoir_monthly.csv"))
  usdm <- fread(file.path(out_dir, "usdm_monthly.csv"))
  rho_tab <- fread(file.path(out_dir, "reservoir_queue_meta.csv"))[
    , .(DAM_ID, rho)]
  d <- merge(mon[month_complete == TRUE], usdm,
             by = c("county_fips", "date"))
  d <- merge(d, rho_tab, by = "DAM_ID")
  d <- d[!is.na(dsci_mean)]
  setorder(d, DAM_ID, date)

  train_years <- 2000:2012
  test_years <- 2013:2020
  d_in <- d[rho >= P$rho_window[1] & rho <= P$rho_window[2]]
  cat(sprintf("reservoir-months: full %d (%d reservoirs), in-window %d (%d)\n",
              nrow(d), uniqueN(d$DAM_ID), nrow(d_in), uniqueN(d_in$DAM_ID)))

  evaluate_sample <- function(dat, label) {
    designs <- list()
    for (g in unique(dat$DAM_ID)) {
      x <- dat[DAM_ID == g]
      if (nrow(x) < 120) next
      x[, year := as.integer(format(date, "%Y"))]
      x[, month := as.integer(format(date, "%m"))]
      x[, train := year %in% train_years]
      x[, test := year %in% test_years]
      x[, target_sma := as.integer(dsci_mean >= 100)]
      x[, ssi3 := ssi3(mean_mu, date, train)]
      x[, `:=`(spi3 = NA_real_, spei3 = NA_real_)]
      x[, ssi3_lag := shift(ssi3, 1)]
      x[, p_ge_q_lag := shift(mean_p_ge_q, 1)]
      x[, p_ge_q_lag2 := shift(mean_p_ge_q, 2)]
      x[, p_ge_q_inc := p_ge_q_lag - p_ge_q_lag2]
      x[, `:=`(spi3_lag = NA_real_, spei3_lag = NA_real_)]
      designs[[as.character(g)]] <- x
    }
    cat(sprintf("  %s: %d reservoir designs\n", label, length(designs)))

    metrics <- list(); preds <- list()
    for (nm in names(designs)) {
      x <- designs[[nm]]
      for (ep in c("E1", "E2")) {
        f <- stage7_fit(x, "target_sma", ep)
        metrics[[paste0(nm, "_", ep)]] <-
          cbind(DAM_ID = as.integer(nm), endpoint = ep, f$metrics)
        if (nrow(f$predictions)) {
          preds[[paste0(nm, "_", ep)]] <-
            cbind(DAM_ID = as.integer(nm), endpoint = ep, f$predictions)
        }
      }
    }
    mt <- rbindlist(metrics, fill = TRUE)
    pr <- rbindlist(preds, fill = TRUE)
    pr[, gauge_id := DAM_ID]
    fwrite(mt, file.path(out_dir, sprintf("us_metrics_%s.csv", label)))
    fwrite(pr, file.path(out_dir, sprintf("us_predictions_%s.csv", label)))

    meta_rows <- list()
    for (ep in c("E1", "E2")) {
      p <- pr[endpoint == ep]
      ps <- stage7_paired_stats(p, "ssi3", "ssi3_plus_queue")
      boot <- stage7_paired_bootstrap(p, "ssi3", "ssi3_plus_queue")
      st <- sign_test(ps$delta_brier)
      fwrite(ps, file.path(out_dir,
                           sprintf("us_paired_%s_%s.csv", label, tolower(ep))))
      meta_rows[[ep]] <- data.table(
        sample = label, endpoint = ep, n = nrow(ps),
        median_delta = median(ps$delta_brier, na.rm = TRUE),
        mean_delta = mean(ps$delta_brier, na.rm = TRUE),
        boot_lo = boot["lo"], boot_hi = boot["hi"],
        sign_k = st$k, sign_n = st$n, sign_p = st$p,
        median_dauc = median(ps$delta_auc, na.rm = TRUE),
        auc_improved = sum(ps$delta_auc > 0, na.rm = TRUE),
        harm = sum(ps$delta_brier < -0.005, na.rm = TRUE)
      )
    }
    rbindlist(meta_rows)
  }

  meta_in <- evaluate_sample(d_in, "in_window")
  meta_full <- evaluate_sample(d, "full")
  fwrite(meta_in, file.path(out_dir, "us_meta.csv"))
  fwrite(meta_full, file.path(out_dir, "us_meta_full.csv"))

  cat("\n=== in-window (primary) ===\n"); print(meta_in)
  cat("\n=== full sample (sensitivity) ===\n"); print(meta_full)
})
