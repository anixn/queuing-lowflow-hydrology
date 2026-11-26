# =====================================================================
# R/us_pilot/07_build_reservoir_rates.R -- daily lambda/mu and queue run
# for the 50-reservoir US core.
#
# Unit = reservoir.
#   lambda(t): irrigation demand over the command area
#              need = max(Kc * ET0_FAO_PM - phi * P, 0),  lambda = need / 20
#   mu(t)    : reservoir outflow over the command area, capped at 10 mm/day
#   K        : reservoir storage expressed in claims (capped 25..80)
#   target   : USDM monthly mean DSCI >= 100 (D1 or worse)
#
# Kc is a declared constant (0.8) for the first pass; it is a sensitivity
# axis. OpenET/WaPOR are reserved for calibration/validation.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  dir.create(file.path(out_dir, "rates"), showWarnings = FALSE, recursive = TRUE)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R")) source(file.path(root, "R", "00_utils", u))
  suppressMessages(library(data.table))

  Kc <- 0.8
  phi <- P$phi
  d_mm <- P$d_mm
  cap_mm <- P$cap_mm
  start <- as.Date("2000-01-01"); end <- as.Date("2020-12-31")

  core <- fread(file.path(out_dir, "reservoir_core.csv"))
  county <- fread(file.path(out_dir, "reservoir_county.csv"))
  usdm <- fread(file.path(out_dir, "usdm_monthly.csv"))
  core <- merge(core, county[, .(DAM_ID, county_fips, county_name)], by = "DAM_ID")

  meta <- list(); monthly_all <- list(); daily_all <- list()
  for (i in seq_len(nrow(core))) {
    r <- core[i]
    cf <- file.path("D:/Datasets/Caravan_2025/timeseries/camels",
                    paste0(r$matched_gauge, ".csv"))
    rf <- file.path("D:/Datasets/ResOpsUS/extracted/ResOpsUS/time_series_all",
                    sprintf("ResOpsUS_%d.csv", r$DAM_ID))
    if (!file.exists(cf) || !file.exists(rf)) next
    f <- fread(cf, select = c("date", "total_precipitation_sum",
                              "potential_evaporation_sum_FAO_PENMAN_MONTEITH"))
    setnames(f,
             c("total_precipitation_sum",
               "potential_evaporation_sum_FAO_PENMAN_MONTEITH"),
             c("prcp_mm", "et0_mm"))
    d <- fread(rf, select = c("date", "outflow", "storage"))
    f[, date := as.Date(date)]; d[, date := as.Date(date)]
    m <- merge(f, d, by = "date", all = FALSE)
    m <- m[date >= start & date <= end]
    if (nrow(m) < 300) next

    m[, month := as.integer(format(date, "%m"))]
    m[, need_mm := pmax(Kc * et0_mm - phi * prcp_mm, 0)]
    m[, lambda := need_mm / d_mm]
    m[, mu_mm := outflow * 86400 / r$A_cmd_m2 * 1000]
    m[, mu := pmin(mu_mm, cap_mm) / d_mm]
    m[, missing_day := is.na(outflow) | is.na(et0_mm) | is.na(prcp_mm)]
    m[, ym := format(date, "%Y-%m")]

    ok <- !m$missing_day
    if (sum(ok) < 300) next
    lam_bar <- mean(m$lambda[ok]); mu_bar <- mean(m$mu[ok])
    if (!is.finite(lam_bar) || lam_bar <= 0) next
    rho <- sum(m$lambda[ok]) / sum(m$mu[ok])
    q_star <- max(1L, ceiling(P$q_days * lam_bar))
    K_storage <- ifelse(is.finite(r$max_storage_MCM) && r$max_storage_MCM > 0,
                        r$max_storage_MCM * 1e6 / r$V_claim_m3,
                        P$K_days * lam_bar)
    K <- as.integer(min(80, max(25, ceiling(K_storage), q_star + 1L)))
    q_star <- min(q_star, K - 1L)
    theta <- as.integer(min(ceiling(P$theta_mult * q_star), K))
    cfg <- queue_config(q_star, K, c = P$c, theta = theta,
                        alpha = P$alpha, eta = P$eta)
    daily <- as.data.table(run_queue(m$date, m$lambda, m$mu, cfg,
                                     pause = m$missing_day))
    daily[, `:=`(DAM_ID = r$DAM_ID, missing_day = m$missing_day,
                 ym = m$ym)]
    daily_all[[length(daily_all) + 1]] <- daily

    mon <- daily[, {
      complete <- !any(missing_day)
      if (!complete) {
        .(month_complete = FALSE, mean_E_Q = NA_real_,
          mean_p_ge_q = NA_real_, mean_p_ge_theta = NA_real_,
          mean_lambda = NA_real_, mean_mu = NA_real_,
          mean_rho = NA_real_, served = NA_real_,
          reneged = NA_real_, blocked = NA_real_)
      } else {
        .(month_complete = TRUE,
          mean_E_Q = mean(E_Q), mean_p_ge_q = mean(p_ge_q),
          mean_p_ge_theta = mean(p_ge_theta),
          mean_lambda = mean(lambda), mean_mu = mean(mu),
          mean_rho = mean(rho_day, na.rm = TRUE),
          served = sum(served), reneged = sum(reneged),
          blocked = sum(blocked))
      }
    }, by = ym]
    mon[, `:=`(DAM_ID = r$DAM_ID, county_fips = r$county_fips,
               date = as.Date(paste0(ym, "-01")))]
    monthly_all[[length(monthly_all) + 1]] <- mon

    meta[[length(meta) + 1]] <- data.table(
      DAM_ID = r$DAM_ID, DAM_NAME = r$DAM_NAME, STATE = r$STATE,
      matched_gauge = r$matched_gauge, county_fips = r$county_fips,
      A_cmd_km2 = r$A_cmd_m2 / 1e6, max_storage_MCM = r$max_storage_MCM,
      lam_bar = lam_bar, mu_bar = mu_bar, rho = rho,
      q_star = q_star, K = K, theta = theta, K_storage = K_storage,
      max_E_Q = max(daily$E_Q), max_p_ge_q = max(daily$p_ge_q),
      max_p_eq_K = max(daily$p_eq_K),
      ledger_residual = attr(daily, "max_ledger_residual") %||% NA_real_
    )
    if (!(i %% 10)) cat(sprintf("  [%2d/%2d] reservoirs\n", i, nrow(core)))
  }

  meta_tab <- rbindlist(meta, fill = TRUE)
  mon_tab <- rbindlist(monthly_all, fill = TRUE)
  daily_tab <- rbindlist(daily_all, fill = TRUE)
  fwrite(meta_tab, file.path(out_dir, "reservoir_queue_meta.csv"))
  fwrite(daily_tab, file.path(out_dir, "reservoir_daily.csv"))
  fwrite(mon_tab, file.path(out_dir, "reservoir_monthly.csv"))

  cat(sprintf("reservoirs run: %d\n", nrow(meta_tab)))
  cat(sprintf("rho range: %.3f to %.3f\n", min(meta_tab$rho), max(meta_tab$rho)))
  cat(sprintf("q* range: %d to %d; K range: %d to %d\n",
              min(meta_tab$q_star), max(meta_tab$q_star),
              min(meta_tab$K), max(meta_tab$K)))
  cat(sprintf("max P(Q=K): %.3e (guard %.0e)\n",
              max(meta_tab$max_p_eq_K, na.rm = TRUE), P$block_guard))
  cat(sprintf("max ledger residual: %.3e\n",
              max(meta_tab$ledger_residual, na.rm = TRUE)))
  cat(sprintf("reservoirs in rho window: %d\n",
              sum(meta_tab$rho >= P$rho_window[1] & meta_tab$rho <= P$rho_window[2])))
  print(meta_tab[order(-rho)][1:10,
        .(DAM_ID, DAM_NAME, STATE, rho = round(rho, 2), q_star, K,
          max_E_Q = round(max_E_Q, 1), max_p_ge_q = round(max_p_ge_q, 3))])
})
