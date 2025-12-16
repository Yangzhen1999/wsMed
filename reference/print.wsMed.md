# Print Method for wsMed Objects

Provides a comprehensive summary of results from a `wsMed` object,
including:

- Input and computed variables with sample size.

- Model fit indices, regression paths, and variance estimates.

- Total, direct, and indirect effects with pairwise contrasts.

- Moderation effects and Monte Carlo confidence intervals for raw and
  standardized estimates (if applicable).

- Diagnostic notes for bootstrapping, imputation, and analysis
  parameters.

The output is formatted for clarity, ensuring an intuitive presentation
of mediation analysis results, including dynamic confidence intervals,
moderation keys, and C1-C2 coefficients.

## Usage

``` r
# S3 method for class 'wsMed'
print(x, digits = 3, ...)
```

## Arguments

- x:

  A `wsMed` object containing the results of within-subject mediation
  analysis.

- digits:

  Numeric. Number of digits to display in the results.

- ...:

  Additional arguments (not used currently).

## Value

Invisibly returns the input `wsMed` object for further use.

## Details

This function is specifically designed to display results from the
within-subject mediation analysis conducted using the `wsMed` function.
Key features include:

- **Variables**:

  - Shows input variables (M_C1, M_C2, Y_C1, Y_C2) and computed
    variables like Ydiff, Mdiff, and Mavg.

  - Reports the sample size used in the analysis.

- **Model Fit Indices**:

  - Displays SEM fit indices (e.g., Chi-square, CFI, TLI, RMSEA, SRMR)
    to assess model quality.

- **Regression Paths and Variance Estimates**:

  - Summarizes path coefficients, intercepts, variances, and confidence
    intervals.

- **Effects**:

  - Reports total, direct, and indirect effects with their significance.

  - Highlights pairwise contrasts between indirect effects for mediation
    paths.

- **Moderation Effects**:

  - Provides moderation results for identified variables with
    corresponding coefficients and paths.

- **Monte Carlo Confidence Intervals**:

  - Includes results for raw and standardized estimates obtained using
    methods such as MI or FIML.

- **Diagnostics**:

  - Summarizes analysis parameters like bootstrapping, imputation
    settings, Monte Carlo iterations, and random seeds.

## See also

[`wsMed`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md),
[`sem`](https://rdrr.io/pkg/lavaan/man/sem.html),
`standardizedSolution_boot_ci`

## Examples

``` r
# Perform within-subject mediation analysis
data("example_data", package = "wsMed")
result1 <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "FIML",
  standardized = FALSE,
  alpha = 0.05
)

# Print the results
print(result1)
#> 
#> 
#> *************** VARIABLES ***************
#> Outcome (Y):
#>    Condition 1: C1 
#>    Condition 2: C2 
#> Mediators (M):
#>   M1:
#>     Condition 1: A1
#>     Condition 2: A2
#>   M2:
#>     Condition 1: B1
#>     Condition 2: B2
#> Sample size (rows kept): 100 
#> 
#> 
#> *************** MODEL FIT ***************
#> 
#> 
#> |Measure   |  Value|
#> |:---------|------:|
#> |Chi-Sq    | 11.436|
#> |df        |  5.000|
#> |p         |  0.043|
#> |CFI       |  0.000|
#> |TLI       | -1.130|
#> |RMSEA     |  0.113|
#> |RMSEA Low |  0.018|
#> |RMSEA Up  |  0.202|
#> |SRMR      |  0.076|
#> 
#> 
#> ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
#> 
#> 
#> |Label          | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|--------:|-----:|---------:|----------:|
#> |Total effect   |    0.015| 0.016|    -0.016|      0.047|
#> |Direct effect  |    0.016| 0.016|    -0.015|      0.048|
#> |Total indirect |   -0.001| 0.004|    -0.010|      0.008|
#> 
#> Indirect effects:
#> 
#> 
#> |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |ind_1 |    0.001| 0.003|    -0.005|      0.008|
#> |ind_2 |   -0.002| 0.003|    -0.009|      0.003|
#> 
#> Indirect-effect key:
#> 
#> 
#> |Ind   |Path                 |
#> |:-----|:--------------------|
#> |ind_1 |X -> M1diff -> Ydiff |
#> |ind_2 |X -> M2diff -> Ydiff |
#> 
#> 
#> *************** MODERATION EFFECTS (d-paths, MC) ***************
#> 
#> 
#> |Coefficient | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----------|--------:|-----:|---------:|----------:|
#> |d1          |   -0.062| 0.091|    -0.241|      0.115|
#> |d2          |   -0.073| 0.086|    -0.241|      0.097|
#> 
#> 
#> *************** MODERATION KEY (d-paths) ***************
#> 
#> 
#> |Coefficient |Path           |Moderated       |
#> |:-----------|:--------------|:---------------|
#> |d1          |M1avg -> Ydiff |M1diff -> Ydiff |
#> |d2          |M2avg -> Ydiff |M2diff -> Ydiff |
#> 
#> 
#> *************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************
#> 
#> 
#> |Contrast                  | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-------------------------|--------:|-----:|---------:|----------:|
#> |indirect_2  -  indirect_1 |   -0.003| 0.004|    -0.012|      0.005|
#> 
#> 
#> *************** C1-C2 COEFFICIENTS (No Moderator) ***************
#> 
#> 
#> |Coeff | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |X1_b1 |   -0.067| 0.104|    -0.269|      0.137|
#> |X0_b1 |   -0.005| 0.104|    -0.209|      0.199|
#> |X1_b2 |   -0.149| 0.112|    -0.366|      0.073|
#> |X0_b2 |   -0.076| 0.093|    -0.258|      0.107|
#> 
#> 
#> *************** REGRESSION PATHS (MC) ***************
#> 
#> 
#> |Path           |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff ~ M1diff |b1    |   -0.036| 0.094|    -0.219|      0.145|
#> |Ydiff ~ M1avg  |d1    |   -0.062| 0.091|    -0.241|      0.115|
#> |Ydiff ~ M2diff |b2    |   -0.112| 0.094|    -0.296|      0.072|
#> |Ydiff ~ M2avg  |d2    |   -0.073| 0.086|    -0.241|      0.097|
#> 
#> 
#> *************** INTERCEPTS (MC) ***************
#> 
#> 
#> |Intercept |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:---------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~1   |cp    |    0.016| 0.016|    -0.015|      0.048|
#> |M1diff~1  |a1    |   -0.027| 0.018|    -0.061|      0.007|
#> |M2diff~1  |a2    |    0.014| 0.018|    -0.021|      0.049|
#> |M1avg~1   |      |   -0.000| 0.019|    -0.036|      0.036|
#> |M2avg~1   |      |    0.000| 0.020|    -0.040|      0.040|
#> 
#> 
#> *************** VARIANCES (MC) ***************
#> 
#> 
#> |Variance       |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~~Ydiff   |      |    0.026| 0.004|     0.019|      0.033|
#> |M1diff~~M1diff |      |    0.031| 0.004|     0.022|      0.039|
#> |M2diff~~M2diff |      |    0.032| 0.005|     0.023|      0.041|
#> |M1avg~~M1avg   |      |    0.034| 0.005|     0.025|      0.043|
#> |M2avg~~M2avg   |      |    0.041| 0.006|     0.030|      0.052|
```
