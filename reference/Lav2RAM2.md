# Convert Lavaan Model to RAM Matrices

Converts a lavaan-style matrix list into RAM (Reticular Action Model)
format, including the A (asymmetric paths), S (symmetric paths), F
(filter matrix), and M (means/intercepts) matrices.

## Usage

``` r
Lav2RAM2(lav_mod)
```

## Arguments

- lav_mod:

  A named list of lavaan matrices including `lambda`, `beta`, `theta`,
  `psi`, and `alpha`.

## Value

A list with components:

- A:

  Asymmetric path matrix (including factor loadings and structural
  paths)

- S:

  Symmetric path matrix (variances and covariances)

- F:

  Filter matrix mapping latent and observed variables

- M:

  Row vector of intercepts/means

## Details

This function reorganizes the lavaan-style matrices into the RAM
representation, commonly used for model standardization and
transformation.
