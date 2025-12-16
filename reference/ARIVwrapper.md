# Average Relative Increase in Variance

Average Relative Increase in Variance

## Usage

``` r
ARIVwrapper(between, within, M, k)
```

## Arguments

- between:

  Numeric matrix. Covariance between imputations
  \\\mathbf{V}\_{\mathrm{between}}\\.

- within:

  Numeric matrix. Covariance within imputations
  \\\mathbf{V}\_{\mathrm{within}}\\.

- M:

  Positive integer. Number of imputations.

- k:

  Positive integer. Number of parameters.

## Value

Returns a numeric vector of length one.

## Details

The average relative increase in variance is given by \$\$ \mathrm{ARIV}
= \left( 1 + M^{-1} \right) \mathrm{tr} \left(
\mathbf{V}\_{\mathrm{between}} \mathbf{V}\_{\mathrm{within}}^{-1}
\right) \$\$

## Author

Ivan Jacob Agaloos Pesigan
