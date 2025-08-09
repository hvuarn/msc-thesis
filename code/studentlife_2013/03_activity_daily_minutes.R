# ===================================================
# StudentLife: activity data - subsampling & activity duration 
# ===================================================

rm(list = ls())
gc()

# load libraries
library(dplyr)
library(readr)
library(lubridate)
library(glue)
library(ggplot2)

# define paths
data_path <- "data/studentlife_2013/preprocessed/sensing/activity"
save_path <- "data/studentlife_2013/preprocessed/sensing/activity"
save_plot_path <- "data/studentlife_2013/preprocessed/sensing/activity/plots"

# create directories if needed
if (!dir.exists(save_plot_path)) dir.create(save_plot_path, recursive = TRUE)

# load cleaned data
time_bounds <- readRDS(file.path(data_path, "time_bounds.rds"))
activity_clean <- readRDS(file.path(data_path, "activity_clean.rds"))

# ================================================
# filter and enrich
# ================================================

# activity as described in https://studentlife.cs.dartmouth.edu/datasets.html : 
# 0 = stationary
# 1 = walking 
# 2 = running
# 3 = unknown -> we remove this

activity_clean <- activity_clean %>%
	filter(activity.inference != 3) %>%  # remove unknown activity (3)
	mutate(
		hour = hour(timestamp),
		day = as.Date(timestamp),
		active_binary = ifelse(activity.inference %in% c(1, 2), 1, 0)
	)

# summaries
summary(activity_clean$activity.inference)
hist(activity_clean$activity.inference)
hist(activity_clean$active_binary)


# -------------------------------------------
# daily active bins: threshold-based (Wang et al. 2014)
# -------------------------------------------
# Wang et al. 2014, p.4: "We are only interested in determining 
# whether a participant is moving. For each 10-min period, we calculate the 
# ratio of non-stationary inferences. If the ratio is greater than a threshold, 
# we consider this period active, meaning that the user is moving. We add up all 
# the 10-min active periods as the daily activity duration."

# define 10-min window size
window_size <- 600  # 10 minutes

# use same min/max time from cleaning
min_time <- min(activity_clean$timestamp)
max_time <- max(activity_clean$timestamp)

# assign each row to a 10-min window
activity_clean <- activity_clean %>%
	mutate(window_start = floor(as.numeric(timestamp) / window_size) * window_size)

# compute active ratio per window
# each 10 min window gets assigned to a day
activity_daily_summary <- activity_clean %>%
	group_by(uid, window_start) %>%
	summarize(active_ratio = mean(active_binary), .groups = "drop") %>%
	mutate(
		active_window = ifelse(active_ratio > 0.5, 1, 0),
		time_norm_window = (window_start - as.numeric(min_time)) / (as.numeric(max_time) - as.numeric(min_time)),
		day = as.Date(as.POSIXct(window_start, origin = "1970-01-01", tz = "UTC"))
	)

# compute total daily active minutes
activity_daily <- activity_daily_summary %>%
	group_by(uid, day) %>%
	summarize(
		active_minutes = sum(active_window) * 10,
		.start_norm = min(time_norm_window),  # first time bin of the day (normalized)
		.end_norm = max(time_norm_window),    # last time bin of the day (normalized)
		.groups = "drop"
	)


# ===================================================
# outlier handling and user filtering (corrected)
# ===================================================

# ---- cap raw minutes FIRST -------------------------------------------
activity_daily <- activity_daily %>% 
	mutate(active_minutes = pmin(active_minutes, 500)) # 500 min (8.3h)

# 1. Remove outlier days based on the 1.5*IQR rule
q1 <- quantile(activity_daily$active_minutes, 0.25, na.rm = TRUE)
q3 <- quantile(activity_daily$active_minutes, 0.75, na.rm = TRUE)
iqr <- q3 - q1
upper_bound <- q3 + 1.5 * iqr

activity_daily_filtered <- activity_daily %>%
	filter(active_minutes <= upper_bound)

message(glue("Removed {nrow(activity_daily) - nrow(activity_daily_filtered)} outlier days from the data."))

# 2. Filter out any users with fewer than 4 remaining observations
activity_daily_final <- activity_daily_filtered %>%
	group_by(uid) %>%
	filter(n() >= 4) %>%
	ungroup()

n_users_before <- n_distinct(activity_daily_filtered$uid)
n_users_after <- n_distinct(activity_daily_final$uid)
message(glue("Removed {n_users_before - n_users_after} users with fewer than 4 days of data."))

# clean data frame for the next steps
activity_daily <- activity_daily_final

boxplot(activity_daily$active_minutes)
summary(activity_daily$active_minutes)


# ===================================================
# response normalization (between-subject)
# ===================================================

# compute global min and max
min_val <- min(activity_daily$active_minutes, na.rm = TRUE)
max_val <- max(activity_daily$active_minutes, na.rm = TRUE)

