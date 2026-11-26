# =====================================================================
# R/00_utils/eval.R -- scoring, calibration and resampling utilities.
#
# Metrics are implemented from first principles so they can be checked
# against hand-computed toy cases (verification test V12).
# =====================================================================

clip_prob <- function(p, eps = 1e-9) pmin(pmax(p, eps), 1 - eps)

brier_score <- function(y, p) {
  ok <- is.finite(y) & is.finite(p)
  mean((p[ok] - y[ok])^2)
}

log_loss <- function(y, p) {
  ok <- is.finite(y) & is.finite(p)
  p <- clip_prob(p[ok]); y <- y[ok]
  -mean(y * log(p) + (1 - y) * log(1 - p))
}

# Mann-Whitney AUC with tie handling.
auc_score <- function(y, p) {
  ok <- is.finite(y) & is.finite(p)
  y <- y[ok]; p <- p[ok]
  if (length(unique(y)) < 2) return(NA_real_)
  r <- rank(p)
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

brier_skill <- function(y, p, p_ref) {
  1 - brier_score(y, p) / brier_score(y, p_ref)
}

# Fixed reliability bins.
reliability_table <- function(y, p, bins = 10L) {
  ok <- is.finite(y) & is.finite(p)
  y <- y[ok]; p <- p[ok]
  b <- pmin(as.integer(floor(p * bins)), bins - 1L)
  out <- data.frame(
    bin = seq_len(bins) - 1L,
    lower = seq_len(bins) / bins - 1 / bins,
    upper = seq_len(bins) / bins,
    n = 0L, mean_pred = NA_real_, obs_freq = NA_real_
  )
  for (k in seq_len(bins) - 1L) {
    idx <- which(b == k)
    out$n[k + 1L] <- length(idx)
    if (length(idx)) {
      out$mean_pred[k + 1L] <- mean(p[idx])
      out$obs_freq[k + 1L] <- mean(y[idx])
    }
  }
  out
}

# Calibration slope/intercept from regressing y on logit(p).
calibration_slope <- function(y, p) {
  ok <- is.finite(y) & is.finite(p)
  y <- y[ok]; p <- clip_prob(p[ok])
  if (length(unique(y)) < 2) return(c(intercept = NA, slope = NA))
  fit <- tryCatch(stats::glm(y ~ stats::qlogis(p), family = stats::binomial()),
                  error = function(e) NULL)
  if (is.null(fit)) return(c(intercept = NA, slope = NA))
  c(intercept = unname(stats::coef(fit)[1]),
    slope = unname(stats::coef(fit)[2]))
}

# --- Ridge logistic regression (IRLS) --------------------------------
# X must include an intercept column; the intercept is not penalized.
fit_ridge_logistic <- function(X, y, lambda = 1, max_iter = 100L, tol = 1e-8) {
  X <- as.matrix(X); y <- as.numeric(y)
  p <- ncol(X)
  pen <- rep(1, p); pen[1] <- 0            # do not penalize intercept
  beta <- rep(0, p)
  for (iter in seq_len(max_iter)) {
    eta <- as.numeric(X %*% beta)
    mu <- stats::plogis(eta)
    w <- pmax(mu * (1 - mu), 1e-6)
    grad <- as.numeric(crossprod(X, y - mu) - lambda * pen * beta)
    H <- crossprod(X * sqrt(w)) + lambda * diag(pen, p) + diag(1e-8, p)
    step <- tryCatch(solve(H, grad), error = function(e) rep(0, p))
    beta_new <- beta + step
    if (max(abs(step)) < tol) { beta <- beta_new; break }
    beta <- beta_new
  }
  list(beta = beta, converged = max(abs(step)) < 1e-4,
       fitted = stats::plogis(as.numeric(X %*% beta)))
}

predict_ridge_logistic <- function(beta, X) {
  stats::plogis(as.numeric(as.matrix(X) %*% beta))
}

# Calendar-month dummies (11 columns; January is the reference).
month_dummies <- function(month) {
  m <- as.integer(month)
  out <- matrix(0, nrow = length(m), ncol = 11)
  for (k in 2:12) out[, k - 1] <- as.integer(m == k)
  colnames(out) <- sprintf("month_%02d", 2:12)
  out
}

# --- Resampling -------------------------------------------------------
# Paired year-block bootstrap for a per-year statistic.
year_block_bootstrap <- function(year, delta, stat = mean, B = 2000L, seed = 1L) {
  set.seed(seed)
  yrs <- sort(unique(year))
  per_year <- vapply(yrs, function(g) stat(delta[year == g]), numeric(1))
  per_year <- per_year[is.finite(per_year)]
  if (length(per_year) < 2) return(c(estimate = NA, lo = NA, hi = NA))
  est <- stat(per_year)
  draws <- vapply(seq_len(B), function(b) {
    stat(sample(per_year, length(per_year), replace = TRUE))
  }, numeric(1))
  c(estimate = est,
    lo = unname(stats::quantile(draws, 0.025)),
    hi = unname(stats::quantile(draws, 0.975)))
}

# Two-level bootstrap: resample gauges, then years within gauge.
two_level_bootstrap <- function(gauge, year, delta, stat = mean,
                                B = 2000L, seed = 1L) {
  set.seed(seed)
  gauges <- sort(unique(gauge))
  est_g <- vapply(gauges, function(g) {
    d <- delta[gauge == g & is.finite(delta)]
    if (!length(d)) return(NA_real_)
    stat(d)
  }, numeric(1))
  est <- stats::median(est_g, na.rm = TRUE)
  draws <- vapply(seq_len(B), function(b) {
    gs <- sample(gauges, length(gauges), replace = TRUE)
    vals <- vapply(gs, function(g) {
      keep <- gauge == g & is.finite(delta) & !is.na(year)
      d <- delta[keep]
      y <- year[keep]
      if (!length(d)) return(NA_real_)
      yrs <- unique(y)
      if (!length(yrs)) return(NA_real_)
      pick <- sample(yrs, length(yrs), replace = TRUE)
      part <- unlist(lapply(pick, function(yy) d[y == yy]))
      part <- part[is.finite(part)]
      if (!length(part)) return(NA_real_)
      val <- stat(part)
      if (!is.finite(val)) NA_real_ else val
    }, numeric(1))
    vals <- vals[is.finite(vals)]
    if (!length(vals)) NA_real_ else stats::median(vals, na.rm = TRUE)
  }, numeric(1))
  draws <- draws[is.finite(draws)]
  if (length(draws) < 2) {
    return(c(estimate = est, lo = NA_real_, hi = NA_real_))
  }
  c(estimate = est,
    lo = unname(stats::quantile(draws, 0.025)),
    hi = unname(stats::quantile(draws, 0.975)))
}

# One-sided sign test over gauges (improvement = delta > 0).
sign_test <- function(delta) {
  d <- delta[is.finite(delta)]
  n <- length(d); k <- sum(d > 0)
  if (n == 0) return(list(n = 0, k = 0, p = NA_real_, share = NA_real_))
  p <- stats::pbinom(k - 1, n, 0.5, lower.tail = FALSE)
  list(n = n, k = k, p = p, share = k / n)
}
