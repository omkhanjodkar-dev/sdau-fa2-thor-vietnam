# -*- coding: utf-8 -*-
"""
build_report.py -- builds report/report.docx for the FA-2 project
"Statistical Data Analysis using R" (THOR Vietnam bombing operations data).

Every number in this report is taken from the R outputs in outputs/*.txt
and the figures in figures/*.png produced by scripts/01_clean.R and
scripts/problem1.R ... problem5.R.
"""

import os
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIG = os.path.join(ROOT, "figures")
OUT = os.path.join(ROOT, "report")

doc = Document()

# ---------------------------------------------------------------- page setup
for sec in doc.sections:
    sec.page_width = Cm(21.0)
    sec.page_height = Cm(29.7)
    sec.top_margin = Cm(2.0)
    sec.bottom_margin = Cm(2.0)
    sec.left_margin = Cm(2.0)
    sec.right_margin = Cm(2.0)

# base style
st = doc.styles["Normal"]
st.font.name = "Times New Roman"
st.font.size = Pt(12)
st.font.color.rgb = RGBColor(0, 0, 0)
st.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
rpr = st.element.get_or_add_rPr()
rf = rpr.find(qn("w:rFonts"))
if rf is None:
    rf = OxmlElement("w:rFonts")
    rpr.append(rf)
for a in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
    rf.set(qn(a), "Times New Roman")


def P(text="", size=12, bold=False, italic=False, align="justify",
      before=0, after=6, indent=None, hanging=False, spacing=None):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    if spacing:
        pf.line_spacing = spacing
    if align == "justify":
        pf.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    elif align == "center":
        pf.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif align == "right":
        pf.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    if indent is not None:
        pf.left_indent = Cm(indent)
        if hanging:
            pf.first_line_indent = Cm(-0.55)
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(size)
    r.bold = bold
    r.italic = italic
    r.font.color.rgb = RGBColor(0, 0, 0)
    return p


def H(text, size=13.5, before=14, after=6):
    return P(text, size=size, bold=True, align="left", before=before, after=after)


def SH(text, size=12):
    return P(text, size=size, bold=True, align="left", before=8, after=4)


def bullet(text, size=12):
    return P("\u2022  " + text, size=size, align="justify", indent=0.75,
             hanging=True, after=3)


def step(n, text):
    return P(f"{n}. {text}", align="justify", indent=0.75, hanging=True, after=3)


def shade(cell, fill="D9D9D9"):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tcPr.append(shd)


def set_cell(cell, text, bold=False, size=10, align="left"):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(1)
    if align == "center":
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif align == "right":
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = p.add_run(str(text))
    r.font.name = "Times New Roman"
    r.font.size = Pt(size)
    r.bold = bold
    r.font.color.rgb = RGBColor(0, 0, 0)


def table(headers, rows, widths, size=10, center_cols=()):
    t = doc.add_table(rows=1, cols=len(headers))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    for j, (h, w) in enumerate(zip(headers, widths)):
        c = t.rows[0].cells[j]
        set_cell(c, h, bold=True, size=size, align="center")
        shade(c)
        c.width = Cm(w)
    for row in rows:
        cells = t.add_row().cells
        for j, v in enumerate(row):
            set_cell(cells[j], v, size=size,
                     align="center" if j in center_cols else "left")
            cells[j].width = Cm(widths[j])
    return t


def fig(name, caption, width=13.5):
    path = os.path.join(FIG, name)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(2)
    p.add_run().add_picture(path, width=Cm(width))
    cp = P(caption, size=10.5, italic=True, align="center", after=10)
    return cp


# ============================================================== cover page
P("PIMPRI CHINCHWAD EDUCATION TRUST'S", size=15, bold=True, align="center", before=40, after=2)
P("PIMPRI CHINCHWAD COLLEGE OF ENGINEERING", size=17, bold=True, align="center", after=2)
P("Department of Applied Science and Humanities (AS&H)", size=13, align="center", after=18)
P("Report of FA-2 activity", size=15, bold=True, align="center", after=18)
P("Subject: BSH23OE04: Open Elective: Statistical Data Analysis using R",
  size=13, bold=True, align="center", after=4)
P("Academic Year 2026-27", size=13, align="center", after=2)
P("Semester I", size=13, align="center", after=24)

P("Submitted by", size=12, bold=True, align="left", after=4)
table(["Sr. No.", "Name of the student", "PRN number", "Branch"],
      [["1.", "", "", ""], ["2.", "", "", ""], ["3.", "", "", ""]],
      [1.6, 7.0, 4.2, 4.2], size=11, center_cols=(0,))

P("", after=10)
P("Submitted to: Dr. Rajesh G Talekar", size=12, bold=True, align="left", after=30)
P("Date: ______________                    Sign: ______________", size=12, align="left", after=30)
doc.add_page_break()

# ============================================================== 1. title/data
H("Project Title", after=4)
P("Statistical Analysis of the Vietnam War Bombing Operations Data using R", bold=True, after=10)

H("Data used", after=4)
P("THOR Vietnam War bombing operations database (Combat Archives, THOR project). "
  "File: THOR_Vietnam_Bombing_Operations.csv. The file is public research data on "
  "weapon-delivery records of the air campaign in South-East Asia.", after=8)

H("Details of the data", after=4)
P("The file contains 46,70,416 records (rows) and 47 columns covering mission dates "
  "from 1 June 1965 to 30 June 1975. One row is one weapon delivery event as reported "
  "by one source database (SEADAB, CACTA6669, CACTA6570 or SACCOACT); the column "
  "SOURCERECORD identifies the source. The columns are listed below together with the "
  "share of values missing in the full file (computed by a complete scan of the file, "
  "script scripts/00_profile_raw.R).", after=6)

