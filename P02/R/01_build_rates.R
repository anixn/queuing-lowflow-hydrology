# =====================================================================
# 01_build_rates.R   --   P02 real-data pilot (CAMELS-India)
#
# PURPOSE
#   Build one clean daily CSV with the two queueing rates
#       lambda(t) = demand claims arriving per day
#       mu(t)     = backlog claims cleared per day
#   from the CAMELS-India catchment forcings and observed streamflow.
#
# HOW TO USE
#   This is a LINEAR script. Edit BLOCK 1, then run from the project root:
#       Rscript P02/R/01_build_rates.R
#   Output: P02/data/generated/rates_4026.csv
#
# DATA
#   D:/Datasets/CIMP6_India/data_raw/camels_ind_forcings/
#       catchment_mean_forcings/04026.csv
#       streamflow_timeseries/streamflow_observed.csv
# =====================================================================


# ---------------------------------------------------------------------
# BLOCK 1 -- SETTINGS (edit here; nothing below needs editing)
# ---------------------------------------------------------------------

gauge_id        <- 4026     # 4026 = Kurundwad, Krishna basin, Maharashtra
data_root       <- "D:/Datasets/CIMP6_India/data_raw/camels_ind_forcings"
out_file        <- "P02/data/generated/rates_4026.csv"

# REVISABLE WORKING CONVENTION (unlocked 25 Nov 2026; see ../START_HERE.md).
# CAMELS-IND does not contain these values. They are explicit assumptions,
# not measurements; replace with documented canal/crop evidence or a declared
# sensitivity envelope, updating all convention locations together.
command_area_ha <- 45000    # Sangli canal-irrigated area proxy (hectares; not gauge-specific)
claim_volume_m3 <- 9e6      # 1 claim = 9x10^6 m^3 = 20 mm over 45,000 ha
mu_cap          <- 3.0      # 3 claims/day = 60 mm/day = 2.7x10^7 m^3/day ceiling

# Physical constants (also assumptions, but standard first-pass choices)
baseflow_frac   <- 0.5      # share of streamflow treated as firm supply
canal_share     <- 0.0      # extra supply from a second source (0 = none)
peff_frac       <- 0.7      # effective rainfall as a fraction of total rainfall
sowing_doy      <- 200      # kharif sowing day-of-year
season_length   <- 120      # growing-season length (days)
peak_kc         <- 1.2      # FAO-56 peak crop coefficient


# ---------------------------------------------------------------------
# BLOCK 2 -- READ CATCHMENT-MEAN FORCINGS
# ---------------------------------------------------------------------

force_file <- file.path(data_root, "catchment_mean_forcings",
                        sprintf("%05d.csv", gauge_id))   # 4026 -> "04026.csv"
force <- read.csv(force_file, stringsAsFactors = FALSE)
force$date <- as.Date(paste(force$year, force$month, force$day, sep = "-"))
cat("Forcings:", nrow(force), "daily rows,",
    format(min(force$date)), "to", format(max(force$date)), "\n")


# ---------------------------------------------------------------------
# BLOCK 3 -- READ OBSERVED STREAMFLOW FOR THIS GAUGE ONLY
# ---------------------------------------------------------------------

q_file <- file.path(data_root, "streamflow_timeseries", "streamflow_observed.csv")
q_all <- read.csv(q_file, stringsAsFactors = FALSE, check.names = FALSE)
q_col <- as.character(gauge_id)            # e.g. "4026" (raw header, no X prefix)
if (!(q_col %in% names(q_all))) {
  stop("Gauge ", q_col, " not found in ", q_file)
}
q <- q_all[, c("year", "month", "day", q_col)]
names(q)[4] <- "q_m3s"
q$date <- as.Date(paste(q$year, q$month, q$day, sep = "-"))
q <- q[, c("date", "q_m3s")]
cat("Streamflow:", nrow(q), "daily rows; non-missing:",
    sum(!is.na(q$q_m3s)), "\n")


