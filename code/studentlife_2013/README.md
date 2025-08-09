# R code – StudentLife 2013: activity data

This folder contains R code for preprocessing and preparing the StudentLife `activity` sensing data for further analysis.

---

## `01_activity_cleaning.R`

**Purpose:**  
Loads raw activity data (CSV per user), removes duplicated rows and timestamps, and saves a clean, unified dataset.

**Output:**  
- `activity_clean.csv`  
- `activity_clean.rds`  


## `02_activity_daily_minutes.R`

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

-

## How to run

It’s recommended to open the project in RStudio and run the scripts from there  
to ensure relative paths work correctly and outputs are saved to the correct folder.

### Option 1: via RStudio Project (recommended)
1. Open `msc-thesis.Rproj` in RStudio (root folder)
2. Open e.g. `Rcode/01_activity_cleaning.R` or `Rcode/02_activity_daily_minutes.R`
3. Run the full script

### Option 2: from console
You can also run the scripts using:

```r
source("Rcode/01_activity_cleaning.R")
source("Rcode/02_activity_daily_minutes.R")




recommended: run via RStudio project
to ensure relative paths and project structure work correctly:

▶ open the R project:
  - open `msc-thesis-public.Rproj` in RStudio (located in the root folder)

▶ run the cleaning script:
  - open `rcode/01_activity_cleaning.R` inside the project
  - run the full script

▶ outputs will be saved as:
  - data/preprocessed/sensing/activity/activity_clean.csv
  - data/preprocessed/sensing/activity/activity_clean.rds

this will generate the cleaned activity dataset from raw studentlife files


