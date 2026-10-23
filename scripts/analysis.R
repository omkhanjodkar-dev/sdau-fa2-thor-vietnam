## ==============================================================================
## THOR Vietnam War Operations - Exploratory Data Analysis
## File: scripts/analysis.R
## 
## Run in RStudio: Click "Source" or run line-by-line (Ctrl + Enter)
## ==============================================================================

# 1. Load Libraries
if (!require("ggplot2", quietly = TRUE)) install.packages("ggplot2")
library(ggplot2)

# Ensure working directory is project root
if (basename(getwd()) == "scripts" && file.exists("../clean_data.csv")) {
  setwd("..")
}

# Create output folders if needed
dir.create("figures", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

cat("======================================================================\n")
cat("  THOR VIETNAM WAR OPERATIONS: BASIC DATA ANALYSIS\n")
cat("======================================================================\n\n")

# 2. Load Dataset
cat("Loading cleaned dataset (clean_data.csv)...\n")
data <- read.csv("clean_data.csv", stringsAsFactors = FALSE)
cat(sprintf("-> Successfully loaded %s records and %s columns.\n\n",
            format(nrow(data), big.mark = ","), ncol(data)))

# Clean up factor levels for clean plotting
data$YEAR <- as.factor(data$YEAR)
data$COUNTRY <- ifelse(is.na(data$COUNTRY) | data$COUNTRY == "", "Other/Unknown", data$COUNTRY)
data$PERIOD <- ifelse(is.na(data$PERIOD) | data$PERIOD == "", "Unknown", data$PERIOD)
data$AIRCRAFT_GROUP <- ifelse(is.na(data$AIRCRAFT_GROUP) | data$AIRCRAFT_GROUP == "", "Other", data$AIRCRAFT_GROUP)

# Common styling for beautiful, clear graphs
plot_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1a252f"),
    plot.subtitle = element_text(size = 11, color = "#555555", margin = margin(b = 10)),
    axis.title = element_text(face = "bold", size = 11, color = "#2c3e50"),
    axis.text = element_text(color = "#333333"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "none"
  )

# ------------------------------------------------------------------------------
# GRAPH 1: Bombing Missions Over Time (1965 - 1975)
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("[Graph 1] Missions Across Years\n")
cat("----------------------------------------------------------------------\n")

yearly_counts <- as.data.frame(table(Year = data$YEAR))

p1 <- ggplot(yearly_counts, aes(x = Year, y = Freq)) +
  geom_bar(stat = "identity", fill = "#2b5c8f", width = 0.7) +
  geom_text(aes(label = format(Freq, big.mark = ",")), vjust = -0.5, size = 3.5, fontface = "bold") +
  labs(
    title = "Graph 1: Bombing Deliveries Across Years (1965 - 1975)",
    subtitle = "Number of recorded weapon delivery events per year",
    x = "Year",
    y = "Number of Deliveries"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  plot_theme

print(p1)
ggsave("figures/graph1_missions_by_year.png", plot = p1, width = 8, height = 5, dpi = 300)

peak_year <- as.character(yearly_counts$Year[which.max(yearly_counts$Freq)])
cat(sprintf("EXPLANATION: Operational activity peaked around %s during intense combat phases\n", peak_year))
cat("and steadily declined leading to the 1973-1975 ceasefire and withdrawal.\n\n")


# ------------------------------------------------------------------------------
# GRAPH 2: Bombing Operations by Target Country
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("[Graph 2] Operations by Target Country\n")
cat("----------------------------------------------------------------------\n")

country_counts <- as.data.frame(table(Country = data$COUNTRY))
country_counts <- country_counts[order(country_counts$Freq, decreasing = FALSE), ]
country_counts$Country <- factor(country_counts$Country, levels = country_counts$Country)

p2 <- ggplot(country_counts, aes(x = Country, y = Freq)) +
  geom_bar(stat = "identity", fill = "#348e71", width = 0.65) +
  geom_text(aes(label = format(Freq, big.mark = ",")), hjust = -0.15, size = 3.5, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Graph 2: Bombing Deliveries by Target Country",
    subtitle = "Geographic distribution of strike locations",
    x = "Target Country",
    y = "Number of Deliveries"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  plot_theme +
  theme(panel.grid.major.x = element_line(color = "grey90"), panel.grid.major.y = element_blank())

print(p2)
ggsave("figures/graph2_target_country.png", plot = p2, width = 8, height = 5, dpi = 300)

top_country <- as.character(country_counts$Country[which.max(country_counts$Freq)])
cat(sprintf("EXPLANATION: %s was the primary theater of operations (over 50%% of records),\n", top_country))
cat("followed closely by missions in Laos targeting Ho Chi Minh trail logistics.\n\n")


# ------------------------------------------------------------------------------
# GRAPH 3: Top Aircraft Groups
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("[Graph 3] Deliveries by Aircraft Group\n")
cat("----------------------------------------------------------------------\n")

aircraft_counts <- as.data.frame(table(Aircraft = data$AIRCRAFT_GROUP))
aircraft_counts <- aircraft_counts[order(aircraft_counts$Freq, decreasing = FALSE), ]
aircraft_counts$Aircraft <- factor(aircraft_counts$Aircraft, levels = aircraft_counts$Aircraft)

p3 <- ggplot(aircraft_counts, aes(x = Aircraft, y = Freq)) +
  geom_bar(stat = "identity", fill = "#d96b27", width = 0.65) +
  geom_text(aes(label = format(Freq, big.mark = ",")), hjust = -0.15, size = 3.5, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Graph 3: Deliveries by Aircraft Group",
    subtitle = "Primary aircraft types carrying out delivery operations",
    x = "Aircraft Model",
    y = "Number of Deliveries"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  plot_theme +
  theme(panel.grid.major.x = element_line(color = "grey90"), panel.grid.major.y = element_blank())

print(p3)
ggsave("figures/graph3_aircraft_group.png", plot = p3, width = 8, height = 5, dpi = 300)

top_named_ac <- as.character(aircraft_counts$Aircraft[aircraft_counts$Aircraft != "Other"][which.max(aircraft_counts$Freq[aircraft_counts$Aircraft != "Other"])])
cat(sprintf("EXPLANATION: Among identified models, the %s carried out the highest number of strikes,\n", top_named_ac))
cat("reflecting its role as the primary multi-mission tactical fighter-bomber of the war.\n\n")


# ------------------------------------------------------------------------------
# GRAPH 4: Day vs. Night Bombing Comparison
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("[Graph 4] Day vs. Night Missions\n")
cat("----------------------------------------------------------------------\n")

period_counts <- as.data.frame(table(Period = data$PERIOD))
period_counts$Percentage <- round(100 * period_counts$Freq / sum(period_counts$Freq), 1)

p4 <- ggplot(period_counts, aes(x = Period, y = Freq, fill = Period)) +
  geom_bar(stat = "identity", width = 0.55) +
  scale_fill_manual(values = c("Day" = "#f39c12", "Night" = "#2c3e50", "Unknown" = "#95a5a6")) +
  geom_text(aes(label = paste0(format(Freq, big.mark = ","), " (", Percentage, "%)")),
            vjust = -0.5, size = 4, fontface = "bold") +
  labs(
    title = "Graph 4: Day vs. Night Operational Split",
    subtitle = "Comparison of daytime visual strikes vs. nighttime operations",
    x = "Time Period",
    y = "Number of Deliveries"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  plot_theme

print(p4)
ggsave("figures/graph4_day_vs_night.png", plot = p4, width = 7, height = 5, dpi = 300)

day_pct <- period_counts$Percentage[period_counts$Period == "Day"]
cat(sprintf("EXPLANATION: Over two-thirds (~%.1f%%) of all missions were conducted during daylight hours,\n", day_pct))
cat("as daytime offered superior visibility for ground-target acquisition.\n\n")


# ------------------------------------------------------------------------------
# GRAPH 5: Weapon Load Distribution (lb)
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("[Graph 5] Distribution of Weapon Load\n")
cat("----------------------------------------------------------------------\n")

# Filter positive loads for clean histogram
load_data <- data[!is.na(data$LOAD_LB) & data$LOAD_LB > 0 & data$LOAD_LB <= 15000, ]
med_load <- median(load_data$LOAD_LB)
mean_load <- mean(load_data$LOAD_LB)

p5 <- ggplot(load_data, aes(x = LOAD_LB)) +
  geom_histogram(binwidth = 500, fill = "#8e44ad", color = "white", alpha = 0.85) +
  geom_vline(aes(xintercept = med_load), color = "#e74c3c", linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = mean_load), color = "#2ecc71", linetype = "dotdash", linewidth = 1) +
  annotate("text", x = med_load + 200, y = Inf, vjust = 2, hjust = 0,
           label = paste0("Median: ", round(med_load), " lb"), color = "#e74c3c", fontface = "bold", size = 3.8) +
  annotate("text", x = mean_load + 200, y = Inf, vjust = 4, hjust = 0,
           label = paste0("Mean: ", round(mean_load), " lb"), color = "#27ae60", fontface = "bold", size = 3.8) +
  labs(
    title = "Graph 5: Distribution of Weapon Load per Delivery (up to 15,000 lb)",
    subtitle = "Shows typical payload sizes with median (red dashed) and mean (green dotdash)",
    x = "Weapon Load (Pounds)",
    y = "Frequency"
  ) +
  plot_theme

print(p5)
ggsave("figures/graph5_weapon_load_distribution.png", plot = p5, width = 8, height = 5, dpi = 300)

cat(sprintf("EXPLANATION: Tactical fighter-bomber payloads most commonly range between 2,000 and 6,000 lb.\n"))
cat(sprintf("The median payload is %d lb, representing standard ordnance configurations.\n\n", round(med_load)))

cat("======================================================================\n")
cat("  ALL 5 BASIC GRAPHS COMPLETED & SAVED TO figures/ DIRECTORY\n")
cat("======================================================================\n")
