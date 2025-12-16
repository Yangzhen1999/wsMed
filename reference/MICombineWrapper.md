# Wrapper for Internal Multiple Imputation Combining Function

A wrapper function for the internal `.MICombine()` function from the
`semmcci` package. This function pools parameter estimates and
covariance matrices from multiple imputed datasets using Rubin's rules.

## Usage

``` r
MICombineWrapper(coefs, vcovs, M, k, adj = FALSE)
```

## Arguments

- coefs:

  A list of numeric vectors, where each vector contains the parameter
  estimates from one imputed dataset.

- vcovs:

  A list of numeric matrices, where each matrix represents the
  covariance matrix of the parameter estimates for one imputed dataset.

- M:

  An integer indicating the number of imputations.

- k:

  An integer specifying the number of parameters in the SEM model.

- adj:

  A logical value indicating whether to apply an adjustment for finite
  samples. Default is `TRUE`.

## Value

A list containing the pooled estimates and covariance matrix:

- `est`: A numeric vector of pooled parameter estimates.

- `total`: A numeric matrix representing the pooled covariance matrix.

## Details

This wrapper provides an abstraction over the internal `.MICombine()`
function from the `semmcci` package, allowing it to be used within your
package without directly exposing the internal function. It is primarily
designed for use within workflows that involve multiple imputation and
structural equation modeling (SEM). Rubin's rules are applied to compute
pooled parameter estimates and their covariance matrices.

## See also

[`RunMCMIAnalysis()`](https://yangzhen1999.github.io/wsMed/reference/RunMCMIAnalysis.md)
