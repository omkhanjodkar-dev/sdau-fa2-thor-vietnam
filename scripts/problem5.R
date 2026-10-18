## --------------------------------------------------------------------------
## problem5.R -- Unit IV: correlation, multiple linear regression, prediction
##
## Problem statement 5:
## What explains the size of the attacking formation in a delivery record?
## Correlation analysis of the numerical variables and a multiple linear
## regression of log10(aircraft per record) on aircraft type, target country,
## period of day, year and source database, with model evaluation.
##
## Input : clean_data.csv   Output: outputs/problem5.txt, figures/fig5_*.png
## --------------------------------------------------------------------------

source("scripts/common_setup.R")
cat("problem5.R running ...\n")
begin_log("outputs/problem5.txt")

cat("=============================================================\n")
cat("PROBLEM 5: Explaining the number of aircraft (regression)\n")
cat("=============================================================\n\n")

## --------------------------------------------------------------------------
## 5.1 correlation analysis of the numerical variables
## --------------------------------------------------------------------------
num_vars <- c("AIRCRAFT_NO", "WEAPONS_DELIVERED", "LOAD_LB", "TGT_HOUR", "LAT", "LON")
cat("--- 5.1 Correlation analysis ---\n")
cat("Pearson and Spearman correlations between the numerical variables\n")
cat("(pairwise complete observations; the variables are strongly skewed, so\n")
cat("the Spearman coefficient is the more reliable one)\n\n")

cor_tab <- data.frame()
for (i in seq_along(num_vars)) for (j in seq_along(num_vars)) {
  if (j <= i) next
  a <- num_vars[i]; b <- num_vars[j]
  ok <- !is.na(DATA[[a]]) & !is.na(DATA[[b]])
  pe <- cor.test(DATA[[a]][ok], DATA[[b]][ok], method = "pearson")
  sp <- cor.test(DATA[[a]][ok], DATA[[b]][ok], method = "spearman", exact = FALSE)
  cor_tab <- rbind(cor_tab, data.frame(
    pair = paste(a, "-", b), n = sum(ok),
    pearson = round(unname(pe$estimate), 3), p_pearson = fmt_p(pe$p.value),
    spearman = round(unname(sp$estimate), 3), p_spearman = fmt_p(sp$p.value)))
}
print(cor_tab, row.names = FALSE)

## Spearman matrix for the heat map
sp_mat <- matrix(NA, length(num_vars), length(num_vars),
                 dimnames = list(num_vars, num_vars))
for (i in seq_along(num_vars)) for (j in seq_along(num_vars)) {
  ok <- !is.na(DATA[[num_vars[i]]]) & !is.na(DATA[[num_vars[j]]])
  sp_mat[i, j] <- if (i == j) 1 else cor(DATA[[num_vars[i]]][ok],
                                          DATA[[num_vars[j]]][ok],
                                          method = "spearman")
}
cat("\nSpearman correlation matrix:\n")
print(round(sp_mat, 3))

dp <- data.frame(x = log10(DATA$WEAPONS_DELIVERED), y = log10(DATA$AIRCRAFT_NO))
p1 <- ggplot(subset(dp, is.finite(x) & is.finite(y)), aes(x, y)) +
  geom_point(size = 0.4, alpha = 0.25, colour = "black") +
  geom_smooth(method = "lm", formula = y ~ x, colour = "black",
              linetype = "dashed", linewidth = 0.7, se = FALSE) +
  labs(title = "Weapons delivered and aircraft per record",
       subtitle = "both axes on the log10 scale; dashed line: least squares fit",
       x = "log10(weapons delivered)", y = "log10(aircraft in the record)") +
  theme_rep
save_fig(p1, "fig5_1_scatter_weapons_aircraft.png")

