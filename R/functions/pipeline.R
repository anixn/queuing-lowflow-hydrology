# =====================================================================
# R/functions/pipeline.R -- the functions of the one common study.
#
# Every function is plain and testable; R/study.R calls them top to bottom
# and writes the CSVs. There is no hidden global state between steps.
#
#   Loaders    load_flow(), gauge_meta()
#   Common     common_rates(), common_screen()
#   Queue      stage5_queue()
#   Indices    stage6_indices(), stage6_design()
#   Evaluation stage7_fit(), stage7_deltas(), stage7_meta(),
#              stage7_paired_stats(), stage7_paired_bootstrap()
# =====================================================================

# ---------------------------------------------------------------------
# Shared loaders
# ---------------------------------------------------------------------

# Read the full streamflow matrix once. Returns a data.table keyed by date
# with one column per gauge (character gauge id).
load_flow <- function() {
  d <- data.table::fread(CAMELS_FLOW_FILE, showProgress = FALSE)
  d[, date := as.Date(sprintf("%04d-%02d-%02d", year, month, day))]
  d[, c("year", "month", "day") := NULL]
  data.table::setkey(d, date)
  d
}

# Gauge metadata (area, basin, coordinates) from attributes.
gauge_meta <- function() {
  attrs <- read_camels_attributes()
  topo <- data.table::fread(file.path(CAMELS_ATTR_DIR, "camels_ind_topo.csv"))
  topo[, gauge_id := as.integer(gauge_id)]
  out <- merge(
    attrs[, c("gauge_id", "cwc_area", "river_basin")],
    topo[, c("gauge_id", "cwc_lat", "cwc_lon")],
    by = "gauge_id", all.x = TRUE
  )
  data.table::setDT(out)
  data.table::setnames(out, c("cwc_area", "river_basin"),
                       c("area_km2", "basin"))
  out
}

# ---------------------------------------------------------------------
# S5 -- queue propagation
# ---------------------------------------------------------------------

# Run the queue for one gauge's daily rate table. Returns daily and monthly
# tables plus run metadata (thresholds, blocking diagnostics).
# FQ4 fix: lam_bar (and therefore q*, K, theta) is computed on TRAINING
# years only; test years are touched only at scoring time.
stage5_queue <- function(rates, q_days = P$q_days, K_days = P$K_days) {
  yr <- as.integer(format(rates$date, "%Y"))
  ok <- !rates$missing_day & yr %in% P$train_years
  lam_bar <- mean(rates$lambda[ok])
  th <- thresholds_from_lambda(lam_bar, q_days = q_days, K_days = K_days,
                               theta_mult = P$theta_mult)
  cfg <- queue_config(th$q_star, th$K, c = P$c, theta = th$theta,
                      alpha = P$alpha, eta = P$eta)
  daily <- run_queue(rates$date, rates$lambda, rates$mu, cfg,
                     pause = rates$flag_pause)
  daily <- data.table::as.data.table(daily)
  daily[, `:=`(gauge_id = rates$gauge_id[1],
               missing_day = rates$missing_day,
               flag_excluded_month = rates$flag_excluded_month)]
  # Enforce the blocking guard rather than merely recording it.
  max_block <- max(daily$p_eq_K, na.rm = TRUE)
  if (is.finite(max_block) && max_block >= P$block_guard) {
    stop(sprintf("Blocking guard: max P(Q=K)=%.3e >= %.0e for gauge %d",
                 max_block, P$block_guard, rates$gauge_id[1]),
         call. = FALSE)
  }
  daily[, ym := format(date, "%Y-%m")]
  # Monthly aggregation over complete months only.
  monthly <- daily[, {
    complete <- !any(missing_day)
    if (!complete) {
      .(month_complete = FALSE,
        mean_E_Q = NA_real_, mean_p_ge_q = NA_real_,
        mean_p_ge_theta = NA_real_, mean_lambda = NA_real_,
        mean_mu = NA_real_, mean_rho = NA_real_,
        served = NA_real_, reneged = NA_real_, blocked = NA_real_)
    } else {
      .(month_complete = TRUE,
        mean_E_Q = mean(E_Q), mean_p_ge_q = mean(p_ge_q),
        mean_p_ge_theta = mean(p_ge_theta), mean_lambda = mean(lambda),
        mean_mu = mean(mu), mean_rho = mean(rho_day, na.rm = TRUE),
        served = sum(served), reneged = sum(reneged), blocked = sum(blocked))
    }
  }, by = ym]
  monthly[, date := as.Date(paste0(ym, "-01"))]
  monthly[, gauge_id := rates$gauge_id[1]]
  list(
    daily = daily, monthly = monthly,
    meta = list(gauge_id = rates$gauge_id[1], lam_bar = lam_bar,
                q_star = th$q_star, K = th$K, theta = th$theta,
                max_E_Q = max(daily$E_Q), max_p_ge_q = max(daily$p_ge_q),
                max_p_eq_K = max(daily$p_eq_K),
                ledger_residual = attr(daily, "max_ledger_residual") %||% NA_real_)
  )
}

