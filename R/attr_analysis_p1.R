# =====================================================================
# R/attr_analysis_p1.R -- do catchment attributes help, and where?
#
# Three questions, three analyses:
#
#   1. WITHIN a gauge, an attribute is a constant column. Standardising it
#      on training rows makes it all zeros, so a per-gauge model cannot use
#      it. This script does not re-derive that; it states it and moves on.
#      (The storage family already carries k_days, BFI and S_cap as
#      constant features; they can only act through the intercept.)
#
#   2. BETWEEN gauges, attributes explain WHERE the forecast has skill.
#      We relate per-gauge skill (BSS of the best baseline, and the paired
#      storage gain) to area, climate, topography, soil, geology and
#      land-use attributes with Spearman correlations and a standardised
#      linear model, with Benjamini-Hochberg control across attributes.
#
#   3. BY BASIN, the same question at the scale an operator sees. We report
#      median skill and median attributes per river basin, for basins with
#      at least five scored catchments.
#
# Inputs : paper01/output/p1_bss_paired.csv, p1_storage_params.csv,
#          CAMELS-IND attributes_csv (paths from R/config.R)
# Outputs: paper01/output/p1_attr_merge.csv
#          paper01/output/p1_attr_cor.csv
#          paper01/output/p1_attr_lm.csv
#          paper01/output/p1_basin_attr.csv
#          paper01/figures/fig_p1_attr_cor.{pdf,png}
#          paper01/figures/fig_p1_attr_scatter.{pdf,png}
#          paper01/figures/fig_p1_basin_skill.{pdf,png}
#
# Usage  : Rscript R/attr_analysis_p1.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/attr_analysis_p1.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "eval.R", "io.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages({ library(data.table); library(ggplot2) })
  ensure_dir(FIG_DIR)

  pal <- list(blue = "#2C6FBB", orange = "#D1603D", red = "#B23A48",
              purple = "#8C6BB1", green = "#41AB5D", grey = "#6B6B6B")
  th <- theme_minimal(base_size = 9) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 10),
          plot.subtitle = element_text(colour = pal$grey, size = 8),
          legend.position = "bottom")
  save_fig <- function(p, name, w, h) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h,
           dpi = 300)
  }

  # ---- gather attributes ----------------------------------------------
  attr_files <- c(anth = "camels_ind_anth.csv", clim = "camels_ind_clim.csv",
                  geol = "camels_ind_geol.csv", hydro = "camels_ind_hydro.csv",
                  land = "camels_ind_land.csv", soil = "camels_ind_soil.csv",
                  topo = "camels_ind_topo.csv")
  keep <- list(
    anth  = c("irrigation_frac", "crops_frac", "urban_frac_2005",
              "pop_density_2010", "reservoir_index"),
    clim  = c("p_mean", "pet_mean", "aridity_p_pet", "p_monthly_variability",
              "sm_lvl1_mean"),
    geol  = c("geol_porosity", "geol_permeability", "carb_rocks_frac"),
    hydro = c("bfi", "q_zero", "runoff_ratio", "slope_fdc", "q_cv"),
    land  = c("trees_frac", "crops_frac", "lai_mean", "bare_frac"),
    soil  = c("soil_depth", "soil_awc_top", "sand_frac_top", "clay_frac_top"),
    topo  = c("cwc_area", "elev_mean", "slope_mean")
  )
  att <- NULL
  for (nm in names(attr_files)) {
    p <- file.path(CAMELS_ATTR_DIR, attr_files[[nm]])
    if (!file.exists(p)) {
      cat("  attribute file missing:", p, "\n"); next
    }
    d <- fread(p, showProgress = FALSE)
    cols <- intersect(c("gauge_id", keep[[nm]]), names(d))
    d <- d[, cols, with = FALSE]
    # crops_frac appears in anth and land; keep the land-cover version only.
    if (nm == "land" && "crops_frac" %in% names(att)) {
      d[, crops_frac := NULL]
    }
    att <- if (is.null(att)) d else merge(att, d, by = "gauge_id", all = TRUE)
  }
  att[, gauge_id := as.character(gauge_id)]

  # ---- per-gauge skill -------------------------------------------------
  bp <- fread(file.path(OUTPUT_DIR, "p1_bss_paired.csv"))
  prm <- fread(file.path(OUTPUT_DIR, "p1_storage_params.csv"))
  bp[, gauge_id := as.character(gauge_id)]
  prm[, gauge_id := as.character(gauge_id)]
  att[, gauge_id := as.character(gauge_id)]
  bp <- bp[region == "India" & target == "t1"]

  # one column per family x lead; the cast is on (gauge_id) only, so the
  # lead must stay in the value name rather than in the cast formula.
  dat <- unique(bp[, .(gauge_id)])
  for (fam in c("persistence", "lagged_indices", "storage_plus_indices")) {
    for (h in c(1, 3)) {
      d <- bp[family == fam & lead == h, .(gauge_id, bss)]
      setnames(d, "bss", paste0(fam, "_", h))
      dat <- merge(dat, d, by = "gauge_id", all.x = TRUE)
    }
  }
  dat[, delta3 := storage_plus_indices_3 - lagged_indices_3]
  dat <- merge(dat, prm[, .(gauge_id, basin, k_days, S_cap_mm, BFI, zero_frac)],
               by = "gauge_id", all.x = TRUE)
  dat <- merge(dat, att, by = "gauge_id", all.x = TRUE)

  # metrics to explain
  metrics <- c(bss_lag3 = "bss_lag3", bss_pers1 = "bss_pers1",
               delta3 = "delta3")
  dat[, bss_lag3 := lagged_indices_3]
  dat[, bss_pers1 := persistence_1]
  dat[, bss_lag1 := lagged_indices_1]

  # ---- 1. correlations -------------------------------------------------
  attr_names <- setdiff(names(att), "gauge_id")
  attr_names <- c(attr_names, c("k_days", "S_cap_mm", "BFI", "zero_frac"))
  cor_rows <- list()
  for (m in c("bss_lag3", "bss_pers1", "delta3")) {
    for (a in attr_names) {
      ok <- is.finite(dat[[m]]) & is.finite(dat[[a]])
      if (sum(ok) < 50) next
      ct <- suppressWarnings(stats::cor.test(dat[[a]][ok], dat[[m]][ok],
                                             method = "spearman",
                                             exact = FALSE))
      cor_rows[[length(cor_rows) + 1L]] <- data.table(
        metric = m, attribute = a, n = sum(ok),
        rho = unname(ct$estimate), p = ct$p.value)
    }
  }
  cors <- rbindlist(cor_rows)
  cors[, p_adj := stats::p.adjust(p, method = "BH"), by = metric]
  cors[, source := fifelse(attribute %in% c("k_days", "S_cap_mm", "BFI",
                                            "zero_frac"),
                           "fitted / observed", "dataset attribute")]

  # ---- 2. standardised linear model ------------------------------------
  # Greedy de-collinearity: keep attributes with |rho| < 0.7 against those
  # already in the model, so the coefficients are interpretable.
  lm_rows <- list()
  for (m in c("bss_lag3", "delta3")) {
    cand <- unique(cors[metric == m & p_adj < 0.25, attribute])
    cand <- cand[vapply(cand, function(a) sum(is.finite(dat[[a]])) > 0.8 * nrow(dat), logical(1))]
    chosen <- character(0)
    for (a in cand) {
      if (!length(chosen)) { chosen <- a; next }
      X <- as.matrix(dat[, c(a, chosen), with = FALSE])
      r <- suppressWarnings(max(abs(stats::cor(X, use = "pairwise.complete.obs",
                                               method = "spearman")[a, chosen]),
                                na.rm = TRUE))
      if (is.finite(r) && r < 0.7) chosen <- c(chosen, a)
    }
    if (!length(chosen)) next
    z <- dat[stats::complete.cases(dat[, c(m, chosen), with = FALSE])]
    if (nrow(z) < 50) next
    X <- as.data.frame(z[, chosen, with = FALSE])
    X[] <- lapply(X, function(v) as.numeric(scale(v)))
    y <- as.numeric(scale(z[[m]]))
    fit <- stats::lm(y ~ ., data = X)
    cf <- summary(fit)$coefficients
    lm_rows[[length(lm_rows) + 1L]] <- data.table(
      metric = m, term = rownames(cf), std_beta = cf[, 1], se = cf[, 2],
      p = cf[, 4], r2 = summary(fit)$r.squared, n = nrow(z))
  }
  lms <- rbindlist(lm_rows, fill = TRUE)

  # ---- 3. basin summary ------------------------------------------------
  basin <- dat[!is.na(basin), .(
    n = .N,
    bss_lag1 = stats::median(bss_lag1, na.rm = TRUE),
    bss_lag3 = stats::median(bss_lag3, na.rm = TRUE),
    bss_pers1 = stats::median(bss_pers1, na.rm = TRUE),
    delta3 = stats::median(delta3, na.rm = TRUE),
    area_km2 = stats::median(cwc_area, na.rm = TRUE),
    aridity = stats::median(aridity_p_pet, na.rm = TRUE),
    bfi = stats::median(bfi, na.rm = TRUE),
    k_days = stats::median(k_days, na.rm = TRUE),
    zero_frac = stats::median(zero_frac, na.rm = TRUE),
    irr_frac = stats::median(irrigation_frac, na.rm = TRUE)
  ), by = basin][n >= 5][order(-bss_lag3)]

  write_csv_sidecar(dat, file.path(OUTPUT_DIR, "p1_attr_merge.csv"))
  write_csv_sidecar(cors, file.path(OUTPUT_DIR, "p1_attr_cor.csv"))
  write_csv_sidecar(lms, file.path(OUTPUT_DIR, "p1_attr_lm.csv"))
  write_csv_sidecar(basin, file.path(OUTPUT_DIR, "p1_basin_attr.csv"))

  # ---- figures ---------------------------------------------------------
  # (a) correlation dot plot for two metrics, one panel (dumbbell)
  cd <- cors[metric %in% c("bss_lag3", "delta3") & is.finite(rho)]
  cd[, metric := factor(metric, levels = c("bss_lag3", "delta3"),
                        labels = c("skill of lagged indices",
                                   "storage gain over lagged indices"))]
  ord <- cd[metric == levels(metric)[1]][order(rho)][, attribute]
  cd[, attribute := factor(attribute, levels = ord)]
  w <- dcast(cd, attribute ~ metric, value.var = "rho")
  p_cor <- ggplot(cd, aes(rho, attribute)) +
    geom_vline(xintercept = 0, colour = pal$grey, linewidth = 0.35) +
    geom_segment(data = w, aes(x = `storage gain over lagged indices`,
                               xend = `skill of lagged indices`,
                               y = attribute, yend = attribute),
                 colour = "grey85", linewidth = 0.7) +
    geom_point(aes(colour = metric, shape = p_adj < 0.05), size = 2.2) +
    scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16),
                       labels = c("not significant", "BH p < 0.05"),
                       name = NULL) +
    scale_colour_manual(values = c(pal$blue, pal$red), name = NULL) +
    labs(x = "Spearman rho with the attribute (3-month lead)", y = NULL,
         title = "Attributes explain where skill lives, not what the state adds",
         subtitle = "India, T1, about 130 gauges; filled = BH-adjusted p < 0.05; both at the 3-month lead") +
    th + theme(axis.text.y = element_text(size = 7))
  save_fig(p_cor, "fig_p1_attr_cor", 7.4, 6.2)

  # (b) scatter grid of skill against six attributes
  dat[, log_area := log10(cwc_area)]
  sc <- c("log_area", "aridity_p_pet", "bfi", "k_days", "zero_frac",
          "irrigation_frac")
  lab <- c(log_area = "area (km2, log)", aridity_p_pet = "aridity (P/PET)",
           bfi = "baseflow index", k_days = "recession constant k (d)",
           zero_frac = "zero-flow fraction",
           irrigation_frac = "irrigated fraction")
  long <- melt(dat[stats::complete.cases(dat[, c("bss_lag3", sc), with = FALSE])],
               id.vars = "bss_lag3", measure.vars = sc,
               variable.name = "attribute", value.name = "value")
  long[, attribute := factor(attribute, levels = sc, labels = lab[sc])]
  p_sc <- ggplot(long, aes(value, bss_lag3)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = pal$grey,
               linewidth = 0.3) +
    geom_point(colour = pal$blue, alpha = 0.45, size = 0.9) +
    geom_smooth(method = "loess", formula = y ~ x, se = TRUE,
                colour = pal$red, fill = pal$red, alpha = 0.12,
                linewidth = 0.6) +
    coord_cartesian(ylim = c(-0.35, 0.7)) +
    facet_wrap(~attribute, ncol = 3, scales = "free_x") +
    labs(x = NULL, y = "BSS of lagged indices, 3-month lead",
         title = "Where the forecast works",
         subtitle = paste0("Per gauge; red = LOESS with 95% band; ",
                           "y clipped at -0.35 to 0.7 (a few gauges lie outside)")) +
    th
  save_fig(p_sc, "fig_p1_attr_scatter", 8.6, 5.2)

  # (c) basin dot plot
  bs <- basin[!is.na(bss_lag3)]
  bs[, basin := factor(basin, levels = bs[order(bss_lag3), basin])]
  p_bs <- ggplot(bs, aes(bss_lag3, basin)) +
    geom_vline(xintercept = 0, colour = pal$grey, linewidth = 0.35) +
    geom_segment(aes(x = 0, xend = bss_lag3, yend = basin),
                 colour = "grey80", linewidth = 0.5) +
    geom_point(aes(size = n), colour = pal$blue) +
    scale_size_continuous(name = "catchments", range = c(1.2, 4)) +
    labs(x = "median BSS of lagged indices (3-month lead)", y = NULL,
         title = "Basin by basin: the skill is real but small",
         subtitle = "Basins with at least five scored catchments; median on identical months") +
    th
  save_fig(p_bs, "fig_p1_basin_skill", 7.2, 5.2)

  cat("\n=== top attribute associations with baseline skill (3 mo) ===\n")
  print(head(cors[metric == "bss_lag3"][order(-abs(rho)),
                                        .(attribute, n, rho = round(rho, 3),
                                          p_adj = signif(p_adj, 2))], 8))
  cat("\n=== top associations with the storage gain (3 mo) ===\n")
  print(head(cors[metric == "delta3"][order(-abs(rho)),
                                      .(attribute, n, rho = round(rho, 3),
                                        p_adj = signif(p_adj, 2))], 8))
  cat("\n=== standardised models ===\n")
  print(lms[, .(metric, term, std_beta = round(std_beta, 3),
                p = signif(p, 2), r2 = round(r2, 3))])
  cat("\nattr_analysis_p1.R complete\n")
})
