# =====================================================================
# R/00_utils/pipeline.R -- the multi-catchment analysis pipeline.
#
# Each stage is a function so the R Markdown notebooks are thin wrappers
# (documentation + assertions) around this file. All exchange is via the
# objects returned here and the CSVs written by the runner; no hidden
# global state between stages beyond the explicit data objects.
#
# Stages:
#   S2  stage2_inventory(), stage2_zero_audit()
#   S3  stage3_catchment(), stage3_rates(), stage3_screen()
#   S5  stage5_queue()
#   S6  stage6_indices(), stage6_targets(), stage6_design()
#   S7  stage7_fit(), stage7_meta()
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

# Kharif crop coefficient curve (Stage A demand).
kc_curve <- function(doy, sowing = P$sowing_doy, len = P$season_length,
                     kc_base = P$kc_base, kc_peak = P$kc_peak,
                     kc_off = P$kc_off) {
  phase <- ((doy - sowing) %% 365) / len
  ifelse(phase <= 1,
         kc_base + (kc_peak - kc_base) * sin(pi * pmin(pmax(phase, 0), 1)),
         kc_off)
}

# Gauge metadata (area, basin, coordinates, district) from attributes.
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

# Map gauges to districts (cached sf point-in-polygon).
map_gauges_to_districts <- function(meta) {
  suppressMessages(requireNamespace("sf", quietly = TRUE))
  pts <- sf::st_as_sf(
    data.frame(gauge_id = meta$gauge_id, lon = meta$cwc_lon, lat = meta$cwc_lat),
    coords = c("lon", "lat"), crs = 4326
  )
  poly <- sf::st_read(DISTRICT_BOUNDARY_FILE, quiet = TRUE)
  joined <- sf::st_join(pts, poly[, c("id", "district", "state")], left = TRUE)
  jd <- data.table::as.data.table(sf::st_drop_geometry(joined))
  data.table::setnames(jd, c("id", "district", "state"),
                       c("district_id", "district_name", "state_name"))
  jd
}

# ---------------------------------------------------------------------
# S2 -- inventory and zero audit
# ---------------------------------------------------------------------

# Per-gauge coverage/gap/zero inventory. `flow` is the wide data.table.
stage2_inventory <- function(flow, meta) {
  gauge_cols <- setdiff(names(flow), "date")
  interior_gap <- function(x) {
    ok <- which(!is.na(x))
    if (length(ok) < 2) return(NA_integer_)
    span <- x[min(ok):max(ok)]
    r <- rle(is.na(span))
    if (!any(r$values)) 0L else max(r$lengths[r$values])
  }
  n <- length(gauge_cols)
  out <- data.table::data.table(
    gauge_id = as.integer(gauge_cols),
    n_obs = vapply(gauge_cols, function(g) sum(!is.na(flow[[g]])), integer(1)),
    first_date = as.Date(vapply(gauge_cols, function(g)
      as.numeric(min(flow$date[!is.na(flow[[g]])], na.rm = TRUE)), numeric(1)),
      origin = "1970-01-01"),
    last_date = as.Date(vapply(gauge_cols, function(g)
      as.numeric(max(flow$date[!is.na(flow[[g]])], na.rm = TRUE)), numeric(1)),
      origin = "1970-01-01"),
    zero_frac = vapply(gauge_cols, function(g)
      mean(flow[[g]] == 0, na.rm = TRUE), numeric(1)),
    interior_gap = vapply(gauge_cols, function(g) interior_gap(flow[[g]]),
                          integer(1)),
    mean_q = vapply(gauge_cols, function(g)
      mean(flow[[g]], na.rm = TRUE), numeric(1))
  )
  data.table::setnames(out, "interior_gap", "interior_gap_days")
  merge(out, meta[, c("gauge_id", "area_km2", "basin")], by = "gauge_id")
}

