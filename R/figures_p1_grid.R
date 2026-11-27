# =====================================================================
# R/figures_p1_grid.R -- two summary plates.
#
#   fig_p1_summary_grid  the whole argument on one page: where the data are
#                        (counts), how much memory the state has, how skill
#                        decays, how the paired differences behave, and where
#                        they sit against the harm bound.
#   fig_p1_basin_grid    the same decay curve, small multiples by river basin:
#                        lagged indices against the storage family.
#
# Inputs : paper01/output/p1_storage_params.csv, p1_bss_paired.csv,
#          p1_paired.csv, p1_equivalence.csv, p1_sample_report.csv
# Outputs: paper01/figures/fig_p1_summary_grid.{pdf,png}
#          paper01/figures/fig_p1_basin_grid.{pdf,png}
#
# Usage  : Rscript R/figures_p1_grid.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/figures_p1_grid.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "eval.R", "io.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
  ensure_dir(FIG_DIR)

  pal <- list(blue = "#2C6FBB", orange = "#D1603D", red = "#B23A48",
              purple = "#8C6BB1", green = "#41AB5D", grey = "#6B6B6B")
  fam_cols <- c(climatology = pal$grey, persistence = pal$purple,
                lagged_indices = pal$blue, api = pal$green,
                storage = pal$orange, storage_plus_indices = pal$red)
  th <- theme_minimal(base_size = 8) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 9),
          plot.subtitle = element_text(colour = pal$grey, size = 7),
          legend.position = "none",
          plot.margin = margin(4, 6, 4, 4))
  rd <- function(f) {
    p <- file.path(OUTPUT_DIR, f)
    if (!file.exists(p)) return(NULL)
    fread(p)
  }
  save_fig <- function(p, name, w, h) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w,
           height = h, dpi = 300)
  }

  prm <- rd("p1_storage_params.csv")
  bp <- rd("p1_bss_paired.csv")
  pd <- rd("p1_paired.csv")
  eq <- rd("p1_equivalence.csv")
  scr <- rd("p1_sample_report.csv")
  stopifnot(!is.null(prm), !is.null(bp), !is.null(eq))

  days_per_month <- 30.4
  k_req <- function(h) h * days_per_month / log(4)

  # -------------------------------------------------------------------
  # Plate 1 -- summary grid (3 x 2)
  # -------------------------------------------------------------------
  # (a) sample funnel as a bar chart
  fun <- data.table(
    stage = factor(c("read", "complete months", "T1 events",
                     "storage-scored"),
                   levels = c("read", "complete months", "T1 events",
                              "storage-scored")),
    n = c(nrow(scr), sum(scr$pass_complete, na.rm = TRUE),
          sum(scr$pass_complete & scr$pass_events_t1, na.rm = TRUE),
          sum(scr$pass_complete & scr$pass_events_t1 &
                scr$pass_recession, na.rm = TRUE)))
  p_a <- ggplot(fun, aes(stage, n)) +
    geom_col(fill = pal$blue, width = 0.62) +
    geom_text(aes(label = n), vjust = -0.3, size = 2.4, colour = pal$grey) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
    labs(title = "a  Sample", subtitle = "India, screen stages",
         x = NULL, y = "catchments") +
    th + theme(axis.text.x = element_text(angle = 25, hjust = 1, size = 6.5))

  # (b) recession constant against the requirement of each lead
  req <- data.table(h = c(1, 3, 6, 12), k_need = k_req(c(1, 3, 6, 12)))
  p_b <- ggplot(data.table(k = prm$k_days), aes(k)) +
    geom_histogram(fill = pal$blue, colour = "white", linewidth = 0.15,
                   bins = 28, alpha = 0.85) +
    geom_vline(data = req, aes(xintercept = k_need), colour = pal$red,
               linetype = "dashed", linewidth = 0.35) +
    geom_text(data = req, aes(x = k_need, y = Inf, label = sprintf("%dmo", h)),
              angle = 90, vjust = 1.2, hjust = 1, size = 2.2, colour = pal$red) +
    scale_x_log10(breaks = c(3, 10, 30, 100, 300),
                  labels = c("3", "10", "30", "100", "300")) +
    labs(title = "b  Memory budget", subtitle = "k (days); lines = k needed",
         x = "recession constant k (days, log)", y = "gauges") + th

  # (c) share of gauges with useful memory at each lead
  sh <- data.table(h = P1_LEADS,
                   share = vapply(P1_LEADS, function(h)
                     mean(prm$k_days >= k_req(h), na.rm = TRUE), numeric(1)))
  sh[, lead := factor(sprintf("%d", h), levels = sprintf("%d", P1_LEADS))]
  p_c <- ggplot(sh, aes(lead, share)) +
    geom_col(fill = pal$orange, width = 0.6) +
    geom_text(aes(label = sprintf("%.0f%%", 100 * share)), vjust = -0.3,
              size = 2.3, colour = pal$grey) +
    scale_y_continuous(labels = function(x) sprintf("%.0f%%", 100 * x),
                       expand = expansion(mult = c(0, 0.15))) +
    labs(title = "c  Who has the memory", subtitle = "share with >=25% at the lead",
         x = "lead (months)", y = "share of gauges") + th

  # (d) skill by family and lead, paired benchmark (India, T1)
  sk <- bp[region == "India" & target == "t1",
           .(bss = stats::median(bss, na.rm = TRUE)), by = .(family, lead)]
  sk[, family := factor(family, levels = names(fam_cols))]
  p_d <- ggplot(sk, aes(lead, bss, colour = family, group = family)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = pal$grey,
               linewidth = 0.3) +
    geom_line(linewidth = 0.6) +
    geom_point(aes(size = family == "storage_plus_indices"), show.legend = FALSE) +
    scale_size_manual(values = c(`FALSE` = 1.1, `TRUE` = 2.2)) +
    scale_colour_manual(values = fam_cols) +
    scale_x_continuous(breaks = P1_LEADS) +
    labs(title = "d  Skill decay", subtitle = "median BSS on a common sample",
         x = "lead (months)", y = "BSS vs climatology") + th

  # (e) paired differences against the harm band
  pdd <- pd[region == "India" & target == "t1" & baseline == "bestof" &
              is.finite(delta_brier)]
  pdd[, lead := factor(sprintf("%d", lead), levels = sprintf("%d", P1_LEADS))]
  p_e <- ggplot(pdd, aes(lead, delta_brier)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = -P1_HARM_BOUND,
             ymax = P1_HARM_BOUND, fill = pal$green, alpha = 0.10) +
    geom_hline(yintercept = 0, colour = pal$grey, linewidth = 0.3) +
    geom_violin(fill = "grey92", colour = NA, scale = "width") +
    geom_boxplot(width = 0.12, outlier.size = 0.4, fill = "white",
                 linewidth = 0.3) +
    coord_cartesian(ylim = c(-0.03, 0.03)) +
    labs(title = "e  Paired differences", subtitle = "band = +/- 0.005 Brier",
         x = "lead (months)", y = "dBrier (positive = storage better)") + th

  # (f) equivalence intervals
  e1 <- eq[region == "India" & target == "t1"]
  e1[, lead := factor(sprintf("%d", lead), levels = sprintf("%d", P1_LEADS))]
  p_f <- ggplot(e1, aes(lead)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = -P1_HARM_BOUND,
             ymax = P1_HARM_BOUND, fill = pal$green, alpha = 0.10) +
    geom_hline(yintercept = 0, colour = pal$grey, linewidth = 0.3) +
    geom_errorbar(aes(ymin = lo90, ymax = hi90), width = 0.12,
                  colour = pal$blue, linewidth = 0.5) +
    geom_point(aes(y = median_delta), colour = pal$red, size = 1.8) +
    labs(title = "f  Equivalence", subtitle = "90% interval inside the band",
         x = "lead (months)", y = "dBrier (positive = storage better)") + th

  plate <- (p_a | p_b | p_c) / (p_d | p_e | p_f) +
    plot_annotation(
      title = "Storage-deficit states for seasonal drought forecasting: the whole argument",
      subtitle = paste0("India, CAMELS-IND. The state cannot remember long enough: ",
                        "median recession constant 9 days, a 3-month index boxcar ",
                        "remembers for three months."),
      theme = theme(plot.title = element_text(face = "bold", size = 12),
                    plot.subtitle = element_text(colour = pal$grey, size = 9)))
  save_fig(plate, "fig_p1_summary_grid", 10.5, 6.8)

  # -------------------------------------------------------------------
  # Plate 2 -- basin small multiples
  # -------------------------------------------------------------------
  bp[, gauge_id := as.character(gauge_id)]
  prm[, gauge_id := as.character(gauge_id)]
  pb <- merge(bp[region == "India" & target == "t1" &
                   family %in% c("lagged_indices", "storage_plus_indices")],
              prm[, .(gauge_id, basin)], by = "gauge_id")
  bmed <- pb[, .(bss = stats::median(bss, na.rm = TRUE), n = uniqueN(gauge_id)),
             by = .(basin, lead, family)]
  keep <- bmed[, .(n = max(n)), by = basin][order(-n)][1:12, basin]
  bmed <- bmed[basin %in% keep]
  bmed[, family := factor(family, levels = c("lagged_indices",
                                             "storage_plus_indices"),
                          labels = c("lagged indices", "storage + indices"))]
  p_basin <- ggplot(bmed, aes(lead, bss, colour = family)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = pal$grey,
               linewidth = 0.3) +
    geom_line(linewidth = 0.6) +
    geom_point(size = 1.3) +
    facet_wrap(~basin, ncol = 4, scales = "free_y") +
    scale_colour_manual(values = c("lagged indices" = pal$blue,
                                   "storage + indices" = pal$red),
                        name = NULL) +
    scale_x_continuous(breaks = c(1, 3, 6, 12)) +
    labs(x = "lead (months)", y = "median BSS vs climatology",
         title = "The decay is not a national average: it holds basin by basin",
         subtitle = paste0("Twelve largest basins by catchment count; median BSS ",
                           "on identical months; dashed = climatology")) +
    theme_minimal(base_size = 8) +
    theme(panel.grid.minor = element_blank(),
          legend.position = "bottom",
          plot.title = element_text(face = "bold", size = 11),
          plot.subtitle = element_text(colour = pal$grey, size = 8))
  save_fig(p_basin, "fig_p1_basin_grid", 9.5, 6.2)

  cat("figures_p1_grid.R complete: summary_grid, basin_grid\n")
})
