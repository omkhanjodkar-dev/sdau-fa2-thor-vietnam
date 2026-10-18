## --------------------------------------------------------------------------
## problem2.R -- Unit II: probability and probability distributions
##
## Problem statement 2:
## The weapon load of a delivery record.  Can a simple probability model
## (normal or lognormal) describe the recorded ordnance weight, what
## probabilities for a heavy strike follow from the model that fits best, and
## how well does the central limit theorem describe the average load of a
## group of 30 records?
##
## Note: WEAPONSLOADEDWEIGHT (LOAD_LB) is recorded only in the SEADAB source,
## so this problem works with those records.
##
## Input : clean_data.csv   Output: outputs/problem2.txt, figures/fig2_*.png
## --------------------------------------------------------------------------

source("scripts/common_setup.R")
cat("problem2.R running ...\n")
begin_log("outputs/problem2.txt")

cat("=============================================================\n")
cat("PROBLEM 2: Probability model for the weapon load of a record\n")
cat("=============================================================\n\n")

## analysis variable: positive recorded weapon load
load <- DATA$LOAD_LB[!is.na(DATA$LOAD_LB)]
n <- length(load)
cat("Records with a recorded weapon load (LOAD_LB > 0):", n, "\n")
cat("share of the 20,000-record sample:", round(100 * n / nrow(DATA), 1), "%\n")
cat("source of these records:\n"); print(table(DATA$SOURCE_DB[!is.na(DATA$LOAD_LB)]))

## --------------------------------------------------------------------------
## 2.1 the variable
## --------------------------------------------------------------------------
cat("\n--- 2.1 Descriptive statistics of the weapon load (pounds) ---\n")
cat("n       :", n, "\n")
cat("mean    :", round(mean(load), 1), "\n")
cat("median  :", round(median(load), 1), "\n")
cat("sd      :", round(sd(load), 1), "\n")
cat("min/max :", min(load), "/", max(load), "\n")
cat("skewness:", round(skewness(load), 3), " (0 for a symmetric variable)\n")
cat("kurtosis:", round(kurtosis(load), 3), " (0 for a normal variable)\n")
cat("quartiles:", paste(round(quantile(load, c(.25, .5, .75)), 0), collapse = "  "), "\n")

p1 <- ggplot(data.frame(load), aes(x = load)) +
  geom_histogram(bins = 40, fill = "grey55", colour = "black", linewidth = 0.2) +
  labs(title = "Recorded weapon load per delivery record",
       x = "Weapon load (pounds)", y = "Number of records") +
  theme_rep
save_fig(p1, "fig2_1_load_hist.png")

## --------------------------------------------------------------------------
## 2.2 candidate 1: a normal distribution for the load itself
## --------------------------------------------------------------------------
## equal-probability bins from the fitted normal: expected count = n/8 per bin
gof_chisq <- function(x, mean_hat, sd_hat, nbin = 8) {
  br <- qnorm(seq(0, 1, length.out = nbin + 1), mean_hat, sd_hat)
  br[1] <- -Inf; br[nbin + 1] <- Inf
  obs <- as.numeric(table(cut(x, br, include.lowest = TRUE)))
  exp <- length(x) / nbin
  list(stat = sum((obs - exp)^2 / exp), df = nbin - 1 - 2, obs = obs, exp = exp)
}

m_hat <- mean(load)
s_hat <- sqrt(mean((load - m_hat)^2))
g_norm <- gof_chisq(load, m_hat, s_hat)

cat("\n--- 2.2 Candidate 1: normal distribution for the load ---\n")
cat("maximum likelihood estimates: mean =", round(m_hat, 1),
    " sd =", round(s_hat, 1), "\n")
cat("chi-square goodness of fit (8 equal-probability bins): statistic =",
    round(g_norm$stat, 1), " df =", g_norm$df, " p-value =",
    fmt_p(pchisq(g_norm$stat, g_norm$df, lower.tail = FALSE)), "\n")
cat("observed counts per bin:", g_norm$obs, "\n")
cat("the normal model puts", round(100 * g_norm$exp[1] / n, 1),
    "% of the records in the lowest bin although none can be negative or zero.\n")

## --------------------------------------------------------------------------
## 2.3 candidate 2: lognormal (the normal on the log10 scale)
## --------------------------------------------------------------------------
z <- log10(load)
mu_hat <- mean(z)
sd_hat <- sqrt(mean((z - mu_hat)^2))

cat("\n--- 2.3 Candidate 2: lognormal model ---\n")
cat("log10(load): mean =", round(mu_hat, 4), " sd =", round(sd_hat, 4), "\n")
cat("=> lognormal parameters in natural logs: meanlog =",
    round(mu_hat * log(10), 4), " sdlog =", round(sd_hat * log(10), 4), "\n")
cat("skewness of the log10 values:", round(skewness(z), 3),
    "  kurtosis:", round(kurtosis(z), 3), "\n")

set.seed(2026)
sw <- shapiro.test(sample(z, 2000))
cat("Shapiro-Wilk test on a random subsample of 2000 log10 values: W =",
    round(sw$statistic, 4), " p-value =", fmt_p(sw$p.value), "\n")

