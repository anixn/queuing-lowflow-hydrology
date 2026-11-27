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
# CAMELS-IND has been mounted under more than one layout on this machine.
# The environment variable wins; otherwise the first existing candidate is
# used, and the original default is kept as the last resort so a missing
# dataset fails with a path the operator recognises.
.camels_candidates <- c(
  file.path(DATA_ROOT, "CIMP6_India", "data_raw", "camels_ind_forcings"),
  file.path(DATA_ROOT, "CAMELS-IND", "CAMELS_IND_All_Catchments")
)
CAMELS_ROOT <- Sys.getenv("QDJ_CAMELS_ROOT", unset = "")
if (!nzchar(CAMELS_ROOT)) {
  hit <- .camels_candidates[dir.exists(.camels_candidates)]
  CAMELS_ROOT <- if (length(hit)) hit[1] else .camels_candidates[1]
}
CARAVAN_ROOT <- Sys.getenv(
  "QDJ_CARAVAN_ROOT",
  unset = file.path(DATA_ROOT, "Caravan_B")
)

# --- Derived input files ----------------------------------------------
CAMELS_FORCING_DIR <- file.path(CAMELS_ROOT, "catchment_mean_forcings")
CAMELS_FLOW_FILE <- file.path(CAMELS_ROOT, "streamflow_timeseries",
                              "streamflow_observed.csv")
CAMELS_ATTR_DIR <- file.path(CAMELS_ROOT, "attributes_csv")

# Map outlines only (figures; no analysis uses these).
# The repository of the Drought Intelligence Explorer has moved between
# drafts; the first existing candidate wins, and QDJ_DIE_ROOT overrides all.
.die_candidates <- c(
  file.path(DATA_ROOT, "Drought_Intelligence_Explorer_v2", "source",
            "anixn-drought-intelligence-explorer-d0b1573", "data"),
  "D:/Websites/drought-intelligence-explorer-v2.0/data"
)
DIE_DATA_ROOT <- Sys.getenv("QDJ_DIE_ROOT", unset = "")
if (!nzchar(DIE_DATA_ROOT)) {
  hit <- .die_candidates[dir.exists(.die_candidates)]
  DIE_DATA_ROOT <- if (length(hit)) hit[1] else .die_candidates[1]
}
INDIA_OUTLINE_FILE <- file.path(DIE_DATA_ROOT, "boundaries", "india_outline.geojson")
INDIA_STATES_FILE <- file.path(DIE_DATA_ROOT, "boundaries", "india_states.geojson")

# --- Output directories ------------------------------------------------
OUTPUT_DIR <- file.path(QDJ_ROOT, "paper01", "output")
FIG_DIR <- file.path(QDJ_ROOT, "paper01", "figures")

# --- Pivot parameters (PIVOT.md §3 Gate G2 and §4 Study P1) ------------
# PET source: "shipped" = the dataset PET column carried by the forcings
# (GLEAM `pet_gleam(mm/day)` in CAMELS-IND; FAO Penman-Monteith in
# Caravan-US); "hargreaves" = the retired temperature-based arm, kept only
# as a declared sensitivity axis (PIVOT.md §4.4/FQ6).
PET_SOURCE <- Sys.getenv("QDJ_PET_SOURCE", unset = "shipped")
stopifnot(PET_SOURCE %in% c("shipped", "hargreaves"))
# US transfer arm on/off (PIVOT.md §4.2; India is the study).
TRANSFER_ARM <- Sys.getenv("QDJ_TRANSFER_ARM", unset = "on")
stopifnot(TRANSFER_ARM %in% c("on", "off"))