# ---------------------------------------------------------------------
# S6 -- indices, targets, design matrices
# ---------------------------------------------------------------------

# Monthly indices from the daily rate table (training-only standardization).
# Built on a CONTINUOUS monthly grid so the 3-month rolling accumulations
# never skip a calendar month; incomplete months are NA and propagate.
stage6_indices <- function(rates) {
  d <- rates[, .(
    prcp = if (all(!is.na(prcp_mm)) && all(month_complete)) sum(prcp_mm) else NA_real_,
    pet = if (all(!is.na(pet_mm)) && all(month_complete)) sum(pet_mm) else NA_real_,
    flow = if (all(month_complete)) mean(q_used) else NA_real_,
    api_p = if (all(month_complete)) mean(api_p) else NA_real_,
    api_pet = if (all(month_complete)) mean(api_pet) else NA_real_
  ), by = ym]
  grid <- data.table::data.table(
    date = seq(as.Date("1981-01-01"), as.Date("2020-12-01"), by = "month"))
  grid[, ym := format(date, "%Y-%m")]
  mon <- merge(grid, d, by = "ym", all.x = TRUE)
  mon <- mon[order(date)]
  train <- format(mon$date, "%Y") %in% as.character(P$train_years)
  mon[, spi3 := spi3(prcp, date, train)]
  mon[, spi6 := spi6(prcp, date, train)]
  mon[, spei3 := spei3(prcp, pet, date, train)]
  mon[, ssi3 := ssi3(flow, date, train)]
  mon[, ssi6 := ssi6(flow, date, train)]
  mon[, c("ym", "flow") := NULL]
  mon
}

# Assemble a monthly design table for one gauge: queue features, indices and
# the two catchment targets (SPEI-3 primary, SPI-3 sensitivity).
stage6_design <- function(monthly, indices) {
  d <- merge(indices, monthly[, .(date, mean_E_Q, mean_p_ge_q,
                                  mean_p_ge_theta, mean_rho)],
             by = "date", all.x = TRUE)
  d[, target_spi3 := as.integer(!is.na(spi3) & spi3 <= -1)]
  d[, target_spei3 := as.integer(!is.na(spei3) & spei3 <= -1)]
  d <- d[order(date)]
  # Lagged predictors for the memory baselines (1-month lag; the G2 gate
  # and P1 extend leads in the design builders of each script).
  d[, `:=`(
    spi3_lag = data.table::shift(spi3, 1),
    spi6_lag = data.table::shift(spi6, 1),
    spei3_lag = data.table::shift(spei3, 1),
    ssi3_lag = data.table::shift(ssi3, 1),
    ssi6_lag = data.table::shift(ssi6, 1),
    api_p_lag = data.table::shift(api_p, 1),
    api_pet_lag = data.table::shift(api_pet, 1),
    p_ge_q_lag = data.table::shift(mean_p_ge_q, 1),
    p_ge_q_lag2 = data.table::shift(mean_p_ge_q, 2),
    E_Q_lag = data.table::shift(mean_E_Q, 1)
  )]
  d[, p_ge_q_inc := p_ge_q_lag - p_ge_q_lag2]
  d[, month := as.integer(format(date, "%m"))]
  d[, year := as.integer(format(date, "%Y"))]
  d[, train := year %in% P$train_years]
  d[, test := year %in% P$test_years]
  d
}

