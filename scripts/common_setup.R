## --------------------------------------------------------------------------
## common_setup.R -- shared set-up for all five problem scripts
##
## Loads clean_data.csv, defines the analysis factors, a black-and-white
## plotting theme and a few small helper functions that the problem scripts
## reuse. Source this file from the project root:
##
##     source("scripts/common_setup.R")
## --------------------------------------------------------------------------

suppressMessages(library(ggplot2))

## -- always work from the project root -------------------------------------
if (basename(getwd()) == "scripts" && file.exists("../clean_data.csv")) setwd("..")
stopifnot(file.exists("clean_data.csv"))
dir.create("figures", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

## --------------------------------------------------------------------------
## load the cleaned data (one file for every analysis)
## --------------------------------------------------------------------------
DATA <- read.csv("clean_data.csv", stringsAsFactors = FALSE)

## re-attach factor levels after the csv round trip
DATA$PERIOD   <- factor(DATA$PERIOD,   levels = c("Day", "Night"))
DATA$COUNTRY  <- factor(DATA$COUNTRY,
                        levels = c("South Vietnam", "North Vietnam", "Laos",
                                   "Cambodia", "Thailand", "Other"))
DATA$SERVICE  <- factor(DATA$SERVICE,  levels = c("USAF", "USN", "VNAF", "USMC", "Other"))
DATA$SOURCE_DB <- factor(DATA$SOURCE_DB,
                         levels = c("SEADAB", "CACTA6669", "CACTA6570", "SACCOACT"))
DATA$AIRCRAFT_GROUP <- factor(DATA$AIRCRAFT_GROUP,
                              levels = c("F-4 Phantom", "F-100 Super Sabre", "A-4 Skyhawk",
                                         "A-1 Skyraider", "A-37 Dragonfly",
                                         "B-52 Stratofortress", "Other"))
DATA$CLOUD <- factor(DATA$CLOUD,
                     levels = c("Clear", "Scattered", "Broken", "Overcast", "Other"))
DATA$WEAPON_CLASS <- factor(DATA$WEAPON_CLASS,
                            levels = c("BOMB", "ROCKET", "GUN", "MISSILE", "SUPPORT"))
DATA$MISSION_DATE <- as.Date(DATA$MISSION_DATE)
DATA <- droplevels(DATA)

## --------------------------------------------------------------------------
## black and white plotting theme (the report allows no colour)
## --------------------------------------------------------------------------
theme_rep <- theme_bw(base_size = 12) +
  theme(
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(colour = "grey85", linewidth = 0.3),
    panel.border      = element_rect(colour = "black", linewidth = 0.5),
    axis.text         = element_text(colour = "black"),
    axis.title        = element_text(colour = "black", face = "bold"),
    plot.title        = element_text(colour = "black", face = "bold", size = 12),
    plot.subtitle     = element_text(colour = "black", size = 10),
    plot.caption      = element_text(colour = "black", size = 9, hjust = 0),
    legend.position   = "bottom",
    legend.title      = element_text(face = "bold"),
    legend.key        = element_rect(fill = "white", colour = NA),
    strip.background  = element_rect(fill = "grey92", colour = "black"),
    strip.text        = element_text(colour = "black", face = "bold")
  )

## grey scales used by every figure
grey_fill  <- scale_fill_grey(start = 0.85, end = 0.30, na.value = "white")
grey_col   <- scale_colour_grey(start = 0.10, end = 0.55)

## helper: save a ggplot as a png in figures/
save_fig <- function(plot, file, width = 6.6, height = 4.2, dpi = 150) {
  ggsave(file.path("figures", file), plot = plot, width = width, height = height,
         dpi = dpi, bg = "white")
  invisible(file.path("figures", file))
}

## --------------------------------------------------------------------------
## small statistics helpers (kept in base R on purpose)
## --------------------------------------------------------------------------
## moment-based skewness and excess kurtosis
skewness <- function(x) {
  x <- x[!is.na(x)]
  mean((x - mean(x))^3) / stats::sd(x)^3
}
kurtosis <- function(x) {
  x <- x[!is.na(x)]
  mean((x - mean(x))^4) / stats::sd(x)^4 - 3
}

## Levene's test for equal variances, centred on the group medians
levene_test <- function(x, group) {
  ok <- !is.na(x) & !is.na(group)
  x <- x[ok]; group <- droplevels(factor(group[ok]))
  z <- abs(x - ave(x, group, FUN = median))
  fit <- stats::lm(z ~ group)
  a <- stats::anova(fit)
  c(F = a$`F value`[1], df1 = a$Df[1], df2 = a$Df[2], p = a$`Pr(>F)`[1])
}

## variance inflation factors for the numeric terms of a fitted model
vif_numeric <- function(fit) {
  data <- stats::model.frame(fit)
  response <- names(data)[1]
  # numeric predictor columns only
  num <- setdiff(names(data)[vapply(data, is.numeric, logical(1))], response)
  out <- sapply(num, function(v) {
    others <- setdiff(num, v)
    if (length(others) == 0) return(1)
    form <- stats::as.formula(paste(v, "~", paste(others, collapse = "+")))
    r2 <- summary(stats::lm(form, data = data))$r.squared
    1 / (1 - r2)
  })
  out
}

## tidy printing of a p-value
fmt_p <- function(p) {
  ifelse(is.na(p), "NA", ifelse(p < 2.2e-16, "< 2.2e-16", format.pval(p, digits = 3, eps = 1e-16)))
}

## open / close a plain-text log of everything the script prints
begin_log <- function(path) {
  assign(".log_con", file(path, open = "wt"), envir = .GlobalEnv)
  sink(get(".log_con", envir = .GlobalEnv))
}
end_log <- function() {
  sink()
  close(get(".log_con", envir = .GlobalEnv))
}

cat("common_setup.R loaded --", nrow(DATA), "records,",
    length(unique(DATA$YEAR)), "years\n")