cols = [
    ("1", "THOR_DATA_VIET_ID", "Number", "Unique record identifier in the THOR Vietnam database; checked to be unique (46,70,416 distinct values).", "0%"),
    ("2", "COUNTRYFLYINGMISSION", "Category", "Country whose air force flew the mission (USA, South Vietnam, Laos, South Korea, Australia).", "0.08%"),
    ("3", "MILSERVICE", "Category", "Military service of the flying unit: USAF, USN, VNAF, USMC, RLAF, KAF, RAAF, OTHER, USA.", "0.07%"),
    ("4", "MSNDATE", "Date", "Mission date; stored as text in two formats (DD-MMM-YY and YYYYMMDD), parsed in cleaning.", "0%"),
    ("5", "SOURCEID", "Category", "Identifier of the source document the record came from.", "0%"),
    ("6", "SOURCERECORD", "Category", "Source database of the record: SEADAB, CACTA6669, CACTA6570, SACCOACT.", "0%"),
    ("7", "VALID_AIRCRAFT_ROOT", "Category", "Validated aircraft type code (F-4, F-100, A-4, B-52, ...), 129 levels.", "0%"),
    ("8", "TAKEOFFLOCATION", "Category", "Air base, carrier or other location the aircraft took off from.", "0.11%"),
    ("9", "TGTLATDD_DDD_WGS84", "Number", "Target latitude, decimal degrees, WGS84.", "24.20%"),
    ("10", "TGTLONDDD_DDD_WGS84", "Number", "Target longitude, decimal degrees, WGS84.", "24.20%"),
    ("11", "TGTTYPE", "Category", "Text description of the target type (AREA\\DEPOT, BUILDINGS, TRUCKS, ...), 268 levels.", "39.19%"),
    ("12", "NUMWEAPONSDELIVERED", "Number", "Number of weapons delivered on the target in the record.", "0%"),
    ("13", "TIMEONTARGET", "Number", "Time over target, encoded as HHMM.", "0.57%"),
    ("14", "WEAPONTYPE", "Category", "Weapon type designation (e.g. MK-82, 750LB GP).", "51.46%"),
    ("15", "WEAPONTYPECLASS", "Category", "Weapon class in the source file: completely empty in this file.", "100%"),
    ("16", "WEAPONTYPEWEIGHT", "Number", "Weight of one weapon of this type, pounds.", "0%"),
    ("17", "AIRCRAFT_ORIGINAL", "Category", "Aircraft type as written in the source document.", "0.01%"),
    ("18", "AIRCRAFT_ROOT", "Category", "Aircraft type code without model suffix (F4, F100, A4, B52, ...).", "0.01%"),
    ("19", "AIRFORCEGROUP", "Category", "Air force group code; almost completely missing, not used.", "99.94%"),
    ("20", "AIRFORCESQDN", "Category", "Squadron; almost completely missing, not used.", "99.94%"),
    ("21", "CALLSIGN", "Category", "Mission callsign.", "70.66%"),
    ("22", "FLTHOURS", "Number", "Flight hours logged for the record.", "0%"),
    ("23", "MFUNC", "Category", "Mission function code.", "2.16%"),
    ("24", "MFUNC_DESC", "Category", "Mission function description (STRIKE, CLOSE AIR SUPPORT, ...), 95 levels.", "2.24%"),
    ("25", "MISSIONID", "Category", "Mission identifier.", "0.34%"),
    ("26", "NUMOFACFT", "Number", "Number of aircraft taking part in the record.", "0%"),
    ("27", "OPERATIONSUPPORTED", "Category", "Name of the operation supported; text is very inconsistent (51,375 levels).", "41.11%"),
    ("28", "PERIODOFDAY", "Category", "Period of day of the attack: D (day) or N (night); other codes are data-entry noise.", "4.28%"),
    ("29", "UNIT", "Category", "Flying unit name.", "0.01%"),
    ("30", "TGTCLOUDCOVER", "Category", "Cloud cover at the target: CLEAR, SCATTERED, BROKEN, OVERCAST, UNDERCAST, NOT OBS, IN CLOUDS, BETWEEN LAYERS.", "52.25%"),
    ("31", "TGTCONTROL", "Category", "How the target was controlled/acquired (ABN FWD AIR CNTL, TPQ-10, ...).", "46.05%"),
    ("32", "TGTCOUNTRY", "Category", "Country of the target: South Vietnam, Laos, North Vietnam, Cambodia, Thailand, Westpac Waters, UNKNOWN, PHILLIPINES (typo in source).", "4.64%"),
    ("33", "TGTID", "Category", "Target identifier; almost completely missing, not used.", "100%"),
    ("34", "TGTORIGCOORDS", "Category", "Target coordinates as recorded originally.", "22.87%"),
    ("35", "TGTORIGCOORDSFORMAT", "Category", "Format of the original coordinates (7 levels).", "23.40%"),
    ("36", "TGTWEATHER", "Category", "Coded weather at the target; free-text style coding, 16,235 levels.", "55.51%"),
    ("37", "ADDITIONALINFO", "Category", "Additional free-text information about the record.", "0%"),
    ("38", "GEOZONE", "Category", "Target geozone code (84 levels).", "25.01%"),
    ("39", "ID", "Number", "Internal record id.", "0%"),
    ("40", "MFUNC_DESC_CLASS", "Category", "Mission function class: KINETIC or NONKINETIC.", "0%"),
    ("41", "NUMWEAPONSJETTISONED", "Number", "Number of weapons jettisoned; -1 is a missing code.", "0%"),
    ("42", "NUMWEAPONSRETURNED", "Number", "Number of weapons returned to base; -1 is a missing code.", "0%"),
    ("43", "RELEASEALTITUDE", "Number", "Release altitude; almost completely missing.", "99.93%"),
    ("44", "RELEASEFLTSPEED", "Number", "Release flight speed; almost completely missing.", "99.96%"),
    ("45", "RESULTSBDA", "Category", "Bomb damage assessment text; almost completely missing.", "93.89%"),
    ("46", "TIMEOFFTARGET", "Number", "Time off target, encoded as HHMM.", "0.57%"),
    ("47", "WEAPONSLOADEDWEIGHT", "Number", "Total weight of weapons loaded, pounds; -1 is a missing code; only filled in the SEADAB source.", "0%"),
]
table(["No.", "Column", "Type", "Description", "Missing"],
      [[a, b, c, d, e] for a, b, c, d, e in cols],
      [0.9, 4.3, 1.7, 8.4, 1.6], size=9, center_cols=(0, 2, 4))

P("Table 1: Columns of the raw data file with the share of missing values in the full file.",
  size=10.5, italic=True, align="center", after=10)

doc.add_page_break()

# ============================================================== preparation
H("Data preparation and sampling", before=0, after=4)
P("The 47-column file mixes four source databases and contains records that did not "
  "deliver any weapon (for example jettison or return only sorties). The following "
  "steps were applied (script scripts/01_clean.R):", after=4)
bullet("Step 1 - Population. The full file was scanned and the 23,46,224 records with "
       "NUMWEAPONSDELIVERED > 0 (50.24% of the file) were kept. These are the records "
       "in which a weapon was actually delivered, which is the subject of the study.")
bullet("Step 2 - Sampling. A simple random sample without replacement of 20,000 records "
       "was drawn from those 23,46,224 records (set.seed(2026)). Working on a random "
       "sample keeps every run of the scripts fast while the sample is still large "
       "enough for every test in this report.")
bullet("Step 3 - Cleaning and derivation. The sample was cleaned and the analysis "
       "variables were derived; the result is clean_data.csv (20,000 records, 47 raw "
       "plus 17 derived columns) and a data-quality log (outputs/01_data_quality.txt).")

SH("Cleaning rules applied to the sample")
bullet("Mission dates: the 272 records stored in YYYYMMDD format were converted; all "
       "20,000 dates parsed. The sample covers 1 October 1965 to 3 June 1975.")
bullet("NUMWEAPONSDELIVERED = 9999 (sentinel value): 2 records set to missing.")
bullet("WEAPONSLOADEDWEIGHT = -1 (missing code): 12,394 records set to missing; "
       "WEAPONSLOADEDWEIGHT = 0 (records that delivered non-ordnance such as flares or "
       "leaflets, so a weapon load does not apply): 1,600 records set to missing; "
       "values above 1,000,000 lb (implausible, transport aircraft row): 112 records "
       "set to missing.")
