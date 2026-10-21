# Presentation and RStudio demo plan

FA-2 project, BSH23OE04, PCCoE. Total time: about 10 minutes + questions.
The demo runs from `SDAUR.Rproj`; every script regenerates its own log and figures.

---

## 1. Who did what (suggested split)

Use this table in the presentation. If your real split was different, swap the
names but keep the part-to-script mapping, so that each person can run the
script they are presenting.

| Student | PRN | Part of the project | Files they show | Key results they own |
|---|---|---|---|---|
| Om Khanjodkar | 125B1B283 | Dataset, cleaning and sampling, Problem 1 (Unit I), report assembly | `scripts/01_clean.R`, `scripts/problem1.R`, `report/build_report.py` | 46,70,416 raw rows -> 23,46,224 deliveries -> 20,000 sample; peak 1970; 53.5% South Vietnam; mean 38.1 vs median 8 |
| Siddhant Verma | 125B1B278 | Problem 2 (Unit II: probability models, goodness of fit, CLT), figure quality checks | `scripts/problem2.R` | chi-square 7,337.8 (normal) vs 610.2 (lognormal); B-52 median 3,82,320 lb; CLT mean 59,736.9 vs theory 59,795.3 |
| Parth Ghumade | 125B1B234 | Problems 3 and 4 (Unit III: Welch t-test, chi-square independence), assumption checks | `scripts/problem3.R`, `scripts/problem4.R` | t = 8.069, p = 1.079e-15, day +39.2%; chi-square = 4,538.3, Cramer's V = 0.278 |
| Tanishk Malge | 125B1B247 | Problem 5 (Unit IV: correlation, multiple regression, prediction), report formatting and final QA | `scripts/problem5.R`, `report/report.docx` | R squared = 0.166; B-52 x1.56; night -36.9%; prediction 1.55 [0.51, 4.69] vs observed 1.75 |

One line to say if sir asks how the work was divided:
"Each problem was owned by one member end to end - script, outputs, figures and
the written section - and all four of us reviewed the whole report, so anyone
can run any script."

---

## 2. Ten-minute run sheet

| Time | Who | What happens on screen |
|---|---|---|
| 0:00 | Om | Intro: project title, dataset, population and sample, report structure |
| 0:45 | Om | Show `clean_data.csv` in the Environment and `outputs/01_data_quality.txt` |
| 1:15 | Om | Source `problem1.R`, walk through Figures 1.1, 1.3, 1.4 |
| 2:45 | Siddhant | Source `problem2.R`, show the model comparison and Figure 2.4 |
| 4:15 | Parth | Source `problem3.R`, show the t-test output and Figure 3.1 |
| 5:30 | Parth | Source `problem4.R`, show the residual heatmap (Figure 4.2) |
| 6:45 | Tanishk | Source `problem5.R`, show the regression table and Figure 5.4 |
| 8:15 | Tanishk | Overall conclusion, limitations, reproducibility, thank you |
| 9:00 | all | Questions - route them by the table in section 6 |

Keep each Source run to 2-5 seconds; do not scroll the console, use the log
files and the Plots pane instead.

---

## 3. Before you enter the lab (5-minute checklist)

1. Double-click `SDAUR.Rproj` so RStudio opens in the project root. Type
   `getwd()` and check the path ends in `\SDAUR`.
2. Increase the font: Tools > Global Options > Appearance > font size 14-16.
3. Clear the console (Ctrl+L) and the Plots pane (broom icon).
4. Open these tabs in order: `problem1.R`, `problem2.R`, `problem3.R`,
   `problem4.R`, `problem5.R`, and `report/report.pdf` in a PDF viewer.
5. Run `problem1.R` once to warm up, then clear the console again. `DATA` stays
   in the Environment, so it is visible from the first second.
6. Keep `ORAL_PREP.md` open on a phone or a printout.
7. Check that `dataset/THOR_Vietnam_Bombing_Operations.csv` is present (only
   needed if sir asks to see `01_clean.R`).

---

## 4. How to drive RStudio during the demo

- **Run a whole script:** open the tab, click the **Source** button at the top
  right of the editor. The console shows the run, `outputs/problemN.txt` is
  rewritten, the figures are refreshed in the Plots pane.
- **Run one line (if sir asks):** put the cursor on the line and press
  **Ctrl+Enter**.
