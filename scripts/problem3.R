## --------------------------------------------------------------------------
## problem3.R -- Unit III: hypothesis testing (two-sample t-test)
##
## Problem statement 3:
## Do night delivery records carry a heavier weapon load than day delivery
## records?  Two-sample test on the logarithm of the weapon load with
## assumption checks and a non-parametric cross-check.
##
## Input : clean_data.csv   Output: outputs/problem3.txt, figures/fig3_*.png
## --------------------------------------------------------------------------

source("scripts/common_setup.R")
cat("problem3.R running ...\n")
begin_log("outputs/problem3.txt")

cat("=============================================================\n")
cat("PROBLEM 3: Day versus night weapon load (two-sample t-test)\n")
cat("=============================================================\n\n")

## analysis subset: records with a positive recorded load and a day/night code
sub <- subset(DATA, !is.na(LOAD_LB) & !is.na(PERIOD))
sub$z <- log10(sub$LOAD_LB)
cat("Records used:", nrow(sub), " (of", nrow(DATA), "in the sample)\n")
cat("records dropped: no load recorded =", sum(is.na(DATA$LOAD_LB)),
    ", period of day unknown =", sum(!is.na(DATA$LOAD_LB) & is.na(DATA$PERIOD)), "\n")
print(table(sub$PERIOD))

## --------------------------------------------------------------------------
## 3.1 group summaries
## --------------------------------------------------------------------------
cat("\n--- 3.1 Summary of the weapon load by period of day ---\n")
sum_fn <- function(x) c(n = length(x), mean = mean(x), sd = sd(x),
                        median = median(x), q1 = quantile(x, .25),
                        q3 = quantile(x, .75))
tab <- rbind(Day = sum_fn(sub$LOAD_LB[sub$PERIOD == "Day"]),
             Night = sum_fn(sub$LOAD_LB[sub$PERIOD == "Night"]))
print(round(tab, 1))
cat("\ngeometric mean load (10^mean of log10):\n")
gm <- tapply(sub$z, sub$PERIOD, function(x) 10^mean(x))
print(round(gm, 0))
cat("\nratio of geometric means (night / day):",
    round(gm["Night"] / gm["Day"], 3), "\n")

## --------------------------------------------------------------------------
## 3.2 assumptions
## --------------------------------------------------------------------------
cat("\n--- 3.2 Assumptions ---\n")
cat("(a) The records are separate delivery reports from different missions.\n")
cat("    They are treated as independent; in reality one mission can appear in\n")
cat("    several records, so the p-value is slightly optimistic.  This is a\n")
cat("    limitation of the source data, not of the test.\n\n")
cat("(b) Normality of the log load inside each group\n")
set.seed(2026)
for (g in c("Day", "Night")) {
  zz <- sub$z[sub$PERIOD == g]
  sw <- shapiro.test(sample(zz, min(2000, length(zz))))
  cat(sprintf("    %-6s n=%5d  skewness=%6.3f  Shapiro-Wilk (n=2000): W=%.4f  p=%s\n",
              g, length(zz), skewness(zz), sw$statistic, fmt_p(sw$p.value)))
}
cat("    The log loads are much closer to symmetric than the raw loads\n")
cat("    (group skewness above versus +4.55 for the raw variable), but the\n")
cat("    Shapiro-Wilk test still rejects at this sample size, so the\n")
cat("    Mann-Whitney test is added below as a cross-check.\n\n")
cat("(c) Equal variances\n")
vv <- var.test(z ~ PERIOD, data = sub)
cat("    F test on the logs: F =", round(vv$statistic, 3), " df =",
    paste(vv$parameter, collapse = ","), " p-value =", fmt_p(vv$p.value), "\n")
lv <- levene_test(sub$z, sub$PERIOD)
cat("    Levene test        : F =", round(lv[1], 3), " df1 =", lv[2],
    " df2 =", lv[3], " p-value =", fmt_p(lv[4]), "\n")
cat("    The variance ratio is small but the test is significant because n is\n")
cat("    large; for this reason Welch's version of the t-test is used, which\n")
cat("    does not assume equal variances.\n")

## --------------------------------------------------------------------------
## 3.3 the test
## --------------------------------------------------------------------------
cat("\n--- 3.3 Welch two-sample t-test on log10(load) ---\n")
tt <- t.test(z ~ PERIOD, data = sub)          # Welch by default
print(tt)
mA <- unname(tt$estimate[["mean in group Day"]])
mB <- unname(tt$estimate[["mean in group Night"]])
d <- mA - mB                                   # Day minus Night
ci <- tt$conf.int                              # confidence interval for Day - Night
cat("\ndifference of means on the log10 scale (Day - Night):", round(d, 4),
    " 95% CI [", round(ci[1], 4), ",", round(ci[2], 4), "]\n")
