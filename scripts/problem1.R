## --------------------------------------------------------------------------
## problem1.R -- Unit I: data handling, descriptive statistics, visualisation
##
## Problem statement 1:
## Descriptive analysis of weapon-delivery activity -- how did the number of
## weapon-delivery records change over the war, how were they distributed
## across target countries and aircraft groups, and how are the per-record
## variables distributed?
##
## Input : clean_data.csv   Output: outputs/problem1.txt, figures/fig1_*.png
## Run from the project root:  Rscript scripts/problem1.R
## --------------------------------------------------------------------------

source("scripts/common_setup.R")
cat("problem1.R running ...\n")
begin_log("outputs/problem1.txt")

cat("=============================================================\n")
cat("PROBLEM 1: Descriptive analysis of weapon-delivery records\n")
cat("=============================================================\n\n")
cat("Dataset: clean_data.csv,", nrow(DATA), "records,",
    format(min(DATA$MISSION_DATE)), "to", format(max(DATA$MISSION_DATE)), "\n")
cat("One record is one weapon delivery event reported by the source\n")
cat("(THOR Vietnam War bombing operations database).\n\n")

## --------------------------------------------------------------------------
## 1.1 structure of the variables used in this problem
## --------------------------------------------------------------------------
vars_num <- c("WEAPONS_DELIVERED", "AIRCRAFT_NO", "LOAD_LB",
              "TGT_HOUR", "LAT", "LON")
vars_cat <- c("PERIOD", "COUNTRY", "SERVICE", "AIRCRAFT_GROUP",
              "CLOUD", "SOURCE_DB")

cat("--- 1.1 Variables used ---\n")
cat("Numerical :", paste(vars_num, collapse = ", "), "\n")
cat("Categorical:", paste(vars_cat, collapse = ", "), "\n\n")

cat("class and missingness of the numerical variables:\n")
for (v in vars_num) {
  x <- DATA[[v]]
  cat(sprintf("  %-18s class=%-9s missing=%5d (%5.2f%%)\n", v, class(x)[1],
              sum(is.na(x)), 100 * mean(is.na(x))))
}
cat("\nclass and missingness of the categorical variables:\n")
for (v in vars_cat) {
  x <- DATA[[v]]
  cat(sprintf("  %-18s class=%-9s missing=%5d (%5.2f%%)  levels=%d\n", v,
              class(x)[1], sum(is.na(x)), 100 * mean(is.na(x)), nlevels(x)))
}

## --------------------------------------------------------------------------
## 1.2 frequency tables
## --------------------------------------------------------------------------
cat("\n--- 1.2 Frequency tables ---\n\n")
cat("Records per year:\n")
print(table(DATA$YEAR))

cat("\nRecords per target country (share of non-missing):\n")
tab_c <- table(DATA$COUNTRY)
print(tab_c)
print(round(100 * prop.table(tab_c), 1))

cat("\nRecords per aircraft group:\n")
tab_a <- table(DATA$AIRCRAFT_GROUP)
print(tab_a)
print(round(100 * prop.table(tab_a), 1))

cat("\nRecords by period of day:\n")
print(table(DATA$PERIOD, useNA = "ifany"))

cat("\nRecords by source database:\n")
print(table(DATA$SOURCE_DB))

cat("\nRecords by what was delivered (weapon class):\n")
print(table(DATA$WEAPON_CLASS, useNA = "ifany"))

