# =====================================================================
# R/analysis/make_figures.R -- publication figures (ggplot2).
#
# Reads the pipeline outputs and writes PDF + 300-dpi PNG pairs to
# figures/. Colour-blind-safe (Okabe-Ito) palette. Colour vectors are
# unnamed so scale_colour_manual maps them to factor levels by order.
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/analysis/make_figures.R")
  root <- normalizePath(file.path(dirname(script), "..", ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) source(file.path(QDJ_ROOT, "R", "00_utils", u))
  suppressMessages(library(data.table))
  suppressMessages(library(ggplot2))
  ensure_dir(FIG_DIR)

  blue <- "#0072B2"; orange <- "#E69F00"; green <- "#009E73"
  vermillion <- "#D55E00"; grey <- "#999999"
  save_fig <- function(p, name, w = 8, h = 5) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
  }
  base_theme <- theme_bw(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 11))

  screen <- fread(file.path(OUTPUT_DIR, "screen_report.csv"))
  qm <- fread(file.path(OUTPUT_DIR, "queue_meta.csv"))
  m1 <- fread(file.path(OUTPUT_DIR, "metrics_e1.csv"))
  m2 <- fread(file.path(OUTPUT_DIR, "metrics_e2.csv"))
  d1 <- fread(file.path(OUTPUT_DIR, "delta_e1.csv"))

  # ---- Fig 1: utilization screen (SUP-1) -----------------------------
  s1 <- screen[supply_variant == "SUP-1"]
  s1[, status := factor(ifelse(rho >= P$rho_window[1] & rho <= P$rho_window[2],
                               "inside window", "outside window"),
                        levels = c("inside window", "outside window"))]
  p1 <- ggplot(s1, aes(x = reorder(factor(gauge_id), rho), y = rho,
                       colour = status)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = P$rho_window[1],
             ymax = P$rho_window[2], fill = green, alpha = 0.12) +
    geom_point(size = 2.2) +
    geom_hline(yintercept = P$rho_window, linetype = "dashed", colour = grey) +
    scale_colour_manual(values = c(blue, vermillion), name = NULL) +
    labs(x = "candidate gauge (ordered by utilisation)",
         y = expression(rho == sum(lambda)/sum(mu)),
         title = "Utilization screen (SUP-1): does demand approach supply?",
         subtitle = "Shaded band = predeclared admissible window 0.15-1.20") +
    base_theme + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
  save_fig(p1, "fig01_utilization_screen", 9, 4.5)

  # ---- Fig 2: regime table -------------------------------------------
  qm[, gauge_label := factor(gauge_id, levels = gauge_id[order(max_p_ge_q)])]
  p2a <- ggplot(qm, aes(x = max_p_ge_q, y = gauge_label)) +
    geom_segment(aes(x = 0, xend = max_p_ge_q, yend = gauge_label), colour = grey) +
    geom_point(colour = vermillion, size = 2) +
    labs(x = expression(max[t]~P(Q >= q^"*")), y = "gauge",
         title = "Peak probability of a severe backlog state") +
    base_theme
  p2b <- ggplot(qm, aes(x = max_E_Q, y = gauge_label)) +
    geom_segment(aes(x = 0, xend = max_E_Q, yend = gauge_label), colour = grey) +
    geom_point(colour = blue, size = 2) +
    labs(x = expression(max[t]~E[Q]~"(claims)"), y = NULL,
         title = "Peak expected backlog") +
    base_theme + theme(axis.text.y = element_blank())
  save_fig(p2a, "fig02_regime_pq", 6, 6)
  save_fig(p2b, "fig02_regime_eq", 5, 6)

  # ---- Fig 3: Brier-delta forest (E1 primary contrast) --------------
  ci <- d1[, {
    b <- year_block_bootstrap(year, delta, B = 2000, seed = P$seed)
    .(estimate = mean(delta), lo = b["lo"], hi = b["hi"])
  }, by = gauge_id]
  ci[, gauge_label := factor(gauge_id, levels = gauge_id[order(estimate)])]
  p3 <- ggplot(ci, aes(x = estimate, y = gauge_label)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
    geom_errorbarh(aes(xmin = lo, xmax = hi), width = 0.25, colour = blue) +
    geom_point(size = 2, colour = blue) +
    labs(x = expression(Delta[g] == Brier(SSI3) - Brier(SSI3+queue)),
         y = "gauge",
         title = "E1 Brier delta (positive = queue improves)",
         subtitle = "Bars are paired year-block bootstrap 95% intervals") +
    base_theme
  save_fig(p3, "fig03_brier_forest_e1", 7.5, 6)

  # ---- Fig 4: AUC-delta forest (E1 and E2, faceted) -----------------
  auc_delta <- function(m, ep) {
    a <- m[family == "ssi3", .(gauge_id, auc_a = auc)]
    b <- m[family == "ssi3_plus_queue", .(gauge_id, auc_b = auc)]
    d <- merge(a, b, by = "gauge_id")
    d[, `:=`(endpoint = ep, d_auc = auc_b - auc_a)]
    d
  }
  ad <- rbind(auc_delta(m1, "E1 concurrent"), auc_delta(m2, "E2 prospective"))
  ad[, endpoint := factor(endpoint, levels = c("E1 concurrent", "E2 prospective"))]
  ad[, gauge_label := factor(gauge_id, levels = sort(unique(gauge_id)))]
  p4 <- ggplot(ad, aes(x = d_auc, y = gauge_label)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
    geom_point(size = 2, colour = blue) +
    facet_wrap(~endpoint, ncol = 2) +
    labs(x = expression(Delta*AUC == AUC(SSI3+queue) - AUC(SSI3)),
         y = "gauge", title = "Secondary endpoint: AUC delta (positive = queue improves)") +
    base_theme
  save_fig(p4, "fig04_auc_forest", 9, 6)

  # ---- Fig 5: example monthly series (gauge 5018) -------------------
  g <- 5018L
  flow <- load_flow(); meta <- gauge_meta(); districts <- map_gauges_to_districts(meta)
  aud <- stage2_zero_audit(flow, meta, g)
  cr <- stage3_catchment(g, meta, districts)
  rates <- stage3_rates(g, flow, cr, class_daily = aud$daily)
  qres <- stage5_queue(rates)
  sma <- load_sma_long()
  mon <- merge(qres$monthly, sma[district_id == cr$district_id, .(date, sma, target_sma)],
               by = "date", all.x = TRUE)
  mon <- mon[month_complete == TRUE]
  scale_max <- max(mon$mean_E_Q)
  long <- rbind(
    mon[, .(date, series = "E[Q] backlog (claims)", value = mean_E_Q)],
    mon[, .(date, series = "P(Q>=q*) (scaled)", value = mean_p_ge_q * scale_max)]
  )
  long[, series := factor(series, levels = c("E[Q] backlog (claims)", "P(Q>=q*) (scaled)"))]
  p5 <- ggplot(long, aes(x = date, y = value, colour = series)) +
    geom_rect(data = mon[target_sma == 1],
              aes(xmin = date - 15, xmax = date + 15, ymin = -Inf, ymax = Inf),
              fill = orange, alpha = 0.18, inherit.aes = FALSE) +
    geom_line(linewidth = 0.55) +
    scale_colour_manual(values = c(blue, vermillion), name = NULL) +
    labs(x = NULL, y = "backlog (claims) / scaled probability",
         title = "Gauge 5018 (Erode): monthly queue state and district drought",
         subtitle = "Shaded months = district SMA <= -15% (external product)") +
    base_theme
  save_fig(p5, "fig05_example_series_5018", 9, 4.5)

  # ---- Fig 6: pooled reliability (ssi3 vs ssi3+queue) ---------------
  p1p <- fread(file.path(OUTPUT_DIR, "predictions_e1.csv"))
  rel <- p1p[family %in% c("ssi3", "ssi3_plus_queue"),
             reliability_table(y, p, bins = 10L), by = family]
  rel <- rel[n > 0]
  rel[, family := factor(family, levels = c("ssi3", "ssi3_plus_queue"),
                         labels = c("SSI-3", "SSI-3 + queue"))]
  p6 <- ggplot(rel, aes(x = mean_pred, y = obs_freq, colour = family)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = grey) +
    geom_line(linewidth = 0.6) + geom_point(aes(size = n)) +
    scale_colour_manual(values = c(blue, vermillion), name = NULL) +
    scale_size_area(max_size = 4, name = "months") +
    coord_equal(xlim = c(0, 0.7), ylim = c(0, 0.7)) +
    labs(x = "predicted probability", y = "observed drought frequency",
         title = "E1 reliability (all gauges pooled)") +
    base_theme
  save_fig(p6, "fig06_reliability", 5.8, 5)

  # ---- Fig 7: sensitivity forest (one factor at a time) --------------
  sm_path <- file.path(OUTPUT_DIR, "sensitivity_meta.csv")
  if (file.exists(sm_path)) {
    sm <- fread(sm_path)
    sm[, lab := sprintf("%-16s %s", axis, level)]
    sm[, lab := factor(lab, levels = lab[order(median_delta_brier)])]
    p7 <- ggplot(sm, aes(x = median_delta_brier, y = lab)) +
      geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
      geom_errorbarh(aes(xmin = boot_lo, xmax = boot_hi),
                     width = 0.25, colour = blue) +
      geom_point(size = 2, colour = blue) +
      labs(x = expression(median~Delta[g]~"(positive = queue improves)"),
           y = NULL,
           title = "Sensitivity grid: one factor at a time",
           subtitle = "Baseline plus every predeclared axis level; bars are bootstrap 95% intervals") +
      base_theme
    save_fig(p7, "fig07_sensitivity", 9, 6.5)
  }

  cat("figures written to", FIG_DIR, "\n")
})
