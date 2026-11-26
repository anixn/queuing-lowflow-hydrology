# =====================================================================
# R/00_utils/queue_engine.R -- finite-capacity birth-death CTMC.
#
# States n = 0..K count accumulated unmet demand ("backlog") in claims.
# Rates are claims/day ONLY. The engine never sees m^3, hectares or mm;
# unit conversion happens once, upstream, in units.R.
#
# Model (identical mathematics to the verified v1 engine):
#   birth_n  = lambda                      for n < K, else 0
#   service_n= min(n, c) * mu * (alpha if n >= theta else 1)
#   death_n  = service_n + n * eta          (service + reneging)
#
# The RK4 transient carries a conservation ledger computed from the SAME
# stages, so the per-day identity
#     offered = served + reneged + blocked + Delta_backlog
# holds to floating-point precision (see the derivation in the header of
# rk4_step). A ledger failure stops the pipeline; it is the project's
# signature honesty device.
# =====================================================================

# --- Configuration ----------------------------------------------------
queue_config <- function(q_star, K, c = 1L, theta = NULL, alpha = 1.5,
                         eta = 1 / 60, rk4_dt = NULL, rk4_maxrate = NULL,
                         block_guard = NULL) {
  K <- as.integer(K)
  q_star <- as.integer(q_star)
  if (is.null(theta)) theta <- as.integer(ceiling(1.5 * q_star))
  assert_true(K >= 2, "capacity K must be at least 2")
  assert_true(q_star >= 0 && q_star <= K, "q* must lie in [0, K]")
  # Numerical settings come from config.R (P) unless explicitly supplied.
  if (is.null(rk4_dt)) rk4_dt <- if (exists("P")) P$rk4_dt else 0.1
  if (is.null(rk4_maxrate)) rk4_maxrate <- if (exists("P")) P$rk4_maxrate else 0.1
  if (is.null(block_guard)) block_guard <- if (exists("P")) P$block_guard else 1e-3
  list(K = K, c = as.integer(c), q_star = q_star,
       theta = as.integer(min(theta, K)), alpha = alpha, eta = eta,
       rk4_dt = rk4_dt, rk4_maxrate = rk4_maxrate, block_guard = block_guard)
}

# Catchment-relative thresholds from the gauge's own mean demand rate.
thresholds_from_lambda <- function(lam_bar, q_days = 60, K_days = 365,
                                   theta_mult = 1.5) {
  assert_positive(lam_bar, "lam_bar")
  q_star <- max(1L, as.integer(ceiling(q_days * lam_bar)))
  K <- as.integer(min(80, max(25, ceiling(K_days * lam_bar))))
  if (q_star >= K) q_star <- K - 1L
  theta <- as.integer(min(K, ceiling(theta_mult * q_star)))
  list(q_star = q_star, K = K, theta = theta)
}

# --- Rates ------------------------------------------------------------
birth_n <- function(n, lam, cfg) ifelse(n < cfg$K, lam, 0)

service_n <- function(n, mu, cfg) {
  pmin(n, cfg$c) * mu * ifelse(n >= cfg$theta, cfg$alpha, 1)
}

death_n <- function(n, mu, cfg) service_n(n, mu, cfg) + n * cfg$eta

# Generator Q with dp/dt = p %*% Q (row-vector convention).
generator_matrix <- function(lam, mu, cfg) {
  K <- cfg$K
  n <- 0:K
  b <- birth_n(n, lam, cfg)
  d <- death_n(n, mu, cfg)
  Q <- matrix(0, nrow = K + 1, ncol = K + 1)
  idx <- seq_len(K + 1)
  Q[cbind(idx, idx)] <- -(b + d)
  if (K >= 1) Q[cbind(idx[1:K], idx[1:K] + 1)] <- b[1:K]
  if (K >= 1) Q[cbind(idx[2:(K + 1)], idx[1:K])] <- d[2:(K + 1)]
  Q
}

# --- Exact stationary product form ------------------------------------
stationary <- function(lam, mu, cfg) {
  K <- cfg$K
  n <- 0:K
  b <- birth_n(n, lam, cfg)
  d <- death_n(n, mu, cfg)
  pi <- numeric(K + 1)
  pi[1] <- 1
  if (K >= 1) {
    for (i in 2:(K + 1)) pi[i] <- pi[i - 1] * b[i - 1] / d[i]
  }
  pi / sum(pi)
}

