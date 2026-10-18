## 00b_diagnose_raw.R -- drill into the suspicious columns found by the profile.
suppressMessages(library(readr))
options(stringsAsFactors = FALSE)
raw_path <- "dataset/THOR_Vietnam_Bombing_Operations.csv"
out_path <- "outputs/00b_raw_diagnosis.txt"

## ---- helper: merge two tables with proper name handling ------------------
merge_tab <- function(old, t) {
  out <- old
  m <- match(names(t), names(out))
  add <- is.na(m)
  out[names(t)[add]] <- 0
  m <- match(names(t), names(out))
  out[m] <- out[m] + as.numeric(t)
  out
}

f <- function(chunk, pos) {
  chunk <- as.data.frame(chunk, stringsAsFactors = FALSE)
  n <- nrow(chunk)
  assign("n_rows", get("n_rows", envir = .GlobalEnv) + n, envir = .GlobalEnv)

  ## tables accumulated correctly
  for (nm in c("PERIODOFDAY", "TGTCOUNTRY", "MILSERVICE", "SOURCERECORD",
               "TGTCLOUDCOVER", "MFUNC_DESC_CLASS")) {
    v <- chunk[[nm]]; v <- v[!is.na(v)]
    if (!length(v)) next
    t <- table(v)
    cur <- get(paste0("tab_", nm), envir = .GlobalEnv)
    assign(paste0("tab_", nm), merge_tab(cur, t), envir = .GlobalEnv)
  }

  ## suspicious PERIODOFDAY values: capture examples
  bad <- which(!is.na(chunk$PERIODOFDAY) & !chunk$PERIODOFDAY %in% c("D", "N"))
  if (length(bad)) {
    ex <- get("ex_period", envir = .GlobalEnv)
    if (length(ex) < 8) {
      take <- head(bad, 8 - length(ex))
      for (r in take) ex[[length(ex) + 1]] <- chunk[r, ]
      assign("ex_period", ex, envir = .GlobalEnv)
    }
    assign("n_bad_period", get("n_bad_period", envir = .GlobalEnv) + length(bad), envir = .GlobalEnv)
  }

  ## flags
  nwd <- as.numeric(chunk$NUMWEAPONSDELIVERED)
  wlw <- as.numeric(chunk$WEAPONSLOADEDWEIGHT)
  wt  <- as.numeric(chunk$WEAPONTYPEWEIGHT)
  naf <- as.numeric(chunk$NUMOFACFT)
  flh <- as.numeric(chunk$FLTHOURS)
  wjw <- as.numeric(chunk$NUMWEAPONSRETURNED)
  tjw <- as.numeric(chunk$NUMWEAPONSJETTISONED)
  acc <- get("acc", envir = .GlobalEnv)
  acc$nwd_gt0     <- acc$nwd_gt0     + sum(nwd > 0)
  acc$nwd_9999    <- acc$nwd_9999    + sum(nwd == 9999)
  acc$nwd_ge1000  <- acc$nwd_ge1000  + sum(nwd >= 1000)
  acc$wlw_neg1    <- acc$wlw_neg1    + sum(wlw == -1)
  acc$wlw_zero    <- acc$wlw_zero    + sum(wlw == 0)
  acc$wlw_pos     <- acc$wlw_pos     + sum(wlw > 0)
  acc$wlw_big     <- acc$wlw_big     + sum(wlw > 1e7)
  acc$kinetic     <- acc$kinetic     + sum(chunk$MFUNC_DESC_CLASS == "KINETIC", na.rm = TRUE)
  acc$naf_eq0     <- acc$naf_eq0     + sum(naf == 0)
  acc$naf_gt100   <- acc$naf_gt100   + sum(naf > 100)
  acc$flh_gt100   <- acc$flh_gt100   + sum(flh > 100)
  acc$ret_neg1    <- acc$ret_neg1    + sum(wjw == -1)
  acc$jt_neg1     <- acc$jt_neg1     + sum(tjw == -1)
  acc$wpt_missing <- acc$wpt_missing + sum(is.na(chunk$WEAPONTYPE))
  acc$wlw_when_wpt_missing <- acc$wlw_when_wpt_missing + sum(wlw[is.na(chunk$WEAPONTYPE)] > 0)

  ## date range
  d <- suppressWarnings(as.Date(chunk$MSNDATE))
  acc$date_min <- min(acc$date_min, min(d, na.rm = TRUE))
  acc$date_max <- max(acc$date_max, max(d, na.rm = TRUE))
  assign("acc", acc, envir = .GlobalEnv)
  TRUE
}

