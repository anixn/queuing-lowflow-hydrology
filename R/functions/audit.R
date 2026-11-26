# =====================================================================
# R/functions/audit.R -- zero-flow classification and gap handling.
#
# Zeros are a data-quality question, not a modelling assumption. The
# classifier compares each zero day with same-basin peer gauges (a
# documented proxy grade when no independent CWC series is available).
# The gap rule never fills silently: short gaps pause the queue state,
# longer gaps exclude the affected month.
# =====================================================================

# Classify a flow series day by day.
#   q                 : numeric flow (m^3/s), NA = missing
#   peer_positive_frac: fraction of same-basin peer gauges with flow > 0
#                       on the same day (NA when no peer is available)
# Returns a character vector: positive / real-zero / artifact / unknown / missing
classify_zeros <- function(q, peer_positive_frac) {
  stopifnot(length(q) == length(peer_positive_frac))
  out <- rep(NA_character_, length(q))
  out[is.na(q)] <- "missing"
  pos <- !is.na(q) & q > 0
  out[pos] <- "positive"
  zero <- !is.na(q) & q == 0
  out[zero & is.na(peer_positive_frac)] <- "unknown"
  out[zero & !is.na(peer_positive_frac) & peer_positive_frac > 0.5] <- "artifact"
  out[zero & !is.na(peer_positive_frac) & peer_positive_frac <= 0.5] <- "real-zero"
  out
}

# Fraction of same-basin peers with positive flow on each day.
# peer_matrix: days x peers numeric matrix (NA allowed); self excluded by caller.
peer_positive_fraction <- function(peer_matrix) {
  if (is.null(peer_matrix) || ncol(peer_matrix) == 0) {
    return(rep(NA_real_, nrow(peer_matrix)))
  }
  pos <- peer_matrix > 0
  n_avail <- rowSums(!is.na(peer_matrix))
  n_pos <- rowSums(pos, na.rm = TRUE)
  ifelse(n_avail > 0, n_pos / n_avail, NA_real_)
}

# Gap handling.
# Returns a data frame aligned to `dates`:
#   pause          : short gap (<= max_short_gap): state pause, no fill
#   missing_unresolved : longer gap: no fill
#   exclude_month  : the calendar month is excluded from aggregation
mark_gaps <- function(dates, missing, max_short_gap = 7L,
                      long_gap_exclusion = 30L) {
  n <- length(dates)
  stopifnot(length(missing) == n)
  pause <- rep(FALSE, n)
  unresolved <- rep(FALSE, n)
  r <- rle(as.logical(missing))
  ends <- cumsum(r$lengths)
  starts <- ends - r$lengths + 1L
  for (k in seq_along(r$values)) {
    if (!isTRUE(r$values[k])) next
    len <- r$lengths[k]
    idx <- starts[k]:ends[k]
    if (len <= max_short_gap) {
      pause[idx] <- TRUE
    } else {
      unresolved[idx] <- TRUE
    }
  }
  exclude_month <- rep(FALSE, n)
  if (any(unresolved)) {
    ym <- format(as.Date(dates), "%Y-%m")
    bad <- unique(ym[unresolved])
    exclude_month <- ym %in% bad
  }
  data.frame(date = as.Date(dates), pause = pause,
             missing_unresolved = unresolved, exclude_month = exclude_month)
}

# Convert classified zeros to missing under a treatment variant.
#   V0: as recorded (no change)
#   V1: artifact and unknown zeros become missing
#   V2: handled upstream by restricting to verified months
zeros_to_missing <- function(q, cls, variant = c("V0", "V1", "V2")) {
  variant <- match.arg(variant)
  out <- q
  if (variant == "V1") {
    out[cls %in% c("artifact", "unknown")] <- NA_real_
  }
  out
}
