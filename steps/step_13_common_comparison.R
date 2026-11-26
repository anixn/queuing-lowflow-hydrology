# =====================================================================
# step_13_common_comparison.R -- like-for-like India-US comparison under
# protocol/COMMON_PROTOCOL.md.
#
# Identical in both regions: f_irr=0.10, Kc=0.8, SUP-1, SPI-3 target,
# 1981-2010 / 2011-2020 split, eight families, paired Brier/AUC.
# =====================================================================
source("steps/_helpers.R")
step_init()
run_script("R/compare/01_screen_us_gauges.R", "Common: Caravan-US gauge screen")
run_script("R/compare/02_common_arm.R", "Common: India-US comparison")
