# ================================================================= 
# StudentLife 2013: Exploratory data analysis (EDA) of PHQ-9
# ================================================================= 

# Description:
# This script loads, cleans, and performs an initial exploratory analysis 
# on the PHQ-9 survey data from the StudentLife 2013 dataset.
#
# Expected file structure:
# .
# ├── msc-thesis-public.Rproj
# └── data/
#     └── studentlife_2013/
#         └── raw/						# was renamed to "raw" for clarity
# ==================================================================

rm(list = ls())
gc()

# Load libraries
library(dplyr)      
library(readr)      
library(tidyr) 
library(ggplot2)    
library(ggmice)    
library(mice)       
library(visdat)     
library(gridExtra) 
library(raincloudplots)
library(patchwork)
library(xtable)

# ===================================================
#  Load PHQ-9 data
# ===================================================

# define relative paths to data
data_path <- "data/studentlife_2013/raw/dataset/survey"
save_path <- "data/studentlife_2013/preprocessed/phq9"

# make sure directory exists; create if missing
if (!dir.exists(save_path)) {dir.create(save_path, recursive = TRUE)}

# Load the data
phq9 <- read.csv(file.path(data_path, "PHQ-9.csv"))

# check column names to verify structure
colnames(phq9)

# extract question columns dynamically (excluding uid, type, Response)
question_cols <- setdiff(names(phq9), c("uid", "type", "Response"))  

# generate q1, q2, ..., q9 dynamically
new_names <- paste0("q", seq_along(question_cols))  

# rename the questions and rename "Response" to "q10"
phq9 <- phq9 %>%
	rename_with(~ new_names, all_of(question_cols)) %>%
	rename(q10 = Response)  

# mapping for PHQ-9 responses (q1 to q9)
phq9_score_map <- c("Not at all" = 0, "Several days" = 1, "More than half the days" = 2, "Nearly every day" = 3)

# mapping for functional impairment (q10)
q10_map <- c("Not difficult at all" = 0, "Somewhat difficult" = 1, "Very difficult" = 2, "Extremely difficult" = 3)

# convert PHQ-9 answers and functional impairment
phq9 <- phq9 %>%
	mutate(across(q1:q9, ~ recode(., !!!phq9_score_map, .default = NA_real_))) %>%
	mutate(q10 = recode(q10, !!!q10_map, .default = NA_real_)) 


# ===================================================
# Compute total PHQ-9 score
# ===================================================
phq9 <- phq9 %>%
	rowwise() %>%
	mutate(phq9_score = sum(c_across(q1:q9), na.rm = TRUE)) %>%
	ungroup()

head(phq9)

# separate pre and post data
phq9_pre <- phq9 %>%
	filter(type == "pre") %>%
	dplyr::select(uid, phq9_score, q10) %>%
	rename(phq9_pre = phq9_score, q10_pre = q10)

phq9_post <- phq9 %>%
	filter(type == "post") %>%
	dplyr::select(uid, phq9_score, q10) %>%
	rename(phq9_post = phq9_score, q10_post = q10)

# merge pre and post data
phq9_wide <- full_join(phq9_pre, phq9_post, by = "uid") %>%
	dplyr::select(uid, phq9_pre, phq9_post) # we only need phq9

# ===================================================
# Data exploration
# ===================================================
head(phq9_wide)
summary(phq9_wide$phq9_pre)
summary(phq9_wide$phq9_post)

# Severity thresholds follow standard interpretation bands: minimal (0--4), mild (5--9), moderate (10--14), moderately severe (15--19), and severe (20--27).

#---------------------------------------------------
# 1. xtable for baseline!
phq9_baseline_summary <- phq9_wide %>%
	filter(!is.na(phq9_pre)) %>% # Ensure we only count participants with baseline scores
	mutate(
		severity_category = cut(
			phq9_pre,
			breaks = c(-Inf, 4, 9, 14, 19, Inf),
			labels = c("minimal (0-4)", "mild (5-9)", "moderate (10-14)", 
								 "moderately severe (15-19)", "severe (20-27)"),
			right = TRUE 
		)
	)

# frequencies and percentage
phq9_freq_table <- phq9_baseline_summary %>%
	count(severity_category, name = "n") %>%
	mutate(Percentage = paste0(round(n / sum(n) * 100, 1), "%")) %>% 
	rename(`Severity Category` = severity_category)

