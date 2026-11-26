# =====================================================================
# R/verify.R -- the verification battery (gate G1). Exit code 1 on failure.
#
# Usage:  Rscript R/verify.R
#
# The 14 checks are defined below; each either passes or stops with a
# message. V1-V4 pin the queue engine against exact solutions, V5 the
# discrete-event simulation, V6-V14 the units, indices, metrics, IO,
# zero classifier and gap rule.
# =====================================================================

local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/verify.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  source(file.path(root, "R", "config.R"))
  suppressMessages(library(data.table))
  for (u in c("units.R", "queue_engine.R", "indices.R", "eval.R", "io.R",
              "audit.R", "pipeline.R")) {
    source(file.path(root, "R", "functions", u))
  }
# =====================================================================
# R/verify.R -- the 14-test verification battery (plan ┬º6).
#
# Each test is a function returning a one-row data frame. A test either
# passes or stops with an informative message. run_verification() runs
# all of them and prints a summary table.
# =====================================================================

verif_result <- function(id, name, pass, detail) {
  data.frame(id = id, test = name, pass = isTRUE(pass), detail = detail,
             stringsAsFactors = FALSE)
}

# V1: stationary vs M/M/1/K closed form.
v01_mm1k <- function() {
  lam <- 1.3; mu <- 2.0; K <- 12
  cfg <- queue_config(q_star = 3, K = K, c = 1, theta = 1, alpha = 1, eta = 0)
  pi_num <- stationary(lam, mu, cfg)
  rho <- lam / mu
  n <- 0:K
  pi_ref <- if (abs(rho - 1) < 1e-12) rep(1 / (K + 1), K + 1) else
    (1 - rho) * rho^n / (1 - rho^(K + 1))
  d <- max(abs(pi_num - pi_ref))
  verif_result("V1", "M/M/1/K closed form", d < 1e-10,
               sprintf("max abs diff = %.3e", d))
}

# V2: stationary vs M/M/c/K closed form.
v02_mmc <- function() {
  lam <- 3.1; mu <- 2.0; c <- 2L; K <- 15
  cfg <- queue_config(q_star = 4, K = K, c = c, theta = 1, alpha = 1, eta = 0)
  pi_num <- stationary(lam, mu, cfg)
  n <- 0:K
  loga <- numeric(K + 1)
  for (i in 0:K) {
    loga[i + 1] <- if (i <= c) i * log(lam / mu) - lgamma(i + 1) else
      i * log(lam / mu) - lgamma(c + 1) - (i - c) * log(c)
  }
  a <- exp(loga - max(loga))
  pi_ref <- a / sum(a)
  d <- max(abs(pi_num - pi_ref))
  verif_result("V2", "M/M/c/K closed form", d < 1e-10,
               sprintf("max abs diff = %.3e", d))
}

# V3: stationary with eta/alpha vs long RK4 run.
v03_rk4_stationary <- function() {
  lam <- 0.8; mu <- 1.0
  cfg <- queue_config(q_star = 6, K = 20, c = 1, theta = 8, alpha = 1.5, eta = 1 / 60)
  pi_ref <- stationary(lam, mu, cfg)
  e_ref <- sum((0:cfg$K) * pi_ref)
  p <- numeric(cfg$K + 1); p[1] <- 1
  cfg_fast <- cfg; cfg_fast$rk4_dt <- 0.5; cfg_fast$rk4_maxrate <- 2.0
  for (i in 1:5000) p <- rk4_day(p, lam, mu, cfg_fast)$p
  e_num <- sum((0:cfg$K) * p)
  d <- abs(e_num - e_ref)
  verif_result("V3", "RK4 converges to stationary", d < 1e-3,
               sprintf("|E_Q diff| = %.3e", d))
}