sp_df <- as.data.frame(as.table(sp_mat))
names(sp_df) <- c("v1", "v2", "r")
p2 <- ggplot(sp_df, aes(x = v1, y = v2, fill = r)) +
  geom_tile(colour = "black", linewidth = 0.2) +
  geom_text(aes(label = round(r, 2)), size = 2.9, colour = "black") +
  scale_fill_gradient(low = "white", high = "grey35", limits = c(-1, 1),
                      name = "Spearman\ncorrelation") +
  labs(title = "Spearman correlation matrix of the numerical variables",
       x = NULL, y = NULL) +
  theme_rep +
  theme(panel.grid.major = element_blank())
save_fig(p2, "fig5_2_correlation_matrix.png", height = 4.6)

## --------------------------------------------------------------------------
## 5.2 regression data
## --------------------------------------------------------------------------
reg_vars <- c("AIRCRAFT_NO", "AIRCRAFT_GROUP", "COUNTRY", "PERIOD", "YEAR",
              "SOURCE_DB", "WEAPONS_DELIVERED")
reg <- DATA[complete.cases(DATA[, reg_vars]), reg_vars]
reg$y <- log10(reg$AIRCRAFT_NO)
cat("\n--- 5.2 Regression data ---\n")
cat("records with all regression variables recorded:", nrow(reg), "\n")
cat("summary of the response AIRCRAFT_NO:\n"); print(summary(reg$AIRCRAFT_NO))
cat("skewness of AIRCRAFT_NO:", round(skewness(reg$AIRCRAFT_NO), 3),
    "  of log10(AIRCRAFT_NO):", round(skewness(reg$y), 3), "\n")

## --------------------------------------------------------------------------
## 5.3 simple regression first (one predictor)
## --------------------------------------------------------------------------
reg$wlog <- log10(reg$WEAPONS_DELIVERED)
simple <- lm(y ~ wlog, data = reg)
cat("\n--- 5.3 Simple linear regression: log10(aircraft) on log10(weapons) ---\n")
print(summary(simple)$coefficients)
cat("R squared:", round(summary(simple)$r.squared, 4), "\n")

## --------------------------------------------------------------------------
## 5.4 multiple regression
## --------------------------------------------------------------------------
fit <- lm(y ~ AIRCRAFT_GROUP + COUNTRY + PERIOD + YEAR + SOURCE_DB, data = reg)
cat("\n--- 5.4 Multiple linear regression ---\n")
cat("model: log10(AIRCRAFT_NO) ~ AIRCRAFT_GROUP + COUNTRY + PERIOD + YEAR + SOURCE_DB\n")
cat("reference categories: F-4 Phantom, South Vietnam, Day, SEADAB\n\n")
print(summary(fit))
ss <- summary(fit)
cat("\nR squared:", round(ss$r.squared, 4),
    " adjusted R squared:", round(ss$adj.r.squared, 4), "\n")
cat("F statistic:", round(ss$fstatistic[1], 1), " on", ss$fstatistic[2], "and",
    ss$fstatistic[3], "df, p-value =",
    fmt_p(pf(ss$fstatistic[1], ss$fstatistic[2], ss$fstatistic[3], lower.tail = FALSE)), "\n")
cat("residual standard error:", round(ss$sigma, 4), "on", ss$df[2], "df\n")
cat("AIC:", round(AIC(fit), 1), " vs simple model:", round(AIC(simple), 1), "\n")

cat("\n95% confidence intervals of the coefficients:\n")
print(round(confint(fit), 4))

cat("\ninterpretation of the largest coefficients (change in aircraft, %):\n")
co <- coef(fit)[-1]
for (nm in names(sort(abs(co), decreasing = TRUE))[1:5]) {
  cat(sprintf("  %-34s %+6.1f%%\n", nm, 100 * (10^co[nm] - 1)))
}
cat("(Thailand has only", sum(reg$COUNTRY == "Thailand"),
    "records, so that coefficient is based on a small group)\n")
cat("\nB-52 records carry on average", round(10^coef(fit)["AIRCRAFT_GROUPB-52 Stratofortress"], 2),
    "times as many aircraft as equivalent F-4 records (holding the other\nvariables fixed)\n")

