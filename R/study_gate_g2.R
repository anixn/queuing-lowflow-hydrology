# =====================================================================
# R/study_gate_g2.R -- Gate G2: corrected re-run of the retired design
# (PIVOT.md §3). Runs AFTER the pivot infrastructure commit; the decision
# rule below was frozen in PIVOT.md §3 BEFORE this gate ran.
#
# Changes vs the retired study (all seven):
#   1 PET    : dataset PET (GLEAM `pet_gleam` shipped in CAMELS-IND);
#              Hargreaves fallback per gauge if the column is unusable,
#              flagged in pet_source.
#   2 Demand : f_irr from measured `irrigation_frac`; seasonal Kc/phi
#              (kharif/rabi curve, India); USA keeps flat envelope.
#   3 FQ4    : queue thresholds (lam_bar, q*, K, theta) on training years.
#   4 FQ3    : rho reported from training years; completeness-only screen
#              reported alongside (probe; the confirmatory sample still
#              uses the retired in_window rule + basin caps).
#   5 FQ1    : memory baselines ssi6, api, persistence added.
#   6 FS3    : ridge penalty tuned per family (calendar-block CV, train).
#   7 FS1    : BSS vs climatology reported.
#
# Decision rule (frozen 26 Nov 2026, PIVOT.md §3, applied as written):
#   If median paired dBrier of ssi3_plus_queue over the BEST of the new
#   baselines on the SPEI-3 target is >= +0.010 with the 95% interval
#   excluding zero in BOTH regions at the current screens -> the queue
#   survives; else the null is recorded as final for the concurrent design
#   and Study P1 starts.
#
# Output: output/gateG2_summary.csv, output/gateG2_paired_{region}.csv,
#         output/gateG2_bss.csv, output/gateG2_sample_report.csv (+JSON).
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

  # ---- load India (dataset PET + measured envelope) ------------------
  cat("=== India: rates and screen (G2) ===\n")
  flow <- load_flow(); meta <- gauge_meta()
  attrs <- read_camels_attributes()
  irr <- setNames(attrs$irrigation_frac, attrs$gauge_id)
  ind_rates <- list(); ind_screen <- list(); pet_flag <- list()
  for (i in seq_len(nrow(meta))) {
    g <- meta$gauge_id[i]
    f <- .read_forcing_one(g)
    if (is.null(f)) next
    f <- data.table::as.data.table(f)
    q <- flow[[as.character(g)]]
    if (is.null(q) || sum(!is.na(q)) < 300) next
    # PET source decision, per gauge, declared: use the shipped GLEAM PET
    # unless the column is unusable (>30% missing over the analysis window),
    # then fall back to Hargreaves and flag it.
    pet_col <- f$pet_gleam_mm
    pet_frac_missing <- mean(!is.finite(pet_col))
    pet_source <- if (is.finite(pet_frac_missing) && pet_frac_missing < 0.30)
      "shipped_gleam" else "hargreaves_fallback"
    pet_obs <- if (pet_source == "shipped_gleam") pet_col else NULL
    d <- merge(f[, .(date, prcp_mm, tmax_c, tmin_c, tavg_c)],
               data.table(date = flow$date, q = q), by = "date", all.x = TRUE)
    r <- common_rates(g, d$date, d$q, d$prcp_mm, d$tmax_c, d$tmin_c,
                      d$tavg_c, meta$area_km2[i], meta$cwc_lat[i],
                      pet_obs = pet_obs, region = "India",
                      irrigation_frac = irr[[as.character(g)]])
    r[, pet_source := pet_source]
    s <- common_screen(r, meta$basin[i])
    s[, area_km2 := meta$area_km2[i]]
    s[, irrigation_frac := irr[[as.character(g)]]]
    ind_rates[[as.character(g)]] <- r
    ind_screen[[as.character(g)]] <- s
    pet_flag[[as.character(g)]] <- data.table(
      gauge_id = g, pet_source = pet_source,
      pet_frac_missing = pet_frac_missing)
    if (!(i %% 100)) cat(sprintf("  %d/%d\n", i, nrow(meta)))
  }
  ind_scr <- rbindlist(ind_screen)
  ind_pet <- rbindlist(pet_flag)
  cat(sprintf("India gauges read: %d; PET source: %s\n", nrow(ind_scr),
      paste(names(table(ind_pet$pet_source)), table(ind_pet$pet_source),
            sep = "=", collapse = ", ")))

  # ---- load USA (transfer arm; flat envelope, FAO-PM PET) ------------
  cat("=== USA: rates and screen (G2) ===\n")
  ot <- fread(file.path(CARAVAN_ROOT, "attributes", "camels",
                        "attributes_other_camels.csv"))
  us_rates <- list(); us_screen <- list(); us_pet <- list()
  for (i in seq_len(nrow(ot))) {
    g <- ot$gauge_id[i]
    f <- tryCatch(fread(file.path(CARAVAN_ROOT, "timeseries", "camels",
                                  paste0(g, ".csv")),
                        select = c("date", "streamflow",
                                   "total_precipitation_sum",
                                   "temperature_2m_max", "temperature_2m_min",
                                   "temperature_2m_mean",
                                   "potential_evaporation_sum_FAO_PENMAN_MONTEITH"),
                        showProgress = FALSE), error = function(e) NULL)
    if (is.null(f) || !nrow(f)) next
    if (sum(!is.na(f$streamflow)) < 300) next
    pet_col <- f$potential_evaporation_sum_FAO_PENMAN_MONTEITH
    pet_frac_missing <- mean(!is.finite(pet_col))
    # Sanity gate on the shipped PET scale: reference ET must lie in a
    # plausible annual range; outside it the column is unusable.
    pet_mean <- mean(pet_col, na.rm = TRUE)
    pet_source <- if (is.finite(pet_mean) && pet_mean > 0 && pet_mean < 15 &&
                      pet_frac_missing < 0.30)
      "shipped_fao_pm" else "hargreaves_fallback"
    pet_obs <- if (pet_source == "shipped_fao_pm") pet_col else NULL
    r <- common_rates(g, f$date, f$streamflow, f$total_precipitation_sum,
                      f$temperature_2m_max, f$temperature_2m_min,
                      f$temperature_2m_mean, ot$area[i], ot$gauge_lat[i],
                      pet_obs = pet_obs, region = "USA",
                      irrigation_frac = NA_real_)
    r[, pet_source := pet_source]
    s <- common_screen(r, substr(gsub("camels_", "", g), 1, 4))
    s[, area_km2 := ot$area[i]]
    us_rates[[g]] <- r
    us_screen[[g]] <- s
    us_pet[[g]] <- data.table(gauge_id = g, pet_source = pet_source,
                              pet_frac_missing = pet_frac_missing)
    if (!(i %% 200)) cat(sprintf("  %d/%d\n", i, nrow(ot)))
  }
  us_scr <- rbindlist(us_screen)
  us_pet <- rbindlist(us_pet)
  cat(sprintf("USA gauges read: %d\n", nrow(us_scr)))

  # ---- sample report (FQ3 probe; no selection change) ----------------
  sample_report <- rbind(
    ind_scr[, .(region = "India", basin, gauge_id, n_train, n_test,
                rho_train = rho, zero_frac, interior_gap,
                in_window_retired = in_window, complete_only)],
    us_scr[, .(region = "USA", basin, gauge_id, n_train, n_test,
               rho_train = rho, zero_frac, interior_gap,
               in_window_retired = in_window, complete_only)])
  write_csv_sidecar(sample_report,
                    file.path(OUTPUT_DIR, "gateG2_sample_report.csv"))
  cat("Completeness-only sample: India",
      sum(sample_report[region == "India"]$complete_only), "of",
      nrow(sample_report[region == "India"]),
      "; USA", sum(sample_report[region == "USA"]$complete_only), "of",
      nrow(sample_report[region == "USA"]), "\n")

  # ---- gate confirmatory sample: the RETIRED selection rule ----------
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
  if (TRANSFER_ARM == "on") us_sel <- select_region(us_scr) else
    us_sel <- ind_sel[0]
  cat(sprintf("Gate sample: India %d; USA %d\n", nrow(ind_sel), nrow(us_sel)))

  # ---- run the corrected queue + indices + G2 families ---------------
  run_region <- function(sel, rates_list, region) {
    preds <- list(); meta_rows <- list(); fits <- list()
    for (i in seq_len(nrow(sel))) {
      g <- as.character(sel$gauge_id[i])
      r <- rates_list[[g]]
      if (is.null(r)) next
      out <- tryCatch({
        qres <- stage5_queue(r)
        ind <- stage6_indices(r)
        des <- stage6_design(qres$monthly, ind)
        f1 <- stage7_fit(des, "target_spei3", endpoint = "E1",
                         features = FAMILY_FEATURES_G2)
        f2 <- stage7_fit(des, "target_spi3", endpoint = "E1",
                         features = FAMILY_FEATURES_G2)
        base <- data.table(gauge_id = sel$gauge_id[i], region = region)
        meta_rows[[g]] <- data.table(
          gauge_id = sel$gauge_id[i], region = region,
          events_train_spei = sum(des$target_spei3[des$train], na.rm = TRUE),
          events_test_spei = sum(des$target_spei3[des$test], na.rm = TRUE),
          events_train_spi = sum(des$target_spi3[des$train], na.rm = TRUE),
          events_test_spi = sum(des$target_spi3[des$test], na.rm = TRUE),
          lam_bar_train = qres$meta$lam_bar,
          q_star = qres$meta$q_star, K = qres$meta$K,
          pet_source = r$pet_source[1], status = "ok")
        fits[[g]] <- rbind(
          cbind(base, target = "SPEI-3", f1$metrics),
          cbind(base, target = "SPI-3", f2$metrics))
        list(ps = cbind(base, target = "SPEI-3", f1$predictions),
             pp = cbind(base, target = "SPI-3", f2$predictions))
      }, error = function(e) {
        meta_rows[[g]] <<- data.table(
          gauge_id = sel$gauge_id[i], region = region,
          events_train_spei = NA_integer_, events_test_spei = NA_integer_,
          events_train_spi = NA_integer_, events_test_spi = NA_integer_,
          lam_bar_train = NA_real_, q_star = NA_integer_, K = NA_integer_,
          pet_source = NA_character_, status = conditionMessage(e))
        NULL
      })
      if (!is.null(out)) {
        preds[[g]] <- rbind(out$ps, out$pp)
      }
      if (!(i %% 10)) cat(sprintf("  %d/%d\n", i, nrow(sel)))
    }
    list(preds = rbindlist(preds, fill = TRUE),
         meta = rbindlist(meta_rows, fill = TRUE),
         fits = rbindlist(fits, fill = TRUE))
  }
  cat("=== queue and G2 fit ===\n")
  ind_res <- run_region(ind_sel, ind_rates, "India")
  if (TRANSFER_ARM == "on") us_res <- run_region(us_sel, us_rates, "USA") else
    us_res <- list(preds = ind_res$preds[0], meta = ind_res$meta[0],
                   fits = ind_res$fits[0])

  keep <- function(m) m[status == "ok" &
                          events_train_spei >= P$min_train_events &
                          events_test_spei >= P$min_test_events, gauge_id]
  ind_keep <- keep(ind_res$meta); us_keep <- keep(us_res$meta)
  cat(sprintf("Paired gauges: India %d, USA %d\n",
              length(ind_keep), length(us_keep)))
  write_csv_sidecar(ind_res$meta, file.path(OUTPUT_DIR, "gateG2_india_meta.csv"))
  if (TRANSFER_ARM == "on")
    write_csv_sidecar(us_res$meta, file.path(OUTPUT_DIR, "gateG2_usa_meta.csv"))

  # ---- per-gauge BSS vs climatology (FS1 fix) ------------------------
  bss_all <- rbind(
    ind_res$preds[gauge_id %in% ind_keep],
    us_res$preds[gauge_id %in% us_keep])
  bss <- bss_vs_climatology(bss_all)
  write_csv_sidecar(bss, file.path(OUTPUT_DIR, "gateG2_bss.csv"))

  # ---- paired deltas: queue vs each baseline + frozen best-of --------
  NEW_BASELINES <- c("persistence", "ssi6", "api")
  paired_rows <- list()
  paired_one <- function(p, ids, region, target, base_fam) {
    # Filter to the requested target so the pairing never mixes endpoints.
    tgt <- target
    p <- p[gauge_id %in% ids & target == tgt]
    if (!nrow(p)) return(NULL)
    ps <- stage7_paired_stats(p, base_fam, "ssi3_plus_queue")
    boot <- stage7_paired_bootstrap(p, base_fam, "ssi3_plus_queue")
    st <- sign_test(ps$delta_brier)
    ps[, `:=`(region = region, target = target, baseline = base_fam)]
    paired_rows[[length(paired_rows) + 1L]] <<- ps
    data.table(region = region, target = target, baseline = base_fam,
               n = nrow(ps),
               median_delta = median(ps$delta_brier, na.rm = TRUE),
               boot_lo = unname(boot["lo"]), boot_hi = unname(boot["hi"]),
               sign_k = st$k, sign_n = st$n, sign_p = st$p,
               median_bss_queue =
                 median(bss[gauge_id %in% ids & family == "ssi3_plus_queue",
                            ]$bss, na.rm = TRUE),
               median_bss_base =
                 median(bss[gauge_id %in% ids & family == base_fam, ]$bss,
                        na.rm = TRUE))
  }
  # Best-of selection (frozen protocol, PIVOT.md §3 change 5 / §4.6): per
  # gauge, the new memory baseline with the LOWEST mean 5-fold CV Brier
  # inside the training years. The CV is recomputed here in one dedicated
  # pass so the selector never touches a test year.
  cv_scores_for_bestof <- function(sel, rates_list) {
    out <- list()
    for (i in seq_len(nrow(sel))) {
      g <- as.character(sel$gauge_id[i])
      r <- rates_list[[g]]
      if (is.null(r)) next
      sc <- tryCatch({
        qres <- stage5_queue(r)
        ind <- stage6_indices(r)
        des <- stage6_design(qres$monthly, ind)
        y <- des$target_spei3
        train_mask <- des$train & is.finite(y)
        yrs <- sort(unique(des$year[train_mask]))
        fold_of_year <- unlist(split(seq_along(yrs),
                                     cut(seq_along(yrs), breaks = RIDGE_FOLDS,
                                         labels = FALSE)))
        names(fold_of_year) <- as.character(yrs)
        des$fold_id <- as.integer(fold_of_year[as.character(des$year)])
        res <- list()
        for (fam in NEW_BASELINES) {
          cols <- FAMILY_FEATURES_G2[[fam]]
          need <- c(cols, "month")
          ok_tr <- train_mask & stats::complete.cases(des[, need, with = FALSE])
          if (sum(ok_tr) < 40 || length(unique(y[ok_tr])) < 2) next
          selrows <- ok_tr
          Xd <- des[selrows]; tr <- ok_tr[selrows]
          Xtr <- standardize_train(Xd, cols, tr)
          Xmat <- cbind(matrix(1, nrow(Xd), 1), Xtr$X, month_dummies(Xd$month))
          colnames(Xmat)[1] <- "intercept"
          folds <- sort(unique(Xd$fold_id[tr]))
          bs <- numeric(length(folds))
          for (fi in seq_along(folds)) {
            itr <- Xd$fold_id[tr] != folds[fi]
            ite <- Xd$fold_id[tr] == folds[fi]
            fit <- fit_ridge_logistic(Xmat[tr, , drop = FALSE][itr, , drop = FALSE],
                                      y[ok_tr][itr], lambda = P$L2)
            pp <- predict_ridge_logistic(fit$beta,
                                         Xmat[tr, , drop = FALSE][ite, , drop = FALSE])
            bs[fi] <- brier_score(y[ok_tr][ite], pp)
          }
          res[[fam]] <- data.table(gauge_id = sel$gauge_id[i], family = fam,
                                   cv_brier = mean(bs))
        }
        rbindlist(res)
      }, error = function(e) NULL)
      if (!is.null(sc)) out[[g]] <- sc
    }
    rbindlist(out, fill = TRUE)
  }
  cat("=== best-of CV selection (training years only) ===\n")
  ind_cv <- cv_scores_for_bestof(ind_sel, ind_rates)
  us_cv <- if (TRANSFER_ARM == "on") cv_scores_for_bestof(us_sel, us_rates) else NULL
  best_tab <- rbind(
    if (!is.null(ind_cv)) copy(ind_cv)[, region := "India"] else NULL,
    if (!is.null(us_cv)) copy(us_cv)[, region := "USA"] else NULL)
  if (nrow(best_tab)) {
    best_tab[, is_best := cv_brier == min(cv_brier), by = .(gauge_id, region)]
    best_gauges <- best_tab[is_best == TRUE,
                            .(gauge_id, region, best_family = family)]
    write_csv_sidecar(best_tab, file.path(OUTPUT_DIR, "gateG2_bestof_cv.csv"))
    cat("Best-of selection counts:\n"); print(table(best_gauges$best_family))
  }

  # Paired stats vs each baseline and vs the frozen per-gauge best-of.
  summ_rows <- list()
  for (rg in list(list("India", ind_res$preds, ind_keep, ind_cv),
                  list("USA", us_res$preds, us_keep, us_cv))) {
    region <- rg[[1]]; p <- rg[[2]]; ids <- rg[[3]]; cv <- rg[[4]]
    if (!length(ids)) next
    for (tgt in c("SPEI-3", "SPI-3")) {
      for (bf in c(NEW_BASELINES, "ssi3")) {
        row <- paired_one(p, ids, region, tgt, bf)
        if (!is.null(row)) summ_rows[[length(summ_rows) + 1L]] <- row
      }
      # Frozen best-of contrast (per gauge, selected on training CV).
      if (!is.null(cv) && nrow(cv)) {
        pbo <- copy(p)[target == tgt]
        bg <- cv[, .(gauge_id, family)][, .(best_family = family[
          which.min(cv_brier)]), by = gauge_id]
        pbo <- merge(pbo, bg, by = "gauge_id", all.x = TRUE)
        pbo_keep <- pbo[family == best_family |
                          family == "ssi3_plus_queue"]
        # collapse best-of rows into one pseudo-family
        pbo_best <- pbo_keep[family != "ssi3_plus_queue"]
        pbo_best[, family := "bestof"]
        pboq <- pbo_keep[family == "ssi3_plus_queue"]
        pbo2 <- rbind(pboq, pbo_best)
        ps <- stage7_paired_stats(pbo2, "bestof", "ssi3_plus_queue")
        boot <- stage7_paired_bootstrap(pbo2, "bestof", "ssi3_plus_queue")
        st <- sign_test(ps$delta_brier)
        ps[, `:=`(region = region, target = tgt, baseline = "bestof")]
        paired_rows[[length(paired_rows) + 1L]] <- ps
        summ_rows[[length(summ_rows) + 1L]] <- data.table(
          region = region, target = tgt, baseline = "bestof",
          n = nrow(ps),
          median_delta = median(ps$delta_brier, na.rm = TRUE),
          boot_lo = unname(boot["lo"]), boot_hi = unname(boot["hi"]),
          sign_k = st$k, sign_n = st$n, sign_p = st$p,
          median_bss_queue = NA_real_, median_bss_base = NA_real_)
      }
    }
  }
  summ <- rbindlist(summ_rows, fill = TRUE)
  write_csv_sidecar(summ, file.path(OUTPUT_DIR, "gateG2_summary.csv"))
  paired_all <- rbindlist(paired_rows, fill = TRUE)
  if (nrow(paired_all))
    write_csv_sidecar(paired_all, file.path(OUTPUT_DIR, "gateG2_paired.csv"))

  # ---- the frozen decision rule, applied as written ------------------
  cat("\n=== Gate G2 decision table ===\n")
  print(summ[baseline == "bestof"])
  bo_spei <- summ[baseline == "bestof" & target == "SPEI-3"]
  survive <- nrow(bo_spei) == 2 &&
    all(bo_spei$median_delta >= 0.010, na.rm = TRUE) &&
    all(bo_spei$boot_lo > 0, na.rm = TRUE)
  decision <- if (isTRUE(survive))
    "QUEUE SURVIVES: median paired dBrier >= +0.010 with 95% interval excluding zero in both regions; schedule a decision meeting before touching P1." else
    "NULL RECORDED: the queue does not clear the frozen bar over the best memory baseline; the null is final for the concurrent design and Study P1 starts (PIVOT.md §3)."
  cat("\nDECISION:", decision, "\n")
  writeLines(decision,
             file.path(OUTPUT_DIR, "gateG2_decision.txt"))
})