- **Show results calmly:** after Source, do not scroll the console; open
  `outputs/problemN.txt` from the Files pane (lower right) - it is the same log
  in readable form.
- **Show figures:** Plots pane, use the back/forward arrows, click **Zoom** for
  a full-screen view.
- **Show the data:** Environment pane, click `DATA` - "20,000 observations of
  64 variables". `View(DATA)` opens it like a spreadsheet.
- **Full pipeline from raw data (only if asked):** `01_clean.R` reads the
  1.5 GB file in chunks and takes a few minutes; the five problem scripts then
  take 2-5 seconds each.

Useful one-liners if sir asks to run something live (after any script has run):

```r
nrow(DATA)                                    # 20000
median(DATA$WEAPONS_DELIVERED, na.rm = TRUE)  # 8
t.test(log10(LOAD_LB) ~ PERIOD, data = DATA)  # Welch t = 8.0689, p = 1.079e-15
cor(DATA$WEAPONS_DELIVERED, DATA$AIRCRAFT_NO,
    method = "spearman", use = "complete.obs") # 0.173
```

---

## 5. What each person says (speaking script)

### Om - intro, data preparation, Problem 1 (about 2.5 minutes)

Intro:
"Good morning sir. Our FA-2 project is 'Statistical Analysis of the Vietnam War
Bombing Operations Data using R'. We used the THOR Vietnam dataset: 46,70,416
delivery records and 47 columns. Our study population is the 23,46,224 records
that actually delivered a weapon; from that population we drew a random sample
of 20,000 records with seed 2026. All five problem statements and the whole
report are generated from these scripts."

Data preparation:
"The cleaning script applies documented rules - sentinel values like 9999 and
-1 become missing, coordinates outside the 0-30N / 90-130E box are dropped,
aircraft are grouped into six types plus Other. The result is `clean_data.csv`:
20,000 records, 64 columns, and a data-quality log that records every count."

Problem 1 (after Source):
"Figure 1.1 shows the campaign building up from 1966, peaking in 1970 with 3,532
records, and falling after 1972; 57.6% of all records are in 1968-71. South
Vietnam takes 53.5% of the records, Laos 29.2%, North Vietnam 12.0% and Cambodia
4.9%. The F-4 is the most used aircraft at 24.1%, and bombs are 61.8% of the
records with a known weapon class. Figure 1.3 shows why we report medians: half
the records deliver 8 weapons or fewer, while the mean is 38.1 because 5.74%
deliver more than 100. Day records are 13,786 against 5,380 at night."

### Siddhant - Problem 2 (about 1.5 minutes)

"Problem 2 models the weapon load. It is recorded only in the SEADAB source, so
we have 5,894 records, 29.5% of the sample. The normal model is rejected with a
chi-square of 7,337.8 on 5 degrees of freedom - it even needs negative loads.
The lognormal is twelve times better, chi-square 610.2, but still formally
rejected at this sample size. Figure 2.4 explains why: the load is a mixture of
aircraft groups - the B-52 median is 3,82,320 lb against 21,240 lb for the A-37.
Even so the probabilities are usable: the model gives 0.3397 above 50,000 lb
against 0.3522 observed. The CLT check used 20,000 samples of 30 records: the
simulated mean is 59,736.9 against the theoretical 59,795.3, and the standard
deviation 17,169.1 against 17,291.8."

### Parth - Problems 3 and 4 (about 2.5 minutes)

Problem 3:
"We compare the load by period of day on 5,891 records. Because the load is
skewed we test log10(load), which compares geometric means, and we use Welch's
t-test because Levene's test rejects equal variances - F = 143.1. The result is
t = 8.069 on 2,561.6 degrees of freedom, p = 1.079e-15: day deliveries are 39.2%
heavier, with a 95% interval of 28.5% to 50.9%, and Cohen's d is 0.258. The raw
means look reversed, night 65,259 against day 57,615, because night deliveries
are polarised - 27.9% are below 10,000 lb but 6.8% are above 2,00,000 lb. The
medians, 42,240 against 24,900, agree with the test, and the Mann-Whitney test
confirms it with U = 4,112,513."

