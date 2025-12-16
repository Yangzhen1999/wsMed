# Test for a Positive Definite Matrix

Returns `TRUE` if input is a positive definite matrix, and `FALSE`
otherwise.

## Usage

``` r
TestPositiveDefinitewrapper(eigen, tol = 1e-06)
```

## Arguments

- eigen:

  output of the [`eigen()`](https://rdrr.io/r/base/eigen.html) function.

- tol:

  Numeric. Tolerance.

## Value

Logical.

## Details

A \\k \times k\\ symmetric matrix \\\mathbf{A}\\ is positive definite if
all of its eigenvalues are positive.

## References

[Wikipedia: Definite
matrix](https://en.wikipedia.org/wiki/Definite_matrix)
