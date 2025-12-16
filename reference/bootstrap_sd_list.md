# Bootstrap Standard Deviations for Standardization

Performs bootstrap sampling to estimate SDs of variables used in
standardization.

## Usage

``` r
bootstrap_sd_list(data, var_names, nboot = 20000, seed = NULL)
```

## Arguments

- data:

  A data frame.

- var_names:

  A character vector of variable names.

- nboot:

  Integer. Number of bootstrap samples.

- seed:

  Integer. Random seed.

## Value

A named list of numeric vectors (bootstrapped SD samples).
