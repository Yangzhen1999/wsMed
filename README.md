
# wsMed
  
  <!-- badges: start -->
  
  <!-- badges: end -->
  
The `wsMed` function is designed for two condition within-subject
mediation analysis, incorporating SEM models through the `lavaan`
package and Monte Carlo simulation methods. This document provides a
detailed description of the function's parameters, workflow, and usage,
along with an example demonstration.

## Installation

You can install the development version of wsMed from [GitHub](https://github.com/) with:
  
  ``` r
# install.packages("pak")
pak::pak("Yangzhen1999/wsMed")
```

Alternatively, if you prefer using devtools, you can install wsMed as follows:
  
  ``` r
# install.packages("devtools")
devtools::install_github("Yangzhen1999/wsMed")
```

## Example

This is a basic example which shows you how to solve a common problem:
  
  ``` r
library(wsMed)

# Load example data
data(example_data)
set.seed(123)
example_dataN <- mice::ampute(
  data = example_data,
  prop = 0.1,
)$amp

# Perform within-subject mediation analysis (Parallel mediation model)
result <- wsMed(
  data = example_dataN,   #dataset
  M_C1 = c("A1","B1"),    # A1/B1 is A/B mediator variable in condition 1
  M_C2 = c("A2","B2"),    # A2/B2 is A/B mediator variable in condition 2
  Y_C1 = "C1",            # C1 is outcome variable in condition 1
  Y_C2 = "C2",            # C2 is outcome variable in condition 2
  form = "P",             # Parallel mediation
  C_C1 = "D1",            # within-subject covariate (e.g., measured under D1)
  C_C2 = "D2",            # within-subject covariate (e.g., measured under C2)
  C = "D3",               # between-subject covariates
  Na = "MI",              # Use multiple imputation for missing data
  standardized = TRUE,    # Request standardized path coefficients and effects
)

# Print summary results
print(result)
```

## Main Function Overview

The `wsMed()` function automates the full workflow for two-condition within-subject mediation analysis.
Its main steps are:

1. **Validate inputs** – check dataset structure, mediation model type (`form`), and missing-data settings.

2. **Prepare data** – compute difference scores (`Mdiff`, `Ydiff`) and centered averages (`Mavg`)
   from the two-condition variables.

3. **Build the model** – generate SEM syntax according to the chosen structure:
   - `"P"`: Parallel mediation
    <p align="center">
    <img src="inst/extdata/Wa.png" alt="parallel within-subject mediation model" width="60%">
  </p>
   - `"CN"`: Chained / serial mediation
    <p align="center">
    <img src="inst/extdata/Wb.png" alt="serial within-subject mediation model" width="60%">
  </p>
   - `"CP"`: Chained + Parallel
    <p align="center">
    <img src="inst/extdata/Wc.png" alt="serial-parallel within-subject mediation model" width="60%">
  </p>
   - `"PC"`: Parallel + Chained
   <p align="center">
    <img src="inst/extdata/Wd.png" alt="parallel-serial within-subject mediation model" width="60%">
  </p>

4. **Fit the model** – estimate parameters while handling missing data:
   - `"DE"`: listwise deletion
   - `"FIML"`: full-information ML
   - `"MI"`: multiple imputation

5. **Compute inference** – provide confidence intervals using:
   - **Bootstrap** (`ci_method = "bootstrap"`)
   - **Monte Carlo** (`ci_method = "mc"`)

6. **Optional: Standardization** – if `standardized = TRUE`, return standardized effects with CIs.

7. **Optional: Covariates** – automatically center and include:
   - **Between-subject covariates** (`C`): mean-centered and added to all regressions.
   - **Within-subject covariates** (`C_C1`, `C_C2`): difference scores and centered averages are computed and included.
