# Prepare Data for Two-Condition Within-Subject Mediation (WsMed)

`PrepareData()` transforms raw pre/post data into the set of variables
required by the **WsMed** workflow. It handles *mediators*, *outcome*,
*within-subject controls*, *between-subject controls*, *moderators*, and
all necessary **interaction terms**, while automatically centering /
dummy-coding variables as needed.

## Usage

``` r
PrepareData(
  data,
  M_C1,
  M_C2,
  Y_C1,
  Y_C2,
  C_C1 = NULL,
  C_C2 = NULL,
  C = NULL,
  C_type = NULL,
  W = NULL,
  W_type = NULL,
  center_W = TRUE,
  keep_W_raw = TRUE,
  keep_C_raw = TRUE
)
```

## Arguments

- data:

  A data frame with the raw pre/post measures.

- M_C1, M_C2:

  Character vectors: mediator names at occasion 1 and 2 (equal length).

- Y_C1, Y_C2:

  Character scalars: outcome names at occasion 1 and 2.

- C_C1, C_C2:

  Optional character vectors: within-subject control names.

- C:

  Optional character vector: between-subject control names.

- C_type:

  Optional vector of the same length as `C`. Each element is one of
  `"continuous"`, `"categorical"`, or `"auto"` (default). Ignored when
  `C = NULL`.

- W:

  Optional character vector: moderator names (one or more).

- W_type:

  Optional vector of the same length as `W`. Same coding as `C_type`.
  Ignored when `W = NULL`.

- center_W:

  Logical. Whether to center the moderator variable `W`.

- keep_W_raw, keep_C_raw:

  Logical. If `TRUE`, keep the original `W` / `C` columns in the
  returned data.

## Value

A data frame containing at minimum:

- `Ydiff`

- `Mi_diff`, `Mi_avg` for each mediator

- centered or dummy-coded `Cb*`, `Cw*diff`, `Cw*avg`

- centered or dummy-coded `W*` and all `int_*` interaction terms

plus the attributes `"W_info"` and `"C_info"` described above.

## Details

The function performs the following steps:

1.  Outcome difference: `Ydiff = Y_C2 - Y_C1`.

2.  Mediator variables for each pair `(M_C1[i], M_C2[i])`:

    - `Mi_diff = M_C2 - M_C1`

    - `Mi_avg` is the mean-centered average of the two occasions.

3.  Between-subject controls `C`:

    - Continuous variables are grand-mean centered (`Cb1`, `Cb2`, ...).

    - Categorical variables (binary or multi-level) are expanded into
      `k - 1` dummy variables (`Cb1_1`, `Cb2_1`, `Cb2_2`, ...), using
      the first level as the reference.

4.  Within-subject controls `Cw`: difference and centered-average
    versions (`Cw1diff`, `Cw1avg`, ...).

5.  Moderators `W` (one or more):

    - Continuous variables are grand-mean centered (`W1`, `W2`, ...).

    - Categorical variables are dummy-coded in the same way as `C`.

6.  Interaction terms between each moderator column and each mediator
    column:

    - `int_<Mi_diff>_<Wj>`, `int_<Mi_avg>_<Wj>`.

7.  Two attributes are added to the returned data:

    - `"W_info"`: raw names, dummy names, level mapping

    - `"C_info"`: same structure for between-subject controls.

Row counts are preserved even if input factors contain NA values
(model.matrix is called with `na.action = na.pass`).

## See also

[`PrepareMissingData`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md),
[`GenerateModelP`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelP.md),
[`wsMed`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)

## Examples

``` r
set.seed(1)
raw <- data.frame(
  A1 = rnorm(50), A2 = rnorm(50),   # mediator 1
  B1 = rnorm(50), B2 = rnorm(50),   # mediator 2
  C1 = rnorm(50), C2 = rnorm(50),   # outcome
  D1 = rnorm(50), D2 = rnorm(50),   # within-subject control
  W_bin  = sample(0:1, 50, TRUE),   # between-subject binary C
  W_fac3 = factor(sample(c("Low","Med","High"), 50, TRUE)) # moderator W
)

prep <- PrepareData(
  data  = raw,
  M_C1  = c("A1","B1"), M_C2 = c("A2","B2"),
  Y_C1  = "C1",         Y_C2 = "C2",
  C_C1  = "D1",         C_C2 = "D2",
  C     = "W_bin",      C_type = "categorical",
  W     = "W_fac3",     W_type = "categorical"
)
head(prep)
#>   W_bin W_fac3       Ydiff     M1diff      M2diff      M1avg       M2avg Cb1_1
#> 1     0    Med -0.27317995  1.0245597  1.07055378 -0.2230613 -0.04728171     0
#> 2     0    Low -1.28170568 -0.7956697 -0.06067571 -0.3230789  0.04958610     0
#> 3     1    Low -1.65624325  1.1767483  0.59285327 -0.3561418 -0.57668693     1
#> 4     1    Med  0.08324346 -2.7246439 -1.08739092  0.1240715 -0.34785861     1
#> 5     0    Low  2.98078634  1.1035159 -0.83287567  0.7723784 -1.03321440     0
#> 6     0    Med -1.35143323  2.8008683 -2.84247957  0.4710784  0.38385556     0
#>       Cw1diff     Cw1avg W1 W2 int_M1diff_W1 int_M1diff_W2 int_M2diff_W1
#> 1  0.69594079  1.1321756  0  1     0.0000000      1.024560    0.00000000
#> 2  1.84029996 -0.2366167  1  0    -0.7956697      0.000000   -0.06067571
#> 3 -1.47564138  1.1240482  1  0     1.1767483      0.000000    0.59285327
#> 4  0.30656699 -0.3398171  0  1     0.0000000     -2.724644    0.00000000
#> 5  0.03947981  1.5644167  1  0     1.1035159      0.000000   -0.83287567
#> 6 -0.80024527  1.0026215  0  1     0.0000000      2.800868    0.00000000
#>   int_M2diff_W2 int_M1avg_W1 int_M1avg_W2 int_M2avg_W1 int_M2avg_W2
#> 1      1.070554    0.0000000   -0.2230613    0.0000000  -0.04728171
#> 2      0.000000   -0.3230789    0.0000000    0.0495861   0.00000000
#> 3      0.000000   -0.3561418    0.0000000   -0.5766869   0.00000000
#> 4     -1.087391    0.0000000    0.1240715    0.0000000  -0.34785861
#> 5      0.000000    0.7723784    0.0000000   -1.0332144   0.00000000
#> 6     -2.842480    0.0000000    0.4710784    0.0000000   0.38385556
```