# Classify zeros against same-basin peer gauges (proxy match grade).
# Returns per-gauge class counts and a per-day class matrix in long form.
stage2_zero_audit <- function(flow, meta, gauge_ids) {
  gauge_cols <- as.character(gauge_ids)
  basin <- meta$basin[match(gauge_ids, meta$gauge_id)]
  out_summary <- vector("list", length(gauge_ids))
  out_daily <- vector("list", length(gauge_ids))
  for (k in seq_along(gauge_ids)) {
    g <- gauge_ids[k]
    peers <- gauge_ids[basin == basin[k] & gauge_ids != g]
    peer_mat <- if (length(peers)) {
      as.matrix(flow[, as.character(peers), with = FALSE])
    } else NULL
    ppf <- if (is.null(peer_mat)) rep(NA_real_, nrow(flow)) else
      peer_positive_fraction(peer_mat)
    q <- flow[[as.character(g)]]
    cls <- classify_zeros(q, ppf)
    out_summary[[k]] <- data.table::data.table(
      gauge_id = g, basin = basin[k],
      n_days = length(q),
      n_positive = sum(cls == "positive"),
      n_real_zero = sum(cls == "real-zero"),
      n_artifact = sum(cls == "artifact"),
      n_unknown = sum(cls == "unknown"),
      n_missing = sum(cls == "missing"),
      match_grade = "proxy"
    )
    out_daily[[k]] <- data.table::data.table(
      gauge_id = g, date = flow$date, class = cls
    )
  }
  list(
    summary = data.table::rbindlist(out_summary),
    daily = data.table::rbindlist(out_daily)
  )
}

# ---------------------------------------------------------------------
# S3 -- catchment table, demand, supply, utilization screen
# ---------------------------------------------------------------------

# Command area and provenance for the Stage A demand envelope.
stage3_catchment <- function(gauge_ids, meta, districts, f_irr = P$f_irr) {
  idx <- match(gauge_ids, meta$gauge_id)
  didx <- match(gauge_ids, districts$gauge_id)
  out <- data.table::data.table(
    gauge_id = gauge_ids,
    basin = meta$basin[idx],
    area_km2 = meta$area_km2[idx],
    area_m2 = meta$area_km2[idx] * 1e6,
    lat = meta$cwc_lat[idx],
    lon = meta$cwc_lon[idx],
    f_irr = f_irr,
    area_cmd_m2 = f_irr * meta$area_km2[idx] * 1e6,
    area_source = sprintf("Stage A envelope: f_irr=%.2f x CAMELS-IND cwc_area", f_irr),
    district_id = districts$district_id[didx],
    district_name = districts$district_name[didx],
    state_name = districts$state_name[didx]
  )
  out[, claim_m3 := claim_volume_m3(P$d_mm, area_cmd_m2)]
  out
}

