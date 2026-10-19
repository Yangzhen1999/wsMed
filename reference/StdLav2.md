# Standardize parameter estimates in a lavaan model

Applies full standardization (including intercepts) to a fitted lavaan
model by converting to RAM form, performing standardization, and
converting back to lavaan matrix structure.

## Usage

``` r
StdLav2(
  est,
  object,
  marginal_variances = object@external$wsmed_mi_marginal$point
)
```

## Arguments

- est:

  A numeric vector of parameter estimates (free parameters).

- object:

  A fitted lavaan model object (used to extract model structure).

- marginal_variances:

  Optional jointly pooled MI marginal variances.

## Value

A numeric vector of fully standardized parameter estimates (including
intercepts and defined parameters).

## Details

The function extracts the model's RAM representation via `Lav2RAM2`,
applies `StdRAM2` standardization, restores the standardized GLIST via
`RAM2Lav2`, and retrieves standardized user-defined parameter estimates
with `lav_model_get_parameters()`.
