# =====================================================================
# R/us_pilot/04_county_match.R -- assign each core reservoir to a US county
# (for the USDM target).
#
# Inputs:
#   output_us/reservoir_core.csv
#   D:/Datasets/US_boundaries/cb_2020_us_county_500k.zip
# Output:
#   output_us/reservoir_county.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(sf))
  suppressMessages(library(data.table))

  zip <- US_COUNTY_ZIP
  exdir <- file.path(DATA_ROOT, "US_boundaries", "county")
  if (!dir.exists(exdir)) unzip(zip, exdir = exdir)
  shp <- list.files(exdir, pattern = "\\.shp$", full.names = TRUE)[1]
  county <- st_read(shp, quiet = TRUE)
  county <- st_transform(county, 4326)

  core <- fread(file.path(out_dir, "reservoir_core.csv"))
  pts <- st_as_sf(core, coords = c("dam_lon", "dam_lat"), crs = 4326)

  hit <- st_intersects(pts, county)
  fips <- vapply(hit, function(i) if (length(i)) county$GEOID[i[1]] else NA_character_,
                 character(1))
  cname <- vapply(hit, function(i) if (length(i)) county$NAME[i[1]] else NA_character_,
                  character(1))
  out <- data.table(
    DAM_ID = core$DAM_ID, DAM_NAME = core$DAM_NAME, STATE = core$STATE,
    dam_lat = core$dam_lat, dam_lon = core$dam_lon,
    county_fips = sprintf("%05d", as.integer(fips)),
    county_name = cname
  )
  fwrite(out, file.path(out_dir, "reservoir_county.csv"))
  cat("reservoirs:", nrow(out), "\n")
  cat("with a county:", sum(!is.na(out$county_fips)), "\n")
  cat("unique counties:", uniqueN(out$county_fips, na.rm = TRUE), "\n")
  print(out[is.na(county_fips)])
  cat("wrote", file.path(out_dir, "reservoir_county.csv"), "\n")
})
