# Monte Carlo Summary for Standardized Estimates

Computes standardized estimates, standard errors, and confidence
intervals based on Monte Carlo samples from a `semmcci` object. This
function fully standardizes both point estimates and sampling
distributions (including intercepts).

## Usage

``` r
MCStd2(mc, alpha = c(0.001, 0.01, 0.05))
```

## Arguments

- mc:

  A Monte Carlo result object of class `semmcci`, typically from `MC()`
  or `MCMI()`.

- alpha:

  A numeric vector of significance levels (default:
  `c(0.001, 0.01, 0.05)`).

## Value

A data frame containing:

- Parameter:

  Parameter name

- Estimate:

  Standardized point estimate

- SE:

  Standard deviation of standardized samples

- R:

  Number of Monte Carlo replications

- CI columns:

  Multiple confidence intervals based on `alpha`

## Details

The function standardizes the sampling distribution using
[`StdLav2()`](https://yangzhen1999.github.io/wsMed/reference/StdLav2.md)
on each Monte Carlo draw, then summarizes the distribution into SEs and
quantile-based confidence intervals.