# ---------------------------------------------------------------------
# Common study: ONE rate builder and ONE screen for both regions
# ---------------------------------------------------------------------

# Interior missing-data run length, in days (0 = no interior gap).
interior_gap_days <- function(x) {
  ok <- which(!is.na(x))
  if (length(ok) < 2) return(NA_integer_)
  r <- rle(is.na(x[min(ok):max(ok)]))
  if (!any(r$values)) 0L else max(r$lengths[r$values])
}

# Build daily demand/service rates for one gauge catchment (G2 corrected
# version, PIVOT.md §3 changes 1-2).
# Units: prcp, PET, need in mm/day; lambda and mu in claims/day.
# PET: dataset column (pet_obs) when shipped, else Hargreaves (declared by
# the caller via pet_source). Demand envelope: seasonal Kc_m(month) and
# phi_m(month) from R/functions/units.R; the USA keeps the flat values.
# A_cmd = f_irr_measured * A_catchment (m^2) from the measured attribute.
common_rates <- function(gauge_id, date, q, prcp, tmax, tmin, tmean,
                         area_km2, lat, pet_obs = NULL, region = "India",
                         irrigation_frac = NA_real_) {
  d <- data.table::data.table(
    date = as.Date(date), q = as.numeric(q), prcp = as.numeric(prcp),
    tmax = as.numeric(tmax), tmin = as.numeric(tmin), tmean = as.numeric(tmean))
  doy <- as.integer(format(d$date, "%j"))
  mo <- as.integer(format(d$date, "%m"))
  et0 <- rep(NA_real_, nrow(d))
  if (!is.null(pet_obs)) {
    x <- as.numeric(pet_obs)
    assert_true(all(is.na(x) | x >= 0), "pet_obs must be non-negative mm/day")
    et0 <- x
  }
  if (is.null(pet_obs) || !any(is.finite(et0))) {
    if (is.finite(lat)) {
      ra <- extraterrestrial_radiation(lat, doy)
      ok <- is.finite(ra)
      if (any(ok)) {
        et0[ok] <- hargreaves_et0(d$tmax[ok], d$tmin[ok], d$tmean[ok], ra[ok])
      }
    }
  }
  d[, et0 := et0]
  # Seasonal demand envelope (FQ6 fix): Kc_m and phi_m by month and region.
  d[, need := pmax(kc_month(mo, region) * et0 - phi_month(mo, region) * prcp, 0)]
  d[, lambda := need / P$d_mm]
  f_irr <- f_irr_measured(irrigation_frac)
  A_cmd <- f_irr * area_km2 * 1e6
  d[, mu := if (is.finite(A_cmd)) {
    pmin(q * 86400 * P$s_firm / A_cmd * 1000, P$cap_mm) / P$d_mm
  } else NA_real_]
  # Antecedent Precipitation Index, daily recursive (memory baseline,
  # FQ1 fix): API_t = k * API_{t-1} + P_t [assumption: decay API_DECAY,
  # effective memory ~API_DAYS]. PET-side accumulation weighted by Kc_m.
  n_d <- nrow(d)
  api_p <- numeric(n_d); api_pet <- numeric(n_d)
  p_ok <- is.finite(d$prcp); e_ok <- is.finite(d$et0)
  kc <- kc_month(mo, region)
  for (i in seq_len(n_d)) {
    prev_p <- if (i > 1) api_p[i - 1] else 0
    prev_e <- if (i > 1) api_pet[i - 1] else 0
    api_p[i] <- API_DECAY * prev_p + if (p_ok[i]) d$prcp[i] else 0
    api_pet[i] <- API_DECAY * prev_e + if (e_ok[i]) kc[i] * d$et0[i] else 0
  }
  d[, api_p := api_p]
  d[, api_pet := api_pet]
  d[, missing_day := is.na(q) | is.na(et0) | is.na(prcp) | is.na(mu)]
  d[, ym := format(date, "%Y-%m")]
  d[, month_complete := !any(missing_day), by = ym]
  d[, .(gauge_id = gauge_id, date, q_used = q, prcp_mm = prcp, pet_mm = et0,
        need_mm = need, lambda, mu, api_p, api_pet, missing_day, ym,
        month_complete,
        flag_pause = missing_day, flag_excluded_month = !month_complete)]
}

