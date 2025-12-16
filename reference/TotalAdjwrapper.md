# Adjusted Total Sampling Covariance Matrix

Adjusted Total Sampling Covariance Matrix

## Usage

``` r
TotalAdjwrapper(ariv, within)
```

## Arguments

- ariv:

  Numeric. Average relative increase in variance.

- within:

  Numeric matrix. Covariance within imputations
  \\\mathbf{V}\_{\mathrm{within}}\\.

## Details

The adjusted total sampling covariance matrix is given by \$\$
\tilde{\mathbf{V}}\_{\mathrm{total}} = \left( 1 + \mathrm{ARIV} \right)
\mathbf{V}\_{\mathrm{within}} \$\$

## Author

Ivan Jacob Agaloos Pesigan
