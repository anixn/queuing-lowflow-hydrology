# =====================================================================
# R/compare/01_screen_us_gauges.R -- screen Caravan-US gauges under the
# COMMON protocol (same as India): f_irr = 0.10, Kc = 0.8, SUP-1.
#
# This is the first step of the like-for-like India-US comparison. It only
# profiles and screens; the common queue and evaluation follow.
#
# Output: output_compare/us_gauges_screen.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_compare")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(data.table))

  ot <- fread(file.path(CARAVAN_ROOT, "attributes", "camels",
                        "attributes_other_camels.csv"))
  ts_dir <- file.path(CARAVAN_ROOT, "timeseries", "camels")
  files <- list.files(ts_dir, pattern = "\\.csv$", full.names = TRUE)
  cat("Caravan-US gauges:", length(files), "\n")

  interior_gap <- function(x) {
    ok <- which(!is.na(x))
    if (length(ok) < 2) return(NA_integer_)
    r <- rle(is.na(x[min(ok):max(ok)]))
    if (!any(r$values)) 0L else max(r$lengths[r$values])
  }

  rows <- vector("list", length(files))
  for (k in seq_along(files)) {
    f <- files[k]
    gid <- sub("\\.csv$", "", basename(f))
    d <- tryCatch(fread(f, select = c("date", "streamflow",
                                      "total_precipitation_sum",
                                      "potential_evaporation_sum_FAO_PENMAN_MONTEITH"),
                        showProgress = FALSE),
                  error = function(e) NULL)
    if (is.null(d) || !nrow(d)) next
    q <- d$streamflow
    q[!is.na(q) & q < 0] <- NA_real_
    pet <- d$potential_evaporation_sum_FAO_PENMAN_MONTEITH
    prcp <- d$total_precipitation_sum
    area_km2 <- ot$area[match(gid, ot$gauge_id)]
    if (is.na(area_km2)) next
    A_cmd <- 0.10 * area_km2 * 1e6

    need <- pmax(0.8 * pet - 0.7 * prcp, 0)
    lambda <- need / 20
    mu <- pmin(q * 86400 * 0.5 / A_cmd * 1000, 10) / 20
    ok <- !is.na(q) & !is.na(pet) & !is.na(prcp)
    ok_flow <- !is.na(q)
    if (!any(ok_flow)) next
    rho <- if (sum(ok) > 0) sum(lambda[ok]) / sum(mu[ok]) else NA_real_

    rows[[k]] <- data.table(
      gauge_id = gid,
      area_km2 = area_km2,
      n_days = nrow(d),
      n_flow = sum(ok_flow),
      first_flow = min(d$date[ok_flow]),
      last_flow = max(d$date[ok_flow]),
      zero_frac = mean(q == 0, na.rm = TRUE),
      interior_gap = interior_gap(q),
      mean_q = mean(q, na.rm = TRUE),
      mean_lambda = mean(lambda[ok]),
      mean_mu = mean(mu[ok]),
      rho = rho,
      in_window = is.finite(rho) & rho >= P$rho_window[1] & rho <= P$rho_window[2]
    )
    if (!(k %% 100)) cat(sprintf("  profiled %d/%d\n", k, length(files)))
  }

  out <- rbindlist(rows, fill = TRUE)
  fwrite(out, file.path(out_dir, "us_gauges_screen.csv"))
  cat("profiled:", nrow(out), "\n")
  cat("in window:", sum(out$in_window, na.rm = TRUE), "\n")
  cat("strict (zero<0.3, gap<=30, in window):",
      sum(out$in_window & out$zero_frac < 0.3 & out$interior_gap <= 30,
          na.rm = TRUE), "\n")
  cat("wrote", file.path(out_dir, "us_gauges_screen.csv"), "\n")
})
