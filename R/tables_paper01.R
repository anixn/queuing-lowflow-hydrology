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
#   table06_power.csv         sign-test power curve
#   table07_kclass.csv        labelled post-hoc k-class cut (appendix)
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

  # ---- T6: power curve --------------------------------------------------
  pw <- rd("p1_power.csv")
  if (!is.null(pw)) {
    t6 <- pw[n %in% c(50, 100, 150, 200, 300),
             .(region, target, n_gauges_obs,
               sd_delta = signif(sd_delta, 3),
               median_delta_gate = signif(median_delta, 3),
               n, power = signif(power, 2), clears_080)]
    wr(t6, "table06_power.csv")
  }

  # ---- T7: labelled post-hoc k-class cut (appendix) --------------------
  kc <- rd("p1_bss_by_kclass.csv")
  if (!is.null(kc)) {
    t7 <- dcast(kc, family + lead ~ k_class, value.var = "median_bss")
    t7 <- t7[order(lead, family)]
    wr(t7, "table07_kclass.csv")
  }

  cat("tables_paper01.R complete: tables in paper01/tables/\n")
})
