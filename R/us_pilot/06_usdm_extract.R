# =====================================================================
# R/us_pilot/06_usdm_extract.R -- monthly USDM DSCI target for each core
# reservoir's county, 2000-2020.
#
# USDM REST API: CountyStatistics/GetDSCI returns weekly DSCI per county.
# We aggregate to monthly mean and max. DSCI is 0 (no drought) to 500
# (exceptional, D4); >=100 approximates D1 or worse.
#
# Inputs:  output_us/reservoir_county.csv
# Outputs: output_us/usdm_monthly.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  suppressMessages(library(data.table))

  county <- fread(file.path(out_dir, "reservoir_county.csv"))
  fips <- unique(county$county_fips[!is.na(county$county_fips)])
  cat("unique counties:", length(fips), "\n")

  base <- "https://usdmdataservices.unl.edu/api/CountyStatistics/GetDSCI"
  rows <- list()
  for (k in seq_along(fips)) {
    f <- sprintf("%05d", as.integer(fips[k]))
    url <- sprintf("%s?aoi=%s&startdate=1/1/2000&enddate=12/31/2020&statisticsType=1",
                   base, f)
    tmp <- tempfile(fileext = ".csv")
    cmd <- sprintf('curl.exe -s -L -A "Mozilla/5.0" -o "%s" "%s"', tmp, url)
    status <- system(cmd)
    if (!identical(status, 0L)) { cat("  failed:", f, "curl", status, "\n"); next }
    if (!file.exists(tmp) || file.size(tmp) == 0) { cat("  empty:", f, "\n"); next }
    d <- tryCatch(data.table::fread(tmp), error = function(e) NULL)
    if (is.null(d) || !nrow(d) || !"DSCI" %in% names(d)) next
    d[, date := as.Date(as.character(MapDate), format = "%Y%m%d")]
    d[, ym := format(date, "%Y-%m")]
    mon <- d[, .(dsci_mean = mean(DSCI, na.rm = TRUE),
                 dsci_max = max(DSCI, na.rm = TRUE),
                 n_weeks = .N), by = ym]
    mon[, `:=`(county_fips = f,
               date = as.Date(paste0(ym, "-01")))]
    rows[[length(rows) + 1]] <- mon[, .(county_fips, date, dsci_mean,
                                        dsci_max, n_weeks)]
    if (!(k %% 10)) cat(sprintf("  [%2d/%2d] counties\n", k, length(fips)))
  }

  out <- rbindlist(rows, fill = TRUE)
  setorder(out, county_fips, date)
  fwrite(out, file.path(out_dir, "usdm_monthly.csv"))
  cat(sprintf("USDM rows: %d for %d counties\n", nrow(out),
              uniqueN(out$county_fips)))
  cat("date range:", as.character(min(out$date)), "to",
      as.character(max(out$date)), "\n")
  cat("wrote", file.path(out_dir, "usdm_monthly.csv"), "\n")
})
