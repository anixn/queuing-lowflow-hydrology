# =====================================================================
# R/tables_paper01.R -- formatted tables for Paper 01, written ONLY into
# paper01/tables/ (CSV + JSON sidecar), from output/*.csv produced by the
# verified study scripts. Nothing hand-edited.
#
#   table01_sample.csv        screen stages, India + USA transfer arm
#   table02_storage_params.csv  fitted recession/storage parameters by basin
#   table03_bss.csv           median BSS vs climatology, family x lead x target
#   table04_confirmatory.csv  the frozen confirmatory contrasts H0/H1/H2
#   table05_usa_transfer.csv  descriptive transfer-check contrasts
#   table06_kclass.csv        labelled post-hoc k-class cut (appendix)
#   table07_equivalence.csv   TOST at the declared harm bound
#   table08_bss_paired.csv    skill on one common sample for every family
#   table09_memory.csv        recession constant and retained memory
#
# Usage:  Rscript R/tables_paper01.R
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/tables_paper01.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  source(file.path(root, "R", "config.R"))
  for (u in c("eval.R", "io.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
  suppressMessages(library(data.table))
  TAB_DIR <- file.path(root, "paper01", "tables")
  ensure_dir(TAB_DIR)
  rd <- function(f) {
    p <- file.path(OUTPUT_DIR, f)
    if (!file.exists(p)) return(NULL)
    fread(p)
  }
  wr <- function(df, name) write_csv_sidecar(df, file.path(TAB_DIR, name))

  # ---- T1: sample report ----------------------------------------------
  s1 <- rd("p1_sample_report.csv"); s2 <- rd("p1_sample_report_usa.csv")
  mk_sample <- function(s, region) {
    if (is.null(s)) return(NULL)
    data.table::data.table(
      region = region,
      catchments_read = nrow(s),
      completeness_screens_passed = sum(s$pass_complete),
      t1_events_screen_passed = sum(s$pass_complete & s$pass_events_t1),
      t2_events_screen_passed = sum(s$pass_complete & s$pass_events_t2),
      recession_quality_passed = sum(s$pass_complete & s$pass_events_t1 &
                                       s$pass_recession),
      borrowed_parameters = sum(s$borrowed_parameters))
  }
  t1 <- rbind(mk_sample(s1, "India"), mk_sample(s2, "USA (transfer)"),
              fill = TRUE)
  wr(t1, "table01_sample.csv")

  # ---- T2: storage parameters by basin (India) ------------------------
  p <- rd("p1_storage_params.csv")
  if (!is.null(p)) {
    t2 <- p[!is.na(k_days) & !is.na(S_cap_mm) & S_cap_mm > 0,
            .(gauges = .N,
              median_k_days = signif(stats::median(k_days), 3),
              median_S_cap_mm = signif(stats::median(S_cap_mm), 3),
              median_BFI = signif(stats::median(BFI), 3),
              median_zero_frac = signif(stats::median(zero_frac), 3)),
            by = basin][order(-gauges)]
    t2_all <- p[!is.na(k_days) & !is.na(S_cap_mm) & S_cap_mm > 0,
                .(basin = "ALL INDIA",
                  gauges = .N,
                  median_k_days = signif(stats::median(k_days), 3),
                  median_S_cap_mm = signif(stats::median(S_cap_mm), 3),
                  median_BFI = signif(stats::median(BFI), 3),
                  median_zero_frac = signif(stats::median(zero_frac), 3))]
    t2 <- rbind(t2_all, t2)
    wr(t2, "table02_storage_params.csv")
  }

  # ---- T3: median BSS by family x lead x target ------------------------
  bss <- rd("p1_bss.csv")
  if (!is.null(bss)) {
    b <- bss[is.finite(bss)]
    t3 <- b[, .(median_BSS = signif(stats::median(bss), 3),
                n_gauges = .N,
                IQR_BSS_lo = signif(stats::quantile(bss, 0.25, names = FALSE), 3),
                IQR_BSS_hi = signif(stats::quantile(bss, 0.75, names = FALSE), 3)),
            by = .(family, lead, target)]
    t3 <- t3[order(target, lead, family)]
    wr(t3, "table03_bss.csv")
  }

  # ---- T4: the frozen confirmatory contrasts ---------------------------
  cf <- rd("p1_confirmatory.csv")
  if (!is.null(cf)) {
    t4 <- cf[, .(hypothesis, lead, n_gauges = n,
                 median_delta = signif(median_delta, 3),
                 CI = sprintf("[%+.4f, %+.4f]", boot_lo, boot_hi),
                 sign_positive = sprintf("%d/%d", sign_k, sign_n),
                 sign_share = signif(sign_share, 3),
                 sign_p = signif(sign_p, 2),
                 verdict)]
    wr(t4, "table04_confirmatory.csv")
  }

  # ---- T5: USA transfer check (descriptive) ----------------------------
  us <- rd("p1_summary_usa.csv")
  if (!is.null(us) && nrow(us)) {
    t5 <- us[baseline == "bestof", .(
      target, lead, n_gauges = n,
      median_delta = signif(median_delta, 3),
      sign_positive = sprintf("%d/%d", sign_k, sign_n),
      sign_share = signif(sign_share, 3),
      sign_p = signif(sign_p, 2))]
    wr(t5, "table05_usa_transfer.csv")
  }

  # ---- T6: labelled post-hoc k-class cut (appendix) ---------------------
  kc <- rd("p1_bss_by_kclass.csv")
  if (!is.null(kc)) {
    t7 <- dcast(kc, family + lead ~ k_class, value.var = "median_bss")
    t7 <- t7[order(lead, family)]
    wr(t7, "table06_kclass.csv")
  }

  # ---- T7: equivalence at the declared harm bound ----------------------
  eq <- rd("p1_equivalence.csv")
  if (!is.null(eq) && nrow(eq)) {
    t8 <- eq[, .(region, lead, role, n_gauges, n_months,
                 margin = signif(margin, 3),
                 median_delta = signif(median_delta, 3),
                 ci90 = sprintf("[%+.4f, %+.4f]", lo90, hi90),
                 ci95 = sprintf("[%+.4f, %+.4f]", lo95, hi95),
                 p_tost = signif(p_tost, 2), equivalent)]
    wr(t8, "table07_equivalence.csv")
  }

  # ---- T8: paired skill benchmark (one sample for every family) --------
  bp <- rd("p1_bss_paired.csv")
  if (!is.null(bp) && nrow(bp)) {
    sm <- bp[, .(bss = signif(stats::median(bss, na.rm = TRUE), 3),
                 n = uniqueN(gauge_id)),
             by = .(region, target, lead, family)]
    t9 <- dcast(sm, region + target + lead ~ family, value.var = "bss")
    t9 <- t9[order(region, target, lead)]
    wr(t9, "table08_bss_paired.csv")
  }

  # ---- T9: the memory budget -------------------------------------------
  prm <- rd("p1_storage_params.csv")
  if (!is.null(prm) && nrow(prm)) {
    kd <- prm$k_days[is.finite(prm$k_days)]
    q <- stats::quantile(kd, c(0.05, 0.25, 0.5, 0.75, 0.95), names = FALSE)
    t10 <- data.table(statistic = c("n gauges", "k p05 (d)", "k p25 (d)",
                                    "k median (d)", "k p75 (d)", "k p95 (d)",
                                    "max k (d)", "share k < 10 d",
                                    "share k < 30 d"))
    t10[, value := c(nrow(prm), signif(q, 3), signif(max(kd), 3),
                     signif(mean(kd < 10), 3), signif(mean(kd < 30), 3))]
    t10 <- rbind(t10, data.table(
      statistic = sprintf("median memory retained at %d mo", P1_LEADS),
      value = signif(vapply(P1_LEADS, function(h)
        stats::median(exp(-h * 30.4 / kd)), numeric(1)), 3)))
    wr(t10, "table09_memory.csv")
  }

  cat("tables_paper01.R complete: tables in paper01/tables/\n")
})