print(xtable(phq9_freq_table,
		caption = "Distribution of baseline PHQ-9 severity for the StudentLife 2013 sample.",
		label = "tab:phq9_dist",
		align = c("l", "l", "c", "c") 
	),
	caption.placement = "top",
	include.rownames = FALSE,
	booktabs = TRUE # nicer lines
)

#---------------------------------------------------
# 2. xtable for baseline & follow-up!
severity_breaks <- c(-Inf, 4, 9, 14, 19, Inf)
severity_labels <- c("Minimal (0–4)", "Mild (5–9)", "Moderate (10–14)", 
										 "Moderately severe (15–19)", "Severe (20–27)")

baseline_summary <- phq9_wide %>%
	filter(!is.na(phq9_pre)) %>%
	mutate(category = cut(phq9_pre, breaks = severity_breaks, labels = severity_labels)) %>%
	count(category) %>%
	mutate(Baseline = paste0(n, " (", round(n / sum(n) * 100, 1), "%)")) %>%
	dplyr::select(category, Baseline)

followup_summary <- phq9_wide %>%
	filter(!is.na(phq9_post)) %>%
	mutate(category = cut(phq9_post, breaks = severity_breaks, labels = severity_labels)) %>%
	count(category) %>%
	mutate(`Follow-up` = paste0(n, " (", round(n / sum(n) * 100, 1), "%)")) %>%
	dplyr::select(category, `Follow-up`)

final_table <- full_join(baseline_summary, followup_summary, by = "category") %>%
	replace_na(list(Baseline = "-", `Follow-up` = "-"))


n_total <- nrow(phq9_wide)
n_missing_pre <- sum(is.na(phq9_wide$phq9_pre))
n_missing_post <- sum(is.na(phq9_wide$phq9_post))

baseline_header <- paste0("Baseline ($n=", n_total - n_missing_pre, ")")
followup_header <- paste0("Follow-up ($n=", n_total - n_missing_post, ")")
colnames(final_table) <- c("Severity category", baseline_header, followup_header)

print(xtable(final_table,
				 caption = "Distribution of PHQ-9 severity categories at baseline and follow-up.",
				 label = "tab:phq9_dist_summary",
				 align = c("l", "l", "r", "r")  
	),
	caption.placement = "top",
	include.rownames = FALSE,
	booktabs = TRUE
)

# ===================================================
# missing values
vis_miss(phq9_wide)

# for trend we need long format again
# convert 'type' to a factor for ordered plotting
phq9 <- phq9 %>%
	mutate(type = factor(type, levels = c("pre", "post"), labels = c("pre", "post")))


## ====== inital plots ======
# individual trends
ggplot(phq9, aes(x = type, y = phq9_score, group = uid)) +
	geom_line(aes(color = uid), alpha = 0.5, linewidth = 0.8) +  
	geom_point(aes(color = uid), size = 1.5) +  
	labs(x = "timepoint", y = "PHQ-9") +
	theme_minimal() +
	theme(legend.position = "none") 

# boxplot
ggplot(phq9, aes(x = type, y = phq9_score, fill = type)) + 
	geom_jitter(aes(color = type), width = 0.1, alpha = 0.5, size = 1.5) + 
	geom_boxplot(width = 0.1, color = "black", alpha = 0.7, outlier.shape = NA) + 
	labs(x = "Timepoint", y = "PHQ-9") + 
	theme_minimal() +
	theme(legend.position = "none") 


## ====== severity thresholds ======
# minimal (0--4), mild (5--9), moderate (10--14), moderately severe (15--19), and severe (20--27).

#------------------------ 
# facet by time
phq9_facet <- phq9_wide %>%
	drop_na(phq9_pre, phq9_post) %>%
	pivot_longer(cols = c(phq9_pre, phq9_post), names_to = "timepoint", values_to = "score") %>%
	mutate(
		timepoint = factor(timepoint, levels = c("phq9_pre", "phq9_post"), labels = c("baseline", "follow-up")),
		phq9_cat = cut(
			score,  
			breaks = c(-Inf, 4, 9, 14, 19, Inf),
			labels = c("minimal", "mild", "moderate", "mod. severe", "severe")
		)
	)

ggplot(phq9_facet, aes(x = phq9_cat, y = score, fill = phq9_cat)) +
	geom_boxplot(width = 0.6, alpha = 0.7, color = "black", outlier.shape = NA) +
	geom_jitter(width = 0.1, alpha = 0.4, size = 1.5) +
	facet_wrap(~ timepoint) +
	labs(x = "Severity", y = "PHQ-9") +
	scale_fill_brewer(palette = "Set2") +
	theme_bw() +
	theme(panel.grid.minor = element_blank(), legend.position = "none")

