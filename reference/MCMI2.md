# Monte Carlo Confidence Intervals for Multiple Imputation SEM Models

Computes Monte Carlo confidence intervals (MCCI) for structural equation
models (SEM) fitted to multiple imputed datasets. This function
integrates SEM fitting across imputed datasets, pools the results, and
generates confidence intervals through Monte Carlo sampling.

## Usage

``` r
MCMI2(
  sem_model,
  imputations,
  R = 20000L,
  alpha = c(0.001, 0.01, 0.05),
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06,
  seed = NULL,
  estimator = "ML",
  se = "standard",
  missing = "listwise"
)
```

## Arguments

- sem_model:

  A character string specifying the SEM model syntax.

- imputations:

  A list of data frames, where each data frame represents an imputed
  dataset.

- R:

  An integer specifying the number of Monte Carlo samples. Default is
  `20000L`.

- alpha:

  A numeric vector specifying significance levels for the confidence
  intervals. Default is `c(0.001, 0.01, 0.05)`.

- decomposition:

  A character string specifying the decomposition method for the
  covariance matrix. Default is `"eigen"`. Options include `"chol"`,
  `"eigen"`, or `"svd"`.

- pd:

  A logical value indicating whether to ensure positive definiteness of
  the covariance matrix. Default is `TRUE`.

- tol:

  A numeric value specifying the tolerance for positive definiteness
  checks. Default is `1e-06`.

- seed:

  An optional integer specifying the random seed for reproducibility.
  Default is `NULL`.

- estimator:

  A character string specifying the estimator for SEM fitting. Default
  is `"ML"` (Maximum Likelihood).

- se:

  A character string specifying the type of standard errors to compute.
  Default is `"standard"`.

- missing:

  A character string specifying the method for handling missing data in
  SEM fitting. Default is `"listwise"`.

## Value

An object of class `semmcci` containing:

- `call`: The matched function call.

- `args`: A list of input arguments.

- `thetahat`: The pooled parameter estimates.

- `thetahatstar`: Monte Carlo samples for parameter estimates.

- `fun`: The name of the function (`"MCMI2"`).

## Details

This function is designed for SEM models that require multiple
imputation to handle missing data. It performs the following steps:

- **SEM Fitting**: Fits the specified SEM model to each imputed dataset
  using [`lavaan::sem()`](https://rdrr.io/pkg/lavaan/man/sem.html).

- **Pooling Results**: Combines parameter estimates and covariance
  matrices across imputations using Rubin's rules.

- **Monte Carlo Sampling**: Generates Monte Carlo samples based on the
  pooled estimates and covariance matrices, and calculates confidence
  intervals for model parameters.

This function supports custom estimators, handling of missing data, and
precision adjustments for Monte Carlo sampling. It is particularly
useful for mediation analysis or complex SEM models where missing data
are addressed using multiple imputation.

## See also

[`lavaan::sem()`](https://rdrr.io/pkg/lavaan/man/sem.html),
[`semmcci::MC()`](https://github.com/jeksterslab/semmcci/reference/MC.html),
[`semmcci::MCStd()`](https://github.com/jeksterslab/semmcci/reference/MCStd.html)

## Examples

``` r
# Example SEM model
sem_model <- "
  Ydiff ~ b1 * M1diff + cp * 1
  M1diff ~ a1 * 1
  indirect := a1 * b1
  total := cp + indirect
"

# Example imputed datasets
imputations <- list(
  data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
  data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
)

# Compute Monte Carlo confidence intervals
result <- MCMI2(
  sem_model = sem_model,
  imputations = imputations,
  R = 1000,
  alpha = c(0.05, 0.01),
  seed = 123
)
```
