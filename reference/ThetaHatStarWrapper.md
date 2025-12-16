# Monte Carlo Sampling for Parameter Estimates

Generates Monte Carlo samples for parameter estimates using a covariance
matrix and a location vector. This function is a wrapper for the
internal `.ThetaHatStar()` function from the `semmcci` package.

## Usage

``` r
ThetaHatStarWrapper(
  R = 20000L,
  scale,
  location,
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06
)
```

## Arguments

- R:

  Integer. Number of Monte Carlo samples to generate.

- scale:

  Numeric matrix. The covariance matrix of the parameter estimates.

- location:

  Numeric vector. The mean (or location) of the parameter estimates.

- decomposition:

  Character. Decomposition method for the covariance matrix. Options:
  `"chol"` (Cholesky), `"eigen"` (eigenvalue decomposition), `"svd"`
  (singular value decomposition). Default is `"eigen"`.

- pd:

  Logical. Ensure positive definiteness of the covariance matrix.
  Default is `TRUE`.

- tol:

  Numeric. Tolerance for positive definiteness checks. Default is
  `1e-06`.

## Value

A list containing:

- `thetahatstar`: A matrix of simulated parameter estimates with
  dimensions `R x length(location)`.

- `decomposition`: The decomposition method used.

## See also

[`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md),
[`RunMCMIAnalysis()`](https://yangzhen1999.github.io/wsMed/reference/RunMCMIAnalysis.md)