# One screen for both regions (FQ3/FQ4 fix, PIVOT.md §3 changes 3-4).
# All statistics are computed on TRAINING years only.
#   in_window     : the RETIRED study's rule, kept only so the G2 gate can
#                   score its confirmatory sample unchanged (rho window,
#                   zero-flow cap and basin caps stay in the calling
#                   script).
#   complete_only : the pivot's completeness-only rule (the sample the
#                   study "could have been"); it selects nothing here.
common_screen <- function(rates, basin) {
  yr <- as.integer(format(rates$date, "%Y"))
  tr <- yr %in% P$train_years
  ok <- !rates$missing_day
  # FQ4 fix: utilisation from TRAINING years only (descriptive reporting
  # column; it selects nothing on the pivot path).
  rho <- if (any(ok & tr)) sum(rates$lambda[ok & tr]) /
    sum(rates$mu[ok & tr]) else NA_real_
  n_train <- sum(!is.na(rates$q_used) & tr)
  n_test <- sum(!is.na(rates$q_used) & yr %in% P$test_years)
  zf <- mean(rates$q_used == 0, na.rm = TRUE)
  gp <- interior_gap_days(rates$q_used)
  data.table::data.table(
    gauge_id = rates$gauge_id[1], basin = basin,
    rho = rho, zero_frac = zf, interior_gap = gp,
    n_train = n_train, n_test = n_test,
    in_window = is.finite(rho) & rho >= P$rho_window[1] &
      rho <= P$rho_window[2] & zf < 0.30 & !is.na(gp) & gp <= 30 &
      n_train >= 1095 & n_test >= 730,
    complete_only = n_train >= 1095 & n_test >= 730 &
      !is.na(gp) & gp <= 30)
}

# ---------------------------------------------------------------------
# S7 -- fitting and meta-endpoint
# ---------------------------------------------------------------------

# Standardize columns on training rows (leakage-free); return matrix + params.
standardize_train <- function(d, cols, train_mask) {
  X <- as.matrix(d[, cols, with = FALSE])
  mu <- vapply(cols, function(cn) mean(X[train_mask, cn], na.rm = TRUE), numeric(1))
  sdv <- vapply(cols, function(cn) stats::sd(X[train_mask, cn], na.rm = TRUE), numeric(1))
  sdv[!is.finite(sdv) | sdv <= 0] <- 1
  for (j in seq_along(cols)) X[, j] <- (X[, j] - mu[j]) / sdv[j]
  list(X = X, mu = mu, sd = sdv)
}

# Fit all model families for one gauge and one endpoint (E1 concurrent or
# E2 lagged). Returns a metrics table (family x metric) and a predictions
# table carrying the test year (needed for the year-block bootstrap).
FAMILY_FEATURES <- list(
  climatology = character(0),
  spi3 = "spi3",
  spei3 = "spei3",
  ssi3 = "ssi3",
  queue = c("mean_E_Q", "mean_p_ge_q"),
  ssi3_plus_queue = c("ssi3", "mean_E_Q", "mean_p_ge_q"),
  spei3_plus_queue = c("spei3", "mean_E_Q", "mean_p_ge_q"),
  ssi3_plus_spei3_plus_queue = c("ssi3", "spei3", "mean_E_Q", "mean_p_ge_q")
)

