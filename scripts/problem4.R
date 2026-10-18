## --------------------------------------------------------------------------
## problem4.R -- Unit III: chi-square test of independence
##
## Problem statement 4:
## Is the mix of aircraft types used in a delivery record independent of the
## target country?  Chi-square test of independence with effect size and
## analysis of the largest standardised residuals.
##
## Input : clean_data.csv   Output: outputs/problem4.txt, figures/fig4_*.png
## --------------------------------------------------------------------------

source("scripts/common_setup.R")
cat("problem4.R running ...\n")
begin_log("outputs/problem4.txt")

cat("=============================================================\n")
cat("PROBLEM 4: Aircraft type and target country (chi-square test)\n")
cat("=============================================================\n\n")

sub <- subset(DATA, !is.na(AIRCRAFT_GROUP) & !is.na(COUNTRY))
cat("Records with both variables recorded:", nrow(sub), " (of", nrow(DATA),
    "in the sample)\n")
cat("dropped: aircraft group unknown =", sum(is.na(DATA$AIRCRAFT_GROUP)),
    ", target country unknown =", sum(is.na(DATA$COUNTRY)), "\n")
n_th <- sum(sub$COUNTRY == "Thailand")
sub <- subset(sub, COUNTRY != "Thailand")
sub$COUNTRY <- droplevels(sub$COUNTRY)
cat("records with targets in Thailand excluded:", n_th,
    " (expected counts for two aircraft groups were below 5, which breaks the\n")
cat("  chi-square approximation; Thailand holds only",
    round(100 * n_th / nrow(DATA), 1), "% of the sample)\n\n")

## --------------------------------------------------------------------------
## 4.1 contingency table
## --------------------------------------------------------------------------
tab <- table(sub$AIRCRAFT_GROUP, sub$COUNTRY)
cat("--- 4.1 Contingency table: aircraft group (rows) by target country ---\n")
print(tab)
cat("\nrow percentages:\n")
print(round(100 * prop.table(tab, 1), 1))
cat("\ncolumn totals:\n")
print(colSums(tab))

## --------------------------------------------------------------------------
## 4.2 assumptions
## --------------------------------------------------------------------------
cat("\n--- 4.2 Assumptions ---\n")
cat("(a) Each record contributes to exactly one cell: yes, the two variables\n")
cat("    are recorded once per record.\n")
cat("(b) Independence between records: records are separate delivery reports,\n")
cat("    but one mission can generate several records, so the effective sample\n")
cat("    is smaller than 19,650 and the p-value is optimistic.  The conclusion\n")
cat("    is therefore based on the effect size as much as on the p-value.\n")
cat("(c) Expected frequencies: minimum expected count =",
    round(min(chisq.test(tab)$expected), 2),
    "; all expected counts >= 5 is", all(chisq.test(tab)$expected >= 5), "\n")

## --------------------------------------------------------------------------
## 4.3 the test
## --------------------------------------------------------------------------
cat("\n--- 4.3 Chi-square test of independence ---\n")
ct <- chisq.test(tab)
print(ct)
cat("\nmin expected count:", round(min(ct$expected), 2),
    " max expected count:", round(max(ct$expected), 1), "\n")

k <- min(nrow(tab), ncol(tab))
V <- sqrt(as.numeric(ct$statistic) / (sum(tab) * (k - 1)))
cat("Cramer's V =", round(V, 3), " (0 = no association, 1 = perfect association)\n")

cat("\nstandardised residuals (observed - expected) / sqrt(expected):\n")
res <- round(ct$stdres, 1)
print(res)
cat("\n|standardised residual| > 3 (cells that contribute most to the test):\n")
rr <- which(abs(ct$stdres) > 3, arr.ind = TRUE)
if (nrow(rr)) {
  for (i in seq_len(nrow(rr))) {
    cat(sprintf("  %-20s x %-14s  observed %5d  expected %7.1f  std.residual %6.1f\n",
                rownames(res)[rr[i, 1]], colnames(res)[rr[i, 2]],
                tab[rr[i, 1], rr[i, 2]], ct$expected[rr[i, 1], rr[i, 2]],
                ct$stdres[rr[i, 1], rr[i, 2]]))
  }
}
cat("\nshare of North Vietnam records flown by B-52:",
    round(100 * tab["B-52 Stratofortress", "North Vietnam"] /
            sum(tab[, "North Vietnam"]), 1), "%\n")
cat("share of all records flown by B-52:",
    round(100 * sum(tab["B-52 Stratofortress", ]) / sum(tab), 1), "%\n")
cat("B-52 records: North Vietnam",
    tab["B-52 Stratofortress", "North Vietnam"], " of",
    sum(tab["B-52 Stratofortress", ]), " (",
    round(100 * tab["B-52 Stratofortress", "North Vietnam"] /
            sum(tab["B-52 Stratofortress", ]), 1), "%)\n")

## --------------------------------------------------------------------------
## 4.4 figures
## --------------------------------------------------------------------------
row_pct <- as.data.frame(prop.table(tab, 1) * 100)
names(row_pct) <- c("aircraft", "country", "pct")
p1 <- ggplot(row_pct, aes(x = aircraft, y = pct, fill = country)) +
  geom_col(colour = "black", linewidth = 0.2,
           position = position_dodge(width = 0.8), width = 0.75) +
  grey_fill +
  labs(title = "Target country mix by aircraft group",
       x = NULL, y = "Percentage of the group's records", fill = "Target country") +
  theme_rep +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
save_fig(p1, "fig4_1_country_mix_by_aircraft.png", height = 4.8)

res_df <- as.data.frame(ct$stdres)
names(res_df) <- c("aircraft", "country", "stdres")
res_df$stdres_cap <- pmax(pmin(res_df$stdres, 12), -12)
p2 <- ggplot(res_df, aes(x = country, y = aircraft, fill = stdres_cap)) +
  geom_tile(colour = "black", linewidth = 0.2) +
  geom_text(aes(label = round(stdres, 1)), size = 2.8, colour = "black") +
  scale_fill_gradient(low = "white", high = "grey35", name = "std.\nresidual",
                      limits = c(-12, 12)) +
  labs(title = "Standardised residuals of the independence test",
       subtitle = "positive = more records than expected under independence",
       x = "Target country", y = NULL) +
  theme_rep +
  theme(axis.text.x = element_text(angle = 20, hjust = 1),
        panel.grid.major = element_blank())
save_fig(p2, "fig4_2_residual_heatmap.png", height = 4.8)

end_log()
cat("problem4.R finished; wrote outputs/problem4.txt and 2 figures\n")