cat("\ncollinearity check: YEAR regressed on all other predictors (factors expanded\nas dummy variables):\n")
vif_year <- 1 / (1 - summary(lm(YEAR ~ AIRCRAFT_GROUP + COUNTRY + PERIOD +
                                  SOURCE_DB, data = reg))$r.squared)
cat("VIF of YEAR:", round(vif_year, 3),
    " -- below the usual threshold of 5, but not negligible: the country mix\n",
    "and the year overlap (for example, targets in Thailand appear only late\n",
    "in the war), so part of the year effect is shared with the country terms\n")

## --------------------------------------------------------------------------
## 5.5 model checks
## --------------------------------------------------------------------------
cat("\n--- 5.5 Model checks ---\n")
set.seed(2026)
sw <- shapiro.test(sample(residuals(fit), 2000))
cat("Shapiro-Wilk test on 2000 residuals: W =", round(sw$statistic, 4),
    " p-value =", fmt_p(sw$p.value), "\n")
cat("skewness of the residuals:", round(skewness(residuals(fit)), 3),
    " kurtosis:", round(kurtosis(residuals(fit)), 3), "\n")
cooks <- cooks.distance(fit)
cat("Cook's distance above 4/n:", sum(cooks > 4 / nrow(reg)),
    " records (", round(100 * mean(cooks > 4 / nrow(reg)), 2), "% )\n")
cat("largest Cook's distance:", round(max(cooks), 4), "\n")

res_df <- data.frame(fitted = fitted(fit), resid = residuals(fit))
p3 <- ggplot(res_df, aes(x = fitted, y = resid)) +
  geom_point(size = 0.4, alpha = 0.25, colour = "black") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Residuals against fitted values",
       x = "Fitted log10(aircraft)", y = "Residual") +
  theme_rep
save_fig(p3, "fig5_3_residuals_fitted.png")

p4 <- ggplot(res_df, aes(sample = resid)) +
  stat_qq(size = 0.4, alpha = 0.4, colour = "black") +
  stat_qq_line(colour = "black", linetype = "dashed") +
  labs(title = "Normal Q-Q plot of the regression residuals",
       x = "Theoretical quantiles", y = "Sample quantiles") +
  theme_rep
save_fig(p4, "fig5_4_residual_qq.png", height = 4.2)

## --------------------------------------------------------------------------
## 5.6 prediction
## --------------------------------------------------------------------------
cat("\n--- 5.6 Prediction example ---\n")
new <- reg[1, ]
new$AIRCRAFT_GROUP <- factor("F-4 Phantom", levels = levels(reg$AIRCRAFT_GROUP))
new$COUNTRY <- factor("North Vietnam", levels = levels(reg$COUNTRY))
new$PERIOD <- factor("Night", levels = levels(reg$PERIOD))
new$YEAR <- 1972
new$SOURCE_DB <- factor("SEADAB", levels = levels(reg$SOURCE_DB))
pr <- predict(fit, newdata = new, interval = "prediction", level = 0.95)
cat("profile: F-4 Phantom, target North Vietnam, night, 1972, SEADAB\n")
cat("predicted log10(aircraft):", round(pr[1], 4), "  => aircraft:",
    round(10^pr[1], 2), "\n")
cat("95% prediction interval: [", round(10^pr[2], 2), ",", round(10^pr[3], 2), "] aircraft\n")
obs <- subset(DATA, AIRCRAFT_GROUP == "F-4 Phantom" & COUNTRY == "North Vietnam" &
                PERIOD == "Night" & YEAR == 1972 & SOURCE_DB == "SEADAB")
cat("observed records with this profile:", nrow(obs),
    " observed mean aircraft:", round(mean(obs$AIRCRAFT_NO), 2), "\n")

end_log()
cat("problem5.R finished; wrote outputs/problem5.txt and 4 figures\n")
