# Convert Standardized RAM Back to Lavaan Matrices

Converts a standardized RAM object back to lavaan-style matrix
structure. Optionally ensures correlations for `theta` and `psi`
matrices.

## Usage

``` r
RAM2Lav2(ram, lav_mod, standardized = FALSE)
```

## Arguments

- ram:

  A RAM list containing standardized matrices (`A`, `S`, `F`, and `M`).

- lav_mod:

  A lavaan-style matrix list (e.g., GLIST) to be updated.

- standardized:

  Logical. If TRUE, forces symmetric matrices to correlation form
  (cov2cor).

## Value

A modified lavaan-style matrix list with updated `lambda`, `beta`,
`theta`, `psi`, and `alpha`.

## Details

This function restores the internal lavaan model matrix structure from a
RAM representation.
