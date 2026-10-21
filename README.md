# SDAUR FA-2 Project: Statistical Analysis of THOR Vietnam Bombing Operations Data

FA-2 activity for BSH23OE04 (Open Elective: Statistical Data Analysis using R),
Pimpri Chinchwad College of Engineering. The project explores the THOR Vietnam
War bombing operations dataset with R: cleaning, sampling, descriptive analysis,
probability models, hypothesis tests, correlation and regression, and produces a
full report (report/report.docx and report/report.pdf).

## Requirements

- R 4.6.x (tested 4.6.1) with packages: readr, ggplot2 (both standard CRAN).
  All other statistics (Levene, skewness, kurtosis, VIF) are implemented in base
  R in scripts/common_setup.R, so no further packages are needed.
- Python 3.10+ for the report: python-docx, docx2pdf, pymupdf (only needed to
  rebuild the .docx/.pdf; the R analysis itself does not depend on Python).
- Microsoft Word (used by docx2pdf to convert docx to pdf on Windows).

## Data

- dataset/THOR_Vietnam_Bombing_Operations.csv -- 46,70,416 records x 47 columns,
  June 1965 - June 1975 (THOR project / Combat Archives). **Not tracked in this
  repository** (1.5 GB, above GitHub's file limit; see .gitignore) -- download it
  from the THOR project and place it at that path to rerun the pipeline from raw
  data. `clean_data.csv` (the 20,000-record analysis file) is tracked, so the five
  problem scripts run without the raw file.
- dataset/THOR_Vietnam_Weapons_Glossary.csv -- weapons glossary used for the
  weapon-class join.
- dataset/THOR_Vietnam_Aircraft_Glossary.csv and dataset/thor_data_dictionary_2016.pdf
  -- reference material.

## Running the project

Windows PowerShell, from the project root:

```powershell
# optional but safe on Windows: strip UTF-8 BOMs that editors may add
Get-ChildItem "scripts\*.R" | ForEach-Object {
  $c = [System.IO.File]::ReadAllText($_.FullName)
  [System.IO.File]::WriteAllText($_.FullName, $c, (New-Object System.Text.UTF8Encoding($false)))
}

Rscript scripts/00_profile_raw.R     # full-file profile (about 3 minutes)
Rscript scripts/00b_diagnose_raw.R   # level tables of key raw columns
Rscript scripts/00c_check_relations.R# glossary relation checks
Rscript scripts/01_clean.R           # builds clean_data.csv + data-quality log
Rscript scripts/problem1.R           # descriptive analysis          (Unit I)
Rscript scripts/problem2.R           # normal/lognormal + CLT        (Unit II)
Rscript scripts/problem3.R           # day vs night t-test           (Unit III)
Rscript scripts/problem4.R           # chi-square independence       (Unit III)
Rscript scripts/problem5.R           # correlation + regression      (Unit IV)

# rebuild the report (optional)
python report/build_report.py        # -> report/report.docx
python report/convert_preview.py     # -> report/report.pdf + page previews
```

The sample is drawn with set.seed(2026), so clean_data.csv and every output are
reproduced exactly on each run.

## Demo in RStudio (for the oral)

1. Open `SDAUR.Rproj` (double-click, or File > Open Project). RStudio sets the
   working directory to the project root; check with `getwd()`.
2. First time on a new machine only: `install.packages(c("readr", "ggplot2"))`.
3. Open a script in `scripts/` and press **Source** (Ctrl+Shift+S), or run it
   line by line with Ctrl+Enter. Every script sources `scripts/common_setup.R`,
   loads `clean_data.csv`, prints its results, and writes its log to `outputs/`
   and its figures to `figures/`.
4. Suggested live demo (each script takes 2-5 seconds):
   `problem1.R` (descriptive statistics + 5 figures), `problem3.R` (Welch
   t-test + boxplots), `problem5.R` (correlation + regression diagnostics).
5. Full pipeline from the raw file: `01_clean.R` (reads the 1.5 GB file in
   chunks, takes a few minutes) and then `problem1.R` to `problem5.R`.

All five problem scripts were re-run after the final edit and reproduce the
committed outputs and figures byte for byte.

## File map

```
clean_data.csv                the 20,000-record analysis file (47 raw + 17 derived columns)
scripts/00_profile_raw.R      missingness + level counts on the full 1.5 GB file (chunked)
scripts/00b_diagnose_raw.R    focused diagnostics of the raw-level problems
scripts/00c_check_relations.R glossary join checks (WEAPONTYPE -> class, weight relations)
scripts/01_clean.R            population definition, random sample, cleaning, derivations
scripts/common_setup.R        shared loader, black-and-white ggplot2 theme, base-R helpers
scripts/problem1..5.R         one script per problem statement (analysis + figures + log)
outputs/00_raw_profile.txt    full-file profile used for the report's data table
outputs/00b_raw_diagnosis.txt, outputs/00c_relations.txt
outputs/01_data_quality.txt   cleaning counts and sample missingness
outputs/problem1..5.txt       complete console logs of each analysis (numbers used in report)
figures/fig1_*..fig5_*.png    19 figures, grayscale, referenced in the report
report/build_report.py        builds report.docx with python-docx from outputs/figures
report/convert_preview.py     docx -> pdf (Word) and renders page previews (pymupdf)
report/report.docx, report.pdf  the final report
ASSUMPTIONS.md                every assumption taken, with reasons and impact
ORAL_PREP.md                  viva questions with short answers
```

## Problem statements covered

1. Descriptive analysis of the weapon-delivery activity (Unit I).
2. Probability model for the weapon load: normal vs lognormal, goodness of fit,
   model probabilities, central limit theorem simulation (Unit II).
3. Day vs night weapon load: two-sample Welch t-test on logs with assumption
   checks and Mann-Whitney cross-check (Unit III).
4. Aircraft type vs target country: chi-square test of independence, Cramer's V,
   standardised residuals (Unit III).
5. Correlation analysis and multiple regression for the number of aircraft per
   record, with diagnostics, prediction and validation (Unit IV).

## Notes on integrity

- Records are delivery events, not independent missions; p-values are declared
  optimistic throughout, and conclusions rest on effect sizes where possible.
- The weapon load is recorded only in the SEADAB source; every load-based result
  says so.
- No result in the report was typed into the report by hand: every number is
  produced by the scripts and copied from outputs/*.txt, which are regenerated by
  rerunning the pipeline.
