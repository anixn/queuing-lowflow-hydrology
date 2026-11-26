# =====================================================================
# R/compare/02_common_arm.R -- like-for-like India-US comparison under
# protocol/COMMON_PROTOCOL.md.
#
# Identical in both regions:
#   f_irr = 0.10, Kc = 0.8, SUP-1 (50% flow, cap 10 mm/day),
#   target = training-only SPI-3 <= -1, split 1981-2010 / 2011-2020,
#   eight families, paired Brier/AUC.
#
# Outputs (output_compare/):
#   common_predictions.csv, common_meta.csv, common_paired_india.csv,
#   common_paired_usa.csv, common_region_difference.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_compare")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  setwd(root); Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(root, "R", "00_utils", u))
  suppressMessages(library(data.table))

  Kc <- 0.8
  build_design <- function(monthly, ind) {
    d <- merge(ind, monthly[, .(date, mean_E_Q, mean_p_ge_q)],
               by = "date", all.x = TRUE)
    d[, target_spi3 := as.integer(!is.na(spi3) & spi3 <= -1)]
    d[, month := as.integer(format(date, "%m"))]
    d[, year := as.integer(format(date, "%Y"))]
    d[, train := year %in% P$train_years]
    d[, test := year %in% P$test_years]
    d[, ssi3_lag := shift(ssi3, 1)]
    d[, spi3_lag := shift(spi3, 1)]
    d[, spei3_lag := shift(spei3, 1)]
    d[, p_ge_q_lag := shift(mean_p_ge_q, 1)]
    d[, p_ge_q_lag2 := shift(mean_p_ge_q, 2)]
    d[, p_ge_q_inc := p_ge_q_lag - p_ge_q_lag2]
    d[order(date)]
  }

  fit_one <- function(des, gid, region) {
    if (sum(des$train & !is.na(des$target_spi3)) < 40) return(NULL)
    fit <- stage7_fit(des, "target_spi3", "E1", drop_spi3 = TRUE)
    if (!nrow(fit$predictions)) return(NULL)
    list(
      preds = cbind(gauge_id = gid, region = region, fit$predictions),
      meta = data.table(
        gauge_id = gid, region = region,
        events_train = sum(des$target_spi3[des$train], na.rm = TRUE),
        events_test = sum(des$target_spi3[des$test], na.rm = TRUE)
      )
    )
  }

  # ---------------- India ---------------------------------------------
  cat("=== India common arm ===\n")
  flow <- load_flow(); meta <- gauge_meta()
  districts <- map_gauges_to_districts(meta)
  recon <- fread(file.path(OUTPUT_DIR, "_recon_gauge_stats.csv"))
  strict <- recon[zero_frac < 0.3 & interior_gap <= 30]
  aud <- stage2_zero_audit(flow, meta, strict$gauge_id)
  sel <- fread(file.path(OUTPUT_DIR, "selected_gauges.csv"))[in_endpoint == TRUE]

  ind_res <- list()
  for (g in sel$gauge_id) {
    cr <- stage3_catchment(g, meta, districts, f_irr = 0.10)
    rates <- stage3_rates(g, flow, cr, Kc_override = Kc,
                          class_daily = aud$daily)
    qres <- stage5_queue(rates)
    ind <- stage6_indices(rates)
    des <- build_design(qres$monthly, ind)
    r <- fit_one(des, g, "India")
    if (!is.null(r)) ind_res[[as.character(g)]] <- r
  }
  ind_meta <- rbindlist(lapply(ind_res, `[[`, "meta"))
  ind_pred <- rbindlist(lapply(ind_res, `[[`, "preds"))
  cat(sprintf("India gauges fitted: %d\n", nrow(ind_meta)))

  # ---------------- USA -----------------------------------------------
  cat("=== USA common arm ===\n")
  us <- fread(file.path(out_dir, "us_gauges_screen.csv"))
  us <- us[in_window == TRUE & zero_frac < 0.3 & interior_gap <= 30]
  us[, huc4 := substr(gsub("camels_", "", gauge_id), 1, 4)]
  setorder(us, huc4, -n_flow)
  us[, rank_in_huc4 := seq_len(.N), by = huc4]
  us <- us[rank_in_huc4 <= 3]
  cat(sprintf("US gauges to process (<=3 per HUC4): %d\n", nrow(us)))

  ts_dir <- file.path(CARAVAN_ROOT, "timeseries", "camels")
  us_res <- list()
  for (i in seq_len(nrow(us))) {
    gid <- us$gauge_id[i]
    f <- file.path(ts_dir, paste0(gid, ".csv"))
    d <- tryCatch(fread(f, select = c(
      "date", "streamflow", "total_precipitation_sum",
      "potential_evaporation_sum_FAO_PENMAN_MONTEITH"), showProgress = FALSE),
      error = function(e) NULL)
    if (is.null(d) || !nrow(d)) next
    d[, date := as.Date(date)]
    q <- d$streamflow; q[!is.na(q) & q < 0] <- NA_real_
    pet <- d$potential_evaporation_sum_FAO_PENMAN_MONTEITH
    prcp <- d$total_precipitation_sum
    yr <- as.integer(format(d$date, "%Y"))
    if (sum(!is.na(q) & yr %in% P$train_years) < 1095) next
    if (sum(!is.na(q) & yr %in% P$test_years) < 730) next

    A_cmd <- 0.10 * us$area_km2[i] * 1e6
    need <- pmax(Kc * pet - P$phi * prcp, 0)
    lambda <- need / P$d_mm
    mu <- pmin(q * 86400 * P$s_firm / A_cmd * 1000, P$cap_mm) / P$d_mm
    missing <- is.na(q) | is.na(pet) | is.na(prcp)
    rates <- data.table(
      gauge_id = gid, date = d$date, q_used = q, prcp_mm = prcp,
      pet_mm = pet, need_mm = need, lambda = lambda, mu = mu,
      missing_day = missing, class = NA_character_
    )
    rates[, ym := format(date, "%Y-%m")]
    rates[, month_complete := !any(missing_day), by = ym]
    rates[, flag_pause := missing_day]
    rates[, flag_excluded_month := !month_complete]

    r <- tryCatch({
      qres <- stage5_queue(rates)
      ind <- stage6_indices(rates)
      des <- build_design(qres$monthly, ind)
      fit_one(des, gid, "USA")
    }, error = function(e) NULL)
    if (!is.null(r)) us_res[[gid]] <- r
    if (!(i %% 25)) cat(sprintf("  [%3d/%3d]\n", i, nrow(us)))
  }
  us_meta <- rbindlist(lapply(us_res, `[[`, "meta"))
  us_pred <- rbindlist(lapply(us_res, `[[`, "preds"))
  cat(sprintf("US gauges fitted: %d\n", nrow(us_meta)))

  # ---------------- Minimum-events rule and paired stats --------------
  keep <- function(m) m[events_train >= P$min_train_events &
                         events_test >= P$min_test_events, gauge_id]
  ind_keep <- keep(ind_meta); us_keep <- keep(us_meta)
  meta <- rbind(ind_meta, us_meta)
  preds <- rbind(ind_pred, us_pred, fill = TRUE)
  fwrite(meta, file.path(out_dir, "common_meta.csv"))
  fwrite(preds, file.path(out_dir, "common_predictions.csv"))

  paired <- function(reg, ids) {
    p <- preds[region == reg & gauge_id %in% ids]
    stage7_paired_stats(p, "ssi3", "ssi3_plus_queue")
  }
  ps_ind <- paired("India", ind_keep)
  ps_us <- paired("USA", us_keep)
  fwrite(ps_ind, file.path(out_dir, "common_paired_india.csv"))
  fwrite(ps_us, file.path(out_dir, "common_paired_usa.csv"))

  boot_ind <- stage7_paired_bootstrap(
    preds[region == "India" & gauge_id %in% ind_keep], "ssi3", "ssi3_plus_queue")
  boot_us <- stage7_paired_bootstrap(
    preds[region == "USA" & gauge_id %in% us_keep], "ssi3", "ssi3_plus_queue")

  # Region difference: independent bootstrap of the median difference.
  set.seed(P$seed)
  draws <- replicate(2000, {
    median(sample(ps_us$delta_brier, nrow(ps_us), replace = TRUE)) -
      median(sample(ps_ind$delta_brier, nrow(ps_ind), replace = TRUE))
  })
  diff_tab <- data.table(
    comparison = "USA minus India",
    median_india = median(ps_ind$delta_brier),
    median_usa = median(ps_us$delta_brier),
    difference = median(ps_us$delta_brier) - median(ps_ind$delta_brier),
    diff_lo = unname(quantile(draws, 0.025)),
    diff_hi = unname(quantile(draws, 0.975)),
    n_india = nrow(ps_ind), n_usa = nrow(ps_us)
  )
  fwrite(diff_tab, file.path(out_dir, "common_region_difference.csv"))

  cat("\n=== Common-protocol paired results (SPI-3 target) ===\n")
  cat(sprintf("India: n=%d median dBrier=%+.5f CI[%+.5f,%+.5f] dAUC=%+.4f\n",
              nrow(ps_ind), median(ps_ind$delta_brier), boot_ind["lo"],
              boot_ind["hi"], median(ps_ind$delta_auc)))
  cat(sprintf("USA  : n=%d median dBrier=%+.5f CI[%+.5f,%+.5f] dAUC=%+.4f\n",
              nrow(ps_us), median(ps_us$delta_brier), boot_us["lo"],
              boot_us["hi"], median(ps_us$delta_auc)))
  print(diff_tab)
})
