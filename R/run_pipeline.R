# =====================================================================
# R/run_pipeline.R -- end-to-end execution of stages S2-S7.
#
# Usage (from the project root):
#   Rscript R/run_pipeline.R
#
# Produces, under output/:
#   inventory.csv                 per-gauge coverage/gap/zero inventory
#   zero_audit_summary.csv        per-gauge zero classification counts
#   screen_report.csv             utilization rho per gauge x supply variant
#   catchment_table.csv           command area + district + provenance
#   selected_gauges.csv           the analysis set with inclusion reasons
#   queue_meta.csv                thresholds and blocking diagnostics
#   metrics_e1.csv, metrics_e2.csv   per-gauge per-family held-out metrics
#   predictions_e1.csv, predictions_e2.csv
#   delta_e1.csv, delta_e2.csv    per-gauge Brier deltas (primary contrast)
#   meta_e1.csv, meta_e2.csv      cross-gauge endpoint summaries
#   sensitivity_strict_e1.csv     leakage-clean target sensitivity
#
# Every output is written with a JSON sidecar (git hash, params, seed).
# =====================================================================

local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/run_pipeline.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) {
    source(file.path(QDJ_ROOT, "R", "00_utils", u))
  }
  suppressMessages(library(data.table))
  ensure_dir(OUTPUT_DIR)

  t_start <- Sys.time()
  cat("=== S2: load and inventory ===\n")
  flow <- load_flow()
  meta <- gauge_meta()
  cat(sprintf("flow: %d days x %d gauges\n", nrow(flow), ncol(flow) - 1))

  # ---- S2 inventory ---------------------------------------------------
  inventory <- stage2_inventory(flow, meta)
  write_csv_sidecar(inventory, file.path(OUTPUT_DIR, "inventory.csv"),
                    list(stage = "S2", seed = P$seed))
  cat(sprintf("inventory: %d gauges\n", nrow(inventory)))

  # ---- S2 zero audit (candidate gauges only, for speed) --------------
  recon_path <- file.path(OUTPUT_DIR, "_recon_gauge_stats.csv")
  if (!file.exists(recon_path)) {
    stop("Missing recon screen; run the reconnaissance step first.")
  }
  recon <- data.table::fread(recon_path)
  strict <- recon[in_window == TRUE & zero_frac < 0.3 & interior_gap <= 30]
  cat(sprintf("strict-pass candidates: %d\n", nrow(strict)))
  zero_audit <- stage2_zero_audit(flow, meta, strict$gauge_id)
  write_csv_sidecar(zero_audit$summary,
                    file.path(OUTPUT_DIR, "zero_audit_summary.csv"),
                    list(stage = "S2", seed = P$seed))

  # ---- S3 selection: strict screen + both-period coverage + 3/basin --
  train_start <- as.Date("1981-01-01"); train_end <- as.Date("2010-12-31")
  test_start  <- as.Date("2011-01-01"); test_end  <- as.Date("2020-12-31")
  strict[, n_train := vapply(gauge_id, function(g) {
    x <- flow[[as.character(g)]]
    sum(!is.na(x[flow$date >= train_start & flow$date <= train_end]))
  }, integer(1))]
  strict[, n_test := vapply(gauge_id, function(g) {
    x <- flow[[as.character(g)]]
    sum(!is.na(x[flow$date >= test_start & flow$date <= test_end]))
  }, integer(1))]
  strict[, period_ok := n_train >= 1095 & n_test >= 730]
  cand <- strict[period_ok == TRUE]
  cand[, coverage_rank := pmin(n_train, n_test)]
  data.table::setorder(cand, basin, -coverage_rank)
  cand[, rank_in_basin := seq_len(.N), by = basin]
  selected <- cand[rank_in_basin <= 3]
  selected[, include_reason := "strict screen + both-period coverage + <=3/basin"]
  write_csv_sidecar(selected[, .(gauge_id, basin, area_km2, zero_frac,
                                 interior_gap, rho, n_train, n_test,
                                 include_reason)],
                    file.path(OUTPUT_DIR, "selected_gauges.csv"),
                    list(stage = "S3", seed = P$seed))
  cat(sprintf("selected gauges: %d across %d basins\n",
              nrow(selected), data.table::uniqueN(selected$basin)))

  # ---- S3 district mapping and catchment table ------------------------
  districts <- map_gauges_to_districts(meta)
  catch <- stage3_catchment(selected$gauge_id, meta, districts)
  write_csv_sidecar(catch, file.path(OUTPUT_DIR, "catchment_table.csv"),
                    list(stage = "S3", seed = P$seed))

  # ---- S3 utilization screen (all candidates) -------------------------
  screen <- data.table::rbindlist(lapply(strict$gauge_id, function(g) {
    cr <- catch[gauge_id == g]
    if (nrow(cr) == 0) {
      cr <- stage3_catchment(g, meta, districts)
    }
    stage3_screen(g, flow, cr, zero_audit$daily)
  }))
  write_csv_sidecar(screen, file.path(OUTPUT_DIR, "screen_report.csv"),
                    list(stage = "S3", seed = P$seed))

  # ---- S5-S7 per gauge -----------------------------------------------
  sma_long <- load_sma_long()
  queue_meta <- list(); metrics_e1 <- list(); metrics_e2 <- list()
  preds_e1 <- list(); preds_e2 <- list(); sens_strict <- list()
  design_audit <- list()
  cat("=== S5-S7: queue, indices, design, fit ===\n")
  for (i in seq_len(nrow(selected))) {
    g <- selected$gauge_id[i]
    cr <- catch[gauge_id == g]
    rates <- stage3_rates(g, flow, cr, supply_variant = "SUP-1",
                          zero_variant = "V1", pet_source = "GLEAM",
                          class_daily = zero_audit$daily)
    qres <- stage5_queue(rates)
    queue_meta[[i]] <- data.table::as.data.table(qres$meta)
    ind <- stage6_indices(rates)
    des <- stage6_design(qres$monthly, ind, sma_long, cr$district_id)

    # Target and design audit: event counts per split and predictor
    # availability. This is the leakage-audit evidence table (S6).
    design_audit[[i]] <- data.table::data.table(
      gauge_id = g,
      n_train = sum(des$train), n_test = sum(des$test),
      events_sma_train = sum(des$target_sma[des$train], na.rm = TRUE),
      events_sma_test = sum(des$target_sma[des$test], na.rm = TRUE),
      events_spi3_train = sum(des$target_spi3[des$train], na.rm = TRUE),
      events_spi3_test = sum(des$target_spi3[des$test], na.rm = TRUE),
      n_spi3_finite = sum(is.finite(des$spi3)),
      n_ssi3_finite = sum(is.finite(des$ssi3)),
      n_spei3_finite = sum(is.finite(des$spei3)),
      n_queue_finite = sum(is.finite(des$mean_p_ge_q)),
      target_definition = "district SMA <= -15% (external product, leakage disclosed)"
    )

    fit1 <- stage7_fit(des, "target_sma", "E1")
    fit2 <- stage7_fit(des, "target_sma", "E2")
    metrics_e1[[i]] <- cbind(gauge_id = g, fit1$metrics)
    metrics_e2[[i]] <- cbind(gauge_id = g, fit2$metrics)
    if (nrow(fit1$predictions)) preds_e1[[i]] <- cbind(gauge_id = g, fit1$predictions)
    if (nrow(fit2$predictions)) preds_e2[[i]] <- cbind(gauge_id = g, fit2$predictions)

    # Leakage-clean target sensitivity: training-only SPI-3 target, drop spi3.
    fs <- stage7_fit(des, "target_spi3", "E1", drop_spi3 = TRUE)
    sens_strict[[i]] <- cbind(gauge_id = g, fs$metrics)

    cat(sprintf("  [%2d/%2d] gauge %5d  q*=%d K=%d  E1 ssi3 Brier=%.4f ssi3+q=%.4f\n",
                i, nrow(selected), g, qres$meta$q_star, qres$meta$K,
                fit1$metrics[family == "ssi3", brier],
                fit1$metrics[family == "ssi3_plus_queue", brier]))
  }

  # ---- Write per-gauge tables ----------------------------------------
  qm <- data.table::rbindlist(queue_meta, fill = TRUE)
  write_csv_sidecar(qm, file.path(OUTPUT_DIR, "queue_meta.csv"),
                    list(stage = "S5", seed = P$seed))
  m1 <- data.table::rbindlist(metrics_e1, fill = TRUE)
  m2 <- data.table::rbindlist(metrics_e2, fill = TRUE)
  write_csv_sidecar(m1, file.path(OUTPUT_DIR, "metrics_e1.csv"),
                    list(stage = "S7", seed = P$seed))
  write_csv_sidecar(m2, file.path(OUTPUT_DIR, "metrics_e2.csv"),
                    list(stage = "S7", seed = P$seed))
  p1 <- data.table::rbindlist(preds_e1, fill = TRUE)
  p2 <- data.table::rbindlist(preds_e2, fill = TRUE)
  write_csv_sidecar(p1, file.path(OUTPUT_DIR, "predictions_e1.csv"),
                    list(stage = "S7", seed = P$seed))
  write_csv_sidecar(p2, file.path(OUTPUT_DIR, "predictions_e2.csv"),
                    list(stage = "S7", seed = P$seed))
  ss <- data.table::rbindlist(sens_strict, fill = TRUE)
  write_csv_sidecar(ss, file.path(OUTPUT_DIR, "sensitivity_strict_e1.csv"),
                    list(stage = "S7", seed = P$seed))
  da <- data.table::rbindlist(design_audit, fill = TRUE)
  write_csv_sidecar(da, file.path(OUTPUT_DIR, "design_audit.csv"),
                    list(stage = "S6", seed = P$seed))

  # ---- S7 meta endpoints ---------------------------------------------
  # CONFIRMATORY STATISTIC: Delta_g is the PAIRED gauge-level Brier
  # difference on identical held-out months (pipeline.R: stage7_paired_stats,
  # stage7_paired_bootstrap). The per-gauge-year file is kept only for the
  # descriptive forest plot.
  cat("=== S7: meta endpoints ===\n")
  meta_out <- list()
  for (ep in c("E1", "E2")) {
    pr <- if (ep == "E1") p1 else p2
    d <- stage7_deltas(pr, c("ssi3", "ssi3_plus_queue"))
    write_csv_sidecar(d, file.path(OUTPUT_DIR, sprintf("delta_%s.csv", tolower(ep))),
                      list(stage = "S7", endpoint = ep, seed = P$seed))
    ps <- stage7_paired_stats(pr, "ssi3", "ssi3_plus_queue")
    write_csv_sidecar(ps, file.path(OUTPUT_DIR, sprintf("paired_%s.csv", tolower(ep))),
                      list(stage = "S7", endpoint = ep, seed = P$seed))
    boot <- stage7_paired_bootstrap(pr, "ssi3", "ssi3_plus_queue")
    st <- sign_test(ps$delta_brier)
    meta_out[[ep]] <- data.table::data.table(
      endpoint = ep,
      n_gauges = nrow(ps),
      median_delta = stats::median(ps$delta_brier, na.rm = TRUE),
      mean_delta = mean(ps$delta_brier, na.rm = TRUE),
      boot_lo = boot["lo"],
      boot_hi = boot["hi"],
      sign_n = st$n,
      sign_k = st$k,
      sign_p = st$p,
      sign_share = st$share,
      harm_count = sum(ps$delta_brier < -0.005, na.rm = TRUE),
      median_delta_auc = stats::median(ps$delta_auc, na.rm = TRUE),
      auc_improved = sum(ps$delta_auc > 0, na.rm = TRUE)
    )
    # Secondary contrast: spei3 vs spei3+queue (same paired treatment)
    ps2 <- stage7_paired_stats(pr, "spei3", "spei3_plus_queue")
    boot2 <- stage7_paired_bootstrap(pr, "spei3", "spei3_plus_queue")
    st2 <- sign_test(ps2$delta_brier)
    meta_out[[paste0(ep, "_spei")]] <- data.table::data.table(
      endpoint = paste0(ep, "_spei3_contrast"),
      n_gauges = nrow(ps2),
      median_delta = stats::median(ps2$delta_brier, na.rm = TRUE),
      mean_delta = mean(ps2$delta_brier, na.rm = TRUE),
      boot_lo = boot2["lo"],
      boot_hi = boot2["hi"],
      sign_n = st2$n,
      sign_k = st2$k,
      sign_p = st2$p,
      sign_share = st2$share,
      harm_count = sum(ps2$delta_brier < -0.005, na.rm = TRUE),
      median_delta_auc = stats::median(ps2$delta_auc, na.rm = TRUE),
      auc_improved = sum(ps2$delta_auc > 0, na.rm = TRUE)
    )
  }
  meta_tab <- data.table::rbindlist(meta_out, fill = TRUE)
  write_csv_sidecar(meta_tab, file.path(OUTPUT_DIR, "meta_endpoints.csv"),
                    list(stage = "S7", seed = P$seed))
  print(meta_tab)

  cat(sprintf("=== done in %.1f min ===\n",
              as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
})
