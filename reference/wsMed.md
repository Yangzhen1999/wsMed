# Within-Subject Mediation Analysis (Two-Condition)

`wsMed()` fits a structural equation model (SEM) for two-condition
within-subject mediation. It can handle missing data (DE, FIML, MI) and
computes both unstandardized and standardized effects with bootstrap or
Monte Carlo confidence intervals.

## Usage

``` r
wsMed(
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
  MP = NULL,
  form = c("P", "CN", "CP", "PC", "UD"),
  Na = c("DE", "FIML", "MI"),
  alpha = 0.05,
  mi_args = list(),
  R = 20000L,
  bootstrap = 2000,
  boot_ci_type = "perc",
  iseed = 123,
  fixed.x = FALSE,
  ci_method = c("mc", "bootstrap", "both"),
  MCmethod = NULL,
  seed = 123,
  standardized = FALSE,
  verbose = FALSE,
  paths = NULL
)
```

## Arguments

- data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) containing the
  raw scores.

- M_C1, M_C2:

  Character vectors of mediator names under condition 1 and 2.

- Y_C1, Y_C2:

  Character scalars for the outcome under each condition.

- C_C1, C_C2:

  Character vectors of within-subject covariates (per condition).

- C:

  Character vector of between-subject covariates.

- C_type:

  Character; type of `C`: `"continuous"` or `"categorical"`.

- W:

  Character vector of moderators. Default `NULL`.

- W_type:

  Character; `"continuous"` or `"categorical"`.

- MP:

  Character vector identifying which regression paths are moderated (for
  example, `"a1"`, `"b_1_2"`, `"cp"`).

- form:

  Model type: `"P"`, `"CN"`, `"CP"`, `"PC"`, or `"UD"`. Use `"UD"` to
  specify a user-defined mediation model.

- Na:

  Missing-data method: `"DE"`, `"FIML"`, or `"MI"`.

- alpha:

  Numeric vector in (0, 1); two-sided significance levels.

- mi_args:

  List of MI-specific controls:

  `m`

  :   Number of imputations. Default 5.

  `method_num`

  :   Imputation method for `mice()`.

  `decomposition`

  :   Covariance-decomposition method (`"eigen"`, `"chol"`, `"svd"`).

  `pd`

  :   Logical; positive-definiteness check.

  `tol`

  :   Tolerance for the positive-definiteness check.

- R:

  Integer; number of Monte Carlo draws. Default `20000L`.

- bootstrap:

  Integer; number of bootstrap replicates (DE and FIML only).

- boot_ci_type:

  Character; bootstrap CI type: `"perc"`, `"bc"`, or `"bca.simple"`.

- iseed, seed:

  Integer seeds for bootstrap and Monte Carlo, respectively.

- fixed.x:

  Logical; passed to lavaan.

- ci_method:

  CI engine: `"bootstrap"` or `"mc"`. If `NULL` (default) the choice is
  `"bootstrap"` for `Na = "DE"` and `"mc"` otherwise.

- MCmethod:

  If `Na = "FIML"` and `ci_method = "mc"`, choose `"mc"` (default) or
  `"bootSD"`.

- standardized:

  Logical; if `TRUE`, return standardized effects. Default `FALSE`.

- verbose:

  Logical; print progress messages.

- paths:

  A character vector defining directed paths when `form = "UD"`. Paths
  are specified using mediator labels `M1`, `M2`, and so on, with `Y`
  denoting the outcome. For example,
  `c("M1 -> M3", "M3 -> Y", "M2 -> Y")`. Must be `NULL` for the
  predefined model forms.

## Value

An object of class `"wsMed"` with elements:

- data:

  Preprocessed data frame.

- sem_model:

  Generated lavaan syntax.

- mc:

  List with Monte Carlo draws, bootstrap tables (if any), and the fitted
  model.

- moderation:

  Conditional or moderated effect tables.

- form,Na,alpha:

  Analysis settings.

- paths:

  The user-defined paths when `form = "UD"`; otherwise `NULL`.

- input_vars:

  Names of all user-supplied variables.

## Details

Model structures:

- `"P"`: parallel mediation

- `"CN"`: chained (serial) mediation

- `"CP"`: chained then parallel

- `"PC"`: parallel then chained

- `"UD"`: user-defined mediation model

Missing-data strategies:

- `"DE"`: list-wise deletion

- `"FIML"`: full-information maximum likelihood

- `"MI"`: multiple imputation via mice

Confidence-interval engines:

- Bootstrap: percentile, BC, or BCa (DE and FIML only)

- Monte Carlo: draws via semmcci (all `Na` options)

For `Na = "FIML"`, you may choose `MCmethod = "mc"` (default) or
`"bootSD"` to add a finite-sample SD correction.

Workflow: (1) preprocess -\> (2) generate SEM syntax -\> (3) fit -\> (4)
compute confidence intervals -\> (5) optional: standardize estimates.

## Examples

