# =====================================================================
# R/analysis/sensitivity_grid.R -- stage S8, predeclared one-factor-at-a-
# time sensitivity grid (plan section 3.8).
#
# Every axis level is run end to end around the baseline; results are
# reported regardless of direction (no selective reporting). Interactions
# are NOT swept (the plan's combinatorial guard).
#
# CONFIRMATORY STATISTIC. Delta_g = Brier_g(SSI-3) - Brier_g(SSI-3+queue)
# computed on the SAME held-out months for both families (paired). An
# unpaired comparison, where each family is scored on its own complete-case
# sample, is NOT the protocol's Delta_g and is never used here.
#
# Axes (baseline in brackets):
#   zero-flow variant [V1] : V0, V2
#   demand stage A f_irr [0.10] : 0.03, 0.25
#   supply variant [SUP-1] : SUP-2, SUP-3
#   intake cap mm/day [10] : 5, 20
#   q_days [60] : 45, 90
#   K_days [365] : 180
#   PET source [GLEAM] : Hargreaves
#   target [external SMA] : training-only SPI-3 (drop spi3 predictor)
#
# Outputs:
#   output/sensitivity_grid.csv  per gauge x config metrics + deltas
#   output/sensitivity_meta.csv  per config cross-gauge endpoint summary
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/analysis/sensitivity_grid.R")
  root <- normalizePath(file.path(dirname(script), "..", ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(QDJ_ROOT, "R", "00_utils", u))
  suppressMessages(library(data.table))
  ensure_dir(OUTPUT_DIR)

  quick <- "--quick" %in% commandArgs(trailingOnly = TRUE)

  # --- Load shared inputs once --------------------------------------
  flow <- load_flow()
  meta <- gauge_meta()
  recon <- fread(file.path(OUTPUT_DIR, "_recon_gauge_stats.csv"))
  strict <- recon[zero_frac < 0.3 & interior_gap <= 30]
  zero_audit <- stage2_zero_audit(flow, meta, strict$gauge_id)
  selected <- fread(file.path(OUTPUT_DIR, "selected_gauges.csv"))
  if ("in_endpoint" %in% names(selected)) {
    selected <- selected[in_endpoint == TRUE]
  }
  gids <- selected$gauge_id
  districts <- map_gauges_to_districts(meta[meta$gauge_id %in% gids])
  catchment_all <- stage3_catchment(gids, meta, districts)
  sma_long <- load_sma_long()
  cat(sprintf("sensitivity grid: %d gauges, %d basins\n",
              length(gids), uniqueN(selected$basin)))

  # --- Baseline configuration ---------------------------------------
  baseline <- list(
    zero = "V1", f_irr = P$f_irr, supply = "SUP-1", cap = P$cap_mm,
    q_days = P$q_days, K_days = P$K_days, pet = "GLEAM",
    target = "target_sma"
  )

  configs <- list(list(axis = "baseline", level = "baseline", cfg = baseline))
  add <- function(axis, level, ...) {
    cfg <- baseline
    changes <- list(...)
    for (nm in names(changes)) cfg[[nm]] <- changes[[nm]]
    configs[[length(configs) + 1]] <<- list(axis = axis, level = level, cfg = cfg)
  }
  add("zero_variant", "V0", zero = "V0")
  add("zero_variant", "V2", zero = "V2")
  add("demand_f_irr", "0.03", f_irr = 0.03)
  add("demand_f_irr", "0.25", f_irr = 0.25)
  add("supply_variant", "SUP-2", supply = "SUP-2")
  add("supply_variant", "SUP-3", supply = "SUP-3")
  add("intake_cap_mm", "5", cap = 5)
  add("intake_cap_mm", "20", cap = 20)
  add("q_days", "45", q_days = 45)
  add("q_days", "90", q_days = 90)
  add("K_days", "180", K_days = 180)
  add("pet_source", "Hargreaves", pet = "Hargreaves")
  add("target", "SPI3_training_only", target = "target_spi3")

  if (quick) configs <- configs[1:3]

  # --- One configuration --------------------------------------------
  # Returns per-gauge paired statistics and the pooled prediction table.
  run_config <- function(cfg) {
    rows <- vector("list", length(gids))
    preds <- vector("list", length(gids))
    for (i in seq_along(gids)) {
      g <- gids[i]
      # Recompute the catchment for THIS config: the command area depends on
      # f_irr, so reusing a single precomputed table would silently make the
      # demand_f_irr axis identical to baseline.
      cr <- stage3_catchment(g, meta, districts, f_irr = cfg$f_irr)
      if (nrow(cr) == 0) next
      rates <- stage3_rates(g, flow, cr, supply_variant = cfg$supply,
                            zero_variant = cfg$zero, pet_source = cfg$pet,
                            class_daily = zero_audit$daily, cap_mm = cfg$cap)
      qres <- stage5_queue(rates, q_days = cfg$q_days, K_days = cfg$K_days)
      ind <- stage6_indices(rates)
      des <- stage6_design(qres$monthly, ind, sma_long, cr$district_id)
      fit <- stage7_fit(des, cfg$target, "E1",
                        drop_spi3 = identical(cfg$target, "target_spi3"))
      if (!nrow(fit$predictions)) next
      pr_i <- cbind(gauge_id = g, fit$predictions)
      ps <- stage7_paired_stats(pr_i)
      ps[, `:=`(q_star = qres$meta$q_star, K = qres$meta$K,
                max_p_eq_K = qres$meta$max_p_eq_K)]
      rows[[i]] <- ps
      preds[[i]] <- pr_i
      if (!(i %% 8)) cat(sprintf("    gauge %d/%d\n", i, length(gids)))
    }
    d <- data.table::rbindlist(rows, fill = TRUE)
    pr <- data.table::rbindlist(preds, fill = TRUE)
    list(per_gauge = d, preds = pr)
  }

  # --- Loop ----------------------------------------------------------
  grid <- list(); meta_out <- list()
  t0 <- Sys.time()
  for (k in seq_along(configs)) {
    ax <- configs[[k]]$axis; lv <- configs[[k]]$level
    cat(sprintf("[%2d/%2d] %-16s %-18s ... ", k, length(configs), ax, lv))
    res <- run_config(configs[[k]]$cfg)
    d <- res$per_gauge
    d[, `:=`(axis = ax, level = lv)]
    grid[[k]] <- d

    ok <- d[is.finite(delta_brier)]
    per_g <- ok[, .(delta = mean(delta_brier)), by = gauge_id]
    boot <- stage7_paired_bootstrap(res$preds)
    st <- sign_test(per_g$delta)
    meta_out[[k]] <- data.table::data.table(
      axis = ax, level = lv, n_gauges = nrow(per_g),
      median_delta_brier = stats::median(per_g$delta),
      mean_delta_brier = mean(per_g$delta),
      boot_lo = boot["lo"], boot_hi = boot["hi"],
      sign_k = st$k, sign_n = st$n, sign_p = st$p,
      median_delta_auc = stats::median(ok$delta_auc, na.rm = TRUE),
      auc_improved = sum(ok$delta_auc > 0, na.rm = TRUE),
      harm_count = sum(per_g$delta < -0.005),
      max_p_eq_K = max(d$max_p_eq_K, na.rm = TRUE)
    )
    cat(sprintf("median dBrier=%+.5f  med dAUC=%+.4f  sign %d/%d\n",
                meta_out[[k]]$median_delta_brier,
                meta_out[[k]]$median_delta_auc,
                meta_out[[k]]$sign_k, meta_out[[k]]$sign_n))
  }

  grid_tab <- data.table::rbindlist(grid, fill = TRUE)
  meta_tab <- data.table::rbindlist(meta_out, fill = TRUE)
  write_csv_sidecar(grid_tab, file.path(OUTPUT_DIR, "sensitivity_grid.csv"),
                    list(stage = "S8", seed = P$seed))
  write_csv_sidecar(meta_tab, file.path(OUTPUT_DIR, "sensitivity_meta.csv"),
                    list(stage = "S8", seed = P$seed))
  cat(sprintf("\n=== S8 done in %.1f min ===\n",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  print(meta_tab)
})
