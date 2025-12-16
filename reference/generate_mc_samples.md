# Generate Monte Carlo Samples

Generates a Monte Carlo sample of model parameters from a multivariate
normal distribution.

## Usage

``` r
generate_mc_samples(fit, resolved_map, R = 20000, seed = NULL)
```

## Arguments

- fit:

  A fitted `lavaan` model.

- resolved_map:

  A dependency map from
  [`resolve_all_dependencies()`](https://yangzhen1999.github.io/wsMed/reference/resolve_all_dependencies.md).

- R:

  Integer. Number of Monte Carlo samples to generate.

- seed:

  Integer. Random seed.

## Value

A numeric matrix of Monte Carlo samples.