## --------------------------------------------------------------------------
## 1.3 descriptive statistics of the numerical variables
## --------------------------------------------------------------------------
cat("\n--- 1.3 Descriptive statistics of the numerical variables ---\n\n")
stat_tab <- data.frame(
  variable = vars_num,
  n        = sapply(vars_num, function(v) sum(!is.na(DATA[[v]]))),
  mean     = sapply(vars_num, function(v) mean(DATA[[v]], na.rm = TRUE)),
  median   = sapply(vars_num, function(v) median(DATA[[v]], na.rm = TRUE)),
  sd       = sapply(vars_num, function(v) sd(DATA[[v]], na.rm = TRUE)),
  min      = sapply(vars_num, function(v) min(DATA[[v]], na.rm = TRUE)),
  q1       = sapply(vars_num, function(v) quantile(DATA[[v]], .25, na.rm = TRUE)),
  q3       = sapply(vars_num, function(v) quantile(DATA[[v]], .75, na.rm = TRUE)),
  max      = sapply(vars_num, function(v) max(DATA[[v]], na.rm = TRUE)),
  skewness = sapply(vars_num, function(v) skewness(DATA[[v]])),
  kurtosis = sapply(vars_num, function(v) kurtosis(DATA[[v]])),
  row.names = NULL
)
print(stat_tab, digits = 4, row.names = FALSE)

cat("\ninterquartile range of the key variables:\n")
print(sapply(c("WEAPONS_DELIVERED", "AIRCRAFT_NO", "LOAD_LB"),
             function(v) IQR(DATA[[v]], na.rm = TRUE)))

cat("\npercentiles of WEAPONS_DELIVERED:\n")
print(quantile(DATA$WEAPONS_DELIVERED, c(.5, .75, .90, .95, .99, 1), na.rm = TRUE))

cat("\nnumber and share of records with more than 100 weapons delivered:\n")
n100 <- sum(DATA$WEAPONS_DELIVERED > 100, na.rm = TRUE)
cat("  count =", n100, " share =", round(100 * n100 / sum(!is.na(DATA$WEAPONS_DELIVERED)), 2), "%\n")

## --------------------------------------------------------------------------
## 1.4 figures
## --------------------------------------------------------------------------
cat("\n--- 1.4 Figures ---\n\n")

## fig 1-1: records per year ------------------------------------------------
p1 <- ggplot(subset(DATA, !is.na(YEAR)), aes(x = factor(YEAR))) +
  geom_bar(fill = "grey40", colour = "black", width = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.35, size = 3) +
  labs(title = "Weapon-delivery records per year",
       x = "Year", y = "Number of records") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.10))) +
  theme_rep
save_fig(p1, "fig1_1_records_by_year.png")
tab_year <- table(DATA$YEAR)
cat("fig1_1_records_by_year.png : records per year, peak year =",
    names(tab_year)[which.max(tab_year)], "with", max(tab_year), "records;",
    "minimum year =", names(tab_year)[which.min(tab_year)], "with", min(tab_year), "\n")

## fig 1-2: monthly trend by target country --------------------------------
mon <- aggregate(list(records = rep(1, nrow(DATA))),
                 by = list(month = as.Date(format(DATA$MISSION_DATE, "%Y-%m-01")),
                           COUNTRY = DATA$COUNTRY), FUN = length)
mon <- subset(mon, !is.na(COUNTRY) &
                COUNTRY %in% c("South Vietnam", "North Vietnam", "Laos",
                               "Cambodia", "Thailand"))
p2 <- ggplot(mon, aes(x = month, y = records, group = COUNTRY, linetype = COUNTRY)) +
  geom_line(linewidth = 0.5, colour = "black") +
  labs(title = "Monthly weapon-delivery records by target country",
       x = "Month", y = "Number of records", linetype = "Target country") +
  scale_linetype_manual(values = c("solid", "dashed", "dotted", "dotdash", "longdash")) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  theme_rep
save_fig(p2, "fig1_2_monthly_by_country.png", height = 4.4)
cat("fig1_2_monthly_by_country.png : monthly series per target country\n")

## fig 1-3: bar chart of weapons delivered per target country --------------
p3 <- ggplot(subset(DATA, !is.na(WEAPONS_DELIVERED)), aes(x = WEAPONS_DELIVERED)) +
  geom_histogram(binwidth = 2, boundary = 0, fill = "grey55", colour = "black",
                 linewidth = 0.2) +
  coord_cartesian(xlim = c(0, 100)) +
  labs(title = "Distribution of weapons delivered per record",
       subtitle = "records with more than 100 weapons are shown at the right edge",
       x = "Weapons delivered in the record", y = "Number of records") +
  theme_rep