# Seasonal demand envelope [assumption: FAO-56-style two-season
# simplification of kharif (Jun-Oct) / rabi (Nov-Mar) crop stages; a
# sensitivity axis, not a claim]. Annual means: India Kc 0.846 (old 0.80),
# phi 0.675 (old 0.70). The USA keeps the flat retired values [assumption:
# flat envelope for the transfer region; not calibrated on US data].
KC_MONTHLY <- list(
  India = c(0.85, 0.85, 0.85, 0.70, 0.70, 0.90, 0.90, 0.90, 0.90, 0.90,
            0.85, 0.85),
  USA   = c(0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
)
PHI_MONTHLY <- list(
  India = c(0.85, 0.85, 0.85, 0.85, 0.60, 0.45, 0.45, 0.45, 0.45, 0.60,
            0.85, 0.85),
  USA   = c(0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
)

# Ridge-penalty grid and fold structure for per-family CV tuning (FS3
# fix, PIVOT.md §3 change 6 / §4.7). Folds are contiguous calendar-year
# blocks inside the training years, frozen here before any scoring run.
RIDGE_GRID  <- c(0.1, 0.3, 1, 3, 10)
RIDGE_FOLDS <- 5L

# Antecedent Precipitation Index (memory baseline, PIVOT.md §3 change 5 /
# §4.6): recursive API_t = k * API_{t-1} + P_t [assumption: decay k = 0.95,
# effective memory ~90 days (1 - 0.95^90 ~= 0.99)].
API_DECAY <- 0.95
API_DAYS  <- 90L

# P1 leads in months. 1, 3 and 6 are the FROZEN confirmatory set
# (PIVOT.md §4.1: H0 at 1, H1 at 3, H2 at 6). 2 and 12 were added on
# 27 November 2026 as a declared post-hoc extension: they are descriptive
# only, they never enter a confirmatory decision, and they are labelled as
# exploratory in every output. The frozen three are unchanged.
P1_LEADS <- c(1L, 2L, 3L, 6L, 12L)
P1_LEADS_FROZEN <- c(1L, 3L, 6L)
P1_LEADS_EXPLORATORY <- c(2L, 12L)

# P1 debug switch: limit the number of gauges per region (0 = all).
P1_LIMIT <- suppressWarnings(as.integer(Sys.getenv("QDJ_P1_LIMIT", unset = "0")))
if (is.na(P1_LIMIT)) P1_LIMIT <- 0L

# P1 screen and fit criteria (PIVOT.md §4.2, §4.4, §4.7), frozen before
# any P1 scoring run:
P1_MIN_SEGMENTS <- 20L        # recession-quality screen (>=20 segments)
P1_MIN_SEG_DAYS <- 10L        # segment length (days)
# Rain-day threshold that breaks a recession segment [assumption: a
# significant-rainfall day is >= 5 mm/day; trace rainfall does not break
# a recession. Diagnostics on 24 gauges: counts at 1/5/10 mm differ
# little for perennial gauges; 5 mm is the declared default].
P1_RAIN_DAY_MM <- 5
P1_MIN_TRAIN_EVENTS <- 8L     # target events in training years per target
P1_WARMUP_YEARS <- 2L         # S(0) = S_cap/2 warm-up excluded from features
P1_FEATURE_START_YEAR <- 1982L  # first year with storage features
P1_HARM_BOUND <- 0.005        # declared harm bound [assumption: §4.1]
P1_BOOT_B <- 2000L

# --- Scientific parameters --------------------------------------------
# Two groups only.
#
# (a) Study P1 -- the storage state and the statistical design. The P1
#     state is a depth in mm over the catchment and has NO demand model;
#     there is no claim, no utilisation and no capacity on this path.
#
# (b) Study P3 -- the frozen CTMC engine (R/functions/queue_engine.R) and
#     the measured demand envelope it consumes (demand_envelope.R). These
#     parameters are inert for P1: nothing in study_p1.R reads them.
P <- list(
  # --- (a) Study P1 ---------------------------------------------------
  train_years       = 1981:2010,
  test_years        = 2011:2020,
  # Data handling
  max_short_gap     = 7L,          # short-gap forward state pause (days)
  long_gap_exclusion = 30L,        # months with a longer gap are excluded
  # Reproducibility
  seed              = 20261125L,

  # --- (b) Study P3: frozen CTMC + demand envelope ---------------------
  # Unit definitions (the demand envelope's claim depth and the command
  # area that the measured irrigated fraction scales).
  d_mm              = 20,          # claim depth: 20 mm over the command area
  f_irr             = 0.10,        # fallback irrigated fraction [assumption]
  # Supply
  s_firm            = 0.5,         # firm share of observed flow (SUP-1)
  cap_mm            = 10,          # infrastructure delivery cap (mm/day)
  # Catchment-relative queue parameters (thresholds_from_lambda defaults)
  q_days            = 60,          # q* = ceil(q_days * lam_bar)
  K_days            = 365,         # K  = min(80, max(25, ceil(K_days * lam_bar)))
  theta_mult        = 1.5,         # theta = ceil(theta_mult * q*)
  c                 = 1L,          # servers in the main experiment
  # Numerical safety of the RK4 propagator
  rk4_dt            = 0.5,         # max RK4 step (days); 0.1 vs 0.5 differ by 4e-8
  rk4_maxrate       = 0.5,         # dt * max rate cap (convergence-checked)
  block_guard       = 1e-3,        # max P(Q = K) before a blocking rerun
  # Measured demand envelope: per-catchment irrigated fraction from
  # CAMELS-IND `irrigation_frac` (HydroATLAS), replacing the flat 0.10
  # [assumption: floor of 0.01 keeps the command area defined where the
  # attribute is 0; the floor is a declared default, not a measurement].
  f_irr_floor       = 0.01,
  f_irr_cap         = 1.0
)

# --- Small helpers ----------------------------------------------------
ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}
