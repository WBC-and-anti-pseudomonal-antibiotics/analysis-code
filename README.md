# Analysis Code — Association of White Blood Cell Count with Treatment Response to Cefepime vs Piperacillin-Tazobactam

> [Authors]. [Journal]. [Year]. DOI: [insert DOI upon acceptance]  
> Zenodo archive: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)

---

## Overview

This repository contains the R code used to produce all analyses, tables, and figures reported in the manuscript. The analysis examines for heterogeneity of treatment effect by white blood cell (WBC) count between cefepime and piperacillin-tazobactam in the ACORN randomized trial and a cohort of patients included in a large instrumental variable (IV) study. The findings from the original study are available at the following links: 
https://jamanetwork.com/journals/jama/fullarticle/2810592
https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2818278

Because only the ACORN patient-level data is available, this repo focuses primarily on reproducing the analysis in that cohort, however, the code used to analyze the IV cohort data is included as well for reproducibility and transparency. 
---

## Repository Structure

```
├── README.md
├── data/
│   └── README_data.md                           # Data dictionary and access instructions
├── code/
│   ├── 01_data_cleaning.Rmd                     # Data import, cleaning, and variable derivation
│   ├── 02_descriptive.Rmd                       # Table 1 and descriptive statistics
│   ├── 03_logistic_regression.Rmd               # Primary logistic regression and sensitivity analyses
│   ├── 04_figures.Rmd                           # All manuscript figures
│   ├── 05_penalized_regression.Rmd              # LASSO penalized regression for variable selection
│   ├── 06_analysis_code_IV.Rmd                  # Instrumental variable analysis
│   ├── analysis_code_IV_response_to_review.R    # Reviewer-requested sensitivity analyses (IV)
│   └── 00_session_info.R                        # R session and package version info
├── output/
│   └── session_info.txt                         # Captured session info at time of analysis
└── LICENSE
```

---

## Data Availability

The dataset used in this analysis contains protected health information and cannot be shared publicly. Researchers interested in accessing the data may: 

- De-identified data and a data dictionary for the ACORN trial data is available. Data will be made available to researchers whose research
proposal is approved by the principal investigator in addition to approval by an Institutional
Review Board and an executed data use agreement. Data will become available 3 months
following publication of outcomes and will remain available for at least 5 years. Contact edward.t.qian@vumc.org for more information. 
- Patient-level data for the IV study will not be shared publicly in the
interest of securing patient identitiers and protected health information. Aggregate data is
provided in the linked manuscript Supplement, and additional aggregate data will be provided upon request.Contact rchander@med.umich.edu for more information


A data dictionary describing all variables is provided in `data/README_data.md`.

---

## How to Reproduce the Analysis

Requirements

R version 4.3.0 or later (see output/session_info.txt for exact version used)
RStudio (recommended) or any R environment supporting R Markdown
The following R packages (installed automatically by each script if missing):

PackageVersion usedPurposetidyverse2.0.0Data manipulation and plottinghere1.0.1Reproducible file pathstableone0.13.2Table 1 generationgtsummary1.7.2Model result tablesbroom1.0.5Tidying model outputlmtest0.9-40Likelihood ratio testsglmnet4.1-8LASSO penalized regressioncaret6.0-94Train/test splitting and model evaluationpROC1.18.4ROC curves and AUCMASS7.3-60Ordinal logistic regressionpurrr1.0.2Functional programming for model iterationpatchwork1.2.0Combining ggplot figuresscales1.3.0Axis formattingknitr1.45R Markdown rendering

### Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/your-org-name/your-repo-name.git
   cd your-repo-name
   ```

2. **Obtain the data** — follow instructions in `data/README_data.md` and place the data file in the `data/` folder

3. **Run scripts in order** — open each `.Rmd` file in RStudio and knit, or run from the console:
   ```r
   rmarkdown::render("code/01_data_cleaning.Rmd")
   rmarkdown::render("code/02_descriptive.Rmd")
   rmarkdown::render("code/03_logistic_regression (1).Rmd")
   rmarkdown::render("code/04_figures.Rmd")
   rmarkdown::render("code/05_penalized_regression.RMD")
   ```

4. **Check session info** — compare your environment against `output/session_info.txt` if results differ

---

## License

Code in this repository is licensed under the [MIT License](LICENSE). Data (if any included) are licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).

---

## Contributors

| Contributor | Role | Code |
|-------------|------|------|
| Dan Rzewnicki | ACORN analyst | `01_` through `05_` scripts |
| Rishi Chanderraj | IV analyst | `05_` through `07_` script |

---

## Contact

**Corresponding author:** Siva Bhavani, MD  
**Email:** [sivasubramanium.bhavani@emory.edu@]  
**Institution:** [Emory University]