# Build the daily rate table for one gauge under a supply and zero variant.
# Returns data.table(date, q_used, prcp, pet, need_mm, lambda, mu, missing_day,
#                     class, flag_pause, flag_excluded_month).
stage3_rates <- function(gauge_id, flow, catchment_row, supply_variant = "SUP-1",
                         zero_variant = "V1", pet_source = "GLEAM",
                         class_daily = NULL, cap_mm = P$cap_mm) {
  f <- .read_forcing_one(gauge_id)
  if (is.null(f)) return(NULL)
  grid <- data.table::data.table(
    date = seq(as.Date("1981-01-01"), as.Date("2020-12-31"), by = "day")
  )
  m <- merge(grid, f[, c("date", "prcp_mm", "pet_gleam_mm", "tmax_c", "tmin_c",
                         "tavg_c")], by = "date", all.x = TRUE)
  m <- merge(m, data.table::data.table(date = flow$date,
                                       q = flow[[as.character(gauge_id)]]),
             by = "date", all.x = TRUE)
  m <- m[order(date)]

  # Zero treatment
  gid <- gauge_id
  if (!is.null(class_daily)) {
    cd <- class_daily[gauge_id == gid, .(date, class)]
    m <- merge(m, cd, by = "date", all.x = TRUE)
  } else {
    m[, class := NA_character_]
  }
  q <- m$q
  if (zero_variant == "V1") {
    # zeros-as-missing: artifact and unknown zeros become missing days
    q[m$class %in% c("artifact", "unknown")] <- NA_real_
  } else if (zero_variant == "V2") {
    # verified-flow-only: keep positive and real-zero days, then drop every
    # day of any calendar month whose verified fraction is below 90%.
    q[m$class %in% c("artifact", "unknown")] <- NA_real_
    m[, ym_v2 := format(date, "%Y-%m")]
    m[, verified_v2 := class %in% c("positive", "real-zero")]
    frac <- m[, .(verified_frac = mean(verified_v2, na.rm = TRUE)), by = ym_v2]
    bad <- frac[verified_frac < 0.90, ym_v2]
    if (length(bad)) q[m$ym_v2 %in% bad] <- NA_real_
    m[, c("ym_v2", "verified_v2") := NULL]
  }

  # PET source
  pet <- if (pet_source == "GLEAM") {
    m$pet_gleam_mm
  } else {
    ra <- extraterrestrial_radiation(catchment_row$lat %||% 20,
                                     as.integer(format(m$date, "%j")))
    hargreaves_et0(m$tmax_c, m$tmin_c, m$tavg_c, ra)
  }
  # If GLEAM PET has holes, fall back to Hargreaves on those days only.
  if (pet_source == "GLEAM" && anyNA(pet)) {
    ra <- extraterrestrial_radiation(catchment_row$lat %||% 20,
                                     as.integer(format(m$date, "%j")))
    hg <- hargreaves_et0(m$tmax_c, m$tmin_c, m$tavg_c, ra)
    pet[is.na(pet)] <- hg[is.na(pet)]
  }

  # Demand (claims/day). Computed only where PET and rain exist; NA stays NA
  # (never silently filled) and becomes a missing day below.
  doy <- as.integer(format(m$date, "%j"))
  kc <- kc_curve(doy)
  need <- rep(NA_real_, length(pet))
  ok_need <- !is.na(pet) & !is.na(m$prcp_mm)
  need[ok_need] <- crop_need_mm(kc[ok_need] * pet[ok_need], m$prcp_mm[ok_need], P$phi)
  lambda <- rep(NA_real_, length(need))
  lambda[ok_need] <- demand_claims(need[ok_need], P$d_mm)

  # Supply (claims/day). Computed only on days with an observed flow.
  area_m2 <- catchment_row$area_cmd_m2
  ok_q <- !is.na(q)
  s_mm <- rep(NA_real_, length(q))
  if (supply_variant == "SUP-1") {
    s_mm[ok_q] <- supply_mm_day(q[ok_q], area_m2, P$s_firm, cap_mm)
  } else if (supply_variant == "SUP-2") {
    q_dep <- stats::quantile(q, 0.05, na.rm = TRUE)
    s_mm[ok_q] <- pmin(q_m3s_to_mm_day(pmin(q[ok_q], q_dep), area_m2), cap_mm)
  } else { # SUP-3 infrastructure-first
    q_eco <- P$eco_frac * mean(q, na.rm = TRUE)
    s_mm[ok_q] <- ifelse(q[ok_q] >= q_eco, cap_mm,
                         supply_mm_day(q[ok_q], area_m2, P$s_firm, cap_mm))
  }
  mu <- s_mm / P$d_mm

  missing_day <- is.na(q) | is.na(lambda) | is.na(mu)
  out <- data.table::data.table(
    gauge_id = gauge_id, date = m$date, q_used = q,
    prcp_mm = m$prcp_mm, pet_mm = pet, need_mm = need,
    lambda = lambda, mu = mu, missing_day = missing_day,
    class = m$class
  )
  # Gap rule: pause on any missing day; the month is excluded from
  # aggregation if it contains any missing day (complete-month rule).
  out[, ym := format(date, "%Y-%m")]
  out[, month_complete := !any(missing_day), by = ym]
  out[, flag_pause := missing_day]
  out[, flag_excluded_month := !month_complete]
  out
}

