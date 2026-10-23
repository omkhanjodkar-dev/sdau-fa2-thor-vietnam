# Presentation Guide & Speaking Script (Basic Data Analysis)

This guide provides simple, confident speaking points for presenting the project in **RStudio**.

---

## 1. Quick Introduction (1 minute)

> *"Good morning sir/ma'am. Our project is an exploratory data analysis of the THOR Vietnam War aerial bombing operations dataset using R.*  
> *Rather than performing overly complex statistical models, we focused on answering five foundational exploratory questions about the operations between 1965 and 1975 using clean visual graphs and data summaries."*

---

## 2. Showing the Work in RStudio

You have two easy ways to demonstrate this:

### Option A: Running the Script (`scripts/analysis.R`)
1. Open `scripts/analysis.R` in RStudio.
2. Click **Source** (or press `Ctrl + Shift + S`).
3. Each graph appears in the **Plots** pane, and the explanation prints directly into the **Console**.

### Option B: The R Markdown Document (`analysis.Rmd`)
1. Open `analysis.Rmd` in RStudio.
2. Click the **Knit** button (or open the already rendered `analysis.html` in your browser).
3. Walk through each section smoothly with the professor.

---

## 3. Explaining the 5 Graphs (Speaking Points)

### Graph 1: Missions Across Years (1965 – 1975)
- **What it shows:** Total weapon delivery records by year.
- **Key point to speak:**  
  > *"As we can see from Graph 1, bombing activity ramped up significantly from 1965 and peaked around 1969–1970 during intense combat operations, followed by a steep drop leading to the 1973 ceasefire and final 1975 withdrawal."*

---

### Graph 2: Operations by Target Country
- **What it shows:** Geographic distribution of strike targets.
- **Key point to speak:**  
  > *"Graph 2 reveals that South Vietnam was the primary operational theater, accounting for over 50% of all sorties. Laos was the second largest target area, reflecting extensive aerial interdiction of the Ho Chi Minh trail logistics."*

---

### Graph 3: Deliveries by Aircraft Group
- **What it shows:** Strike frequency categorized by combat aircraft model.
- **Key point to speak:**  
  > *"Graph 3 displays the main aircraft involved. Among identified models, the McDonnell Douglas F-4 Phantom flew the highest number of missions, as it served as the core multi-role tactical fighter-bomber across the US Air Force and Navy."*

---

### Graph 4: Day vs. Night Operational Split
- **What it shows:** Comparison of daytime versus nighttime strike missions.
- **Key point to speak:**  
  > *"Graph 4 shows that roughly 69% of all strikes were conducted during the daytime. Visual target identification was critical over jungle terrain during the 1960s, long before modern night-vision and GPS guidance systems were standard."*

---

### Graph 5: Weapon Load Distribution (lb)
- **What it shows:** Histogram of payload weight delivered per sortie.
- **Key point to speak:**  
  > *"Finally, Graph 5 shows the payload distribution. Standard tactical payloads typically fall between 2,000 and 6,000 lb, with a median payload of 6,440 lb representing standard bomb configurations (such as sets of 500-lb Mk 82 bombs)."*

---

## 4. Conclusion & Summary

> *"In summary, our exploratory analysis reveals clear patterns in temporal intensity, geographic focus on South Vietnam and Laos, tactical reliance on multi-role fighters like the F-4 Phantom, and an operational preference for daytime visual delivery."*