bullet("NUMOFACFT = 0 (impossible for a delivery record): 13 records set to missing.")
bullet("TIMEONTARGET: 8 records with impossible HHMM values set to missing; the valid "
       "values were converted to the hour of the day (TGT_HOUR).")
bullet("Coordinates outside the study box 0-30N, 90-130E: 2,456 records set to missing.")
bullet("TGTCLOUDCOVER 'NOT OBS' treated as missing (396 records); the rare categories "
       "'IN CLOUDS' and 'BETWEEN LAYERS' grouped with 'Other'.")
bullet("TGTCOUNTRY 'PHILLIPINES' corrected to PHILIPPINES; 'WESTPAC WATERS' and "
       "'UNKNOWN' grouped as 'Other'; MILSERVICE values OTHER and USA (118 records) "
       "grouped as 'Other'.")
bullet("Aircraft types were grouped into the six most used types (F-4, F-100, A-4, A-1, "
       "A-37, B-52) plus 'Other'; the weapon type was joined with the weapons glossary "
       "file to obtain WEAPON_CLASS (BOMB, ROCKET, GUN, MISSILE, SUPPORT); every weapon "
       "string matched the glossary.")
bullet("Derived variables: YEAR, MONTH from the mission date; PERIOD (Day/Night); "
       "COUNTRY, SERVICE, SOURCE_DB, AIRCRAFT_GROUP, CLOUD, WEAPON_CLASS as factors; "
       "WEAPONS_DELIVERED, LOAD_LB, AIRCRAFT_NO, TGT_HOUR, LAT, LON, FLIGHT_HOURS "
       "as numbers.")

SH("Missing values of the analysis variables in the 20,000-record sample")
table(["Variable", "Missing", "Share", "Variable", "Missing", "Share"],
      [["PERIOD", "834", "4.17%", "LOAD_LB", "14,106", "70.53%"],
       ["COUNTRY", "349", "1.75%", "AIRCRAFT_NO", "13", "0.06%"],
       ["AIRCRAFT_GROUP", "1", "0.00%", "TGT_HOUR", "8", "0.04%"],
       ["CLOUD", "10,729", "53.65%", "LAT / LON", "2,456", "12.28%"],
       ["WEAPON_CLASS", "4,250", "21.25%", "WEAPONS_DELIVERED", "2", "0.01%"],
       ["SERVICE / SOURCE_DB", "0", "0.00%", "FLIGHT_HOURS", "0", "0.00%"]],
      [4.3, 2.0, 2.1, 4.3, 2.0, 2.1], size=10, center_cols=(1, 2, 4, 5))
P("Table 2: Missing values of the analysis variables after cleaning.",
  size=10.5, italic=True, align="center", after=8)

P("The weapon load (LOAD_LB) is recorded only in the SEADAB source, which is why 70.5% "
  "of the sample has no load; every problem that uses the load states this and analyses "
  "only the records where it is known. The cloud cover is missing for more than half of "
  "the records because ground reports often did not observe it.", after=8)

SH("Limitations of the data (stated once, valid for every problem)")
bullet("One record is one delivery event as reported by one source, not one mission. "
       "A single mission can produce several records, so records are not fully "
       "independent. The p-values in the tests are therefore slightly optimistic; the "
       "effect sizes are quoted for this reason.")
bullet("The four source databases overlap in time and purpose; the database merges "
       "them without deduplication flags, so double counting of unusual events cannot "
       "be fully excluded.")
bullet("Weapons loaded weight is recorded only in SEADAB; results about the load apply "
       "to that source only.")
bullet("The source data are historical reports of the war; recorded numbers "
       "(weapons, aircraft) are the numbers reported at the time.")

# ============================================================== unit mapping
H("Mapping of the course units to the problem statements", after=4)
table(["Unit", "Topics in the syllabus", "Covered by"],
      [["Unit I", "Data handling in R, descriptive statistics, data visualization",
        "Problem statement 1"],
       ["Unit II", "Probability, random variables, standard distributions, "
        "central limit theorem", "Problem statement 2"],
       ["Unit III", "Sampling, estimation, hypothesis testing (t-test, chi-square "
        "test), testing of means and proportions", "Problem statements 3 and 4"],
       ["Unit IV", "Correlation, simple and multiple linear regression, prediction",
        "Problem statement 5"]],
      [1.8, 10.4, 4.7], size=11, center_cols=(0,))
P("Table 3: Coverage of the four units of the syllabus by the five problem statements.",
  size=10.5, italic=True, align="center", after=8)

doc.add_page_break()

# ============================================================== PROBLEM 1
H("Problem statement 1 (Unit I): Descriptive analysis of the weapon-delivery records",
  size=14, before=0)

SH("Problem statement")
P("Describe how the weapon-delivery activity recorded in the data is distributed over "
  "time, target countries, aircraft types and weapon classes, and summarize the number "
  "of weapons delivered and the number of aircraft used per record with suitable "
  "descriptive statistics and graphs.", after=6)

SH("Introduction (purpose and approach)")
P("The purpose is to build the first overall picture of the air campaign as recorded in "
  "the data: when it happened, where it happened, who flew it and what was delivered. "
  "The approach is classical descriptive statistics: frequency tables for the "
  "categorical variables, summary statistics (mean, median, quartiles, standard "
  "deviation, skewness, kurtosis) for the numerical variables and one graph per "
  "question, all produced with R and ggplot2.", after=6)

SH("Approach / algorithm with explanation")
step(1, "Load clean_data.csv (source scripts/common_setup.R).")
step(2, "Frequency tables of records by year, month, target country, aircraft group, "
        "period of day, source database and weapon class.")
step(3, "Summary statistics of WEAPONS_DELIVERED, AIRCRAFT_NO, LOAD_LB, TGT_HOUR, LAT "
        "and LON, including the median, quartiles, interquartile range, skewness and "
        "kurtosis, because the distributions are strongly skewed.")
step(4, "Graphs: bar chart of records per year; monthly time series by target country; "
        "histogram of weapons delivered; boxplots of weapons delivered by country; map "
        "of the target coordinates.")
step(5, "Read each number with attention to the heavy skew (comparison of mean and "
        "median).")

SH("Output with description")
P("Frequency tables (from outputs/problem1.txt):", after=2)
table(["Year", "1965", "1966", "1967", "1968", "1969", "1970", "1971", "1972", "1973", "1974", "1975"],
      [["Records", "300", "1,954", "2,337", "3,352", "2,470", "3,532", "2,161", "2,642", "910", "256", "86"]],
      [1.9, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35], size=9.5,
      center_cols=tuple(range(1, 12)))
P("Table 4: Number of weapon-delivery records per year in the sample.",
  size=10.5, italic=True, align="center", after=6)

