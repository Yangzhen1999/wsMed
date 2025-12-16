# Process Monte Carlo Samples for Defined Parameters in SEM

A wrapper for the internal `.MCDef()` function from the `semmcci`
package. This function processes Monte Carlo samples to compute defined
parameters for structural equation modeling (SEM).

## Usage

``` r
MCDefWrapper(object, thetahat, thetahatstar_orig)
```

## Arguments

- object:

  A fitted `lavaan` SEM model object.

- thetahat:

  A numeric vector of parameter estimates.

- thetahatstar_orig:

  A matrix of Monte Carlo samples, where rows represent samples and
  columns represent parameters.

## Value

A matrix of computed defined parameters for each Monte Carlo sample.

## Details

This function takes Monte Carlo samples of parameter estimates and a
fitted SEM model object to compute the defined parameters (e.g.,
indirect effects or user-defined contrasts) based on the model syntax.
It is particularly useful for examining derived quantities in SEM
analyses using Monte Carlo methods.

## See also

[`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md),
[`RunMCMIAnalysis()`](https://yangzhen1999.github.io/wsMed/reference/RunMCMIAnalysis.md)
