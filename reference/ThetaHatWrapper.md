# Compute Updated Parameter Estimates for SEM Models

A wrapper for the internal `.ThetaHat()` function from the `semmcci`
package. This function computes updated parameter estimates for
structural equation models (SEM) using pooled estimates from multiple
imputations or Monte Carlo simulations.

## Usage

``` r
ThetaHatWrapper(object, est = NULL)
```

## Arguments

- object:

  A fitted `lavaan` SEM model object.

- est:

  A numeric vector of pooled parameter estimates, typically obtained
  from multiple imputations or Monte Carlo simulations.

## Value

A numeric vector of updated parameter estimates.

## Details

The function takes a fitted SEM model object and pooled parameter
estimates to calculate the updated parameter values. It is particularly
useful for combining results from multiple imputations or Monte Carlo
samples to refine parameter estimates.

## See also

[`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md),
[`RunMCMIAnalysis()`](https://yangzhen1999.github.io/wsMed/reference/RunMCMIAnalysis.md)

## Examples

``` r
NULL
#> NULL
```
