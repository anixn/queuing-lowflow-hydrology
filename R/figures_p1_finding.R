# =====================================================================
# R/figures_p1_finding.R -- the figures that carry the argument.
#
#   fig_p1_memory_wall    WHY the storage state cannot work: the fitted
#                         recession constant caps its memory at days, while
#                         a 3-month index boxcar remembers for months, and
#                         the state needs an order of magnitude more memory
#                         than these catchments have.
#   fig_p1_skill_memory   WHERE the skill would have to come from: per-gauge
#                         skill gain vs the gauge's own recession constant,
#                         at the frozen H1 lead. If the mechanism were the
#                         explanation, the slowest gauges would gain most.
#   fig_p1_equivalence    WHAT the null means: every paired interval sits
#                         inside the declared harm bound, i.e. any gain is
#                         smaller than the smallest change an operator would
#                         act on.
#
# Inputs : paper01/output/p1_storage_params.csv
#          paper01/output/p1_bss_paired.csv
#          paper01/output/p1_equivalence.csv
# Outputs: paper01/figures/fig_p1_{memory_wall,skill_memory,equivalence}.{pdf,png}
#
# Usage  : Rscript R/figures_p1_finding.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/figures_p1_finding.R")
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
  base_theme <- theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 10.5),
          plot.subtitle = element_text(colour = pal$grey, size = 8.5),
          legend.position = "none")

  save_fig <- function(p, name, w, h) {
    ggsave(file.path(FIG_DIR, paste0(name, ".pdf")), p, width = w, height = h)
    ggsave(file.path(FIG_DIR, paste0(name, ".png")), p, width = w, height = h,
           dpi = 300)
  }
  rd <- function(f) {
    p <- file.path(OUTPUT_DIR, f)
    if (!file.exists(p)) return(NULL)
    fread(p)
  }

  prm <- rd("p1_storage_params.csv")
  eq <- rd("p1_equivalence.csv")
  bp <- rd("p1_bss_paired.csv")
  if (is.null(prm) || is.null(eq) || is.null(bp)) {
    stop("Run Rscript R/study_p1.R and Rscript R/paired_analysis_p1.R first")
  }

  # The lead a gauge's state can survive: e-folding memory is k days.
  # A linear reservoir retains exp(-h/k); 25% retention needs k = h/ln(4).
  days_per_month <- 30.4
  k_req <- function(h) h * days_per_month / log(4)

  # -------------------------------------------------------------------
  # Fig 1 -- the memory wall (two panels)
  # -------------------------------------------------------------------
  k <- data.table(k_days = prm$k_days, borrowed = prm$borrowed_parameters)
  req <- data.table(h = c(1, 3, 6, 12), k_need = k_req(c(1, 3, 6, 12)))

  p_a <- ggplot(k, aes(x = k_days)) +
    geom_histogram(fill = pal$blue, colour = "white", linewidth = 0.2,
                   bins = 34, alpha = 0.85) +
    geom_vline(data = req, aes(xintercept = k_need), colour = pal$red,
               linetype = "dashed", linewidth = 0.45) +
    geom_text(data = req, aes(x = k_need, y = Inf, label = sprintf("%d mo", h)),
              angle = 90, vjust = 1.4, hjust = 1.05, size = 2.5,
              colour = pal$red) +
    scale_x_log10(breaks = c(3, 10, 30, 100, 300),
                  labels = c("3", "10", "30", "100", "300")) +
    labs(x = "recession constant k (days, log scale)", y = "gauges",
         title = "a  These catchments drain in days",
         subtitle = sprintf(paste0("median k = %.1f d; %.0f%% of %d gauges below 10 d; ",
                                   "slowest %.0f d. Red lines = k needed for 25%% memory at each lead."),
                            stats::median(k$k_days), 100 * mean(k$k_days < 10),
                            nrow(k), max(k$k_days))) +
    base_theme

  # Share of gauges that retain at least a quarter of their memory at each
  # lead. This is the single number that decides whether the method can work.
  share <- data.table(h = P1_LEADS,
                      share = vapply(P1_LEADS, function(h)
                        mean(prm$k_days >= k_req(h), na.rm = TRUE), numeric(1)))
  share[, lead_lab := factor(sprintf("%d mo", h), levels = sprintf("%d mo", P1_LEADS))]
  p_b <- ggplot(share, aes(x = lead_lab, y = share)) +
    geom_col(fill = pal$blue, width = 0.62, alpha = 0.85) +
    geom_text(aes(label = sprintf("%.0f%%", 100 * share)),
              vjust = -0.35, size = 2.7, colour = pal$grey) +
    scale_y_continuous(labels = function(x) sprintf("%.0f%%", 100 * x),
                       limits = c(0, max(0.12, max(share$share) * 1.35))) +
    labs(x = "forecast lead", y = "gauges with useful memory",
         title = "b  almost no gauge qualifies at any lead",
         subtitle = "Share retaining at least 25% of state memory (k >= lead/ln 4)") +
    base_theme

  save_fig(p_a / p_b, "fig_p1_memory_wall", 5.4, 6.6)

  # -------------------------------------------------------------------
  # Fig 2 -- skill gain vs the gauge's own memory (frozen H1 lead)
  # -------------------------------------------------------------------
  h1 <- 3L
  gain <- dcast(bp[region == "India" & target == "t1" & lead == h1 &
                     family %in% c("storage_plus_indices", "lagged_indices")],
                gauge_id ~ family, value.var = "bss")
  if (all(c("storage_plus_indices", "lagged_indices") %in% names(gain))) {
    gain[, gain_bss := storage_plus_indices - lagged_indices]
    gain[, gauge_id := as.character(gauge_id)]
    prm[, gauge_id := as.character(gauge_id)]
    gain <- merge(gain, prm[, .(gauge_id, k_days)], by = "gauge_id")
    gain <- gain[is.finite(gain_bss) & is.finite(k_days)]
    bins <- gain[, .(k_med = stats::median(k_days),
                     g_med = stats::median(gain_bss),
                     n = .N),
                 by = .(k_bin = cut(k_days, breaks = unique(
                   stats::quantile(k_days, probs = seq(0, 1, 0.2))),
                   include.lowest = TRUE))]
    p_s <- ggplot(gain, aes(x = k_days, y = gain_bss)) +
      annotate("rect", xmin = -Inf, xmax = Inf,
               ymin = -P1_HARM_BOUND, ymax = P1_HARM_BOUND,
               fill = pal$green, alpha = 0.10) +
      geom_hline(yintercept = 0, colour = pal$grey, linewidth = 0.4) +
      geom_point(colour = pal$blue, alpha = 0.45, size = 1.1) +
      geom_line(data = bins, aes(x = k_med, y = g_med), colour = pal$red,
                linewidth = 0.8) +
      geom_point(data = bins, aes(x = k_med, y = g_med), colour = pal$red,
                 size = 2.2) +
      coord_cartesian(ylim = c(-0.06, 0.06)) +
      scale_x_log10(breaks = c(3, 10, 30),
                    labels = c("3", "10", "30")) +
      labs(x = "recession constant k (days, log scale)",
           y = "paired BSS gain of storage over lagged indices",
           title = "A weak gradient, but no group reaches a useful gain",
           subtitle = paste0("One point per gauge (n = ", nrow(gain),
                             "); red line = binned median by k quintile; ",
                             "shaded band = +/- ", P1_HARM_BOUND,
                             " Brier. Spearman rho = ",
                             round(stats::cor(gain$k_days, gain$gain_bss,
                                              method = "spearman"), 2),
                             "; slowest quintile median = ",
                             sprintf("%+.4f", bins$g_med[which.max(bins$k_med)]),
                             ". Axis clipped at +/- 0.06 (full range ",
                             sprintf("%+.2f to %+.2f", min(gain$gain_bss),
                                     max(gain$gain_bss)), ").")) +
      base_theme
    save_fig(p_s, "fig_p1_skill_memory", 5.6, 4.2)
  }

  # -------------------------------------------------------------------
  # Fig 3 -- equivalence, not failure
  # -------------------------------------------------------------------
  eq1 <- eq[region == "India" & target == "t1"]
  eq1[, lead_lab := factor(sprintf("%d mo", lead),
                           levels = sprintf("%d mo", sort(unique(lead))))]
  band <- P1_HARM_BOUND
  p_eq <- ggplot(eq1, aes(x = lead_lab)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = -band, ymax = band,
             fill = pal$green, alpha = 0.10) +
    geom_hline(yintercept = 0, colour = pal$grey, linewidth = 0.4) +
    geom_hline(yintercept = c(-band, band), linetype = "dashed",
               colour = pal$red, linewidth = 0.5) +
    geom_errorbar(aes(ymin = lo90, ymax = hi90), width = 0.12,
                  colour = pal$blue, linewidth = 0.7) +
    geom_point(aes(y = median_delta), colour = pal$red, size = 2.6) +
    annotate("text", x = seq_len(nrow(eq1)), y = band * 0.86,
             label = ifelse(eq1$equivalent, "equivalent", "not shown"),
             size = 2.6, colour = pal$green) +
    labs(x = "forecast lead",
         y = "paired Brier difference (positive = storage better)",
         title = "A bounded null, not an unresolved one",
         subtitle = paste0("Median paired difference and 90% bootstrap interval; ",
                           "shaded band = +/- ", band,
                           " Brier, the declared smallest operational change. ",
                           "Leads marked 'exploratory' carry no confirmatory weight.")) +
    base_theme
  save_fig(p_eq, "fig_p1_equivalence", 6.4, 4.0)

  cat("figures_p1_finding.R complete: memory_wall, skill_memory, equivalence\n")
})
