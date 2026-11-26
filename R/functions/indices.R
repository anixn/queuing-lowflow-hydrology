# =====================================================================
# R/functions/indices.R -- standardized drought indices with training-only
# climatology (the leakage fix, U4).
#
# All standardization is fitted on TRAINING years only. The functions
# return z-scores on the standard normal scale; missing inputs stay NA and
# are never silently filled.
# =====================================================================

# Trailing sum over k months (current month included).
rolling_sum <- function(x, k = 3L) {
  n <- length(x)
  out <- rep(NA_real_, n)
  if (n < k) return(out)
  cs <- c(0, cumsum(ifelse(is.na(x), 0, x)))
  valid <- rep(TRUE, n)
  for (i in seq_len(k)) valid <- valid & !is.na(c(rep(NA, i - 1), x)[seq_len(n)])
  for (i in k:n) {
    window <- x[(i - k + 1):i]
    out[i] <- if (anyNA(window)) NA_real_ else sum(window)
  }
  out
}

# Calendar month (1..12) from a Date vector.
calendar_month <- function(dates) as.integer(format(as.Date(dates), "%m"))

# Standardize x to a z-score using per-calendar-month training moments.
# Returns a vector the same length as x.
standardize_normal_month <- function(x, month, train_mask) {
  stopifnot(length(x) == length(month), length(x) == length(train_mask))
  z <- rep(NA_real_, length(x))
  for (m in 1:12) {
    idx <- which(month == m)
    tr <- idx[train_mask[idx] & is.finite(x[idx])]
    if (length(tr) < 5) next
    mu <- mean(x[tr]); sdv <- stats::sd(x[tr])
    if (!is.finite(sdv) || sdv <= 0) next
    z[idx] <- (x[idx] - mu) / sdv
  }
  z
}

# Gamma-based SPI for one accumulation series, fitted per calendar month
# on training years only. Zero values are handled with a mixed mass at 0.
gamma_spi_month <- function(x, month, train_mask) {
  stopifnot(length(x) == length(month), length(x) == length(train_mask))
  z <- rep(NA_real_, length(x))
  for (m in 1:12) {
    idx <- which(month == m)
    tr <- idx[train_mask[idx] & is.finite(x[idx])]
    if (length(tr) < 8) next
    x_tr <- x[tr]
    p0 <- mean(x_tr <= 0)
    pos <- x_tr[x_tr > 0]
    if (length(pos) < 5) next
    m1 <- mean(pos); v1 <- stats::var(pos)
    if (!is.finite(v1) || v1 <= 0) next
    shape <- m1^2 / v1
    rate <- m1 / v1
    xv <- x[idx]
    f <- ifelse(xv <= 0, p0,
                p0 + (1 - p0) * stats::pgamma(xv, shape = shape, rate = rate))
    f <- pmin(pmax(f, 1e-6), 1 - 1e-6)
    z[idx] <- stats::qnorm(f)
  }
  z
}

# SPI-3 from a monthly precipitation series (mm/month).
spi3 <- function(precip_month, dates, train_mask) {
  acc <- rolling_sum(precip_month, 3L)
  gamma_spi_month(acc, calendar_month(dates), train_mask)
}

# SPI-6: same construction at a 6-month accumulation (memory baseline,
# FQ1 fix, PIVOT.md §3 change 5).
spi6 <- function(precip_month, dates, train_mask) {
  acc <- rolling_sum(precip_month, 6L)
  gamma_spi_month(acc, calendar_month(dates), train_mask)
}

# SPEI-3 proxy: 3-month climatic water balance (P - PET), standardized
# with per-calendar-month training moments.
spei3 <- function(precip_month, pet_month, dates, train_mask) {
  d <- precip_month - pet_month
  acc <- rolling_sum(d, 3L)
  standardize_normal_month(acc, calendar_month(dates), train_mask)
}

# SSI-3 proxy: 3-month accumulation of log(1 + flow), standardized with
# per-calendar-month training moments. Flow must be in m^3/s.
ssi3 <- function(flow_month, dates, train_mask) {
  acc <- rolling_sum(log1p(pmax(flow_month, 0)), 3L)
  standardize_normal_month(acc, calendar_month(dates), train_mask)
}

# SSI-6 proxy: same construction at a 6-month accumulation (memory
# baseline, FQ1 fix, PIVOT.md §3 change 5). Flow must be in m^3/s.
ssi6 <- function(flow_month, dates, train_mask) {
  acc <- rolling_sum(log1p(pmax(flow_month, 0)), 6L)
  standardize_normal_month(acc, calendar_month(dates), train_mask)
}