# Utilization screen: rho = sum(lambda)/sum(mu) over verified days.
stage3_screen <- function(gauge_id, flow, catchment_row, class_daily,
                          variants = SUPPLY_VARIANTS) {
  rows <- vector("list", length(variants))
  for (i in seq_along(variants)) {
    r <- stage3_rates(gauge_id, flow, catchment_row, supply_variant = variants[i],
                      zero_variant = "V1", class_daily = class_daily)
    ok <- !r$missing_day
    rho <- sum(r$lambda[ok]) / sum(r$mu[ok])
    rows[[i]] <- data.table::data.table(
      gauge_id = gauge_id, supply_variant = variants[i],
      mean_lambda = mean(r$lambda[ok]), mean_mu = mean(r$mu[ok]),
      rho = rho, in_window = rho >= P$rho_window[1] && rho <= P$rho_window[2],
      usable_days = sum(ok)
    )
  }
  data.table::rbindlist(rows)
}

# ---------------------------------------------------------------------
# S5 -- queue propagation
# ---------------------------------------------------------------------

# Run the queue for one gauge's daily rate table. Returns daily and monthly
# tables plus run metadata (thresholds, blocking diagnostics).
stage5_queue <- function(rates, q_days = P$q_days, K_days = P$K_days) {
  ok <- !rates$missing_day
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
    flow = if (all(month_complete)) mean(q_used) else NA_real_
  ), by = ym]
  grid <- data.table::data.table(
    date = seq(as.Date("1981-01-01"), as.Date("2020-12-01"), by = "month"))
  grid[, ym := format(date, "%Y-%m")]
  mon <- merge(grid, d, by = "ym", all.x = TRUE)
  mon <- mon[order(date)]
  train <- format(mon$date, "%Y") %in% as.character(P$train_years)
  mon[, spi3 := spi3(prcp, date, train)]
  mon[, spei3 := spei3(prcp, pet, date, train)]
  mon[, ssi3 := ssi3(flow, date, train)]
  mon[, c("ym", "flow") := NULL]
  mon
}

# District soil-moisture-anomaly target series (T1 primary).
load_sma_long <- function() {
  sm <- data.table::fread(DROUGHT_SOIL_FILE, showProgress = FALSE)
  meta_cols <- c("district_id", "district_name", "state_name")
  long <- data.table::melt(sm, id.vars = meta_cols,
                           variable.name = "ym", value.name = "sma")
  long[, date := as.Date(paste0(ym, "-01"))]
  long[, ym := NULL]
  long <- long[date >= as.Date("1981-01-01") & date <= as.Date("2020-12-01")]
  long[, target_sma := as.integer(!is.na(sma) & sma <= -15)]
  long
}

# Assemble a monthly design table for one gauge: queue features, indices,
# and both targets (T1 external SMA, T1-strict training-only SPI-3).
stage6_design <- function(monthly, indices, sma_long, district_id) {
  did <- district_id
  d <- merge(indices, monthly[, .(date, mean_E_Q, mean_p_ge_q,
                                  mean_p_ge_theta, mean_rho)],
             by = "date", all.x = TRUE)
  d <- merge(d, sma_long[district_id == did, .(date, target_sma)],
             by = "date", all.x = TRUE)
  d[, target_spi3 := as.integer(!is.na(spi3) & spi3 <= -1)]
  d <- d[order(date)]
  # Lagged predictors for E2 (prospective, 1-month lead).
  d[, `:=`(
    spi3_lag = data.table::shift(spi3, 1),
    spei3_lag = data.table::shift(spei3, 1),
    ssi3_lag = data.table::shift(ssi3, 1),
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
                       drop_spi3 = FALSE) {
  feats <- if (endpoint == "E1") FAMILY_FEATURES else FAMILY_FEATURES_E2
  y <- design[[target_col]]
  train_mask <- design$train & is.finite(y)
  test_mask <- design$test & is.finite(y)
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
        brier = NA_real_, auc = NA_real_, logloss = NA_real_)
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
    fit <- fit_ridge_logistic(Xmat[tr, , drop = FALSE], y[ok_train], lambda = P$L2)
    p <- predict_ridge_logistic(fit$beta, Xmat[te, , drop = FALSE])
    yt <- y[ok_test]
    metrics[[fam]] <- data.table::data.table(
      family = fam, n_train = sum(ok_train), n_test = sum(ok_test),
      brier = brier_score(yt, p), auc = auc_score(yt, p),
      logloss = log_loss(yt, p))
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
