# Extract All Parameters and Definitions

Extracts free and defined parameters from a fitted `lavaan` model, and
builds a dependency map of user-defined parameters.

## Usage

``` r
extract_all_parameters(fit)
```

## Arguments

- fit:

  A `lavaan` model object.

## Value

A list with:

- `free`: Names of free parameters.

- `defined`: Names of defined parameters.

- `definition_map`: A list mapping defined parameters to their
  dependencies.
