# =====================================================================
# R/functions/io.R -- data access and provenance sidecars.
#
# All raw-data reading goes through here. Gauge identifiers are
# normalised to integer; dates are always Date. Every generated CSV gets a
# JSON sidecar recording the git hash, code hash, shape and R session.
# =====================================================================

# --- Provenance -------------------------------------------------------
git_hash <- function(root = QDJ_ROOT) {
  h <- tryCatch(system2("git", c("-C", shQuote(root), "rev-parse", "--short", "HEAD"),
                        stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
  if (length(h) == 0) NA_character_ else trimws(h[1])
}

# Fingerprint of the R source tree that produced an output. This is recorded
# alongside the git hash so a sidecar identifies the code that actually ran,
# even when the working tree was uncommitted.
code_hash <- function(root = QDJ_ROOT) {
  dirs <- c(file.path(root, "R"), file.path(root, "steps"))
  files <- unlist(lapply(dirs[dir.exists(dirs)], function(d)
    list.files(d, pattern = "\\.(R|Rmd)$", recursive = TRUE, full.names = TRUE)))
  files <- sort(files)
  if (!length(files)) return(NA_character_)
  md5 <- tools::md5sum(files)
  tmp <- tempfile()
  writeLines(paste(basename(files), unname(md5), sep = ":"), tmp)
  h <- unname(tools::md5sum(tmp))
  unlink(tmp)
  h
}

write_csv_sidecar <- function(df, path, meta = list()) {
  ensure_dir(dirname(path))
  utils::write.csv(df, path, row.names = FALSE, na = "")
  sidecar <- sub("\\.csv$", ".json", path)
  # AGENTS.md §4.6: the sidecar carries the git hash, parameters, seed and
  # R session. The seed is the configured one whenever config.R is loaded;
  # a caller can override it through `meta$seed`.
  seed <- if (exists("P", inherits = TRUE) && !is.null(P$seed)) P$seed else NA
  payload <- c(
    list(file = basename(path), git_hash = git_hash(),
         code_hash = code_hash(),
         written = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
         seed = seed,
         nrow = nrow(df), ncol = ncol(df),
         session = list(R = R.version.string,
                        platform = R.version$platform)),
    meta
  )
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(payload, sidecar, auto_unbox = TRUE, pretty = TRUE)
  }
  invisible(path)
}

# --- CAMELS-IND attributes -------------------------------------------
.read_attr <- function(file) {
  if (!file.exists(file)) return(NULL)
  d <- utils::read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
  d$gauge_id <- as.integer(d$gauge_id)
  d
}

read_camels_attributes <- function() {
  files <- c(name = "camels_ind_name.csv", topo = "camels_ind_topo.csv",
             clim = "camels_ind_clim.csv", anth = "camels_ind_anth.csv",
             land = "camels_ind_land.csv")
  out <- NULL
  for (nm in names(files)) {
    d <- .read_attr(file.path(CAMELS_ATTR_DIR, files[[nm]]))
    if (is.null(d)) next
    if (is.null(out)) out <- d else out <- merge(out, d, by = "gauge_id", all = TRUE)
  }
  out
}

# --- CAMELS-IND forcings ---------------------------------------------
.read_forcing_one <- function(gauge_id) {
  f <- file.path(CAMELS_FORCING_DIR, sprintf("%05d.csv", as.integer(gauge_id)))
  if (!file.exists(f)) return(NULL)
  d <- utils::read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)
  nm <- names(d)
  pick <- function(pat) {
    i <- grep(pat, nm, fixed = TRUE)
    if (length(i)) nm[i[1]] else NA_character_
  }
  map <- c(prcp_mm = "prcp(mm/day)", tmax_c = "tmax(C)", tmin_c = "tmin(C)",
           tavg_c = "tavg(C)", pet_mm = "pet(mm/day)",
           pet_gleam_mm = "pet_gleam(mm/day)", aet_gleam_mm = "aet_gleam(mm/day)",
           srad_sw = "srad_sw(w/m2)", srad_lw = "srad_lw(w/m2)",
           wind_ms = "wind(m/s)", sm_lvl1 = "sm_lvl1(kg/m2)",
           sm_lvl2 = "sm_lvl2(kg/m2)", sm_lvl3 = "sm_lvl3(kg/m2)",
           sm_lvl4 = "sm_lvl4(kg/m2)")
  out <- data.frame(gauge_id = as.integer(gauge_id),
                    date = as.Date(sprintf("%04d-%02d-%02d", d$year, d$month, d$day)))
  for (k in names(map)) {
    i <- match(map[[k]], nm)
    out[[k]] <- if (is.na(i)) NA_real_ else d[[i]]
  }
  out[order(out$date), ]
}

read_camels_forcing <- function(gauge_ids) {
  do.call(rbind, lapply(gauge_ids, .read_forcing_one))
}

# --- CAMELS-IND streamflow -------------------------------------------
read_camels_flow <- function(gauge_ids) {
  d <- utils::read.csv(CAMELS_FLOW_FILE, stringsAsFactors = FALSE,
                       check.names = FALSE)
  d$date <- as.Date(sprintf("%04d-%02d-%02d", d$year, d$month, d$day))
  cols <- as.character(as.integer(gauge_ids))
  cols <- cols[cols %in% names(d)]
  out <- data.frame(date = d$date)
  for (g in cols) out[[g]] <- d[[g]]
  out[order(out$date), ]
}


# --- Monthly aggregation ---------------------------------------------
# Complete-month rule: a month is complete only if every day is present
# and none is flagged excluded. Returns one row per complete month.
monthly_complete <- function(daily, value_cols, date_col = "date",
                             exclude_flag = "flag_excluded") {
  d <- daily
  d$year <- as.integer(format(d[[date_col]], "%Y"))
  d$month <- as.integer(format(d[[date_col]], "%m"))
  keys <- unique(d[, c("year", "month")])
  rows <- vector("list", nrow(keys))
  for (i in seq_len(nrow(keys))) {
    g <- d[d$year == keys$year[i] & d$month == keys$month[i], ]
    n_days <- as.integer(lubridate::days_in_month(
      as.Date(sprintf("%04d-%02d-01", keys$year[i], keys$month[i]))))
    complete <- nrow(g) == n_days &&
      (!exclude_flag %in% names(g) || !any(g[[exclude_flag]], na.rm = TRUE)) &&
      all(stats::complete.cases(g[, value_cols, drop = FALSE]))
    if (!complete) next
    row <- data.frame(year = keys$year[i], month = keys$month[i],
                      date = as.Date(sprintf("%04d-%02d-01", keys$year[i], keys$month[i])))
    for (v in value_cols) row[[v]] <- mean(g[[v]], na.rm = FALSE)
    rows[[i]] <- row
  }
  do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
}
