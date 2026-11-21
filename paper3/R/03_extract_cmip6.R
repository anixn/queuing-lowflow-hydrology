# =====================================================================
# 03_extract_cmip6.R   --   Paper 3: extract one CMIP6 SSP at the pilot gauge
#
# PURPOSE
#   Read the daily SSP NetCDF files for ONE model and ONE scenario, take the
#   grid cell nearest gauge 4026, convert units, and write a clean daily CSV
#       date, pr_mm, tasmax_c, tasmin_c, et0_mm
#   where et0_mm is Hargreaves reference evapotranspiration from Tmax/Tmin.
#
# HOW TO USE
#   Linear script. Edit BLOCK 1, then run from the project root:
#       Rscript paper3/R/03_extract_cmip6.R
#   Requires the R package ncdf4 (already installed here).
#
# DATA
#   D:/Datasets/Download_CMIP/SSP/{pr,tasmax,tasmin}/
#       <var>_day_<model>_<ssp>_r1i1p1f1_gn_<year>_v2.0.nc
#   Run only AFTER the download for the chosen model/SSP/years has finished.
# =====================================================================

library(ncdf4)


# ---------------------------------------------------------------------
# BLOCK 1 -- SETTINGS (edit here; nothing below needs editing)
# ---------------------------------------------------------------------

model     <- "ACCESS-ESM1-5"       # use a combination with all 3 variables present
ssp       <- "ssp245"
years     <- 2015:2040             # near-term window from download_cmip6_ssp.R

cmip_root <- "D:/Datasets/Download_CMIP/SSP"
lat_gauge <- 16.6836               # gauge 4026 Kurundwad (from camels_ind_topo.csv)
lon_gauge <- 74.6031
out_file  <- "paper3/data/cmip_4026_ACCESS-ESM1-5_ssp245_2015-2040.csv"


# ---------------------------------------------------------------------
# BLOCK 2 -- READ ONE VARIABLE OVER ALL YEARS, NEAREST GRID CELL
# ---------------------------------------------------------------------

read_var <- function(var, years, model, ssp, root, lat, lon) {

  out <- data.frame(date = as.Date(character()), value = numeric())

  for (yr in years) {
    f <- file.path(root, var,
                   paste0(var, "_day_", model, "_", ssp,
                          "_r1i1p1f1_gn_", yr, "_v2.0.nc"))
    if (!file.exists(f)) {
      cat("MISSING:", f, "\n")
      next
    }

    nc <- nc_open(f)
    lats <- ncvar_get(nc, "lat")
    lons <- ncvar_get(nc, "lon")
    ilat <- which.min(abs(lats - lat))
    ilon <- which.min(abs(lons - lon))
    vals <- ncvar_get(nc, var,
                      start = c(ilon, ilat, 1),
                      count = c(1, 1, -1))
    tnum <- ncvar_get(nc, "time")
    nc_close(nc)

    # CMIP6 time coordinate: days since 1850-01-01, proleptic Gregorian.
    dates <- as.Date("1850-01-01") + as.numeric(tnum)
    out <- rbind(out, data.frame(date = dates,
                                 value = as.numeric(vals)))
  }

  out <- out[order(out$date), ]
  out <- out[!duplicated(out$date), ]
  out
}


# ---------------------------------------------------------------------
# BLOCK 3 -- READ THE THREE VARIABLES
# ---------------------------------------------------------------------

pr_raw    <- read_var("pr",     years, model, ssp, cmip_root, lat_gauge, lon_gauge)
tasmax_raw <- read_var("tasmax", years, model, ssp, cmip_root, lat_gauge, lon_gauge)
tasmin_raw <- read_var("tasmin", years, model, ssp, cmip_root, lat_gauge, lon_gauge)

cat("Rows read: pr =", nrow(pr_raw),
    " tasmax =", nrow(tasmax_raw),
    " tasmin =", nrow(tasmin_raw), "\n")


# ---------------------------------------------------------------------
# BLOCK 4 -- UNIT CONVERSION AND MERGE
# ---------------------------------------------------------------------
# pr is kg m-2 s-1 -> mm/day by multiplying by 86400.
# tasmax and tasmin are Kelvin -> degrees Celsius by subtracting 273.15.

d <- merge(
  data.frame(date = pr_raw$date,     pr_mm    = pr_raw$value * 86400),
  data.frame(date = tasmax_raw$date, tasmax_c = tasmax_raw$value - 273.15),
  by = "date")
d <- merge(
  d,
  data.frame(date = tasmin_raw$date, tasmin_c = tasmin_raw$value - 273.15),
  by = "date")
d <- d[order(d$date), ]


# ---------------------------------------------------------------------
# BLOCK 5 -- HARGREAVES REFERENCE EVAPOTRANSPIRATION (FAO-56)
# ---------------------------------------------------------------------
# Needs only Tmax, Tmin, latitude and day of year. Kept as explicit steps.

doy   <- as.integer(format(d$date, "%j"))
lat_r <- lat_gauge * pi / 180
dr    <- 1 + 0.033 * cos(2 * pi * doy / 365)
delta <- 0.409 * sin(2 * pi * doy / 365 - 1.39)
ws    <- acos(pmin(1, pmax(-1, -tan(lat_r) * tan(delta))))
Ra    <- (24 * 60 / pi) * 0.0820 * dr *
         (ws * sin(lat_r) * sin(delta) +
          cos(lat_r) * cos(delta) * sin(ws))

tmean <- (d$tasmax_c + d$tasmin_c) / 2
d$et0_mm <- 0.0023 * Ra * (tmean + 17.8) * sqrt(pmax(d$tasmax_c - d$tasmin_c, 0))


# ---------------------------------------------------------------------
# BLOCK 6 -- WRITE CLEAN CSV AND PRINT DIAGNOSTICS
# ---------------------------------------------------------------------

dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
out <- d
out$date <- format(out$date, "%Y-%m-%d")
write.csv(out, out_file, row.names = FALSE)

cat("Written:", out_file, "\n")
cat("Rows:", nrow(out), " dates:", out$date[1], "to", out$date[nrow(out)], "\n")
cat(sprintf("pr   : mean %.2f mm/day\n", mean(d$pr_mm)))
cat(sprintf("Tmax : mean %.2f C\n", mean(d$tasmax_c)))
cat(sprintf("Tmin : mean %.2f C\n", mean(d$tasmin_c)))
cat(sprintf("ET0  : mean %.2f mm/day\n", mean(d$et0_mm)))
cat("NEXT: bias-correct against CAMELS/IMD, then build future lambda and mu.\n")
