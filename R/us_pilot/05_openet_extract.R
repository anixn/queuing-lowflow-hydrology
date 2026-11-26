# =====================================================================
# R/us_pilot/05_openet_extract.R -- monthly OpenET actual ET for the 50
# core reservoir catchments, 2016-2020.
#
# The point queried is the Caravan catchment centroid (the irrigated-area
# context), not the dam itself: ET over a water surface is not irrigation
# demand. The result is used to calibrate/validate the crop-coefficient
# demand model, not as the multi-decade driver.
#
# Requires OPENET_API_KEY in the environment. Responses are cached one CSV
# per reservoir under output_us/openet/ and the script is resumable.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  cache <- file.path(out_dir, "openet")
  dir.create(cache, showWarnings = FALSE, recursive = TRUE)
  suppressMessages(library(data.table))
  suppressMessages(library(jsonlite))

  key <- Sys.getenv("OPENET_API_KEY")
  if (!nzchar(key)) stop("OPENET_API_KEY is not set.", call. = FALSE)

  core <- fread(file.path(out_dir, "reservoir_core.csv"))
  screen <- fread(file.path(out_dir, "caravan_us_screen.csv"))
  core <- merge(core, screen[, .(gauge_id, gauge_lat, gauge_lon)],
                by.x = "matched_gauge", by.y = "gauge_id", all.x = TRUE)
  core <- core[!is.na(gauge_lat) & !is.na(gauge_lon)]

  url <- "https://openet-api.org/raster/timeseries/point"
  body_path <- tempfile(fileext = ".json")
  out_path <- tempfile(fileext = ".json")

  rows <- list()
  for (i in seq_len(nrow(core))) {
    id <- core$DAM_ID[i]
    cache_f <- file.path(cache, sprintf("DAM_%d.csv", id))
    if (file.exists(cache_f)) {
      d <- fread(cache_f)
    } else {
      body <- list(
        date_range = c("2016-01-01", "2020-12-31"),
        interval = "monthly",
        geometry = c(core$gauge_lon[i], core$gauge_lat[i]),
        model = "Ensemble",
        variable = "ET",
        reference_et = "gridMET",
        units = "mm",
        file_format = "JSON"
      )
      write_json(body, body_path, auto_unbox = TRUE)
      status <- system2("curl.exe", c(
        "-s", "-f", "-X", "POST", shQuote(url),
        "-H", shQuote(paste0("Authorization: ", key)),
        "-H", "accept: application/json",
        "-H", "Content-Type: application/json",
        "-d", shQuote(paste0("@", body_path)),
        "-o", shQuote(out_path)
      ), stdout = FALSE, stderr = FALSE)
      if (!identical(status, 0L)) {
        cat(sprintf("  [%2d/%2d] DAM %d curl exit %s -- skipped\n",
                    i, nrow(core), id, status))
        next
      }
      d <- tryCatch(fromJSON(out_path), error = function(e) NULL)
      if (is.null(d) || !nrow(d)) next
      d <- as.data.table(d)
      setnames(d, c("time", "et"), c("date", "et_mm"), skip_absent = TRUE)
      fwrite(d, cache_f)
      Sys.sleep(0.4)
    }
    d[, DAM_ID := id]
    rows[[length(rows) + 1]] <- d
    if (!(i %% 10)) cat(sprintf("  [%2d/%2d] done\n", i, nrow(core)))
  }

  out <- rbindlist(rows, fill = TRUE)
  if (nrow(out)) {
    out[, date := as.Date(date)]
    setorder(out, DAM_ID, date)
  }
  fwrite(out, file.path(out_dir, "openet_monthly.csv"))
  cat(sprintf("OpenET rows: %d for %d reservoirs\n", nrow(out),
              uniqueN(out$DAM_ID)))
  cat("wrote", file.path(out_dir, "openet_monthly.csv"), "\n")
})
