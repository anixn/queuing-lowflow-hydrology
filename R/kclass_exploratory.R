# Exploratory (post-hoc, labelled, NOT confirmatory): does the fitted
# recession constant k stratify the storage family's BSS? Hypothesis: the
# fluid state carries memory only where the catchment drains slowly.
Sys.setenv(QDJ_ROOT = "D:/Research/queuing-lowflow-hydrology")
setwd("D:/Research/queuing-lowflow-hydrology")
source("R/config.R")
for (u in c("eval.R", "io.R")) source(file.path("R", "functions", u))
suppressMessages(library(data.table))
bss <- fread(file.path(OUTPUT_DIR, "p1_bss.csv"))
prm <- fread(file.path(OUTPUT_DIR, "p1_storage_params.csv"))
bss[, gauge_id := as.character(gauge_id)]
prm[, gauge_id := as.character(gauge_id)]
m <- merge(bss, prm[, .(gauge_id, k_days, S_cap_mm, BFI, zero_frac)],
           by = "gauge_id")
m <- m[family %in% c("storage", "storage_plus_indices", "persistence",
                     "lagged_indices") & target == "t1"]
m[, k_class := fifelse(k_days >= 30, "slow (k >= 30 d)",
                fifelse(k_days >= 10, "medium (10-30 d)", "fast (k < 10 d)"))]
cat("k_class counts:\n")
print(m[lead == 3 & family == "storage", .N, by = k_class])
out <- m[, .(median_bss = stats::median(bss), n = .N),
         by = .(family, lead, k_class)]
out <- out[order(lead, family, k_class)]
write_csv_sidecar(out, file.path(OUTPUT_DIR, "p1_bss_by_kclass.csv"))
cat("\nMedian BSS (T1) by recession-speed class (EXPLORATORY):\n")
print(dcast(out, family + lead ~ k_class, value.var = "median_bss"), digits = 3)