# Model families for the G2 gate (PIVOT.md §3 change 5, FQ1 fix): the
# concurrent families PLUS the honest memory baselines. `persistence` =
# lag-1 SSI-3 (what an operator does today); `ssi6` = lag-1 SSI-6;
# `api` = the recursive antecedent index (decay + window in config.R).
FAMILY_FEATURES_G2 <- list(
  climatology = character(0),
  ssi3 = "ssi3",
  queue = c("mean_E_Q", "mean_p_ge_q"),
  ssi3_plus_queue = c("ssi3", "mean_E_Q", "mean_p_ge_q"),
  persistence = "ssi3_lag",
  ssi6 = "ssi6_lag",
  api = c("api_p_lag", "api_pet_lag")
)
FAMILY_FEATURES_E2 <- list(
  climatology = character(0),
  spi3 = "spi3_lag",
  spei3 = "spei3_lag",
  ssi3 = "ssi3_lag",
  queue = c("p_ge_q_lag", "p_ge_q_inc"),
  ssi3_plus_queue = c("ssi3_lag", "p_ge_q_lag", "p_ge_q_inc"),
  spei3_plus_queue = c("spei3_lag", "p_ge_q_lag", "p_ge_q_inc"),
  ssi3_plus_spei3_plus_queue = c("ssi3_lag", "spei3_lag", "p_ge_q_lag", "p_ge_q_inc")
)

stage7_fit <- function(design, target_col = "target_sma", endpoint = "E1",
                       drop_spi3 = FALSE, features = NULL) {
  feats <- if (!is.null(features)) features else
    if (endpoint == "E1") FAMILY_FEATURES else FAMILY_FEATURES_E2
  y <- design[[target_col]]
  train_mask <- design$train & is.finite(y)
  test_mask <- design$test & is.finite(y)
  # Calendar-year-block fold ids inside the training years (FS3 fix; fold
  # structure frozen in config.R: RIDGE_FOLDS contiguous year blocks).
  yrs <- sort(unique(design$year[train_mask]))
  fold_of_year <- unlist(split(seq_along(yrs),
                               cut(seq_along(yrs), breaks = RIDGE_FOLDS,
                                   labels = FALSE)))
  names(fold_of_year) <- as.character(yrs)
  design$fold_id <- as.integer(fold_of_year[as.character(design$year)])
  metrics <- list()
  preds <- list()
  for (fam in names(feats)) {
    cols <- feats[[fam]]
    if (drop_spi3 && "spi3" %in% cols) cols <- setdiff(cols, "spi3")
    if (drop_spi3 && "spi3_lag" %in% cols) cols <- setdiff(cols, "spi3_lag")
    need <- c(cols, "month")
    ok_train <- train_mask & stats::complete.cases(design[, need, with = FALSE])
    ok_test <- test_mask & stats::complete.cases(design[, need, with = FALSE])
    if (sum(ok_train) < 40 || sum(ok_test) < 10 || length(unique(y[ok_train])) < 2) {
      metrics[[fam]] <- data.table::data.table(
        family = fam, n_train = sum(ok_train), n_test = sum(ok_test),
        brier = NA_real_, auc = NA_real_, logloss = NA_real_, lambda = NA_real_)
      next
    }
    sel <- ok_train | ok_test
    Xd <- design[sel]
    tr <- ok_train[sel]
    te <- ok_test[sel]
    Xtr <- if (length(cols)) standardize_train(Xd, cols, tr) else list(X = matrix(0, nrow(Xd), 0))
    Xmat <- matrix(1, nrow = nrow(Xd), ncol = 1)
    if (length(cols)) Xmat <- cbind(Xmat, Xtr$X)
    Xmat <- cbind(Xmat, month_dummies(Xd$month))
    colnames(Xmat)[1] <- "intercept"
    # FS3 fix: ridge penalty tuned per family by calendar-block CV inside
    # the training years, then one final refit on all training rows.
    lam <- cv_ridge_lambda(Xmat[tr, , drop = FALSE], y[ok_train],
                           Xd$fold_id[tr], grid = RIDGE_GRID)
    fit <- fit_ridge_logistic(Xmat[tr, , drop = FALSE], y[ok_train], lambda = lam)
    p <- predict_ridge_logistic(fit$beta, Xmat[te, , drop = FALSE])
    yt <- y[ok_test]
    metrics[[fam]] <- data.table::data.table(
      family = fam, n_train = sum(ok_train), n_test = sum(ok_test),
      brier = brier_score(yt, p), auc = auc_score(yt, p),
      logloss = log_loss(yt, p), lambda = lam)
    preds[[fam]] <- data.table::data.table(
      date = Xd$date[te], year = Xd$year[te], y = yt, p = p, family = fam)
  }
  list(metrics = data.table::rbindlist(metrics), predictions = data.table::rbindlist(preds))
}

