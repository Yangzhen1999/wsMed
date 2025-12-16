# Run Monte Carlo-Based Mediation Inference

Performs Monte Carlo simulation to estimate confidence intervals for
both unstandardized and (optionally) standardized mediation parameters,
based on fitted SEM models.

## Usage

``` r
run_mc_mediation(
  fit,
  data,
  standardized = FALSE,
  R = 20000,
  seed = 123,
  alpha = 0.05,
  alphastd = 0.05
)
```

## Arguments

- fit:

  A fitted `lavaan` model.

- data:

  The dataset used for the fitted model.

- standardized:

  Logical. If TRUE, standardized results will also be returned. Default
  is FALSE.

- R:

  Integer. Number of Monte Carlo replications. Default is 20000.

- seed:

  Integer. Random seed for reproducibility. Default is 123.

- alpha:

  Numeric value for the confidence level of unstandardized Monte Carlo
  intervals. Default is 0.05.

- alphastd:

  Numeric value for the confidence level of standardized Monte Carlo
  intervals. Default is 0.05.

## Value

A list with unstandardized and (if requested) standardized results. Each
result includes Monte Carlo estimates, SEs, and CIs.