# --- One RK4 substep with exact ledger integrals ----------------------
# Derivation: with g_n = b_n - d_n, (Q n)_n = g_n, so n . (p Q) = p . g.
# RK4 applied to the state therefore gives
#   n . Delta p = dt/6 * (p1.g + 2 p2.g + 2 p3.g + p4.g),
# which is exactly the RK4 quadrature of the flux integral. Computing the
# flux integrals from the same stages makes the ledger identity exact.
# Internal: one RK4 substep given a precomputed generator and rate
# vectors. Rates are constant across the substeps of a single day, so the
# day loop builds these once (this is the only performance concession).
rk4_substep <- function(p, lam, Q, svc, ren, K, dt) {
  k1 <- as.numeric(p %*% Q)
  p1 <- p
  p2 <- p + (dt / 2) * k1
  k2 <- as.numeric(p2 %*% Q)
  p3 <- p + (dt / 2) * k2
  k3 <- as.numeric(p3 %*% Q)
  p4 <- p + dt * k3
  k4 <- as.numeric(p4 %*% Q)
  p_new <- p + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)

  w <- dt / 6
  served <- w * (sum(p1 * svc) + 2 * sum(p2 * svc) +
                 2 * sum(p3 * svc) + sum(p4 * svc))
  reneged <- w * (sum(p1 * ren) + 2 * sum(p2 * ren) +
                  2 * sum(p3 * ren) + sum(p4 * ren))
  blocked <- w * lam * (p1[K + 1] + 2 * p2[K + 1] +
                          2 * p3[K + 1] + p4[K + 1])
  offered <- lam * dt

  if (any(p_new < 0)) p_new[p_new < 0] <- 0
  s <- sum(p_new)
  if (!is.finite(s) || s <= 0) stop("RK4 lost probability mass.")
  p_new <- p_new / s

  list(p = p_new, served = served, reneged = reneged,
       blocked = blocked, offered = offered)
}

rk4_step <- function(p, lam, mu, cfg, dt) {
  K <- cfg$K
  n <- 0:K
  Q <- generator_matrix(lam, mu, cfg)
  svc <- service_n(n, mu, cfg)
  ren <- n * cfg$eta
  rk4_substep(p, lam, Q, svc, ren, K, dt)
}

# --- One day with adaptive substeps -----------------------------------
# The generator, service and reneging vectors depend only on (lam, mu),
# which are piecewise constant within a day, so they are built once.
rk4_day <- function(p, lam, mu, cfg) {
  K <- cfg$K
  n <- 0:K
  Q <- generator_matrix(lam, mu, cfg)
  svc <- service_n(n, mu, cfg)
  ren <- n * cfg$eta
  death_max <- cfg$c * mu * cfg$alpha + cfg$K * cfg$eta
  dt <- min(cfg$rk4_dt, cfg$rk4_maxrate / max(lam + death_max, 1e-9))
  dt <- max(dt, 1e-4)
  t <- 0
  served <- reneged <- blocked <- offered <- 0
  steps <- 0L
  while (t < 1 - 1e-12) {
    h <- min(dt, 1 - t)
    s <- rk4_substep(p, lam, Q, svc, ren, K, h)
    p <- s$p
    served <- served + s$served
    reneged <- reneged + s$reneged
    blocked <- blocked + s$blocked
    offered <- offered + s$offered
    t <- t + h
    steps <- steps + 1L
  }
  list(p = p, served = served, reneged = reneged, blocked = blocked,
       offered = offered, steps = steps)
}

# --- Indicators -------------------------------------------------------
indicators <- function(p, cfg) {
  n <- 0:cfg$K
  e_q <- sum(n * p)
  p_ge_q <- if (cfg$q_star <= cfg$K) sum(p[(cfg$q_star + 1):(cfg$K + 1)]) else 0
  p_ge_theta <- if (cfg$theta <= cfg$K) sum(p[(cfg$theta + 1):(cfg$K + 1)]) else 0
  p_eq_K <- p[cfg$K + 1]
  list(E_Q = e_q, p_ge_q = p_ge_q, p_ge_theta = p_ge_theta, p_eq_K = p_eq_K)
}

