## 00c_check_relations.R -- relations between weapons columns, chunked scan (safe).
suppressMessages({library(readr)})
options(stringsAsFactors = FALSE)
raw_path <- "dataset/THOR_Vietnam_Bombing_Operations.csv"
out_path <- "outputs/00c_relations.txt"

keep_cols <- c("SOURCEID", "SOURCERECORD", "NUMWEAPONSDELIVERED", "WEAPONTYPE",
               "WEAPONTYPEWEIGHT", "WEAPONSLOADEDWEIGHT", "NUMWEAPONSRETURNED",
               "NUMWEAPONSJETTISONED", "NUMOFACFT", "FLTHOURS", "OPERATIONSUPPORTED",
               "MFUNC_DESC_CLASS", "TIMEONTARGET", "MSNDATE", "PERIODOFDAY")
ct <- as.list(setNames(rep("character", length(keep_cols)), keep_cols))
col_type <- do.call(cols, ct)

store <- list()
si <- 0; pos0 <- 0
f <- function(chunk, pos) {
  chunk <- as.data.frame(chunk, stringsAsFactors = FALSE)
  pos0 <<- pos0 + nrow(chunk)
  cat("chunk at", pos0, "rows\n")
  idx <- which((pos + seq_len(nrow(chunk))) %% 41 == 0)
  if (length(idx)) {
    si <<- si + 1
    store[[si]] <<- chunk[idx, , drop = FALSE]
  }
  TRUE
}
read_csv_chunked(raw_path, SideEffectChunkCallback$new(f), chunk_size = 1000000,
                 col_types = col_type, progress = FALSE)
s <- do.call(rbind, store[seq_len(si)])

num <- function(x) suppressWarnings(as.numeric(x))
s$nwd <- num(s$NUMWEAPONSDELIVERED); s$wtw <- num(s$WEAPONTYPEWEIGHT)
s$wlw <- num(s$WEAPONSLOADEDWEIGHT); s$naf <- num(s$NUMOFACFT)
s$flh <- num(s$FLTHOURS); s$jt <- num(s$NUMWEAPONSRETURNED); s$ret <- num(s$NUMWEAPONSJETTISONED)

con <- file(out_path, open = "wt"); sink(con)
cat("ROWS scanned sample:", nrow(s), "\n")
cat("\n-- WEAPONSLOADEDWEIGHT vs NUMWEAPONSDELIVERED*WEAPONTYPEWEIGHT (wlw>0) --\n")
sub <- subset(s, wlw > 0)
sub$prod <- sub$nwd * sub$wtw
sub$ratio <- ifelse(sub$prod > 0, sub$wlw / sub$prod, NA)
print(summary(sub$ratio))
cat("ratio ~ NUMOFACFT? cor(ratio, naf):", cor(sub$ratio, sub$naf, use = "complete.obs"), "\n")
cat("median ratio by NUMOFACFT (1..6):\n")
print(round(tapply(sub$ratio, pmin(sub$naf, 6), median, na.rm = TRUE), 2))
cat("share wlw>0 by SOURCERECORD:\n")
print(round(100 * prop.table(table(s$SOURCERECORD, s$wlw > 0), 1), 2))
cat("share wlw>0 by MFUNC_DESC_CLASS:\n")
print(round(100 * prop.table(table(s$MFUNC_DESC_CLASS, s$wlw > 0), 1), 2))
cat("share wlw>0 by PERIODOFDAY:\n")
print(round(100 * prop.table(table(s$PERIODOFDAY, s$wlw > 0), 1), 2))

cat("\n-- WEAPONTYPE strings --\n")
u <- sort(table(s$WEAPONTYPE), decreasing = TRUE)
cat("unique weapon strings in sample:", length(u), "\n")
print(round(head(u, 30)))
cat("\nclass by grepl rule on text:\n")
cls <- rep(NA_character_, length(s$WEAPONTYPE))
txt <- s$WEAPONTYPE
rules <- list(
  BOMB     = "BOMB|CBU|M117|Mk ?8|MK ?8|BLU",
  ROCKET   = "ROCKET|HYDRA|ZUNI|FFAR|2\\.75",
  GUN_AMMO = "GUN|ROUNDS|AMMO|MM |MM$|CAL\\.|CARTRIDGE|SHELL|FUZE|7\\.62|20MM|40MM",
  MISSILE  = "MISSILE|MAVERICK|SIDEWINDER|SHRIKE|BULLPUP|WALLEYE",
  LEAFLET  = "LEAFLET|LEAFLETS",
  NAPALM   = "NAPALM|FIRE BOMB|FUEL TANK",
  MINE     = "MINE",
  FLARE    = "FLARE|MARKER|SMOKE|PYRO",
  OTHERW   = ".?"
)
for (j in rev(seq_along(rules))) cls[grepl(rules[[j]], txt, ignore.case = TRUE)] <- names(rules)[j]
print(table(cls, useNA = "ifany"))
cat("\nmean nwd by derived class:\n")
print(round(tapply(s$nwd, cls, mean, na.rm = TRUE), 2))
cat("median nwd by derived class:\n")
print(round(tapply(s$nwd, cls, median, na.rm = TRUE), 2))

cat("\n-- match against weapons glossary --\n")
wep <- readr::read_csv("dataset/THOR_Vietnam_Weapons_Glossary.csv", show_col_types = FALSE)
cat("share of non-missing weapon strings found in glossary:",
    round(mean(txt[!is.na(txt)] %in% wep$WEAPONTYPE), 3), "\n")

cat("\n-- OPERATIONSUPPORTED grepl mapping on sample --\n")
op <- s$OPERATIONSUPPORTED
hit <- rep(NA_character_, length(op))
for (j in rev(seq_along(rules_op <- list(
  ROLLING_THUNDER = "^ROLLING THUN|^ROLLING$|^ROLLING -",
  STEEL_TIGER = "STEEL TIGER|STEEL TIGER",
  BARREL_ROLL = "BARREL ROLL",
  LINEBACKER = "LINEBACK",
  MENU = "MENU",
  FREEDOM_DEAL = "FREEDOM",
  IN_COUNTRY = "^IN COUNTRY|IN COUNTRY",
  BLUE_TREE = "BLUE TREE",
  OTHER = ".?")))) hit[grepl(rules_op[[j]], op)] <- names(rules_op)[j]
print(table(hit, useNA = "ifany"))

cat("\n-- TIMEONTARGET sanity --\n")
tot <- num(s$TIMEONTARGET)
print(summary(tot))
cat("share 0..2359:", round(mean(tot >= 0 & tot <= 2359, na.rm = TRUE), 4), "\n")
cat("share with minute part 60..99 or =00:", round(mean((tot %% 100) >= 60, na.rm = TRUE), 4), "\n")

cat("\n-- MSNDATE span --\n")
d <- as.Date(s$MSNDATE); print(range(d, na.rm = TRUE))
sink(); close(con)
cat("Wrote", out_path, "\n")