# ---------------------------------------------------------------------
# BLOCK 4 -- PUT BOTH SERIES ON ONE COMPLETE DAILY CALENDAR
# ---------------------------------------------------------------------

dates <- seq(min(force$date), max(force$date), by = "day")
d <- data.frame(date = dates)
d <- merge(d, force[, c("date", "prcp.mm.day.", "pet_gleam.mm.day.")],
           by = "date", all.x = TRUE)
d <- merge(d, q, by = "date", all.x = TRUE)
d <- d[order(d$date), ]

# Fill gaps by linear interpolation and flag which streamflow days were filled.
xnum <- as.numeric(d$date)
d$q_imputed <- is.na(d$q_m3s)
d$q_m3s <- approx(xnum, d$q_m3s, xout = xnum, rule = 2)$y
d$prcp.mm.day. <- approx(xnum, d$prcp.mm.day., xout = xnum, rule = 2)$y
d$pet_gleam.mm.day. <- approx(xnum, d$pet_gleam.mm.day., xout = xnum, rule = 2)$y

cat("Streamflow days interpolated:", sum(d$q_imputed), "\n")
cat("Zero-flow days in series:", sum(d$q_m3s == 0), "\n")


# ---------------------------------------------------------------------
# BLOCK 5 -- DEMAND: CROP WATER REQUIREMENT -> lambda(t)
# ---------------------------------------------------------------------

doy <- as.integer(format(d$date, "%j"))
phase <- ((doy - sowing_doy) %% 365) / season_length
kc <- ifelse(phase <= 1,
             0.4 + (peak_kc - 0.4) * sin(pi * pmin(pmax(phase, 0), 1)),
             0.35)

p_eff   <- peff_frac * d$prcp.mm.day.           # effective rain (mm/day)
etc     <- kc * d$pet_gleam.mm.day.             # crop evapotranspiration (mm/day)
need_mm <- pmax(etc - p_eff, 0)                 # irrigation need (mm/day)

# 1 mm over 1 hectare = 10 cubic metres.
d$cwr_m3 <- need_mm * command_area_ha * 10
d$lambda <- d$cwr_m3 / claim_volume_m3          # claims per day


# ---------------------------------------------------------------------
# BLOCK 6 -- SUPPLY: STREAMFLOW -> mu(t)
# ---------------------------------------------------------------------

# Convert m^3/s to m^3/day, take the firm (baseflow) share, then cap it at a
# nominal intake capacity. Without the cap, flood flows create meaningless
# service rates and make the RK4 step unstable.
firm_m3 <- d$q_m3s * 86400 * baseflow_frac
firm_m3 <- firm_m3 * (1 + canal_share)
d$mu <- pmin(firm_m3 / claim_volume_m3, mu_cap) # claims per server per day


# ---------------------------------------------------------------------
# BLOCK 7 -- WRITE CLEAN CSV AND PRINT DIAGNOSTICS
# ---------------------------------------------------------------------

dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
out <- d[, c("date", "lambda", "mu", "cwr_m3", "q_m3s", "q_imputed")]
out$date <- format(out$date, "%Y-%m-%d")
write.csv(out, out_file, row.names = FALSE)

cat("\nWritten:", out_file, "\n")
cat(sprintf("lambda: min %.3f  mean %.3f  max %.3f claims/day\n",
            min(d$lambda), mean(d$lambda), max(d$lambda)))
cat(sprintf("mu    : min %.3f  mean %.3f  max %.3f claims/day\n",
            min(d$mu), mean(d$mu), max(d$mu)))
cat(sprintf("rho at mean rates (lambda/mu): %.3f\n",
            mean(d$lambda) / mean(d$mu)))
cat("REMINDER: command_area_ha, claim_volume_m3 and mu_cap are ASSUMPTIONS.\n")
cat("Fix them on physical grounds before interpreting queue indicators.\n")
