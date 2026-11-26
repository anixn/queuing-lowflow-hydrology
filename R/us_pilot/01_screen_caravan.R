# =====================================================================
# R/us_pilot/01_screen_caravan.R -- screen Caravan-US catchments for the
# reservoir + irrigation queue pilot.
#
# Inputs (local, read-only):
#   D:/Datasets/Caravan_2025/attributes/camels/*.csv
#   D:/Datasets/Caravan_2025/timeseries/camels/*.csv
# Outputs:
#   output_us/caravan_us_screen.csv
#
# This step only PROFILES candidates. It does not build rates or run the
# queue; that is the next script once ResOpsUS is unpacked.
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  suppressMessages(library(data.table))

  base <- "D:/Datasets/Caravan_2025"
  ha <- fread(file.path(base, "attributes", "camels",
                        "attributes_hydroatlas_camels.csv"))
  ot <- fread(file.path(base, "attributes", "camels",
                        "attributes_other_camels.csv"))

  ts_dir <- file.path(base, "timeseries", "camels")
  files <- list.files(ts_dir, pattern = "\\.csv$", full.names = TRUE)
  cat("profiling", length(files), "Caravan-US timeseries ...\n")

  prof <- rbindlist(lapply(files, function(f) {
    d <- tryCatch(fread(f, select = c("date", "streamflow"),
                        showProgress = FALSE),
                  error = function(e) NULL)
    if (is.null(d)) return(NULL)
    ok <- !is.na(d$streamflow)
    if (!any(ok)) {
      return(data.table(gauge_id = sub("\\.csv$", "", basename(f)),
                        ts_start = as.IDate(NA), ts_end = as.IDate(NA),
                        n_days = nrow(d), n_flow = 0L))
    }
    data.table(
      gauge_id = sub("\\.csv$", "", basename(f)),
      ts_start = min(d$date[ok]),
      ts_end = max(d$date[ok]),
      n_days = nrow(d),
      n_flow = sum(ok)
    )
  }), fill = TRUE)

  out <- merge(ot[, .(gauge_id, gauge_name, gauge_lat, gauge_lon, area)],
               ha, by = "gauge_id", all.x = TRUE)
  out <- merge(out, prof, by = "gauge_id", all.x = TRUE)

  # Queue-relevant flags (static):
  out[, irrigated := ire_pc_sse > 0]
  out[, regulated := dor_pc_pva > 0 | rev_mc_usu > 0]
  out[, cropped := crp_pc_sse > 0]
  out[, queue_candidate := irrigated & regulated]
  out[, flow_span_days := as.integer(ts_end - ts_start) + 1L]
  out[, flow_coverage := n_flow / pmax(flow_span_days, 1)]

  setorder(out, -queue_candidate, -irrigated, -regulated, -flow_coverage)
  fwrite(out, file.path(out_dir, "caravan_us_screen.csv"))

  cat(sprintf("total catchments: %d\n", nrow(out)))
  cat(sprintf("irrigated (>0): %d\n", sum(out$irrigated, na.rm = TRUE)))
  cat(sprintf("regulated/reservoir: %d\n", sum(out$regulated, na.rm = TRUE)))
  cat(sprintf("queue candidates (both): %d\n", sum(out$queue_candidate, na.rm = TRUE)))
  cat(sprintf("with >= 10 y flow and >= 0.8 coverage: %d\n",
              sum(out$n_flow >= 3650 & out$flow_coverage >= 0.8, na.rm = TRUE)))
  cat("\nqueue candidates:\n")
  print(out[queue_candidate == TRUE,
            .(gauge_id, gauge_name, area, ire_pc_sse, crp_pc_sse,
              dor_pc_pva, rev_mc_usu, ts_start, ts_end, flow_coverage)])
  cat("\nwrote", file.path(out_dir, "caravan_us_screen.csv"), "\n")
})
