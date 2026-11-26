# =====================================================================
# R/config.R -- single source of truth for paths, seeds and parameters.
#
# RULES
#   * No other file in this project may hardcode a filesystem path or a
#     scientific parameter. Everything is read from here.
#   * Absolute data paths live ONLY in this file, and each is overridable
#     through an environment variable so the project is portable.
#   * Every value below is either a definition (claim depth, window) or a
#     predeclared default from the redesign plan Appendix A.
# =====================================================================

# --- Locate the project root via the .qdj_root marker -----------------
.qdj_find_root <- function(start) {
  d <- normalizePath(start, winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, ".qdj_root"))) return(d)
    p <- dirname(d)
    if (identical(p, d)) {
      stop("Could not find project root: no .qdj_root marker found upward from ", start)
    }
    d <- p
  }
}

.qdj_start_dir <- local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  if (length(f)) return(dirname(normalizePath(sub("^--file=", "", f[[1]]))))
  for (i in seq_len(sys.nframe())) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(dirname(normalizePath(of)))
  }
  getwd()
})

QDJ_ROOT <- Sys.getenv("QDJ_ROOT", unset = "")
if (!nzchar(QDJ_ROOT)) QDJ_ROOT <- .qdj_find_root(.qdj_start_dir)
QDJ_ROOT <- normalizePath(QDJ_ROOT, winslash = "/", mustWork = FALSE)

`%||%` <- function(a, b) if (is.null(a)) b else a

# --- Data roots (the ONLY absolute paths; override with env vars) -----
DATA_ROOT <- Sys.getenv("QDJ_DATA_ROOT", unset = "D:/Datasets")
CAMELS_ROOT <- Sys.getenv(
  "QDJ_CAMELS_ROOT",
  unset = file.path(DATA_ROOT, "CIMP6_India", "data_raw", "camels_ind_forcings")
)
DROUGHT_ROOT <- Sys.getenv(
  "QDJ_DROUGHT_ROOT",
  unset = file.path(
    DATA_ROOT, "Drought_Intelligence_Explorer_v2", "source",
    "anixn-drought-intelligence-explorer-d0b1573", "data"
  )
)
CAMELS_PROJ_ROOT <- Sys.getenv(
  "QDJ_CAMELS_PROJ_ROOT",
  unset = file.path(DATA_ROOT, "CAMELS_IND_Proj")
)
CARAVAN_ROOT <- Sys.getenv(
  "QDJ_CARAVAN_ROOT",
  unset = file.path(DATA_ROOT, "Caravan_2025")
)
RESOPS_ROOT <- Sys.getenv(
  "QDJ_RESOPS_ROOT",
  unset = file.path(DATA_ROOT, "ResOpsUS", "extracted", "ResOpsUS")
)
US_COUNTY_ZIP <- Sys.getenv(
  "QDJ_US_COUNTY_ZIP",
  unset = file.path(DATA_ROOT, "US_boundaries", "cb_2020_us_county_500k.zip")
)

# --- Derived input files ----------------------------------------------
CAMELS_FORCING_DIR <- file.path(CAMELS_ROOT, "catchment_mean_forcings")
CAMELS_FLOW_FILE <- file.path(CAMELS_ROOT, "streamflow_timeseries",
                              "streamflow_observed.csv")
CAMELS_ATTR_DIR <- file.path(CAMELS_ROOT, "attributes_csv")
DROUGHT_SOIL_FILE <- file.path(DROUGHT_ROOT, "drought", "soil_moisture.csv")
DROUGHT_SPI3_FILE <- file.path(DROUGHT_ROOT, "drought", "spi_03.csv")
DROUGHT_SPEI3_FILE <- file.path(DROUGHT_ROOT, "drought", "spei_03.csv")
DISTRICT_TABLE_FILE <- file.path(DROUGHT_ROOT, "districts.csv")
DISTRICT_BOUNDARY_FILE <- file.path(DROUGHT_ROOT, "boundaries",
                                    "india_districts.geojson")

