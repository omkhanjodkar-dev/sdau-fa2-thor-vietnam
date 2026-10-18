# ORAL_PREP.md

Likely viva questions with short, defensible answers. Numbers refer to
outputs/*.txt and report/report.pdf.

## Data and cleaning

**Q1. Why did you analyse a sample instead of the full 46.7-lakh-row file?**
The full file is 1.5 GB; a random sample of 20,000 records is large enough for
every test we use (chi-square with cell counts in the thousands, t-tests with
4,196/1,695 records per group) and lets every script run in seconds. The seed
(2026) is fixed, so the sample is reproduced exactly on every run.

**Q2. Why is the weapon load available for only 29.5% of the sample?**
LOAD_LB comes from WEAPONSLOADEDWEIGHT, which is only filled in the SEADAB source
database. Every load result therefore describes SEADAB records; this is stated in
the report instead of hiding it.

**Q3. Why did you treat -1 and 9999 as missing?**
They are the source's documented sentinel codes: -1 marks "not recorded" and 9999
in NUMWEAPONSDELIVERED is an overflow marker. The raw profile (scripts/00_profile_raw.R)
shows exactly where they occur, and the cleaning log counts every replacement.

**Q4. Why does B-52 appear as its own group when it is only the 7th type by count?**
Because it is operationally distinctive (median load 3.82 lakh lb, about 1.56x the
aircraft per record of an F-4). Keeping it separate makes the mixture story in
Problem 2 and the residual story in Problem 4 visible. This choice is documented
in ASSUMPTIONS.md item 12.

## Problem 1

**Q5. Why do you report medians when you also have means?**
Weapons delivered have skewness 21.5: mean 38.1 against median 8. The mean is a
statement about the total, the median about the typical record; both are useful
but they must not be confused.

## Problem 2

**Q6. You rejected the lognormal model - so why keep it?**
Two different questions: does a model fit perfectly (no), and is it useful (yes).
The lognormal statistic is 610 against 7,338 for the normal, and its probabilities
are within about 4 percentage points of the observed shares. The formal rejection
is caused by the data being a mixture of aircraft groups (B-52 vs A-37 medians
differ by more than a factor of 10), which no single distribution can fit.

**Q7. Why df = 5 in the chi-square goodness of fit?**
8 equal-probability bins give 7 df; two parameters were estimated from the data
(mean, sd), so we subtract 2: df = 5. The standard result for an estimated-
parameter chi-square test.

**Q8. The CLT simulation shows skewness 0.822 for n = 30. Is the CLT failing?**
No - the CLT is asymptotic. The simulated mean and standard error match theory
almost exactly (59,736.9 vs 59,795.3; 17,169 vs 17,292). The residual skew just
says n = 30 is not "large" for a variable with kurtosis 25; at n = 100 it would be
visually normal.

## Problem 3

**Q9. Raw means say night loads are heavier, your test says day loads are heavier.
Which is right?**
The test, for "typical record" claims. The night group is polarised: 27.9% of its
records are below 10,000 lb (day: 13.8%) but it also has proportionally more very
heavy deliveries (6.8% above 200,000 lb vs 3.2%), which pull its mean up. On the
log scale day is +39.2% (CI 28.5-50.9%), and the medians agree (42,240 vs 24,900).

**Q10. Why Welch and not the standard t-test?**
The variance-ratio F test (0.605) and Levene's test both reject equal variances on
the logs. Welch is the safe default and costs almost no power when variances are
equal.

**Q11. Is the effect important, not just significant?**
Cohen's d = 0.26, small-to-moderate. The significance is partly a matter of
n = 5,891; the confidence interval on the ratio (1.28 to 1.51) is the honest
summary.

## Problem 4

**Q12. Why were Thailand records excluded?**
Two expected cell counts fell below 5, where the chi-square approximation is
documented to break down. Thailand is 0.4% of the sample; excluding it is stated
up front in the report. An alternative (Fisher/permutation) is overkill for a
0.4% cell.

**Q13. Is Cramer's V = 0.278 strong?**
Moderate by the usual rule of thumb (0.1/0.3/0.5). With df = 18, a small V can be
"significant" at n = 19,569; that is exactly why the report quotes V and the
residual table, not only the p-value.

**Q14. What does a standardised residual of +42 mean?**
The F-100/South Vietnam cell has 2,516 records against 1,489 expected under
independence, i.e. 42.2 standard deviations of Poisson noise above expectation. It
is the single strongest pattern in the table.

## Problem 5

**Q15. Your R squared is only 0.166. Is the model bad?**
It is a record-level model with five factors: it explains about 17% of
record-to-record variation of formation size. The dominant drivers (type, period)
are captured with large, precise coefficients (B-52 +55.9%, Night -36.9%, all
p < 1e-12) and the prediction example validates (1.55 predicted vs 1.75 observed
mean of 32 records). The remaining variation lives in factors not recorded per
record (target importance, availability, weather), which is a data limit, not a
model error.

**Q16. Why is the response log10(aircraft)?**
Raw counts go from 1 to 276 with skewness 9.7; on the log scale skewness is 2.5
and the residuals are symmetrical enough for inference. Coefficients convert to
percentage changes exactly (10^b - 1).

**Q17. Why is YEAR's VIF 3.76 and not ~1?**
Country composition drifts over the war (Thailand only appears late, northern
targets cluster in 1967-68 and 1972), so YEAR partly overlaps the country dummies.
Still below the threshold 5; the report warns to read the 7%/year as an average
trend, not a causal effect.

**Q18. What does the largest Cook's distance tell you?**
0.0089, far below 1: no single record drives the coefficients. The heavy
right-skewed residuals come from the largest formations (up to 99 aircraft) that
the model under-predicts - expected for a multiplicative model of counts.

## Methods and integrity

**Q19. Are your p-values trustworthy given one mission = several records?**
We state clearly they are optimistic because rows are not independent missions.
The remedy used here is to lean on effect sizes and intervals, all of which are
unaffected by the mild dependence; a rigorous fix (cluster-robust errors on
MISSIONID) is listed as future work, and MISSIONID is included in the raw data.

**Q20. What was the hardest part?**
Keeping honesty: rejecting the lognormal on a large sample shattered early; the
professional answer was the mixture investigation (Problem 2) instead of hiding
the misfit. The reversal of the raw means in Problem 3 taught the same lesson from
the other side.

**Q21. If you had one more week?**
Cluster-robust standard errors, weighting the sample to the population
(survey-style weights), and a two-part model for the load (probability of being
recorded x load given recorded) to handle the SEADAB-only censoring.