Problem 4:
"Here both variables are categorical: aircraft group against target country,
19,569 records after excluding 82 Thailand records whose expected counts were
below 5. The chi-square is 4,538.3 on 18 degrees of freedom, p < 2.2e-16, and
Cramer's V is 0.278 - a moderate association. The residual heatmap shows the
pattern: the F-100 and A-37 work almost only over South Vietnam, residuals +42.2
and +25.0; the Navy A-4 is over North Vietnam at +24.0; the F-4 is over Laos at
+25.4; and the B-52 is over Cambodia at +14.3."

### Tanishk - Problem 5 and closing (about 2 minutes)

Problem 5:
"Problem 5 explains the size of the formation. The Spearman correlation between
weapons and load is 0.648; aircraft per record correlates 0.288 with the load
and 0.173 with weapons. The simple regression has an R squared of only 0.063, so
we fit a multiple regression with type, country, period, year and source on
18,811 records: R squared 0.166, F = 267.2. A B-52 record carries about 1.56
times the aircraft of an equivalent F-4 record, night records are 36.9% smaller,
and formations shrink about 7% per year. The diagnostics pass - the largest
Cook's distance is 0.0089, and the VIF of year is 3.76. For the profile F-4,
North Vietnam, night, 1972, SEADAB the model predicts 1.55 aircraft with a 95%
prediction interval of 0.51 to 4.69, and the 32 real records with that profile
average 1.75 - inside the interval."

Closing:
"To conclude: the campaign peaks in 1970 and is concentrated in South Vietnam
and Laos; the load is lognormal in shape but is a mixture of aircraft types; day
deliveries are about 39% heavier than night; the aircraft mix depends strongly
on the country; and formation size is explained about 17% by the recorded
factors. The common thread is skewness - medians and log scales tell the honest
story. Our main limitations are that records are delivery events, not
independent missions, and the load exists only in SEADAB. Everything is
reproducible: seed 2026, one script per problem, and every number in the report
comes from `outputs/`. Thank you."

---

## 6. Questions - who answers what

| Topic | First answer | Backup |
|---|---|---|
| Dataset, sample, cleaning rules | Om | Tanishk |
| Descriptive results, medians vs means | Om | Siddhant |
| Normal vs lognormal, chi-square fit, CLT | Siddhant | Om |
| t-test, Welch, log transformation, Mann-Whitney | Parth | Siddhant |
| Chi-square independence, Cramer's V, residuals | Parth | Tanishk |
| Regression, R squared, VIF, prediction interval | Tanishk | Parth |
| Report format, division of work | Om | all |

Short answers to the most likely questions:

- **Why a sample and not the full file?** 23.46 lakh delivery records; a 20,000
  random sample keeps every run fast and is far above the minimum of 500, while
  losing no precision that matters for these tests.
- **Why seed 2026?** So the sample - and every number in the report - is
  reproducible exactly.
- **Why log10(load)?** The load is right-skewed (skewness 4.55). Logs make the
  groups nearly symmetric and turn a difference of means into a ratio of
  geometric means.
- **Why Welch?** Variances differ (Levene F = 143.1); Welch does not assume
  equal variances.
- **Why is the lognormal rejected if it fits well?** With n = 5,894 the
  chi-square detects the mixture of aircraft types; the probabilities are still
  accurate to about 5 percentage points.
- **What is Cramer's V?** A 0-1 measure of association for contingency tables;
  0.278 is moderate.
- **Why exclude Thailand?** Two expected cell counts were below 5, which breaks
  the chi-square approximation.
- **What does R squared = 0.166 mean?** The five recorded factors explain 16.6%
  of the variation in log aircraft; the rest is unrecorded (target importance,
  availability, weather).
- **Does non-normal residual stop the regression?** No - with 18,811 records the
  coefficients are reliable by the CLT; the right tail is a few giant
  formations, and Cook's distance shows no influential record.
- **What if records are not independent?** The p-values are optimistic; we say
  so and rely on effect sizes and confidence intervals.

---

## 7. Back-up if RStudio misbehaves

- Show `outputs/problem1.txt` ... `problem5.txt` - they are the exact console
  logs, committed to the repository.
- Show `figures/*.png` and `report/report.pdf`.
- Last resort from a terminal in the project folder:
  `Rscript scripts/problem1.R` (same result, 4 seconds).
- If the console says `cannot open file 'clean_data.csv'`, the working
  directory is wrong: open `SDAUR.Rproj` or Session > Set Working Directory >
  Project Directory.
