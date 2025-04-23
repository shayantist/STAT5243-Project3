rm(list=ls())

install.packages("dplyr")
install.packages("rpart")


library(dplyr)
library(readr)

groupA <- read_csv("groupA.csv", skip = 5)
groupB <- read_csv("groupB.csv", skip = 5)

colnames(groupA) <- tolower(colnames(groupA))
colnames(groupB) <- tolower(colnames(groupB))

groupA <- rename(groupA,
                 event_name = `event name`,
                 event_count = `event count`,
                 user_engagement = `user engagement`,
                 average_session_duration = `average session duration`
)

groupB <- rename(groupB,
                 event_name = `event name`,
                 event_count = `event count`,
                 user_engagement = `user engagement`,
                 average_session_duration = `average session duration`
)

groupA$version <- "A"
groupB$version <- "B"
df <- bind_rows(groupA, groupB)



# Conversion Rate Comparison (calendar_adds / total_event_count)

adds <- df %>%
  filter(event_name == "calendar_adds") %>%
  select(version, event_count) %>%
  rename(adds = event_count)

grand_totals <- df %>%
  group_by(version) %>%
  summarise(grand_total = max(event_count, na.rm = TRUE))

conversion_data <- left_join(adds, grand_totals, by = "version")

if (nrow(conversion_data) == 2) {
  conversion_test <- prop.test(
    x = conversion_data$adds,
    n = conversion_data$grand_total
  )
  
  cat("\n Approx. Conversion Rate Comparison \n")
  print(conversion_data)
  print(conversion_test)
} else {
  cat("Could not perform conversion test due to missing data.\n")
}




# Average Session Duration Comparison 

duration_A <- df %>% filter(event_name == "page_view", version == "A") %>% pull(average_session_duration)
duration_B <- df %>% filter(event_name == "page_view", version == "B") %>% pull(average_session_duration)

if (length(duration_A) == 1 && length(duration_B) == 1) {
  diff <- duration_B - duration_A
  pct_diff <- 100 * diff / duration_A
  cat("\n Average Session Duration (Page View) \n")
  cat(sprintf("Group A: %.2f sec | Group B: %.2f sec\n", duration_A, duration_B))
  cat(sprintf("Difference: %.2f sec (%.2f%% increase in Group B)\n", diff, pct_diff))
} else {
  cat("\n Missing session duration data.\n")
}



# Plot Part
install.packages("ggplot2")
install.packages("scales")
library(ggplot2)
library(scales)



# Conversion Rate Bar Plot
conversion_data <- conversion_data %>%
  mutate(conversion_rate = adds / grand_total)

ggplot(conversion_data, aes(x = version, y = conversion_rate, fill = version)) +
  geom_bar(stat = "identity", width = 0.6) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "Conversion Rate by Group",
       x = "Version",
       y = "Conversion Rate") +
  theme_minimal() +
  theme(legend.position = "none")

# Session Duration Bar Plot
session_df <- data.frame(
  version = c("A", "B"),
  duration = c(duration_A, duration_B)
)

ggplot(session_df, aes(x = version, y = duration, fill = version)) +
  geom_bar(stat = "identity", width = 0.6) +
  labs(title = "Average Session Duration (Page View)",
       x = "Version",
       y = "Duration (seconds)") +
  theme_minimal() +
  theme(legend.position = "none")
