# Summarize Monte Carlo Simulation Results

Computes summary statistics for Monte Carlo simulation results,
including the mean estimate, standard error (SE), and confidence
intervals (CIs).

## Usage

``` r
summarize_mc_ci(mc_result, alpha = 0.05)
```

## Arguments

- mc_result:

  A data frame where each column corresponds to a parameter, and each
  row represents one Monte Carlo replication of that parameter's
  estimate.

- alpha:

  Numeric. Significance level used to compute the (1 - alpha) confidence
  interval. Default is 0.05 for a 95% confidence interval.

## Value

A data frame with one row per parameter and the following columns:

- Parameter:

  The name of the parameter.

- Estimate:

  The average estimate across all Monte Carlo replications.

- SE:

  The standard deviation of the estimates (standard error).

- CI_lower:

  The lower bound of the confidence interval.

- CI_upper:

  The upper bound of the confidence interval.
