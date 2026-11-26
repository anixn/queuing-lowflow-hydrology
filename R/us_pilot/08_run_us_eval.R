# =====================================================================
# R/us_pilot/08_run_us_eval.R -- paired SSI-3 vs SSI-3+queue comparison
# for the reservoir-centric US pilot.
#
# Target: USDM monthly mean DSCI >= 100 (D1 or worse).
# Baseline: SSI-3 on monthly firm supply (mean mu).
# Queue: mean E[Q] and mean P(Q >= q*).
# Split: train 2000-2012, test 2013-2020.
#
# Reuses the verified stage7_fit / stage7_paired_stats / bootstrap code.
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
  d <- merge(mon[month_complete == TRUE], usdm,
             by = c("county_fips", "date"))
  d <- d[!is.na(dsci_mean)]
  setorder(d, DAM_ID, date)

  train_years <- 2000:2012
  test_years <- 2013:2020

  designs <- list()
  for (g in unique(d$DAM_ID)) {
    x <- d[DAM_ID == g]
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
  cat("reservoir designs:", length(designs), "\n")

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
  fwrite(mt, file.path(out_dir, "us_metrics.csv"))
  fwrite(pr, file.path(out_dir, "us_predictions.csv"))

  cat("\nmean metrics by family (E1):\n")
  print(mt[endpoint == "E1",
           .(mean_brier = mean(brier, na.rm = TRUE),
             mean_auc = mean(auc, na.rm = TRUE), n = .N),
           by = family][order(mean_auc)])

  meta_rows <- list()
  for (ep in c("E1", "E2")) {
    p <- pr[endpoint == ep]
    ps <- stage7_paired_stats(p, "ssi3", "ssi3_plus_queue")
    boot <- stage7_paired_bootstrap(p, "ssi3", "ssi3_plus_queue")
    st <- sign_test(ps$delta_brier)
    cat(sprintf("\n%s: n=%d median dBrier=%+.6f CI[%+.6f,%+.6f] sign %d/%d p=%.4f median dAUC=%+.4f\n",
                ep, nrow(ps), median(ps$delta_brier, na.rm = TRUE),
                boot["lo"], boot["hi"], st$k, st$n, st$p,
                median(ps$delta_auc, na.rm = TRUE)))
    fwrite(ps, file.path(out_dir, sprintf("us_paired_%s.csv", tolower(ep))))
    meta_rows[[ep]] <- data.table(
      endpoint = ep, n = nrow(ps),
      median_delta = median(ps$delta_brier, na.rm = TRUE),
      boot_lo = boot["lo"], boot_hi = boot["hi"],
      sign_k = st$k, sign_n = st$n, sign_p = st$p,
      median_dauc = median(ps$delta_auc, na.rm = TRUE),
      auc_improved = sum(ps$delta_auc > 0, na.rm = TRUE)
    )
  }
  fwrite(rbindlist(meta_rows), file.path(out_dir, "us_meta.csv"))
  cat("\nwrote us_metrics.csv, us_predictions.csv, us_paired_*.csv, us_meta.csv\n")
})
