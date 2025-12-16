# Conditional Indirect Effects with a Continuous Moderator

Summarises Monte-Carlo draws from a `semmcci` object when the moderator
*W* is **continuous**. The function outputs:

1.  **mod_coeff** – table of every moderated path coefficient (`aw`,
    `bw`, `dw`, `cpw`) with its base counterpart and 95 % CI;

2.  **beta_coef** – indirect effect at three reference points of *W* (–1
    SD, mean, +1 SD);

3.  **path_HML** – likewise, the moderated primary paths (`a`, `b`, …)
    at the three W levels;

4.  **theta_curve** – full curve of the indirect effect over a
    user-defined grid of centred *W*;

5.  **path_curve** – full curve for every moderated base path.

Significance stars (`"*"`) are added where the CI excludes 0.

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

  A `semmcci` object returned by
  [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md).

- data:

  A processed data frame (first element of
  [`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  output) that contains the raw moderator column.

- W_raw_name:

  Name of the moderator column in `data`. Default `"W"`.

- ci_level:

  Two-sided confidence level (default `0.95`).

- W_values:

  Numeric vector of raw *W* values at which to evaluate “Low / Mid /
  High” effects. If `NULL` (default) the vector \\mean(W) ± 1\\SD\\ is
  used.

- n_curve:

  Integer, number of points used to draw the continuous effect curve
  (default `120`).

- digits:

  Integer, decimal places for rounding (default `3`).

## Value

A named list with components:

- `mod_coeff`:

  Moderated path coefficients (`aw`, `bw`, …).

- `beta_coef`:

  Indirect effect at –1 SD / 0 SD / +1 SD.

- `path_HML`:

  Moderated base paths at the three W levels.

- `theta_curve`:

  Data frame of the indirect effect curve.

- `path_curve`:

  Data frame of each moderated base-path curve.
