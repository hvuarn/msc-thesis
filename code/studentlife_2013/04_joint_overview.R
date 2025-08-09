# ===================================================
# StudentLife: overview before ghcm
# ===================================================

rm(list = ls())
gc()

# load libraries
library(dplyr)
library(readr)

# Ensure the directory exists; create if missing
save_path <- "data/studentlife_2013/preprocessed/joint"
if (!dir.exists(save_path)) {dir.create(save_path, recursive = TRUE)}

# load data
activity <- readRDS("data/studentlife_2013/preprocessed/sensing/activity/activity_daily.rds")
activity_long <- readRDS("data/studentlife_2013/preprocessed/sensing/activity/activity_daily_long.rds")
phq9 <- readRDS("data/studentlife_2013/preprocessed/phq9/phq9_wide.rds") %>% 
	dplyr::select(uid, phq9_post, phq9_pre) #phq_wide.rds where is script?

# summarize activity per user
activity_summary <- activity_long %>%
	group_by(.obs) %>%
	summarize(
		activity_mean = mean(.value, na.rm = TRUE),
		activity_max = max(.value, na.rm = TRUE),
		activity_sd = sd(.value, na.rm = TRUE),
		.groups = "drop"
	)

# join everything by uid / .obs
overview <- activity %>%
	distinct(uid, .obs) %>%
	left_join(phq9, by = "uid") %>%
	left_join(activity_summary, by = ".obs") %>%
	arrange(.obs)

# optional: print summary
print(overview, n = Inf)

# correlation (complete obs only)
cor(overview$phq9_post, overview$activity_mean, use = "complete.obs")

# filter complete cases (based on estimand: phq9_post)
overview_complete <- overview %>% filter(!is.na(phq9_post))
overview_complete %>% print(n =Inf)

# subset long activity for complete users
activity_filtered <- activity_long %>% filter(.obs %in% overview_complete$.obs)

# check final counts
nrow(overview_complete)
n_distinct(activity_filtered$.obs)

str(overview_complete)
str(activity_filtered)

# check mapping
overview_complete %>% dplyr::select(uid, .obs) %>% arrange(.obs)
activity_filtered %>% distinct(.obs) %>%
	left_join(overview_complete %>% dplyr::select(uid, .obs), by = ".obs")


# optional: save
saveRDS(overview_complete, "data/studentlife_2013/preprocessed/joint/overview_complete.rds")
saveRDS(activity_filtered, "data/studentlife_2013/preprocessed/joint/activity_filtered.rds")

