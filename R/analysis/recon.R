# =====================================================================
# R/analysis/recon.R -- one-time gauge profiling table (reconnaissance).
#
# Produces output/_recon_gauge_stats.csv, which R/run_pipeline.R consumes to
# shortlist strict-screen candidates. This is a PROFILING step, not a
# manuscript result: the authoritative utilisation screen is recomputed by
# run_pipeline.R for the shortlisted gauges, with the zero audit applied.
#
# SAFETY: by default this refuses to overwrite an existing profiling table,
# because the committed table defines the frozen analysis set. Pass --force
# to regenerate it; if you do, check output/selected_gauges.csv afterwards
# and record any change in protocol/CHANGELOG.md before quoting new results.
#
# Usage:
#   Rscript R/analysis/recon.R            # no-op if the table exists
#   Rscript R/analysis/recon.R --force    # regenerate
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/analysis/recon.R")
  root <- normalizePath(file.path(dirname(script), "..", ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(QDJ_ROOT, "R", "00_utils", u))
  suppressMessages(library(data.table))
  ensure_dir(OUTPUT_DIR)

  out_path <- file.path(OUTPUT_DIR, "_recon_gauge_stats.csv")
  force <- "--force" %in% commandArgs(trailingOnly = TRUE)
  if (file.exists(out_path) && !force) {
    cat("Profiling table already exists:", out_path, "\n")
    cat("Use --force to regenerate (and re-check the selected set).\n")
    return(invisible(NULL))
  }

  flow <- load_flow()
  meta <- gauge_meta()
  districts <- map_gauges_to_districts(meta)
  gauges <- meta$gauge_id

  interior_gap <- function(x) {
    ok <- which(!is.na(x))
    if (length(ok) < 2) return(NA_integer_)
    r <- rle(is.na(x[min(ok):max(ok)]))
    if (!any(r$values)) 0L else max(r$lengths[r$values])
  }

  rows <- vector("list", length(gauges))
  for (k in seq_along(gauges)) {
    g <- gauges[k]
    f <- .read_forcing_one(g)
    if (is.null(f)) next
    q <- flow[[as.character(g)]]
    if (is.null(q) || sum(!is.na(q)) < 300) next
    cr <- stage3_catchment(g, meta, districts)
    if (nrow(cr) == 0) next
    rates <- stage3_rates(g, flow, cr, class_daily = NULL)
    ok <- !rates$missing_day
    if (sum(ok) < 300) next
    rho <- sum(rates$lambda[ok]) / sum(rates$mu[ok])
    rows[[k]] <- data.table::data.table(
      gauge_id = g,
      basin = cr$basin[1],
      area_km2 = cr$area_km2[1],
      n_obs = sum(!is.na(q)),
      zero_frac = mean(q == 0, na.rm = TRUE),
      interior_gap = interior_gap(q),
      mean_q = mean(q, na.rm = TRUE),
      mean_lam = mean(rates$lambda[ok]),
      mean_mu = mean(rates$mu[ok]),
      rho = rho,
      in_window = rho >= P$rho_window[1] && rho <= P$rho_window[2]
    )
    if (!(k %% 50)) cat(sprintf("  profiled %d/%d gauges\n", k, length(gauges)))
  }

  recon <- data.table::rbindlist(rows, fill = TRUE)
  write_csv_sidecar(recon, out_path, list(stage = "recon", seed = P$seed))
  cat(sprintf("wrote %s: %d profiled gauges, %d in window\n",
              out_path, nrow(recon), sum(recon$in_window)))
})