# --- Full run ---------------------------------------------------------
# dates/lambda/mu must be aligned, sorted daily. `keep` selects output
# days; `pause` marks days on which the state is carried forward with no
# arrival and no service (V1 short-gap rule), still emitting indicators.
run_queue <- function(dates, lambda, mu, cfg, keep = rep(TRUE, length(dates)),
                      pause = rep(FALSE, length(dates))) {
  stopifnot(length(dates) == length(lambda), length(lambda) == length(mu))
  p <- numeric(cfg$K + 1); p[1] <- 1
  rows <- vector("list", sum(keep))
  j <- 0L
  max_resid <- 0
  for (i in seq_along(dates)) {
    e0 <- sum((0:cfg$K) * p)
    if (!isTRUE(pause[i])) {
      d <- rk4_day(p, lambda[i], mu[i], cfg)
      p <- d$p
      e1 <- sum((0:cfg$K) * p)
      resid <- d$offered - d$served - d$reneged - d$blocked - (e1 - e0)
      max_resid <- max(max_resid, abs(resid))
      if (abs(resid) > 1e-6) {
        stop(sprintf("Conservation ledger failed on %s: residual %.3e",
                     format(dates[i]), resid))
      }
      served <- d$served; reneged <- d$reneged
      blocked <- d$blocked; offered <- d$offered
    } else {
      served <- reneged <- blocked <- offered <- 0
    }
    if (isTRUE(keep[i])) {
      ind <- indicators(p, cfg)
      j <- j + 1L
      rows[[j]] <- data.frame(
        date = dates[i], lambda = lambda[i], mu = mu[i],
        E_Q = ind$E_Q, p_ge_q = ind$p_ge_q, p_ge_theta = ind$p_ge_theta,
        p_eq_K = ind$p_eq_K, served = served, reneged = reneged,
        blocked = blocked, offered = offered,
        rho_day = if (!is.na(mu[i]) && mu[i] > 0) lambda[i] / mu[i] else NA_real_,
        flag_pause = isTRUE(pause[i]),
        stringsAsFactors = FALSE
      )
    }
  }
  out <- do.call(rbind, rows)
  attr(out, "max_ledger_residual") <- max_resid
  out
}

# --- Blocking guard ---------------------------------------------------
# If the stationary mass at the capacity state exceeds the guard, K is
# too small. Return the next K formula step so the caller can rerun and
# log the decision instead of silently saturating.
check_blocking <- function(p_eq_K, cfg, guard = 1e-3) {
  ok <- is.finite(p_eq_K) && p_eq_K < guard
  list(ok = ok, p_eq_K = p_eq_K,
       suggested_K = if (ok) cfg$K else as.integer(min(200, cfg$K * 2)))
}

# --- First passage: mean days from q* to empty ------------------------
first_passage_mean <- function(lam, mu, cfg, q_star = cfg$q_star) {
  if (q_star <= 0) return(0)
  K <- cfg$K
  Q <- generator_matrix(lam, mu, cfg)
  idx <- 2:(K + 1)                 # transient states 1..K (0 absorbing)
  A <- Q[idx, idx, drop = FALSE]
  rhs <- rep(-1, length(idx))
  m <- tryCatch(solve(A, rhs), error = function(e) rep(NA_real_, length(idx)))
  if (q_star >= 1 && q_star <= K) as.numeric(m[q_star]) else NA_real_
}

# --- Discrete-event simulation (verification only) --------------------
# Gillespie thinning with a uniform bound Gamma. Rates are piecewise
# constant per day. Returns time-averaged indicators over [0, days].
des_run <- function(lam_vec, mu_vec, cfg, seed = 1L, max_events = 3e6,
                    gamma = NULL, warmup = 0) {
  set.seed(seed)
  days <- length(lam_vec)
  if (is.null(gamma)) {
    gamma <- max(lam_vec + cfg$c * mu_vec * cfg$alpha + cfg$K * cfg$eta) * 1.05
  }
  n <- 0L
  t <- 0
  dwell <- numeric(cfg$K + 1)
  events <- 0
  # Add only the portion of [from, to] that lies after `warmup`.
  add_dwell <- function(from, to) {
    a <- max(from, warmup)
    if (to > a) dwell[n + 1] <<- dwell[n + 1] + (to - a)
  }
  while (t < days && events < max_events) {
    t_next <- t + rexp(1, rate = gamma)
    if (t_next >= days) {
      add_dwell(t, days)
      t <- days
      break
    }
    day <- floor(t_next) + 1L
    lam <- lam_vec[day]; mu <- mu_vec[day]
    b <- birth_n(n, lam, cfg)
    d <- death_n(n, mu, cfg)
    q <- b + d
    add_dwell(t, t_next)
    t <- t_next
    if (runif(1) < q / gamma) {
      if (runif(1) < b / q) n <- n + 1L else n <- n - 1L
      events <- events + 1L
    }
  }
  pi <- dwell / sum(dwell)
  ind <- indicators(pi, cfg)
  c(E_Q = ind$E_Q, p_ge_q = ind$p_ge_q, p_ge_theta = ind$p_ge_theta,
    p_eq_K = ind$p_eq_K, events = events, total_time = sum(dwell))
}