table(["Category", "Records", "Share", "Category", "Records", "Share"],
      [["South Vietnam", "10,510", "53.5%", "F-4 Phantom", "4,827", "24.1%"],
       ["North Vietnam", "2,363", "12.0%", "F-100 Super Sabre", "2,877", "14.4%"],
       ["Laos", "5,736", "29.2%", "A-4 Skyhawk", "1,841", "9.2%"],
       ["Cambodia", "960", "4.9%", "A-1 Skyraider", "2,067", "10.3%"],
       ["Thailand", "82", "0.4%", "A-37 Dragonfly", "1,515", "7.6%"],
       ["Day records", "13,786", "68.8%", "B-52 Stratofortress", "836", "4.2%"],
       ["Night records", "5,380", "26.8%", "Other types", "6,036", "30.2%"],
       ["BOMB class", "12,362", "61.8%", "SEADAB source", "7,606", "38.0%"],
       ["GUN class", "535", "2.7%", "CACTA6669 source", "9,944", "49.7%"]],
      [3.6, 1.9, 1.5, 4.0, 1.9, 1.5], size=10, center_cols=(1, 2, 4, 5))
P("Table 5: Headline frequencies of the sample (shares are of the 20,000 records; "
  "weapon classes exclude the 4,250 records without a usable weapon type).",
  size=10.5, italic=True, align="center", after=6)

table(["Variable", "n", "Mean", "Median", "Std. dev.", "Q1", "Q3", "Max", "Skewness"],
      [["WEAPONS_DELIVERED", "19,998", "38.10", "8", "268.91", "4", "16", "9,040", "21.50"],
       ["AIRCRAFT_NO", "19,987", "3.06", "2", "7.53", "2", "2", "276", "11.35"],
       ["LOAD_LB (lb)", "5,894", "59,795.3", "34,260", "94,711.3", "15,930", "63,720", "8,96,480", "4.55"],
       ["TGT_HOUR (hour of day)", "19,992", "8.98", "8", "6.23", "4", "13", "23", "0.52"]],
      [4.0, 1.5, 2.0, 1.8, 2.1, 1.3, 1.3, 1.9, 1.7], size=10,
      center_cols=tuple(range(1, 9)))
P("Table 6: Summary statistics of the main numerical variables.",
  size=10.5, italic=True, align="center", after=6)

fig("fig1_1_records_by_year.png",
    "Figure 1.1: Weapon-delivery records per year. Activity builds up 1966-68, peaks in "
    "1970 (3,532 records) and nearly stops after 1972 (86 records in 1975).")
P("Inference: the war effort recorded in the data is concentrated in 1968-1971 "
  "(57.6% of all sample records); the sharp fall after 1972 matches the withdrawal of "
  "US forces and the end of large-scale bombing.", after=8)

fig("fig1_2_monthly_by_country.png",
    "Figure 1.2: Monthly number of records by target country. South Vietnam dominates "
    "throughout; Laos is present steadily; the North Vietnam series appears mainly in "
    "1972.", width=14.5)
P("Inference: the monthly profile differs by country - South Vietnam is a continuous "
  "high-volume theatre, while North Vietnam shows concentrated campaigns (1967-68 and "
  "1972), which is consistent with the historical record of the two bombing campaigns "
  "against the North.", after=8)

fig("fig1_3_weapons_hist.png",
    "Figure 1.3: Number of weapons delivered per record (records above 100 weapons are "
    "shown at the right edge).")
P("Inference: the distribution is extremely skewed: half of the records deliver 8 or "
  "fewer weapons, but 5.74% of the records deliver more than 100 (maximum 9,040). "
  "For this reason the median and the quartiles are reported next to the mean "
  "everywhere in this report.", after=8)

fig("fig1_4_weapons_by_country.png",
    "Figure 1.4: Weapons delivered per record by target country (boxplots).")
P("Inference: the typical (median) record is small in every country (8 weapons in "
  "South Vietnam, North Vietnam and Laos, 12 in Cambodia); the means are much larger "
  "than the medians in every country because of the long right tail. Comparing "
  "countries by mean would be misleading, by median they are similar.", after=8)

fig("fig1_5_target_map.png",
    "Figure 1.5: Target locations of the sampled records (longitude against latitude).",
    width=12.5)
P("Inference: the target coordinates form the expected map of the theatre: a dense "
  "band along the South Vietnamese coast and the Mekong delta, the Laos panhandle, and "
  "clusters in the North. The coordinates agree with the recorded target country, so "
  "the geographic information is internally consistent.", after=8)

SH("Conclusion")
P("The descriptive analysis shows a campaign concentrated in 1966-1972 with a clear "
  "peak in 1970; the main theatre is South Vietnam (53.5% of targets) followed by Laos "
  "(29.2%); the workhorse aircraft are the F-4 (24.1%), F-100 (14.4%) and A-1/A-4/A-37 "
  "families; bombing (BOMB class, 61.8% of records with a known class) is the dominant "
  "weapon; day records outnumber night records 13,786 to 5,380. Every numerical "
  "variable is strongly right-skewed, so medians and quartiles describe the typical "
  "record better than means.", after=10)

doc.add_page_break()

# ============================================================== PROBLEM 2
H("Problem statement 2 (Unit II): A probability model for the weapon load",
  size=14, before=0)

SH("Problem statement")
P("Find a probability distribution that describes the recorded weapon load of a "
  "delivery record. Compare the normal and the lognormal model, test the quality of "
  "the fit, use the model to compute probabilities, and check the central limit "
  "theorem for the mean load of 30 records.", after=6)

SH("Introduction (purpose and approach)")
P("The weapon load (LOAD_LB) is recorded for the 5,894 sampled records of the SEADAB "
  "source (29.5% of the sample) and is the best continuous measure of the size of a "
  "delivery in the data. A probability model for it allows statements such as 'the "
  "chance that a record delivers more than 50,000 lb' to be computed. The approach is: "
  "estimate the parameters of the candidate models by maximum likelihood, test the "
  "goodness of fit with the chi-square test on equal-probability bins, and verify the "
  "central limit theorem by simulation.", after=6)

SH("Approach / algorithm with explanation")
step(1, "Take the 5,894 records with a recorded load; summarise them (mean, median, "
        "standard deviation, skewness, kurtosis, quartiles).")
step(2, "Fit the normal model: parameters equal to the sample mean and standard "
        "deviation (maximum likelihood for the normal).")
step(3, "Fit the lognormal model: take log10(load), fit a normal distribution to the "
        "logs, report the parameters in natural log units.")
step(4, "Chi-square goodness of fit for both models: split the fitted distribution "
        "into 8 equally likely bins, count the observed records in the same bins, "
        "compute the chi-square statistic with df = 7 - 2 estimated parameters = 5.")
step(5, "Compare observed and fitted quartiles and compute model probabilities; use "
        "boxplots of the load by aircraft group to investigate the misfit.")
step(6, "Central limit theorem: draw 20,000 samples of n = 30 records, form the sample "
        "means, compare their mean, standard deviation and shape with the theoretical "
        "values, and compute the probability that the sample mean exceeds 70,000 lb "
        "by theory and by simulation.")

SH("Output with description")
table(["Quantity", "Value", "Quantity", "Value"],
      [["n (records with load)", "5,894", "Median", "34,260 lb"],
       ["Mean", "59,795.3 lb", "Q1, Q3", "15,930 / 63,720 lb"],
       ["Std. deviation", "94,711.3 lb", "Minimum, maximum", "60 / 8,96,480 lb"],
       ["Skewness", "4.554", "Kurtosis", "25.245"]],
      [4.6, 3.4, 3.8, 4.2], size=10, center_cols=(1, 3))
