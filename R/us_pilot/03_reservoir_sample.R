# =====================================================================
# R/us_pilot/03_reservoir_sample.R -- build the reservoir-centric pilot
# sample: reservoirs with a usable outflow record and a nearby irrigated
# Caravan catchment.
#
# Unit of analysis = the reservoir (not the CAMELS gauge). The CAMELS
# catchment is used only to supply an irrigated-area context and a
# representative ET point.
#
# Inputs:
#   output_us/resops_caravan_match.csv
#   D:/Datasets/ResOpsUS/extracted/ResOpsUS/attributes/time_series_inventory.csv
#   D:/Datasets/ResOpsUS/extracted/ResOpsUS/time_series_all/ResOpsUS_<DAM_ID>.csv
# Output:
#   output_us/reservoir_core.csv
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  out_dir <- file.path(root, "output_us")
  suppressMessages(library(data.table))

  m <- fread(file.path(out_dir, "resops_caravan_match.csv"))
  inv <- fread("D:/Datasets/ResOpsUS/extracted/ResOpsUS/attributes/time_series_inventory.csv")
  x <- merge(m, inv[, .(DAM_ID, OUTFLOW, OUTFLOW_START, OUTFLOW_END)],
             by = "DAM_ID", all.x = TRUE)

  core <- x[OUTFLOW == 1 & !is.na(ire_pc_sse) & ire_pc_sse > 0 &
              dist_nearest_km <= 20]
  core[, A_cmd_m2 := (ire_pc_sse / 100) * area * 1e6]
  core[, V_claim_m3 := (20 / 1000) * A_cmd_m2]

  ts_dir <- "D:/Datasets/ResOpsUS/extracted/ResOpsUS/time_series_all"
  core[, max_storage_MCM := NA_real_]
  core[, n_storage := NA_integer_]
  for (i in seq_len(nrow(core))) {
    f <- file.path(ts_dir, sprintf("ResOpsUS_%d.csv", core$DAM_ID[i]))
    if (!file.exists(f)) next
    d <- tryCatch(fread(f, select = c("date", "storage"),
                        showProgress = FALSE), error = function(e) NULL)
    if (is.null(d) || !nrow(d)) next
    if (all(is.na(d$storage))) next
    core$max_storage_MCM[i] <- max(d$storage, na.rm = TRUE)
    core$n_storage[i] <- sum(!is.na(d$storage))
  }
  core[, storage_years := n_storage / 365.25]

  setorder(core, -ire_pc_sse)
  fwrite(core, file.path(out_dir, "reservoir_core.csv"))

  cat("core reservoirs (outflow + ire>0 + <=20 km):", nrow(core), "\n")
  cat("  with a storage series:", sum(!is.na(core$max_storage_MCM)), "\n")
  cat("  with >=10 y storage:", sum(core$storage_years >= 10, na.rm = TRUE), "\n")
  cat("  states:", uniqueN(core$STATE), "\n")
  print(core[order(-ire_pc_sse)][1:20,
        .(DAM_ID, DAM_NAME, STATE, matched_gauge,
          ire_pc_sse = round(ire_pc_sse, 2), area_km2 = round(area, 0),
          A_cmd_km2 = round(A_cmd_m2 / 1e6, 1),
          max_storage_MCM = round(max_storage_MCM, 0),
          dist_km = round(dist_nearest_km, 1))])
  cat("\nwrote", file.path(out_dir, "reservoir_core.csv"), "\n")
})