# normalize globally
activity_daily <- activity_daily %>%
	dplyr::select(uid, day, active_minutes, .start_norm, .end_norm) %>%
	mutate(active_scaled = (active_minutes - min_val) / (max_val - min_val))

# --------------------------------
# preview results
head(activity_daily)
summary(activity_daily$active_minutes)
hist(activity_daily$active_minutes)

# plot activity duration per day in global normalized time
ggplot(activity_daily, aes(x = .start_norm, y = active_minutes, color = as.factor(uid))) +
	geom_point() +
	geom_line(aes(group = uid), alpha = 0.5) +
	theme_bw() +
	scale_y_continuous(name = "active minutes (daily)") +
	scale_x_continuous(name = "normalized time") +
	guides(color = "none") +
	ggtitle("daily active minutes")


# how many unique calender days?
n_distinct(activity_daily$day)

sum(activity_daily$active_scaled)
boxplot(activity_daily$active_scaled)
# ===================================================
# prep for ghcm format
# ===================================================

# assign .obs id for each uid
uid_map <- activity_daily %>%
	distinct(uid) %>%
	mutate(.obs = row_number())

activity_daily <- activity_daily %>%
	left_join(uid_map, by = "uid")

# prepare for plotting + ghcm format
activity_daily_plot <- activity_daily %>%
	mutate(subsampled = TRUE) %>%
	dplyr::select(.obs, .index = .start_norm, .value = active_scaled, subsampled) # changed to active_scaled!!


# ===================================================
# plots
# ===================================================
# plot for first 5 students
plot_01 <- ggplot(activity_daily_plot %>% filter(.obs <= 5), aes(x = .index, y = .value, color = as.factor(.obs))) +
	geom_point(aes(shape = subsampled, size = subsampled)) +
	geom_line(alpha = 0.7) +
	scale_size_manual(values = c(0.7, 2)) +
	guides(color = "none", size = "none", shape = "none") +
	scale_x_continuous(name = "Normalized time") +
	scale_y_continuous(name = "Normalized daily active minutes") +
	theme_bw()
ggsave(file.path(save_plot_path, "plot_01.pdf"), plot = plot_01, width = 7, height = 4)

# combined plot
highlight_ids <- c(1, 2, 3, 4, 5) # highlight first five
plot_03 <- ggplot(activity_daily_plot, aes(x = .index, y = .value, group = .obs)) +
	geom_line(color = "grey85", alpha = 0.3) +
	geom_line(data = . %>% filter(.obs %in% highlight_ids), aes(color = as.factor(.obs)), linewidth = 0.5) +
	geom_point(data = . %>% filter(.obs %in% highlight_ids), aes(color = as.factor(.obs)), size = 0.7) +
	theme_bw() +
	guides(color = "none") +
	labs(x = "Normalized time", y = "Normalized daily active minutes")
ggsave(file.path(save_plot_path, "plot_03.pdf"), plot = plot_03, width = 7, height = 4)

# plot all
plot_02 <- ggplot(activity_daily_plot, aes(x = .index, y = .value, color = as.factor(.obs))) +
	geom_point(aes(shape = subsampled, size = subsampled)) +
	geom_line(alpha = 0.3) +
	scale_size_manual(values = c(0.5, 2)) +
	guides(color = "none", size = "none", shape = "none") +
	scale_x_continuous(name = "Normalized time") +
	scale_y_continuous(name = "Normalized daily activity") +
	theme_bw()
ggsave(file.path(save_plot_path, "plot_02.pdf"), plot = plot_02, width = 7, height = 4)


# reuse for ghcm input
activity_daily_long <- activity_daily_plot %>%
	select(.obs, .index, .value)

str(activity_daily)
str(activity_daily_plot)

# structure as needed for ghcm
str(activity_daily_long)
n_obs <- n_distinct(activity_daily_long$.obs)
message(glue("saved long-format data with {n_obs} observations"))


# ===================================================
# save outputs
# ===================================================
write.csv(activity_daily, file.path(save_path, "activity_daily.csv"), row.names = FALSE)
saveRDS(activity_daily, file.path(save_path, "activity_daily.rds"))

write.csv(activity_daily_plot, file.path(save_path, "activity_daily_plot.csv"), row.names = FALSE)
saveRDS(activity_daily_plot, file.path(save_path, "activity_daily_plot.rds"))

write.csv(activity_daily_long, file.path(save_path, "activity_daily_long.csv"), row.names = FALSE)
saveRDS(activity_daily_long, file.path(save_path, "activity_daily_long.rds"))

# extract and save uid → .obs mapping (RDS only)
uid_map <- activity_daily %>% distinct(uid, .obs)
saveRDS(uid_map, file.path(save_path, "uid_map.rds"))