P("Table 7: The recorded weapon load (all 5,894 records come from the SEADAB source).",
  size=10.5, italic=True, align="center", after=6)

fig("fig2_1_load_hist.png",
    "Figure 2.1: Histogram of the recorded weapon load; the strong right skew "
    "(skewness 4.55) makes a normal model implausible for the load itself.")

P("Normal model: mean 59,795.3 lb, sd 94,703.2 lb. The chi-square statistic is 7,337.8 "
  "on 5 degrees of freedom (p < 2.2e-16), i.e. the model is rejected. The fitted normal "
  "puts 12.5% of the records in the lowest bin, but not a single record can be below "
  "the physical minimum of zero, so the lower tail is impossible.", after=8)

fig("fig2_2_log_hist.png",
    "Figure 2.2: log10 of the weapon load with the fitted normal density; on the log "
    "scale the data are close to symmetric (skewness -0.64), which is the lognormal "
    "idea.")
fig("fig2_3_log_qq.png",
    "Figure 2.3: Normal Q-Q plot of log10(load): the middle follows the line, but both "
    "tails bend away.")

P("Lognormal model: log10(load) has mean 4.4669 and sd 0.5616, i.e. meanlog = 10.2854 "
  "and sdlog = 1.2931 in natural logs. The goodness-of-fit chi-square statistic is "
  "610.2 on 5 degrees of freedom (p < 2.2e-16): the lognormal model is far better than "
  "the normal (statistic 610 vs 7,338) but is still formally rejected, because the "
  "sample is large and the observed bin counts are not smooth (727, 582, 550, 653, "
  "1,163, 1,006, 825, 388 against 736.8 expected in each bin). The middle bins contain "
  "more records and the tails fewer than the model predicts; the fitted quartiles "
  "(12,249 / 29,302 / 70,097) differ from the observed ones (15,930 / 34,260 / 63,720) "
  "in both tails.", after=6)

table(["Threshold load", "Model probability P(load > threshold)", "Observed share"],
      [["25,000 lb", "0.5489", "0.5976"],
       ["50,000 lb", "0.3397", "0.3522"],
       ["75,000 lb", "0.2337", "0.1971"],
       ["1,00,000 lb", "0.1713", "0.1318"]],
      [4.6, 7.4, 4.0], size=10, center_cols=(0, 1, 2))
P("Table 8: Probabilities from the fitted lognormal model against the observed shares. "
  "P(20,000 < load < 60,000) is 0.3264 by the model and 0.3453 observed.",
  size=10.5, italic=True, align="center", after=6)

fig("fig2_4_load_by_aircraft.png",
    "Figure 2.4: Weapon load by aircraft group on the log scale. The B-52 group "
    "(median 3,82,320 lb) is an extreme group, more than ten times the median load of "
    "the F-4 (47,790 lb) or the A-37 (21,240 lb).", width=14)
P("Inference: the load distribution is a mixture of very different aircraft groups, "
  "not one single population. A single lognormal cannot fit a mixture, which explains "
  "the formal rejection even though the lognormal is qualitatively the right family. "
  "This is a limitation of the source data (the load is only recorded for one source "
  "database) rather than a failure of the method.", after=8)

fig("fig2_5_clt_sim.png",
    "Figure 2.5: Simulated sampling distribution of the mean load of 30 records "
    "(20,000 repetitions) against the normal approximation.", width=14)
P("Central limit theorem: for n = 30 the standard error of the mean is 94,711.3 / "
  "sqrt(30) = 17,291.8 lb. The simulation gives mean 59,736.9 lb (theory 59,795.3) and "
  "standard deviation 17,169.1 lb (theory 17,291.8) - both match well. The theoretical "
  "normal probability P(sample mean > 70,000) is 0.2775 while the simulation gives "
  "0.2494; the distribution of the means is still slightly right-skewed (skewness "
  "0.822), so n = 30 is not yet large for this very heavy-tailed variable.", after=8)

SH("Conclusion")
P("The normal model is clearly wrong for the weapon load (impossible negative region, "
  "statistic 7,338). The lognormal model captures the shape well on the log scale and "
  "gives useful probabilities (for example about 34% of the records exceed 50,000 lb "
  "against 35% observed), but it is formally rejected by the chi-square test (610.2, "
  "p < 2.2e-16) because the data are a mixture of aircraft groups with very different "
  "loads. The central limit theorem was verified by simulation: the mean of 30 records "
  "has the theoretical mean and standard error, and the normal approximation for such "
  "means is adequate but not exact for this heavy-tailed variable.", after=10)

doc.add_page_break()

# ============================================================== PROBLEM 3
H("Problem statement 3 (Unit III): Day versus night weapon load (two-sample t-test)",
  size=14, before=0)

SH("Problem statement")
P("Test, at the 5% level, whether the mean weapon load of a delivery record differs "
  "between day and night missions. State the hypotheses, check the assumptions of the "
  "test, and cross-check the conclusion with a test that does not assume normality.",
  after=6)

SH("Introduction (purpose and approach)")
P("Period of day is one of the few operational factors that is recorded for almost "
  "every record (PERIOD missing for only 4.2%). If night deliveries carry "
  "systematically different loads, mission planning and the interpretation of the "
  "earlier descriptive graphs must take that into account. The two-sample t-test "
  "compares the mean load between the day and night groups; because the load is "
  "extremely skewed, the test is applied to log10(load), which turns the comparison "
  "into a comparison of geometric means. Welch's version of the test is used because "
  "it does not assume equal variances.", after=6)

SH("Approach / algorithm with explanation")
bullet("H0: the mean log10(load) is the same for day and night records; H1: the means "
       "differ (two-sided), level of significance 5%.")
step(1, "Keep the 5,891 records with both a recorded load and a recorded period.")
step(2, "Check normality of log10(load) inside each group (skewness, Shapiro-Wilk on a "
        "subsample of 2,000) and equality of variances (F test and Levene's test).")
step(3, "Carry out Welch's two-sample t-test and report the difference of means on the "
        "log scale, its 95% confidence interval and the ratio of geometric means.")
step(4, "Measure the size of the effect with Cohen's d on the log scale.")
step(5, "Cross-check with the Mann-Whitney test on the raw loads, which assumes "
        "neither normality nor equal variances.")
step(6, "Investigate the apparent contradiction between the raw means and the medians.")

SH("Output with description")
table(["Group", "n", "Mean (lb)", "sd (lb)", "Median (lb)", "Q1", "Q3", "Geometric mean (lb)"],
      [["Day", "4,196", "57,614.7", "80,064.1", "42,240", "17,600", "65,600", "32,254"],
       ["Night", "1,695", "65,258.9", "1,23,637.8", "24,900", "8,900", "63,720", "23,165"]],
      [1.8, 1.4, 2.0, 2.2, 1.8, 1.4, 1.4, 2.3], size=10,
      center_cols=tuple(range(1, 8)))
