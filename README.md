# Toward causality in mobile sensing for depression: Modeling time-varying behavior with functional data


This repository contains the R code for **data preprocessing, analysis, and visualization** used in my master's thesis. The `code` folder contains two subfolders, one for each of the publicly available datasets used: 

- **StudentLife 2013** — the original *StudentLife* study ([Wang et al., 2014](#references))  
- **StudentLife 2017–2022** — the *College Experience Study* ([Nepal et al., 2024](#references))


## Abstract
Mobile sensing has become increasingly popular for studying depression with objective, real-world data. However, much of the existing literature focuses on marginal associations without controlling for measured confounding. This thesis addresses that gap by testing whether passively sensed **physical activity** influences follow-up depression after controlling for **baseline depression** and other relevant covariates.

We applied a novel framework combining **sparse functional data analysis (FDA)** ([Yao et al., 2005](#references); [Wang et al., 2016](#references); [Gertheiss et al., 2024](#references)) with the **Generalised Hilbertian Covariance Measure (GHCM)** ([Lundborg et al., 2022](#references)) to two longitudinal datasets from Dartmouth College:  
- *StudentLife 2013 (N=38)*
- *StudentLife 2017–2022 (N=196)*

Four analyses were conducted, operationalizing physical activity as **daily active minutes** or **step counts**, and adjusting for baseline depression, concurrent behaviors (conversation duration, phone lock duration), and gender. A bootstrap procedure was used to quantify the uncertainty of the resulting $p$-values of the GHCM tests.

Across all four analyses, we failed to reject the null hypothesis of conditional independence. However, bootstrap analysis indicated that three of the four results were inconclusive, and only one provided robust evidence for the null hypothesis.

Our findings suggest that, in these samples, the longitudinal physical activity signal did not provide additional predictive information about follow-up depression beyond what was contained in the conditioning set. This thesis serves as a **proof of concept**, demonstrating a rigorous methodology for moving beyond marginal correlations to testing conditional associations in digital mental health. As such, it highlights the critical importance of accounting for measured confounding.


## Data 
The raw datasets are **publicly available** but **not included** in this repository. To reproduce the analysis:


1.  **Download the data:**
    * StudentLife 2013: https://studentlife.cs.dartmouth.edu/datasets.html
    * StudentLife 2017-2022: https://www.kaggle.com/datasets/subigyanepal/college-experience-dataset
  
  
2.  **Organize the data folders:** Inside the project root, create a new folder named `data` with the following structure:
    * Place the unzipped StudentLife 2013 dataset into `data/studentlife_2013/raw/`.
    * Place the unzipped StudentLife 2017--2022 dataset into `data/studentlife_2017_2022/`.
    
    The final structure should look like this:

    ```
    data/
    ├── studentlife_2013/
    │   └── raw/
    │       └── ... (raw files from StudentLife 2013)
    └── studentlife_2017_2022/
        └── ... (raw files from StudentLife 2017-2022)
    ```

3. **Run the scripts:** To reproduce the analysis:  
   * **Recommended:** Open the R project file `msc-thesis-public.Rproj` in RStudio (located in the root folder). This automatically sets the correct working directory, such that all relative paths in the scripts work as intended. The analysis scripts are in the `code/` folder, organized into subdirectories for each dataset.  
   * Run the scripts in sequence. For the specific execution order, see the **`README.md`** file in `studentlife_2013` and `studentlife_2017_2022`.

---


## References

- Gertheiss, J., Rügamer, D., Liew, B. X. W., & Greven, S. (2024). Functional data analysis: An introduction and recent developments. *Biometrical Journal*, 66(7), e202300363. https://doi.org/10.1002/bimj.202300363  

- Lundborg, A. R., Shah, R. D., & Peters, J. (2022). Conditional independence testing in Hilbert spaces with applications to functional data analysis. *Journal of the Royal Statistical Society: Series B (Statistical Methodology)*, 84(5), 1821–1850. https://doi.org/10.1111/rssb.12544

- Nepal, S., Liu, W., Pillai, A., Wang, W., Vojdanovski, V., Huckins, J. F., Rogers, C., Meyer, M. L., & Campbell, A. T. (2024). *Capturing the College Experience: A Four-Year Mobile Sensing Study of Mental Health, Resilience and Behavior of College Students during the Pandemic.* Proceedings of the ACM on Interactive, Mobile, Wearable and Ubiquitous Technologies, 8(1), 1–38. https://doi.org/10.1145/3643501  

- Yao, F., Müller, H. G., & Wang, J. L. (2005). Functional data analysis for sparse longitudinal data. *Journal of the American Statistical Association*, 100(470), 577–590. https://doi.org/10.1198/016214504000001745  

- Wang, R., Chen, F., Chen, Z., Li, T., Harari, G., Tignor, S., Zhou, X., Ben-Zeev, D., & Campbell, A. T. (2014). *StudentLife: Assessing mental health, academic performance and behavioral trends of college students using smartphones.* Proceedings of the 2014 ACM International Joint Conference on Pervasive and Ubiquitous Computing, 3–14. https://doi.org/10.1145/2632048.2632054  


