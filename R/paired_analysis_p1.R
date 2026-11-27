# =====================================================================
# R/paired_analysis_p1.R -- equivalence test and paired skill benchmark.
#
# Two analyses that the confirmatory table does not provide:
#
#   (1) EQUIVALENCE. The protocol declares a harm bound: a per-gauge Brier
#       change smaller than P1_HARM_BOUND (0.005) is not operationally
#       meaningful. "H1 FAIL" only says the improvement is not detected;
#       it does not say the improvement is small. This script answers the
#       stronger question with a two-one-sided-test (TOST) on the same
#       two-level bootstrap used for the confirmatory intervals: is the
#       paired difference provably inside +/- the harm bound? Equivalence
#       is declared when the 90% bootstrap interval lies strictly inside
#       (-margin, +margin), which is the interval form of two one-sided
#       tests at 5% each.
#
#   (2) PAIRED BENCHMARK. The headline skill table (p1_bss.csv) computes
#       each family's Brier skill score on that family's own complete-case
#       months, so the columns are not strictly comparable. This script
#       recomputes every family on the months where ALL families have a
#       prediction for that gauge, so the benchmark is a like-for-like
#       comparison. AGENTS.md rule 10: only the paired statistic may carry
#       a comparative claim.
#
# Inputs : paper01/output/p1_predictions{,_usa}.csv
#          paper01/output/p1_bestof_selection{,_usa}.csv
# Outputs: paper01/output/p1_equivalence.csv      (+ sidecar)
#          paper01/output/p1_bss_paired.csv        (+ sidecar)
#
# Usage  : Rscript R/paired_analysis_p1.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/paired_analysis_p1.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  Sys.setenv(QDJ_ROOT = root)
  source(file.path(root, "R", "config.R"))
  for (u in c("units.R", "eval.R", "io.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages(library(data.table))

  MARGIN <- P1_HARM_BOUND
  FAMILIES <- c("climatology", "persistence", "lagged_indices", "api",
                "storage", "storage_plus_indices")
  A_FAM <- "storage_plus_indices"
  B_FAM <- "bestof"

  # ---- 1. Equivalence ------------------------------------------------
  # Pair the confirmatory family with the frozen per-gauge best baseline
  # on IDENTICAL held-out months, exactly as the confirmatory table does.
  equivalence_region <- function(preds, sel, region) {
    rows <- list()
    for (h in P1_LEADS) {
      px <- preds[target == "t1" & lead == h]
      bg <- sel[target == "t1" & lead == h]
      if (!nrow(px) || !nrow(bg)) next
      pb <- merge(px, bg, by = "gauge_id")
      base <- pb[family == best_family, .(gauge_id, date, year, y, p_base = p)]
      fam <- pb[family == A_FAM, .(gauge_id, date, p_fam = p)]
      m <- merge(base, fam, by = c("gauge_id", "date"))
      if (!nrow(m)) next
      # The bootstrap indexes gauges by name; the CSV reader may return
      # integer ids, so make the type explicit here.
      m[, gauge_id := as.character(gauge_id)]
      # Sign convention identical to the study backbone (stage7_paired_stats):
      # delta = Brier(baseline) - Brier(storage family), so POSITIVE means the
      # storage family is better. Keeping one convention across every table
      # and figure is what stops a sign being read the wrong way.
      m[, delta := (p_base - y)^2 - (p_fam - y)^2]
      bt <- two_level_bootstrap_fast(m$gauge_id, m$year, m$delta,
                                     stat = stats::median, B = P1_BOOT_B,
                                     seed = P$seed, return_draws = TRUE)
      draws <- bt$draws
      if (length(draws) < 2) next
      q90 <- stats::quantile(draws, c(0.05, 0.95), names = FALSE)
      q95 <- stats::quantile(draws, c(0.025, 0.975), names = FALSE)
      # TOST: H0_lower delta <= -margin, H0_upper delta >= +margin.
      p_lower <- mean(draws <= -MARGIN)
      p_upper <- mean(draws >= MARGIN)
      rows[[length(rows) + 1L]] <- data.table(
        region = region, target = "t1", lead = h,
        n_gauges = uniqueN(m$gauge_id), n_months = nrow(m),
        margin = MARGIN,
        median_delta = bt$estimate,
        lo90 = q90[1], hi90 = q90[2], lo95 = q95[1], hi95 = q95[2],
        p_lower = p_lower, p_upper = p_upper,
        p_tost = max(p_lower, p_upper),
        equivalent = (q90[1] > -MARGIN) && (q90[2] < MARGIN),
        # The frozen confirmatory leads are labelled; 2 and 12 are the
        # declared post-hoc extension and can never carry a claim.
        role = if (h %in% P1_LEADS_FROZEN) "frozen lead" else
          "exploratory lead")
    }
    rbindlist(rows, fill = TRUE)
  }

  # ---- 2. Paired benchmark -------------------------------------------
  # Every family scored on the intersection of months where all families
  # have a prediction, per gauge. The climatology reference is computed on
  # that same intersection, so every BSS in the table shares one sample.
  paired_bss_region <- function(preds, region) {
    out <- list()
    for (tgt in c("t1", "t2")) {
      for (h in P1_LEADS) {
        px <- preds[target == tgt & lead == h]
        if (!nrow(px)) next
        w <- data.table::dcast(px[, .(gauge_id, date, y, family, p)],
                               gauge_id + date + y ~ family, value.var = "p")
        fam_here <- intersect(FAMILIES, names(w))
        if (!all(c("climatology", A_FAM) %in% fam_here)) next
        w <- w[stats::complete.cases(w[, c(fam_here, "y"), with = FALSE])]
        if (!nrow(w)) next
        w[, brier_clim := (climatology - y)^2]
        for (fm in fam_here) {
          w[, brier_fam := (get(fm) - y)^2]
          g <- w[, .(n_months = .N,
                     brier = mean(brier_fam),
                     brier_clim = mean(brier_clim)),
                 by = gauge_id]
          g[, `:=`(family = fm, region = region, target = tgt, lead = h,
                   role = if (h %in% P1_LEADS_FROZEN) "frozen lead" else
                     "exploratory lead")]
          g[, bss := 1 - brier / brier_clim]
          out[[length(out) + 1L]] <- g
        }
      }
    }
    rbindlist(out, fill = TRUE)
  }

  # ---- run ------------------------------------------------------------
  ind_pred <- file.path(OUTPUT_DIR, "p1_predictions.csv")
  ind_sel <- file.path(OUTPUT_DIR, "p1_bestof_selection.csv")
  if (!file.exists(ind_pred) || !file.exists(ind_sel)) {
    stop("Missing p1_predictions.csv or p1_bestof_selection.csv; ",
         "run Rscript R/study_p1.R first", call. = FALSE)
  }
  eq <- equivalence_region(fread(ind_pred), fread(ind_sel), "India")
  pbss <- paired_bss_region(fread(ind_pred), "India")

  us_pred <- file.path(OUTPUT_DIR, "p1_predictions_usa.csv")
  us_sel <- file.path(OUTPUT_DIR, "p1_bestof_selection_usa.csv")
  if (file.exists(us_pred) && file.exists(us_sel)) {
    eq <- rbind(eq, equivalence_region(fread(us_pred), fread(us_sel), "USA"),
                fill = TRUE)
    pbss <- rbind(pbss, paired_bss_region(fread(us_pred), "USA"), fill = TRUE)
  }

  write_csv_sidecar(eq, file.path(OUTPUT_DIR, "p1_equivalence.csv"))
  write_csv_sidecar(pbss, file.path(OUTPUT_DIR, "p1_bss_paired.csv"))

  cat("\n=== Equivalence at the declared harm bound (median delta",
      MARGIN, ") ===\n")
  print(eq[, .(region, lead, role, n_gauges,
               median_delta = round(median_delta, 4),
               ci90 = sprintf("[%+.4f, %+.4f]", lo90, hi90),
               p_tost = signif(p_tost, 2), equivalent)])

  cat("\n=== Paired benchmark: median BSS on identical months ===\n")
  sm <- pbss[, .(bss = round(stats::median(bss, na.rm = TRUE), 3),
                 n = uniqueN(gauge_id)), by = .(region, target, lead, family)]
  print(data.table::dcast(sm, region + target + lead ~ family,
                          value.var = "bss"))
  cat("\npaired_analysis_p1.R complete; outputs in paper01/output/\n")
})
