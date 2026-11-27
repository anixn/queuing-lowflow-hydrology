# =====================================================================
# R/functions/storage_engine.R -- the P1 fluid storage engine (PIVOT.md
# §4.4). Units: every rate is mm/day of depth over the whole catchment;
# storage S is mm of depth. Observed discharge NEVER enters as a daily
# input: Q enters only through recession parameters fitted on the
# training years (k, exponent p, release coefficient K_a) and through the
# censored zero-flow indicator (PIVOT.md §4.2). No claims, no hectares,
# no reneging/boost/blocking -- the M/M/1/K artefacts (FQ2) are gone.
#
#   Fitted per gauge (training years only):
#     bfi_lyne_hollick()   baseflow index [assumption: alpha = 0.925]
#     recession_segments() censored recession segments
#     fit_recession()      k (days), exponent p, release law a
#     fit_storage_scale()  S_cap (mm) from the low-flow envelope
#   Propagated daily:
#     propagate_storage()  Moran-type fluid balance with a per-day ledger
#
# Successor of the conservation ledger: the per-day identity
#   S(t+1) - S(t) = Pe - Ea - Q_g - overflow + deficit
# holds to floating point; R/verify.R fails above 1e-9.
# =====================================================================

# --- Baseflow index ---------------------------------------------------
# Lyne-Hollick single-pass digital filter on daily flow (mm/day), with
# the standard smoothing constraint b(t) <= q(t) (the raw filter can
# exceed the observed flow and produce BFI > 1).
# b(t) = min(alpha * b(t-1) + (1 - alpha) * q(t), q(t)), seeded with the
# first FINITE flow (a leading gap must not poison the filter; NA days
# are skipped without updating the state).
# BFI = sum(b) / sum(q) over the requested rows (NA rows excluded).
bfi_lyne_hollick <- function(q_mm, alpha = 0.925, mask = NULL) {
  assert_true(alpha >= 0 && alpha < 1, "Lyne-Hollick alpha must lie in [0,1)")
  q <- as.numeric(q_mm)
  n <- length(q)
  b <- rep(NA_real_, n)
  prev <- NA_real_
  for (i in seq_len(n)) {
    if (is.finite(q[i])) {
      if (is.na(prev)) prev <- q[i]
      else prev <- min(alpha * prev + (1 - alpha) * q[i], q[i])
      b[i] <- prev
    }
  }
  ok <- if (is.null(mask)) is.finite(q) & is.finite(b) else
    is.finite(q) & is.finite(b) & mask
  if (sum(q[ok], na.rm = TRUE) <= 0) return(NA_real_)
  sum(b[ok]) / sum(q[ok])
}

# --- Recession segments ------------------------------------------------
# A recession segment is a run of >= min_len consecutive days in which the
# daily flow change is strictly negative, no day is a rain day
# (prcp > rain_mm; the threshold is a declared config value,
# P1_RAIN_DAY_MM = 5 mm/day), and no day or predecessor day is a recorded
# zero (zero-flow censoring, PIVOT.md §4.2). Segments are identified
# inside the mask (training years) only.
recession_segments <- function(q_mm, prcp_mm, mask = NULL,
                               min_len = 10L, rain_mm = 1.0) {
  q <- as.numeric(q_mm); pr <- as.numeric(prcp_mm)
  n <- length(q)
  dQ <- c(NA_real_, diff(q))
  bad <- is.na(q) | is.na(dQ) | dQ >= 0 | is.na(pr) | pr > rain_mm |
    q <= 0 | c(FALSE, q[-n] <= 0)
  if (!is.null(mask)) bad <- bad | !mask
  seg <- vector("list", 0)
  i <- 1L
  while (i <= n) {
    if (!bad[i]) {
      j <- i
      while (j < n && !bad[j + 1]) j <- j + 1
      if (j - i + 1 >= min_len) {
        seg[[length(seg) + 1L]] <- c(i, j)
      }
      i <- j + 1L
    } else i <- i + 1L
  }
  if (!length(seg)) {
    return(data.table::data.table(start = integer(), end = integer(),
                                  length = integer()))
  }
  m <- do.call(rbind, seg)
  data.table::data.table(start = m[, 1], end = m[, 2],
                         length = m[, 2] - m[, 1] + 1L)
}