# --- Output directories ------------------------------------------------
OUTPUT_DIR <- file.path(QDJ_ROOT, "output")
FIG_DIR <- file.path(QDJ_ROOT, "figures")
PROTOCOL_DIR <- file.path(QDJ_ROOT, "protocol")
SESSION_LOG <- file.path(QDJ_ROOT, "docs", "project", "SESSION_LOG_v2.md")

# --- Scientific parameters (plan Appendix A) --------------------------
P <- list(
  # Unit definitions
  d_mm              = 20,          # claim depth: 20 mm over the command area
  phi               = 0.7,         # effective-rain fraction [assumption]
  # Stage A demand (crop-water envelope)
  sowing_doy        = 200L,        # kharif sowing day-of-year
  season_length     = 120L,        # growing-season length (days)
  kc_base           = 0.4,         # Kc at season start/end
  kc_peak           = 1.2,         # Kc peak
  kc_off            = 0.35,        # Kc outside the season
  f_irr             = 0.10,        # irrigated fraction of catchment [default]
  f_irr_sweep       = c(0.03, 0.10, 0.25),
  # Supply
  s_firm            = 0.5,         # firm share of observed flow (SUP-1)
  cap_mm            = 10,          # infrastructure delivery cap (mm/day)
  cap_mm_sweep      = c(5, 10, 20),
  q95_ref           = 0.95,        # SUP-2 dependable-flow quantile
  eco_frac          = 0.10,        # SUP-3 ecological floor as fraction of mean flow
  # Catchment-relative queue parameters
  q_days            = 60,          # q* = ceil(q_days * lam_bar)
  q_days_sweep      = c(45, 60, 90),
  K_days            = 365,         # K  = min(80, max(25, ceil(K_days * lam_bar)))
  K_days_sweep      = c(180, 365),
  theta_mult        = 1.5,         # theta = ceil(theta_mult * q*)
  alpha             = 1.5,         # service boost above theta
  eta               = 1 / 60,      # reneging rate per day (~60-day tolerance)
  c                 = 1L,          # servers in the main experiment
  # Statistical design
  L2                = 1.0,         # logistic ridge penalty
  train_years       = 1981:2010,
  test_years        = 2011:2020,
  # Data handling
  max_short_gap     = 7L,          # short-gap forward state pause (days)
  long_gap_exclusion = 30L,        # months with a longer gap are excluded
  # Numerical safety
  rk4_dt            = 0.5,         # max RK4 step (days); 0.1 vs 0.5 differ by 4e-8
  rk4_maxrate       = 0.5,         # dt * max rate cap (convergence-checked)
  block_guard       = 1e-3,        # max P(Q = K) before a blocking rerun
  # Screening
  rho_window        = c(0.15, 1.20),
  zero_unresolved_max = 0.30,      # >30% unresolved zeros -> V2 only
  # Minimum events per unit in the confirmatory set. Applied to the DESIGN
  # event counts (complete months), not to raw district months, so a unit with
  # too few usable drought outcomes cannot enter the endpoint as noise.
  min_test_events   = 3L,
  min_train_events  = 5L,
  # Reproducibility
  seed              = 20261125L
  # Note: the transient starts empty at ANALYSIS_START (1981-01-01). The plan's
  # 1980 warm-up is not implemented; the early-month bias is negligible at the
  # service rates used here and is disclosed in protocol/CHANGELOG.md.
)

# Convenience: the analysis calendar
ANALYSIS_START <- as.Date("1981-01-01")
ANALYSIS_END <- as.Date("2020-12-31")

# --- Model families (predeclared) -------------------------------------
MODEL_FAMILIES <- c(
  "climatology", "spi3", "spei3", "ssi3", "queue",
  "ssi3_plus_queue", "spei3_plus_queue", "ssi3_plus_spei3_plus_queue"
)

# --- Supply and zero-flow variants (predeclared) ----------------------
SUPPLY_VARIANTS <- c("SUP-1", "SUP-2", "SUP-3")
ZERO_VARIANTS <- c("V0", "V1", "V2")
PRIMARY_ZERO_VARIANT <- "V1"
PRIMARY_SUPPLY_VARIANT <- "SUP-1"

# --- Small helpers ----------------------------------------------------
ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}
