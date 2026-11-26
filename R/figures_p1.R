# =====================================================================
# R/figures_p1.R -- figures for Study P1.
#
# Reads only output/*.csv written by R/study_p1.R (plus, for the example
# catchment panel, a recomputation of the one-gauge fluid state through
# the verified engine). Nothing is hand-edited. Writes PDF + 300-dpi PNG
# to figures/.
#
# Figures:
#   fig_p1_map       : the screened sample across India by screen stage
#   fig_p1_leadtime  : CENTREPIECE -- median BSS vs lead for every family
#   fig_p1_paired    : per-gauge paired deltas (frozen best-of contrast)
#   fig_p1_storage   : recession/storage landscape across the sample
#   fig_p1_state     : the fluid state S(t) for one example catchment
#   fig_p1_reliability: pooled reliability curves (needs predictions CSV)
#
# Usage:  Rscript R/figures_p1.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/figures_p1.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "storage_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages({
    library(data.table)
    library(ggplot2)
  })
  ensure_dir(FIG_DIR)

  blue <- "#2c6fbb"; orange <- "#d1603d"; green <- "#2e8b57"
  grey <- "#666666"; red <- "#b23a48"
  fam_cols <- c(climatology = grey, persistence = "#8c6bb1",
                lagged_indices = blue, api = "#41ab5d",
                storage = orange, storage_plus_indices = red)

  save_fig <- function(p, name, w, h) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h,
           dpi = 300)
  }

  base_theme <- theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 11),
          plot.subtitle = element_text(colour = grey, size = 9),
          legend.position = "bottom")

  rd <- function(f) {
    p <- file.path(OUTPUT_DIR, f)
    if (!file.exists(p)) return(NULL)
    fread(p)
  }

  scr <- rd("p1_sample_report.csv")
  params <- rd("p1_storage_params.csv")
  bss <- rd("p1_bss.csv")
  paired <- rd("p1_paired.csv")
  summ <- rd("p1_summary.csv")

  # ---- 1. sample map ---------------------------------------------------
  if (!is.null(scr) && nrow(scr) && requireNamespace("sf", quietly = TRUE)) {
    suppressMessages(library(sf))
    suppressMessages(library(patchwork))
    ind_outline <- sf::st_read(INDIA_OUTLINE_FILE, quiet = TRUE)
    ind_states <- sf::st_read(INDIA_STATES_FILE, quiet = TRUE)
    ind_meta <- data.table::as.data.table(gauge_meta())[
      , .(gauge_id = as.character(gauge_id), lon = cwc_lon, lat = cwc_lat)]
    scr[, gauge_id := as.character(gauge_id)]
    pts <- merge(scr, ind_meta, by = "gauge_id")
    pts[, stage := fifelse(
      pass_recession == TRUE & pass_complete == TRUE & pass_events_t1 == TRUE,
      "3 storage-scored (complete + events + recession)",
      fifelse(pass_complete == TRUE,
              "2 completeness screens passed", "1 read, excluded by screens"))]
    pts[, stage := factor(stage, levels = rev(c(
      "1 read, excluded by screens", "2 completeness screens passed",
      "3 storage-scored (complete + events + recession)")))]
    stage_cols <- c("1 read, excluded by screens" = "grey75",
                    "2 completeness screens passed" = blue,
                    "3 storage-scored (complete + events + recession)" = red)
    n3 <- sum(pts$stage == "3 storage-scored (complete + events + recession)")
    n2 <- sum(pts$stage == "2 completeness screens passed")
    p_map <- ggplot() +
      geom_sf(data = ind_states, fill = "grey95", colour = "white",
              linewidth = 0.18) +
      geom_sf(data = ind_outline, fill = NA, colour = "grey35",
              linewidth = 0.35) +
      geom_point(data = pts, aes(lon, lat, colour = stage),
                 size = 1.7, alpha = 0.85) +
      scale_colour_manual(values = stage_cols, name = NULL) +
      coord_sf(xlim = c(68, 98), ylim = c(6, 38), expand = FALSE) +
      labs(title = "Study P1 sample: recession-calibrated storage states across CAMELS-IND",
           subtitle = sprintf("%d catchments read; %d pass completeness + event screens; %d additionally pass the recession-quality screen",
                              nrow(pts), n2, n3)) +
      theme_void(base_size = 10) +
      theme(plot.title = element_text(face = "bold", size = 11),
            plot.subtitle = element_text(colour = grey, size = 9),
            legend.position = "bottom",
            legend.text = element_text(size = 8))
    save_fig(p_map, "fig_p1_map", 8, 5.2)
  }

  # ---- 2. lead-time skill curves (centrepiece) -------------------------
  if (!is.null(bss) && nrow(bss)) {
    b <- bss[is.finite(bss)]
    med <- b[, .(bss_med = stats::median(bss)), by = .(family, lead, target)]
    fam_order <- c("climatology", "persistence", "api", "lagged_indices",
                   "storage", "storage_plus_indices")
    med[, family := factor(family, levels = fam_order)]
    lab <- c(t1 = "T1: hydrological drought (SSI-3 <= -1)",
             t2 = "T2: low flow (monthly mean < training Q90)")
    p_lead <- ggplot(med, aes(lead, bss_med, colour = family, group = family)) +
      geom_hline(yintercept = 0, linetype = "dashed", colour = grey) +
      geom_line(linewidth = 0.7, alpha = 0.9) +
      geom_point(aes(size = family == "storage_plus_indices"), show.legend = FALSE) +
      scale_size_manual(values = c(`FALSE` = 1.7, `TRUE` = 3.1)) +
      facet_wrap(~target, labeller = as_labeller(lab)) +
      scale_colour_manual(values = fam_cols, name = NULL) +
      scale_x_continuous(breaks = c(1, 3, 6), labels = c("1", "3", "6")) +
      labs(x = "forecast lead (months)",
           y = "median Brier skill score vs climatology",
           title = "Lead-time skill: storage states vs memory baselines",
           subtitle = "Per-gauge BSS, median across catchments; issue month t, target t+h; training-only fitting") +
      base_theme
    save_fig(p_lead, "fig_p1_leadtime", 9, 4.6)

    # by-basin version of the centrepiece for the confirmatory family
    if ("basin" %in% names(b)) {
      bb <- merge(b[family == "storage_plus_indices"], 
                  params[, .(gauge_id, basin)], by = "gauge_id", all.x = TRUE)
      bmed <- bb[is.finite(bss), .(bss_med = stats::median(bss),
                                   n = .N), by = .(basin, lead, target)]
      p_basin <- ggplot(bmed[basin %in% names(which(table(bmed$basin) >= 5))],
                        aes(factor(lead), bss_med)) +
        geom_col(aes(fill = n), width = 0.7) +
        geom_hline(yintercept = 0, colour = grey) +
        facet_wrap(~target, labeller = labeller(target = lab)) +
        scale_fill_gradient(low = "#fdd0a2", high = "#d94801", name = "gauges") +
        labs(x = "forecast lead (months)", y = "median BSS (storage_plus_indices)",
             title = "Confirmatory family by river basin",
             subtitle = "Basins with at least 5 scored catchments") +
        base_theme
      save_fig(p_basin, "fig_p1_basin", 9, 4.4)
    }
  }

  # ---- 3. paired deltas -------------------------------------------------
  if (!is.null(paired) && nrow(paired)) {
    pd <- paired[baseline == "bestof" & is.finite(delta_brier)]
    pd[, lead_f := factor(lead, levels = c(1, 3, 6),
                          labels = c("1 month", "3 months", "6 months"))]
    pd[, tgt := factor(target, levels = c("t1", "t2"),
                       labels = c("T1 hydrological drought", "T2 low flow"))]
    p_pair <- ggplot(pd, aes(lead_f, delta_brier)) +
      geom_hline(yintercept = 0, colour = grey, linewidth = 0.5) +
      geom_violin(fill = "grey92", colour = NA, scale = "width") +
      geom_boxplot(width = 0.12, outlier.size = 0.7, fill = "white") +
      stat_summary(fun = stats::median, geom = "point", size = 2.2,
                   colour = red) +
      facet_wrap(~tgt, scales = "free_y") +
      labs(x = "forecast lead",
           y = "paired Brier delta (positive = storage family better)",
           title = "Confirmatory contrast: storage_plus_indices vs frozen best memory baseline",
           subtitle = "Per-gauge paired deltas on identical held-out months (2011-2020); red dot = median") +
      base_theme
    save_fig(p_pair, "fig_p1_paired", 9, 4.6)
  }

  # ---- 4. storage landscape --------------------------------------------
  if (!is.null(params) && nrow(params)) {
    q <- params[is.finite(k_days) & is.finite(S_cap_mm) & k_days > 0]
    q[, basin := factor(basin)]
    big <- names(sort(table(q$basin), decreasing = TRUE))[1:12]
    q12 <- q[basin %in% big]
    p_scatter <- ggplot(q12, aes(k_days, S_cap_mm, colour = BFI)) +
      geom_point(size = 1.6, alpha = 0.75) +
      scale_colour_viridis_c(name = "baseflow index", option = "viridis") +
      scale_x_log10() + scale_y_log10() +
      labs(x = "recession constant k (days, log)",
           y = expression("storage scale" ~ S[cap] ~ " (mm, log)"),
           title = "Recession-calibrated storage across Indian catchments",
           subtitle = "Fitted on training years (1981-2010); largest 12 basins by count; gauges with borrowed parameters excluded") +
      base_theme
    save_fig(p_scatter, "fig_p1_storage", 7.6, 4.8)
  }

  # ---- 5. example catchment state --------------------------------------
  # Recompute the verified fluid state for one well-observed gauge
  # through the SAME engine (no new code path; ledger-checked).
  {
    flow <- load_flow(); meta <- as.data.table(gauge_meta())
    done <- FALSE
    for (g in c(13004L, 8034L, 12018L)) {
      if (done) break
      i <- which(meta$gauge_id == g)
      if (!length(i)) next
      ff <- .read_forcing_one(g)
      if (is.null(ff)) next
      ff <- data.table::as.data.table(ff)
      qq <- flow[[as.character(g)]]
      if (is.null(qq) || sum(!is.na(qq)) < 3000) next
      d <- merge(ff[, .(date, prcp_mm, tmax_c, tmin_c, tavg_c, pet_gleam_mm)],
                 data.table(date = flow$date, q = qq), by = "date", all.x = TRUE)
      r <- common_rates(as.character(g), d$date, d$q, d$prcp_mm, d$tmax_c,
                        d$tmin_c, d$tavg_c, meta$area_km2[i], meta$cwc_lat[i],
                        pet_obs = d$pet_gleam_mm, region = "India",
                        irrigation_frac = 0.2)
      q_mm <- q_m3s_to_mm_day_na(r$q_used, meta$area_km2[i] * 1e6)
      yr <- as.integer(format(r$date, "%Y"))
      mask <- yr %in% P$train_years & is.finite(q_mm)
      rec <- fit_storage_scale(q_mm, r$prcp_mm, mask = mask,
                               min_len = P1_MIN_SEG_DAYS,
                               rain_mm = P1_RAIN_DAY_MM)
      if (!is.finite(rec$S_cap) || rec$S_cap <= 0 || rec$n_segments <
          P1_MIN_SEGMENTS) next
      st <- propagate_storage(r$date, r$prcp_mm, r$pet_mm,
                              as.integer(format(r$date, "%m")), "India",
                              S_cap = rec$S_cap, K_a = rec$K_a,
                              b_s = rec$b_s,
                              zero_day = q_mm == 0 & !is.na(q_mm))
      dd <- merge(st, r[, .(date, q_used, prcp_mm)], by = "date")
      dd <- dd[date >= as.Date("2005-01-01")]
      top <- ggplot(dd, aes(date)) +
        geom_col(aes(y = prcp_mm), fill = "grey85", width = 1.6) +
        geom_line(aes(y = S_mm), colour = blue, linewidth = 0.6) +
        labs(y = expression("P (bars, mm/day);  storage S (mm)"), x = NULL) +
        base_theme + theme(axis.title.x = element_blank(),
                           axis.text.x = element_blank())
      bot <- ggplot(dd, aes(date, q_used)) +
        geom_line(colour = red, linewidth = 0.3, alpha = 0.85) +
        scale_y_log10(labels = function(v) format(v, digits = 2)) +
        labs(y = expression("daily flow Q (m"^3 * "/s, log)"), x = NULL) +
        base_theme
      p_state <- top / bot + plot_layout(heights = c(1, 1)) +
        plot_annotation(
          title = sprintf("The fluid storage state for catchment %d (ledger-verified)", g),
          subtitle = sprintf("k = %.1f days, storage scale = %.1f mm, recession exponent p = %.2f; blue: state S(t); red: observed flow",
                             rec$k_days, rec$S_cap, rec$p),
          theme = theme(plot.title = element_text(face = "bold", size = 11),
                        plot.subtitle = element_text(colour = grey, size = 9)))
      save_fig(p_state, "fig_p1_state", 9.5, 5.0)
      done <- TRUE
    }
  }

  # ---- 6. reliability (needs predictions) -------------------------------
  preds <- rd("p1_predictions.csv")
  if (!is.null(preds) && nrow(preds)) {
    px <- preds[target == "t1" & lead == 3 &
                  family %in% c("climatology", "bestof",
                                "storage_plus_indices")]
    if (nrow(px)) {
      px[, family := factor(family, levels = c("climatology", "bestof",
                                               "storage_plus_indices"))]
      bins <- px[, .(n = .N, mean_p = mean(p), obs = mean(y)),
                 by = .(family, cut(p, breaks = seq(0, 1, by = 0.1),
                                    include.lowest = TRUE,
                                    labels = FALSE))]
      bins[, bin_centre := (cut - 0.5) / 10 + 0.05]
      p_rel <- ggplot(bins[n > 30], aes(mean_p, obs)) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                    colour = grey) +
        geom_line(aes(colour = family), linewidth = 0.6) +
        geom_point(aes(colour = family, size = n), alpha = 0.85) +
        scale_colour_manual(values = c(climatology = grey, bestof = blue,
                                       storage_plus_indices = red),
                            name = NULL) +
        lims(x = c(0, 1), y = c(0, 1)) +
        labs(x = "forecast probability", y = "observed frequency",
             title = "Pooled reliability, hydrological-drought target (T1), 3-month lead",
             subtitle = "Deciles pooled across scored catchments; dashed = perfect reliability") +
        base_theme
      save_fig(p_rel, "fig_p1_reliability", 6.6, 5.6)
    }
  }

  cat("figures_p1.R complete\n")
})