P("Table 9: Weapon load by period of day (5,891 records with both variables recorded; "
  "3 records had a load but no valid period).", size=10.5, italic=True,
  align="center", after=6)

fig("fig3_1_boxplot_period.png",
    "Figure 3.1: Weapon load (raw pounds) by period of day. The night group has a "
    "lower median but a longer upper tail.", width=12)
fig("fig3_2_qq_by_period.png",
    "Figure 3.2: Normal Q-Q plots of log10(load) by period; both groups are close to "
    "normal on the log scale but the tails deviate.", width=14)
fig("fig3_3_ecdf_period.png",
    "Figure 3.3: Empirical distribution functions of the weapon load (logarithmic "
    "axis) by period; the day curve lies to the right for most of the range.",
    width=12)

P("Assumption checks: on the log scale the day group has skewness -0.79 and the night "
  "group -0.28 (against +4.55 for the raw load), so the log transformation makes the "
  "groups nearly symmetric; the Shapiro-Wilk test still rejects strict normality "
  "(day W = 0.9583, night W = 0.9876, both p < 1e-10) as it does for almost any large "
  "sample. The variance ratio test (F = 0.605) and Levene's test (F = 143.1, p < "
  "2.2e-16) both indicate unequal variances, so Welch's version of the t-test is the "
  "correct one.", after=6)

P("Welch two-sample t-test result (on log10(load)): t = 8.069 on 2,561.6 degrees of "
  "freedom, p-value = 1.079e-15, so H0 is rejected. The mean log10(load) is 4.5086 for "
  "day and 4.3648 for night; the difference (day - night) is 0.1438 with 95% confidence "
  "interval [0.1088, 0.1787]. On the original scale this means the day geometric mean "
  "is 1.392 times the night geometric mean (39.2% higher), with interval [1.285, 1.509], "
  "i.e. between 28.5% and 50.9% higher. Cohen's d on the log scale is 0.258, a small "
  "to moderate effect.", after=6)

P("The raw group means tell the opposite story (night 65,258.9 lb against day "
  "57,614.7 lb). The reason is visible in the data: night deliveries are polarised. "
  "27.9% of night records deliver less than 10,000 lb (day: 13.8%) but 6.8% deliver "
  "more than 2,00,000 lb (day: 3.2%), so the night mean is pulled up by a small number "
  "of very heavy deliveries while the typical (median, geometric mean) night record is "
  "lighter. The median day load is 42,240 lb against 24,900 lb at night, a difference "
  "of 17,340 lb in the same direction as the t-test.", after=6)

P("Mann-Whitney cross-check: U = 4,112,513, p < 2.2e-16; the raw-load medians differ "
  "significantly in the same direction. The conclusion does not depend on the "
  "normality assumption.", after=8)

SH("Conclusion")
P("There is strong evidence (p = 1.08e-15) that day and night deliveries differ: the "
  "typical day load is about 39% heavier than the typical night load (geometric means "
  "32,254 lb against 23,165 lb; medians 42,240 lb against 24,900 lb). The effect is "
  "small to moderate (d = 0.26). The raw means disagree only because a few very heavy "
  "night deliveries (large formations) pull the night mean up - a textbook example of "
  "why skewed data should be compared on the log scale or with medians. Limitation: "
  "records of the same mission are not strictly independent, so the p-value is "
  "slightly optimistic; the effect size and the confidence interval remain the "
  "reliable quantities.", after=10)

doc.add_page_break()

# ============================================================== PROBLEM 4
H("Problem statement 4 (Unit III): Aircraft type and target country (chi-square test "
  "of independence)", size=14, before=0)

SH("Problem statement")
P("Test whether the mix of aircraft types used in a delivery record is independent of "
  "the target country. Use the chi-square test of independence, measure the strength "
  "of the association and identify which combinations of aircraft and country occur "
  "more or less often than expected.", after=6)

SH("Introduction (purpose and approach)")
P("Different aircraft have different roles (close air support, interdiction, strategic "
  "bombing); the question is whether the recorded aircraft mix actually changes from "
  "country to country, or whether the same mix is used everywhere. Both variables are "
  "categorical, so the chi-square test of independence is the appropriate test. The "
  "strength of the association is measured with Cramer's V and the individual cells "
  "are analysed with standardised residuals.", after=6)

SH("Approach / algorithm with explanation")
bullet("H0: aircraft type and target country are independent; H1: they are associated "
       "(level of significance 5%).")
step(1, "Keep the records with both variables recorded: 19,651 records. The 82 "
        "records with targets in Thailand are then excluded from the test because two "
        "expected cell counts fall below 5, which would break the chi-square "
        "approximation (Thailand is 0.4% of the sample); 19,569 records remain.")
step(2, "Build the contingency table (7 aircraft groups x 4 countries) and the row "
        "percentages.")
step(3, "Check the assumptions: each record is in exactly one cell, the minimum "
        "expected count is 40.96 (all above 5), and records are not fully independent "
        "(several records per mission - limitation stated once).")
step(4, "Chi-square test of independence; Cramer's V for the effect size.")
step(5, "Standardised residuals (observed - expected) / sqrt(expected) per cell; "
        "|residual| > 3 marks the cells that drive the association.")

SH("Output with description")
table(["Aircraft group", "South Vietnam", "North Vietnam", "Laos", "Cambodia", "Total"],
      [["F-4 Phantom", "1,743 (36.5%)", "784 (16.4%)", "2,093 (43.9%)", "149 (3.1%)", "4,769"],
       ["F-100 Super Sabre", "2,516 (90.8%)", "9 (0.3%)", "140 (5.1%)", "107 (3.9%)", "2,772"],
       ["A-4 Skyhawk", "948 (51.5%)", "542 (29.4%)", "350 (19.0%)", "1 (0.1%)", "1,841"],
       ["A-1 Skyraider", "1,060 (51.7%)", "94 (4.6%)", "836 (40.8%)", "59 (2.9%)", "2,049"],
       ["A-37 Dragonfly", "1,222 (85.4%)", "0 (0.0%)", "22 (1.5%)", "187 (13.1%)", "1,431"],
       ["B-52 Stratofortress", "409 (49.0%)", "67 (8.0%)", "231 (27.7%)", "128 (15.3%)", "835"],
       ["Other types", "2,612 (44.5%)", "867 (14.8%)", "2,064 (35.1%)", "329 (5.6%)", "5,872"],
       ["Total", "10,510", "2,363", "5,736", "960", "19,569"]],
      [3.6, 3.1, 3.1, 2.9, 2.9, 1.4], size=9.5, center_cols=(1, 2, 3, 4, 5))
P("Table 10: Contingency table of aircraft group against target country (row "
  "percentages in brackets).", size=10.5, italic=True, align="center", after=6)

fig("fig4_1_country_mix_by_aircraft.png",
    "Figure 4.1: Target country mix (row percentages) by aircraft group. Aircraft "
    "types clearly differ in where they operate.", width=14)