``` r
data("example_data", package = "wsMed")
set.seed(123)
result <- wsMed(
  data = example_data,
  M_C1 = c("A2", "B2"),
  M_C2 = c("A1", "B1"),
  Y_C1 = "C1", Y_C2 = "C2",
  form = "P", Na = "DE"
)
print(result)
#> 
#> 
#> *************** VARIABLES ***************
#> Outcome (Y):
#>    Condition 1: C1 
#>    Condition 2: C2 
#> Mediators (M):
#>   M1:
#>     Condition 1: A2
#>     Condition 2: A1
#>   M2:
#>     Condition 1: B2
#>     Condition 2: B1
#> Sample size (rows kept): 100 
#> 
#> 
#> *************** MODEL FIT ***************
#> 
#> 
#> |Measure   |  Value|
#> |:---------|------:|
#> |Chi-Sq    | 11.436|
#> |df        |  5.000|
#> |p         |  0.043|
#> |CFI       |  0.000|
#> |TLI       | -1.130|
#> |RMSEA     |  0.113|
#> |RMSEA Low |  0.018|
#> |RMSEA Up  |  0.202|
#> |SRMR      |  0.076|
#> 
#> 
#> ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
#> 
#> 
#> |Label          | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|--------:|-----:|---------:|----------:|
#> |Total effect   |    0.015| 0.016|    -0.017|      0.047|
#> |Direct effect  |    0.016| 0.016|    -0.016|      0.048|
#> |Total indirect |   -0.001| 0.004|    -0.010|      0.008|
#> 
#> Indirect effects:
#> 
#> 
#> |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |ind_1 |    0.001| 0.003|    -0.005|      0.008|
#> |ind_2 |   -0.002| 0.003|    -0.009|      0.003|
#> 
#> Indirect-effect key:
#> 
#> 
#> |Ind   |Path                 |
#> |:-----|:--------------------|
#> |ind_1 |X -> M1diff -> Ydiff |
#> |ind_2 |X -> M2diff -> Ydiff |
#> 
#> 
#> *************** MODERATION EFFECTS (d-paths, MC) ***************
#> 
#> 
#> |Coefficient | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----------|--------:|-----:|---------:|----------:|
#> |d1          |   -0.062| 0.091|    -0.238|      0.115|
#> |d2          |   -0.073| 0.083|    -0.236|      0.092|
#> 
#> 
#> *************** MODERATION KEY (d-paths) ***************
#> 
#> 
#> |Coefficient |Path           |Moderated       |
#> |:-----------|:--------------|:---------------|
#> |d1          |M1avg -> Ydiff |M1diff -> Ydiff |
#> |d2          |M2avg -> Ydiff |M2diff -> Ydiff |
#> 
#> 
#> *************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************
#> 
#> 
#> |Contrast                  | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-------------------------|--------:|-----:|---------:|----------:|
#> |indirect_2  -  indirect_1 |   -0.003| 0.004|    -0.012|      0.005|
#> 
#> 
#> *************** C1-C2 COEFFICIENTS (No Moderator) ***************
#> 
#> 
#> |Coeff | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |X1_b1 |    0.006| 0.102|    -0.190|      0.205|
#> |X0_b1 |    0.068| 0.102|    -0.135|      0.266|
#> |X1_b2 |    0.077| 0.099|    -0.114|      0.272|
#> |X0_b2 |    0.150| 0.099|    -0.045|      0.344|
#> 
#> 
#> *************** REGRESSION PATHS (MC) ***************
#> 
#> 
#> |Path           |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff ~ M1diff |b1    |    0.036| 0.091|    -0.141|      0.215|
#> |Ydiff ~ M1avg  |d1    |   -0.062| 0.091|    -0.238|      0.115|
#> |Ydiff ~ M2diff |b2    |    0.112| 0.090|    -0.061|      0.291|
#> |Ydiff ~ M2avg  |d2    |   -0.073| 0.083|    -0.236|      0.092|
#> 
#> 
#> *************** INTERCEPTS (MC) ***************
#> 
#> 
#> |Intercept |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:---------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~1   |cp    |    0.016| 0.016|    -0.016|      0.048|
#> |M1diff~1  |a1    |    0.027| 0.018|    -0.008|      0.062|
#> |M2diff~1  |a2    |   -0.014| 0.018|    -0.049|      0.020|
#> |M1avg~1   |      |   -0.000| 0.018|    -0.036|      0.037|
#> |M2avg~1   |      |    0.000| 0.020|    -0.039|      0.039|
#> 
#> 
#> *************** VARIANCES (MC) ***************
#> 
#> 
#> |Variance       |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~~Ydiff   |      |    0.026| 0.004|     0.018|      0.033|
#> |M1diff~~M1diff |      |    0.031| 0.004|     0.022|      0.039|
#> |M2diff~~M2diff |      |    0.032| 0.005|     0.023|      0.041|
#> |M1avg~~M1avg   |      |    0.034| 0.005|     0.024|      0.043|
#> |M2avg~~M2avg   |      |    0.041| 0.006|     0.030|      0.052|
```
