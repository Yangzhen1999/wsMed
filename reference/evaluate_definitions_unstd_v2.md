# Evaluate Unstandardized Monte Carlo Definitions

Evaluates user-defined parameter expressions from Monte Carlo samples
without any standardization.

## Usage

``` r
evaluate_definitions_unstd_v2(theta_star, definitions)
```

## Arguments

- theta_star:

  A matrix of Monte Carlo samples.

- definitions:

  A named list of algebraic definitions (as strings).

## Value

A data frame with R rows (simulations) and p + d columns (p = number of
free parameters, d = number of defined parameters).
