# =====================================================================
# R/study_p1.R -- Study P1: storage-deficit states for seasonal
# hydrological-drought and low-flow forecasting (PIVOT.md §4).
#
# Unit      : gauge catchment; storage state S in mm of depth
# Engine    : fluid water balance, recession-calibrated per gauge
#             (storage_engine.R); NO queue artefacts, no claims
# Q enters  : only through fitted recession parameters + the censored
#             zero-flow indicator (never as a daily input)
# Targets   : T1 = SSI-3 <= -1 (confirmatory); T2 = monthly mean flow
#             below the training-period daily Q90 (descriptive)
# Leads     : 1, 3, 6 months, strictly prospective (issue t -> target t+h)
# Split     : train 1981-2010 (features from 1982 after warm-up),
#             test 2011-2020; test years touched only at scoring
# Families  : climatology, persistence, lagged_indices, api, storage,
#             storage_plus_indices (confirmatory); frozen best-of
#             baseline per gauge on training-year CV
# Headline  : Brier skill score vs climatology; paired per-gauge deltas
#             on identical held-out months; two-level block bootstrap
#
# India is the study; Caravan-US runs the identical protocol as a
# declared transfer check behind QDJ_TRANSFER_ARM (PIVOT.md §4.2).
#
# Outputs (all with JSON sidecars):
#   output/p1_sample_report.csv   n per screen stage
#   output/p1_storage_params.csv  per-gauge recession fits
#   output/p1_bss.csv             per gauge x family x lead x target
#   output/p1_paired.csv          per-gauge paired deltas
#   output/p1_summary.csv         medians, CIs, sign tests
#   output/p1_confirmatory.csv    H1/H2 (+H0 descriptive) decision table
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  setwd(root); Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "storage_engine.R", "indices.R",
              "eval.R", "io.R", "audit.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages(library(data.table))
  ensure_dir(OUTPUT_DIR)

  # ===================================================================
  # 1. Per-gauge preparation: recession fits + fluid state + features
  # ===================================================================
  prepare_gauge <- function(g, dates, q_obs, prcp_mm, area_km2, basin,
                            region) {
    q_mm <- q_m3s_to_mm_day_na(q_obs, area_km2 * 1e6)
    yr <- as.integer(format(dates, "%Y"))
    # FQ4 discipline: all recession fits on TRAINING years only.
    mask_train <- yr %in% P$train_years & is.finite(q_mm)
    zero_frac <- mean(q_mm == 0, na.rm = TRUE)
    rec <- fit_storage_scale(q_mm, prcp_mm, mask = mask_train,
                             min_len = P1_MIN_SEG_DAYS,
                             rain_mm = P1_RAIN_DAY_MM)
    bfi <- bfi_lyne_hollick(q_mm, mask = mask_train)
    borrowed <- !is.finite(rec$S_cap) || rec$S_cap <= 0 ||
      !is.finite(rec$K_a) || rec$K_a <= 0 ||
      !is.finite(rec$b_s) || rec$n_segments < P1_MIN_SEGMENTS
    data.table(
      gauge_id = g, basin = basin, region = region,
      area_km2 = area_km2, k_days = rec$k_days, p = rec$p, a = rec$a,
      K_a = rec$K_a, b_s = rec$b_s, S_cap_mm = rec$S_cap,
      n_segments = rec$n_segments, BFI = bfi,
      q10 = stats::quantile(q_mm[mask_train], 0.10, na.rm = TRUE,
                            names = FALSE),
      q90 = stats::quantile(q_mm[mask_train], 0.90, na.rm = TRUE,
                            names = FALSE),
      zero_frac = zero_frac, borrowed_parameters = borrowed)
  }

  propagate_and_monthly <- function(r, prm, region) {
    # Fluid state over the full record; S(0) = S_cap/2 [assumption];
    # 2-year warm-up excluded from features downstream.
    q_mm <- q_m3s_to_mm_day_na(r$q_used, prm$area_km2 * 1e6)
    zero_day <- q_mm == 0 & !is.na(q_mm)   # censored recorded zeros
    st <- propagate_storage(r$date, r$prcp_mm, r$pet_mm,
                            as.integer(format(r$date, "%m")), region,
                            S_cap = prm$S_cap_mm, K_a = prm$K_a,
                            b_s = prm$b_s, zero_day = zero_day)
    dshf <- days_since_high_flow(q_mm, prm$q10)
    st[, dshf := dshf]
    ok <- r$month_complete
    m <- st[ok, .(
      S_m = mean(S_mm),
      dshf_m = if (all(is.finite(dshf))) mean(dshf) else NA_real_
    ), by = .(ym = format(date, "%Y-%m"))]
    m[, date := as.Date(paste0(ym, "-01"))]
    m[, ym := NULL]
    m
  }

  build_monthly <- function(r, prm, m_state) {
    ind <- stage6_indices(r)          # monthly indices (training-only std)
    m <- merge(ind, m_state, by = "date", all.x = TRUE)
    m <- m[order(date)]
    m[, month := as.integer(format(date, "%m"))]
    m[, year := as.integer(format(date, "%Y"))]
    # Storage anomaly vs month-of-year climatology, TRAINING feature
    # years only (1982-2010; warm-up 1980-1981 excluded) [assumption].
    fy <- year >= P1_FEATURE_START_YEAR & year %in% P$train_years
    clim <- m[fy & is.finite(S_m), .(S_bar = mean(S_m), S_sd = stats::sd(S_m)),
              by = month]
    m <- merge(m, clim, by = "month", all.x = TRUE)
    m[order(date)]
    m[, S_anom := (S_m - S_bar) / pmax(S_sd, 1e-6)]
    m[, dS1 := S_m - data.table::shift(S_m, 1)]
    m[, dS3 := S_m - data.table::shift(S_m, 3)]
    # Targets (PIVOT.md §4.5). T1: SSI-3 <= -1; T2: monthly mean flow
    # below the TRAINING-period daily Q90 threshold.
    m[, t1 := as.integer(!is.na(ssi3) & ssi3 <= -1)]
    m[, t2 := as.integer(is.finite(flow) & flow < prm$q90)]
    m[, q90_flag := t2]
    # Time-invariant fitted attributes carried as feature columns
    # (they identify nothing within a gauge; they matter for the pooled
    # descriptive model and are declared features in PIVOT.md §4.6).
    m[, k_days := prm$k_days]
    m[, BFI := prm$BFI]
    m[, S_cap_mm := prm$S_cap_mm]
    m
  }

  # ===================================================================
  # 2. Region driver (two passes: fits -> borrowing -> propagate)
  # ===================================================================
  make_region_driver <- function(region) {
    if (region == "India") {
      flow <- load_flow(); meta <- gauge_meta()
      attrs <- read_camels_attributes()
      irr <- setNames(attrs$irrigation_frac, attrs$gauge_id)
      ids <- as.character(meta$gauge_id)
      areas <- setNames(meta$area_km2, ids)
      lats <- setNames(meta$cwc_lat, ids)
      basins <- setNames(meta$basin, ids)
      get_rates <- function(g) {
        gi <- as.integer(g)
        f <- .read_forcing_one(gi)
        if (is.null(f)) return(NULL)
        f <- data.table::as.data.table(f)
        q <- flow[[g]]
        if (is.null(q) || sum(!is.na(q)) < 300) return(NULL)
        pet_col <- f$pet_gleam_mm
        pet_frac_missing <- mean(!is.finite(pet_col))
        pet_source <- if (is.finite(pet_frac_missing) &&
                          pet_frac_missing < 0.30) "shipped_gleam" else
          "hargreaves_fallback"
        pet_obs <- if (pet_source == "shipped_gleam") pet_col else NULL
        d <- merge(f[, .(date, prcp_mm, tmax_c, tmin_c, tavg_c)],
                   data.table(date = flow$date, q = q), by = "date",
                   all.x = TRUE)
        common_rates(g, d$date, d$q, d$prcp_mm, d$tmax_c, d$tmin_c,
                     d$tavg_c, areas[[g]], lats[[g]], pet_obs = pet_obs,
                     region = "India", irrigation_frac = irr[[as.character(gi)]])
      }
    } else {
      ot <- fread(file.path(CARAVAN_ROOT, "attributes", "camels",
                            "attributes_other_camels.csv"))
      ids <- ot$gauge_id
      areas <- setNames(ot$area, ids)
      lats <- setNames(ot$gauge_lat, ids)
      basins <- setNames(substr(gsub("camels_", "", ot$gauge_id), 1, 4), ids)
      get_rates <- function(g) {
        f <- tryCatch(fread(file.path(CARAVAN_ROOT, "timeseries", "camels",
                                      paste0(g, ".csv")),
                            select = c("date", "streamflow",
                                       "total_precipitation_sum",
                                       "temperature_2m_max",
                                       "temperature_2m_min",
                                       "temperature_2m_mean",
                                       "potential_evaporation_sum_FAO_PENMAN_MONTEITH"),
                            showProgress = FALSE), error = function(e) NULL)
        if (is.null(f) || !nrow(f) || sum(!is.na(f$streamflow)) < 300)
          return(NULL)
        pet_col <- f$potential_evaporation_sum_FAO_PENMAN_MONTEITH
        pet_frac_missing <- mean(!is.finite(pet_col))
        pet_mean <- mean(pet_col, na.rm = TRUE)
        pet_source <- if (is.finite(pet_mean) && pet_mean > 0 &&
                          pet_mean < 15 && pet_frac_missing < 0.30)
          "shipped_fao_pm" else "hargreaves_fallback"
        pet_obs <- if (pet_source == "shipped_fao_pm") pet_col else NULL
        common_rates(g, f$date, f$streamflow, f$total_precipitation_sum,
                     f$temperature_2m_max, f$temperature_2m_min,
                     f$temperature_2m_mean, areas[[g]], lats[[g]],
                     pet_obs = pet_obs, region = "USA",
                     irrigation_frac = NA_real_)
      }
    }
    list(ids = ids, basins = basins, areas = areas, get_rates = get_rates)
  }

  # Borrowing (PIVOT.md §4.4): gauges failing the recession-quality screen
  # borrow the basin-median (k_days, b_s, K_a, S_cap) and stay flagged.
  apply_borrowing <- function(params) {
    okp <- params[borrowed_parameters == FALSE & is.finite(S_cap_mm) &
                    S_cap_mm > 0 & is.finite(K_a) & K_a > 0 &
                    is.finite(b_s)]
    if (!nrow(okp)) return(params)
    bm <- okp[, .(k_days = stats::median(k_days, na.rm = TRUE),
                  b_s = stats::median(b_s, na.rm = TRUE),
                  K_a = stats::median(K_a, na.rm = TRUE),
                  S_cap_mm = stats::median(S_cap_mm, na.rm = TRUE)),
              by = basin]
    for (gb in params[borrowed_parameters == TRUE, gauge_id]) {
      b <- params[gauge_id == gb, basin]
      if (!b %in% bm$basin) next
      vals <- as.list(bm[basin == b,
                         .SD, .SDcols = c("k_days", "b_s", "K_a", "S_cap_mm")])
      set(params, which(params$gauge_id == gb),
          c("k_days", "b_s", "K_a", "S_cap_mm"), vals)
    }
    params
  }

  run_region_p1 <- function(region) {
    cat(sprintf("=== P1 region %s ===\n", region))
    drv <- make_region_driver(region)
    params <- list()
    for (g in drv$ids) {
      r <- drv$get_rates(g)
      if (is.null(r)) next
      prm <- tryCatch(
        prepare_gauge(g, r$date, r$q_used, r$prcp_mm, drv$areas[[g]],
                      drv$basins[[g]], region),
        error = function(e) NULL)
      if (is.null(prm)) next
      params[[g]] <- prm
      if (!(which(drv$ids == g) %% 50)) cat(sprintf("  fits %d/%d\n",
        which(drv$ids == g), length(drv$ids)))
    }
    params <- rbindlist(params, fill = TRUE)
    # Borrowing (PIVOT.md §4.4): gauges failing the recession-quality
    # screen borrow the basin-median (k_days, b_s, K_a, S_cap).
    params <- apply_borrowing(params)
    monthly <- list(); screens <- list()
    for (g in params$gauge_id) {
      r <- drv$get_rates(g)
      if (is.null(r)) next
      prm_row <- params[gauge_id == g]
      out <- tryCatch({
        ms <- propagate_and_monthly(r, prm_row, region)
        mm <- build_monthly(r, prm_row, ms)
        sc <- common_screen(r, drv$basins[[g]])
        sc[, n_segments := prm_row$n_segments]
        sc[, region := region]
        sc[, gauge_id := g]
        list(mm = mm, sc = sc)
      }, error = function(e) NULL)
      if (is.null(out)) next
      monthly[[g]] <- out$mm
      screens[[g]] <- out$sc
      if (!(which(params$gauge_id == g) %% 50))
        cat(sprintf("  propagated %d/%d\n", which(params$gauge_id == g),
                    nrow(params)))
    }
    list(monthly = monthly, params = params,
         screens = rbindlist(screens, fill = TRUE))
  }

  ind <- run_region_p1("India")
  us <- NULL

  # ===================================================================
  # 3. Screens (PIVOT.md §4.2) and the sample report
  # ===================================================================
  screen_table <- function(rg) {
    p <- rg$params
    s <- rg$screens
    d <- merge(s, p[, .(gauge_id, n_segments, zero_frac, BFI, k_days,
                        S_cap_mm, borrowed_parameters)],
               by = "gauge_id")
    # Event counts and month-completeness from the monthly tables. A
    # month is complete when every day is present (month_complete rule);
    # on the monthly grid that is exactly a finite `flow`.
    ev <- rbindlist(lapply(names(rg$monthly), function(g) {
      m <- rg$monthly[[g]]
      fy <- m$year >= P1_FEATURE_START_YEAR & m$year %in% P$train_years
      ty <- m$year %in% P$test_years
      data.table(gauge_id = g,
                 complete_train_months = sum(fy & is.finite(m$flow)),
                 complete_test_months = sum(ty & is.finite(m$flow)),
                 t1_train = sum(m$t1[fy], na.rm = TRUE),
                 t2_train = sum(m$t2[fy], na.rm = TRUE),
                 t1_test = sum(m$t1[ty], na.rm = TRUE),
                 t2_test = sum(m$t2[ty], na.rm = TRUE),
                 balance_t1 = mean(m$t1[fy], na.rm = TRUE),
                 balance_t2 = mean(m$t2[fy], na.rm = TRUE))
    }), fill = TRUE)
    d <- merge(d, ev, by = "gauge_id", all.x = TRUE)
    # Screen 2 (PIVOT.md §4.2): >= 30 complete training months and >= 10
    # complete test months per gauge (NOT the retired day-count rule).
    d[, pass_complete := !is.na(complete_train_months) &
        complete_train_months >= 30 & complete_test_months >= 10]
    d[, pass_events_t1 := !is.na(t1_train) & t1_train >= P1_MIN_TRAIN_EVENTS]
    d[, pass_events_t2 := !is.na(t2_train) & t2_train >= P1_MIN_TRAIN_EVENTS]
    d[, pass_recession := !is.na(n_segments) & n_segments >= P1_MIN_SEGMENTS]
    d[]
  }
  ind_scr2 <- screen_table(ind)
  write_csv_sidecar(ind_scr2, file.path(OUTPUT_DIR, "p1_sample_report.csv"))
  write_csv_sidecar(ind$params, file.path(OUTPUT_DIR, "p1_storage_params.csv"))

  n_report <- function(scr, region) {
    data.table(
      region = region,
      n_read = nrow(scr),
      n_complete = sum(scr$pass_complete),
      n_events_t1 = sum(scr$pass_complete & scr$pass_events_t1),
      n_events_t2 = sum(scr$pass_complete & scr$pass_events_t2),
      n_recession_ok = sum(scr$pass_complete & scr$pass_events_t1 &
                             scr$pass_recession),
      n_borrowed = sum(scr$borrowed_parameters))
  }
  sample_n <- n_report(ind_scr2, "India")
  cat("Sample report (India):\n"); print(sample_n)

  # ===================================================================
  # 4. Fit + score: per gauge, per target, per lead
  # ===================================================================
  score_region <- function(rg, scr2, region) {
    gauges_ok <- scr2[pass_complete == TRUE, gauge_id]
    storage_ok_ids <- scr2[pass_complete == TRUE & pass_recession == TRUE &
                             is.finite(S_cap_mm) & is.finite(k_days),
                           gauge_id]
    bss_rows <- list(); pred_rows <- list(); metric_rows <- list()
    for (gi in seq_along(gauges_ok)) {
      g <- gauges_ok[gi]
      mm <- rg$monthly[[as.character(g)]]
      if (is.null(mm)) next
      use_storage <- g %in% storage_ok_ids
      for (tgt in c("t1", "t2")) {
        bal_col <- if (tgt == "t1") "balance_t1" else "balance_t2"
        bal <- scr2[gauge_id == g][[bal_col]]
        balance_ok <- is.finite(bal) && bal > 0.02 && bal < 0.98
        fams <- if (use_storage) names(P1_FAMILY_FEATURES[[toupper(tgt)]]) else
          setdiff(names(P1_FAMILY_FEATURES[[toupper(tgt)]]), P1_STORAGE_FAMILIES)
        for (h in P1_LEADS) {
          des <- p1_design_at_lead(mm, tgt, h)
          ft <- stage7_fit(des, target_col = "y", endpoint = "E1",
                           features = P1_FAMILY_FEATURES[[toupper(tgt)]][fams])
          ft$metrics[, `:=`(gauge_id = g, region = region, target = tgt,
                            lead = h)]
          ft$predictions[, `:=`(gauge_id = g, region = region, target = tgt,
                                lead = h, balance_ok = balance_ok)]
          metric_rows[[length(metric_rows) + 1L]] <- ft$metrics
          bss_rows[[length(bss_rows) + 1L]] <- bss_vs_climatology(
            ft$predictions)[, `:=`(gauge_id = g, region = region,
                                   target = tgt, lead = h)]
          pred_rows[[length(pred_rows) + 1L]] <- ft$predictions
        }
      }
      if (!(gi %% 25)) cat(sprintf("  scored %d/%d\n", gi, length(gauges_ok)))
    }
    list(bss = rbindlist(bss_rows, fill = TRUE),
         preds = rbindlist(pred_rows, fill = TRUE),
         metrics = rbindlist(metric_rows, fill = TRUE),
         storage_ok_ids = storage_ok_ids)
  }
  cat("=== P1 fitting and scoring (India) ===\n")
  ind_fit <- score_region(ind, ind_scr2, "India")

  # ===================================================================
  # 5. Paired contrasts + frozen best-of + confirmatory table
  # ===================================================================
  paired_region <- function(fit, region) {
    preds <- fit$preds; metrics <- fit$metrics
    rows <- list(); best_sel <- list()
    for (tgt in c("t1", "t2")) {
      for (h in P1_LEADS) {
        px <- preds[target == tgt & lead == h]
        if (!nrow(px)) next
        # Frozen best-of: per gauge, the P1_BASELINES family with the
        # lowest training-year CV Brier (selector never sees test years).
        sel <- metrics[target == tgt & lead == h &
                         family %in% P1_BASELINES & is.finite(cv_brier),
                       .(gauge_id, family, cv_brier)]
        if (nrow(sel)) {
          bg <- sel[, .(best_family = family[which.min(cv_brier)]),
                    by = gauge_id]
          best_sel[[length(best_sel) + 1L]] <-
            bg[, .(gauge_id, target = tgt, lead = h, best_family)]
          for (bf in P1_BASELINES) {
            ps <- stage7_paired_stats(px, bf, "storage_plus_indices")
            ps[, `:=`(region = region, target = tgt, lead = h,
                      baseline = bf)]
            rows[[length(rows) + 1L]] <- ps
          }
          # best-of pseudo-family: predictions of the per-gauge chosen
          # baseline, paired on identical months.
          pb <- merge(px, bg, by = "gauge_id")
          pb_best <- pb[family == best_family]
          pb_best[, family := "bestof"]
          pbq <- pb[family == "storage_plus_indices"]
          pb2 <- rbind(pbq, pb_best)
          if (nrow(pb2)) {
            ps <- stage7_paired_stats(pb2, "bestof", "storage_plus_indices")
            ps[, `:=`(region = region, target = tgt, lead = h,
                      baseline = "bestof")]
            rows[[length(rows) + 1L]] <- ps
          }
        }
      }
    }
    list(paired = rbindlist(rows, fill = TRUE),
         best_sel = rbindlist(best_sel, fill = TRUE))
  }
  cat("=== paired contrasts (India) ===\n")
  ind_pair <- paired_region(ind_fit, "India")

  # ---- summary: median deltas, bootstrap CIs, sign tests -------------
  summ_rows <- list(); conf_rows <- list()
  for (tgt in c("t1", "t2")) {
    for (h in P1_LEADS) {
      pd <- ind_pair$paired[target == tgt & lead == h]
      if (!nrow(pd)) next
      for (bf in c(P1_BASELINES, "bestof")) {
        ps <- pd[baseline == bf]
        if (!nrow(ps)) next
        # Class-balance rule (§4.7): exclude flagged cells from the Brier
        # contrast (reported separately).
        ok_ps <- ps$delta_brier[is.finite(ps$delta_brier)]
        st <- sign_test(ok_ps)
        row <- data.table(region = "India", target = tgt, lead = h,
                          baseline = bf, n = length(ok_ps),
                          median_delta = stats::median(ok_ps),
                          sign_k = st$k, sign_n = st$n,
                          sign_share = st$share, sign_p = st$p)
        # Two-level block bootstrap for the confirmatory cells and the
        # H0 parity cell (T1, h = 1); sign tests elsewhere.
        if (tgt == "t1" && bf == "bestof" && nrow(ps) >= 20) {
          px <- ind_fit$preds[target == tgt & lead == h]
          bg <- ind_pair$best_sel[target == tgt & lead == h]
          pb <- merge(px, bg, by = "gauge_id")
          pb_best <- pb[family == best_family]; pb_best$family <- "bestof"
          pb2 <- rbind(pb[family == "storage_plus_indices"], pb_best)
          m2 <- merge(pb2[family == "bestof", .(gauge_id, date, year, y, p)],
                      pb2[family == "storage_plus_indices",
                           .(gauge_id, date, p2 = p)],
                      by = c("gauge_id", "date"))
          m2[, delta := (p2 - y)^2 - (p - y)^2]
          boot <- two_level_bootstrap_fast(m2$gauge_id, m2$year, m2$delta,
                                           B = P1_BOOT_B, seed = P$seed)
          row[, `:=`(boot_lo = unname(boot["lo"]),
                     boot_hi = unname(boot["hi"]))]
        } else {
          row[, `:=`(boot_lo = NA_real_, boot_hi = NA_real_)]
        }
        summ_rows[[length(summ_rows) + 1L]] <- row
      }
    }
  }
  p1_summ <- rbindlist(summ_rows, fill = TRUE)

  # Confirmatory decision table (frozen §4.10 criteria applied as written).
  conf <- p1_summ[target == "t1" & baseline == "bestof"]
  conf[, hypothesis := fifelse(lead == 3, "H1 (confirmatory)",
                        fifelse(lead == 6, "H2 (confirmatory)",
                                "H0 (descriptive: parity expected)"))]
  conf[, criterion_median_pos := median_delta > 0]
  conf[, criterion_ci_excl0 := boot_lo > 0]
  conf[, criterion_sign60 := sign_share >= 0.60]
  conf[, verdict := fifelse(
    lead == 1, "descriptive (H0): report as predicted parity/null",
    fifelse(criterion_median_pos & criterion_ci_excl0 & criterion_sign60,
            "PASS", "FAIL"))]
  write_csv_sidecar(p1_summ, file.path(OUTPUT_DIR, "p1_summary.csv"))
  write_csv_sidecar(conf, file.path(OUTPUT_DIR, "p1_confirmatory.csv"))
  write_csv_sidecar(ind_pair$paired,
                    file.path(OUTPUT_DIR, "p1_paired.csv"))
  write_csv_sidecar(ind_fit$bss, file.path(OUTPUT_DIR, "p1_bss.csv"))
  write_csv_sidecar(ind_fit$preds, file.path(OUTPUT_DIR, "p1_predictions.csv"))
  write_csv_sidecar(ind_pair$best_sel,
                    file.path(OUTPUT_DIR, "p1_bestof_selection.csv"))
  write_csv_sidecar(ind_fit$metrics, file.path(OUTPUT_DIR, "p1_metrics.csv"))

  cat("\n=== P1 confirmatory (India) ===\n")
  print(conf[, .(hypothesis, lead, n, median_delta, boot_lo, boot_hi,
                 sign_share, verdict)])

  # ===================================================================
  # 6. US transfer arm (declared check; same code path)
  # ===================================================================
  if (TRANSFER_ARM == "on") {
    us <- run_region_p1("USA")
    us_scr2 <- screen_table(us)
    write_csv_sidecar(us_scr2, file.path(OUTPUT_DIR,
                                         "p1_sample_report_usa.csv"))
    write_csv_sidecar(us$params, file.path(OUTPUT_DIR,
                                           "p1_storage_params_usa.csv"))
    sample_n_us <- n_report(us_scr2, "USA")
    cat("Sample report (USA):\n"); print(sample_n_us)
    cat("=== P1 fitting and scoring (USA transfer arm) ===\n")
    us_fit <- score_region(us, us_scr2, "USA")
    us_pair <- paired_region(us_fit, "USA")
    us_rows <- list()
    for (tgt in c("t1", "t2")) {
      for (h in P1_LEADS) {
        pd <- us_pair$paired[target == tgt & lead == h]
        if (!nrow(pd)) next
        for (bf in c(P1_BASELINES, "bestof")) {
          ps <- pd[baseline == bf]
          if (!nrow(ps)) next
          ok_ps <- ps$delta_brier[is.finite(ps$delta_brier)]
          st <- sign_test(ok_ps)
          us_rows[[length(us_rows) + 1L]] <- data.table(
            region = "USA", target = tgt, lead = h, baseline = bf,
            n = length(ok_ps), median_delta = stats::median(ok_ps),
            boot_lo = NA_real_, boot_hi = NA_real_,
            sign_k = st$k, sign_n = st$n, sign_share = st$share,
            sign_p = st$p)
        }
      }
    }
    us_summ <- rbindlist(us_rows, fill = TRUE)
    write_csv_sidecar(us_summ, file.path(OUTPUT_DIR, "p1_summary_usa.csv"))
    write_csv_sidecar(us_pair$paired,
                      file.path(OUTPUT_DIR, "p1_paired_usa.csv"))
    write_csv_sidecar(us_fit$bss, file.path(OUTPUT_DIR, "p1_bss_usa.csv"))
    write_csv_sidecar(us_fit$preds, file.path(OUTPUT_DIR,
                                              "p1_predictions_usa.csv"))
    write_csv_sidecar(us_pair$best_sel,
                      file.path(OUTPUT_DIR, "p1_bestof_selection_usa.csv"))
    write_csv_sidecar(us_fit$metrics,
                      file.path(OUTPUT_DIR, "p1_metrics_usa.csv"))
    cat("\n=== USA transfer check (descriptive) ===\n")
    print(us_summ[target == "t1" & baseline == "bestof"])
  }

  cat("\nP1 study complete. All outputs written with sidecars.\n")
})
