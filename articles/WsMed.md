# Using wsMed: A step-by-step tutorial

## Introduction

[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
fits multiple mediation and moderated mediation models for two-condition
within-subject designs. A complete call identifies the paired mediator
and outcome variables, selects the mediation structure, specifies the
estimation options, and, when needed, adds moderators or covariates.

This tutorial shows how to construct a
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
call one step at a time. Each section begins with the same basic call
and changes only the arguments needed for the next part of the analysis.

## Quick start

The following example fits a parallel mediation model with two
mediators. It uses `example_data`, which is included in the package.

``` r

data("example_data", package = "wsMed")
```

``` r

result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)

print(result)
```

The arguments in this call answer four basic questions:

- Which data set should be analyzed?
- Which columns contain the mediator and outcome measurements under the
  two conditions?
- What is the mediation structure?
- How should missing data and confidence intervals be handled?

The following sections explain how to answer each question.

## Step 1: Specify the repeated-measures variables

The data must be in wide format. Each row represents one participant,
and each repeated measure has a separate column for each condition.

The mediator names are supplied through `M_C1` and `M_C2`. Their
positions must match. For example:

``` r

M_C1 = c("A1", "B1")
M_C2 = c("A2", "B2")
```

This tells
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
that `A1` and `A2` are the two measurements of the first mediator,
whereas `B1` and `B2` are the two measurements of the second mediator.
The outcome pair is supplied through `Y_C1` and `Y_C2`:

``` r

Y_C1 = "C1"
Y_C2 = "C2"
```

The variable mapping in the quick-start example is therefore:

| Construct | Condition 1 | Condition 2 | Internal label |
|:----------|:------------|:------------|:---------------|
| A         | `A1`        | `A2`        | `M1`           |
| B         | `B1`        | `B2`        | `M2`           |
| C         | `C1`        | `C2`        | `Y`            |

The internal mediator labels are determined by position. If three
mediators are supplied as follows:

``` r

M_C1 = c("A1", "B1", "C1")
M_C2 = c("A2", "B2", "C2")
```

then A, B, and C are labeled `M1`, `M2`, and `M3`, respectively. This
numbering is especially important when specifying a user-defined model
in Step 2.

[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
automatically prepares the difference and level components used in the
model. Users should supply the original condition-specific columns, not
manually computed difference or average scores.

## Step 2: Choose the mediation structure

The mediation structure is selected with `form`. Users can choose one of
four predefined structures or define the mediator paths themselves.

### Predefined models

The predefined options are:

| `form` | Structure | How the mediators are connected |
|:---|:---|:---|
| `"P"` | Parallel | All mediators operate in parallel. |
| `"CN"` | Chained/serial | The mediators form one serial chain. |
| `"CP"` | Chained–parallel | The first mediator predicts multiple later mediators. |
| `"PC"` | Parallel–chained | Multiple mediators predict one final mediator. |

For a predefined model, the mediator order in `M_C1` and `M_C2`
determines their positions in the structure. To fit a different
predefined structure, replace the value of `form` in the basic call:

``` r

form = "P"
form = "CN"
form = "CP"
form = "PC"
```

For example, the following call fits a three-mediator chained model:

``` r

result_chained <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  form = "CN",
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)
```

Here, the mediator order defines the chain from A (`M1`) to B (`M2`) and
then to C (`M3`).

### User-defined models

Use `form = "UD"` when the intended paths cannot be represented by one
of the four predefined structures. The mediator labels still come from
the order of `M_C1` and `M_C2`, but the paths are supplied through
`paths`.

Suppose A, B, and C are the three mediators and the intended structure
contains:

- a path from A (`M1`) to C (`M3`);
- a path from C (`M3`) to the outcome; and
- a path from B (`M2`) to the outcome.

The path vector is:

``` r

custom_paths <- c(
  "M1 -> M3",
  "M3 -> Y",
  "M2 -> Y"
)
```

Pass this vector to
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
together with `form = "UD"`:

``` r

result_custom <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  form = "UD",
  paths = custom_paths,
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)
```

Only mediator-to-mediator and mediator-to-outcome paths are included in
`paths`. Do not add paths beginning with `X`:
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
automatically adds the condition-to-mediator paths and the direct path
from the condition to the outcome.

The specified mediator structure must be acyclic. Detailed path rules,
parameter labels, generated equations, and indirect-effect definitions
are described in the
[`GenerateModelCustom()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCustom.md)
vignette.

## Step 3: Choose the estimation options

After selecting the mediation structure, choose how to handle missing
data, construct confidence intervals, and, if required, standardize the
effects.

### Missing data and confidence intervals

The `Na` argument selects the missing-data method, and `ci_method`
selects the confidence-interval method.

| `Na` | Missing-data method | Available `ci_method` |
|:---|:---|:---|
| `"DE"` | Listwise deletion | `"mc"`, `"bootstrap"`, or `"both"` |
| `"FIML"` | Full-information maximum likelihood | `"mc"`, `"bootstrap"`, or `"both"` |
| `"MI"` | Multiple imputation | `"mc"` |

For a complete data analysis using Monte Carlo confidence intervals,
use:

``` r

Na = "DE"
ci_method = "mc"
R = 5000
seed = 123
```

`R` controls the number of Monte Carlo draws, and `seed` makes the
results reproducible.

To use bootstrap confidence intervals instead, use:

``` r

Na = "DE"
ci_method = "bootstrap"
bootstrap = 2000
boot_ci_type = "perc"
iseed = 123
```

The supported values of `boot_ci_type` are `"perc"`, `"bc"`, and
`"bca.simple"`. Setting `ci_method = "both"` requests Monte Carlo and
bootstrap intervals in the same analysis.

The following code creates a copy of `example_data` with missing values
for the FIML and multiple-imputation examples:

``` r

set.seed(123)
example_data_missing <- example_data
analysis_variables <- c("A1", "A2", "B1", "B2", "C1", "C2")

for (variable in analysis_variables) {
  missing_rows <- sample(
    seq_len(nrow(example_data_missing)),
    size = ceiling(0.10 * nrow(example_data_missing))
  )
  example_data_missing[missing_rows, variable] <- NA_real_
}
```

For data with missing values, FIML can be requested by changing `Na`:

``` r

result_fiml <- wsMed(
  data = example_data_missing,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "FIML",
  ci_method = "mc",
  R = 5000,
  seed = 123
)
```

For FIML with Monte Carlo intervals, `MCmethod` can be set to `"mc"` or
`"bootSD"`.

Multiple imputation is requested with `Na = "MI"`. Its controls are
supplied through `mi_args`:

``` r

result_mi <- wsMed(
  data = example_data_missing,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "MI",
  ci_method = "mc",
  mi_args = list(
    m = 20,
    method_num = "pmm"
  ),
  R = 5000,
  seed = 123
)
```

Here, `m` is the number of imputed data sets and `method_num` is the
imputation method passed to the multiple-imputation procedure.

### Standardized effects

Set `standardized = TRUE` when standardized path coefficients and
effects are needed:

``` r

result_standardized <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  standardized = TRUE,
  seed = 123
)
```

## Step 4: Add optional model components

Moderators and covariates are added to the same
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
call. They do not require a separate analysis workflow.

### Moderators

A moderated mediation analysis requires three arguments:

- `W` identifies the moderator variable;
- `W_type` specifies whether it is `"continuous"` or `"categorical"`;
  and
- `MP` identifies the paths moderated by `W`.

For example:

``` r

result_moderated <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "CN",
  W = "D3",
  W_type = "continuous",
  MP = c("a1", "b_1_2", "b2", "cp"),
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)
```

In this chained model, `a1` is the condition-to-`M1` path, `b_1_2` is
the `M1`-to-`M2` difference-component path, `b2` is the `M2`-to-outcome
difference-component path, and `cp` is the direct effect. Every label in
`MP` must correspond to a path that exists in the selected model.

The same arguments can be used with `form = "UD"`. For example, the
user-defined model in Step 2 contains the labels `b_1_3`, `b2`, and
`b3`, but it does not contain `b1` because `"M1 -> Y"` was not
specified.

For a categorical moderator, change the relevant arguments:

``` r

W = "Group"
W_type = "categorical"
```

After fitting a moderated model,
[`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
can be used to display conditional effects:

``` r

plot_moderation_curve(
  result_moderated,
  "indirect_effect_1_2"
)

plot_moderation_curve(
  result_moderated,
  "b_1_2"
)
```

The conditional indirect effect used by
[`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
is named `indirect_effect_1_2`; the corresponding indirect effect in the
generated SEM syntax is named `indirect_1_2`.

### Covariates

Within-subject covariates are supplied as matched pairs through `C_C1`
and `C_C2`. Between-subject covariates are supplied through `C`, with
their type identified by `C_type`.

``` r

result_covariates <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  C_C1 = "D1",
  C_C2 = "D2",
  C = "D3",
  C_type = "continuous",
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)
```

In this example, `D1` and `D2` form one within-subject covariate, and
`D3` is a continuous between-subject covariate. The prepared covariate
terms are included in the mediator and outcome regressions.

## Step 5: Inspect the results

Print the fitted object to obtain the main analysis summary:

``` r

print(result)
```

Depending on the selected options, the printed output includes:

- the variables included in the analysis;
- model-fit information;
- regression paths;
- specific indirect effects;
- the total indirect effect;
- the direct and total effects;
- confidence intervals;
- standardized effects; and
- conditional effects for moderated models.

Use
[`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md)
to display the generated model equations:

