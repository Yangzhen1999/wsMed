# Compute Monte Carlo Estimates, Standard Errors, and CIs (with Percent Labels)

`mc_summary_pct()` summarizes a numeric vector of Monte Carlo samples
`x` by computing its mean, standard deviation, and percentile-based
confidence interval. The result is returned as a `data.frame` with
column names that include percentage signs. This function is typically
used to generate tables of mediation effects or path coefficient
estimates with path labels.

Returned columns include:

- `Path`: Path label.

- `Estimate`: Sample mean.

- `SE`: Sample standard deviation.

- `<p%CI.Lo>`, `<p%CI.Up>`: Lower and upper bounds of the percentile CI,
  with `%` in the column names.

## Usage

``` r
mc_summary_pct(x, label, ci_level = 0.95, digits = 3)
```

## Arguments

- x:

  Numeric vector of Monte Carlo samples.

- label:

  Character string for the value in the `Path` column of the output.

- ci_level:

  Confidence level for the CI (default `0.95`).

- digits:

  Number of decimal places to retain (default `3`).

## Value

A `data.frame` containing the path label, estimate, standard error, and
CI. Column names are formatted like `"2.5%CI.Lo"` and `"97.5%CI.Up"`.
