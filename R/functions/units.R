# =====================================================================
# R/functions/units.R -- the unit wall.
#
# Every conversion between hydrological units (mm/day, m^3/day, m^3/s,
# claims/day) lives here exactly once, with an assertion and a comment
# stating the physics. The queue engine never sees m^3 or hectares; it
# only ever receives claims/day. This architectural wall is what makes
# the v1 unit-mixing defect (F1) impossible to repeat.
# =====================================================================

# --- Assertions -------------------------------------------------------
assert_true <- function(cond, msg) {
  if (!isTRUE(all(cond))) stop("Unit assertion failed: ", msg, call. = FALSE)
  invisible(TRUE)
}

assert_positive <- function(x, name) {
  if (any(!is.finite(x)) || any(x < 0)) {
    stop("Unit assertion failed: ", name, " must be finite and non-negative.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# --- Area and depth ---------------------------------------------------
# 1 mm of water spread over 1 m^2 is 1 litre = 0.001 m^3.
mm_to_m3 <- function(depth_mm, area_m2) {
  assert_positive(depth_mm, "depth_mm")
  assert_positive(area_m2, "area_m2")
  0.001 * depth_mm * area_m2
}

# A claim is d_mm of water over the command area. It is the single
# volumetric unit used for BOTH demand and supply at one gauge.
claim_volume_m3 <- function(d_mm, area_m2) {
  assert_positive(d_mm, "d_mm")
  assert_positive(area_m2, "area_m2")
  mm_to_m3(d_mm, area_m2)
}

# --- Demand -----------------------------------------------------------
# Demand is a depth rate over the command area, so area cancels when it
# is expressed in claims/day: lambda = need_mm / d_mm.
demand_claims <- function(need_mm, d_mm) {
  assert_positive(need_mm, "need_mm")
  assert_positive(d_mm, "d_mm")
  need_mm / d_mm
}

# Crop-water need (mm/day) from FAO-style crop evapotranspiration minus
# effective rainfall. Never negative.
crop_need_mm <- function(etc_mm, rain_mm, phi) {
  assert_positive(etc_mm, "etc_mm")
  assert_positive(rain_mm, "rain_mm")
  assert_true(phi >= 0 && phi <= 1, "phi must lie in [0, 1]")
  pmax(etc_mm - phi * rain_mm, 0)
}

# --- Supply -----------------------------------------------------------
# Convert discharge (m^3/s) to a depth rate (mm/day) over an area.
# Q [m^3/s] * 86,400 [s/day] = m^3/day; divide by area [m^2] gives m/day;
# multiply by 1,000 gives mm/day. This is the ONLY place 86,400 appears.
q_m3s_to_mm_day <- function(q_m3s, area_m2) {
  assert_positive(q_m3s, "q_m3s")
  assert_positive(area_m2, "area_m2")
  q_m3s * 86400 / area_m2 * 1000
}

# Raw firm abstraction in m^3/day (no area, no claim conversion yet).
firm_abstraction_m3_day <- function(q_m3s, s_firm) {
  assert_positive(q_m3s, "q_m3s")
  assert_true(s_firm >= 0 && s_firm <= 1, "s_firm must lie in [0, 1]")
  q_m3s * 86400 * s_firm
}

# Deliverable supply as a depth rate (mm/day), capped by infrastructure.
supply_mm_day <- function(q_m3s, area_m2, s_firm, cap_mm) {
  s_mm <- q_m3s_to_mm_day(q_m3s, area_m2) * s_firm
  assert_positive(cap_mm, "cap_mm")
  pmin(s_mm, cap_mm)
}

# Supply in claims/day: depth rate divided by the same claim depth used
# for demand. Area enters exactly once (through supply_mm_day).
supply_claims <- function(q_m3s, area_m2, s_firm, cap_mm, d_mm) {
  assert_positive(d_mm, "d_mm")
  supply_mm_day(q_m3s, area_m2, s_firm, cap_mm) / d_mm
}

# Inverse helpers used for reporting only.
claims_to_mm <- function(claims, d_mm) {
  assert_positive(claims, "claims")
  claims * d_mm
}

# --- PET: Hargreaves with the FAO-56 0.408 radiation conversion -------
# Extraterrestrial radiation Ra in MJ m^-2 day^-1 (FAO-56 Eqs. 21-25).
extraterrestrial_radiation <- function(lat_deg, doy) {
  assert_true(abs(lat_deg) <= 90, "latitude must be within [-90, 90]")
  gsc <- 0.0820                      # solar constant, MJ m^-2 min^-1
  phi <- lat_deg * pi / 180
  j <- doy
  dr <- 1 + 0.033 * cos(2 * pi * j / 365)
  delta <- 0.409 * sin(2 * pi * j / 365 - 1.39)
  ws <- acos(pmin(pmax(-tan(phi) * tan(delta), -1), 1))
  ra <- (24 * 60 / pi) * gsc * dr *
    (ws * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(ws))
  pmax(ra, 0)
}

# Hargreaves-Samani reference evapotranspiration (mm/day).
# Ra is converted from MJ m^-2 day^-1 to mm/day equivalent by 0.408
# BEFORE entering the equation. Omitting 0.408 inflates ET0 by ~2.45x;
# that was the v1 defect (F6) and the reason V9 exists.
hargreaves_et0 <- function(tmax_c, tmin_c, tmean_c, ra_mj) {
  assert_positive(ra_mj, "ra_mj")
  tr <- pmax(tmax_c - tmin_c, 0)
  ra_mm <- 0.408 * ra_mj
  et0 <- 0.0023 * (tmean_c + 17.8) * sqrt(tr) * ra_mm
  pmax(et0, 0)
}

# --- Seasonal demand curves (FQ6 fix, PIVOT.md §3 change 2) -----------
# Month-of-year crop coefficient Kc_m and effective-rainfall fraction
# phi_m. Values live in R/config.R (KC_MONTHLY / PHI_MONTHLY, one entry
# per region); this is the only place they are applied, with assertions.
# [assumption: FAO-56-style two-season simplification, declared in config.]
kc_month <- function(month, region = "India") {
  assert_true(all(month %in% 1:12), "month must be in 1:12")
  v <- KC_MONTHLY[[region]]
  assert_true(length(v) == 12, "KC_MONTHLY must have 12 monthly values")
  assert_true(all(v >= 0 & v <= 2), "Kc monthly values must lie in [0, 2]")
  v[as.integer(month)]
}

phi_month <- function(month, region = "India") {
  assert_true(all(month %in% 1:12), "month must be in 1:12")
  v <- PHI_MONTHLY[[region]]
  assert_true(length(v) == 12, "PHI_MONTHLY must have 12 monthly values")
  assert_true(all(v >= 0 & v <= 1), "phi monthly values must lie in [0, 1]")
  v[as.integer(month)]
}

# Measured irrigated fraction from the dataset attribute (irrigation_frac),
# replacing the flat 0.10 on the G2/P1 path [assumption: floor/cap in
# config.R keep the command area defined; applied exactly once here].
f_irr_measured <- function(irrigation_frac) {
  x <- as.numeric(irrigation_frac)
  if (!is.finite(x)) return(P$f_irr)  # unknown attribute -> retired default
  pmin(pmax(x, P$f_irr_floor), P$f_irr_cap)
}

# --- Worked check mandated by the plan (┬º3.1) -------------------------
# With 45,000 ha, d = 20 mm, s_firm = 0.5 and Q = 500 m^3/s:
#   S_mm = 0.5*500*86400/4.5e8*1000 = 48 mm/day -> capped at 10
#   mu   = 10/20 = 0.5 claims/day; need 2 mm/day -> lambda = 0.1
#   rho  = 0.2 (inside the 0.15-1.20 window)
units_worked_check <- function() {
  area_m2 <- 45000 * 1e4
  s_mm <- supply_mm_day(500, area_m2, 0.5, 10)
  mu <- supply_claims(500, area_m2, 0.5, 10, 20)
  lam <- demand_claims(2, 20)
  list(claim_m3 = claim_volume_m3(20, area_m2),
       supply_mm = s_mm, mu = mu, lambda = lam, rho = lam / mu)
}
