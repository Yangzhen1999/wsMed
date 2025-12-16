# Example Data for within subject mediation

A simulated dataset containing variables for within-subject mediation
analysis. The dataset includes four within-subject variables (A, B, C,
D), each measured at three levels:

- **A1, A2, A3**: Levels of within-subject variable A (e.g., mediator
  conditions).

- **B1, B2, B3**: Levels of within-subject variable B (e.g., outcome
  conditions).

- **C1, C2, C3**: Levels of within-subject variable.

- **D1, D2, D3**: Levels of within-subject variable.

## Usage

``` r
example_data
```

## Format

A tibble (data frame) with 100 rows and 12 variables:

- A1:

  Numeric variable

- A2:

  Numeric variable

- A3:

  Numeric variable

- B1:

  Numeric variable

- B2:

  Numeric variable

- B3:

  Numeric variable

- C1:

  Numeric variable

- C2:

  Numeric variable

- C3:

  Numeric variable

- D1:

  Numeric variable

- D2:

  Numeric variable

- D3:

  Numeric variable

## Examples

``` r
data(example_data)
head(example_data)
#> # A tibble: 6 × 14
#>      A1    A2     A3     B1    B2    B3    C1    C2    C3    D1    D2     D3
#>   <dbl> <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
#> 1 0.520 0.348 0.0518 0.0935 0.254 0.502 0     0.240 0     0.702 0.485 0.314 
#> 2 0.329 0.121 0.291  0.259  0.328 0.152 0.116 0     0.118 0     0.392 0.0133
#> 3 0.208 0.168 0.156  0.295  0.342 0.490 0.237 0.214 0.137 0.336 0.706 0.521 
#> 4 0.565 0.175 0.401  0.622  0.450 0.536 0.285 0.395 0.143 0.532 0.437 0.290 
#> 5 0.514 0.767 0.598  0.653  0.448 0.525 0.284 0.464 0.161 0.456 0.351 0.217 
#> 6 0.763 0.567 0.803  0.766  0.716 0.554 0.260 0.313 0.177 0.813 0.666 1     
#> # ℹ 2 more variables: Group <fct>, W_Group <fct>
```