# V4: transient RK4 vs DES on a seasonal cycle.
v04_rk4_des <- function() {
  days <- 20000
  t <- seq_len(days)
  lam <- 0.6 + 0.3 * sin(2 * pi * t / 365)
  mu <- 0.9 + 0.2 * cos(2 * pi * t / 365)
  cfg <- queue_config(q_star = 6, K = 20, c = 1, theta = 8, alpha = 1.5, eta = 1 / 60)
  p <- numeric(cfg$K + 1); p[1] <- 1
  e_rk <- numeric(days)
  for (i in seq_len(days)) {
    p <- rk4_day(p, lam[i], mu[i], cfg)$p
    e_rk[i] <- sum((0:cfg$K) * p)
  }
  des <- des_run(lam, mu, cfg, seed = 42, max_events = 3e5, warmup = days / 2)
  e_des <- unname(des["E_Q"])
  e_rk_mean <- mean(e_rk[(days / 2 + 1):days])
  rel <- abs(e_rk_mean - e_des) / max(e_rk_mean, 1e-9)
  verif_result("V4", "RK4 vs thinning DES (seasonal)",
               rel < 0.02,
               sprintf("RK4 %.4f vs DES %.4f (rel %.2f%%, %d events)",
                       e_rk_mean, e_des, 100 * rel, as.integer(des["events"])))
}

# V5: conservation ledger on a full seasonal run.
v05_ledger <- function() {
  days <- 730
  t <- seq_len(days)
  lam <- 0.7 + 0.3 * sin(2 * pi * t / 365)
  mu <- 0.95 + 0.15 * cos(2 * pi * t / 365)
  cfg <- queue_config(q_star = 6, K = 20, c = 1, theta = 8, alpha = 1.5, eta = 1 / 60)
  out <- run_queue(as.Date("2000-01-01") + 0:729, lam, mu, cfg)
  res <- attr(out, "max_ledger_residual")
  verif_result("V5", "Conservation ledger every day", res < 1e-6,
               sprintf("max per-day residual = %.3e", res))
}

# V6: first passage vs simulated hitting times.
v06_first_passage <- function() {
  lam <- 1.0; mu <- 1.2
  cfg <- queue_config(q_star = 4, K = 15, c = 1, theta = 6, alpha = 1.5, eta = 1 / 60)
  m_theory <- first_passage_mean(lam, mu, cfg, q_star = cfg$q_star)
  set.seed(7)
  reps <- 2000
  hit <- numeric(reps)
  for (r in seq_len(reps)) {
    n <- cfg$q_star; tt <- 0
    while (n > 0) {
      b <- birth_n(n, lam, cfg); d <- death_n(n, mu, cfg)
      tt <- tt + rexp(1, b + d)
      n <- if (runif(1) < b / (b + d)) n + 1L else n - 1L
    }
    hit[r] <- tt
  }
  se <- stats::sd(hit) / sqrt(reps)
  ok <- abs(mean(hit) - m_theory) < 2 * se
  verif_result("V6", "First passage vs simulation", ok,
               sprintf("theory %.3f vs sim %.3f (2SE %.3f)",
                       m_theory, mean(hit), 2 * se))
}

# V7: blocking guard behaviour.
v07_blocking <- function() {
  cfg <- queue_config(q_star = 5, K = 8, c = 1, theta = 7, alpha = 1.5, eta = 1 / 60)
  pi <- stationary(3.0, 1.0, cfg)          # heavily overloaded, tiny K
  g <- check_blocking(pi[cfg$K + 1], cfg)
  ok <- !g$ok && g$suggested_K > cfg$K
  verif_result("V7", "Blocking guard triggers rerun", ok,
               sprintf("P(Q=K)=%.3e, suggested K=%d", g$p_eq_K, g$suggested_K))
}

# V8: unit wall on real attributes for three gauges.
v08_unit_wall <- function() {
  attrs <- read_camels_attributes()
  ids <- intersect(c(4026L, 4064L, 3001L), attrs$gauge_id)
  if (length(ids) < 3) ids <- attrs$gauge_id[1:3]
  area_km2 <- attrs$cwc_area[match(ids, attrs$gauge_id)]
  area_m2 <- area_km2 * 1e6
  v_claim <- claim_volume_m3(P$d_mm, area_m2)
  # Demand and supply share the same claim volume within a gauge.
  lam <- demand_claims(2, P$d_mm)
  mu <- supply_claims(500, area_m2, P$s_firm, P$cap_mm, P$d_mm)
  same_within <- all(is.finite(v_claim)) &&
    isTRUE(all.equal(lam, 2 / P$d_mm))
  differs_across <- length(unique(round(v_claim))) == length(v_claim)
  verif_result("V8", "Unit wall: one claim volume per gauge",
               same_within && differs_across,
               sprintf("claim volumes (m3): %s",
                       paste(signif(v_claim, 4), collapse = ", ")))
}

