# SDAUR FA-2 Project: Exploratory Analysis of THOR Vietnam Bombing Operations

Exploratory Data Analysis (EDA) of the **Theater History of Operations Reports (THOR)** Vietnam War aerial bombing operations dataset using **R** and **RStudio**.

This project provides a clean, visual, foundational data analysis focusing on **5 core exploratory graphs** with straightforward explanations.

---

## Quick Start (Demo in RStudio)

1. **Open the Project:**  
   Double-click `SDAUR.Rproj` (or open it via `File > Open Project...` in RStudio).
2. **Option A — Run Single Script:**  
   - Open `scripts/analysis.R`.
   - Click **Source** (or press `Ctrl + Shift + S`).
   - The 5 graphs appear one after another in the **Plots** pane, and plain-English explanations print in the **Console**.
3. **Option B — Interactive Notebook / HTML:**  
   - Open `analysis.Rmd` and click **Knit** to view the full interactive report.
   - Alternatively, open `analysis.html` directly in any web browser.

---

## The 5 Core Visualizations

All graphs are saved in high resolution under the [`figures/`](figures/) directory:

| Graph | Filename | Description |
|---|---|---|
| **Graph 1** | `graph1_missions_by_year.png` | Bombing deliveries across years (1965–1975), highlighting the 1969–1970 operational peak. |
| **Graph 2** | `graph2_target_country.png` | Delivery volume by target country (South Vietnam, Laos, North Vietnam, Cambodia, Thailand). |
| **Graph 3** | `graph3_aircraft_group.png` | Sorties across combat aircraft models (F-4 Phantom, F-100, A-1, A-4, etc.). |
| **Graph 4** | `graph4_day_vs_night.png` | Percentage split between daytime visual strikes (~69%) and night missions. |
| **Graph 5** | `graph5_weapon_load_distribution.png` | Histogram of weapon payload (lb) showing typical ordnance loadouts with median and mean markers. |

---

## Oral & Presentation Notes

See [`PRESENTATION.md`](PRESENTATION.md) for ready-to-read speaking points for each graph during your demonstration.

---

## File Structure

```
SDAUR.Rproj               RStudio project configuration
clean_data.csv            Cleaned analysis dataset (20,000 sampled records)
scripts/
  └── analysis.R          Main standalone R script producing all 5 graphs & console notes
analysis.Rmd              Interactive R Markdown document (code + text + visuals)
analysis.html             Rendered self-contained HTML report
figures/                  Saved PNG images for all 5 graphs
PRESENTATION.md           Speaking guide for viva/presentation
README.md                 This documentation
```
