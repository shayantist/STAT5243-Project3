rm(list=ls())

install.packages("dplyr")
install.packages("ggplot2")
install.packages("rpart")
install.packages("rpart.plot")
install.packages("corrplot")

library(dplyr)
library(ggplot2)
library(rpart)
library(rpart.plot)
library(corrplot)

df <- read.csv("session_summaries.csv")

df <- df %>%
  mutate(
    conversion_rate = ifelse(event_clicks > 0, calendar_adds / event_clicks, NA)
  )

summary_stats <- df %>%
  group_by(version) %>%
  summarise(
    users = n(),
    avg_clicks = mean(event_clicks, na.rm = TRUE),
    avg_adds = mean(calendar_adds, na.rm = TRUE),
    avg_conversion = mean(conversion_rate, na.rm = TRUE),
    avg_duration = mean(session_duration, na.rm = TRUE),
    avg_ai_chat = mean(AI_chat_messages_sent, na.rm = TRUE),
    avg_ai_suggest = mean(AI_suggestions_requested, na.rm = TRUE)
  )
print(summary_stats)

# we can find that:
# Although the click-through rate of Group B was lower, 
# its conversion rate was significantly higher.

# The stay time of Group A was slightly longer, 
# but Group B used AI chat more frequently.

# T-Tests
group_A <- df %>% filter(version == "A")
group_B <- df %>% filter(version == "B")

t_conversion <- t.test(group_A$conversion_rate, group_B$conversion_rate)
t_duration <- t.test(group_A$session_duration, group_B$session_duration)

# A
# The conversion rate was significantly higher in Version B (mean = 0.60) 
# than Version A (mean = 0.39), t(60.5) = –2.21, p = .031. 
# This suggests that the enhanced UI and/or AI assistant positively 
# influenced users' likelihood to add events to their calendar.

# B 
# Although users in Version A had a slightly longer average session duration, 
# the difference was not statistically significant, p = .22. 
# This suggests that version alone may not explain browsing time.




cat("Conversion Rate t-test:\n")
print(t_conversion)
cat("\nSession Duration t-test:\n")
print(t_duration)



# Boxplots
ggplot(df, aes(x = version, y = conversion_rate)) +
  geom_boxplot(fill = c("#f97c7c", "#62c2c2")) +
  geom_jitter(width = 0.1, color = "black", size = 2) +
  labs(
    title = "Conversion Rate by Version",
    x = "Version", y = "Conversion Rate"
  ) +
  theme_minimal()
# The median of Version B is higher, and the IQR range is also more inclined towards high conversion.
# The distribution of group A is more discrete and leans towards the lower limit, 
# with the extreme values concentrated at 0.
# Some users in both groups had a conversion rate of 1 (i.e., all users added).

# Users in Version B showed a significantly higher conversion rate distribution compared to Version A. 
# This supports the hypothesis that the redesigned UI or 
# AI assistant positively influenced users' likelihood to add events.


ggplot(df, aes(x = version, y = session_duration)) +
  geom_boxplot(fill = c("#f2b5d4", "#b5d2f2")) +
  geom_jitter(width = 0.1, color = "black", size = 2) +
  labs(
    title = "Session Duration by Version",
    x = "Version", y = "Duration (seconds)"
  ) +
  theme_minimal()
# The median stay time of Version A is higher;
# The distribution of Version B is slightly more concentrated in a shorter time period;
# p = 0.22 → The difference was not significant;

# While Version A users had slightly longer sessions on average, 
# this difference was not statistically significant. 
# Time spent may not directly reflect UI effectiveness.




# ANOVA 
anova_event <- aov(event_clicks ~ version, data = df)
cat("\nANOVA: Event Clicks by Version\n")
summary(anova_event)

# A one-way ANOVA revealed a significant effect of interface version on 
# the number of event clicks, F(1, 69) = 10.18, p = .002. 
# Version A users clicked more frequently on average.


# Logistic Regression
df$calendar_added <- factor(ifelse(df$calendar_adds > 0, "yes", "no"))

logit_model <- glm(calendar_added ~ event_clicks + session_duration + 
                     AI_chat_messages_sent + AI_suggestions_requested + version,
                   data = df, family = binomial)
summary(logit_model)

# Logistic regression showed that Version B significantly increased the odds 
# of a calendar add by approximately 3.3 times (p = .060), 
# controlling for user behavior. Additionally, 
# each AI suggestion requested increased the odds by 2.18 times (p ≈ .081), 
# indicating AI recommendation engagement was meaningful.


# Odds Ratio
exp(coef(logit_model))

# Predicted Probabilities
df$predicted_prob <- predict(logit_model, type = "response")