# --- Recession fit ------------------------------------------------------
# From censored recession segments on daily flow in mm/day:
#   1. recession constant k (days): per segment, mean of
#      ln Q(t+1) - ln Q(t) = -1/k; take the MEDIAN across segments.
#   2. low-flow nonlinearity exponent p in -dQ/dt = a * Q^p, fitted by
#      OLS on log scale over segment day-pairs, clipped to [0.5, 1]
#      [assumption: the clip is the declared physical range].
# Returns list(k_days, p, a, n_segments). Requires >= 2 segments; the
# >= 20-segment quality screen lives in the calling script.
fit_recession <- function(q_mm, prcp_mm, mask = NULL,
                          min_len = 10L, rain_mm = 1.0) {
  segs <- recession_segments(q_mm, prcp_mm, mask = mask,
                             min_len = min_len, rain_mm = rain_mm)
  if (nrow(segs) < 2) {
    return(list(k_days = NA_real_, p = NA_real_, a = NA_real_,
                n_segments = nrow(segs)))
  }
  q <- as.numeric(q_mm)
  ks <- vapply(seq_len(nrow(segs)), function(s) {
    qq <- q[segs$start[s]:segs$end[s]]
    d <- diff(log(qq[qq > 0]))
    if (length(d) < 2) return(NA_real_)
    m <- mean(d)
    if (m >= 0) return(NA_real_)
    -1 / m
  }, numeric(1))
  k_days <- stats::median(ks[is.finite(ks) & ks > 0])
  # Exponent fit over pooled segment day-pairs.
  dq <- diff(q)
  xs <- c(); ys <- c()
  for (s in seq_len(nrow(segs))) {
    idx <- segs$start[s]:(segs$end[s] - 1L)
    rate <- -dq[idx]
    qv <- q[idx]
    okp <- is.finite(rate) & is.finite(qv) & rate > 0 & qv > 0
    xs <- c(xs, qv[okp]); ys <- c(ys, rate[okp])
  }
  p <- NA_real_; a <- NA_real_
  if (length(xs) >= 20) {
    fit <- stats::lm(log(ys) ~ log(xs))
    p <- unname(stats::coef(fit)[2])
    a <- exp(unname(stats::coef(fit)[1]))
    p <- pmin(pmax(p, 0.5), 1.0)
  }
  list(k_days = k_days, p = p, a = a, n_segments = nrow(segs))
}

# --- Storage scale ------------------------------------------------------
# Storage-outflow inversion (Brutsaert-type). With Q_g = (K_a * S)^{b_s}
# and dS/dt = -Q_g along a recession, the recession law
# -dQ/dt = a * Q^p implies b_s = 1 / (2 - p) and K_a = a / b_s.
# The implied storage along segment days is S(t) = Q(t)^{1/b_s} / K_a;
# S_cap is the 95th percentile of the implied S over the training
# segments (the low-flow envelope; PIVOT.md §4.4 item 3).
fit_storage_scale <- function(q_mm, prcp_mm, mask = NULL,
                              min_len = 10L, rain_mm = 1.0,
                              p_cap = 0.95) {
  rec <- fit_recession(q_mm, prcp_mm, mask = mask, min_len = min_len,
                       rain_mm = rain_mm)
  if (!is.finite(rec$p) || !is.finite(rec$a) || rec$a <= 0 ||
      !is.finite(rec$k_days) || rec$k_days <= 0) {
    return(list(k_days = rec$k_days, p = rec$p, a = rec$a,
                n_segments = rec$n_segments,
                S_cap = NA_real_, b_s = NA_real_, K_a = NA_real_))
  }
  b_s <- 1 / (2 - rec$p)
  K_a <- rec$a / b_s
  segs <- recession_segments(q_mm, prcp_mm, mask = mask,
                             min_len = min_len, rain_mm = rain_mm)
  q <- as.numeric(q_mm)
  Svals <- unlist(lapply(seq_len(nrow(segs)), function(s) {
    qq <- q[segs$start[s]:segs$end[s]]
    S <- qq^(1 / b_s) / K_a
    S[is.finite(S)]
  }))
  S_cap <- if (length(Svals) >= 50) stats::quantile(Svals, p_cap, names = FALSE) else
    NA_real_
  list(k_days = rec$k_days, p = rec$p, a = rec$a,
       n_segments = rec$n_segments, S_cap = S_cap, b_s = b_s, K_a = K_a)
}