save_fig(p3, "fig1_3_weapons_hist.png")
cat("fig1_3_weapons_hist.png : histogram of weapons delivered per record\n")

## fig 1-4: boxplot of weapons delivered per target country ----------------
p4 <- ggplot(subset(DATA, !is.na(COUNTRY) & !is.na(WEAPONS_DELIVERED)),
             aes(x = COUNTRY, y = WEAPONS_DELIVERED)) +
  geom_boxplot(outlier.size = 0.4, outlier.colour = "grey40", fill = "grey85") +
  scale_y_continuous(trans = "log10") +
  labs(title = "Weapons delivered per record by target country",
       subtitle = "logarithmic scale",
       x = NULL, y = "Weapons delivered (log scale)") +
  theme_rep
save_fig(p4, "fig1_4_weapons_by_country.png", height = 4.6)
cat("fig1_4_weapons_by_country.png : boxplots of weapons delivered by country\n")

## fig 1-5: target locations -----------------------------------------------
p5 <- ggplot(subset(DATA, !is.na(LAT) & !is.na(COUNTRY)), aes(x = LON, y = LAT)) +
  geom_point(aes(shape = COUNTRY), size = 0.7, colour = "black", alpha = 0.35) +
  labs(title = "Locations of the targets in the sample",
       x = "Longitude (degrees east)", y = "Latitude (degrees north)",
       shape = "Target country") +
  guides(shape = guide_legend(nrow = 2)) +
  theme_rep +
  theme(legend.text = element_text(size = 9))
save_fig(p5, "fig1_5_target_map.png", height = 4.9)
cat("fig1_5_target_map.png : scatter plot of target coordinates\n")

## --------------------------------------------------------------------------
## 1.5 supporting numbers quoted in the report
## --------------------------------------------------------------------------
cat("\n--- 1.5 Supporting numbers ---\n")
cat("share of records from the four years 1968-1971:\n")
y <- table(DATA$YEAR)
cat("  ", round(100 * sum(y[c("1968", "1969", "1970", "1971")]) / sum(y), 1), "%\n")
cat("median weapons delivered, South Vietnam:",
    median(DATA$WEAPONS_DELIVERED[DATA$COUNTRY == "South Vietnam"], na.rm = TRUE), "\n")
cat("median weapons delivered, North Vietnam:",
    median(DATA$WEAPONS_DELIVERED[DATA$COUNTRY == "North Vietnam"], na.rm = TRUE), "\n")
cat("median weapons delivered, Laos:",
    median(DATA$WEAPONS_DELIVERED[DATA$COUNTRY == "Laos"], na.rm = TRUE), "\n")
cat("median weapons delivered, Cambodia:",
    median(DATA$WEAPONS_DELIVERED[DATA$COUNTRY == "Cambodia"], na.rm = TRUE), "\n")
cat("mean and median weapons, bomb records:",
    mean(DATA$WEAPONS_DELIVERED[DATA$WEAPON_CLASS == "BOMB"], na.rm = TRUE),
    median(DATA$WEAPONS_DELIVERED[DATA$WEAPON_CLASS == "BOMB"], na.rm = TRUE), "\n")
cat("mean and max weapons, gun records:",
    mean(DATA$WEAPONS_DELIVERED[DATA$WEAPON_CLASS == "GUN"], na.rm = TRUE),
    max(DATA$WEAPONS_DELIVERED[DATA$WEAPON_CLASS == "GUN"], na.rm = TRUE), "\n")
cat("median aircraft per record:",
    median(DATA$AIRCRAFT_NO, na.rm = TRUE), "\n")
cat("median hour at target (HH):",
    median(DATA$TGT_HOUR, na.rm = TRUE), "\n")

end_log()
cat("problem1.R finished; wrote outputs/problem1.txt and 5 figures\n")
