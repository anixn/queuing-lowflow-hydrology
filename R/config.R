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
CARAVAN_ROOT <- Sys.getenv(
  "QDJ_CARAVAN_ROOT",
  unset = file.path(DATA_ROOT, "Caravan_2025")
)

# --- Derived input files ----------------------------------------------
CAMELS_FORCING_DIR <- file.path(CAMELS_ROOT, "catchment_mean_forcings")
CAMELS_FLOW_FILE <- file.path(CAMELS_ROOT, "streamflow_timeseries",
                              "streamflow_observed.csv")
CAMELS_ATTR_DIR <- file.path(CAMELS_ROOT, "attributes_csv")

# Map outlines only (figures; no analysis uses these).
DIE_DATA_ROOT <- Sys.getenv(
  "QDJ_DIE_ROOT",
  unset = file.path(DATA_ROOT, "Drought_Intelligence_Explorer_v2", "source",
                    "anixn-drought-intelligence-explorer-d0b1573", "data"))
INDIA_OUTLINE_FILE <- file.path(DIE_DATA_ROOT, "boundaries", "india_outline.geojson")
INDIA_STATES_FILE <- file.path(DIE_DATA_ROOT, "boundaries", "india_states.geojson")

# --- Output directories ------------------------------------------------
OUTPUT_DIR <- file.path(QDJ_ROOT, "output")
FIG_DIR <- file.path(QDJ_ROOT, "figures")

# --- Scientific parameters (plan Appendix A) --------------------------
P <- list(
  # Unit definitions
  d_mm              = 20,          # claim depth: 20 mm over the command area
  phi               = 0.7,         # effective-rain fraction [assumption]
  Kc                = 0.8,         # common crop coefficient (both regions)
  f_irr             = 0.10,        # irrigated fraction of catchment
  # Supply
  s_firm            = 0.5,         # firm share of observed flow (SUP-1)
  cap_mm            = 10,          # infrastructure delivery cap (mm/day)
  # Catchment-relative queue parameters
  q_days            = 60,          # q* = ceil(q_days * lam_bar)
  K_days            = 365,         # K  = min(80, max(25, ceil(K_days * lam_bar)))
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
  # Minimum design events per catchment in the paired set.
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
