# Analyze two-condition within-subject mediation

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

  Character; `"continuous"` or `"categorical"`. Automatic numeric 0/1
  moderator detection emits a message and is recorded in
  `fit$diagnostics$input_notes`. Use an explicit type or factor for
  consistency with
  [`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md).

- MP:

  Character vector identifying which regression paths are moderated (for
  example, `"a1"`, `"b_1_2"`, `"cp"`). Main effects of W already
  included in each regression are always used when computing conditional
  intercepts, whether or not a/cp is explicitly listed in MP.

- form:

  Model type: `"P"`, `"CN"`, `"CP"`, `"PC"`, or `"UD"`. Use `"UD"` to
  specify a user-defined mediation model. Values are case-insensitive.

- Na:

  Missing-data method: `"DE"`, `"FIML"`, or `"MI"`. Values are
  case-insensitive.

- alpha:

  Numeric vector in (0, 1); two-sided significance levels.

- mi_args:

  List of MI-specific controls:

  `m`

  :   Number of imputations. Default 5.

  `method_num`

  :   Imputation method for `mice()`.

  `completed`

  :   Optional list of completed wide data frames or a `mice` mids
      object. Observed values, rows and factor levels must be preserved.
      The number of imputations is inferred; supplied m must match. Omit
      method_num. With external imputations, seed still controls MC
      only. See
      [`wsmed_fit`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md)
      for model-compatible imputation guidance.

  `decomposition`

  :   Covariance-decomposition method (`"eigen"`, `"chol"`, `"svd"`).
      The default `"eigen"` uses the principal symmetric covariance
      square root; fixed-seed MI draws differ from wsMed 1.1.0.

  `pd`

  :   Logical; positive-definiteness check.

  `tol`

  :   Tolerance for the positive-definiteness check.

- R:

  Integer; number of Monte Carlo draws. Default `20000L`.

- bootstrap:

  Integer; number of bootstrap replicates (DE and FIML only).

- boot_ci_type:

  Character; CI type for stored legacy bootstrap parameter tables:
  `"perc"`, `"bc"`, or `"bca.simple"` (zero acceleration). Current
  effect reports use percentile intervals regardless of this setting.

- iseed, seed:

  Integer seeds for bootstrap and Monte Carlo, respectively.

- fixed.x:

  Logical; passed to lavaan.

- ci_method:

  CI engine: `"mc"`, `"bootstrap"`, or `"both"`. Values are
  case-insensitive. The default (also used for `NULL`) is `"mc"`. With
  `Na = "MI"`, only `"mc"` is supported.

- MCmethod:

  NULL or `"mc"`. The unimplemented `"bootSD"` option is rejected
  explicitly.

- standardized:

  Logical; if `TRUE`, return standardized parameter tables (including
  defined effects at the reference moderator value). Raw conditional
  results remain in moderation; standardized conditional tables and
  curves are added in moderation_std. Default FALSE. This choice is
  saved as the default for print, summary, wsmed_effects and generic
  plot; standardized = TRUE or FALSE on those methods overrides it for
  one query. Raw fitting parameters remain available through coef and
  vcov.

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

  Raw conditional or moderated effect tables.

- moderation_std:

  Standardized conditional tables and curves when standardized=TRUE and
  a moderator is supplied.

- form,Na,alpha:

  Analysis settings.

- paths:

  The user-defined paths when `form = "UD"`; otherwise `NULL`.

- input_vars:

  Names of all user-supplied variables.

- model,fit,inference:

  Structured specification, reusable fit (including all imputation
  fits), and named stored inference objects.

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

- Bootstrap: participant resampling (DE and FIML only)

- Monte Carlo: joint parameter draws via semmcci for DE/FIML, or the
  package's pooled-parameter sampler for MI

Monte Carlo inference uses the existing joint-parameter sampler. The
legacy `MCmethod = "bootSD"` option was accepted but never applied; it
now produces an explicit error rather than silently returning ordinary
MC results.

Standardization divides differences by their marginal model-implied SDs,
without recentering them. Dummy variables retain 0/1 units; interaction
terms use the product of their component scale factors, not the
interaction column SD. MC and bootstrap draws are transformed jointly
with their scales. Current effect reports from print, summary and
wsmed_effects, and confint applied to extracted effects, use percentile
intervals (type-7 quantiles), with or without moderation. The
boot_ci_type argument controls stored legacy parameter-table intervals,
not these effect reports. In standardized legacy tables, bc and
bca.simple apply bias correction with zero acceleration, not full BCa.
Their bootstrap p-values require at least 1000 valid replicates.

Conditional tables use percentile intervals and fixed numerical probes.
With fixed.x=TRUE, scale transformations condition on the fitted
external moments rather than adding sampling uncertainty for those
moments. In MI, probes/centering references use the first completed data
set; fixed.x=TRUE also conditions on its external moments in the pooled
transform. In MI models with products of mediator differences and the
moderator, marginal variances are pooled jointly with primitive
coefficients, including their delta-method within-imputation and Rubin
between-imputation covariance. MC propagates this joint uncertainty.
Endogenous product moments are estimated even with fixed.x=TRUE.

Workflow: (1) preprocess -\> (2) generate SEM syntax -\> (3) fit -\> (4)
compute confidence intervals -\> (5) optional: standardize estimates.
See
[wsmed_categorical](https://yangzhen1999.github.io/wsMed/reference/wsmed_categorical.md)
for supported categorical predictors, reference coding, and missing-data
restrictions. In both interfaces, declare categorical covariates and
moderators as unordered factors with explicit levels before fitting. The
first factor level is the reference group. Existing automatic
recognition of numeric 0/1 predictors is retained in this one-call
interface. The empirical manuscript dataset is available as
[wsmed_examples](https://yangzhen1999.github.io/wsMed/reference/wsmed_examples.md);
[example_data](https://yangzhen1999.github.io/wsMed/reference/example_data.md)
is simulated tutorial data.

The one-call interface uses the same fitting and inference engines as
[`wsmed_model()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_model.md),
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md),
and
[`wsmed_infer()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_infer.md).
Default printing is concise; `print(result, detail = "full")` adds path
coefficients to the structured effect report. Use `detail = "legacy"`
for the original tables. Use
[`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md)
to query stored draws without rerunning the analysis.

## Examples

``` r
data("example_data", package = "wsMed")
result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "D1",
  Y_C2 = "D2"
)
print(result)
#> wsMed analysis
#> Model: P | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -0.031795   0.017000 -0.064525  0.001864
#> indirect_1: M1                         0.001311   0.003208 -0.004601  0.008917
#> indirect_2: M2                        -0.001120   0.002587 -0.007507  0.003186
#> total_indirect: Total indirect effect  0.000191   0.004145 -0.008311  0.008883
#> total: Total effect                   -0.031604   0.017031 -0.064494  0.001789
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
```
