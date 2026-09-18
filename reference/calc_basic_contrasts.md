# Basic Contrasts for Indirect Effects and Pre/Post Path Coefficients

\`calc_basic_contrasts()\` extracts two convenient sets of contrasts
from a Monte-Carlo SEM result (\`semmcci\` object):

1.  All pairwise differences between indirect effects (\`indirect\_\*\`
    columns);

2.  Pre-test (\\X_0\\) and post-test (\\X_1\\) coefficients for every
    primary \\b\\ path, obtained with \\X_1 = (2b + d)/2\\, \\X_0 =
    X_1 - d\\.

## Usage

``` r
calc_basic_contrasts(
  mc_result,
  ci_level = 0.95,
  digits = 3,
  point_estimates = NULL
)
```

## Arguments

- mc_result:

  A Monte-Carlo result of class \`"semmcci"\` (returned by \[MCMI2()\]).

- ci_level:

  Confidence level for the CI (default \`0.95\`).

- digits:

  Decimal places to keep (default \`3\`).

- point_estimates:

  Named fitted parameter estimates, including defined effects.

## Value

A list with up to two data frames:

- IE_contrasts:

  Pairwise contrasts of indirect effects, or \`NULL\` if fewer than two
  are present.

- Xcoef:

  Rows \`X1_b\*\` and \`X0_b\*\` for every detected \\b\\ path, or
  \`NULL\` if no \\b\\ path is found.

## Details

\* Indirect-effect columns are detected by the regular expression
\`^indirect\_\`. \* A primary \\b\\ path is any coefficient named
\`b1\`, \`b_1_2\`, … Its matching \\d\\ path (\`d1\`, \`d_1_2\`, …) is
paired automatically.

Each contrast is summarised with its plug-in estimate, sampling SD, and
a symmetric \\100(1-\alpha)\\ \`mc_summary_pct()\` and
\`fix_pct_names()\` ensure that the final CI columns are named, for
example, \`2.5
