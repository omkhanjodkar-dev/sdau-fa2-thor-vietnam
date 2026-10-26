import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_border(cell, **kwargs):
    """
    Set cell borders
    kwargs: top, bottom, left, right
    values: dict(sz=12, val='single', color='FF0000', space='0')
    """
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(f'<w:tcBorders {nsdecls("w")}/>')
    for border_name, border_props in kwargs.items():
        border_xml = f'<w:{border_name} {nsdecls("w")} '
        for key, val in border_props.items():
            border_xml += f'w:{key}="{val}" '
        border_xml += '/>'
        tcBorders.append(parse_xml(border_xml))
    tcPr.append(tcBorders)

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def create_report():
    doc = Document()

    # Set margins
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)

    # Base styling
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0x22, 0x22, 0x22)

    # 1. Header block
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("PIMPRI CHINCHWAD EDUCATION TRUST'S\n")
    run.font.size = Pt(13)
    run.bold = True
    run.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)

    run = p.add_run("PIMPRI CHINCHWAD COLLEGE OF ENGINEERING\n")
    run.font.size = Pt(15)
    run.bold = True
    run.font.color.rgb = RGBColor(0x8B, 0x00, 0x00)

    # Logo if available
    logo_path = os.path.join("report", "assets", "pccoe_logo.png")
    if os.path.exists(logo_path):
        p_logo = doc.add_paragraph()
        p_logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_logo.paragraph_format.space_before = Pt(4)
        p_logo.paragraph_format.space_after = Pt(4)
        p_logo.add_run().add_picture(logo_path, width=Inches(1.2))

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("Department of AS&H\n")
    run.font.size = Pt(12)
    run.bold = True

    run = p.add_run("Report of FA-2 activity\n")
    run.font.size = Pt(13)
    run.bold = True
    run.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)

    run = p.add_run("Subject: BSH23OE04: Open Elective: Statistical Data Analysis using R\n")
    run.font.size = Pt(11)
    run.bold = True

    run = p.add_run("Academic Year 2026-27 | Semester I\n")
    run.font.size = Pt(10)
    run.italic = True

    # Divider line
    p_div = doc.add_paragraph()
    p_div.paragraph_format.space_after = Pt(8)
    p_div.add_run("―" * 58).font.color.rgb = RGBColor(0xAA, 0xAA, 0xAA)

    # Student Details
    p = doc.add_paragraph()
    r = p.add_run("Submitted by:\n")
    r.bold = True
    
    # Table of students
    t_students = doc.add_table(rows=1, cols=3)
    t_students.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr = t_students.rows[0].cells
    hdr[0].text = "Name of the student"
    hdr[1].text = "PRN number"
    hdr[2].text = "Branch"
    for c in hdr:
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True
                run.font.size = Pt(10)
        set_cell_background(c, "EAECEE")

    students = [
        ("Om Khanjodkar", "125B1B283", "Computer Engineering"),
        ("Siddhant Verma", "125B1B278", "Computer Engineering"),
        ("Parth Ghumade", "125B1B234", "Computer Engineering"),
        ("Tanishk Malge", "125B1B247", "Computer Engineering")
    ]
    for s in students:
        row = t_students.add_row().cells
        row[0].text = s[0]
        row[1].text = s[1]
        row[2].text = s[2]
        for c in row:
            for para in c.paragraphs:
                for run in para.runs:
                    run.font.size = Pt(9.5)

    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_before = Pt(8)
    p_sub.add_run("Submitted to: ").bold = True
    p_sub.add_run("Dr. Rajesh G Talekar\n")
    p_sub.add_run("Date: ").bold = True
    p_sub.add_run("23/10/2026          ")
    p_sub.add_run("Sign: ").bold = True
    p_sub.add_run("____________________\n")

    p_div2 = doc.add_paragraph()
    p_div2.add_run("―" * 58).font.color.rgb = RGBColor(0xAA, 0xAA, 0xAA)

    # Project Title & Data
    p = doc.add_paragraph()
    r = p.add_run("Project Title: ")
    r.bold = True
    p.add_run("Descriptive and Exploratory Analysis of THOR Vietnam War Bombing Operations Data using R\n")

    r = p.add_run("Data used: ")
    r.bold = True
    p.add_run("Theater History of Operations Reports (THOR) Vietnam War Aerial Bombing Dataset\n")

    r = p.add_run("Details of the data: ")
    r.bold = True
    p.add_run("The analyzed dataset consists of 20,000 representative combat delivery records sampled across 1965–1975 with key variables as follows:\n")

    vars_info = [
        ("1. MISSION_DATE", "Calendar date of the combat mission"),
        ("2. YEAR", "Year of operation (1965 to 1975)"),
        ("3. PERIOD", "Time period of delivery: Day vs. Night"),
        ("4. COUNTRY", "Target sovereign country (South Vietnam, Laos, North Vietnam, Cambodia, Thailand)"),
        ("5. SERVICE", "Operating military service branch (USAF, USN, VNAF, USMC)"),
        ("6. AIRCRAFT_GROUP", "Standardized combat aircraft model (F-4 Phantom, B-52, F-100, A-1, A-4, A-37)"),
        ("7. WEAPON_CLASS", "Class of weapon delivered (BOMB, ROCKET, GUN, MISSILE, SUPPORT)"),
        ("8. WEAPONS_DELIVERED", "Number of ordnance units delivered on target"),
        ("9. LOAD_LB", "Total weight of ordnance delivered (in pounds)"),
        ("10. TGT_HOUR", "Local hour of target delivery (0-23)"),
        ("11. LAT & LON", "Geographic coordinates of strike location")
    ]
    for v_name, v_desc in vars_info:
        pv = doc.add_paragraph()
        pv.paragraph_format.left_indent = Inches(0.2)
        pv.paragraph_format.space_after = Pt(2)
        r = pv.add_run(f"{v_name}: ")
        r.bold = True
        pv.add_run(v_desc)

    p_flow = doc.add_paragraph()
    p_flow.paragraph_format.space_before = Pt(8)
    r = p_flow.add_run("Flow: ")
    r.bold = True
    p_flow.add_run("\nProblem Statement\nStatistical Analysis\nData Visualization\nCoding in R\nFindings & Interpretations\n")

    p_div3 = doc.add_paragraph()
    p_div3.add_run("―" * 58).font.color.rgb = RGBColor(0xAA, 0xAA, 0xAA)

    # --------------------------------------------------------------------------
    # PROBLEM STATEMENT 1
    # --------------------------------------------------------------------------
    p1 = doc.add_heading("Problem statement 1: How did bombing mission activity and weapon delivery volume change across the years of the war?", level=2)
    p1.paragraph_format.space_before = Pt(12)

    doc.add_paragraph(
        "The data is grouped by operation year from 1965 through 1975 to assess annual operational tempo, "
        "peak engagement periods, and de-escalation trends. The frequency distribution of missions is summarized below:"
    )

    t1 = doc.add_table(rows=1, cols=3)
    t1.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr = t1.rows[0].cells
    hdr[0].text = "Year"
    hdr[1].text = "Recorded Deliveries"
    hdr[2].text = "Percentage Share (%)"
    for c in hdr:
        set_cell_background(c, "EAECEE")
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True

    year_data = [
        ("1965", "300", "1.50%"),
        ("1966", "1,954", "9.77%"),
        ("1967", "2,337", "11.69%"),
        ("1968", "3,352", "16.76%"),
        ("1969", "2,470", "12.35%"),
        ("1970", "3,532", "17.66%"),
        ("1971", "2,161", "10.81%"),
        ("1972", "2,642", "13.21%"),
        ("1973", "910", "4.55%"),
        ("1974", "256", "1.28%"),
        ("1975", "86", "0.43%")
    ]
    for row_val in year_data:
        row = t1.add_row().cells
        row[0].text = row_val[0]
        row[1].text = row_val[1]
        row[2].text = row_val[2]

    doc.add_paragraph(
        "It shows that weapon delivery operations escalated sharply between 1966 and 1968, reaching an all-time operational "
        "peak in 1970 (3,532 deliveries, 17.66%), followed by a gradual reduction and steep drop following the 1973 ceasefire. "
        "This trend is visualized in the bar chart below:"
    )

    fig1 = os.path.join("figures", "graph1_missions_by_year.png")
    if os.path.exists(fig1):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(fig1, width=Inches(5.5))

    p_code1 = doc.add_paragraph()
    r = p_code1.add_run("R Code Snippet:\n")
    r.bold = True
    p_code1.add_run(
        'yearly_counts <- as.data.frame(table(Year = data$YEAR))\n'
        'ggplot(yearly_counts, aes(x = Year, y = Freq)) +\n'
        '  geom_bar(stat = "identity", fill = "#2b5c8f", width = 0.7) +\n'
        '  geom_text(aes(label = format(Freq, big.mark = ",")), vjust = -0.5, fontface = "bold") +\n'
        '  labs(title = "Bombing Deliveries Across Years (1965-1975)", x = "Year", y = "Deliveries")'
    ).font.size = Pt(9.5)
    p_code1.style = 'Normal'

    doc.add_paragraph(
        "Explanation & Takeaway: The peak in 1968 and 1970 reflects the intensive phases of ground support and interdiction campaigns. "
        "Post-1972 deliveries decreased precipitously as direct air support operations were transferred to local forces."
    )

    # --------------------------------------------------------------------------
    # PROBLEM STATEMENT 2
    # --------------------------------------------------------------------------
    p2 = doc.add_heading("Problem statement 2: What was the geographic distribution of bombing operations across target countries?", level=2)
    p2.paragraph_format.space_before = Pt(12)

    doc.add_paragraph(
        "To evaluate geographic concentration of tactical sorties, records are grouped by target country. "
        "The deliveries and relative proportions are detailed below:"
    )

    t2 = doc.add_table(rows=1, cols=3)
    t2.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr2 = t2.rows[0].cells
    hdr2[0].text = "Target Country"
    hdr2[1].text = "Total Deliveries"
    hdr2[2].text = "Percentage Share (%)"
    for c in hdr2:
        set_cell_background(c, "EAECEE")
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True

    c_data = [
        ("South Vietnam", "10,510", "53.48%"),
        ("Laos", "5,736", "29.19%"),
        ("North Vietnam", "2,363", "12.02%"),
        ("Cambodia", "960", "4.89%"),
        ("Thailand", "82", "0.42%")
    ]
    for row_val in c_data:
        row = t2.add_row().cells
        row[0].text = row_val[0]
        row[1].text = row_val[1]
        row[2].text = row_val[2]

    doc.add_paragraph(
        "It shows that South Vietnam accounted for the clear majority of all weapon delivery records (53.48%), followed by "
        "Laos (29.19%). The geographic distribution is visualized by the horizontal bar chart below:"
    )

    fig2 = os.path.join("figures", "graph2_target_country.png")
    if os.path.exists(fig2):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(fig2, width=Inches(5.5))

    p_code2 = doc.add_paragraph()
    r = p_code2.add_run("R Code Snippet:\n")
    r.bold = True
    p_code2.add_run(
        'country_counts <- as.data.frame(table(Country = data$COUNTRY))\n'
        'ggplot(country_counts, aes(x = Country, y = Freq)) +\n'
        '  geom_bar(stat = "identity", fill = "#348e71", width = 0.65) +\n'
        '  coord_flip() +\n'
        '  labs(title = "Bombing Deliveries by Target Country", x = "Target Country", y = "Deliveries")'
    ).font.size = Pt(9.5)

    doc.add_paragraph(
        "Explanation & Takeaway: The primary combat theater was internal close air support in South Vietnam. "
        "The high frequency in Laos highlights the extensive air interdiction campaign targeting logistics and troop movements along the Ho Chi Minh trail network."
    )

    # --------------------------------------------------------------------------
    # PROBLEM STATEMENT 3
    # --------------------------------------------------------------------------
    p3 = doc.add_heading("Problem statement 3: Which combat aircraft models were most frequently deployed for weapon deliveries?", level=2)
    p3.paragraph_format.space_before = Pt(12)

    doc.add_paragraph(
        "Aircraft types were classified into standard operational airframe groups to identify the primary combat platforms used. "
        "The frequency and proportion across identified aircraft are as follows:"
    )

    t3 = doc.add_table(rows=1, cols=3)
    t3.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr3 = t3.rows[0].cells
    hdr3[0].text = "Aircraft Group"
    hdr3[1].text = "Total Deliveries"
    hdr3[2].text = "Percentage Share (%)"
    for c in hdr3:
        set_cell_background(c, "EAECEE")
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True

    ac_data = [
        ("F-4 Phantom", "4,827", "24.14%"),
        ("F-100 Super Sabre", "2,877", "14.39%"),
        ("A-1 Skyraider", "2,067", "10.34%"),
        ("A-4 Skyhawk", "1,841", "9.21%"),
        ("A-37 Dragonfly", "1,515", "7.58%"),
        ("B-52 Stratofortress", "836", "4.18%"),
        ("Other / Unspecified", "6,036", "30.18%")
    ]
    for row_val in ac_data:
        row = t3.add_row().cells
        row[0].text = row_val[0]
        row[1].text = row_val[1]
        row[2].text = row_val[2]

    doc.add_paragraph(
        "It clearly shows that the multi-role F-4 Phantom was the single most deployed combat platform (24.14%), "
        "delivering significantly more ordnance events than specialized attack aircraft or heavy bombers. "
        "This can be visualized by the bar chart below:"
    )

    fig3 = os.path.join("figures", "graph3_aircraft_group.png")
    if os.path.exists(fig3):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(fig3, width=Inches(5.5))

    p_code3 = doc.add_paragraph()
    r = p_code3.add_run("R Code Snippet:\n")
    r.bold = True
    p_code3.add_run(
        'aircraft_counts <- as.data.frame(table(Aircraft = data$AIRCRAFT_GROUP))\n'
        'ggplot(aircraft_counts, aes(x = Aircraft, y = Freq)) +\n'
        '  geom_bar(stat = "identity", fill = "#d96b27", width = 0.65) +\n'
        '  coord_flip() +\n'
        '  labs(title = "Deliveries by Aircraft Group", x = "Aircraft Model", y = "Deliveries")'
    ).font.size = Pt(9.5)

    doc.add_paragraph(
        "Explanation & Takeaway: The McDonnell Douglas F-4 Phantom II served as the primary workhorse due to its high speed, heavy payload capability, "
        "and adaptability for both USAF and US Navy joint strike missions."
    )

    # --------------------------------------------------------------------------
    # PROBLEM STATEMENT 4
    # --------------------------------------------------------------------------
    p4 = doc.add_heading("Problem statement 4: How did mission frequency and delivered weapon loads compare between Day and Night operations?", level=2)
    p4.paragraph_format.space_before = Pt(12)

    doc.add_paragraph(
        "The data is partitioned by operational period (Day vs. Night). Mission count, percentage, average weapon load, "
        "and standard deviation of load delivered were computed as follows:"
    )

    t4 = doc.add_table(rows=1, cols=5)
    t4.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr4 = t4.rows[0].cells
    hdr4[0].text = "Period"
    hdr4[1].text = "Total Deliveries"
    hdr4[2].text = "Share (%)"
    hdr4[3].text = "Average Load (lb)"
    hdr4[4].text = "Std. Deviation (lb)"
    for c in hdr4:
        set_cell_background(c, "EAECEE")
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True

    p_data = [
        ("Day", "13,778", "68.9%", "57,614.7 lb", "80,064.1 lb"),
        ("Night", "6,222", "31.1%", "65,258.9 lb", "123,637.8 lb")
    ]
    for row_val in p_data:
        row = t4.add_row().cells
        for idx, val in enumerate(row_val):
            row[idx].text = val

    doc.add_paragraph(
        "It shows that over two-thirds (68.9%) of all deliveries were conducted during daylight hours. Night operations, "
        "while less frequent, exhibited a higher mean load (65,258 lb) driven by B-52 radar-guided arc light strikes. "
        "The day vs. night delivery ratio is visualized below:"
    )

    fig4 = os.path.join("figures", "graph4_day_vs_night.png")
    if os.path.exists(fig4):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(fig4, width=Inches(5.0))

    p_code4 = doc.add_paragraph()
    r = p_code4.add_run("R Code Snippet:\n")
    r.bold = True
    p_code4.add_run(
        'period_counts <- as.data.frame(table(Period = data$PERIOD))\n'
        'period_counts$Percentage <- round(100 * period_counts$Freq / sum(period_counts$Freq), 1)\n'
        'ggplot(period_counts, aes(x = Period, y = Freq, fill = Period)) +\n'
        '  geom_bar(stat = "identity", width = 0.55) +\n'
        '  labs(title = "Day vs. Night Operational Split", x = "Period", y = "Deliveries")'
    ).font.size = Pt(9.5)

    doc.add_paragraph(
        "Explanation & Takeaway: Visual ground-target identification was imperative for tactical fighter-bombers in jungle canopy terrain. "
        "Night operations relied on specialized radar beacons or illumination flares, concentrating heavier payloads per mission."
    )

    # --------------------------------------------------------------------------
    # PROBLEM STATEMENT 5
    # --------------------------------------------------------------------------
    p5 = doc.add_heading("Problem statement 5: What was the distribution and central tendency of weapon payload (in pounds) delivered per mission?", level=2)
    p5.paragraph_format.space_before = Pt(12)

    doc.add_paragraph(
        "To understand typical tactical ordnance carried by strike aircraft, deliveries with recorded positive weapon loads "
        "(up to 15,000 lb, representing tactical fighter-bombers) were analyzed. Key summary statistics are tabulated below:"
    )

    t5 = doc.add_table(rows=1, cols=6)
    t5.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr5 = t5.rows[0].cells
    hdr5[0].text = "Metric"
    hdr5[1].text = "Sample Size (N)"
    hdr5[2].text = "Median Load"
    hdr5[3].text = "Mean Load"
    hdr5[4].text = "Std. Deviation"
    hdr5[5].text = "IQR"
    for c in hdr5:
        set_cell_background(c, "EAECEE")
        for para in c.paragraphs:
            for run in para.runs:
                run.bold = True

    row = t5.add_row().cells
    row[0].text = "Weapon Load (lb)"
    row[1].text = "1,393"
    row[2].text = "6,440.0 lb"
    row[3].text = "6,540.2 lb"
    row[4].text = "3,720.2 lb"
    row[5].text = "5,000.0 lb"

    doc.add_paragraph(
        "It shows that the median weapon load is 6,440 lb with an average load of 6,540 lb. "
        "The distribution can be visualized with the following histogram showing the median and mean markers:"
    )

    fig5 = os.path.join("figures", "graph5_weapon_load_distribution.png")
    if os.path.exists(fig5):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(fig5, width=Inches(5.5))

    p_code5 = doc.add_paragraph()
    r = p_code5.add_run("R Code Snippet:\n")
    r.bold = True
    p_code5.add_run(
        'load_data <- data[!is.na(data$LOAD_LB) & data$LOAD_LB > 0 & data$LOAD_LB <= 15000, ]\n'
        'med_load <- median(load_data$LOAD_LB)\n'
        'mean_load <- mean(load_data$LOAD_LB)\n'
        'ggplot(load_data, aes(x = LOAD_LB)) +\n'
        '  geom_histogram(binwidth = 500, fill = "#8e44ad", color = "white") +\n'
        '  geom_vline(aes(xintercept = med_load), color = "red", linetype = "dashed") +\n'
        '  geom_vline(aes(xintercept = mean_load), color = "green", linetype = "dotdash")'
    ).font.size = Pt(9.5)

    doc.add_paragraph(
        "Explanation & Takeaway: The distribution clusters notably around standard bomb configurations—most notably clusters "
        "of 500-lb Mk 82 general-purpose bombs, 750-lb M117 bombs, and 2.75-inch rocket pods, demonstrating standard tactical military loadouts."
    )

    # --------------------------------------------------------------------------
    # OVERALL CONCLUSION
    # --------------------------------------------------------------------------
    p_conc = doc.add_heading("Overall Conclusion:", level=2)
    p_conc.paragraph_format.space_before = Pt(14)

    conclusions = [
        ("1. Temporal Escalation and Peak:", " Aerial bombing intensity escalated steadily during the late 1960s, reaching maximum combat frequency in 1968 and 1970 before declining sharply after 1972."),
        ("2. Focus on Close Air Support & Interdiction:", " South Vietnam received over half (53.5%) of all deliveries, while operations in Laos (29.2%) formed a critical sustained campaign targeting supply movement along the Ho Chi Minh trail."),
        ("3. Tactical Aircraft Dominance:", " The versatile McDonnell Douglas F-4 Phantom II was the most utilized combat platform, flying nearly a quarter (24.1%) of all recorded missions."),
        ("4. Daytime Visual Primacy:", " Approximately 68.9% of missions occurred in daylight hours due to visual target identification requirements in jungle terrain."),
        ("5. Standardized Tactical Ordnance:", " Weapon loads clustered tightly around standard munitions packages, featuring a median payload of 6,440 pounds per tactical fighter delivery.")
    ]

    for c_title, c_text in conclusions:
        pc = doc.add_paragraph()
        pc.paragraph_format.left_indent = Inches(0.2)
        pc.paragraph_format.space_after = Pt(4)
        r = pc.add_run(c_title)
        r.bold = True
        pc.add_run(c_text)

    # Save document
    out_docx = os.path.join("report", "report.docx")
    doc.save(out_docx)
    print(f"Report saved successfully to {out_docx}")

if __name__ == "__main__":
    create_report()
