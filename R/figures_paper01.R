# =====================================================================
# R/figures_paper01.R -- publication-grade figures for Paper 01
# (the P1 study package). Writes ONLY into paper01/figures/, PDF + PNG
# (300 dpi), from output/*.csv written by the verified study scripts.
# Nothing is hand-edited. One shared palette; panel tags (a)-(g).
#
# Usage:  Rscript R/figures_paper01.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/figures_paper01.R")
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
  PAPER_DIR <- file.path(root, "paper01")
  FIG_DIR <- file.path(PAPER_DIR, "figures")
  ensure_dir(FIG_DIR)

  # ---- shared palette (colour-blind-safe ordering) --------------------
  pal <- list(
    blue = "#2C6FBB", orange = "#D1603D", red = "#B23A48",
    purple = "#8C6BB1", green = "#41AB5D", teal = "#31859C",
    grey = "#666666", dark = "#1A1A1A")
  fam_cols <- c(climatology = pal$grey, persistence = pal$purple,
                lagged_indices = pal$blue, api = pal$green,
                storage = pal$orange, storage_plus_indices = pal$red)
  fam_lab <- c(climatology = "Climatology", persistence = "Persistence",
               lagged_indices = "Lagged indices", api = "API",
               storage = "Storage", storage_plus_indices = "Storage + indices")

  save_fig <- function(p, name, w, h) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h,
           dpi = 300)
  }
  base_theme <- theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 12),
          plot.subtitle = element_text(colour = pal$grey, size = 9.5),
          legend.position = "bottom",
          strip.text = element_text(face = "bold"))
  rd <- function(f) {
    p <- file.path(OUTPUT_DIR, f)
    if (!file.exists(p)) return(NULL)
    fread(p)
  }
  tag <- function(p, text) p + ggplot2::labs(tag = text) +
    theme(plot.tag = element_text(face = "bold", size = 12))

  # =====================================================================
  # Fig01 -- methods / analysis flow (drawn, reproducible, no data)
  # =====================================================================
  box <- function(x, y, w, h, fill) {
    data.table::data.table(x = x, y = y, w = w, h = h, fill = fill)
  }
  steps <- data.table::rbindlist(list(
    box(4.9, 9.7, 9.4, 1.0, "#FDF3E7"),
    box(1.4, 8.0, 2.7, 1.15, "#EFF4FA"),
    box(1.4, 6.5, 2.7, 1.15, "#EFF4FA"),
    box(1.4, 5.0, 2.7, 1.15, "#EFF4FA"),
    box(1.4, 3.5, 2.7, 1.15, "#EFF4FA"),
    box(4.9, 3.5, 2.7, 1.15, "#F4EFF9"),
    box(4.9, 5.0, 2.7, 1.15, "#F4EFF9"),
    box(8.3, 3.5, 2.7, 1.15, "#EFF7EF"),
    box(8.3, 5.0, 2.7, 1.15, "#EFF7EF")
  ))
  labels <- data.table::data.table(
    x = c(4.9, 1.4, 1.4, 1.4, 1.4, 4.9, 4.9, 8.3, 8.3),
    y = c(9.7, 8.0, 6.5, 5.0, 3.5, 3.5, 5.0, 3.5, 5.0),
    lab = c(
      "LEAKAGE DISCIPLINE\nEvery threshold, screen, standardisation and fit uses the\ntraining years (1981-2010) only; test years are touched once",
      "Daily forcings\nP, PET, observed Q\n(CAMELS-IND;\nCaravan-US transfer)",
      "Recession fits\n(training years only)\nBFI, k, p, a\n-> K_a, b_s, S_cap",
      "Fluid state S(t)\nledger-checked daily\nbalance; Q never\nenters as an input",
      "Monthly features\nS_anom, dS1, dS3,\ndays-since-high-flow",
      "Targets and leads\nT1: SSI-3 <= -1\nT2: flow < Q90\nleads 1 / 3 / 6 months",
      "Baselines\npersistence, lagged\nindices (SPI/SSI-3,6),\nAPI, climatology",
      "Ridge logistic\nper-family CV-tuned\npenalty (train only)",
      "Evaluation\nBSS vs climatology;\npaired deltas;\n2-level bootstrap")
  )
  arrows <- data.table::data.table(
    x = c(1.4, 1.4, 1.4, 2.75, 6.25, 6.25, 8.3),
    y = c(7.42, 5.92, 4.42, 3.5, 4.42, 3.5, 4.07),
    xend = c(1.4, 1.4, 1.4, 3.55, 6.95, 6.95, 8.3),
    yend = c(7.07, 5.57, 4.07, 3.5, 3.9, 3.5, 4.43)
  )
  flow <- ggplot() +
    geom_rect(data = steps,
              aes(xmin = x - w / 2, xmax = x + w / 2,
                  ymin = y - h / 2, ymax = y + h / 2, fill = fill),
              colour = pal$dark, linewidth = 0.25) +
    geom_text(data = labels, aes(x, y, label = lab),
              size = 2.55, lineheight = 0.95) +
    geom_segment(data = arrows, aes(x = x, y = y, xend = xend, yend = yend),
                 arrow = arrow(length = unit(2.5, "mm"), type = "closed"),
                 colour = pal$grey, linewidth = 0.35) +
    scale_fill_identity() +
    coord_fixed(ratio = 1.15, xlim = c(-0.1, 9.7), ylim = c(2.8, 10.4)) +
    theme_void(base_size = 11) +
    labs(title = "Analysis flow: from daily records to the frozen confirmatory contrasts",
         subtitle = "Every box is a script stage in R/; every number in the paper is generated by one of them")
  save_fig(flow, "Fig01_methods_flow", 9.2, 4.4)

  # =====================================================================
  # Fig02 -- study map (India; screen stages)
  # =====================================================================
  scr <- rd("p1_sample_report.csv")
  if (!file.exists(INDIA_OUTLINE_FILE) || !file.exists(INDIA_STATES_FILE)) {
    cat("  Fig02_study_map skipped: boundary file not mounted\n")
  }
  if (!is.null(scr) && requireNamespace("sf", quietly = TRUE) &&
      file.exists(INDIA_OUTLINE_FILE) && file.exists(INDIA_STATES_FILE)) {
    suppressMessages(library(sf))
    ind_outline <- sf::st_read(INDIA_OUTLINE_FILE, quiet = TRUE)
    ind_states <- sf::st_read(INDIA_STATES_FILE, quiet = TRUE)
    ind_meta <- as.data.table(gauge_meta())[
      , .(gauge_id = as.character(gauge_id), lon = cwc_lon, lat = cwc_lat)]
    scr[, gauge_id := as.character(gauge_id)]
    pts <- merge(scr, ind_meta, by = "gauge_id")
    pts[, stage := fifelse(
      pass_recession == TRUE & pass_complete == TRUE & pass_events_t1 == TRUE,
      "Storage-scored (complete + events + recession)",
      fifelse(pass_complete == TRUE, "Completeness screens passed",
              "Read, excluded by screens"))]
    pts[, stage := factor(stage, levels = c("Read, excluded by screens",
                                            "Completeness screens passed",
                                            "Storage-scored (complete + events + recession)"))]
    stage_cols <- c("Read, excluded by screens" = "grey75",
                    "Completeness screens passed" = pal$blue,
                    "Storage-scored (complete + events + recession)" = pal$red)
    n3 <- sum(scr$pass_complete & scr$pass_events_t1 & scr$pass_recession,
              na.rm = TRUE)
    n2 <- sum(scr$pass_complete, na.rm = TRUE)
    n_plot <- nrow(pts)
    p_map <- ggplot() +
      geom_sf(data = ind_states, fill = "grey95", colour = "white",
              linewidth = 0.18) +
      geom_sf(data = ind_outline, fill = NA, colour = "grey35",
              linewidth = 0.35) +
      geom_point(data = pts, aes(lon, lat, colour = stage), size = 1.8,
                 alpha = 0.85) +
      scale_colour_manual(values = stage_cols, name = NULL) +
      coord_sf(xlim = c(68, 98), ylim = c(6, 38), expand = FALSE) +
      labs(subtitle = sprintf(paste0("%d catchments read; %d pass the completeness screens; ",
                                     "%d of those also pass the event and recession screens (%d plotted)"),
                              nrow(scr), n2, n3, n_plot)) +
      theme_void(base_size = 11) +
      theme(plot.subtitle = element_text(colour = pal$grey, size = 9.5),
            legend.position = "bottom", legend.text = element_text(size = 8.5))
    save_fig(tag(p_map, "a"), "Fig02_study_map", 8.0, 5.4)
  }

  # =====================================================================
  # Fig03 -- CENTREPIECE: lead-time skill curves (paired benchmark)
  # =====================================================================
  bss <- rd("p1_bss_paired.csv")
  if (!is.null(bss) && nrow(bss)) {
    bss <- bss[region == "India"]
    b <- bss[is.finite(bss)]
    med <- b[, .(bss_med = stats::median(bss)), by = .(family, lead, target)]
    fam_order <- c("climatology", "persistence", "api", "lagged_indices",
                   "storage", "storage_plus_indices")
    med[, family := factor(family, levels = fam_order)]
    lab <- c(t1 = "T1: hydrological drought (SSI-3 <= -1)",
             t2 = "T2: low flow (monthly mean < training Q90)")
    p_lead <- ggplot(med, aes(lead, bss_med, colour = family, group = family)) +
      geom_hline(yintercept = 0, linetype = "dashed", colour = pal$grey) +
      geom_line(linewidth = 0.8, alpha = 0.95) +
      geom_point(aes(size = family == "storage_plus_indices"),
                 show.legend = FALSE) +
      scale_size_manual(values = c(`FALSE` = 1.8, `TRUE` = 3.2)) +
      facet_wrap(~target, labeller = as_labeller(lab)) +
      scale_colour_manual(values = fam_cols, labels = fam_lab, name = NULL) +
      scale_x_continuous(breaks = P1_LEADS,
                         labels = as.character(P1_LEADS)) +
      labs(x = "Forecast lead (months)",
           y = "Median Brier skill score vs climatology",
           subtitle = paste0("Every family scored on identical months (one common ",
                             "sample per gauge); median across catchments; ",
                             "training-only fitting. Leads 2 and 12 are exploratory.")) +
      base_theme
    save_fig(tag(p_lead, "b"), "Fig03_leadtime_skill", 9.2, 4.8)
  }

  # =====================================================================
  # Fig04 -- confirmatory paired deltas (frozen best-of contrast)
  # =====================================================================
  paired <- rd("p1_paired.csv")
  if (!is.null(paired) && nrow(paired)) {
    pd <- paired[baseline == "bestof" & is.finite(delta_brier)]
    pd[, lead_f := factor(lead, levels = P1_LEADS,
                          labels = sprintf("%d month%s", P1_LEADS,
                                           ifelse(P1_LEADS == 1, "", "s")))]
    pd[, tgt := factor(target, levels = c("t1", "t2"),
                       labels = c("T1 hydrological drought", "T2 low flow"))]
    p_pair <- ggplot(pd, aes(lead_f, delta_brier)) +
      geom_hline(yintercept = 0, colour = pal$grey, linewidth = 0.5) +
      geom_violin(fill = "grey92", colour = NA, scale = "width") +
      geom_boxplot(width = 0.12, outlier.size = 0.7, fill = "white") +
      stat_summary(fun = stats::median, geom = "point", size = 2.4,
                   colour = pal$red) +
      facet_wrap(~tgt, scales = "free_y") +
      labs(x = "Forecast lead",
           y = "Paired Brier delta (positive = storage family better)",
           subtitle = "Per-gauge paired deltas on identical held-out months (2011-2020); red dot = median") +
      base_theme
    save_fig(tag(p_pair, "c"), "Fig04_paired_deltas", 9.2, 4.8)
  }

  # =====================================================================
  # Fig05 -- the fluid state for one example catchment
  # =====================================================================
  if (requireNamespace("patchwork", quietly = TRUE)) {
    suppressMessages(library(patchwork))
    flow_meta <- as.data.table(gauge_meta())
    done <- FALSE
    for (g in c(13004L, 8034L, 12018L)) {
      if (done) break
      i <- which(flow_meta$gauge_id == g)
      if (!length(i)) next
      ff <- .read_forcing_one(g)
      if (is.null(ff)) next
      ff <- as.data.table(ff)
      qq <- load_flow()
      q <- qq[[as.character(g)]]
      if (is.null(q) || sum(!is.na(q)) < 3000) next
      d <- merge(ff[, .(date, prcp_mm, tmax_c, tmin_c, tavg_c, pet_gleam_mm)],
                 data.table(date = qq$date, q = q), by = "date", all.x = TRUE)
      r <- prepare_daily(as.character(g), d$date, d$q, d$prcp_mm, d$tmax_c,
                         d$tmin_c, d$tavg_c, flow_meta$cwc_lat[i],
                         pet_obs = d$pet_gleam_mm, region = "India")
      q_mm <- q_m3s_to_mm_day_na(r$q_used, flow_meta$area_km2[i] * 1e6)
      yr <- as.integer(format(r$date, "%Y"))
      mask <- yr %in% P$train_years & is.finite(q_mm)
      rec <- fit_storage_scale(q_mm, r$prcp_mm, mask = mask,
                               min_len = P1_MIN_SEG_DAYS,
                               rain_mm = P1_RAIN_DAY_MM)
      if (!is.finite(rec$S_cap) || rec$S_cap <= 0 ||
          rec$n_segments < P1_MIN_SEGMENTS) next
      st <- propagate_storage(r$date, r$prcp_mm, r$pet_mm,
                              as.integer(format(r$date, "%m")), "India",
                              S_cap = rec$S_cap, K_a = rec$K_a,
                              b_s = rec$b_s,
                              zero_day = q_mm == 0 & !is.na(q_mm))
      dd <- merge(st, r[, .(date, q_used, prcp_mm)], by = "date")
      dd <- dd[date >= as.Date("2005-01-01")]
      top <- ggplot(dd, aes(date)) +
        geom_col(aes(y = prcp_mm), fill = "grey85", width = 1.6) +
        geom_line(aes(y = S_mm), colour = pal$blue, linewidth = 0.6) +
        labs(y = "P (bars, mm/day);  S (mm)", x = NULL) +
        base_theme + theme(axis.title.x = element_blank(),
                           axis.text.x = element_blank())
      bot <- ggplot(dd, aes(date, q_used)) +
        geom_line(colour = pal$red, linewidth = 0.3, alpha = 0.85) +
        scale_y_log10(labels = function(v) format(v, digits = 2)) +
        labs(y = expression("daily flow Q (m"^3 * "/s, log)"), x = NULL) +
        base_theme
      p_state <- top / bot + plot_layout(heights = c(1, 1)) +
        plot_annotation(
          subtitle = sprintf("Catchment %d: recession constant k = %.1f days, storage scale = %.1f mm, exponent p = %.2f. Blue: ledger-verified state S(t); red: observed flow. The state is a smoothed mirror of the flow record - the mechanism behind the null.",
                             g, rec$k_days, rec$S_cap, rec$p),
          theme = theme(plot.subtitle = element_text(colour = pal$grey,
                                                     size = 9.5)))
      save_fig(tag(p_state, "d"), "Fig05_example_state", 9.5, 5.2)
      done <- TRUE
    }
  }

  # =====================================================================
  # Fig06 -- storage landscape (k vs S_cap, colour = BFI)
  # =====================================================================
  params <- rd("p1_storage_params.csv")
  if (!is.null(params) && nrow(params)) {
    q <- params[is.finite(k_days) & is.finite(S_cap_mm) & k_days > 0]
    big <- names(sort(table(q$basin), decreasing = TRUE))[1:12]
    q12 <- q[basin %in% big]
    p_scatter <- ggplot(q12, aes(k_days, S_cap_mm, colour = BFI)) +
      geom_point(size = 1.7, alpha = 0.8) +
      scale_colour_viridis_c(name = "Baseflow index", option = "viridis") +
      scale_x_log10() + scale_y_log10() +
      labs(x = "Recession constant k (days, log)",
           y = expression("Storage scale" ~ S[cap] ~ "(mm, log)"),
           subtitle = "Fitted on training years (1981-2010); 12 largest basins by count; gauges with borrowed parameters excluded") +
      base_theme
    save_fig(tag(p_scatter, "e"), "Fig06_storage_landscape", 7.8, 5.0)
  }

  # =====================================================================
  # Fig07 -- pooled reliability (T1, 3-month lead)
  # =====================================================================
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
                                    include.lowest = TRUE, labels = FALSE))]
      bins[, bin_centre := (cut - 0.5) / 10 + 0.05]
      p_rel <- ggplot(bins[n > 30], aes(mean_p, obs)) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                    colour = pal$grey) +
        geom_line(aes(colour = family), linewidth = 0.65) +
        geom_point(aes(colour = family, size = n), alpha = 0.85) +
        scale_colour_manual(values = c(climatology = pal$grey,
                                       bestof = pal$blue,
                                       storage_plus_indices = pal$red),
                            labels = c("Climatology", "Best baseline",
                                       "Storage + indices"), name = NULL) +
        lims(x = c(0, 1), y = c(0, 1)) +
        labs(x = "Forecast probability", y = "Observed frequency",
             subtitle = "Deciles pooled across scored catchments; dashed = perfect reliability") +
        base_theme
      save_fig(tag(p_rel, "f"), "Fig07_reliability", 6.8, 5.8)
    }
  }

  cat("figures_paper01.R complete: Fig01-Fig07 in paper01/figures/\n")
})
