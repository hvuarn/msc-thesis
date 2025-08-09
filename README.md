# Toward causality in mobile sensing for depression: Modeling time-varying behavior with functional data

This repository contains all the R code used for the data preprocessing, analysis, and visualization for my master's thesis. 
The analysis is divided into two main parts, based on two distinct datasets: the StudentLife 2013 dataset and the StudentLife 2017-2022 dataset.

## Abstract
Mobile sensing has become increasingly popular for studying depression with objective, real-world data. However, much of the existing literature only reports 
marginal associations without controlling for measured confounding. This thesis addresses this gap by testing whether passively sensed physical 
activity influences follow-up depression after controlling for baseline depression and other relevant covariates.

We applied a novel framework combining sparse functional data analysis (FDA) with the Generalised Hilbertian Covariance Measure (GHCM) to two longitudinal datasets from Dartmouth College: 
the StudentLife study (2013; $N=38$) and the College Experience Study (2017–-2022; $N=196$). Four distinct analyses were conducted, operationalizing physical activity as daily 
active minutes or step counts and adjusting for baseline depression, concurrent behaviors (conversation duration and phone lock duration), and gender. A bootstrap procedure was used to quantify the uncertainty of the resulting $p$-values of the GHCM test.

Across all four analyses, we failed to reject the null hypothesis of conditional independence. However, bootstrap analysis revealed that 
the findings for three of the four analyses were inconclusive, with only one analysis providing robust evidence for the null hypothesis. 

Our findings suggest that, in these samples, the longitudinal physical activity signal did not provide additional predictive information about follow-up depression 
beyond what was contained in the conditioning set. This thesis serves as a crucial proof of concept, demonstrating a rigorous methodology for moving beyond marginal 
correlations to testing conditional associations in digital mental health. As such, we demonstrate the critical importance of accounting for measured confounding.


## About this repository
This repository contains all the R code used for the data preprocessing, analysis, and visualization described in the abstract above. The analysis is divided into two main parts, based on the StudentLife 2013 dataset and the StudentLife 2017–2022 dataset.

#----------------
## Data 
The raw datasets are publicly available and are not included in this repository. To run the analysis, you must download the data and place it in the correct directory.

Of the three StudentLife studies, we use the two publicly available datasets: 
the original StudentLife study \citep{Wang2014} and the College Experience Study \citep{Nepal2024}. 
The first is available from the project's website \citep{StudentLife2013} and the second was released on Kaggle on April 15, 2025 \citep{Kaggle}. 
We refer to the datasets as StudentLife 2013 and StudentLife 2017–2022, respectively.

1.  **Download the data:**
    * StudentLife 2013: https://studentlife.cs.dartmouth.edu/datasets.html
    * StudentLife 2017-2022: https://www.kaggle.com/datasets/subigyanepal/college-experience-dataset
  
2.  **Organize the data folders:** Inside this project, create a new folder named `data`. Then, create two subfolders inside it `studentlife_2013` and `studentlife_2017_2022`. Important: Rename the folders to match the names used in the scripts:
    *Place the unzipped contents of the first StudentLife dataset into the folder `data/studentlife_2013/raw`.
    *Place the unzipped contents of the College Experience Study (2017-2022) dataset into the `data/studentlife_2017_2022`.
    
    The final structure should look like this:

    ```
    data/
    ├── studentlife_2013/
    │   └── raw/
    │       └── ... (raw files from StudentLife 2013)
    └── studentlife_2017_2022/
        └── ... (raw files from StudentLife 2017-2022)
    ```


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





