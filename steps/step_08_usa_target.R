# =====================================================================
# step_08_usa_target.R -- county assignment and USDM target extraction.
#
# OpenET (05_openet_extract.R) is optional and requires OPENET_API_KEY.
# The account quota may be exhausted; the pilot runs without it.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/us_pilot/04_county_match.R", "USA: county assignment")
run_script("R/us_pilot/06_usdm_extract.R", "USA: USDM target")
if (nzchar(Sys.getenv("OPENET_API_KEY"))) {
  cat("\nOPENET_API_KEY detected; OpenET extraction is available but optional.\n")
} else {
  cat("\nNo OPENET_API_KEY: skipping OpenET (demand uses Caravan ET0 + Kc).\n")
}
