# Evaluate Standardized Monte Carlo Expressions

Evaluates user-defined parameters (defined via expressions) and
standardized free parameters from Monte Carlo simulated samples. This
version supports both intercept-based standardization and path-based
standardization.

## Usage

``` r
evaluate_definitions_v3(
  theta_star,
  definitions,
  std_map,
  sd_boot_list,
  sd_var_boot,
  path_std_map
)
```

## Arguments

- theta_star:

  A matrix of Monte Carlo samples.

- definitions:

  A named list of parameter definitions (e.g., list(indirect := "a \*
  b")).

- std_map:

  A named character vector mapping intercept labels (e.g., a1) to
  variable names (e.g., M1diff).

- sd_boot_list:

  A list of bootstrap SD samples for intercept variables.

- sd_var_boot:

  A list of bootstrap SD samples for variables involved in slope paths.

- path_std_map:

  A named list mapping path labels to a vector of (predictor, outcome)
  variable names.

## Value

A data frame of R rows (simulations) \* all parameters (standardized
free + defined).