fig("fig4_2_residual_heatmap.png",
    "Figure 4.2: Standardised residuals of the test; darker cells deviate more from "
    "independence (positive = more records than expected).", width=14)

P("Test result: chi-square = 4,538.3 on (7-1)(4-1) = 18 degrees of freedom, p < "
  "2.2e-16, so H0 is rejected: the aircraft mix depends on the target country. "
  "Cramer's V = 0.278, a moderate association.", after=6)

P("The largest standardised residuals identify how the association works: the F-100 "
  "and the A-37 operate almost only over South Vietnam (residuals +42.2 and +25.0; "
  "90.8% and 85.4% of their records). The A-4 Skyhawk (a US Navy aircraft) is over "
  "represented over North Vietnam (+24.0; 29.4% of its records against 12.1% of the "
  "sample) and the F-4 Phantom is over represented over Laos (+25.4; 43.9%). The B-52 "
  "is over represented over Cambodia (+14.3; 15.3% of its records against 4.9%) - the "
  "well-known pattern of the secret Cambodian bombing. The F-4 is less used over South "
  "Vietnam than expected (-27.3) and the F-100 almost never over North Vietnam (-20.5). "
  "The overall conclusion is that the aircraft-country combination is a fairly strong "
  "role effect: each aircraft family has a characteristic theatre.", after=8)

SH("Conclusion")
P("Aircraft type and target country are not independent (chi-square = 4,538.3, df = "
  "18, p < 2.2e-16, Cramer's V = 0.278). Interpreting the residuals: fighter-bombers "
  "like the F-100 and A-37 fly close air support over South Vietnam, the F-4 covers "
  "Laos and the North, the carrier-based A-4 concentrates on North Vietnam, and the "
  "B-52 is heavily over represented over Cambodia. Note the limitation: records are "
  "not strictly independent (several per mission) and the Thailand cells had to be "
  "excluded to keep the chi-square approximation valid, so the p-value is optimistic; "
  "the effect size (moderate) and the residual pattern are the robust results.",
  after=10)

doc.add_page_break()

# ============================================================== PROBLEM 5
H("Problem statement 5 (Unit IV): Explaining the size of the attacking formation "
  "(correlation and multiple regression)", size=14, before=0)

SH("Problem statement")
P("Study the association between the numerical variables of the data and build a "
  "multiple linear regression model for the number of aircraft in a delivery record "
  "(log10 of AIRCRAFT_NO) as a function of aircraft type, target country, period of "
  "day, year and source database. Evaluate the model, check its assumptions and use "
  "it to predict the number of aircraft for a given mission profile.", after=6)

SH("Introduction (purpose and approach)")
P("The number of aircraft in a record measures the size of the formation that flew the "
  "delivery. The purpose is to quantify how much of the size of a formation is "
  "explained by the factors recorded in the data, which combination of factors "
  "produces the largest formations, and whether the model can be used for prediction. "
  "The analysis has two stages: correlation analysis of the numerical variables "
  "(Spearman coefficients are the reliable ones because of the skew), and a multiple "
  "linear regression of log10(AIRCRAFT_NO) on the five categorical/numerical factors, "
  "with full diagnostics.", after=6)

SH("Approach / algorithm with explanation")
step(1, "Pearson and Spearman correlations between AIRCRAFT_NO, WEAPONS_DELIVERED, "
        "LOAD_LB, TGT_HOUR, LAT and LON on pairwise complete observations.")
step(2, "As a baseline, a simple linear regression of log10(AIRCRAFT_NO) on "
        "log10(WEAPONS_DELIVERED).")
step(3, "Multiple regression log10(AIRCRAFT_NO) ~ AIRCRAFT_GROUP + COUNTRY + PERIOD + "
        "YEAR + SOURCE_DB on the 18,811 records with all variables recorded "
        "(reference categories: F-4 Phantom, South Vietnam, Day, SEADAB).")
step(4, "Report the coefficient table with 95% confidence intervals, R squared, the "
        "overall F test and interpret the largest coefficients as percentage changes "
        "(factor 10^b).")
step(5, "Diagnostics: residual plots, Shapiro-Wilk and moments of the residuals, "
        "Cook's distance for influential observations, and the variance inflation of "
        "YEAR against all other predictors.")
step(6, "Prediction example with a 95% prediction interval and comparison with the "
        "observed records of the same profile.")

SH("Output with description")
P("Correlation analysis (Spearman coefficients, all p < 2.2e-16 unless stated): the "
  "strongest association is between weapons delivered and weapon load (rho = 0.648); "
  "aircraft per record correlate with the load (0.288) and with weapons delivered "
  "(0.173); the hour at target has a weak negative association with aircraft "
  "(-0.217); latitude and longitude are negatively correlated (-0.280) simply because "
  "the theatre runs from north-west to south-east. The Pearson coefficients are much "
  "smaller for the heavy-tailed pairs (for example 0.247 against 0.173 for aircraft "
  "and weapons), confirming that the skew distorts the linear correlation.", after=6)

fig("fig5_1_scatter_weapons_aircraft.png",
    "Figure 5.1: log10(weapons delivered) against log10(aircraft per record); the "
    "dashed line is the least squares fit of the simple regression, R squared = 0.063.")
fig("fig5_2_correlation_matrix.png",
    "Figure 5.2: Spearman correlation matrix of the numerical variables.", width=13)

table(["Model", "R squared", "Adjusted R sq.", "F / p", "Residual std. error", "AIC"],
      [["Simple: aircraft on weapons", "0.0634", "0.0633", "1,273 / < 2.2e-16", "0.2594", "2,623.8"],
       ["Multiple: all five factors", "0.1660", "0.1654", "267.2 / < 2.2e-16", "0.2449", "467.1"]],
      [5.0, 1.7, 2.2, 3.4, 2.6, 1.5], size=10, center_cols=(1, 2, 3, 4, 5))
P("Table 11: Comparison of the simple and the multiple regression (n = 18,811).",
  size=10.5, italic=True, align="center", after=6)

P("Multiple regression result: R squared = 0.166 (adjusted 0.1654), so the five "
  "factors together explain about 17% of the variation of log10(aircraft) between "
  "records; the overall F test is 267.2 on (14, 18,796) degrees of freedom, p < "
  "2.2e-16. The largest effects on the size of a formation, holding the other factors "
  "constant:", after=4)

table(["Predictor (against reference)", "Estimate (log10)", "Effect on aircraft", "95% CI (log10)"],
      [["B-52 Stratofortress (vs F-4)", "+0.193", "+55.9% (x1.56)", "[0.164, 0.221]"],
       ["Period: Night (vs Day)", "-0.200", "-36.9%", "[-0.208, -0.192]"],
       ["Source CACTA6669 (vs SEADAB)", "-0.189", "-35.3%", "[-0.203, -0.175]"],
       ["Source CACTA6570 (vs SEADAB)", "-0.103", "-21.1%", "[-0.117, -0.089]"],
       ["Country: Cambodia (vs South Vietnam)", "-0.087", "-18.1%", "[-0.105, -0.070]"],
       ["A-37 Dragonfly (vs F-4)", "-0.074", "-15.6%", "[-0.089, -0.058]"],
       ["Year (per year)", "-0.033", "-7.3% per year", "[-0.036, -0.030]"]],
      [5.4, 2.8, 3.3, 3.4], size=10, center_cols=(1, 2, 3))
