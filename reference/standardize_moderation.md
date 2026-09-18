# Standardize conditional mediation results using existing joint draws

Standardize conditional mediation results using existing joint draws

## Usage

``` r
standardize_moderation(object)
```

## Arguments

- object:

  A wsMed result with a moderator and stored MC or bootstrap draws.

## Value

A moderation list with the same conditional tables and curves as the raw
output, or a list with mc and boot components for ci_method="both".

## Details

Conditional indirect and total effects are divided by the marginal
model-implied SD of Ydiff. Conditional paths use their endpoint scales.
Moderator probe values remain fixed in raw units; continuous interaction
coefficients in mod_coeff are reported per SD of W. Dummy variables
retain 0/1 units. Coefficients and scales are transformed jointly for
each draw. Intervals are percentile intervals, as in the raw conditional
tables. Metadata attributes record scales, probe conventions and draw
diagnostics. With fixed.x=TRUE, external moments are held fixed. MI uses
pooled primitive parameters and the existing first-imputation probing
reference.
