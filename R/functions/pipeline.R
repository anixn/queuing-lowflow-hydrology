# =====================================================================
# R/functions/pipeline.R -- the functions of the one common study.
#
# Every function is plain and testable; R/study.R calls them top to bottom
# and writes the CSVs. There is no hidden global state between steps.
#
#   Loaders    load_flow(), gauge_meta()
#   Common     prepare_daily(), p1_screen()
#   Indices    stage6_indices()
#   Evaluation stage7_fit(), stage7_paired_stats(),
#              stage7_paired_bootstrap()
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
  # The monthly mean flow column is KEPT: Study P1's T2 target (monthly
  # mean flow below the training Q90) reads it. The retired path ignores
  # it; no name collision exists downstream.
  mon[, c("ym") := NULL]
  mon
}

# ---------------------------------------------------------------------
# Common study: ONE daily preparation and ONE screen for both regions
# ---------------------------------------------------------------------

# Interior missing-data run length, in days (0 = no interior gap).
interior_gap_days <- function(x) {
  ok <- which(!is.na(x))
  if (length(ok) < 2) return(NA_integer_)
  r <- rle(is.na(x[min(ok):max(ok)]))
  if (!any(r$values)) 0L else max(r$lengths[r$values])
}

# Build the daily P1 input table for one gauge catchment.
# Units: prcp and PET in mm/day; q in the dataset's discharge unit.
# PET: the dataset column (pet_obs) when shipped, else Hargreaves from
# temperature and latitude (the caller declares which via pet_source).
# A day is missing when any observed input (Q, PET, P) is missing; a month
# is complete when every day is present. No demand envelope and no
# utilisation enter the P1 path: the state is a depth in mm, never a claim.
prepare_daily <- function(gauge_id, date, q, prcp, tmax, tmin, tmean,
                          lat, pet_obs = NULL, region = "India") {
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
  # Antecedent Precipitation Index, daily recursive (memory baseline,
  # PIVOT.md §4.6): API_t = k * API_{t-1} + P_t [assumption: decay
  # API_DECAY, effective memory ~API_DAYS]. The PET side is weighted by
  # the seasonal Kc_m.
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
  d[, missing_day := is.na(q) | is.na(et0) | is.na(prcp)]
  d[, ym := format(date, "%Y-%m")]
  d[, month_complete := !any(missing_day), by = ym]
  d[, .(gauge_id = gauge_id, date, q_used = q, prcp_mm = prcp, pet_mm = et0,
        api_p, api_pet, missing_day, ym, month_complete,
        flag_pause = missing_day, flag_excluded_month = !month_complete)]
}