# --- Fluid propagator ---------------------------------------------------
# One fluid state, three mechanisms (PIVOT.md §4.4), all mm/day:
#   S(t+1) = clip( S(t) + Pe(t) - Ea(t) - Q_g(t), 0, S_cap )
#   Pe(t)  = max( P(t) - phi_m(month) * P(t), 0 )        # effective input
#   Ea(t)  = min( PET(t) * Kc_m(month), S(t) + Pe(t) )   # supply-limited
#   Q_g(t) = min( (K_a * S(t))^{b_s}, S(t) )             # release, bounded
# Zero-flow censoring: on a recorded zero-flow day the state sits at its
# floor S = 0; the release absorbs the whole balance,
#   Q_g(t) = S(t) + Pe(t) - Ea(t)   so that S(t+1) = 0,
# and the censor_release column REPORTS that absorbed release (it is part
# of Q_g, not an extra term) [assumption, declared]. Initialised at
# S(0) = S_cap / 2 [assumption]; the caller excludes the warm-up years
# from features.
# Returns the daily table with the per-day ledger residual as an
# attribute; stop() if any residual exceeds 1e-9. The per-day identity is
#   S(t+1) - S(t) = Pe - Ea - Q_g - overflow + deficit.
propagate_storage <- function(dates, prcp_mm, pet_mm, month,
                              region = "India", S_cap, K_a, b_s,
                              zero_day = NULL, S0 = NULL) {
  assert_true(is.finite(S_cap) && S_cap > 0, "S_cap must be positive mm")
  assert_true(is.finite(K_a) && K_a > 0, "K_a must be positive (per day)")
  assert_true(is.finite(b_s) && b_s >= 0.5 && b_s <= 2, "b_s out of range")
  n <- length(dates)
  pr <- as.numeric(prcp_mm); pe_in <- as.numeric(pet_mm)
  # Declared handling of missing climate inputs: a missing day carries no
  # information, so its input enters the balance as zero and the MONTH is
  # excluded from features downstream by the complete-month rule
  # (missing_day already flags it in prepare_daily). No interpolation.
  pr[is.na(pr)] <- 0; pe_in[is.na(pe_in)] <- 0
  mo <- as.integer(month)
  kc <- kc_month(mo, region); phm <- phi_month(mo, region)
  if (is.null(zero_day)) zero_day <- rep(FALSE, n)
  zero_day <- as.logical(zero_day)
  S <- numeric(n); Pe <- numeric(n); Ea <- numeric(n); Qg <- numeric(n)
  ovf <- numeric(n); dfc <- numeric(n); cens <- numeric(n)
  S_init <- if (is.null(S0)) S_cap / 2 else S0
  S_prev <- S_init
  for (t in seq_len(n)) {
    Pe[t] <- max(pr[t] - phm[t] * pr[t], 0)
    Ea[t] <- min(pe_in[t] * kc[t], S_prev + Pe[t])
    if (!is.finite(Ea[t])) Ea[t] <- 0
    if (zero_day[t]) {
      Qg[t] <- S_prev + Pe[t] - Ea[t]
      cens[t] <- Qg[t]
      raw <- 0
    } else {
      Qg[t] <- min((K_a * S_prev)^b_s, S_prev)
      raw <- S_prev + Pe[t] - Ea[t] - Qg[t]
    }
    if (raw < 0) { dfc[t] <- -raw; S[t] <- 0 }
    else if (raw > S_cap) { ovf[t] <- raw - S_cap; S[t] <- S_cap }
    else S[t] <- raw
    S_prev <- S[t]
  }
  # Per-day ledger identity (successor of the CTMC ledger):
  #   dS = Pe - Ea - Qg - ovf + dfc   (cens is a reported subset of Qg)
  S_prev_all <- c(S_init, S[-n])
  dS <- S - S_prev_all
  resid <- abs(dS - (Pe - Ea - Qg - ovf + dfc))
  if (any(resid > 1e-9, na.rm = TRUE)) {
    stop(sprintf("Fluid ledger residual %.3e exceeds 1e-9",
                 max(resid, na.rm = TRUE)), call. = FALSE)
  }
  out <- data.table::data.table(
    date = as.Date(dates), S_mm = S, Pe_mm = Pe, Ea_mm = Ea, Qg_mm = Qg,
    overflow_mm = ovf, deficit_mm = dfc, censor_release_mm = cens,
    zero_day = zero_day)
  attr(out, "max_ledger_residual") <- max(resid, na.rm = TRUE)
  out
}

# --- Features from the state (PIVOT.md §4.6) ----------------------------
# Days since flow last exceeded the training Q10 threshold, capped at 365.
# If the threshold itself is not finite (degenerate record), the feature
# is NA everywhere -- never a guessed number.
days_since_high_flow <- function(q_mm, q10) {
  n <- length(q_mm)
  if (!is.finite(q10)) return(rep(NA_integer_, n))
  out <- integer(n); last <- -1L
  for (i in seq_len(n)) {
    if (is.finite(q_mm[i]) && q_mm[i] > q10) last <- i
    out[i] <- if (last < 1L) NA_integer_ else min(i - last, 365L)
  }
  out
}
