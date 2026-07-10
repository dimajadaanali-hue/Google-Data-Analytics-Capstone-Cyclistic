# =====================================================================
# خطوة 1: تحميل المكتبات الأساسية وتثبيتها إن لم تكن موجودة
# =====================================================================
# إذا لم تكن هذه المكتبات مثبتة لديكِ، يمكنك تفعيل الأسطر الثلاثة التالية لتثبيتها:
# install.packages("tidyverse")
# install.packages("scales")
# install.packages("patchwork")

library(tidyverse) # Includes ggplot2 for data visualization, dplyr for data manipulation, and lubridate for date-time handling
library(scales)     # For professional formatting of numbers and percentages on plot axes
library(patchwork)  # Package used to combine and arrange multiple plots into a single dashboard layout

# Globally disable scientific notation (e.g., 1e+05) across the script
options(scipen = 999)

# =====================================================================
# Import the dataset from the local directory
# =====================================================================
trips_data <- read_csv("cleaned_combined_data.csv")

## =====================================================================
# Step 2: Data Preparation
# =====================================================================
# Since data is pre-cleaned and prepared in BigQuery, we only filter out 
# outliers (trips < 1 minute or > 24 hours) to ensure statistical accuracy

cleaned_data <- trips_data %>%
  filter(!is.na(ride_length_minutes) & !is.na(member_casual)) %>%
  filter(ride_length_minutes >= 1 & ride_length_minutes <= 1440)


# =====================================================================
# Step 3: Summarize Data for Visualizations
# =====================================================================

# First: Weekly summary statistics table (for the first and second plots)
weekly_summary <- cleaned_data %>%
  group_by(day_of_week, member_casual) %>%
  summarize(
    total_rides = n(),
    avg_length = mean(ride_length_minutes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  
  # Order the days of the week consistently from Saturday to Friday
  mutate(day_of_week = factor(day_of_week, 
                              levels = c("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
  ))

# Second: User types summary table (for the donut chart)
user_summary <- cleaned_data %>%
  group_by(member_casual) %>%
  summarize(total_rides = n()) %>%
  mutate(percentage = total_rides / sum(total_rides))


# =====================================================================
# Step 4: Design Individual Plots Using ggplot2
# =====================================================================

# Plot 1: Total Trips by Day of the Week and User Type
plot1 <- ggplot(data = weekly_summary, 
                aes(x = day_of_week, y = total_rides, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("member" = "#1d3557", "casual" = "#00b4d8")) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Total Trips by Day of Week & User Type",
    x = "Day of the Week",
    y = "Total Number of Trips",
    fill = "Rider Type"
  ) +
  theme_minimal() + 
  theme(
    plot.title = element_text(face = "bold", size = 12, color = "#1e293b"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9), 
    legend.position = "top"
  )


# Plot 2: Average Ride Length (Grouped Horizontal Bar Chart)
plot2 <- ggplot(data = weekly_summary, 
                aes(x = day_of_week, y = avg_length, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("member" = "#1d3557", "casual" = "#00b4d8")) +
  coord_flip() + 
  labs(
    title = "Avg Ride Length (Minutes) by Day",
    x = "Day of the Week",
    y = "Average Duration (min)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 11, color = "#1e293b"),
    legend.position = "none"
  )


# Plot 3: Donut Chart
plot3 <- ggplot(user_summary, aes(x = 2, y = percentage, fill = member_casual)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) +
  scale_fill_manual(values = c("member" = "#1d3557", "casual" = "#00b4d8")) +
  geom_text(aes(label = percent(percentage, accuracy = 0.1)), 
            position = position_stack(vjust = 0.5), color = "white", size = 3, fontface = "bold") +
  labs(title = "Total Trips Share") +
  theme_void() + 
  theme(
    plot.title = element_text(face = "bold", size = 11, color = "#1e293b", hjust = 0.5),
    legend.position = "none"
  )


# =====================================================================
# Step 5: Combine Plots into a Single Dashboard and Save
# =====================================================================
final_dashboard <- plot1 | (plot2 / plot3)

final_dashboard <- final_dashboard + 
  plot_annotation(
    title = "Cyclistic Rider Behavior Dashboard",
    subtitle = "Analysis generated using R, Tidyverse and ggplot2",
    theme = theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#0f172a"),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "#64748b", margin = margin(b = 15))
    )
  )

# Display the final dashboard in RStudio
print(final_dashboard)

# Automatically save as a high-quality image in the project folder
ggsave("cyclistic_r_dashboard.png", plot = final_dashboard, width = 12, height = 8, dpi = 300)