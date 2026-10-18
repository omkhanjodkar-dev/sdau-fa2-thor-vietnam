## 00_profile_raw.R -- one-time streaming profile of the raw THOR file.
## Streams the 1.5 GB CSV in chunks so that memory stays low, and writes a
## profile report to outputs/00_raw_profile.txt.
suppressMessages({library(readr)})
options(stringsAsFactors = FALSE)

raw_path <- "dataset/THOR_Vietnam_Bombing_Operations.csv"
out_path <- "outputs/00_raw_profile.txt"
dir.create("outputs", showWarnings = FALSE)

hdr <- names(read_csv(raw_path, n_max = 0, show_col_types = FALSE))
n_col <- length(hdr)

num_cand <- c("NUMWEAPONSDELIVERED", "WEAPONTYPEWEIGHT", "WEAPONSLOADEDWEIGHT",
              "RELEASEALTITUDE", "RELEASEFLTSPEED", "FLTHOURS", "NUMOFACFT",
              "NUMWEAPONSJETTISONED", "NUMWEAPONSRETURNED", "TGTLATDD_DDD_WGS84",
              "TGTLONDDD_DDD_WGS84", "TIMEONTARGET", "TIMEOFFTARGET")
cat_cand <- c("COUNTRYFLYINGMISSION", "MILSERVICE", "SOURCEID", "SOURCERECORD",
              "VALID_AIRCRAFT_ROOT", "TAKEOFFLOCATION", "TGTTYPE", "WEAPONTYPECLASS",
              "AIRCRAFT_ROOT", "AIRFORCEGROUP", "AIRFORCESQDN", "MFUNC", "MFUNC_DESC",
              "OPERATIONSUPPORTED", "PERIODOFDAY", "TGTCLOUDCOVER", "TGTCONTROL",
              "TGTCOUNTRY", "TGTORIGCOORDSFORMAT", "TGTWEATHER", "GEOZONE",
              "MFUNC_DESC_CLASS")

na_count  <- setNames(numeric(n_col), hdr)
num_stat  <- lapply(num_cand, function(x) list(n = 0, bad = 0, neg = 0, mn = Inf, mx = -Inf, s = 0, ss = 0))
names(num_stat) <- num_cand
cat_tab   <- setNames(lapply(cat_cand, function(x) integer(0)), cat_cand)
id_seen   <- new.env(parent = emptyenv())
n_rows    <- 0
chunk_no  <- 0

f <- function(chunk, pos) {
  chunk_no <<- chunk_no + 1
  n_rows <<- n_rows + nrow(chunk)
  for (j in seq_along(hdr)) na_count[j] <<- na_count[j] + sum(is.na(chunk[[j]]))
  for (nm in num_cand) {
    v <- chunk[[nm]]
    v <- v[!is.na(v)]
    if (length(v) == 0) next
    x <- suppressWarnings(as.numeric(v))
    bad <- sum(is.na(x))
    x <- x[!is.na(x)]
    st <- num_stat[[nm]]
    st$n   <- st$n + length(x)
    st$bad <- st$bad + bad
    st$neg <- st$neg + sum(x < 0)
    st$mn  <- min(st$mn, x)
    st$mx  <- max(st$mx, x)
    st$s   <- st$s + sum(x)
    st$ss  <- st$ss + sum(x * x)
    num_stat[[nm]] <<- st
  }
  for (nm in cat_cand) {
    v <- chunk[[nm]]
    v <- v[!is.na(v)]
    if (length(v) == 0) next
    t <- table(v)
    old <- cat_tab[[nm]]
    add <- setdiff(names(t), names(old))
    old[add] <- 0
    old[names(t)] <- old[names(t)] + as.numeric(t)
    cat_tab[[nm]] <<- old
  }
  if (chunk_no %% 4 == 0) cat("chunk", chunk_no, "rows so far", n_rows, "\n")
  TRUE
}

chunk_size <- 250000
cat("Reading in chunks of", chunk_size, "...\n")
t0 <- Sys.time()
read_csv_chunked(raw_path, SideEffectChunkCallback$new(f), chunk_size = chunk_size,
                 col_types = cols(.default = "c"), progress = FALSE)
cat("Elapsed (min):", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")

con <- file(out_path, open = "wt")
sink(con)
cat("RAW DATA PROFILE -- dataset/THOR_Vietnam_Bombing_Operations.csv\n")
cat("Generated:", format(Sys.time()), "\n\n")
cat("Rows:", n_rows, " Columns:", n_col, "\n\n")
cat("--- Missingness per column (exact, full scan) ---\n")
ord <- order(-na_count)
for (j in ord) {
  cat(sprintf("%-28s  missing %10d  (%6.2f%%)\n", hdr[j], na_count[j], 100 * na_count[j] / n_rows))
}
cat("\n--- Numeric candidate columns ---\n")
for (nm in num_cand) {
  st <- num_stat[[nm]]
  if (st$n == 0) { cat(sprintf("%-24s : no numeric values\n", nm)); next }
  cat(sprintf("%-24s n_nonmiss=%9d nonnum=%6d neg=%8d min=%.4f mean=%.4f max=%.4f\n",
              nm, st$n, st$bad, st$neg, st$mn, st$s / st$n, st$mx))
}
cat("\n--- Categorical candidate columns (level counts) ---\n")
for (nm in cat_cand) {
  tv <- cat_tab[[nm]]
  tv <- sort(tv, decreasing = TRUE)
  cat(sprintf("\n%s : %d levels\n", nm, length(tv)))
  if (length(tv) > 60) {
    print(round(head(tv, 40)))
    cat("...", length(tv) - 40, "more levels; total non-missing =", sum(tv), "\n")
  } else {
    print(tv)
  }
}
cat("\n--- ID uniqueness ---\n")
cat("(checked separately)\n")
sink()
close(con)
cat("Wrote", out_path, "\n")

## distinct count of the primary key, streaming
cnt <- 0L
seen <- character(0)
f2 <- function(chunk, pos) {
  v <- unique(chunk$THOR_DATA_VIET_ID)
  v <- v[!is.na(v)]
  seen <<- unique(c(seen, v))
  cnt <<- cnt + length(v)
  TRUE
}
read_csv_chunked(raw_path, SideEffectChunkCallback$new(f2), chunk_size = 1000000,
                 col_types = cols(.default = "_", THOR_DATA_VIET_ID = "c"), progress = FALSE)
cat("distinct THOR_DATA_VIET_ID values:", length(seen), " over", n_rows, "rows\n")
cat("max id:", max(as.numeric(seen)), "\n")
