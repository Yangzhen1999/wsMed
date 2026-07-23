# Summarise Effects with a Continuous Moderator

\`analyze_mm_continuous()\` summarises Monte Carlo draws from a
\`semmcci\` object when the moderator \`W\` is continuous. It reports
moderated path coefficients, conditional indirect effects, conditional
path coefficients, and effect curves across values of the moderator.

## Usage

``` r
analyze_mm_continuous(
  mc_result,
  data,
  MP,
  W_raw_name = "W",
  ci_level = 0.95,
  W_values = NULL,
  n_curve = 120,
  digits = 8
)
```

## Arguments

- mc_result:

  A \`semmcci\` object returned by \`MCMI2()\`.

- data:

  A processed data frame containing the original moderator variable.
  This is typically the first component returned by \`PrepareData()\`.

- W_raw_name:

  A character string giving the name of the moderator variable in
  \`data\`. The default is \`"W"\`.

- ci_level:

  A numeric value between zero and one specifying the two-sided
  confidence level. The default is \`0.95\`.

- W_values:

  An optional numeric vector containing three raw moderator values at
  which to evaluate the conditional effects. If \`NULL\`, the moderator
  mean and values one standard deviation below and above the mean are
  used.

- n_curve:

  A positive integer specifying the number of moderator values used to
  construct each effect curve. The default is \`120\`.

- digits:

  A non-negative integer specifying the number of decimal places used to
  round the reported results. The default is \`3\`.

## Value

A named list with the following components:

- `mod_coeff`:

  A data frame summarising the moderated path coefficients, their
  corresponding base coefficients, and confidence intervals.

- `beta_coef`:

  A data frame containing the conditional indirect effects at the three
  reference values of the moderator.

- `path_HML`:

  A data frame containing the conditional moderated path coefficients at
  the three reference values of the moderator.

- `theta_curve`:

  A data frame containing the conditional indirect effects evaluated
  over the moderator grid.

- `path_curve`:

  A data frame containing the conditional path coefficients evaluated
  over the moderator grid.

## Details

The function first summarises the coefficients associated with moderated
paths, including interaction terms such as \`aw\`, \`bw\`, \`dw\`, and
\`cpw\`, together with their corresponding base coefficients and
confidence intervals.

It then evaluates conditional indirect effects and moderated path
coefficients at three reference values of the moderator. By default,
these values are the moderator mean and one standard deviation below and
above the mean. Alternative reference values can be supplied through
\`W_values\`.

Finally, the function evaluates the conditional indirect effects and
moderated path coefficients over a moderator grid. These results can be
used to plot effect curves or identify regions in which the confidence
interval excludes zero.

An asterisk is added to an effect when its confidence interval excludes
zero.
