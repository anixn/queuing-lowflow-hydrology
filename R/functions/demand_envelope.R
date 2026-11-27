# =====================================================================
# R/functions/demand_envelope.R -- the demand envelope for Study P3.
#
# NOT used by Study P1. The P1 state is a storage depth in mm and has no
# demand model; the P1 daily input builder is prepare_daily() in
# pipeline.R. This file exists only because Study P3 (climate-projection
# queue reliability) needs the measured demand envelope that the frozen
# CTMC consumes: crop water need in mm/day, converted to claims/day by
# the claim depth d_mm.
#
# Units: prcp, PET, need in mm/day; lambda and mu in claims/day.
# Everything here is an [assumption] declared in R/config.R and
# PIVOT.md §5: seasonal Kc_m(month), effective-rainfall fraction
# phi_m(month), firm share s_firm, infrastructure cap cap_mm, and the
# measured irrigated fraction f_irr (floor/cap in config.R).
# =====================================================================

# Daily demand (lambda) and firm supply (mu) in claims/day for one gauge.
#   need   = max(Kc_m * PET - phi_m * P, 0)                  [mm/day]
#   lambda = need / d_mm                                     [claims/day]
#   mu     = min(Q * 86400 * s_firm / A_cmd * 1000, cap_mm) / d_mm
# with A_cmd = f_irr_measured(irrigation_frac) * area_km2 * 1e6 [m^2].
demand_envelope <- function(date, q, prcp, pet, area_km2,
                            irrigation_frac = NA_real_, region = "India") {
  d <- data.table::data.table(
    date = as.Date(date), q = as.numeric(q), prcp = as.numeric(prcp),
    pet = as.numeric(pet))
  mo <- as.integer(format(d$date, "%m"))
  assert_true(all(is.na(d$pet) | d$pet >= 0),
              "demand_envelope: PET must be non-negative mm/day")
  d[, need := pmax(kc_month(mo, region) * pet - phi_month(mo, region) * prcp, 0)]
  d[, lambda := need / P$d_mm]
  A_cmd <- f_irr_measured(irrigation_frac) * area_km2 * 1e6
  d[, mu := if (is.finite(A_cmd)) {
    pmin(q * 86400 * P$s_firm / A_cmd * 1000, P$cap_mm) / P$d_mm
  } else NA_real_]
  d[, .(date, need_mm = need, lambda, mu)]
}
