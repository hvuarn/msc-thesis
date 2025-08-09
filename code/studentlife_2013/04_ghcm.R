# ===================================================
# GHCM Test: Is activity (X) ⫫ phq9_post (Y) | phq9_pre (Z)?
# ===================================================

rm(list = ls())
gc()

# -------------------------------------------
# libraries
# -------------------------------------------
library(readr)
library(mgcv)
library(ghcm)
library(refund)
library(dplyr)
library(comets)
library(biostatUZH)
library(purrr)
library(furrr)

# -------------------------------------------
# load data
# -------------------------------------------
activity_long <- readRDS("data/studentlife_2013/preprocessed/joint/activity_filtered.rds")
overview <- readRDS("data/studentlife_2013/preprocessed/joint/overview_complete.rds")

save_path <- "data/studentlife_2013/preprocessed/results/analysis_01"
if (!dir.exists(save_path)) {dir.create(save_path, recursive = TRUE)}
# -------------------------------------------
# filter complete cases for phq9_pre and phq9_post
# -------------------------------------------
overview_clean <- overview %>%
	filter(!is.na(phq9_pre), !is.na(phq9_post))

# -------------------------------------------
# build obs index mapping (needed by pffr)
# -------------------------------------------
obs_map <- overview_clean %>%
	arrange(.obs) %>%
	mutate(obs_index = row_number()) %>%
	dplyr::select(.obs, obs_index)

# -------------------------------------------
# fix activity data to use consecutive .obs indices
# -------------------------------------------
activity_fixed <- activity_long %>%
	inner_join(obs_map, by = ".obs") %>%
	dplyr::select(.obs = obs_index, .index, .value)

# -------------------------------------------
# fix overview and set rownames for pffr
# -------------------------------------------
overview_fixed <- overview_clean %>%
	inner_join(obs_map, by = ".obs") %>%
	arrange(obs_index)

overview_df <- as.data.frame(overview_fixed)
rownames(overview_df) <- overview_fixed$obs_index

# -------------------------------------------
# scalar model: Y ~ Z
# -------------------------------------------
model_Y <- gam(phq9_post ~ s(phq9_pre), data = overview_fixed) # s() makes smooth, to capture smooth nonlinear ; family = "poisson"
resid_Y <- resid(model_Y)
# -------------------------------------------
# function on scalar model: X ~ Z
# -------------------------------------------
model_X <- pffr(
	.value ~ s(phq9_pre), #also add smooth term s()!
	ydata = activity_fixed,
	data = overview_df,
)
head(activity_fixed)
resid_X <- residuals(model_X)
resid_Y <- residuals(model_Y)

unique(residuals(model_X)$.obs)
length(residuals(model_Y))
# -------------------------------------------
# GHCM test: X ⫫ Y | Z
# -------------------------------------------
X_limits <- range(activity_fixed$.index)

ghcm_result <- ghcm_test(
	resid_X,
	resid_Y,
	X_limits = X_limits
)

print.default(ghcm_result) #activity does not explain more than phq9 pre!
saveRDS(ghcm_result, file = file.path(save_path, "ghcm_result.rds"))

ghcm_summary <- list( 
	test_statistic = round(ghcm_result$test_statistic, 3),
	p_value = round(ghcm_result$p, 3),
	alpha = ghcm_result$alpha,
	reject = ghcm_result$reject
)
saveRDS(ghcm_summary, file = file.path(save_path, "ghcm_summary.rds"))
# -------------------------------------------
# save results for diagnostics 

# save scalar model: Y ~ Z
saveRDS(model_Y, file = file.path(save_path, "model_Y.rds"))

# save function-on-scalar model: X ~ Z
saveRDS(model_X, file = file.path(save_path, "model_X.rds"))

# -------------------------------------------
# diagnostics
# run dev.off() if plot not showing in window!

# scalar model: Y ~ Z
summary(model_Y) 
plot(model_Y)
gam.check(model_Y)

# save gam plot
pdf(file.path(save_path, "gam_plot.pdf"), width = 7, height = 5)
plot(model_Y, residuals = TRUE, se = TRUE)  # or whatever settings you want
dev.off()

# save gam check
pdf(file.path(save_path, "gam_check.pdf"), width = 7, height = 5)
par(mfrow = c(2, 2))            # 2 rows, 2 columns
gam.check(model_Y, pages = 0)   # page = 0 means: don't page, just plot them all
dev.off()


# function on scalar model: X ~ Z
summary(model_X) 

