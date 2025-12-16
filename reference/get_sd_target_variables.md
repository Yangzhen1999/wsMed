# Extract Target Variables for Standardization

Extracts variable names from a fitted SEM model and a definition map
that are required for computing standardized estimates in Monte Carlo
simulations. Specifically, it identifies intercept terms (e.g., `~1`)
involved in user-defined parameters such as indirect effects (e.g.,
`indirect := a * b`) that require standard deviations for
standardization.

## Usage

``` r
get_sd_target_variables(fit, definition_map, data)
```

## Arguments

- fit:

  A `lavaan` model object. Must be fitted with labels for defined
  parameters.

- definition_map:

  A named list returned from
  [`resolve_all_dependencies()`](https://yangzhen1999.github.io/wsMed/reference/resolve_all_dependencies.md),
  mapping defined parameters (e.g., "indirect1") to their algebraic
  components (e.g., c("a1", "b1")).

- data:

  A data frame used to fit the model, typically the original observed
  dataset. Used to validate the existence of variables.

## Value

A character vector of variable names whose standard deviations are
needed to standardize the intercept estimates in Monte Carlo confidence
interval analysis.
