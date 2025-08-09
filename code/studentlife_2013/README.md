# StudentLife 2013

This folder contains all R scripts for the preprocessing to investigate the relationship between passively sensed behaviors (active minutes, conversation duration, and phone lock duration) and depression (PHQ-9) in the StudentLife 2013 dataset.

---

## Execution order

Please run the scripts in the following order to ensure all data dependencies are met.

1.  **`00_phq9.R`**: Cleans and performs exploratory analysis on the PHQ-9 survey data.
2.  **`01_activity_cleaning.R`**: Cleans and preps the raw activity sensing data.
3.  **`02_activity_daily_minutes.R`**: Cleans and normalized the daily activity data for GHCM input.
4.  **`03_joint_overview.R`**: Joins all preprocessed datasets. 
5.  **`04_ghcm.R`**: Rund the GHCM test controlling for baseline depression (scalar) (Analysis 1).
6.  **`05_convo.Rmd`**: Cleans and prepares the conversation duration data.
7.  **`06_phonelock.Rmd`**: Cleans and prepares the phone lock duration data.
7.  **`07_ghcm.Rmd`**: Runs the full GHCM test with functional covariates (Anaylsis 2). 


## Some high level details: 


1. **`01_activity_cleaning.R`:** Loads raw activity data (CSV per user), removes duplicated rows and timestamps, and saves a clean, unified dataset.

**Output:**  
- `activity_clean.csv`  
- `activity_clean.rds`  

2. **`02_activity_daily_minutes.R`:** 

**Purpose:**  
Implements threshold-based aggregation (Wang et al., 2014) to compute **daily activity duration**.  
Each 10-minute window is labeled active or inactive, and total active minutes per day are computed.  
Also prepares the data for GHCM input format and generates plots.

**Key steps:**  
- Aggregate activity using a 10-minute threshold window  
- Cap extreme activity values at 500 minutes  
- Map `uid` → `.obs` for GHCM compatibility  
- Save daily summaries and long format

**Output:**  
- `activity_daily.csv` / `.rds`  
- `activity_daily_plot.csv` / `.rds`  
- `activity_daily_long.csv` / `.rds`  
- Plots (`plot_01.pdf`, `plot_02.pdf`, `plot_03.pdf`) in `data/preprocessed/sensing/activity/plots`