#------------------------ 
## outcome-based grouping!
phq9_facet <- phq9_wide %>%
	drop_na(phq9_pre, phq9_post) %>%
	mutate(
		phq9_cat = cut(
			phq9_post,  # <- outcome-based grouping!
			breaks = c(-Inf, 4, 9, 14, 19, Inf),
			labels = c("Minimal", "Mild", "Mod.", "Mod. severe", "Severe")
		)
	) %>%
	pivot_longer(
		cols = c(phq9_pre, phq9_post),
		names_to = "timepoint",
		values_to = "score"
	) %>%
	mutate(
		timepoint = factor(timepoint, levels = c("phq9_pre", "phq9_post"), labels = c("Baseline", "Follow-up"))
	)

plot_01 <- ggplot(phq9_facet, aes(x = phq9_cat, y = score, fill = phq9_cat)) +
	geom_boxplot(width = 0.6, alpha = 0.7, color = "black", outlier.shape = NA, linewidth = 0.3) +
	geom_jitter(width = 0.1, alpha = 0.4, size = 1) +
	facet_wrap(~ timepoint) +
	labs(x = "Severity", y = "PHQ-9") + # severity grouping based on follow up!!
	scale_fill_brewer(palette = "Set2") +
	theme_bw() +
	theme(panel.grid.minor = element_blank(), legend.position = "none")
print(plot_01)
ggsave(file.path(save_path, "plot_01.pdf"), plot = plot_01, width = 7, height = 4)

## ====== raincloud plots ======
# prepare data for 1×1 repeated measures (pre vs post)
df_1x1 <- data_1x1(
	array_1 = phq9_wide$phq9_pre,
	array_2 = phq9_wide$phq9_post,
	jit_distance = 0.09,
	jit_seed = 321
)

# raincloud plot
plot_02 <- raincloud_1x1_repmes(
	data = df_1x1,
	colors = c("dodgerblue", "darkorange"),
	fills = c("dodgerblue", "darkorange"),
	line_color = "gray",
	line_alpha = 0.3,
	size = 1,
	alpha = 0.6,
	align_clouds = FALSE
) +
	scale_x_continuous(breaks = c(1, 2), labels = c("Baseline", "Follow-up"), limits = c(0, 3)) +
	xlab("Timepoint") +
	ylab("PHQ-9") +
	theme_classic()
plot_02
ggsave(file.path(save_path, "plot_02.pdf"), plot = plot_02, width = 7, height = 4)


# ===================================================
# ECDF, histogram
# ===================================================
phq9_long <- phq9_wide %>%
	drop_na(phq9_pre, phq9_post) %>%
	pivot_longer(cols = c(phq9_pre, phq9_post), names_to = "timepoint", values_to = "phq9_score") %>%
	mutate(timepoint = factor(timepoint, levels = c("phq9_pre", "phq9_post"), labels = c("baseline", "follow-up")))

ggplot(phq9_long, aes(x = phq9_score, color = timepoint)) +
	stat_ecdf(size = 0.5) +
	labs(title = "ECDF of PHQ-9 scores", x = "PHQ-9 score", y = "ECDF") +
	theme_minimal() +
	theme(legend.title = element_blank())

ggplot(phq9_long, aes(x = phq9_score)) +
	geom_histogram(aes(y = after_stat(density)), binwidth = 2, fill = "gray", color = "black", alpha = 0.6) +
	geom_density(color = "red", linetype = "dashed", size = 1) +
	facet_wrap(~ timepoint) +
	labs(x = "PHQ-9", y = "Density") +
	theme_minimal()

# ===================================================
# save
# ===================================================
saveRDS(phq9_wide, file.path(save_path, "phq9_wide.rds"))


# normalize phq9_pre and phq9_post to [0, 1]
phq9_range <- range(c(phq9_wide$phq9_pre, phq9_wide$phq9_post), na.rm = TRUE)
phq9_min <- phq9_range[1]
phq9_max <- phq9_range[2]

phq9_wide <- phq9_wide %>%
	mutate(
		phq9_pre_norm = (phq9_pre - phq9_min) / (phq9_max - phq9_min),
		phq9_post_norm = (phq9_post - phq9_min) / (phq9_max - phq9_min)
	)
saveRDS(phq9_wide, file.path(save_path, "phq9_wide_normalized.rds"))