# pffr plot
pdf(file.path(save_path, "pffr_plot.pdf"), width = 7, height = 5)
plot(model_X, pages = 0)  # both plots seperately
dev.off()

# pffr check
pdf(file.path(save_path, "pffr_check.pdf"), width = 7, height = 5)
par(mfrow = c(2, 2))     
pffr.check(model_X, pages = 0)  # default pages=1 shows all plots
dev.off()

# --------------------------------
# bootstrap GHCM test


# prepare input for bootstrap
Z_df <- overview_fixed %>%
	dplyr::select(obs_index, phq9_pre) %>%
	as.data.frame()
rownames(Z_df) <- Z_df$obs_index

Y_df <- overview_fixed %>%
	dplyr::select(obs_index, phq9_post)

X_fixed <- activity_fixed  # already matched and relabeled

# -------------------------------------------
# note: no need to run this if already saved
# set up
set.seed(123)
plan(multisession)

# bootstrap function
bootstrap_ghcm <- function(i) {
	obs_ids <- sample(seq_len(nrow(Z_df)), replace = TRUE)
	
	# sampled obs from Z_df
	sampled_obs <- as.integer(rownames(Z_df)[obs_ids])
	
	# deduplicated obs map
	obs_map <- data.frame(.obs = sampled_obs) %>%
		dplyr::distinct(.obs, .keep_all = TRUE) %>%
		dplyr::mutate(obs_index = row_number())
	
	# fix Z
	Zb <- Z_df[as.character(obs_map$.obs), , drop = FALSE]
	Zb$obs_index <- obs_map$obs_index
	rownames(Zb) <- Zb$obs_index
	
	# fix X
	Xb <- X_fixed %>%
		dplyr::inner_join(obs_map, by = ".obs") %>%
		dplyr::select(.obs = obs_index, .index, .value)
	
	# fix Y
	Yb <- Y_df %>%
		dplyr::inner_join(obs_map, by = c("obs_index" = ".obs")) %>%
		dplyr::arrange(obs_index) %>%
		dplyr::pull(phq9_post)
	
	# models
	model_Xb <- pffr(.value ~ phq9_pre, ydata = Xb, data = Zb)
	resid_Xb <- residuals(model_Xb)
	
	model_Yb <- tryCatch(
		gam(Yb ~ s(Zb$phq9_pre)),
		error = function(e) lm(Yb ~ Zb$phq9_pre)
	)
	resid_Yb <- resid(model_Yb)
	
	ghcm_test(resid_Xb, resid_Yb, X_limits = range(Xb$.index))$p
}

B <- 100
p_values <- future_map_dbl(1:B, bootstrap_ghcm, .options = furrr_options(seed = TRUE))
saveRDS(p_values, file = file.path(save_path, glue::glue("p_values_B{B}.rds")))

# -------------------------------------------
# load and summarize
p_vals <- readRDS(file.path(save_path, glue::glue("p_values_B{B}.rds")))
ci_p <- quantile(p_vals, probs = c(0.025, 0.975))
p_mean <- mean(p_vals)

# save summary 
ghcm_boot_summary <- list(
	mean_p = round(p_mean, 3),
	ci_lower = round(ci_p[1], 3),
	ci_upper = round(ci_p[2], 3),
	B = B
)
saveRDS(ghcm_boot_summary, file = file.path(save_path, "ghcm_boot_summary.rds"))


# base R plot
pdf(file.path(save_path, "plot_ghcm_bootstrap.pdf"), width = 7, height = 4)
hist(p_vals, breaks = 50, xlab = "p-value", col = "lightblue", main = "")
abline(v = ci_p, col = "red", lty = 2)
abline(v = p_mean, col = "blue", lwd = 2)
dev.off()


df_p <- data.frame(p_value = p_vals)
plot_ecdf <- ggplot(df_p, aes(x = p_value)) +
	stat_ecdf(geom = "step", size = 1.3, color = "darkorange") +
	geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
	geom_vline(xintercept = 0.05, linetype = "dashed", color = "gray") + # alpha
	labs(x = expression("Bootstrapped "*italic("p")*"-value"), y = "ECDF") +
	coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
	theme_minimal(base_size = 11) +
	theme(
		panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5),
		axis.line = element_blank() 
	)
print(plot_ecdf)
ggsave(file.path(save_path, "plot_ecdf.pdf"), plot = plot_ecdf, width = 6, height = 4) #width 4.5 also good

