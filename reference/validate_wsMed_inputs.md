# Validate user inputs for `wsMed()`

All checks **stop()** with an informative message when they fail.
Invisibly returns `TRUE` on success.

## Usage

``` r
validate_wsMed_inputs(
  data,
  M_C1,
  M_C2,
  Y_C1,
  Y_C2,
  C_C1 = NULL,
  C_C2 = NULL,
  C = NULL,
  W = NULL,
  W_type = NULL,
  MP = NULL,
  form = c("P", "CN", "CP", "PC"),
  Na = c("DE", "FIML", "MI"),
  R = 20000L,
  bootstrap = 1000L,
  m = 5L,
  ci_level = 0.95,
  ci_method = NULL,
  MCmethod = NULL
)
```