# V9: FAO-56 radiation and the 0.408 conversion.
v09_hargreaves <- function() {
  ra_eq <- extraterrestrial_radiation(0, 80)   # equator, near equinox
  ref <- 37.8                                   # MJ m^-2 day^-1, textbook value
  rel <- abs(ra_eq - ref) / ref
  # The 0.408 factor must be present: ET0 scales linearly with Ra_mm.
  et <- hargreaves_et0(30, 20, 25, ra_mj = 100)
  manual <- 0.0023 * (25 + 17.8) * sqrt(10) * (0.408 * 100)
  ok <- rel < 0.01 && abs(et - manual) < 1e-12
  verif_result("V9", "Hargreaves with 0.408 conversion", ok,
               sprintf("Ra(0,80)=%.3f (ref %.1f, %.2f%%); ET0 factor exact",
                       ra_eq, ref, 100 * rel))
}

# V10: catchment-relative thresholds scale with mean demand.
v10_thresholds <- function() {
  a <- thresholds_from_lambda(0.1)
  b <- thresholds_from_lambda(0.2)
  c2 <- thresholds_from_lambda(0.1)
  ok <- identical(a, c2) && b$q_star >= a$q_star && b$K >= a$K
  verif_result("V10", "Catchment-relative thresholds", ok,
               sprintf("lam .1 -> q*=%d K=%d; lam .2 -> q*=%d K=%d",
                       a$q_star, a$K, b$q_star, b$K))
}

# V11: indices on a controlled gamma series.
v11_indices <- function() {
  set.seed(11)
  x <- stats::rgamma(360, shape = 2, rate = 0.5)
  month <- rep(1:12, 30)
  train <- rep(TRUE, 360)
  z <- gamma_spi_month(x, month, train)
  # Direct recomputation for month 1.
  idx <- which(month == 1)
  m1 <- mean(x[idx]); v1 <- stats::var(x[idx])
  shape <- m1^2 / v1; rate <- m1 / v1
  direct <- stats::qnorm(stats::pgamma(x[idx], shape, rate))
  d <- max(abs(z[idx] - direct))
  # Standardization on training has approximately zero mean.
  zs <- standardize_normal_month(x, month, train)
  ok <- d < 1e-10 && abs(mean(zs)) < 1e-8
  verif_result("V11", "SPI/standardization helpers", ok,
               sprintf("max direct diff = %.3e; mean z = %.2e", d, mean(zs)))
}

# V12: metrics on hand-computed toy cases.
v12_metrics <- function() {
  y <- c(0, 0, 1, 1)
  p <- c(0.1, 0.4, 0.35, 0.8)
  b <- brier_score(y, p)
  b_ref <- mean((p - y)^2)
  ll <- log_loss(y, p)
  ll_ref <- -mean(y * log(p) + (1 - y) * log(1 - p))
  a <- auc_score(y, p)
  a_ref <- 0.75
  d <- max(abs(c(b - b_ref, ll - ll_ref, a - a_ref)))
  verif_result("V12", "Brier/AUC/logloss hand cases", d < 1e-12,
               sprintf("max diff = %.3e", d))
}

# V13: zero classifier on a crafted fixture.
v13_zero_classifier <- function() {
  q <- c(5, 0, 0, 0, NA, 2)
  peer <- c(0.8, 0.9, 0.1, NA, 0.5, 0.7)
  cls <- classify_zeros(q, peer)
  ref <- c("positive", "artifact", "real-zero", "unknown", "missing", "positive")
  ok <- identical(cls, ref)
  verif_result("V13", "Zero classifier labels", ok,
               paste(cls, collapse = ","))
}

