# =====================================================================
# R/install_packages.R -- install the R packages this project needs.
#
# renv is NOT installed in the current environment, so no renv lockfile is
# shipped. This script is the documented fallback: it installs only the
# CRAN packages the code actually uses, and prints versions for the record.
#
# Usage:
#   Rscript R/install_packages.R
# =====================================================================
pkgs <- c("data.table", "ggplot2", "sf", "rmarkdown", "knitr",
          "jsonlite", "lubridate")

missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  message("Installing: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

installed <- vapply(pkgs, function(p) {
  if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p))
  else NA_character_
}, character(1))
print(data.frame(package = pkgs, version = installed, row.names = NULL))
cat("\nR version:", R.version.string, "\n")
cat("Optional: install.packages('renv') and run renv::init() to add a lockfile.\n")