P("Table 12: Largest coefficients of the multiple regression (all p < 0.001). The "
  "Thailand coefficient (+0.379, +139%) is significant but rests on only 82 records, "
  "so it is not interpreted. F-100 and 'Other' are not significantly different from "
  "the F-4 at the 5% level once the other factors are held constant; the A-1 and A-4 "
  "coefficients are small but significant (-6.1% and -5.2%).",
  size=10.5, italic=True, align="center", after=6)

P("Interpretation: B-52 records involve about 1.56 times as many aircraft as the "
  "equivalent F-4 records - the classic multi-aircraft cell formations. Night records "
  "are about 37% smaller than day records of the same type and country, and the two "
  "smaller source databases (CACTA) record formations about 35% and 21% smaller than "
  "SEADAB, which is consistent with them recording different kinds of missions. "
  "Formations shrink by about 7% per war year, and attacks recorded over Cambodia are "
  "about 18% smaller than over South Vietnam.", after=6)

fig("fig5_3_residuals_fitted.png",
    "Figure 5.3: Residuals against fitted values. The diagonal stripes come from the "
    "discrete response values (log10(1) = 0, log10(2) = 0.30, ...), not from a "
    "modelling problem; the points scatter evenly around zero.", width=13)
fig("fig5_4_residual_qq.png",
    "Figure 5.4: Normal Q-Q plot of the residuals; the model is adequate in the "
    "middle, the right tail corresponds to a few very large formations (up to 99 "
    "aircraft) that the model under predicts.", width=12)

P("Model checks: the residuals have mean zero by construction; skewness 2.45 and "
  "kurtosis 11.4 (Shapiro-Wilk W = 0.822 on a subsample of 2,000, p < 2.2e-16), driven "
  "by the right tail of very large formations, not by an error of specification. No "
  "observation is influential: the largest Cook's distance is 0.0089, far below 1, and "
  "only 2.81% of the records exceed the 4/n guideline. Collinearity is moderate: the "
  "variance inflation of YEAR against all other predictors is 3.76, below the usual "
  "threshold of 5, but part of the year trend overlaps with the country mix (for "
  "example Thailand targets appear only late in the war), so the year coefficient "
  "should be read as an average trend, not as a causal effect.", after=6)

P("Prediction example: for the profile 'F-4 Phantom, target North Vietnam, night, "
  "1972, SEADAB' the model predicts 1.55 aircraft with a 95% prediction interval of "
  "[0.51, 4.69]. The 32 observed records with exactly this profile have a mean of "
  "1.75 aircraft, comfortably inside the interval. The interval is wide on the "
  "original scale (a factor of nine) - honest evidence that the model predicts the "
  "average behaviour of a group of records well, but a single record only roughly.",
  after=8)

SH("Conclusion")
P("The size of a formation is dominated by the aircraft type (B-52 cells carry about "
  "56% more aircraft than the F-4 reference) and by the period of day (night records "
  "are about 37% smaller). The five factors together explain about 17% of the "
  "record-to-record variation, which is realistic: many determinants of a formation "
  "(target importance, availability, weather, operation) are not in the data. The "
  "model passes the practical checks (no influential observations, moderate "
  "collinearity, sensible residuals) and its prediction interval covers the observed "
  "mean of a specific mission profile. Correlation results confirm the relationships "
  "and warn that Pearson coefficients on skewed variables understate the association "
  "(weapons-load: Pearson 0.31 against Spearman 0.65).", after=10)

doc.add_page_break()

# ============================================================== overall
H("Overall conclusion", size=14, before=0)
steps = [
    "The data preparation pipeline (chunked reading of the 46-lakh-record file, "
    "weapon-delivery population definition, random sample of 20,000 records, cleaning "
    "with documented rules) produced a reproducible analysis file; every number in "
    "this report is regenerated by one command per script and logged in outputs/.",
    "Problem 1: the recorded campaign peaks in 1970, concentrates on South Vietnam "
    "and Laos, is flown mainly by F-4, F-100, A-1, A-4 and A-37 aircraft and delivers "
    "mostly bombs; every numerical variable is strongly right-skewed, so the typical "
    "record is described by medians and quartiles rather than means.",
    "Problem 2: the weapon load is lognormal in shape (far better than the normal "
    "model) but the fit is formally rejected because the load is a mixture of very "
    "different aircraft groups (B-52 median 3.82 lakh lb against A-37 21,240 lb); "
    "model-based probabilities are still accurate to within about 4 percentage "
    "points; the central limit theorem check for the mean of 30 records matched "
    "theory in mean and standard error.",
    "Problem 3: day deliveries carry about 39% more load than night deliveries "
    "(geometric means; medians 42,240 against 24,900 lb; Welch p = 1.08e-15, d = "
    "0.26) - the raw means mislead because a few very heavy night formations pull "
    "the night mean up.",
    "Problem 4: the aircraft mix is not independent of the target country "
    "(chi-square = 4,538.3, df = 18, p < 2.2e-16, Cramer's V = 0.278); the "
    "standardised residuals show exactly how each aircraft family is tied to a "
    "theatre.",
    "Problem 5: log10 of the aircraft per record is explained by type, period, "
    "country, year and source (R squared = 0.166, F = 267.2); B-52 records carry "
    "about 1.56 times the aircraft of an F-4 record and night records about 37% "
    "fewer; the prediction example validated against the observed records.",
    "Across the five problems one methodological lesson repeats: the recorded "
    "quantities (weapons, load) are extremely right-skewed, so medians, geometric "
    "means and log-scale tests describe the data honestly, while raw means are "
    "distorted by a small number of very large deliveries.",
    "Main limitations, stated consistently: records are delivery events (not "
    "independent missions), the load is recorded only in SEADAB, several raw columns "
    "are unusable (WEAPONTYPECLASS 100% empty, BDA 94% empty), and the source file "
    "mixes four databases without de-duplication flags.",
]
for i, s in enumerate(steps, 1):
    P(f"{i}. {s}", align="justify", after=4)

H("R packages and software used", after=4)
P("R 4.6.1 with RStudio-compatible plain scripts. Packages: readr (chunked reading "
  "of the large raw file), ggplot2 (all figures, black-and-white theme), base R "
  "statistics (lm, t.test, chisq.test, shapiro.test, wilcox.test). The Levene test, "
  "the moment-based skewness/kurtosis and the variance inflation calculation are "
  "implemented in base R in scripts/common_setup.R so that the project runs with the "
  "standard library only. File map: scripts/00_profile_raw.R and 00b/00c (profiling "
  "the raw file), scripts/01_clean.R (builds clean_data.csv), scripts/problem1.R to "
  "problem5.R (one script per problem statement), outputs/ (text logs used in this "
  "report), figures/ (all graphs).", after=6)

doc.save(os.path.join(OUT, "report.docx"))
print("saved", os.path.join(OUT, "report.docx"))
