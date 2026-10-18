## --------------------------------------------------------------------------
## 01_clean.R -- builds the analysis dataset clean_data.csv
##
## Statistical Data Analysis using R -- FA-2 project
## THOR Vietnam bombing operations.
##
## The raw file dataset/THOR_Vietnam_Bombing_Operations.csv holds 46,70,416
## records (rows) and 47 columns covering 1965-06-01 to 1975-06-30.
##
## Step 1 : count records that delivered at least one weapon
##          (NUMWEAPONSDELIVERED > 0). These are the actual weapon-delivery
##          records and form the study population for the project.
## Step 2 : draw a simple random sample without replacement (seed 2026) of
##          n = 20000 records from that population (Unit III idea: sampling).
## Step 3 : clean the sample, derive the analysis variables and write
##          clean_data.csv plus a data-quality log outputs/01_data_quality.txt.
##
## Run from the project root:  Rscript scripts/01_clean.R
## --------------------------------------------------------------------------

suppressMessages({library(readr)})
options(stringsAsFactors = FALSE)

## -- run from the project root even if the caller is inside scripts/ -------
if (basename(getwd()) == "scripts" && dir.exists("../dataset")) setwd("..")
stopifnot(dir.exists("dataset"))
dir.create("outputs", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

raw_path <- "dataset/THOR_Vietnam_Bombing_Operations.csv"
out_csv  <- "clean_data.csv"
log_path <- "outputs/01_data_quality.txt"

log_lines <- character(0)
say <- function(...) {
  l <- paste0(...)
  log_lines <<- c(log_lines, l)
  cat(l, "\n")
}
## log the printed output of an object as well (for tables and summaries)
sayp <- function(x) say(paste(capture.output(print(x)), collapse = "\n"))

## --------------------------------------------------------------------------
## Step 1 -- find the population: records with at least one weapon delivered
## --------------------------------------------------------------------------
say("STEP 1: scanning the raw file for weapon-delivery records")
ct_small <- cols(.default = "_", THOR_DATA_VIET_ID = "c", NUMWEAPONSDELIVERED = "c")
ids <- integer(0)
n_all <- 0L
f_pop <- function(chunk, pos) {
  n_all <<- n_all + nrow(chunk)
  nwd <- suppressWarnings(as.numeric(chunk$NUMWEAPONSDELIVERED))
  keep <- !is.na(nwd) & nwd > 0
  ids <<- c(ids, as.integer(chunk$THOR_DATA_VIET_ID[keep]))
  if (n_all %% 1000000 == 0) cat("  ... scanned", n_all, "rows\n")
  TRUE
}
read_csv_chunked(raw_path, SideEffectChunkCallback$new(f_pop), chunk_size = 500000,
                 col_types = ct_small, progress = FALSE)
say("  total records in the raw file      : ", n_all)
pop_n <- length(ids)
say("  records with weapons delivered > 0 : ", pop_n, " (",
    round(100 * pop_n / n_all, 2), "% of the file)")

## --------------------------------------------------------------------------
## Step 2 -- simple random sample of n = 20000 without replacement
## --------------------------------------------------------------------------
N_SAMPLE <- 20000
set.seed(2026)
sel <- sort(sample(ids, size = N_SAMPLE, replace = FALSE))
sel_set <- new.env(hash = TRUE, size = 2 * N_SAMPLE)
for (v in sel) assign(as.character(v), TRUE, envir = sel_set)
say("STEP 2: simple random sample of ", N_SAMPLE,
    " records drawn with set.seed(2026)")

## second pass: read only the sampled rows (all 47 columns, as character)
hdr <- names(read_csv(raw_path, n_max = 0, show_col_types = FALSE))
ct_chr <- do.call(cols, as.list(setNames(rep("character", length(hdr)), hdr)))
keep_chunks <- list()
f_sel <- function(chunk, pos) {
  chunk <- as.data.frame(chunk, stringsAsFactors = FALSE)
  hit <- vapply(chunk$THOR_DATA_VIET_ID,
                function(v) !is.null(get0(v, envir = sel_set, inherits = FALSE)),
                logical(1))
  if (any(hit)) keep_chunks[[length(keep_chunks) + 1]] <<- chunk[hit, , drop = FALSE]
  TRUE
}
read_csv_chunked(raw_path, SideEffectChunkCallback$new(f_sel), chunk_size = 500000,
                 col_types = ct_chr, progress = FALSE)
d <- do.call(rbind, keep_chunks)
rm(rows, sel_set)
say("  rows collected:", nrow(d))

## --------------------------------------------------------------------------
## Step 3 -- cleaning and derived analysis variables
## --------------------------------------------------------------------------
say("")
say("STEP 3: cleaning and derivation (n = ", nrow(d), " sampled records)")

## --- key uniqueness -------------------------------------------------------
say("  duplicate THOR_DATA_VIET_ID values in sample:",
    sum(duplicated(d$THOR_DATA_VIET_ID)))
exact_dupes <- sum(duplicated(d))
say("  exactly duplicated rows (all 47 columns)   :", exact_dupes)
if (exact_dupes > 0) d <- d[!duplicated(d), ]

## --- date ---------------------------------------------------------------
## most dates are ISO (YYYY-MM-DD); 272 sample records use YYYYMMDD
d$MISSION_DATE <- as.Date(d$MSNDATE, format = "%Y-%m-%d")
alt <- is.na(d$MISSION_DATE)
d$MISSION_DATE[alt] <- as.Date(d$MSNDATE[alt], format = "%Y%m%d")
say("  mission dates in YYYYMMDD format (converted):", sum(alt))
say("  unparseable dates:", sum(is.na(d$MISSION_DATE)))
say("  mission date range in sample:", format(min(d$MISSION_DATE, na.rm = TRUE)),
    "to", format(max(d$MISSION_DATE, na.rm = TRUE)))
d$YEAR  <- as.integer(format(d$MISSION_DATE, "%Y"))
d$MONTH <- as.integer(format(d$MISSION_DATE, "%m"))

## --- period of day --------------------------------------------------------
say("  PERIODOFDAY codes other than D/N in sample:",
    sum(!d$PERIODOFDAY %in% c("D", "N")))
d$PERIOD <- factor(ifelse(d$PERIODOFDAY == "D", "Day",
                   ifelse(d$PERIODOFDAY == "N", "Night", NA)),
                   levels = c("Day", "Night"))

## --- target country -------------------------------------------------------
cc <- toupper(trimws(d$TGTCOUNTRY))
cc[cc == "PHILLIPINES"] <- "PHILIPPINES"
d$COUNTRY <- factor(
  ifelse(is.na(cc), NA,
  ifelse(cc == "SOUTH VIETNAM", "South Vietnam",
  ifelse(cc == "NORTH VIETNAM", "North Vietnam",
  ifelse(cc == "LAOS",    "Laos",
  ifelse(cc == "CAMBODIA", "Cambodia",
  ifelse(cc == "THAILAND", "Thailand", "Other")))))),
  levels = c("South Vietnam", "North Vietnam", "Laos", "Cambodia", "Thailand", "Other"))
say("  TGTCOUNTRY values mapped to 'Other':", sum(d$COUNTRY == "Other", na.rm = TRUE))

## --- service --------------------------------------------------------------
ms <- toupper(trimws(d$MILSERVICE))
d$SERVICE <- factor(ifelse(ms %in% c("USAF", "USN", "VNAF", "USMC"), ms, 
                    ifelse(is.na(ms), NA, "Other")),
                    levels = c("USAF", "USN", "VNAF", "USMC", "Other"))
say("  MILSERVICE values grouped into 'Other':", sum(d$SERVICE == "Other", na.rm = TRUE))

## --- source database ------------------------------------------------------
d$SOURCE_DB <- factor(d$SOURCERECORD,
                      levels = c("SEADAB", "CACTA6669", "CACTA6570", "SACCOACT"))

## --- aircraft group (six main combat types + Other) ------------------------
ac <- toupper(trimws(d$AIRCRAFT_ROOT))
d$AIRCRAFT_GROUP <- factor(
  ifelse(ac %in% c("F4", "RF4"), "F-4 Phantom",
  ifelse(ac == "F100",  "F-100 Super Sabre",
  ifelse(ac == "A4",    "A-4 Skyhawk",
  ifelse(ac == "A1",    "A-1 Skyraider",
  ifelse(ac == "A37",   "A-37 Dragonfly",
  ifelse(ac == "B52",   "B-52 Stratofortress", "Other")))))),
  levels = c("F-4 Phantom", "F-100 Super Sabre", "A-4 Skyhawk",
             "A-1 Skyraider", "A-37 Dragonfly", "B-52 Stratofortress", "Other"))

## --- cloud cover ----------------------------------------------------------
cl <- toupper(trimws(d$TGTCLOUDCOVER))
d$CLOUD <- factor(
  ifelse(is.na(cl) | cl == "NOT OBS", NA,
  ifelse(cl == "CLEAR",     "Clear",
  ifelse(cl == "SCATTERED", "Scattered",
  ifelse(cl == "BROKEN",    "Broken",
  ifelse(cl == "OVERCAST",  "Overcast", "Other"))))),
  levels = c("Clear", "Scattered", "Broken", "Overcast", "Other"))
say("  TGTCLOUDCOVER 'NOT OBS' treated as missing:",
    sum(toupper(trimws(d$TGTCLOUDCOVER)) == "NOT OBS", na.rm = TRUE))

## --- weapon class: join the weapons glossary on WEAPONTYPE ----------------
wep <- readr::read_csv("dataset/THOR_Vietnam_Weapons_Glossary.csv",
                       show_col_types = FALSE)
d$WEAPON_CLASS <- factor(wep$WEAPON_CLASS[match(d$WEAPONTYPE, wep$WEAPONTYPE)],
                         levels = c("BOMB", "ROCKET", "GUN", "MISSILE", "SUPPORT"))
unmatched <- unique(d$WEAPONTYPE[!is.na(d$WEAPONTYPE) & is.na(d$WEAPON_CLASS)])
say("  weapon strings not found in the glossary:", length(unmatched))
if (length(unmatched)) print(unmatched)

## --- number of weapons delivered (count variable) -------------------------
nwd <- suppressWarnings(as.numeric(d$NUMWEAPONSDELIVERED))
say("  NUMWEAPONSDELIVERED == 9999 (sentinel, set to NA) in sample:",
    sum(nwd == 9999))
nwd[nwd == 9999] <- NA
d$WEAPONS_DELIVERED <- nwd

## --- weapons loaded weight (pounds; -1 is the missing code) ---------------
## -1  : missing code used by the source
## 0   : the delivered item was not ordnance (troops, cargo, flares, sensors)
## >1e6: more than 500 short tons in one record -- implausible, treated as an
##       error (the largest single-aircraft Vietnam loads were about 60,000 lb)
wlw <- suppressWarnings(as.numeric(d$WEAPONSLOADEDWEIGHT))
say("  WEAPONSLOADEDWEIGHT == -1 (missing code, set to NA):", sum(wlw == -1))
wlw[wlw == -1] <- NA
say("  WEAPONSLOADEDWEIGHT == 0 (non-ordnance delivery, set to NA):",
    sum(wlw == 0, na.rm = TRUE))
wlw[wlw == 0] <- NA
say("  WEAPONSLOADEDWEIGHT above 1,000,000 lb (implausible, set to NA):",
    sum(wlw > 1e6, na.rm = TRUE))
wlw[!is.na(wlw) & wlw > 1e6] <- NA
d$LOAD_LB <- wlw

## --- number of aircraft ---------------------------------------------------
naf <- suppressWarnings(as.numeric(d$NUMOFACFT))
say("  NUMOFACFT == 0 (impossible, set to NA):", sum(naf == 0, na.rm = TRUE))
naf[naf == 0] <- NA
d$AIRCRAFT_NO <- naf

## --- flight hours (recorded, meaning uncertain: kept for reference) -------
d$FLIGHT_HOURS <- suppressWarnings(as.numeric(d$FLTHOURS))

## --- hour at target from TIMEONTARGET (HHMM encoded as a number) ----------
tot <- suppressWarnings(as.numeric(d$TIMEONTARGET))
minute <- tot %% 100
bad_t <- is.na(tot) | tot < 0 | tot > 2359 | minute > 59
say("  TIMEONTARGET invalid (set to NA):", sum(bad_t))
d$TGT_HOUR <- ifelse(bad_t, NA_integer_, as.integer(tot %/% 100))

## --- target coordinates ---------------------------------------------------
lat <- suppressWarnings(as.numeric(d$TGTLATDD_DDD_WGS84))
lon <- suppressWarnings(as.numeric(d$TGTLONDDD_DDD_WGS84))
bad_geo <- is.na(lat) | is.na(lon) | lat < 0 | lat > 30 | lon < 90 | lon > 130
say("  coordinates outside the 0-30N, 90-130E box (set to NA):", sum(bad_geo))
lat[bad_geo] <- NA; lon[bad_geo] <- NA
d$LAT <- lat
d$LON <- lon

## --------------------------------------------------------------------------
## Step 4 -- save
## --------------------------------------------------------------------------
write.csv(d, out_csv, row.names = FALSE)
say("")
say("clean_data.csv written: ", nrow(d), " rows, ", ncol(d), " columns")

## missingness of the analysis variables in the clean sample
say("")
say("Missingness of derived analysis variables in clean_data.csv")
ana <- c("PERIOD", "COUNTRY", "SERVICE", "SOURCE_DB", "AIRCRAFT_GROUP", "CLOUD",
         "WEAPON_CLASS", "WEAPONS_DELIVERED", "LOAD_LB", "AIRCRAFT_NO", "TGT_HOUR",
         "LAT", "LON", "FLIGHT_HOURS")
for (v in ana) {
  nas <- sum(is.na(d[[v]]))
  say(sprintf("  %-18s %6d missing (%5.2f%%)", v, nas, 100 * nas / nrow(d)))
}

## sanity cross-check of weapon class against mission function class
say("")
say("Cross tab: WEAPON_CLASS x MFUNC_DESC_CLASS in the sample")
sayp(table(d$WEAPON_CLASS, d$MFUNC_DESC_CLASS, useNA = "ifany"))
say("")
say("Records by SOURCE_DB in the sample:")
sayp(table(d$SOURCE_DB, useNA = "ifany"))
say("")
say("LOAD_LB summary:")
sayp(summary(d$LOAD_LB))
say("")
say("WEAPONS_DELIVERED summary:")
sayp(summary(d$WEAPONS_DELIVERED))
say("")
say("AIRCRAFT_NO summary:")
sayp(summary(d$AIRCRAFT_NO))

writeLines(log_lines, log_path)
cat("\nWrote", out_csv, "and", log_path, "\n")
