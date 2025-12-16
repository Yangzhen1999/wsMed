# Apply Standardization to Parameter Definitions

Replaces parameters in expressions with their standardized versions.

## Usage

``` r
apply_standardization(definitions, std_map, path_std_map = list())
```

## Arguments

- definitions:

  A list of user-defined parameter expressions.

- std_map:

  A named list mapping intercept parameter names to their observed
  variables.

- path_std_map:

  A named list mapping slope parameters to predictor/outcome variables.

## Value

A list of standardized parameter expressions.
