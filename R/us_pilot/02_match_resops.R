# =====================================================================
# R/us_pilot/02_match_resops.R -- spatially match ResOpsUS reservoirs to
# Caravan-US catchments.
#
# Inputs:
#   D:/Datasets/Caravan_2025/shapefiles/camels/camels_basin_shapes.shp
#   D:/Datasets/ResOpsUS/extracted/ResOpsUS/attributes/reservoir_attributes.csv
#   output_us/caravan_us_screen.csv
# Outputs:
#   output_us/resops_caravan_match.csv
#
# A reservoir is "inside" a catchment if its point falls in the polygon;
# otherwise the nearest catchment is recorded with its distance (km). The
# nearest match is a candidate only when it is close; the distance is kept
# so the analyst can set the tolerance explicitly.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(sf))
  suppressMessages(library(data.table))

  shp <- file.path(CARAVAN_ROOT, "shapefiles", "camels",
                   "camels_basin_shapes.shp")
  res_csv <- file.path(RESOPS_ROOT, "attributes", "reservoir_attributes.csv")

  poly <- st_read(shp, quiet = TRUE)
  poly <- st_transform(poly, 4326)
  res <- fread(res_csv)
  res <- res[!is.na(LAT) & !is.na(LONG)]
  pts <- st_as_sf(res, coords = c("LONG", "LAT"), crs = 4326)

  # Inside matches
  hit <- st_intersects(pts, poly)
  inside_gauge <- vapply(hit, function(i) {
    if (length(i)) poly$gauge_id[i[1]] else NA_character_
  }, character(1))

  # Nearest catchment (for all reservoirs, so distance is always known)
  nearest_i <- st_nearest_feature(pts, poly)
  nearest_gauge <- poly$gauge_id[nearest_i]
  dist_m <- as.numeric(st_distance(pts, poly[nearest_i, ], by_element = TRUE))

  m <- data.table(
    DAM_ID = res$DAM_ID,
    DAM_NAME = res$DAM_NAME,
    STATE = res$STATE,
    dam_lat = res$LAT,
    dam_lon = res$LONG,
    ts_start = res$TIME_SERIES_START,
    ts_end = res$TIME_SERIES_END,
    gauge_id_inside = inside_gauge,
    gauge_id_nearest = nearest_gauge,
    dist_nearest_km = dist_m / 1000
  )
  m[, matched_gauge := fifelse(!is.na(gauge_id_inside), gauge_id_inside,
                               gauge_id_nearest)]
  m[, match_type := fifelse(!is.na(gauge_id_inside), "inside", "nearest")]

  screen <- fread(file.path(out_dir, "caravan_us_screen.csv"))
  m <- merge(m, screen[, .(gauge_id, gauge_name, area, ire_pc_sse, crp_pc_sse,
                           dor_pc_pva, rev_mc_usu, irrigated, regulated)],
             by.x = "matched_gauge", by.y = "gauge_id", all.x = TRUE)
  setorder(m, match_type, -ire_pc_sse, dist_nearest_km)
  fwrite(m, file.path(out_dir, "resops_caravan_match.csv"))

  cat(sprintf("reservoirs: %d\n", nrow(m)))
  cat(sprintf("inside a Caravan catchment: %d\n", sum(m$match_type == "inside")))
  cat(sprintf("nearest match <= 10 km: %d\n",
              sum(m$match_type == "nearest" & m$dist_nearest_km <= 10)))
  cat(sprintf("unique matched catchments: %d\n", uniqueN(m$matched_gauge)))
  cat(sprintf("matched catchments with ire_pc_sse > 0: %d\n",
              uniqueN(m[!is.na(ire_pc_sse) & ire_pc_sse > 0, matched_gauge])))
  cat(sprintf("matched catchments with irrigation AND regulation: %d\n",
              uniqueN(m[!is.na(irrigated) & irrigated &
                          !is.na(regulated) & regulated, matched_gauge])))
  cat("\ntop irrigated matches:\n")
  print(m[!is.na(ire_pc_sse) & ire_pc_sse > 0][order(-ire_pc_sse)][1:15,
        .(DAM_ID, DAM_NAME, STATE, matched_gauge, match_type,
          dist_nearest_km = round(dist_nearest_km, 1),
          area, ire_pc_sse, dor_pc_pva)])
  cat("\nwrote", file.path(out_dir, "resops_caravan_match.csv"), "\n")
})
