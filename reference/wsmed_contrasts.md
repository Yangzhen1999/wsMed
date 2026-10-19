# Contrast effects using their joint stored draws

Contrast effects using their joint stored draws

## Usage

``` r
wsmed_contrasts(object, contrasts, level = object$query$level)
```

## Arguments

- object:

  A wsmed_results object, containing every effect to compare.

- contrasts:

  Named list of named numeric weight vectors. Weight names must match
  the term column of as.data.frame(object).

- level:

  Confidence level; defaults to the input result's level.

## Value

A wsmed_results object. Intervals are percentile intervals of the
jointly evaluated contrasts, not differences between confidence limits.