``` r

printGM(result)
```

Frequently used components of the fitted object can also be accessed
directly:

``` r

result$sem_model       # generated lavaan syntax
result$mc$fit          # fitted lavaan object
result$moderation      # moderation results, when requested
result$paths           # path vector when form = "UD"
```

The exact contents depend on the selected missing-data and
confidence-interval methods.

## Step 6: Interpret the printed results

This section uses two examples to explain the object returned by
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md).
Example 1 describes the output shared by analyses without an external
moderator. Example 2 then focuses on the additional output produced when
a continuous moderator is included.

The explanations follow the order of the sections printed by
[`print()`](https://rdrr.io/r/base/print.html). They describe what each
section contains and how to locate the relevant results; they are not
substantive interpretations of the example data.

### Example 1: A model without an external moderator

The first example fits a parallel mediation model using multiple
imputation and Monte Carlo confidence intervals. Standardized results
are also requested so that all principal output sections are
illustrated.

``` r

result4_mi <- wsMed(
  data = example_data_missing,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "P",
  Na = "MI",
  ci_method = "mc",
  mi_args = list(
    m = 20,
    method_num = "pmm"
  ),
  R = 5000,
  standardized = TRUE,
  seed = 123
)

print(result4_mi)
#> 
#> 
#> *************** VARIABLES ***************
#> Outcome (Y):
#>    Condition 1: C1 
#>    Condition 2: C2 
#> Mediators (M):
#>   M1:
#>     Condition 1: A1
#>     Condition 2: A2
#>   M2:
#>     Condition 1: B1
#>     Condition 2: B2
#> Sample size (rows kept): 100 
#> 
#> 
#> *************** MODEL FIT ***************
#> 
#> 
#> |Measure   |  Value|
#> |:---------|------:|
#> |Chi-Sq    | 13.724|
#> |df        |  5.000|
#> |p         |  0.017|
#> |CFI       |  0.160|
#> |TLI       | -0.512|
#> |RMSEA     |  0.132|
#> |RMSEA Low |  0.051|
#> |RMSEA Up  |  0.218|
#> |SRMR      |  0.083|
#> 
#> 
#> ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
#> 
#> 
#> |Label          | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|--------:|-----:|---------:|----------:|
#> |Total effect   |    0.026| 0.018|    -0.009|      0.060|
#> |Direct effect  |    0.022| 0.017|    -0.012|      0.056|
#> |Total indirect |    0.004| 0.005|    -0.005|      0.015|
#> 
#> Indirect effects:
#> 
#> 
#> |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |ind_1 |    0.004| 0.004|    -0.003|      0.014|
#> |ind_2 |   -0.000| 0.002|    -0.005|      0.004|
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
#> |d1          |    0.031| 0.105|    -0.172|      0.239|
#> |d2          |   -0.096| 0.089|    -0.271|      0.081|
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
#> |indirect_2  -  indirect_1 |   -0.004| 0.005|    -0.015|      0.004|
#> 
#> 
#> *************** C1-C2 COEFFICIENTS (No Moderator) ***************
#> 
#> 
#> |Coeff | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----|--------:|-----:|---------:|----------:|
#> |X1_b1 |   -0.147| 0.105|    -0.347|      0.062|
#> |X0_b1 |   -0.179| 0.109|    -0.396|      0.033|
#> |X1_b2 |   -0.090| 0.105|    -0.297|      0.114|
#> |X0_b2 |    0.004| 0.102|    -0.191|      0.207|
#> 
#> 
#> *************** REGRESSION PATHS (MC) ***************
#> 
#> 
#> |Path           |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff ~ M1diff |b1    |   -0.162| 0.094|    -0.344|      0.022|
#> |Ydiff ~ M1avg  |d1    |    0.031| 0.105|    -0.172|      0.239|
#> |Ydiff ~ M2diff |b2    |   -0.043| 0.094|    -0.224|      0.144|
#> |Ydiff ~ M2avg  |d2    |   -0.096| 0.089|    -0.271|      0.081|
#> 
#> 
#> *************** INTERCEPTS (MC) ***************
#> 
#> 
#> |Intercept |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:---------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~1   |cp    |    0.022| 0.017|    -0.012|      0.056|
#> |M1diff~1  |a1    |   -0.025| 0.020|    -0.063|      0.014|
#> |M2diff~1  |a2    |    0.006| 0.020|    -0.033|      0.045|
#> |M1avg~1   |      |   -0.000| 0.000|    -0.000|     -0.000|
#> |M2avg~1   |      |   -0.000| 0.000|    -0.000|     -0.000|
#> 
#> 
#> *************** VARIANCES (MC) ***************
#> 
#> 
#> |Variance       |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~~Ydiff   |      |    0.024| 0.004|     0.017|      0.032|
#> |M1diff~~M1diff |      |    0.033| 0.006|     0.021|      0.045|
#> |M2diff~~M2diff |      |    0.033| 0.005|     0.023|      0.044|
#> |M1avg~~M1avg   |      |    0.033| 0.000|     0.033|      0.033|
#> |M2avg~~M2avg   |      |    0.040| 0.000|     0.040|      0.040|
#> 
#> 
#> *************** STANDARDIZED (MC) ***************
#> 
#> 
#> |Parameter      | Estimate|    SE|        R|   2.5%| 97.5%|
#> |:--------------|--------:|-----:|--------:|------:|-----:|
#> |cp             |    0.136| 0.108| 5000.000| -0.073| 0.346|
#> |b1             |   -0.185| 0.103| 5000.000| -0.379| 0.023|
#> |d1             |    0.035| 0.115| 5000.000| -0.188| 0.256|
#> |b2             |   -0.049| 0.105| 5000.000| -0.250| 0.159|
#> |d2             |   -0.125| 0.111| 5000.000| -0.330| 0.103|
#> |a1             |   -0.138| 0.113| 5000.000| -0.367| 0.078|
#> |a2             |    0.032| 0.112| 5000.000| -0.182| 0.253|
#> |Ydiff~~Ydiff   |    0.949| 0.052| 5000.000|  0.783| 0.984|
#> |M1diff~~M1diff |    1.000| 0.000| 5000.000|  1.000| 1.000|
#> |M2diff~~M2diff |    1.000| 0.000| 5000.000|  1.000| 1.000|
#> |M1avg~~M1avg   |    1.000| 0.000| 5000.000|  1.000| 1.000|
#> |M1avg~~M2avg   |    0.254| 0.000| 5000.000|  0.254| 0.254|
#> |M2avg~~M2avg   |    1.000| 0.000| 5000.000|  1.000| 1.000|
#> |M1avg~1        |    0.000| 0.000| 5000.000|  0.000| 0.000|
#> |M2avg~1        |    0.000| 0.000| 5000.000|  0.000| 0.000|
#> |indirect_1     |    0.026| 0.026| 5000.000| -0.016| 0.085|
#> |indirect_2     |   -0.002| 0.013| 5000.000| -0.030| 0.027|
#> |total_indirect |    0.024| 0.029| 5000.000| -0.028| 0.089|
#> |total_effect   |    0.160| 0.110| 5000.000| -0.055| 0.383|
```

The output sections and their main purposes are:

| Printed section | What it answers |
|:---|:---|
| `VARIABLES` | Which observed variables and how many cases were used? |
| `MODEL FIT` | How well does the complete SEM reproduce the observed covariance structure? |
| `TOTAL / DIRECT / TOTAL-IND` | What are the overall, direct, and combined indirect effects? |
| `Indirect effects` and `Indirect-effect key` | What is the estimate for each mediation route, and which route does each label represent? |
| `MODERATION EFFECTS (d-paths)` and its key | What are the level-component coefficients associated with the mediator paths? |
| `CONTRAST INDIRECT EFFECTS` | How do the specific indirect effects differ from one another? |
| `C1-C2 COEFFICIENTS` | What are the reconstructed coefficients for the two conditions? |
| `REGRESSION PATHS` | What are the estimates for the individual regression paths? |
| `INTERCEPTS` | What are the estimated difference-score intercepts, including the `a` and `cp` paths? |
| `VARIANCES` | What are the estimated residual variances? |
| `STANDARDIZED` | What are the standardized estimates and confidence intervals? |

The suffix in a heading identifies the requested confidence-interval
engine. For example, `(MC)` denotes Monte Carlo results. When bootstrap
intervals are requested, the corresponding bootstrap output is printed;
with `ci_method = "both"`, both sets of results can be returned.

#### Variables and analysis sample

The `VARIABLES` section restates the condition-specific outcome and
mediator columns. It also maps each mediator pair to its internal label
(`M1`, `M2`, and so on) and reports the number of rows retained for the
analysis.

This section should be checked before interpreting any estimates. In
particular, verify that:

- the Condition 1 and Condition 2 columns have not been reversed;
- the order of the mediator pairs matches the intended model; and
- the retained sample size is consistent with the selected missing-data
  method.

#### Model fit

The `MODEL FIT` section reports the model chi-squared statistic, degrees
of freedom, its $`p`$ value, CFI, TLI, RMSEA with its confidence
interval, and SRMR. These indices evaluate the model as a whole; they do
not test an individual direct or indirect effect.

Fit indices should be interpreted in light of the fitted model. For a
just-identified or saturated model, global fit is perfect by
construction and does not provide evidence that the individual paths are
substantively appropriate.

#### Total, direct, and indirect effects

The `TOTAL / DIRECT / TOTAL-IND` section gives a compact decomposition:

``` math
\text{total effect}
=
\text{direct effect}
+
\text{total indirect effect}.
```

The rows have the following meanings:

- `Total effect` is the overall condition effect on the outcome
  difference.
- `Direct effect` is the remaining condition effect after accounting for
  the mediators; its model label is `cp`.
- `Total indirect` is the sum of all specific indirect effects
  identified by the selected mediation structure.

The `Indirect effects` table then reports each specific route
separately. The accompanying `Indirect-effect key` should be used to
translate a printed label into a path. For example, a key may map
`ind_1` to `X -> M1diff -> Ydiff`. For serial or user-defined models, a
label can refer to a route through more than one mediator.

Each row reports an estimate, its standard error, and confidence limits.
For an indirect effect, inference should be based on the confidence
interval for the complete product rather than on whether every component
path is individually significant. An interval that excludes zero
provides evidence that the corresponding effect differs from zero at the
stated confidence level.

#### Level-component paths and condition-specific coefficients

The printed heading `MODERATION EFFECTS (d-paths)` can appear even when
no external moderator was supplied through `W`. In this section, the `d`
coefficients are the effects of mediator level components, such as
`M1avg`, in the outcome or mediator-difference equation. They are part
of the within-subject parameterization and should not be confused with
moderation by a user-supplied variable.

The associated key maps each `d` label to its regression path. For a
direct mediator-to-outcome path, the difference-component and
level-component terms appear together, for example:

``` text
Ydiff ~ b1 * M1diff + d1 * M1avg
```

The `C1-C2 COEFFICIENTS` section expresses this pair as coefficients for
the two conditions. It is useful when the research question concerns
whether the corresponding mediator-to-outcome relation is the same under
both conditions. The `b` coefficient summarizes the common component,
whereas the `d` coefficient captures the difference between the two
condition-specific coefficients.

#### Contrasts between indirect effects

When the model contains more than one specific indirect effect,
`CONTRAST INDIRECT EFFECTS` reports pairwise differences between them. A
contrast should be read according to the order shown in its label. For
example:

``` text
indirect_2 - indirect_1
```

compares the second specific indirect effect with the first. Its
confidence interval evaluates the difference between the two effects,
not whether either effect separately differs from zero.

#### Regression paths, intercepts, and variances

`REGRESSION PATHS` lists the individual regression coefficients in the
generated SEM. The `Path` column shows the regression in `lavaan`
notation, whereas `Label` gives the name used elsewhere in the output
and in `MP`. Common labels include:

- `b1`, `b2`, and so on for mediator difference-component paths to the
  outcome;
- `d1`, `d2`, and so on for the corresponding level-component paths; and
- labels such as `b_1_2` and `d_1_2` for paths from one mediator to
  another.

`INTERCEPTS` contains the `a` paths and the direct effect because, after
the paired measurements are transformed, the condition effects are
represented as intercepts of the difference-score equations. Thus, `a1`
is found on the `M1diff ~ 1` row, and `cp` is found on the `Ydiff ~ 1`
row.

`VARIANCES` reports the estimated residual variances for the endogenous
difference components and any other modeled variables. These rows
describe unexplained variability; they are not additional mediation
effects.

#### Standardized results

The `STANDARDIZED` section is printed when `standardized = TRUE`. It
contains standardized versions of the path coefficients and derived
effects, including the specific indirect, total indirect, and total
effects when available.

Standardized and unstandardized results answer different reporting
needs. Unstandardized estimates retain the scale of the original
variables, whereas standardized estimates facilitate comparisons across
variables or effects. A report should state explicitly which version is
presented and should not combine an unstandardized estimate with a
standardized confidence interval.

#### Inspecting and extracting Example 1

Use
[`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md)
to connect the printed labels to the generated model:

``` r

printGM(result4_mi)
```

The returned object can also be inspected programmatically:

``` r

names(result4_mi)

result4_mi$input_vars    # variables supplied to wsMed()
result4_mi$sem_model     # generated lavaan syntax
result4_mi$mc$fit        # fitted lavaan model
result4_mi$mc$result     # Monte Carlo results
result4_mi$mc$std_mc     # standardized Monte Carlo results
```

`print(result4_mi)` is intended for reading the analysis summary,
whereas the stored components are intended for inspection or downstream
programming.

### Example 2: A model with a continuous moderator

The second example fits a chained–parallel model and adds `D3` as a
continuous moderator. The paths listed in `MP` are allowed to vary with
the moderator.

``` r

result5 <- wsMed(
  data = example_data_missing,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  form = "CP",
  W = "D3",
  W_type = "continuous",
  MP = c("a1", "b2", "d1", "cp", "b_1_2", "d_1_2"),
  Na = "DE",
  ci_method = "mc",
  R = 5000,
  seed = 123
)

print(result5)
#> 
#> 
#> *************** VARIABLES ***************
#> Outcome (Y):
#>    Condition 1: D1 
#>    Condition 2: D2 
#> Mediators (M):
#>   M1:
#>     Condition 1: A1
#>     Condition 2: A2
#>   M2:
#>     Condition 1: B1
#>     Condition 2: B2
#>   M3:
#>     Condition 1: C1
#>     Condition 2: C2
#> Moderators (W):
#>    W1 : D3 
#> Sample size (rows kept): 100 
#> 
#> 
#> *************** MODEL FIT ***************
#> 
#> 
#> |Measure   |  Value|
#> |:---------|------:|
#> |Chi-Sq    | 14.576|
#> |df        | 16.000|
#> |p         |  0.556|
#> |CFI       |  1.000|
#> |TLI       | -2.294|
#> |RMSEA     |  0.000|
#> |RMSEA Low |  0.000|
#> |RMSEA Up  |  0.111|
#> |SRMR      |  0.048|
#> 
#> 
#> ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
#> 
#> 
#> |Label          | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:--------------|--------:|-----:|---------:|----------:|
#> |Total effect   |   -0.032| 0.024|    -0.076|      0.016|
#> |Direct effect  |   -0.029| 0.023|    -0.074|      0.016|
#> |Total indirect |   -0.003| 0.008|    -0.019|      0.013|
#> 
#> Indirect effects:
#> 
#> 
#> |Label   | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-------|--------:|-----:|---------:|----------:|
#> |ind_1   |    0.002| 0.005|    -0.007|      0.014|
#> |ind_2   |    0.000| 0.004|    -0.008|      0.008|
#> |ind_1_2 |   -0.000| 0.002|    -0.003|      0.004|
#> |ind_3   |   -0.004| 0.006|    -0.018|      0.005|
#> |ind_1_3 |   -0.001| 0.001|    -0.004|      0.001|
#> 
#> Indirect-effect key:
#> 
#> 
#> |Ind     |Path                           |
#> |:-------|:------------------------------|
#> |ind_1   |X -> M1diff -> Ydiff           |
#> |ind_2   |X -> M2diff -> Ydiff           |
#> |ind_1_2 |X -> M1diff -> M2diff -> Ydiff |
#> |ind_3   |X -> M3diff -> Ydiff           |
#> |ind_1_3 |X -> M1diff -> M3diff -> Ydiff |
#> 
#> 
#> *************** MODERATION EFFECTS (d-paths, MC) ***************
#> 
#> 
#> |Coefficient | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:-----------|--------:|-----:|---------:|----------:|
#> |d1          |   -0.040| 0.124|    -0.290|      0.202|
#> |d2          |   -0.000| 0.129|    -0.249|      0.256|
#> |d3          |   -0.160| 0.142|    -0.434|      0.122|
#> |d_1_2       |   -0.044| 0.107|    -0.251|      0.167|
#> |d_1_3       |    0.088| 0.115|    -0.134|      0.312|
#> 
#> 
#> *************** MODERATION KEY (d-paths) ***************
#> 
#> 
#> |Coefficient |Path            |Moderated        |
#> |:-----------|:---------------|:----------------|
#> |d1          |M1avg -> Ydiff  |M1diff -> Ydiff  |
#> |d2          |M2avg -> Ydiff  |M2diff -> Ydiff  |
#> |d3          |M3avg -> Ydiff  |M3diff -> Ydiff  |
#> |d_1_2       |M1avg -> M2diff |M1diff -> M2diff |
#> |d_1_3       |M1avg -> M3diff |M1diff -> M3diff |
#> 
#> 
#> *************** MODERATION RESULTS (Continuous Moderator) ***************
#> 
#> --- Moderated Coefficients ---
#> 
#> 
#> |Path      |BaseCoef |W_dummy | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|Sig |
#> |:---------|:--------|:-------|--------:|-----:|---------:|----------:|:---|
#> |cpw_W1    |cp       |D3      |   -0.172| 0.101|    -0.369|      0.022|    |
#> |dw1_W1    |d1       |D3      |   -0.103| 0.666|    -1.402|      1.204|    |
#> |bw2_W1    |b2       |D3      |   -0.520| 0.667|    -1.856|      0.781|    |
#> |aw1_W1    |a1       |D3      |    0.057| 0.098|    -0.134|      0.258|    |
#> |bw_1_2_W1 |b_1_2    |D3      |   -0.296| 0.545|    -1.373|      0.721|    |
#> |dw_1_2_W1 |d_1_2    |D3      |    0.592| 0.601|    -0.596|      1.755|    |
#> 
#> --- Conditional Indirect Effects ---
#> 
#> 
#> |Path                |Mediators | Level| W_value| Estimate|    SE| 2.5.%CI.Lo| 97.5.%CI.Up|Sig |
#> |:-------------------|:---------|-----:|-------:|--------:|-----:|----------:|-----------:|:---|
#> |indirect_effect_1   |1         | -1 SD|   0.223|    0.003| 0.007|     -0.010|       0.021|    |
#> |indirect_effect_1   |1         |  0 SD|   0.452|    0.002| 0.005|     -0.007|       0.014|    |
#> |indirect_effect_1   |1         | +1 SD|   0.681|    0.001| 0.005|     -0.009|       0.014|    |
#> |indirect_effect_1_2 |1 2       | -1 SD|   0.223|   -0.002| 0.005|     -0.013|       0.006|    |
#> |indirect_effect_1_2 |1 2       |  0 SD|   0.452|    0.000| 0.002|     -0.003|       0.004|    |
#> |indirect_effect_1_2 |1 2       | +1 SD|   0.681|    0.000| 0.002|     -0.004|       0.006|    |
#> |indirect_effect_1_3 |1 3       | -1 SD|   0.223|   -0.001| 0.002|     -0.006|       0.001|    |
#> |indirect_effect_1_3 |1 3       |  0 SD|   0.452|   -0.001| 0.001|     -0.004|       0.001|    |
#> |indirect_effect_1_3 |1 3       | +1 SD|   0.681|   -0.000| 0.001|     -0.004|       0.002|    |
#> |indirect_effect_2   |2         | -1 SD|   0.223|    0.002| 0.006|     -0.009|       0.016|    |
#> |indirect_effect_2   |2         |  0 SD|   0.452|    0.000| 0.004|     -0.008|       0.008|    |
#> |indirect_effect_2   |2         | +1 SD|   0.681|   -0.002| 0.006|     -0.016|       0.009|    |
#> 
#> --- Indirect Effect Contrasts ---
#> 
#> 
#> |Path                |            Contrast| Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|Sig |
#> |:-------------------|-------------------:|--------:|-----:|---------:|----------:|:---|
#> |indirect_effect_1   | (0 SD)   -  (-1 SD)|    0.001| 0.004|    -0.006|      0.011|    |
#> |indirect_effect_1   | (+1 SD)  -  (-1 SD)|    0.002| 0.008|    -0.012|      0.023|    |
#> |indirect_effect_1   | (+1 SD)  -   (0 SD)|    0.001| 0.004|    -0.006|      0.011|    |
#> |indirect_effect_1_2 | (0 SD)   -  (-1 SD)|   -0.002| 0.004|    -0.012|      0.004|    |
#> |indirect_effect_1_2 | (+1 SD)  -  (-1 SD)|   -0.002| 0.005|    -0.015|      0.007|    |
#> |indirect_effect_1_2 | (+1 SD)  -   (0 SD)|   -0.000| 0.002|    -0.005|      0.004|    |
#> |indirect_effect_1_3 | (0 SD)   -  (-1 SD)|   -0.000| 0.001|    -0.003|      0.001|    |
#> |indirect_effect_1_3 | (+1 SD)  -  (-1 SD)|   -0.001| 0.002|    -0.006|      0.003|    |
#> |indirect_effect_1_3 | (+1 SD)  -   (0 SD)|   -0.000| 0.001|    -0.003|      0.001|    |
#> |indirect_effect_2   | (0 SD)   -  (-1 SD)|    0.002| 0.005|    -0.006|      0.013|    |
#> |indirect_effect_2   | (+1 SD)  -  (-1 SD)|    0.003| 0.009|    -0.013|      0.027|    |
#> |indirect_effect_2   | (+1 SD)  -   (0 SD)|    0.002| 0.005|    -0.006|      0.013|    |
#> 
#> --- Moderated Path Coefficients ---
#> 
#> 
#> |Path  | Level| W_value| Estimate|    SE| 2.5.%CI.Lo| 97.5.%CI.Up|Sig |
#> |:-----|-----:|-------:|--------:|-----:|----------:|-----------:|:---|
#> |a1    | -1 SD|   0.223|   -0.039| 0.033|     -0.104|       0.022|    |
#> |a1    |  0 SD|   0.452|   -0.026| 0.023|     -0.070|       0.018|    |
#> |a1    | +1 SD|   0.681|   -0.013| 0.032|     -0.076|       0.047|    |
#> |b2    | -1 SD|   0.223|    0.119| 0.205|     -0.281|       0.518|    |
#> |b2    |  0 SD|   0.452|    0.000| 0.138|     -0.271|       0.275|    |
#> |b2    | +1 SD|   0.681|   -0.119| 0.207|     -0.523|       0.288|    |
#> |d1    | -1 SD|   0.223|   -0.020| 0.205|     -0.440|       0.372|    |
#> |d1    |  0 SD|   0.452|   -0.044| 0.124|     -0.290|       0.202|    |
#> |d1    | +1 SD|   0.681|   -0.067| 0.188|     -0.437|       0.298|    |
#> |cp    | -1 SD|   0.223|   -0.022| 0.018|     -0.057|       0.012|    |
#> |cp    |  0 SD|   0.452|   -0.029| 0.023|     -0.074|       0.016|    |
#> |cp    | +1 SD|   0.681|   -0.036| 0.029|     -0.091|       0.019|    |
#> |b_1_2 | -1 SD|   0.223|    0.372| 0.169|      0.046|       0.701|*   |
#> |b_1_2 |  0 SD|   0.452|    0.304| 0.116|      0.076|       0.531|*   |
#> |b_1_2 | +1 SD|   0.681|    0.236| 0.172|     -0.093|       0.569|    |
#> |d_1_2 | -1 SD|   0.223|   -0.180| 0.172|     -0.515|       0.155|    |
#> |d_1_2 |  0 SD|   0.452|   -0.044| 0.107|     -0.251|       0.167|    |
#> |d_1_2 | +1 SD|   0.681|    0.091| 0.177|     -0.252|       0.446|    |
#> 
#> --- Path Coefficient Contrasts ---
#> 
#> 
#> |Path  |            Contrast| Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|Sig |
#> |:-----|-------------------:|--------:|-----:|---------:|----------:|:---|
#> |a1    | (0 SD)   -  (-1 SD)|   -0.013| 0.023|    -0.059|      0.031|    |
#> |a1    | (+1 SD)  -  (-1 SD)|   -0.026| 0.045|    -0.118|      0.061|    |
#> |a1    | (+1 SD)  -   (0 SD)|   -0.013| 0.023|    -0.059|      0.031|    |
#> |b_1_2 | (0 SD)   -  (-1 SD)|    0.068| 0.125|    -0.165|      0.315|    |
#> |b_1_2 | (+1 SD)  -  (-1 SD)|    0.136| 0.250|    -0.331|      0.630|    |
#> |b_1_2 | (+1 SD)  -   (0 SD)|    0.068| 0.125|    -0.165|      0.315|    |
#> |b2    | (0 SD)   -  (-1 SD)|    0.119| 0.153|    -0.179|      0.425|    |
#> |b2    | (+1 SD)  -  (-1 SD)|    0.238| 0.306|    -0.358|      0.851|    |
#> |b2    | (+1 SD)  -   (0 SD)|    0.119| 0.153|    -0.179|      0.425|    |
#> |cp    | (0 SD)   -  (-1 SD)|    0.007| 0.005|    -0.004|      0.017|    |
#> |cp    | (+1 SD)  -  (-1 SD)|    0.013| 0.011|    -0.007|      0.034|    |
#> |cp    | (+1 SD)  -   (0 SD)|    0.007| 0.005|    -0.004|      0.017|    |
#> |d_1_2 | (0 SD)   -  (-1 SD)|   -0.136| 0.138|    -0.402|      0.137|    |
#> |d_1_2 | (+1 SD)  -  (-1 SD)|   -0.271| 0.275|    -0.805|      0.273|    |
#> |d_1_2 | (+1 SD)  -   (0 SD)|   -0.136| 0.138|    -0.402|      0.137|    |
#> |d1    | (0 SD)   -  (-1 SD)|    0.024| 0.153|    -0.276|      0.321|    |
#> |d1    | (+1 SD)  -  (-1 SD)|    0.047| 0.305|    -0.552|      0.643|    |
#> |d1    | (+1 SD)  -   (0 SD)|    0.024| 0.153|    -0.276|      0.321|    |
#> 
#> --- Conditional Total Effect and Total Indirect Effect ---
#> 
#> 
#> |Effect         | Level| W_value| Estimate|    SE| 2.5.%CI.Lo| 97.5.%CI.Up|Sig |
#> |:--------------|-----:|-------:|--------:|-----:|----------:|-----------:|:---|
#> |total_indirect | -1 SD|   0.223|    0.002| 0.009|     -0.016|       0.022|    |
#> |total_indirect |  0 SD|   0.452|    0.002| 0.006|     -0.010|       0.015|    |
#> |total_indirect | +1 SD|   0.681|   -0.000| 0.008|     -0.017|       0.016|    |
#> |total_effect   | -1 SD|   0.223|    0.012| 0.034|     -0.053|       0.077|    |
#> |total_effect   |  0 SD|   0.452|   -0.028| 0.024|     -0.074|       0.018|    |
#> |total_effect   | +1 SD|   0.681|   -0.069| 0.033|     -0.132|      -0.005|*   |
#> 
#> 
#> *************** REGRESSION PATHS (MC) ***************
#> 
#> 
#> |Path                   |Label     | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:----------------------|:---------|--------:|-----:|---------:|----------:|
#> |Ydiff ~ M1diff         |b1        |   -0.085| 0.133|    -0.346|      0.175|
#> |Ydiff ~ M1avg          |d1        |   -0.040| 0.124|    -0.290|      0.202|
#> |Ydiff ~ M2diff         |b2        |    0.002| 0.138|    -0.271|      0.275|
#> |Ydiff ~ M2avg          |d2        |   -0.000| 0.129|    -0.249|      0.256|
#> |Ydiff ~ M3diff         |b3        |   -0.182| 0.130|    -0.438|      0.076|
#> |Ydiff ~ M3avg          |d3        |   -0.160| 0.142|    -0.434|      0.122|
#> |Ydiff ~ W1             |cpw_W1    |   -0.173| 0.101|    -0.369|      0.022|
#> |Ydiff ~ int_M1avg_W1   |dw1_W1    |   -0.114| 0.666|    -1.402|      1.204|
#> |Ydiff ~ int_M2diff_W1  |bw2_W1    |   -0.514| 0.667|    -1.856|      0.781|
#> |M1diff ~ W1            |aw1_W1    |    0.056| 0.098|    -0.134|      0.258|
#> |M2diff ~ M1diff        |b_1_2     |    0.306| 0.116|     0.076|      0.531|
#> |M2diff ~ M1avg         |d_1_2     |   -0.044| 0.107|    -0.251|      0.167|
#> |M2diff ~ W1            |          |    0.007| 0.097|    -0.182|      0.193|
#> |M2diff ~ int_M1diff_W1 |bw_1_2_W1 |   -0.300| 0.545|    -1.373|      0.721|
#> |M2diff ~ int_M1avg_W1  |dw_1_2_W1 |    0.593| 0.601|    -0.596|      1.755|
#> |M3diff ~ M1diff        |b_1_3     |   -0.147| 0.121|    -0.385|      0.094|
#> |M3diff ~ M1avg         |d_1_3     |    0.088| 0.115|    -0.134|      0.312|
#> |M3diff ~ W1            |          |   -0.081| 0.096|    -0.268|      0.102|
#> 
#> 
#> *************** INTERCEPTS (MC) ***************
#> 
#> 
#> |Intercept       |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:---------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~1         |cp    |   -0.029| 0.023|    -0.074|      0.016|
#> |M1diff~1        |a1    |   -0.026| 0.023|    -0.070|      0.018|
#> |M2diff~1        |a2    |    0.014| 0.022|    -0.028|      0.056|
#> |M3diff~1        |a3    |    0.023| 0.022|    -0.021|      0.066|
#> |M1avg~1         |      |   -0.014| 0.026|    -0.067|      0.035|
#> |M2avg~1         |      |    0.001| 0.025|    -0.049|      0.050|
#> |M3avg~1         |      |   -0.012| 0.023|    -0.060|      0.033|
#> |W1~1            |      |    0.004| 0.031|    -0.056|      0.064|
#> |int_M1avg_W1~1  |      |    0.009| 0.005|    -0.000|      0.017|
#> |int_M2diff_W1~1 |      |    0.002| 0.004|    -0.007|      0.011|
#> |int_M1diff_W1~1 |      |    0.003| 0.005|    -0.008|      0.013|
#> 
#> 
#> *************** VARIANCES (MC) ***************
#> 
#> 
#> |Variance                     |Label | Estimate|    SE| 2.5%CI.Lo| 97.5%CI.Up|
#> |:----------------------------|:-----|--------:|-----:|---------:|----------:|
#> |Ydiff~~Ydiff                 |      |    0.027| 0.005|     0.018|      0.037|
#> |M1diff~~M1diff               |      |    0.031| 0.006|     0.020|      0.042|
#> |M2diff~~M2diff               |      |    0.025| 0.005|     0.016|      0.034|
#> |M3diff~~M3diff               |      |    0.027| 0.005|     0.017|      0.037|
#> |M1avg~~M1avg                 |      |    0.038| 0.007|     0.024|      0.053|
#> |M2avg~~M2avg                 |      |    0.038| 0.007|     0.024|      0.051|
#> |M3avg~~M3avg                 |      |    0.031| 0.006|     0.020|      0.043|
#> |W1~~W1                       |      |    0.054| 0.010|     0.034|      0.074|
#> |int_M1avg_W1~~int_M1avg_W1   |      |    0.001| 0.000|     0.001|      0.002|
#> |int_M2diff_W1~~int_M2diff_W1 |      |    0.001| 0.000|     0.001|      0.002|
#> |int_M1diff_W1~~int_M1diff_W1 |      |    0.002| 0.000|     0.001|      0.002|
```

Most printed sections have the same interpretation as in Example 1. The
important additions are:

| Additional output | What it contains |
|:---|:---|
| Moderator in `VARIABLES` | The observed variable mapped to the internal moderator label, such as `W1`. |
| `Moderated Coefficients` | Interaction terms for the paths named in `MP`. |
| `Conditional Indirect Effects` | Indirect effects evaluated at selected moderator values. |
| `Indirect Effect Contrasts` | Differences between conditional indirect effects at those values. |
| `Moderated Path Coefficients` | The selected path coefficients evaluated at each moderator value. |
| `Path Coefficient Contrasts` | Differences between conditional path coefficients. |
| `Conditional Total Effect and Total Indirect Effect` | Overall and combined indirect effects evaluated at each moderator value. |

#### Moderated coefficients

The `Moderated Coefficients` table reports the interaction term
associated with each path in `MP`. The `BaseCoef` column links the
interaction to the original path. For example, a row whose base
coefficient is `a1` indicates whether the condition-to-`M1` path changes
with `D3`.

The interaction estimate describes the expected change in the base path
for a one-unit increase in the moderator. Its confidence interval
evaluates whether that change differs from zero. This table should be
consulted before interpreting the pattern of conditional path
coefficients.

Because the continuous moderator is centered during data preparation,
the ordinary path estimates in the main output refer to the value
represented by centered $`W=0`$, typically the sample mean of the
original moderator. The conditional tables make the values used for
interpretation explicit.

#### Conditional effects

For a continuous moderator, conditional results are commonly reported at
three reference levels:

- one standard deviation below the mean (`-1 SD`);
- the mean (`0 SD`); and
- one standard deviation above the mean (`+1 SD`).

The `W_value` column gives the corresponding value on the moderator’s
original scale. The `Estimate`, `SE`, and confidence-limit columns
describe the effect at that value of $`W`$.

`Conditional Indirect Effects` reports how each mediation route changes
across these values. Labels used here have the prefix
`indirect_effect_`. For example:

``` text
indirect_effect_1_2
```

refers to the conditional indirect route through `M1` and `M2`. This
name is used by the moderation output and plotting functions. The
corresponding defined parameter in the generated SEM uses:

``` text
indirect_1_2
```

The `Indirect Effect Contrasts` table directly compares the conditional
indirect effect between moderator levels. These contrasts answer whether
the indirect effect changes between the selected values; they are
distinct from testing the indirect effect against zero at any one value.

`Moderated Path Coefficients` and `Path Coefficient Contrasts` provide
the same two views for the individual paths listed in `MP`. The first
table shows each conditional coefficient, and the second tests
differences between the selected moderator levels.

Finally, `Conditional Total Effect and Total Indirect Effect` combines
the relevant paths at each moderator value. When a specific indirect
effect is of primary interest, its row in `Conditional Indirect Effects`
should still be reported separately rather than relying only on the
conditional total indirect effect.

#### Significance markers and confidence intervals

The `Sig` column provides a compact marker when the reported confidence
interval excludes zero. The confidence limits should remain the primary
basis for interpretation because they show both the direction and
precision of the estimate.

A blank marker does not show that two moderator levels are equivalent.
To evaluate a difference between levels, use the relevant contrast table
rather than comparing the two significance markers.

#### Visualizing conditional effects

[`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
displays a conditional indirect effect, an individual path coefficient,
or a total effect across the observed range of a continuous moderator:

``` r

plot_moderation_curve(
  result5,
  "indirect_effect_1_2"
)

plot_moderation_curve(
  result5,
  "b_1_2"
)

plot_moderation_curve(
  result5,
  "total_effect"
)
```

The first call uses a conditional-effect label from the moderation
output. The second uses an individual model-path label. The third
displays the conditional total effect. The curve shows the estimated
effect over $`W`$, the confidence band shows its uncertainty, and the
zero reference line indicates where the interval changes from including
to excluding zero.

Available curve labels can be checked before plotting:

``` r

names(result5$moderation)

unique(result5$moderation$theta_curve$Path)
unique(result5$moderation$path_curve$Path)
```

When `ci_method = "both"`, the Monte Carlo and bootstrap moderation
results are stored separately. Select the desired branch before
accessing its curve data:

``` r

result_both$moderation$mc$theta_curve
result_both$moderation$boot$theta_curve
```

### What to report

The exact reporting format depends on the research question, but a
reproducible summary should identify:

1.  the selected model form and the order of the mediators;
2.  the missing-data method and confidence-interval method;
3.  the number of Monte Carlo draws or bootstrap samples;
4.  model-fit information when it is informative for the fitted model;
5.  the direct, specific indirect, total indirect, and total effects,
    with confidence intervals;
6.  whether the reported estimates are standardized or unstandardized;
    and
7.  for moderated models, the moderator, the paths in `MP`, their
    interaction estimates, and the relevant conditional effects or
    contrasts.

For every indirect-effect label, use the printed key or
[`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md)
to verify the exact mediator route before reporting it.

## Further model details

This tutorial focuses on constructing and running
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
calls. The model-generation vignettes provide the corresponding
equations, parameter-label conventions, and indirect-effect definitions:

- [`GenerateModelP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelP.md)
  for parallel models;
- [`GenerateModelCN()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCN.md)
  for chained models;
- [`GenerateModelCP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCP.md)
  for chained–parallel models;
- [`GenerateModelPC()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelPC.md)
  for parallel–chained models; and
- [`GenerateModelCustom()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCustom.md)
  for user-defined models.

These vignettes are most useful when users need to inspect how a
selected structure is translated into `lavaan` syntax or determine the
label of a path supplied through `MP`.

## Summary

A [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
analysis can be completed in six steps:

1.  Supply matched mediator and outcome variables for the two
    conditions.
2.  Select a predefined model with `form`, or use `form = "UD"` together
    with `paths`.
3.  Choose `Na`, `ci_method`, and whether standardized effects are
    required.
4.  Add moderators or covariates when they are part of the analysis.
5.  Print the fitted object and inspect the generated model.
6.  Read the shared output first, then interpret any additional
    conditional results for a moderated model.

The same basic call is therefore used across simple, user-defined,
missing-data, moderated, and covariate-adjusted analyses. Only the
arguments needed for the intended analysis have to be added or changed.
The returned object can be read through
[`print()`](https://rdrr.io/r/base/print.html), connected to the
generated model with
[`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md),
and accessed directly for further analysis or reporting.
