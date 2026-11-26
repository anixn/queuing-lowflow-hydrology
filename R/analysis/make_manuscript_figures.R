# =====================================================================
# R/analysis/make_manuscript_figures.R -- manuscript figures that are not
# study-specific: workflow, study map, India-US comparison and the
# utilisation diagnosis.
#
# Outputs (PDF + 300-dpi PNG) in figures/:
#   fig_workflow
#   fig_study_map
#   fig_india_us_comparison
#   fig_utilisation_diagnosis
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  setwd(root)
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(data.table))
  suppressMessages(library(ggplot2))
  suppressMessages(library(maps))
  dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

  blue <- "#0072B2"; orange <- "#E69F00"; green <- "#009E73"
  vermillion <- "#D55E00"; grey <- "#666666"; sky <- "#56B4E9"
  save_fig <- function(p, name, w = 8, h = 5) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h,
           dpi = 300)
  }
  base_theme <- theme_bw(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 11))

  # ---- 1. Workflow ---------------------------------------------------
  boxes <- data.table(
    id = c("A", "B", "C", "D", "E", "F", "G", "H"),
    x = c(1.4, 4.2, 7.0, 1.4, 4.2, 7.0, 2.8, 5.6),
    y = c(3.2, 3.2, 3.2, 2.0, 2.0, 2.0, 0.8, 0.8),
    label = c(
      "Data\nIndia: CAMELS-IND + DIE\nUSA: Caravan + ResOpsUS + USDM",
      "Unit wall\none claim = 20 mm\nover the command area",
      "Rates\nlambda(t), mu(t)\nclaims / day",
      "Deficit queue\nRK4 transient +\nconservation ledger",
      "Indicators\nE[Q], P(Q >= q*),\nrecovery, abandonment",
      "Paired evaluation\nBrier, AUC,\ntwo-level bootstrap",
      "Utilisation diagnosis\nrho vs incremental skill",
      "Outcome\nno calibrated-probability gain;\nranking gain only"
    )
  )
  p1 <- ggplot() +
    geom_rect(data = boxes, aes(xmin = x - 1.25, xmax = x + 1.25,
                                ymin = y - 0.38, ymax = y + 0.38),
              fill = "white", colour = blue, linewidth = 0.6) +
    geom_text(data = boxes, aes(x, y, label = label), size = 3.0, lineheight = 0.95) +
    annotate("segment", x = 2.65, xend = 2.95, y = 3.2, yend = 3.2,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 5.45, xend = 5.75, y = 3.2, yend = 3.2,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 7.0, xend = 7.0, y = 2.82, yend = 2.38,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 5.45, xend = 5.75, y = 2.0, yend = 2.0,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 2.65, xend = 2.95, y = 2.0, yend = 2.0,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 4.2, xend = 4.2, y = 1.62, yend = 1.18,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    annotate("segment", x = 4.05, xend = 4.35, y = 0.8, yend = 0.8,
             arrow = arrow(length = unit(0.18, "cm")), colour = grey) +
    coord_cartesian(xlim = c(0, 8.4), ylim = c(0.2, 3.8)) +
    labs(title = "Deficit-queue drought analysis: workflow",
         subtitle = "Two independent multi-catchment tests (India gauges; USA reservoirs)") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", size = 12),
          plot.subtitle = element_text(size = 10, colour = grey),
          plot.margin = margin(10, 10, 10, 10))
  save_fig(p1, "fig_workflow", 9, 5.2)

  # ---- 2. Study map --------------------------------------------------
  world <- map_data("world")
  states <- map_data("state")
  india_poly <- world[world$region == "India", ]
  us_poly <- world[world$region == "USA", ]

  india_pts <- fread(file.path(OUTPUT_DIR, "catchment_table.csv"))
  ind_sel <- fread(file.path(OUTPUT_DIR, "selected_gauges.csv"))
  us_pts <- fread(file.path(root, "output_us", "reservoir_core.csv"))
  us_meta <- fread(file.path(root, "output_us", "reservoir_queue_meta.csv"))
  us_pts <- merge(us_pts, us_meta[, .(DAM_ID, rho)], by = "DAM_ID", all.x = TRUE)
  india_pts <- merge(india_pts, ind_sel[, .(gauge_id, rho)],
                     by = "gauge_id", all.x = TRUE)

  p_ind <- ggplot() +
    geom_polygon(data = india_poly, aes(long, lat, group = group),
                 fill = "grey95", colour = "grey40", linewidth = 0.3) +
    geom_point(data = india_pts, aes(lon, lat, colour = rho), size = 2.2) +
    scale_colour_gradient(low = blue, high = vermillion, name = expression(rho),
                          limits = c(0, 1.5), oob = scales::squish) +
    coord_fixed(xlim = c(68, 98), ylim = c(6, 36)) +
    labs(title = "India: 24 gauges, 11 basins",
         subtitle = "Colour = utilisation rho (SUP-1)") +
    base_theme + theme(axis.title = element_blank())

  p_us <- ggplot() +
    geom_polygon(data = us_poly, aes(long, lat, group = group),
                 fill = "grey95", colour = "grey40", linewidth = 0.3) +
    geom_polygon(data = states, aes(long, lat, group = group),
                 fill = NA, colour = "grey80", linewidth = 0.15) +
    geom_point(data = us_pts, aes(dam_lon, dam_lat, colour = rho), size = 2.2) +
    scale_colour_gradient(low = blue, high = vermillion, name = expression(rho),
                          limits = c(0, 1.5), oob = scales::squish) +
    coord_fixed(xlim = c(-125, -66), ylim = c(24, 50)) +
    labs(title = "USA: 50 reservoir-catchment pairs",
         subtitle = "Colour = utilisation rho (reservoir outflow)") +
    base_theme + theme(axis.title = element_blank())

  if (requireNamespace("patchwork", quietly = TRUE)) {
    p2 <- patchwork::wrap_plots(p_ind, p_us, ncol = 2)
  } else {
    p2 <- p_ind  # fallback: India panel only
  }
  save_fig(p2, "fig_study_map", 11, 5)

  # ---- 3. India-US comparison ---------------------------------------
  ind <- fread(file.path(OUTPUT_DIR, "meta_endpoints.csv"))
  ind <- ind[endpoint %in% c("E1", "E2")]
  ind_cmp <- data.table(study = "India", endpoint = ind$endpoint,
                        dBrier = ind$median_delta, lo = ind$boot_lo,
                        hi = ind$boot_hi, dAUC = ind$median_delta_auc)
  us <- fread(file.path(root, "output_us", "us_meta.csv"))
  us_cmp <- data.table(study = "USA", endpoint = us$endpoint,
                       dBrier = us$median_delta, lo = us$boot_lo,
                       hi = us$boot_hi, dAUC = us$median_dauc)
  cmp <- rbind(ind_cmp, us_cmp)
  long <- rbind(
    cmp[, .(study, endpoint, metric = "Delta Brier (positive = queue improves)",
            value = dBrier, lo, hi)],
    cmp[, .(study, endpoint, metric = "Delta AUC (positive = queue improves)",
            value = dAUC, lo = NA_real_, hi = NA_real_)]
  )
  long[, metric := factor(metric, levels = unique(metric))]
  long[, label := paste(study, endpoint, sep = " ")]
  p3 <- ggplot(long, aes(x = value, y = label, colour = study)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
    geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.18, na.rm = TRUE) +
    geom_point(size = 2.8) +
    facet_wrap(~metric, scales = "free_x") +
    scale_colour_manual(values = c(India = blue, USA = orange), name = NULL) +
    labs(x = NULL, y = NULL,
         title = "Two independent tests: no calibrated-probability gain",
         subtitle = "Bars are two-level bootstrap 95% intervals; AUC is secondary") +
    base_theme
  save_fig(p3, "fig_india_us_comparison", 10, 4.8)

  # ---- 4. Utilisation diagnosis -------------------------------------
  ind_q <- fread(file.path(OUTPUT_DIR, "selected_gauges.csv"))
  ind_p <- fread(file.path(OUTPUT_DIR, "paired_e1.csv"))
  ind_d <- merge(ind_q[, .(id = gauge_id, rho)],
                 ind_p[, .(id = gauge_id, dBrier = delta_brier, dAUC = delta_auc)],
                 by = "id")
  ind_d[, study := "India"]

  us_q <- fread(file.path(root, "output_us", "reservoir_queue_meta.csv"))
  us_p <- fread(file.path(root, "output_us", "us_paired_e1.csv"))
  us_d <- merge(us_q[, .(id = DAM_ID, rho)],
                us_p[, .(id = gauge_id, dBrier = delta_brier, dAUC = delta_auc)],
                by = "id")
  us_d[, study := "USA"]

  diag <- rbind(ind_d, us_d)
  diag[, study := factor(study, levels = c("India", "USA"))]
  p4 <- ggplot(diag, aes(x = rho, y = dBrier, colour = study)) +
    annotate("rect", xmin = P$rho_window[1], xmax = P$rho_window[2],
             ymin = -Inf, ymax = Inf, fill = green, alpha = 0.10) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = grey) +
    geom_point(size = 1.8, alpha = 0.8) +
    geom_smooth(method = "lm", se = TRUE, linewidth = 0.7, formula = y ~ x) +
    facet_wrap(~study, scales = "free_x") +
    scale_colour_manual(values = c(India = blue, USA = orange), guide = "none") +
    coord_cartesian(xlim = c(0, 5)) +
    labs(x = expression("utilisation " * rho),
         y = expression(Delta[g] == Brier(SSI-3) - Brier(SSI-3 + queue)),
         title = "Utilisation diagnosis: where does the queue help?",
         subtitle = "Shaded band = predeclared admissible window 0.15-1.20") +
    base_theme
  save_fig(p4, "fig_utilisation_diagnosis", 9, 4.5)

  cat("manuscript figures written to", FIG_DIR, "\n")
  print(list.files(FIG_DIR, pattern = "^fig_(workflow|study_map|india_us|utilisation)"))
})
