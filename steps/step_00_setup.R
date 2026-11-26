# =====================================================================
# step_00_setup.R -- check the environment, packages and input data.
#
# Purpose : fail fast before any long step.
# Inputs  : R/config.R, local data roots.
# Outputs : none (prints a readiness report).
# =====================================================================
source("steps/_helpers.R")
root <- step_init()
source(file.path(root, "R", "config.R"))

cat("Project root :", root, "\n")
cat("R version    :", R.version.string, "\n\n")

pkgs <- c("data.table", "ggplot2", "sf", "rmarkdown", "knitr",
          "jsonlite", "lubridate", "rnaturalearth", "maps")
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("  %-15s %s\n", p, if (ok) "ok" else "MISSING"))
}
if (any(!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE))) {
  stop("Install missing packages with: Rscript R/install_packages.R",
       call. = FALSE)
}

inputs <- c(
  "CAMELS flow"      = CAMELS_FLOW_FILE,
  "CAMELS forcings"  = CAMELS_FORCING_DIR,
  "CAMELS attributes"= CAMELS_ATTR_DIR,
  "Drought SMA"      = DROUGHT_SOIL_FILE,
  "District polygons"= DISTRICT_BOUNDARY_FILE,
  "Caravan US"       = "D:/Datasets/Caravan_2025/timeseries/camels",
  "ResOpsUS"         = "D:/Datasets/ResOpsUS/extracted/ResOpsUS"
)
cat("\nInput data:\n")
for (nm in names(inputs)) {
  cat(sprintf("  %-20s %s  %s\n", nm, if (file.exists(inputs[[nm]])) "ok  " else "MISS",
              inputs[[nm]]))
}

for (d in c(OUTPUT_DIR, FIG_DIR, file.path(root, "output_us"),
            file.path(root, "manuscript", "figures"))) {
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
}
cat("\nSetup checks complete.\n")
