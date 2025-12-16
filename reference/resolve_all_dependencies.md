# Resolve Dependencies of Defined Parameters

Recursively resolves all free parameters involved in each defined
parameter.

## Usage

``` r
resolve_all_dependencies(def_map)
```

## Arguments

- def_map:

  A definition map produced by
  [`extract_all_parameters()`](https://yangzhen1999.github.io/wsMed/reference/extract_all_parameters.md).

## Value

A list mapping each defined parameter to its dependent free parameters.