# Per-gauge P1 screen (PIVOT.md §4.2): completeness and event counts only.
# The utilisation window, the zero-flow cap and the basin caps of the
# retired design are gone; zero-flow fractions are REPORTED, never used to
# drop a gauge. All statistics are computed on the whole record, but the
# thresholds that consume them (complete months, events) are applied on
# TRAINING years by the caller.
p1_screen <- function(rates, basin) {
  yr <- as.integer(format(rates$date, "%Y"))
  tr <- yr %in% P$train_years
  n_train <- sum(!is.na(rates$q_used) & tr)
  n_test <- sum(!is.na(rates$q_used) & yr %in% P$test_years)
  zf <- mean(rates$q_used == 0, na.rm = TRUE)
  gp <- interior_gap_days(rates$q_used)
  data.table::data.table(
    gauge_id = rates$gauge_id[1], basin = basin,
    zero_frac = zf, interior_gap = gp,
    n_train = n_train, n_test = n_test)
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

# Fit every requested model family for one gauge and one lead.
# `features` is a named list (family -> character vector of design columns)
# and is REQUIRED: the family lists live with the study (P1_FAMILY_FEATURES
# below), not here, so no retired family can leak into a new design.
# Returns a metrics table (family x metric) and a predictions table
# carrying the test year (needed for the year-block bootstrap).
stage7_fit <- function(design, target_col, features) {
  if (is.null(features) || !length(features))
    stop("stage7_fit: `features` must be a named family list", call. = FALSE)
  feats <- features
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
    need <- c(cols, "month")
    ok_train <- train_mask & stats::complete.cases(design[, need, with = FALSE])
    ok_test <- test_mask & stats::complete.cases(design[, need, with = FALSE])
    if (sum(ok_train) < 40 || sum(ok_test) < 10 || length(unique(y[ok_train])) < 2) {
      metrics[[fam]] <- data.table::data.table(
        family = fam, n_train = sum(ok_train), n_test = sum(ok_test),
        brier = NA_real_, auc = NA_real_, logloss = NA_real_,
        lambda = NA_real_, cv_brier = NA_real_)
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
    lam_obj <- cv_ridge_lambda(Xmat[tr, , drop = FALSE], y[ok_train],
                               Xd$fold_id[tr], grid = RIDGE_GRID)
    fit <- fit_ridge_logistic(Xmat[tr, , drop = FALSE], y[ok_train],
                              lambda = lam_obj$lambda)
    p <- predict_ridge_logistic(fit$beta, Xmat[te, , drop = FALSE])
    yt <- y[ok_test]
    metrics[[fam]] <- data.table::data.table(
      family = fam, n_train = sum(ok_train), n_test = sum(ok_test),
      brier = brier_score(yt, p), auc = auc_score(yt, p),
      logloss = log_loss(yt, p), lambda = lam_obj$lambda,
      cv_brier = lam_obj$cv_brier)
    preds[[fam]] <- data.table::data.table(
      date = Xd$date[te], year = Xd$year[te], y = yt, p = p, family = fam)
  }
  list(metrics = data.table::rbindlist(metrics), predictions = data.table::rbindlist(preds))
}

# Paired per-gauge statistics on the SAME held-out months for both families.
# This is the confirmatory statistic: an unpaired comparison (each family on
# its own complete-case sample) is NOT the protocol's Delta_g and must never
# be used for a confirmatory claim. Family names are always supplied by the
# caller so no default can silently point at a retired family.
stage7_paired_stats <- function(all_preds, a_fam, b_fam) {
  empty <- data.table(gauge_id = character(), n_months = integer(),
                      brier_a = numeric(), brier_b = numeric(),
                      delta_brier = numeric(), auc_a = numeric(),
                      auc_b = numeric(), delta_auc = numeric())
  if (is.null(all_preds) || !nrow(all_preds) || !"family" %in% names(all_preds))
    return(empty)
  # Join keys include every design column present (target, lead) so that
  # different endpoints are never mixed or multiplied in the pairing.
  keycols <- intersect(c("gauge_id", "target", "lead"), names(all_preds))
  a <- all_preds[family == a_fam]
  a <- a[, .SD, .SDcols = c(keycols, "date", "year", "y", "p")]
  setnames(a, "p", "p_a")
  b <- all_preds[family == b_fam]
  b <- b[, .SD, .SDcols = c(keycols, "date", "p")]
  setnames(b, "p", "p_b")
  m <- merge(a, b, by = c(keycols, "date"))
  m[, `:=`(brier_a = (p_a - y)^2, brier_b = (p_b - y)^2)]
  out <- m[, .(
    n_months = .N,
    brier_a = mean(brier_a), brier_b = mean(brier_b),
    delta_brier = mean(brier_a) - mean(brier_b),
    auc_a = auc_score(y, p_a), auc_b = auc_score(y, p_b)
  ), by = c(keycols)]
  if ("target" %in% keycols) out[, target := NULL]  # carried by caller
  out[, delta_auc := auc_b - auc_a]
  out
}

# Paired two-level bootstrap for the confirmatory median Delta_g. Resamples
# gauges, then years within gauge, recomputing the pooled per-gauge Brier
# difference from row-level (monthly) paired deltas. Key columns handled
# exactly as in stage7_paired_stats.
stage7_paired_bootstrap <- function(all_preds, a_fam, b_fam,
                                    B = 2000L, seed = P$seed) {
  if (is.null(all_preds) || !nrow(all_preds) || !"family" %in% names(all_preds))
    return(c(estimate = NA_real_, lo = NA_real_, hi = NA_real_))
  keycols <- intersect(c("gauge_id", "target", "lead"), names(all_preds))
  a <- all_preds[family == a_fam]
  a <- a[, .SD, .SDcols = c(keycols, "date", "year", "y", "p")]
  setnames(a, "p", "p_a")
  b <- all_preds[family == b_fam]
  b <- b[, .SD, .SDcols = c(keycols, "date", "p")]
  setnames(b, "p", "p_b")
  m <- merge(a, b, by = c(keycols, "date"))
  m[, delta := (p_a - y)^2 - (p_b - y)^2]
  two_level_bootstrap(m$gauge_id, m$year, m$delta, stat = mean,
                      B = B, seed = seed)
}

# ---------------------------------------------------------------------
# P1 -- storage-state forecasting (PIVOT.md §4.5-§4.8)
# ---------------------------------------------------------------------

# Frozen P1 family feature lists (PIVOT.md §4.6). T1 = SSI-3 <= -1
# (confirmatory target); T2 = monthly mean flow below the training Q90
# (descriptive). `persistence` = the target index at issue time t; the
# confirmatory family is `storage_plus_indices`; the frozen best-of
# baseline is chosen per gauge on training-year CV among {persistence,
# lagged_indices, api}.
P1_FAMILY_FEATURES <- list(
  T1 = list(
    climatology = character(0),
    persistence = "ssi3",
    lagged_indices = c("spi3", "ssi3", "ssi6", "spi6"),
    api = c("api_p", "api_pet"),
    storage = c("S_anom", "dS1", "dS3", "dshf_m", "k_days", "BFI", "S_cap_mm"),
    storage_plus_indices = c("S_anom", "dS1", "dS3", "dshf_m", "k_days",
                             "BFI", "S_cap_mm", "spi3", "ssi3", "ssi6", "spi6")
  ),
  T2 = list(
    climatology = character(0),
    persistence = "q90_flag",
    lagged_indices = c("spi3", "ssi3", "ssi6", "spi6"),
    api = c("api_p", "api_pet"),
    storage = c("S_anom", "dS1", "dS3", "dshf_m", "k_days", "BFI", "S_cap_mm"),
    storage_plus_indices = c("S_anom", "dS1", "dS3", "dshf_m", "k_days",
                             "BFI", "S_cap_mm", "spi3", "ssi3", "ssi6", "spi6")
  )
)
# The frozen best-of candidate set for the confirmatory contrast.
P1_BASELINES <- c("persistence", "lagged_indices", "api")
P1_STORAGE_FAMILIES <- c("storage", "storage_plus_indices")

# P1 design at lead h (PIVOT.md §4.5): a forecast issued at month t uses
# ONLY information available at t and predicts the target at t+h. The
# strict prospective split keeps any issue/target pair fully inside its
# window: training pairs need year(t) in training AND year(t+h) <= last
# training year; test pairs need year(t) in test AND year(t+h) <= last
# test year. This kills the end-of-window leakage that a naive
# issue-month split would admit.
p1_design_at_lead <- function(m, target_col, lead_h) {
  stopifnot(lead_h %in% P1_LEADS)
  m <- copy(m)[order(date)]
  y_vec <- data.table::shift(m[[target_col]], lead_h, type = "lead")
  ty_vec <- data.table::shift(m$year, lead_h, type = "lead")
  m[, y := y_vec]
  m[, target_year := ty_vec]
  last_train <- max(P$train_years); last_test <- max(P$test_years)
  m[, train := year %in% P$train_years &
      !is.na(target_year) & target_year <= last_train]
  m[, test := year %in% P$test_years &
      !is.na(target_year) & target_year <= last_test]
  m[!is.finite(y), c("y", "train", "test") := .(NA_real_, FALSE, FALSE)]
  m
}
