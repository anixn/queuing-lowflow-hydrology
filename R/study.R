# =====================================================================
# R/study.R -- ONE study, applied identically to India and the USA.
#
# Unit      : gauge catchment
# Target    : catchment SPEI-3 <= -1 (primary), SPI-3 <= -1 (sensitivity)
# Demand    : need = max(Kc * ET0_Hargreaves - phi * P, 0), lambda = need/d
# Supply    : mu = min(Q*86400*s_firm/A_cmd*1000, cap)/d
# Area      : A_cmd = f_irr * A_catchment (explicit in both regions)
# Split     : train 1981-2010, test 2011-2020
# Evaluation: 8 families, paired Brier/AUC, two-level bootstrap
#
# No district data, no reservoirs, no USDM, no OpenET. Same code for both.
# Output: output/{india,usa}_{screen,fit_meta,paired}.csv + JSON sidecars,
#         output/region_{summary,difference}.csv + JSON sidecars.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  setwd(root); Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages(library(data.table))
  ensure_dir(OUTPUT_DIR)

  # ---- small helpers -------------------------------------------------
  # Rate builder and screen live in R/functions/pipeline.R so both regions
  # and the test battery use exactly one definition.

  # ---- load India ----------------------------------------------------
  cat("=== India: rates and screen ===\n")
  flow <- load_flow(); meta <- gauge_meta()
  ind_rates <- list(); ind_screen <- list()
  for (i in seq_len(nrow(meta))) {
    g <- meta$gauge_id[i]
    f <- .read_forcing_one(g)
    if (is.null(f)) next
    f <- data.table::as.data.table(f)
    q <- flow[[as.character(g)]]
    if (is.null(q) || sum(!is.na(q)) < 300) next
    d <- merge(f[, .(date, prcp_mm, tmax_c, tmin_c, tavg_c)],
               data.table(date = flow$date, q = q), by = "date", all.x = TRUE)
    r <- common_rates(g, d$date, d$q, d$prcp_mm, d$tmax_c, d$tmin_c,
                      d$tavg_c, meta$area_km2[i], meta$cwc_lat[i])
    s <- common_screen(r, meta$basin[i]); s[, area_km2 := meta$area_km2[i]]
    ind_rates[[as.character(g)]] <- r
    ind_screen[[as.character(g)]] <- s
    if (!(i %% 50)) cat(sprintf("  %d/%d\n", i, nrow(meta)))
  }
  ind_scr <- rbindlist(ind_screen)
  ind_scr[, region := "India"]
  write_csv_sidecar(ind_scr, file.path(OUTPUT_DIR, "india_screen.csv"))

  # ---- load USA ------------------------------------------------------
  cat("=== USA: rates and screen ===\n")
  ot <- fread(file.path(CARAVAN_ROOT, "attributes", "camels",
                        "attributes_other_camels.csv"))
  us_rates <- list(); us_screen <- list()
  for (i in seq_len(nrow(ot))) {
    g <- ot$gauge_id[i]
    f <- tryCatch(fread(file.path(CARAVAN_ROOT, "timeseries", "camels",
                                  paste0(g, ".csv")),
                        select = c("date", "streamflow",
                                   "total_precipitation_sum",
                                   "temperature_2m_max", "temperature_2m_min",
                                   "temperature_2m_mean"),
                        showProgress = FALSE), error = function(e) NULL)
    if (is.null(f) || !nrow(f)) next
    if (sum(!is.na(f$streamflow)) < 300) next
    r <- common_rates(g, f$date, f$streamflow, f$total_precipitation_sum,
                      f$temperature_2m_max, f$temperature_2m_min,
                      f$temperature_2m_mean, ot$area[i], ot$gauge_lat[i])
    s <- common_screen(r, substr(gsub("camels_", "", g), 1, 4))
    s[, area_km2 := ot$area[i]]
    us_rates[[g]] <- r
    us_screen[[g]] <- s
    if (!(i %% 100)) cat(sprintf("  %d/%d\n", i, nrow(ot)))
  }
  us_scr <- rbindlist(us_screen)
  us_scr[, region := "USA"]
  write_csv_sidecar(us_scr, file.path(OUTPUT_DIR, "usa_screen.csv"))

  # ---- select the same way ------------------------------------------
  select_region <- function(scr, max_n = 60) {
    s <- scr[in_window == TRUE]
    if (!nrow(s)) return(s)
    s[, coverage_rank := pmin(n_train, n_test)]
    setorder(s, basin, -coverage_rank)
    s[, rank_in_basin := seq_len(.N), by = basin]
    s <- s[rank_in_basin <= 3]
    s <- s[order(-coverage_rank)]
    s[seq_len(min(.N, max_n))]
  }
  ind_sel <- select_region(ind_scr)
  us_sel <- select_region(us_scr)
  cat(sprintf("India selected: %d; USA selected: %d\n",
              nrow(ind_sel), nrow(us_sel)))

  # ---- queue + target + fit for one region --------------------------
  run_region <- function(sel, rates_list, region) {
    preds_s <- list(); preds_p <- list(); meta_rows <- list()
    for (i in seq_len(nrow(sel))) {
      g <- as.character(sel$gauge_id[i])
      r <- rates_list[[g]]
      if (is.null(r)) next
      out <- tryCatch({
        qres <- stage5_queue(r)
        ind <- stage6_indices(r)
        des <- stage6_design(qres$monthly, ind)
        fs <- stage7_fit(des, "target_spei3", "E1")
        fp <- stage7_fit(des, "target_spi3", "E1")
        base <- data.table(gauge_id = sel$gauge_id[i], region = region)
        list(
          ps = cbind(base, fs$predictions),
          pp = cbind(base, fp$predictions),
          meta = data.table(
            gauge_id = sel$gauge_id[i], region = region,
            events_train_spei = sum(des$target_spei3[des$train], na.rm = TRUE),
            events_test_spei = sum(des$target_spei3[des$test], na.rm = TRUE),
            events_train_spi = sum(des$target_spi3[des$train], na.rm = TRUE),
            events_test_spi = sum(des$target_spi3[des$test], na.rm = TRUE),
            status = "ok"))
      }, error = function(e) list(
        meta = data.table(
          gauge_id = sel$gauge_id[i], region = region,
          events_train_spei = NA_integer_, events_test_spei = NA_integer_,
          events_train_spi = NA_integer_, events_test_spi = NA_integer_,
          status = conditionMessage(e))))
      meta_rows[[g]] <- out$meta
      if (!is.null(out$ps) && nrow(out$ps)) {
        preds_s[[g]] <- out$ps
        preds_p[[g]] <- out$pp
      }
    }
    list(spei = rbindlist(preds_s, fill = TRUE),
         spi = rbindlist(preds_p, fill = TRUE),
         meta = rbindlist(meta_rows, fill = TRUE))
  }
  cat("=== queue and fit ===\n")
  ind_res <- run_region(ind_sel, ind_rates, "India")
  us_res <- run_region(us_sel, us_rates, "USA")

  keep <- function(m) m[status == "ok" &
                         events_train_spei >= P$min_train_events &
                         events_test_spei >= P$min_test_events, gauge_id]
  ind_keep <- keep(ind_res$meta); us_keep <- keep(us_res$meta)
  write_csv_sidecar(ind_res$meta, file.path(OUTPUT_DIR, "india_fit_meta.csv"))
  write_csv_sidecar(us_res$meta, file.path(OUTPUT_DIR, "usa_fit_meta.csv"))
  cat(sprintf("Paired gauges: India %d, USA %d\n", length(ind_keep), length(us_keep)))

  # ---- paired results ------------------------------------------------
  paired <- function(preds, ids, region, target, suffix) {
    p <- preds[gauge_id %in% ids]
    if (!nrow(p)) {
      return(data.table(region = region, target = target, n = 0L,
                        median_delta = NA_real_, boot_lo = NA_real_,
                        boot_hi = NA_real_, sign_k = NA_integer_,
                        sign_n = NA_integer_, sign_p = NA_real_,
                        median_dauc = NA_real_, harm = NA_integer_))
    }
    ps <- stage7_paired_stats(p, "ssi3", "ssi3_plus_queue")
    boot <- stage7_paired_bootstrap(p, "ssi3", "ssi3_plus_queue")
    st <- sign_test(ps$delta_brier)
    ps[, `:=`(region = region, target = target)]
    write_csv_sidecar(ps, file.path(OUTPUT_DIR,
      sprintf("%s_paired%s.csv", tolower(region), suffix)))
    data.table(region = region, target = target, n = nrow(ps),
               median_delta = median(ps$delta_brier, na.rm = TRUE),
               boot_lo = unname(boot["lo"]), boot_hi = unname(boot["hi"]),
               sign_k = st$k, sign_n = st$n, sign_p = st$p,
               median_dauc = median(ps$delta_auc, na.rm = TRUE),
               harm = sum(ps$delta_brier < -0.005, na.rm = TRUE))
  }
  summ <- rbind(
    paired(ind_res$spei, ind_keep, "India", "SPEI-3", ""),
    paired(us_res$spei, us_keep, "USA", "SPEI-3", ""),
    paired(ind_res$spi, ind_keep, "India", "SPI-3", "_spi3"),
    paired(us_res$spi, us_keep, "USA", "SPI-3", "_spi3"))
  write_csv_sidecar(summ, file.path(OUTPUT_DIR, "region_summary.csv"))

  # ---- USA minus India, independently for each target ----------------
  region_diff <- function(target, suffix) {
    read_d <- function(region) {
      f <- file.path(OUTPUT_DIR, sprintf("%s_paired%s.csv", region, suffix))
      if (!file.exists(f)) return(numeric(0))
      fread(f)$delta_brier
    }
    pi <- read_d("india"); pu <- read_d("usa")
    if (length(pi) > 1 && length(pu) > 1) {
      set.seed(P$seed)
      draws <- replicate(2000, median(sample(pu, length(pu), replace = TRUE)) -
                           median(sample(pi, length(pi), replace = TRUE)))
      data.table(target = target, comparison = "USA minus India",
                 median_india = median(pi), median_usa = median(pu),
                 difference = median(pu) - median(pi),
                 diff_lo = unname(quantile(draws, 0.025)),
                 diff_hi = unname(quantile(draws, 0.975)),
                 n_india = length(pi), n_usa = length(pu))
    } else {
      data.table(target = target, comparison = "USA minus India",
                 median_india = NA_real_, median_usa = NA_real_,
                 difference = NA_real_, diff_lo = NA_real_, diff_hi = NA_real_,
                 n_india = length(pi), n_usa = length(pu))
    }
  }
  diff_tab <- rbind(region_diff("SPEI-3", ""), region_diff("SPI-3", "_spi3"))
  write_csv_sidecar(diff_tab, file.path(OUTPUT_DIR, "region_difference.csv"))

  cat("\n=== common study results ===\n")
  print(summ); print(diff_tab)
})
