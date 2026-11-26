# =====================================================================
# R/power_check.R -- power analysis for the P1 confirmatory sign test
# (PIVOT.md §4.2, FS2 fix). Reads the GATE G2 paired deltas
# (output/gateG2_paired.csv, written by R/study_gate_g2.R) and computes:
#
#   1. the empirical gauge-level SD of paired dBrier per region/target;
#   2. the sign-test power curve for n in {50, 100, 150, 200, 300} at
#      consistency 0.60 (PIVOT.md §4.1: positive sign in >= 60% of
#      gauges) under the gate effect size;
#   3. whether the projected power at the achieved P1 sample size clears
#      0.80 for the declared effect.
#
# The gate effect size: median paired dBrier of ssi3_plus_queue over the
# frozen best-of baseline on the SPEI-3 target. p_true, the assumed
# probability that a random gauge improves, is derived from a normal
# approximation at the observed median and SD (declared approximation).
#
# Output: output/p1_power.csv (+ JSON sidecar), figures/fig_p1_power.png
# Usage:  Rscript R/power_check.R
# =====================================================================
local({
  root <- normalizePath("D:/Research/queuing-lowflow-hydrology")
  setwd(root); Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "eval.R", "io.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages({library(data.table); library(ggplot2)})
  ensure_dir(OUTPUT_DIR); ensure_dir(FIG_DIR)
  grey <- "#666666"; blue <- "#2c6fbb"; red <- "#d1603d"

  f <- file.path(OUTPUT_DIR, "gateG2_paired.csv")
  if (!file.exists(f)) {
    cat("gateG2_paired.csv not found; run Rscript R/study_gate_g2.R first.\n")
    quit(status = 0, save = "no")
  }
  pd <- fread(f)
  pd <- pd[baseline == "bestof"]
  if (!nrow(pd)) { cat("no bestof rows in gateG2_paired.csv\n"); quit(status = 0) }

  rows <- list()
  for (rg in unique(pd$region)) {
    for (tgt in unique(pd[region == rg]$target)) {
      d <- pd[region == rg & target == tgt & is.finite(delta_brier)]
      if (nrow(d) < 5) next
      sd_g <- stats::sd(d$delta_brier)
      med <- stats::median(d$delta_brier)
      # Normal approximation at the observed effect and SD [assumption].
      p_true <- stats::pnorm(0, mean = med, sd = sd_g, lower.tail = FALSE)
      p_true <- min(max(p_true, 0.5), 0.99)
      for (n in c(50, 100, 150, 200, 300)) {
        k_need <- ceiling(0.60 * n)
        power <- stats::pbinom(k_need - 1, n, p_true, lower.tail = FALSE)
        rows[[length(rows) + 1L]] <- data.table(
          region = rg, target = tgt, n_gauges_obs = nrow(d),
          sd_delta = sd_g, median_delta = med, p_true = p_true,
          n = n, k_needed = k_need, power = power,
          clears_080 = power >= 0.80)
      }
    }
  }
  out <- rbindlist(rows, fill = TRUE)
  write_csv_sidecar(out, file.path(OUTPUT_DIR, "p1_power.csv"))
  cat("Power analysis (sign test at consistency 0.60):\n")
  print(out[n %in% c(100, 200, 300)])

  p <- ggplot(out, aes(factor(n), power, group = interaction(region, target),
                       colour = interaction(region, target))) +
    geom_hline(yintercept = 0.8, linetype = "dashed", colour = grey) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.8) +
    labs(x = "number of scored catchments",
         y = "sign-test power at consistency 0.60",
         colour = "region / target",
         title = "Power for the P1 confirmatory sign test (from the Gate-G2 variance)",
         subtitle = "Dashed line: 0.80 target; effect size and SD from the Gate-G2 paired deltas") +
    theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 11),
          legend.position = "bottom")
  ggsave(file.path(FIG_DIR, "fig_p1_power.png"), p, width = 7.4, height = 4.4,
         dpi = 300)
  ggsave(file.path(FIG_DIR, "fig_p1_power.pdf"), p, width = 7.4, height = 4.4)
  cat("power figure written\n")
})