cat("=> ratio of geometric means Day/Night:", round(10^d, 3),
    " 95% CI [", round(10^ci[1], 3), ",", round(10^ci[2], 3), "]\n")
cat("=> the day geometric mean is", round(100 * (10^d - 1), 1),
    "% higher (CI:", round(100 * (10^ci[1] - 1), 1), "% to",
    round(100 * (10^ci[2] - 1), 1), "%)\n")

pooled_sd <- sqrt(((sum(sub$PERIOD == "Day") - 1) * sd(sub$z[sub$PERIOD == "Day"])^2 +
                   (sum(sub$PERIOD == "Night") - 1) * sd(sub$z[sub$PERIOD == "Night"])^2) /
                  (nrow(sub) - 2))
cat("Cohen's d on the log scale:", round(d / pooled_sd, 3), "\n")

cat("\nwhy the raw means point the other way -- the night group has a heavy tail:\n")
cat("  raw mean load, day  :", round(mean(sub$LOAD_LB[sub$PERIOD == "Day"]), 0), "\n")
cat("  raw mean load, night:", round(mean(sub$LOAD_LB[sub$PERIOD == "Night"]), 0), "\n")
cat("  share of records with load > 200,000 lb -- day:",
    round(100 * mean(sub$LOAD_LB[sub$PERIOD == "Day"] > 200000), 2), "%  night:",
    round(100 * mean(sub$LOAD_LB[sub$PERIOD == "Night"] > 200000), 2), "%\n")
cat("  share of records with load < 10,000 lb  -- day:",
    round(100 * mean(sub$LOAD_LB[sub$PERIOD == "Day"] < 10000), 2), "%  night:",
    round(100 * mean(sub$LOAD_LB[sub$PERIOD == "Night"] < 10000), 2), "%\n")
cat("  (night deliveries are polarised: many very light loads and a larger\n")
cat("   share of very heavy loads, so their mean is pulled up while their\n")
cat("   median and geometric mean are lower than the day values)\n")

cat("\n--- 3.4 Cross-check with the Mann-Whitney test (no normality assumed) ---\n")
w <- wilcox.test(LOAD_LB ~ PERIOD, data = sub)
cat("Mann-Whitney U:", format(w$statistic, scientific = FALSE),
    " p-value =", fmt_p(w$p.value), "\n")
cat("median load, day:", median(sub$LOAD_LB[sub$PERIOD == "Day"]),
    " night:", median(sub$LOAD_LB[sub$PERIOD == "Night"]), "\n")
cat("difference of medians (day - night):",
    median(sub$LOAD_LB[sub$PERIOD == "Day"]) - median(sub$LOAD_LB[sub$PERIOD == "Night"]), "\n")

## --------------------------------------------------------------------------
## 3.5 figures
## --------------------------------------------------------------------------
p1 <- ggplot(sub, aes(x = PERIOD, y = LOAD_LB)) +
  geom_boxplot(fill = "grey85", width = 0.4, outlier.size = 0.3,
               outlier.colour = "grey45") +
  scale_y_continuous(trans = "log10") +
  labs(title = "Weapon load by period of day",
       subtitle = "logarithmic scale; boxplot median and quartiles",
       x = "Period of day at the target", y = "Weapon load (pounds, log scale)") +
  theme_rep
save_fig(p1, "fig3_1_boxplot_period.png", width = 5.2, height = 4.6)

p2 <- ggplot(sub, aes(sample = z)) +
  stat_qq(colour = "black", size = 0.5, alpha = 0.45) +
  stat_qq_line(colour = "black", linetype = "dashed") +
  facet_wrap(~ PERIOD) +
  labs(title = "Normal Q-Q plots of log10(weapon load)",
       x = "Theoretical quantiles", y = "Sample quantiles") +
  theme_rep
save_fig(p2, "fig3_2_qq_by_period.png", width = 6.6, height = 3.6)

p3 <- ggplot(sub, aes(x = LOAD_LB, linetype = PERIOD)) +
  stat_ecdf(linewidth = 0.7, colour = "black") +
  scale_x_continuous(trans = "log10") +
  labs(title = "Empirical distribution functions of the weapon load",
       x = "Weapon load (pounds, log scale)", y = "Cumulative proportion",
       linetype = "Period of day") +
  theme_rep
save_fig(p3, "fig3_3_ecdf_period.png", width = 6.0, height = 4.2)

end_log()
cat("problem3.R finished; wrote outputs/problem3.txt and 3 figures\n")
