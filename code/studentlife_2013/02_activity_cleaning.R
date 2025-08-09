# ================================================================= 
# StudentLife 2013: Activity data cleaning & normalization
# ================================================================= 
#
# Description:
# This script loads raw activity data for each user, removes
# duplicates, and normalizes timestamps for further analysis.
#
# Expected file structure:
# .
# ├── msc-thesis-public.Rproj
# └── data/
#     └── studentlife_2013/
#         └── raw/
# ================================================================= 

rm(list = ls())
gc()

# load libraries
library(dplyr)
library(lubridate)
library(purrr)
library(readr)
library(glue)

# define relative paths to data
# (note: the original StudentLife dataset folder was renamed to "raw" for clarity)
data_path <- "data/studentlife_2013/raw/dataset/sensing/activity"
save_path <- "data/studentlife_2013/preprocessed/sensing/activity"


# create directories if needed
if (!dir.exists(save_path)) dir.create(save_path, recursive = TRUE)

# list all activity csv files
file_list <- list.files(path = data_path, pattern = "activity_u.*\\.csv", full.names = TRUE)

# =====================
# load and combine all activity data
# =====================
df_raw <- purrr::map_dfr(file_list, function(file_path) {
	df <- read_csv(file_path, show_col_types = FALSE)
	colnames(df) <- c("timestamp", "activity.inference")
	df$timestamp <- as.POSIXct(df$timestamp, origin = "1970-01-01", tz = "UTC")
	df$uid <- gsub(".*activity_(u[0-9]+)\\.csv", "\\1", basename(file_path))
	return(df)
})

# =====================
# clean data
# =====================

# 1. remove exact duplicate rows
df_distinct <- df_raw %>% distinct()

# 2. collapse duplicate timestamps per user (choose max activity level)
df_clean <- df_distinct %>%
	group_by(uid, timestamp) %>%
	summarize(activity.inference = max(activity.inference), .groups = "drop")

# summary
n_all <- nrow(df_raw)
n_distinct <- nrow(df_distinct)
n_clean <- nrow(df_clean)
n_rowdup <- n_all - n_distinct
n_timedup <- n_distinct - n_clean
n_totaldup <- n_all - n_clean

message(glue("row duplicates: {n_rowdup}, timestamp duplicates: {n_timedup}, total removed: {n_totaldup} (from {n_all} → {n_clean})"))

# =====================
# normalize timestamps globally
# =====================
min_time <- min(df_clean$timestamp, na.rm = TRUE)
max_time <- max(df_clean$timestamp, na.rm = TRUE)
time_bounds <- list(min_time = min_time, max_time = max_time)

df_clean <- df_clean %>%
	mutate(time_norm = (as.numeric(timestamp) - as.numeric(min_time)) /
				 	(as.numeric(max_time) - as.numeric(min_time))) %>%
	select(uid, timestamp, time_norm, activity.inference)

# =====================
# save cleaned dataset
# =====================
# this will take a while!
saveRDS(time_bounds, file.path(save_path, "time_bounds.rds")) #save minmax time
write.csv(df_clean, file.path(save_path, "activity_clean.csv"), row.names = FALSE)
saveRDS(df_clean, file.path(save_path, "activity_clean.rds"))

message(glue("Cleaned activity data saved with {n_clean} rows."))