# V14: gap rule (short pause vs long exclusion, no silent fill).
v14_gap_rule <- function() {
  dates <- as.Date("2000-01-01") + 0:399
  q <- rep(1, 400)
  q[100:105] <- NA          # 6-day short gap
  q[200:399] <- NA          # 200-day long gap
  g <- mark_gaps(dates, is.na(q), max_short_gap = 7, long_gap_exclusion = 30)
  short_ok <- all(g$pause[100:105]) && !any(g$missing_unresolved[100:105])
  long_ok <- all(g$missing_unresolved[200:399]) &&
    all(g$exclude_month[200:399])
  no_fill <- !any(g$pause & g$missing_unresolved)
  ok <- short_ok && long_ok && no_fill
  verif_result("V14", "Gap rule: pause vs exclude, no fill", ok,
               sprintf("short pause=%d days; long excluded=%d days",
                       sum(g$pause), sum(g$exclude_month)))
}

# V15: the common rate builder and screen (both regions, one definition).
v15_common_rates <- function() {
  n <- 400
  d <- seq(as.Date("1981-01-01"), by = "day", length.out = n)
  r <- common_rates(1L, d, rep(10, n), rep(1, n), rep(30, n), rep(20, n),
                    rep(25, n), 1000, 20)
  ra <- extraterrestrial_radiation(20, as.integer(format(d, "%j")))
  et0 <- hargreaves_et0(rep(30, n), rep(20, n), rep(25, n), ra)
  need <- pmax(P$Kc * et0 - P$phi * 1, 0)
  mu1 <- 10 * 86400 * P$s_firm / (P$f_irr * 1000 * 1e6) * 1000 / P$d_mm
  r2 <- common_rates(2L, d, rep(10, n), rep(1, n), rep(30, n), rep(20, n),
                     rep(25, n), 2000, 20)
  ok_et0 <- max(abs(r$pet_mm - et0)) < 1e-10
  ok_need <- max(abs(r$need_mm - need)) < 1e-10
  ok_mu <- max(abs(r$mu - mu1)) < 1e-10
  ok_area <- max(abs(r2$mu - mu1 / 2)) < 1e-10
  sc <- common_screen(r, "test")
  ok_screen <- is.finite(sc$rho) && "in_window" %in% names(sc)
  ok <- ok_et0 && ok_need && ok_mu && ok_area && ok_screen
  verif_result("V15", "Common rates and screen (both regions)", ok,
               sprintf("ET0 %.1e; need %.1e; mu %.1e; area-halving %.1e",
                       max(abs(r$pet_mm - et0)), max(abs(r$need_mm - need)),
                       max(abs(r$mu - mu1)), max(abs(r2$mu - mu1 / 2))))
}

run_verification <- function(verbose = TRUE) {
  tests <- list(
    v01_mm1k, v02_mmc, v03_rk4_stationary, v04_rk4_des, v05_ledger,
    v06_first_passage, v07_blocking, v08_unit_wall, v09_hargreaves,
    v10_thresholds, v11_indices, v12_metrics, v13_zero_classifier,
    v14_gap_rule, v15_common_rates
  )
  res <- do.call(rbind, lapply(tests, function(f) {
    out <- tryCatch(f(), error = function(e) {
      verif_result("ERR", deparse(substitute(f)), FALSE, conditionMessage(e))
    })
    if (verbose) {
      cat(sprintf("%-4s %-42s %s  %s\n", out$id, out$test,
                  if (out$pass) "PASS" else "FAIL", out$detail))
    }
    out
  }))
  res
}

  cat("Verification battery (gate G1)\n")
  cat("----------------------------------------\n")
  res <- run_verification(verbose = TRUE)
  cat("----------------------------------------\n")
  cat(sprintf("%d/%d passed\n", sum(res$pass), nrow(res)))
  if (!all(res$pass)) {
    cat("FAILED:", paste(res$id[!res$pass], collapse = ", "), "\n")
    quit(status = 1, save = "no")
  }
})