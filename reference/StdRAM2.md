# Standardize RAM matrices

Performs standardization of RAM matrices by rescaling path and variance
structures using the implied covariance matrix. Intercepts are also
standardized.

## Usage

``` r
StdRAM2(ram_est, roles = NULL, marginal_variances = NULL)
```

## Arguments

- ram_est:

  A RAM object list with matrices `A`, `S`, `F`, and `M` as returned by
  [`Lav2RAM2()`](https://yangzhen1999.github.io/wsMed/reference/Lav2RAM2.md).

- roles:

  Internal list of dummy variable names and interaction components.

- marginal_variances:

  Optional jointly pooled MI marginal variances.

## Value

A list of standardized RAM matrices:

- A:

  Standardized asymmetric path matrix

- S:

  Standardized symmetric path matrix

- F:

  Unchanged filter matrix

- M:

  Standardized intercept vector

## Details

The function computes the implied covariance matrix \\\Sigma = (I -
A)^{-1} S (I - A)^{-T}\\, extracts standard deviations, and performs
standardization via \\D^{-1}\\ scaling.
