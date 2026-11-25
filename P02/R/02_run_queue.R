# =====================================================================
# 02_run_queue.R   --   P02 real-data pilot: solve the CTMC
#
# PURPOSE
#   Read the daily lambda(t) / mu(t) CSV made by 01_build_rates.R and solve
#   the non-stationary finite-capacity birth-death queue by RK4 on the
#   forward equations. Report E[Q], Pr(Q >= q_star), peak rho and the
#   accumulated unmet demand U. Base R only, no packages needed.
#
# HOW TO USE
#   Linear script. Edit BLOCK 1, then run from the project root:
#       Rscript P02/R/02_run_queue.R
#   Output: P02/data/generated/rates_4026_indicators.csv
#
#   Run 01_build_rates.R FIRST.
# =====================================================================


# ---------------------------------------------------------------------
# BLOCK 1 -- SETTINGS (edit here; nothing below needs editing)
# ---------------------------------------------------------------------

rate_file <- "P02/data/generated/rates_4026.csv"
analysis_start <- as.Date("2001-01-01")   # discard earlier spin-up years

# Queue configuration (must match queue_core.py for comparability)
K      <- 20     # max backlog = 20 claims = 2x10^8 m^3 = 400 mm over command
c_srv  <- 2      # number of parallel supply sources
theta  <- 8      # backlog at which emergency/drought service switches on
alpha  <- 1.5    # service-rate multiplier above theta
eta    <- 0.02   # reneging (abandonment) per waiting claim per day
q_star <- 6      # "critical" backlog threshold
dt     <- 0.25   # integration step in days; reduced automatically if needed


# ---------------------------------------------------------------------
# BLOCK 2 -- READ THE RATE FILE
# ---------------------------------------------------------------------

rates <- read.csv(rate_file, stringsAsFactors = FALSE)
rates$date <- as.Date(rates$date)
rates <- rates[order(rates$date), ]
rates <- rates[!is.na(rates$lambda) & !is.na(rates$mu), ]
rates <- rates[rates$date >= analysis_start, ]

lam_v <- rates$lambda
mu_v  <- rates$mu
t_day <- as.numeric(rates$date - min(rates$date))
n_days <- length(t_day)
if (n_days < 2) stop("Need at least two days of rates in ", rate_file)

cat("Loaded", n_days, "days:", format(min(rates$date)), "to",
    format(max(rates$date)), "\n")


# ---------------------------------------------------------------------
# BLOCK 3 -- RATE LOOKUP (linear interpolation, constant outside range)
# ---------------------------------------------------------------------

lam_at <- function(t) approx(t_day, lam_v, xout = t, rule = 2)$y
mu_at  <- function(t) approx(t_day, mu_v,  xout = t, rule = 2)$y


# ---------------------------------------------------------------------
# BLOCK 4 -- RK4 STABILITY GUARD AND TIME GRID
# ---------------------------------------------------------------------
# The forward equations are stiff: RK4 needs dt * |largest eigenvalue| <~ 2.78.
# A safe upper bound on that eigenvalue is the largest total jump rate.
max_rate <- max(lam_v) + c_srv * max(mu_v) * alpha + K * eta
if (dt * max_rate > 2.7) {
  cat(sprintf("dt %.2f x max rate %.2f = %.2f is too large; reducing dt to 0.1\n",
              dt, max_rate, dt * max_rate))
  dt <- 0.1
}

times <- seq(0, t_day[n_days], by = dt)
if (times[length(times)] < t_day[n_days]) {
  times <- c(times, t_day[n_days])
}
nt <- length(times)
cat("Integration steps:", nt, " (dt =", dt, "days)\n")


# ---------------------------------------------------------------------
# BLOCK 5 -- ONE HELPER: BUILD THE GENERATOR MATRIX AT TIME t
# ---------------------------------------------------------------------
# Row n of A holds the transition rates out of backlog state n.
# Column m holds the rates into state m. Rows always sum to zero.