ggplot(df, aes(x = version, y = predicted_prob)) +
  geom_boxplot(fill = c("#cce5ff", "#ffd6cc")) +
  labs(title = "Predicted Probability of Calendar Add by Version", y = "Predicted Probability") +
  theme_minimal()

# The prediction probability of group B was significantly higher overall.
# Be consistent with the actual conversion rate;
# The predicted probability of adding events was consistently higher in Version B across users, 
# indicating that the model also confirms a real behavioral shift between groups.



# PCA
pca_data <- df %>%
  select(event_clicks, calendar_adds, session_duration, AI_chat_messages_sent, AI_suggestions_requested)

pca_result <- prcomp(pca_data, scale. = TRUE)
summary(pca_result)
biplot(pca_result, scale = 0, cex = 0.6)

# Principal component analysis revealed that user behaviors such as event clicks, 
# calendar additions, and AI suggestions loaded strongly onto the first principal component. 
# This suggests that these variables form a shared engagement 
# dimension across interface versions.

# PCA analysis revealed that behavioral features like event_clicks and 
# AI usage align strongly with the first principal component, 
# showing these metrics collectively define user engagement.




# EDA 

# Missing Value Summary 
cat("\nMissing Values per Column:\n")
print(colSums(is.na(df)))

# Histograms
ggplot(df, aes(x = session_duration, fill = version)) +
  geom_histogram(binwidth = 10, position = "identity", alpha = 0.6) +
  labs(title = "Session Duration Distribution", x = "Duration (seconds)", y = "Count") +
  theme_minimal()

ggplot(df, aes(x = event_clicks, fill = version)) +
  geom_histogram(binwidth = 1, position = "identity", alpha = 0.6) +
  labs(title = "Event Clicks Distribution", x = "Event Clicks", y = "Count") +
  theme_minimal()

# Version A: Slightly to the right and more dispersed in distribution;
# Version B: Slightly to the left, with relatively concentrated behavior.
# Conclusion: The behaviors of users in Group A are more discrete, 
# while those in Group B are more concentrated in the "less and more" mode.

# Group A has more dispersed clicks and longer session duration;
# Group B is more concentrated on medium and low clicks but has a higher conversion rate.
# Corresponding to the previous conclusion;

# Version A users were more exploratory, 
# while Version B users were more efficient—interacting less but converting more.



# Correlation Matrix
numeric_vars <- df %>% select(where(is.numeric))
cor_matrix <- cor(numeric_vars, use = "pairwise.complete.obs")
corrplot(cor_matrix, method = "circle", type = "upper", tl.cex = 0.8,
         addCoef.col = "black", number.cex = 0.7,
         title = "Correlation Matrix", mar = c(0, 0, 1, 0))

# Engagement-related variables such as event clicks and conversion rate 
# were positively correlated (r ≈ .60), 
# confirming expected behavioral relationships. 
# Predicted probability from the logistic model also aligned well with actual conversion.

# conversion_rate and event_clicks: r ≈ 0.6;
# predicted_prob has a moderately positive correlation with conversion_rate.
# session_duration has a weak correlation with other variables;

# Event clicks and conversion rate are highly correlated, 
# confirming that clicks are meaningful user intent. 
# AI metrics showed weaker correlation.




# Scatter Plot
ggplot(df, aes(x = event_clicks, y = session_duration, color = version)) +
  geom_point(alpha = 0.7) +
  labs(title = "Event Clicks vs Session Duration", x = "Event Clicks", y = "Session Duration") +
  theme_minimal()

# Scatter plots support a weak positive correlation between event_clicks and session_duration.

# Weak correlation, no obvious aggregation;
# High-click-through users sometimes have short sessions (quick browsing);

# The relationship between clicking and session duration is weak, 
# suggesting different browsing styles—some users explore deeply, others act quickly.




# Decision Tree
tree_model <- rpart(calendar_added ~ event_clicks + session_duration +
                      AI_chat_messages_sent + AI_suggestions_requested + version,
                    data = df, method = "class")

rpart.plot(tree_model, extra = 104, fallen.leaves = TRUE,
           main = "Decision Tree: Predicting Calendar Add")

# The decision tree revealed that the number of event clicks was 
# the most influential factor in determining whether a user added an event. 
# Additionally, Version B and longer session durations further 
# improved the likelihood of calendar interaction.

# event_clicks is the root split variable;
# versionB appears in the path and the split is valid.
# session_duration also has a certain influence;

# Decision tree models show that calendar addition is primarily driven by event clicks, 
# followed by session duration and interface version. This validates the experimental design.