# Per-gauge-year Brier deltas for a contrast (positive = queue improves).
stage7_deltas <- function(all_preds, contrast = c("ssi3", "ssi3_plus_queue")) {
  a <- all_preds[family == contrast[1], .(gauge_id, date, year, y, p_a = p)]
  b <- all_preds[family == contrast[2], .(gauge_id, date, p_b = p)]
  d <- merge(a, b, by = c("gauge_id", "date"))
  d[, brier_a := (p_a - y)^2]
  d[, brier_b := (p_b - y)^2]
  d[, .(delta = mean(brier_a) - mean(brier_b)), by = .(gauge_id, year)]
}

# Meta endpoint: median delta, two-level bootstrap, sign test, harm bound.
# The within-gauge pooling statistic is the MEAN (so Delta_g is the pooled
# held-out Brier difference, exactly as the protocol defines it); the
# across-gauge summary is the median. Using a within-gauge median here
# would report a "median of medians", not the protocol's Delta_g.
stage7_meta <- function(delta_by_year) {
  per_gauge <- delta_by_year[, .(delta = mean(delta)), by = gauge_id]
  boot <- two_level_bootstrap(delta_by_year$gauge_id, delta_by_year$year,
                              delta_by_year$delta, stat = mean,
                              B = 2000, seed = P$seed)
  st <- sign_test(per_gauge$delta)
  list(per_gauge = per_gauge, median_delta = stats::median(per_gauge$delta),
       bootstrap = boot, sign_test = st,
       harm_count = sum(per_gauge$delta < -0.005))
}

# Paired per-gauge statistics on the SAME held-out months for both families.
# This is the confirmatory statistic: an unpaired comparison (each family on
# its own complete-case sample) is NOT the protocol's Delta_g and must never
# be used for a confirmatory claim.
stage7_paired_stats <- function(all_preds, a_fam = "ssi3",
                                b_fam = "ssi3_plus_queue") {
  a <- all_preds[family == a_fam, .(gauge_id, date, year, y, p_a = p)]
  b <- all_preds[family == b_fam, .(gauge_id, date, p_b = p)]
  m <- merge(a, b, by = c("gauge_id", "date"))
  m[, `:=`(brier_a = (p_a - y)^2, brier_b = (p_b - y)^2)]
  out <- m[, .(
    n_months = .N,
    brier_a = mean(brier_a), brier_b = mean(brier_b),
    delta_brier = mean(brier_a) - mean(brier_b),
    auc_a = auc_score(y, p_a), auc_b = auc_score(y, p_b)
  ), by = gauge_id]
  out[, delta_auc := auc_b - auc_a]
  out
}

# Paired two-level bootstrap for the confirmatory median Delta_g. Resamples
# gauges, then years within gauge, recomputing the pooled per-gauge Brier
# difference from row-level (monthly) paired deltas.
stage7_paired_bootstrap <- function(all_preds, a_fam = "ssi3",
                                    b_fam = "ssi3_plus_queue",
                                    B = 2000L, seed = P$seed) {
  a <- all_preds[family == a_fam, .(gauge_id, date, year, y, p_a = p)]
  b <- all_preds[family == b_fam, .(gauge_id, date, p_b = p)]
  m <- merge(a, b, by = c("gauge_id", "date"))
  m[, delta := (p_a - y)^2 - (p_b - y)^2]
  two_level_bootstrap(m$gauge_id, m$year, m$delta, stat = mean,
                      B = B, seed = seed)
}