make_generator <- function(lam, mu) {
  n <- 0:K
  birth <- rep(lam, K + 1)
  birth[K + 1] <- 0                        # no arrivals at full backlog
  death <- pmin(n, c_srv) * mu
  death <- death * ifelse(n >= theta, alpha, 1.0)
  death <- death + n * eta                 # reneging on top of service
  death[1] <- 0                            # nothing to clear at backlog 0

  A <- matrix(0, K + 1, K + 1)
  idx <- 1:(K + 1)
  A[cbind(idx, idx)] <- -(birth + death)                       # diagonal
  A[cbind(idx[1:K], idx[2:(K + 1)])] <- birth[1:K]             # upward jumps
  A[cbind(idx[2:(K + 1)], idx[1:K])] <- death[2:(K + 1)]       # downward jumps
  A
}


# ---------------------------------------------------------------------
# BLOCK 6 -- RK4 TIME STEPPING
# ---------------------------------------------------------------------

P <- matrix(0, nrow = nt, ncol = K + 1)
P[1, ] <- c(1, rep(0, K))                  # start with an empty queue

for (i in 1:(nt - 1)) {
  t <- times[i]
  h <- times[i + 1] - t
  p <- P[i, ]

  k1 <- drop(p %*% make_generator(lam_at(t),               mu_at(t)))
  k2 <- drop((p + 0.5 * h * k1) %*% make_generator(lam_at(t + 0.5 * h),
                                                   mu_at(t + 0.5 * h)))
  k3 <- drop((p + 0.5 * h * k2) %*% make_generator(lam_at(t + 0.5 * h),
                                                   mu_at(t + 0.5 * h)))
  k4 <- drop((p + h * k3) %*% make_generator(lam_at(t + h), mu_at(t + h)))

  pnext <- p + (h / 6) * (k1 + 2 * k2 + 2 * k3 + k4)
  pnext <- pmax(pnext, 0)                  # clamp tiny negative round-off
  P[i + 1, ] <- pnext / sum(pnext)         # renormalise each step
}


# ---------------------------------------------------------------------
# BLOCK 7 -- DROP SPIN-UP AND COMPUTE INDICATORS
# ---------------------------------------------------------------------

burn <- 365                                # discard the first year
keep <- times >= burn
Pk <- P[keep, , drop = FALSE]
tk <- times[keep]

n_state <- 0:K
E_Q     <- as.vector(Pk %*% n_state)                       # mean backlog
P_crit  <- rowSums(Pk[, (q_star + 1):(K + 1), drop = FALSE])
lam_k   <- lam_at(tk)
mu_k    <- mu_at(tk)
rho_k   <- ifelse(mu_k > 0, lam_k / mu_k, Inf)

# Abandoned demand per day = reneging from waiting claims + blocking at K.
abandoned <- eta * E_Q + lam_k * Pk[, K + 1]
U <- sum(diff(tk) * (abandoned[-1] + abandoned[-length(abandoned)]) / 2)

cat("\n--- Indicators (after first-year spin-up) ---\n")
cat(sprintf("E[Q] mean      : %.4f claims\n", mean(E_Q)))
cat(sprintf("E[Q] peak      : %.4f claims\n", max(E_Q)))
cat(sprintf("Pr(Q>=%d) mean  : %.4f\n", q_star, mean(P_crit)))
cat(sprintf("Pr(Q>=%d) peak  : %.4f\n", q_star, max(P_crit)))
cat(sprintf("Peak rho       : %.4f\n", max(rho_k)))
cat(sprintf("Median rho     : %.4f\n", median(rho_k[is.finite(rho_k)])))
cat(sprintf("Days with mu=0 : %.1f%% (rho is Inf on these days by design)\n",
            100 * mean(mu_k == 0)))
cat(sprintf("Unmet demand U : %.3f claim-days\n", U))


# ---------------------------------------------------------------------
# BLOCK 8 -- WRITE A SMALL INDICATOR CSV
# ---------------------------------------------------------------------

out <- data.frame(
  metric = c("E_Q_mean", "E_Q_peak", "P_crit_mean", "P_crit_peak",
             "rho_peak", "rho_median_finite", "U_claim_days"),
  value  = c(mean(E_Q), max(E_Q), mean(P_crit), max(P_crit),
             max(rho_k), median(rho_k[is.finite(rho_k)]), U)
)
out_file <- sub("\\.csv$", "_indicators.csv", rate_file)
write.csv(out, out_file, row.names = FALSE)
cat("\nWritten:", out_file, "\n")
cat("These numbers use ASSUMED command area, claim volume and service cap.\n")
cat("Treat them as a pipeline check, not as research results.\n")