assign("n_rows", 0, envir = .GlobalEnv)
assign("n_bad_period", 0, envir = .GlobalEnv)
assign("ex_period", list(), envir = .GlobalEnv)
for (nm in c("PERIODOFDAY", "TGTCOUNTRY", "MILSERVICE", "SOURCERECORD", "TGTCLOUDCOVER", "MFUNC_DESC_CLASS"))
  assign(paste0("tab_", nm), integer(0), envir = .GlobalEnv)
assign("acc", list(nwd_gt0 = 0, nwd_9999 = 0, nwd_ge1000 = 0, wlw_neg1 = 0, wlw_zero = 0,
                   wlw_pos = 0, wlw_big = 0, kinetic = 0, naf_eq0 = 0, naf_gt100 = 0, flh_gt100 = 0,
                   ret_neg1 = 0, jt_neg1 = 0, wpt_missing = 0, wlw_when_wpt_missing = 0,
                   date_min = as.Date("2100-01-01"), date_max = as.Date("1900-01-01")),
       envir = .GlobalEnv)

read_csv_chunked(raw_path, SideEffectChunkCallback$new(f), chunk_size = 500000,
                 col_types = cols(.default = "c"), progress = FALSE)

con <- file(out_path, open = "wt"); sink(con)
cat("DIAGNOSIS OF SUSPICIOUS COLUMNS\n")
cat("rows:", get("n_rows", envir = .GlobalEnv), "\n\n")
cat("PERIODOFDAY values outside {D,N}:", get("n_bad_period", envir = .GlobalEnv), "\n")
cat("\nPERIODOFDAY level counts:\n"); print(sort(get("tab_PERIODOFDAY", envir = .GlobalEnv), decreasing = TRUE))
cat("\nTGTCOUNTRY level counts (all levels):\n"); print(sort(get("tab_TGTCOUNTRY", envir = .GlobalEnv), decreasing = TRUE))
cat("\nMILSERVICE level counts:\n"); print(sort(get("tab_MILSERVICE", envir = .GlobalEnv), decreasing = TRUE))
cat("\nSOURCERECORD level counts:\n"); print(sort(get("tab_SOURCERECORD", envir = .GlobalEnv), decreasing = TRUE))
cat("\nTGTCLOUDCOVER level counts:\n"); print(sort(get("tab_TGTCLOUDCOVER", envir = .GlobalEnv), decreasing = TRUE))
cat("\nMFUNC_DESC_CLASS level counts:\n"); print(sort(get("tab_MFUNC_DESC_CLASS", envir = .GlobalEnv), decreasing = TRUE))
acc <- get("acc", envir = .GlobalEnv)
cat("\n--- flags ---\n")
cat("NUMWEAPONSDELIVERED > 0        :", acc$nwd_gt0, "\n")
cat("NUMWEAPONSDELIVERED == 9999    :", acc$nwd_9999, "\n")
cat("NUMWEAPONSDELIVERED >= 1000    :", acc$nwd_ge1000, "\n")
cat("WEAPONSLOADEDWEIGHT == -1      :", acc$wlw_neg1, "\n")
cat("WEAPONSLOADEDWEIGHT == 0       :", acc$wlw_zero, "\n")
cat("WEAPONSLOADEDWEIGHT > 0        :", acc$wlw_pos, "\n")
cat("WEAPONSLOADEDWEIGHT > 1e7      :", acc$wlw_big, "\n")
cat("MFUNC_DESC_CLASS == KINETIC    :", acc$kinetic, "\n")
cat("NUMOFACFT == 0                 :", acc$naf_eq0, "\n")
cat("NUMOFACFT > 100                :", acc$naf_gt100, "\n")
cat("FLTHOURS > 100                 :", acc$flh_gt100, "\n")
cat("NUMWEAPONSRETURNED == -1       :", acc$ret_neg1, "\n")
cat("NUMWEAPONSJETTISONED == -1     :", acc$jt_neg1, "\n")
cat("WEAPONTYPE missing             :", acc$wpt_missing, "\n")
cat("WEAPONSLOADEDWEIGHT>0 & WEAPONTYPE missing :", acc$wlw_when_wpt_missing, "\n")
cat("MSNDATE range:", format(acc$date_min), "to", format(acc$date_max), "\n")
cat("\n--- examples of rows with odd PERIODOFDAY (transposed) ---\n")
ex <- get("ex_period", envir = .GlobalEnv)
for (i in seq_along(ex)) {
  cat("\nExample", i, ":\n")
  e <- t(ex[[i]])
  print(noquote(cbind(names(e)[, 1], as.character(e[, 1]))), quote = FALSE)
}
sink(); close(con)
cat("Wrote", out_path, "\n")
