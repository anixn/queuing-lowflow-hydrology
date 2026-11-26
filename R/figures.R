# =====================================================================
# R/figures.R -- figures for the one common study.
#
# Reads only output/*.csv written by R/study.R. Nothing is hand-edited.
# Writes PDF + 300-dpi PNG to figures/.
#
# Figures:
#   fig_study_map    : the two study regions with screened and paired catchments
#   fig_utilisation  : utilisation rho by region, with the common window
#   fig_paired_brier : per-gauge paired Brier improvement by region
#   fig_region       : regional median dBrier / dAUC with bootstrap CIs
#
# Usage:  Rscript R/figures.R
# =====================================================================

local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/figures.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  source(file.path(root, "R", "config.R"))
  for (u in c("io.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages({
    library(data.table)
    library(ggplot2)
  })
  ensure_dir(FIG_DIR)

  blue <- "#2c6fbb"; orange <- "#d1603d"; grey <- "#666666"

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

  scr <- rbind(rd("india_screen.csv"), rd("usa_screen.csv"), fill = TRUE)
  paired <- rbind(rd("india_paired.csv"), rd("usa_paired.csv"), fill = TRUE)
  summ <- rd("region_summary.csv")
  diff_tab <- rd("region_difference.csv")

  # ---- 1. study map ---------------------------------------------------
  # India: full outline and state boundaries from the Drought Intelligence
  # Explorer; USA: state polygons from ggplot2::map_data("state").
  if (!is.null(scr) && nrow(scr) && requireNamespace("sf", quietly = TRUE)) {
    suppressMessages(library(sf))
    suppressMessages(library(patchwork))

    ind_outline <- sf::st_read(INDIA_OUTLINE_FILE, quiet = TRUE)
    ind_states <- sf::st_read(INDIA_STATES_FILE, quiet = TRUE)

    ind_meta <- data.table::as.data.table(gauge_meta())[
      , .(gauge_id = as.character(gauge_id), lon = cwc_lon, lat = cwc_lat)]
    us_attr <- fread(file.path(CARAVAN_ROOT, "attributes", "camels",
                               "attributes_other_camels.csv"))
    us_meta <- us_attr[, .(gauge_id = as.character(gauge_id),
                           lon = gauge_lon, lat = gauge_lat)]

    scr[, gauge_id := as.character(gauge_id)]
    ind_pts <- merge(scr[region == "India"], ind_meta, by = "gauge_id")
    us_pts <- merge(scr[region == "USA"], us_meta, by = "gauge_id")
    ind_ids <- if (file.exists(file.path(OUTPUT_DIR, "india_paired.csv")))
      as.character(fread(file.path(OUTPUT_DIR, "india_paired.csv"))$gauge_id) else character(0)
    us_ids <- if (file.exists(file.path(OUTPUT_DIR, "usa_paired.csv")))
      as.character(fread(file.path(OUTPUT_DIR, "usa_paired.csv"))$gauge_id) else character(0)
    ind_sel <- ind_pts[gauge_id %in% ind_ids]
    us_sel <- us_pts[gauge_id %in% us_ids]

    map_theme <- theme_void(base_size = 12) +
      theme(plot.title = element_text(face = "bold", size = 12),
            plot.subtitle = element_text(colour = grey, size = 9.5),
            plot.margin = margin(2, 2, 2, 2))

    p_ind <- ggplot() +
      geom_sf(data = ind_states, fill = "grey95", colour = "white",
              linewidth = 0.18) +
      geom_sf(data = ind_outline, fill = NA, colour = "grey35",
              linewidth = 0.35) +
      geom_point(data = ind_pts, aes(lon, lat), colour = "grey55",
                 size = 1.0, alpha = 0.55) +
      geom_point(data = ind_sel, aes(lon, lat), colour = blue, size = 2.1) +
      coord_sf(xlim = c(68, 98), ylim = c(6, 38), expand = FALSE) +
      labs(title = "a  India (CAMELS-IND)",
           subtitle = sprintf("%d screened, %d paired catchments",
                              nrow(ind_pts), nrow(ind_sel))) +
      map_theme

    us_map <- ggplot2::map_data("state")
    us_pts_conus <- us_pts[lon >= -125 & lon <= -66 & lat >= 24 & lat <= 50]
    us_sel_conus <- us_sel[lon >= -125 & lon <= -66 & lat >= 24 & lat <= 50]
    p_us <- ggplot() +
      geom_polygon(data = us_map, aes(long, lat, group = group),
                   fill = "grey95", colour = "white", linewidth = 0.18) +
      geom_point(data = us_pts_conus, aes(lon, lat), colour = "grey55",
                 size = 1.0, alpha = 0.55) +
      geom_point(data = us_sel_conus, aes(lon, lat), colour = orange, size = 2.1) +
      coord_fixed(1.3, xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) +
      labs(title = "b  USA (Caravan-US, conterminous)",
           subtitle = sprintf("%d screened, %d paired catchments",
                              nrow(us_pts_conus), nrow(us_sel_conus))) +
      map_theme

    p_map <- p_ind + p_us + plot_layout(widths = c(1, 1.25))
    save_fig(p_map, "fig_study_map", 10, 4.2)
  }

  # ---- 2. utilisation screen -----------------------------------------
  if (!is.null(scr) && nrow(scr)) {
    s <- scr[is.finite(rho) & rho > 0]
    s[, region := factor(ifelse(is.na(region), "India", region),
                         levels = c("India", "USA"))]
    p1 <- ggplot(s, aes(rho)) +
      annotate("rect", xmin = P$rho_window[1], xmax = P$rho_window[2],
               ymin = -Inf, ymax = Inf, fill = blue, alpha = 0.12) +
      geom_histogram(bins = 50, fill = grey, colour = "white", linewidth = 0.12) +
      facet_wrap(~region, scales = "free_y", nrow = 1) +
      scale_x_log10(limits = c(0.01, 10), breaks = c(0.01, 0.1, 1, 10)) +
      labs(x = expression("utilisation " * rho == bar(lambda) / bar(mu) *
                            " (log scale)"),
           y = "catchments",
           title = "Utilisation screen: the same window in both regions",
           subtitle = "Shaded band = predeclared admissible window 0.15-1.20; catchments with rho = 0 omitted") +
      base_theme
    save_fig(p1, "fig_utilisation", 8, 3.4)
  }

  # ---- 2. per-gauge paired Brier -------------------------------------
  if (!is.null(paired) && nrow(paired)) {
    d <- paired[is.finite(delta_brier)]
    d[, region := factor(ifelse(is.na(region), "India", region),
                         levels = c("India", "USA"))]
    med <- d[, .(m = median(delta_brier)), by = region]
    p2 <- ggplot(d, aes(delta_brier, region, colour = region)) +
      geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
      geom_jitter(height = 0.14, width = 0, size = 1.1, alpha = 0.55) +
      geom_point(data = med, aes(m, region), size = 3.2, shape = 18) +
      scale_colour_manual(values = c(India = blue, USA = orange), guide = "none") +
      coord_cartesian(xlim = c(-0.06, 0.06)) +
      labs(x = expression(paste(Delta[g], " = Brier(SSI-3) - Brier(SSI-3 + queue)")),
           y = NULL,
           title = "Paired Brier improvement by catchment (primary target SPEI-3)",
           subtitle = "Diamonds = regional medians; values > 0 favour the queue") +
      base_theme
    save_fig(p2, "fig_paired_brier", 8, 3.6)
  }

  # ---- 4. regional summary (primary contrast) ------------------------
  if (!is.null(summ) && nrow(summ)) {
    z <- summ[is.finite(median_delta)]
    z[, region := factor(region, levels = c("India", "USA"))]
    p3 <- ggplot(z, aes(median_delta, region, colour = region)) +
      geom_vline(xintercept = 0, linetype = "dashed", colour = grey) +
      geom_linerange(aes(xmin = boot_lo, xmax = boot_hi), linewidth = 0.7,
                     na.rm = TRUE) +
      geom_point(size = 3) +
      geom_text(aes(label = sprintf("%+.4f", median_delta)),
                vjust = -1.1, size = 2.7, show.legend = FALSE) +
      facet_wrap(~target, nrow = 1, scales = "free_x") +
      scale_colour_manual(values = c(India = blue, USA = orange),
                          guide = "none") +
      labs(x = expression("median paired Brier improvement " * Delta * "Brier"),
           y = NULL,
           title = "One study, two regions, two targets",
           subtitle = "Bars are two-level bootstrap 95% intervals; positive favours the queue") +
      base_theme
    save_fig(p3, "fig_region", 8, 3.2)
  }

  if (!is.null(diff_tab)) {
    cat("Region difference (USA minus India):\n")
    print(diff_tab)
  }
  cat("Figures written to", FIG_DIR, "\n")
  print(list.files(FIG_DIR, pattern = "^fig_(utilisation|paired_brier|region)"))
})
