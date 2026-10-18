# ASSUMPTIONS.md

Every assumption made while preparing the data and running the analysis, with its
reason and its impact. The implementing script is named for each item.

## 1. Domain and data-quality assumptions

1. One row = one weapon-delivery event reported by one source database, not one
   mission (scripts/01_clean.R header). A mission can produce several rows, so
   records are not fully independent. Impact: all p-values in tests are slightly
   optimistic; this is stated in every problem and the effect sizes are quoted
   alongside. Descriptive statistics are unaffected.
2. Study population = records with NUMWEAPONSDELIVERED > 0 (23,46,224 of 46,70,416
   rows, 50.24%; scripts/01_clean.R Step 1). Records that only return or jettison
   weapons are outside the study.
3. NUMWEAPONSDELIVERED = 9999 is a sentinel, not a real count (2 rows in the
   sample set to missing).
4. WEAPONSLOADEDWEIGHT = -1 is the source's missing code (12,394 rows); 0 means the
   record delivered non-ordnance (flares, leaflets) so a weapon load does not apply
   (1,600 rows); one value above 1,000,000 lb is implausible (112 rows). All set to
   missing. The load is recorded only in the SEADAB source, hence 70.5% missing in
   the sample; load-based results are results about SEADAB records, as stated in
   the report.
5. NUMOFACFT = 0 is impossible in a delivery record (13 rows set to missing).
6. TIMEONTARGET is HHMM; values with minute > 59 or outside 0000-2359 are invalid
   (8 rows). TGT_HOUR = hour of day is derived from the valid values.
7. Target coordinates outside 0-30 N, 90-130 E are considered unusable (2,456
   rows); the box covers the whole theatre with a margin.
8. MSNDATE has two storage formats (272 rows YYYYMMDD, rest DD-MMM-YY); both parsed.
   All 20,000 dates parsed without error.
9. TGTCLOUDCOVER 'NOT OBS' is missing information (396 rows). 'IN CLOUDS' and
   'BETWEEN LAYERS' (very rare) are grouped with 'Other'.
10. TGTCOUNTRY 'PHILLIPINES' is a spelling error for PHILIPPINES; 'WESTPAC WATERS'
    and 'UNKNOWN' (74 and 59 rows in the file) are grouped as 'Other'. MILSERVICE
    'USA' and 'OTHER' (118 rows in the sample) are grouped as 'Other' services.
11. WEAPONTYPECLASS is empty in this file (100% missing), so weapon class is
    obtained by joining WEAPONTYPE with the weapons glossary file; every weapon
    string matched (0 unmatched).
12. Aircraft are grouped into the six most recorded types (F-4, F-100, A-4, A-1,
    A-37, B-52) plus 'Other' (scripts/01_clean.R). The B-52 is deliberately kept as
    its own group although it is only the 7th type by record count, because of its
    distinctive mission profile; this choice is visible in every aircraft breakdown.
13. The analysis works on one shared simple random sample of 20,000 records
    (set.seed(2026)) instead of the full 23.5-lakh population, so all five problems
    refer to the same records and every result can be cross-checked; the sample is
    large enough for all tests used. Standard sampling caveats apply (the sample is
    of records, not of missions).

## 2. Statistical-method assumptions per problem

Problem 1 (descriptive analysis; scripts/problem1.R): none beyond the data
assumptions above. Medians and quartiles are reported next to means because the
variables are strongly right-skewed.

Problem 2 (probability model; scripts/problem2.R):
- Normal and lognormal parameters are estimated by maximum likelihood (sample mean
  and sd; mean and sd of log10 for the lognormal).
- Goodness of fit uses the chi-square test with 8 equal-probability bins;
  df = 7 bins - 1 - 2 estimated parameters = 5 (standard practice for estimated
  parameters).
- Shapiro-Wilk is run on a random subsample of 2,000 because the test is not
  designed for n close to 6,000 with extreme skew.
- The CLT simulation uses 20,000 repetitions of samples of n = 30, seed fixed;
  simulation error of the reported probabilities is about +/- 0.003.

Problem 3 (two-sample t-test; scripts/problem3.R):
- The test is applied to log10(load) because the raw load is far too skewed both
  for the t-test and for meaningful means; a comparison of log means is a
  comparison of geometric means (stated in the report).
- Welch's version is used (unequal variances) after the F test and Levene's test
  (median-centred, base-R implementation in common_setup.R) both indicated unequal
  variances; this is the safe default.
- Cohen's d uses the pooled sd of the log values and is interpreted on the usual
  small/medium/large scale.
- Mann-Whitney is computed with the normal approximation (exact = FALSE) because
  of ties in the raw loads.
- The t-test assumes independent groups; the mission-level dependence is declared
  as a limitation and does not change the direction or the effect size.

Problem 4 (chi-square test; scripts/problem4.R):
- Expected counts must be at least 5; the 82 records with targets in Thailand
  (0.4%) are excluded for this reason, leaving 19,569 records for the test. This is
  stated in the report so the exclusion is transparent.
- Cramer's V is interpreted with the common rule of thumb (0.1 small, 0.3
  moderate, 0.5 strong); 0.278 is called moderate.
- |standardised residual| > 3 is used as the rule to flag the cells that drive the
  association (approximately a 0.3% two-sided tail each).
- The test treats records as independent; the mission-level dependence makes the
  p-value optimistic (stated), the residual pattern and V are robust.

Problem 5 (correlation and regression; scripts/problem5.R):
- The response is log10(AIRCRAFT_NO) because the count is strongly skewed
  (skewness 9.7 raw, 2.5 in logs). Coefficients are read as percentage changes via
  10^b - 1.
- Coeffients are estimated by ordinary least squares on the 18,811 records with
  all model variables present (listwise deletion, 6% of the sample; missingness is
  spread thin so the deletion does not bias the model demonstrably).
- YEAR enters as a linear term; the residual plots show no curvature that would
  demand a quadratic or factor version.
- Reference categories: F-4 Phantom, South Vietnam, Day, SEADAB (the most frequent
  category of each factor).
- The VIF of YEAR is computed against all other predictors treated as dummies;
  threshold 5 for concern.
- The prediction example is a well-observed profile (32 records) so it can be
  validated against the observed mean.
- Correlation coefficients are reported pairwise (complete observations for each
  pair); for skewed pairs the Spearman coefficient is the primary one, the Pearson
  value is shown to demonstrate the distortion.

## 3. Course-mapping assumption

The mapping "Unit I - descriptive analysis; Unit II - probability distributions;
Unit III - sampling and hypothesis testing; Unit IV - correlation and regression"
follows the unit list of the subject (BSH23OE04, Statistical Data Analysis using
R). The actual syllabus order was not available at the time of writing; if the
course orders its units differently, the mapping table in the report can be
relabelled without changing any analysis (Report Table 3, report/build_report.py).

## 4. Software and reproducibility assumptions

- R 4.6.1 with base R plus readr and ggplot2 only; all special statistics
  (Levene, skewness, kurtosis, VIF) are implemented in base R in
  scripts/common_setup.R so the project also runs without extra packages.
- Scripts are run from the project root (`Rscript scripts/<file>.R`); every script
  re-creates its own outputs. The sample is rebuilt identically on every run
  because the seed is fixed (2026).
- The report is generated from the outputs and figures by
  `python report/build_report.py` (python-docx) and converted to PDF with
  docx2pdf (Microsoft Word).
- If an editor adds a UTF-8 byte-order mark to a script on Windows, the byte-order
  mark is stripped before running (see README.md "Running the project").
