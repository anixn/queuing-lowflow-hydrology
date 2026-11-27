# =====================================================================
# R/novelty_p1_screen.R -- rapid P1 prior-art screen (27 Nov 2026).
# Explicitly NOT a WoS/Scopus exhaustive screen. Crossref + OpenAlex,
# four exact PIVOT.md queries, top 100 records per database/query screened
# by title and available abstract; forward-citation traces of the two seed
# DOIs through OpenAlex (top 100 by citation count each).
#
# Outputs:
#   paper01/literature/p1_novelty_screen_2026-11-27.csv + JSON (query log)
#   paper01/literature/p1_novelty_records_2026-11-27.csv + JSON (records + decision)
#   paper01/literature/p1_novelty_summary_2026-11-27.csv + JSON (aggregate)
# The agent manually reviews the candidate records and writes the Markdown
# decision record paper01/literature/p1_novelty_screen_2026-11-27.md.
# =====================================================================
local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  script <- if (length(f)) normalizePath(sub("^--file=", "", f[[1]])) else
    normalizePath("R/novelty_p1_screen.R")
  root <- normalizePath(file.path(dirname(script), ".."))
  source(file.path(root, "R", "config.R"))
  for (u in c("io.R", "pipeline.R")) source(file.path(root, "R", "functions", u))
  suppressMessages(library(data.table))
  LIT_DIR <- file.path(root, "paper01", "literature")
  ensure_dir(LIT_DIR)

  queries <- data.table(
    id = c("P1-S1", "P1-S2", "P1-S3", "P1-S4"),
    query = c(
      "(storage deficit OR storage state OR recession OR baseflow) AND (drought forecast OR low flow forecast) AND (India OR large sample OR CAMELS)",
      "catchment memory AND drought AND forecast",
      "(SPEI OR SSI OR flow duration OR Q90) AND (sub-seasonal OR seasonal) AND (forecast OR prediction) AND India",
      "(hydrological drought OR streamflow drought OR low flow) AND India AND (forecast OR prediction)"
    ),
    source = "PIVOT.md section 9 (S4 is a direct India hydrological-forecast check added 27 Nov 2026)"
  )
  seeds <- c("10.1038/s41598-022-06553-5", "10.3389/frwa.2025.1709138")

  get_json <- function(url, params) {
    for (a in 1:3) {
      r <- tryCatch(httr::GET(url, query = params,
        httr::timeout(90),
        httr::user_agent("queuing-lowflow-hydrology-P1-screen/1.0"),
        httr::accept_json()), error = function(e) NULL)
      if (!is.null(r) && httr::status_code(r) == 200) {
        txt <- httr::content(r, as = "text", encoding = "UTF-8")
        return(jsonlite::fromJSON(txt, simplifyVector = TRUE))
      }
      Sys.sleep(2 * a)
    }
    NULL
  }
  abstract_oa <- function(inv) {
    if (is.null(inv)) return(NA_character_)
    if (!is.list(inv)) return(NA_character_)
    words <- unlist(inv, use.names = FALSE)
    positions <- suppressWarnings(as.integer(unlist(inv, use.names = FALSE)))
    if (!length(positions) || anyNA(positions)) return(paste(words, collapse = " "))
    if (!length(words)) return(NA_character_)
    txt <- rep("", max(positions))
    txt[positions] <- words
    paste(txt, collapse = " ")
  }
  records <- list(); query_rows <- list()

  # ---- exact database queries ----------------------------------------
  for (i in seq_len(nrow(queries))) {
    q <- queries$query[i]
    # OpenAlex
    oa <- get_json("https://api.openalex.org/works",
                   list(search = q, `per-page` = 100,
                        select = "id,doi,title,publication_year,abstract_inverted_index,cited_by_count,primary_location"))
    if (!is.null(oa)) {
      query_rows[[length(query_rows) + 1]] <- data.table(
        query_id = queries$id[i], database = "OpenAlex", date = "2026-11-27",
        query = q, raw_hits = as.integer(oa$meta$count),
        retrieved = if (is.null(oa$results)) 0L else nrow(oa$results),
        screened_scope = "top 100 by relevance; title + available abstract")
      if (!is.null(oa$results)) for (j in seq_len(nrow(oa$results))) {
        r <- oa$results[j, ]
        records[[length(records) + 1]] <- data.table(
          query_id = queries$id[i], database = "OpenAlex",
          doi = if (is.null(r$doi)) NA_character_ else tolower(sub("^https://doi.org/", "", r$doi)),
          title = r$title, year = r$publication_year,
          abstract = abstract_oa(r$abstract_inverted_index),
          cited_by = r$cited_by_count)
      }
    } else query_rows[[length(query_rows) + 1]] <- data.table(
      query_id = queries$id[i], database = "OpenAlex", date = "2026-11-27",
      query = q, raw_hits = NA_integer_, retrieved = 0L,
      screened_scope = "API unavailable")

    # Crossref
    cr <- get_json("https://api.crossref.org/works",
                   list(`query.bibliographic` = q, rows = 100,
                        select = "DOI,title,abstract,author,published,container-title,score"))
    if (!is.null(cr)) {
      items <- cr$message$items
      query_rows[[length(query_rows) + 1]] <- data.table(
        query_id = queries$id[i], database = "Crossref", date = "2026-11-27",
        query = q, raw_hits = as.integer(cr$message$`total-results`),
        retrieved = if (is.null(items)) 0L else nrow(items),
        screened_scope = "top 100 by relevance; title + available abstract")
      if (!is.null(items)) for (j in seq_len(nrow(items))) {
        r <- items[j, ]
        records[[length(records) + 1]] <- data.table(
          query_id = queries$id[i], database = "Crossref",
          doi = if (is.null(r$DOI)) NA_character_ else tolower(r$DOI),
          title = if (is.list(r$title)) paste(unlist(r$title), collapse = " ") else r$title,
          year = if (is.null(r$published)) NA_integer_ else {
            dp <- r$published$`date-parts`
            if (is.null(dp)) NA_integer_ else as.integer(unlist(dp)[1])
          },
          abstract = if (is.null(r$abstract)) NA_character_ else r$abstract,
          cited_by = if (is.null(r$score)) NA_integer_ else as.integer(r$score))
      }
    } else query_rows[[length(query_rows) + 1]] <- data.table(
      query_id = queries$id[i], database = "Crossref", date = "2026-11-27",
      query = q, raw_hits = NA_integer_, retrieved = 0L,
      screened_scope = "API unavailable")
  }

  # ---- forward-citation traces through OpenAlex -----------------------
  for (doi in seeds) {
    seed <- get_json(paste0("https://api.openalex.org/works/https://doi.org/", doi),
                     list(select = "id,doi,title"))
    if (is.null(seed)) next
    oaid <- sub("^https://openalex.org/", "", seed$id)
    ct <- get_json("https://api.openalex.org/works",
                   list(filter = paste0("cites:", oaid), `per-page` = 100,
                        sort = "cited_by_count:desc",
                        select = "id,doi,title,publication_year,abstract_inverted_index,cited_by_count,primary_location"))
    if (!is.null(ct)) {
      query_rows[[length(query_rows) + 1]] <- data.table(
        query_id = paste0("CITES-", doi), database = "OpenAlex", date = "2026-11-27",
        query = paste0("forward citations of ", doi),
        raw_hits = as.integer(ct$meta$count),
        retrieved = if (is.null(ct$results)) 0L else nrow(ct$results),
        screened_scope = "top 100 by cited_by_count; title + available abstract")
      if (!is.null(ct$results)) for (j in seq_len(nrow(ct$results))) {
        r <- ct$results[j, ]
        records[[length(records) + 1]] <- data.table(
          query_id = paste0("CITES-", doi), database = "OpenAlex",
          doi = if (is.null(r$doi)) NA_character_ else tolower(sub("^https://doi.org/", "", r$doi)),
          title = r$title, year = r$publication_year,
          abstract = abstract_oa(r$abstract_inverted_index),
          cited_by = r$cited_by_count)
      }
    }
  }

  # Collapse duplicate DOI/title records across queries and databases, then
  # run the deterministic title/abstract relevance flags used to surface the
  # 21 candidates that were manually reviewed below.
  qlog <- rbindlist(query_rows, fill = TRUE)
  rec <- rbindlist(records, fill = TRUE)
  rec[, key := fifelse(!is.na(doi), paste0("doi:", doi),
                       paste0("title:", tolower(trimws(title))))]
  rec <- unique(rec, by = "key", fromLast = TRUE)
  txt <- tolower(paste(rec$title, rec$abstract, sep = " "))
  rec[, flood := grepl("flood|flash flood|storm surge", txt)]
  rec[, hydrology := grepl("hydrolog|streamflow|river flow|low flow|water storage|baseflow|recession", txt)]
  rec[, forecasting := grepl("forecast|predict", txt)]
  rec[, india := grepl("india|indian|camels", txt)]
  rec[, memory_storage := grepl("storage deficit|storage state|recession|baseflow|catchment memory", txt)]
  rec[, candidate := !flood & hydrology & forecasting & (india | memory_storage)]

  # Agent's manual decisions for the deterministic candidates (27 Nov 2026).
  # Every candidate is dropped as adjacent prior art or a false match; none
  # combines India large sample + recession-derived storage features +
  # 1-6 month probabilistic forecasts + memory baselines + verified state +
  # pre-registered confirmatory contrasts.
  manual <- data.table(
    doi = c("10.5194/hess-21-707-2017", "10.5194/egusphere-egu26-9100",
            "10.5194/egusphere-egu2020-5509", "10.1175/jhm-d-20-0235.1",
            "10.1002/hyp.70413", "10.1029/2021jd035737",
            "10.1038/s41598-022-06553-5", "10.1175/jhm-d-15-0050.1",
            "10.1002/clen.202300430", "10.2139/ssrn.1138371",
            "10.20955/es.2018.30", "10.2139/ssrn.3422278",
            "10.5194/hess-2019-590", "10.1016/j.scitotenv.2020.141220",
            "10.1002/hyp.70106", "10.5194/hess-2019-311",
            "10.5194/hess-2018-248", "10.5194/hess-2021-89",
            "10.54302/mausam.v31i1.4279", "10.5194/egusphere-egu2020-10208",
            "10.5194/egusphere-2026-5964"),
    decision = c(
      "adjacent: India 7-45 day VIC forecast; no recession-storage feature or memory-baseline contrast",
      "adjacent: global recession-process analysis; no forecasting",
      "adjacent: CAMELS-GB baseflow controls; no forecasting",
      "adjacent: India VIC/bias-correction 1-3 day forecast; no storage feature",
      "drop: California non-perennial network monitoring; no forecasting",
      "adjacent: India SubX/ERFS VIC 1-30 day forecast; no storage feature",
      "adjacent: Europe catchment-memory skill relationship; not India, not a storage-feature forecast test",
      "adjacent: India medium-range meteorological/hydrologic forecast; no storage feature",
      "adjacent: one-basin India LSTM/MLP with lagged SSI; no recession-derived storage or memory baselines",
      "drop: economic recession false match",
      "drop: economic recession false match",
      "drop: economic recession false match",
      "adjacent: GRACE storage-deficit recovery; no Indian catchment forecast benchmark",
      "adjacent: aquifer eigenmodels during recession; no India large-sample index-forecast contrast",
      "adjacent: recession-derived storage estimates in seven US catchments; no forecasting",
      "adjacent: Australian catchment drought propagation; no seasonal forecast comparison",
      "adjacent: German baseflow-drought trends/projections; no probabilistic index-forecast benchmark",
      "drop: DOC/chemistry study; not a drought forecast benchmark",
      "adjacent: single Indian catchment Sacramento runoff model; no probabilistic drought benchmark",
      "adjacent: 224-station India drought propagation; no forecasting/storage feature",
      "adjacent: US CAMELS drought propagation; not India and not a forecast-feature test"),
    gap_changing = rep(FALSE, 21))
  rec <- merge(rec, manual, by = "doi", all.x = TRUE,
               suffixes = c("", "_manual"))
  rec[is.na(decision), decision := "drop: automated relevance filter"]
  rec[, manual_review := decision != "drop: automated relevance filter"]
  rec <- rec[order(manual_review, decision, -cited_by, year)]

  qlog <- rbindlist(query_rows, fill = TRUE)
  write_csv_sidecar(qlog, file.path(LIT_DIR, "p1_novelty_screen_2026-11-27.csv"),
                    meta = list(scope = "rapid Crossref/OpenAlex title-abstract screen, not exhaustive WoS/Scopus"))
  write_csv_sidecar(rec, file.path(LIT_DIR, "p1_novelty_records_2026-11-27.csv"),
                    meta = list(scope = "top 100 per database/query plus top-100 OpenAlex citation traces"))
  sm <- qlog[, .(raw_hits = sum(raw_hits, na.rm = TRUE),
                 retrieved = sum(retrieved),
                 queries = .N), by = database]
  sm[, unique_records_after_deduplication := nrow(rec)]
  sm[, candidates_manually_reviewed := sum(rec$manual_review)]
  sm[, gap_changing_findings := sum(rec$gap_changing, na.rm = TRUE)]
  sm[, record_decisions := if (database[1] == "OpenAlex") "see p1_novelty_records CSV" else "combined across both databases"]
  write_csv_sidecar(sm, file.path(LIT_DIR, "p1_novelty_summary_2026-11-27.csv"),
                    meta = list(scope = "rapid P1 prior-art screen"))
  cat("Rapid screen complete. Query log:\n"); print(qlog)
  cat("Candidates manually reviewed:\n")
  print(rec[manual_review == TRUE, .(doi, year, title, decision)])
})