g_log <- gof_chisq(z, mu_hat, sd_hat)
cat("chi-square goodness of fit (8 equal-probability bins): statistic =",
    round(g_log$stat, 1), " df =", g_log$df, " p-value =",
    fmt_p(pchisq(g_log$stat, g_log$df, lower.tail = FALSE)), "\n")
cat("observed counts per bin :", g_log$obs, "\n")
cat("expected counts per bin :", round(rep(n / 8, 8), 1), "\n")

cat("\ncomparison of observed and fitted quartiles of the load:\n")
qt <- rbind(observed = quantile(load, c(.25, .5, .75)),
            fitted   = 10^qnorm(c(.25, .5, .75), mu_hat, sd_hat))
print(round(qt, 0))

p2 <- ggplot(data.frame(z), aes(x = z)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40, fill = "grey70",
                 colour = "black", linewidth = 0.2) +
  stat_function(fun = dnorm, args = list(mean = mu_hat, sd = sd_hat),
                colour = "black", linewidth = 0.8, linetype = "dashed") +
  labs(title = "Weapon load after the log10 transformation",
       subtitle = "dashed curve: fitted normal density",
       x = "log10(weapon load in pounds)", y = "Density") +
  theme_rep
save_fig(p2, "fig2_2_log_hist.png")

p3 <- ggplot(data.frame(z), aes(sample = z)) +
  stat_qq(colour = "black", size = 0.5, alpha = 0.5) +
  stat_qq_line(colour = "black", linetype = "dashed") +
  labs(title = "Normal Q-Q plot of log10(weapon load)",
       x = "Theoretical quantiles", y = "Sample quantiles") +
  theme_rep
save_fig(p3, "fig2_3_log_qq.png", height = 4.0)

## why does the lognormal model fail? -> the load depends on the aircraft
p4 <- ggplot(subset(DATA, !is.na(LOAD_LB)), aes(x = AIRCRAFT_GROUP, y = LOAD_LB)) +
  geom_boxplot(fill = "grey85", outlier.size = 0.3, outlier.colour = "grey40") +
  scale_y_continuous(trans = "log10") +
  labs(title = "Weapon load by aircraft group",
       subtitle = "logarithmic scale; medians differ by more than a factor of 10",
       x = NULL, y = "Weapon load (pounds, log scale)") +
  theme_rep +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
save_fig(p4, "fig2_4_load_by_aircraft.png", height = 4.8)
cat("\nmedian load and number of records by aircraft group:\n")
print(tapply(DATA$LOAD_LB, DATA$AIRCRAFT_GROUP,
             function(x) c(n = sum(!is.na(x)), median = median(x, na.rm = TRUE))))

## --------------------------------------------------------------------------
## 2.4 probabilities for a single record under the lognormal model
## --------------------------------------------------------------------------
cat("\n--- 2.4 Probabilities from the fitted lognormal model ---\n")
prob_cmp <- function(thr) {
  c(threshold = thr,
    fitted_P = 1 - pnorm(log10(thr), mu_hat, sd_hat),
    observed_P = mean(load > thr))
}
cmp <- t(sapply(c(25000, 50000, 75000, 100000), prob_cmp))
print(round(cmp, 4), row.names = FALSE)
cat("\nP(20,000 < load < 60,000) fitted =",
    round(pnorm(log10(60000), mu_hat, sd_hat) - pnorm(log10(20000), mu_hat, sd_hat), 4),
    " observed =", round(mean(load > 20000 & load < 60000), 4), "\n")

## --------------------------------------------------------------------------
## 2.5 central limit theorem for the mean load of 30 records
## --------------------------------------------------------------------------
cat("\n--- 2.5 Sampling distribution of the mean load of n = 30 records ---\n")
mX <- mean(load); sX <- sd(load)
se <- sX / sqrt(30)
cat("mean of the variable       :", round(mX, 1), "\n")
cat("standard deviation         :", round(sX, 1), "\n")
cat("standard error of the mean (n = 30):", round(se, 1), "\n")
cat("CLT normal approximation: P(sample mean > 70,000 lb) =",
    round(1 - pnorm(70000, mX, se), 4), "\n")

set.seed(2026)
sim <- replicate(20000, mean(sample(load, 30, replace = TRUE)))
cat("simulation, 20,000 samples of 30 records:\n")
cat("  P(sample mean > 70,000 lb) =", round(mean(sim > 70000), 4), "\n")
cat("  mean of the sample means   =", round(mean(sim), 1),
    " (theoretical", round(mX, 1), ")\n")
cat("  sd of the sample means     =", round(sd(sim), 1),
    " (theoretical", round(se, 1), ")\n")
cat("  skewness of the means      =", round(skewness(sim), 3), "\n")

p5 <- ggplot(data.frame(mean_load = sim), aes(x = mean_load)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40, fill = "grey70",
                 colour = "black", linewidth = 0.2) +
  stat_function(fun = dnorm, args = list(mean = mX, sd = se),
                colour = "black", linetype = "dashed", linewidth = 0.8) +
  labs(title = "Simulated sampling distribution of the mean load",
       subtitle = "20,000 samples of 30 records; dashed curve: normal approximation",
       x = "Sample mean weapon load (pounds)", y = "Density") +
  theme_rep
save_fig(p5, "fig2_5_clt_sim.png")

end_log()
cat("problem2.R finished; wrote outputs/problem2.txt and 5 figures\n")
