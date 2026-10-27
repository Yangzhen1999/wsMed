# Standardized effects

## Request standardized results

Standardization is available **with or without a moderator**. Set
`standardized = TRUE` in the analysis; subsequent summaries and generic
plots inherit that preference.

``` r

data(example_data)
standardized_intro <- wsMed(
  example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  standardized = TRUE
)
print(standardized_intro)
#> wsMed analysis
#> Model: P | DE | Observations: 100 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Standardization: effect / marginal model-implied SD(D2 - D1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 0.169239 
#> The denominator is not a moderator-specific conditional SD.
#>                                       Estimate Std. Error CI lower CI upper
#> cp: Direct effect                     -0.18787    0.10030 -0.38339  0.01074
#> indirect_1: M1                         0.00775    0.01858 -0.02663  0.05041
#> indirect_2: M2                        -0.00662    0.01496 -0.04328  0.01832
#> total_indirect: Total indirect effect  0.00113    0.02396 -0.04869  0.05065
#> total: Total effect                   -0.18674    0.10059 -0.38126  0.01122
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

These complete condition effects are expressed relative to the marginal
SD of the outcome difference. For a one-off unstandardized query, use
`summary(standardized_intro, standardized = FALSE)`. See the [results
guide](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md)
for table export.

**Choose what to read next:** [definitions](#what-is-standardized),
[continuous
moderators](#continuous-moderators-two-different-quantities),
[categorical moderators](#categorical-moderators), or [missing
data](#missing-data-and-reporting).

## What is standardized?

For a two-condition design, define $`D M=M_2-M_1`$ and $`D Y=Y_2-Y_1`$.
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
centers the mediator average component, but does not center these
differences. Standardization divides a difference by its marginal
model-implied SD, preserving its mean condition effect.

Write $`s_M=SD(D M)`$ and $`s_Y=SD(D Y)`$. Without moderation,

``` math
a^*=a/s_M,\qquad b^*=b s_M/s_Y,\qquad c'^*=c'/s_Y,
\qquad IE^*=ab/s_Y.
```

The condition contrast retains its original unit. In a serial chain, the
intermediate mediator SDs cancel. Thus every complete indirect effect,
its contrast with another complete indirect effect, the total indirect
effect and the total condition effect use the outcome-difference SD.

These are **marginal** SDs implied by the fitted model, not residual
SDs, group-specific SDs or SDs conditional on a selected moderator
value. The same endpoint scales apply at every moderator value within a
fit.

## Continuous moderators: two different quantities

For a centered moderator $`w_c=w-\bar w`$, suppose the conditional paths
are $`a(w_c)=a+a_w w_c`$ and $`b(w_c)=b+b_w w_c`$. Then

``` math
IE^*(w_c)=\frac{(a+a_w w_c)(b+b_w w_c)}{s_Y},
\qquad b^*(w_c)=(b+b_w w_c)\frac{s_M}{s_Y}.
```

The standardized interaction coefficient is instead

``` math
b_w^*=b_w\frac{s_M s_W}{s_Y},\qquad
a_w^*=a_w\frac{s_W}{s_M}.
```

Standardized interaction coefficients are expressed per SD of a
continuous moderator. In contrast, `summary(result)` reports conditional
effects and paths at selected raw moderator values. Conditional tables
and curves evaluate effects at fixed numerical moderator values in the
**original units**. To recover a conditional slope from fully
standardized coefficients, use $`b^*(w_c)=b^*+b_w^*(w_c/s_W)`$. The
scale of an interaction is the product of its component scale factors,
not the SD of the observed product column.

## Fit a reproducible example

The following simulated data have a moderator with a nonzero mean and an
SD different from one. The mediator averages and differences are
generated separately to make the two-condition structure explicit.

``` r

set.seed(918)
n <- 350
w <- rnorm(n, 3, 2)
avg1 <- rnorm(n)
avg2 <- rnorm(n)
dm1 <- 2 + 0.8 * w + rnorm(n)
dm2 <- 1 + 0.4 * w + 0.3 * dm1 + rnorm(n)
dy <- 0.5 + 0.6 * w + 0.5 * dm1 + 0.7 * dm2 +
      0.2 * dm1 * w + 0.3 * avg1 + rnorm(n)
y1 <- rnorm(n)
dat <- data.frame(
  M11 = avg1 - dm1/2,
  M12 = avg1 + dm1/2,
  M21 = avg2 - dm2/2,
  M22 = avg2 + dm2/2,
  Y1 = y1,
  Y2 = y1 + dy,
  W = w
)
```

``` r

result <- wsMed(
  data = dat,
  M_C1 = c("M11", "M21"),
  M_C2 = c("M12", "M22"),
  Y_C1 = "Y1",
  Y_C2 = "Y2",
  W = "W",
  MP = c("b1", "d1"),
  standardized = TRUE
)
print(result)
#> wsMed analysis
#> Model: P | DE | Observations: 350 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: W in raw units; centering reference = 3.23288 
#> Standardization: effect / marginal model-implied SD(Y2 - Y1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 6.28886 
#> The denominator is not a moderator-specific conditional SD.
#>                                                    Estimate Std. Error CI lower
#> cp@1: Direct effect [W = 3.23]                       0.3392     0.0536   0.2374
#> indirect_1@1: M1 [W = 3.23]                          0.8545     0.0509   0.7572
#> indirect_2@1: M2 [W = 3.23]                          0.4512     0.0360   0.3835
#> total_indirect@1: Total indirect effect [W = 3.23]   1.3057     0.0699   1.1755
#> total@1: Total effect [W = 3.23]                     1.6449     0.0645   1.5282
#>                                                    CI upper
#> cp@1: Direct effect [W = 3.23]                       0.4478
#> indirect_1@1: M1 [W = 3.23]                          0.9591
#> indirect_2@1: M2 [W = 3.23]                          0.5248
#> total_indirect@1: Total indirect effect [W = 3.23]   1.4490
#> total@1: Total effect [W = 3.23]                     1.7797
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
summary(result)
#> wsMed statistical summary
#> Model: P | Missing: DE | Observations: 350 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: W in raw units; centering reference = 3.23288 
#> Standardization: effect / marginal model-implied SD(Y2 - Y1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 6.28886 
#> The denominator is not a moderator-specific conditional SD.
#>                                                    Estimate Std. Error CI lower
#> cp@1: Direct effect [W = 3.23]                       0.3392     0.0536   0.2374
#> indirect_1@1: M1 [W = 3.23]                          0.8545     0.0509   0.7572
#> indirect_2@1: M2 [W = 3.23]                          0.4512     0.0360   0.3835
#> total_indirect@1: Total indirect effect [W = 3.23]   1.3057     0.0699   1.1755
#> total@1: Total effect [W = 3.23]                     1.6449     0.0645   1.5282
#>                                                    CI upper
#> cp@1: Direct effect [W = 3.23]                       0.4478
#> indirect_1@1: M1 [W = 3.23]                          0.9591
#> indirect_2@1: M2 [W = 3.23]                          0.5248
#> total_indirect@1: Total indirect effect [W = 3.23]   1.4490
#> total@1: Total effect [W = 3.23]                     1.7797
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>                      Estimate Std. Error  CI lower  CI upper
#> cp@1: cp [W = 3.23]  0.339206   0.053638  0.237400  0.447840
#> b1@1: b1 [W = 3.23]  0.352858   0.017629  0.318267  0.387334
#> d1@1: d1 [W = 3.23]  0.037421   0.008823  0.020411  0.055015
#> b2@1: b2 [W = 3.23]  0.209823   0.015646  0.179364  0.240774
#> d2@1: d2 [W = 3.23] -0.000698   0.008604 -0.017738  0.016190
#> a1@1: a1 [W = 3.23]  2.421621   0.096351  2.244718  2.621101
#> a2@1: a2 [W = 3.23]  2.150476   0.088257  1.989051  2.332774
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

`MP` requests interactions and focal paths. Moderator main effects
already included in the fitted regressions also enter conditional
intercepts, even when `a1` or `cp` is absent from `MP`. The total
indirect effect includes both mediator paths in this example, not just
the path with a requested interaction.

The default report and summary inherit `standardized = TRUE`. Use
`summary(result, standardized = FALSE)` to request unstandardized
results without fitting again. Use `wsmed_effects(result)` when you need
a separate effect table for further comparisons or export.

``` r

plot(result)
```

![plot of chunk
plot-continuous](figures/StandardizedModeratedMediation-plot-continuous-1.png)

plot of chunk plot-continuous

The horizontal axis retains raw moderator units. The default curves show
specific indirect effects with pointwise CIs over the observed range.
They are not simultaneous confidence bands or exact Johnson–Neyman
regions.

## Categorical moderators

Categorical moderators retain their 0/1 dummy coding. There is no
SD-of-dummy multiplier, and all groups share the same marginal endpoint
scales. The factor levels below make the reference category explicit.

``` r

dat$Group <- cut(dat$W, c(-Inf, 2, 4, Inf), labels = c("A", "B", "C"))
levels(dat$Group)
#> [1] "A" "B" "C"
group_result <- wsMed(
  data = dat,
  M_C1 = c("M11", "M21"),
  M_C2 = c("M12", "M22"),
  Y_C1 = "Y1",
  Y_C2 = "Y2",
  W = "Group",
  MP = c("b1", "d1"),
  standardized = TRUE
)
print(group_result)
#> wsMed analysis
#> Model: P | DE | Observations: 350 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: Group ; reference category = A 
#> Standardization: effect / marginal model-implied SD(Y2 - Y1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 6.05489 
#> The denominator is not a moderator-specific conditional SD.
#>                                                     Estimate Std. Error
#> cp@1: Direct effect [Group = A]                      -0.0196     0.0649
#> indirect_1@1: M1 [Group = A]                          0.4185     0.0611
#> indirect_2@1: M2 [Group = A]                          0.4019     0.0365
#> total_indirect@1: Total indirect effect [Group = A]   0.8204     0.0757
#> total@1: Total effect [Group = A]                     0.8008     0.0559
#> cp@2: Direct effect [Group = B]                       0.0997     0.0939
#> indirect_1@2: M1 [Group = B]                          0.8752     0.0907
#> indirect_2@2: M2 [Group = B]                          0.6407     0.0468
#> total_indirect@2: Total indirect effect [Group = B]   1.5159     0.1086
#> total@2: Total effect [Group = B]                     1.6156     0.0738
#> cp@3: Direct effect [Group = C]                      -0.7902     0.1211
#> indirect_1@3: M1 [Group = C]                          2.8137     0.1362
#> indirect_2@3: M2 [Group = C]                          0.9578     0.0640
#> total_indirect@3: Total indirect effect [Group = C]   3.7715     0.1624
#> total@3: Total effect [Group = C]                     2.9813     0.1021
#>                                                     CI lower CI upper
#> cp@1: Direct effect [Group = A]                      -0.1474   0.1089
#> indirect_1@1: M1 [Group = A]                          0.3017   0.5427
#> indirect_2@1: M2 [Group = A]                          0.3347   0.4761
#> total_indirect@1: Total indirect effect [Group = A]   0.6785   0.9750
#> total@1: Total effect [Group = A]                     0.6962   0.9152
#> cp@2: Direct effect [Group = B]                      -0.0811   0.2855
#> indirect_1@2: M1 [Group = B]                          0.7013   1.0575
#> indirect_2@2: M2 [Group = B]                          0.5521   0.7344
#> total_indirect@2: Total indirect effect [Group = B]   1.3123   1.7371
#> total@2: Total effect [Group = B]                     1.4780   1.7673
#> cp@3: Direct effect [Group = C]                      -1.0273  -0.5554
#> indirect_1@3: M1 [Group = C]                          2.5529   3.0883
#> indirect_2@3: M2 [Group = C]                          0.8362   1.0866
#> total_indirect@3: Total indirect effect [Group = C]   3.4616   4.1004
#> total@3: Total effect [Group = C]                     2.7877   3.1927
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Fitted group n: A = 100; B = 139; C = 111.
#> Fitted group counts after missing-data handling; observed counts exclude
#> missing moderator values. 
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
plot(group_result)
```

![plot of chunk
categorical](figures/StandardizedModeratedMediation-categorical-1.png)

plot of chunk categorical

The default report includes each observed category. The
continuous-moderator curve example above should not be interpreted as
interpolating between groups.

## Confidence intervals, bootstrap and both engines

Each valid joint draw supplies both regression coefficients and
model-implied SDs. Transform the effect using those draw-specific SDs,
then summarize the transformed draws. For continuous moderators, the
selected raw values (for example the reference mean and mean plus/minus
one reference SD) remain fixed across draws. If standardized
coefficients are used, evaluate them at $`w_c/s_W^{(r)}`$ in draw $`r`$,
not at one fixed standardized moderator value.

Point estimates evaluate the effect at the fitted parameters, or at
pooled primitive parameters for MI. For MI models with products of
mediator differences and the moderator, the marginal variance estimators
are pooled jointly with those coefficients before taking square roots.
Point estimates are not averages of nonlinear draw effects. Invalid
joint draws are excluded together; use
`wsmed_effects(result)$diagnostics` to inspect the query diagnostics.

The current effect reports from
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md),
and [`confint()`](https://rdrr.io/r/stats/confint.html) applied to
extracted effects, use percentile intervals for both MC and bootstrap,
**with or without moderation**. They use R’s type-7 quantiles.
`boot_ci_type` affects stored legacy parameter tables; it does not
change these effect intervals. See the expandable implementation notes
below for the legacy conventions.

The following longer bootstrap example is not run during vignette
rebuilding:

``` r

both_result <- wsMed(
  data = dat,
  M_C1 = c("M11", "M21"),
  M_C2 = c("M12", "M22"),
  Y_C1 = "Y1",
  Y_C2 = "Y2",
  W = "W",
  MP = c("b1", "d1"),
  ci_method = "both",
  standardized = TRUE
)
print(both_result)
summary(
  both_result,
  method = "mc"
)
summary(
  both_result,
  method = "bootstrap"
)
plot(
  both_result,
  method = "bootstrap"
)
```

When both engines are stored,
[`print()`](https://rdrr.io/r/base/print.html) reports both. Use
`method` in [`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) to select one
engine.

## Missing data and reporting

FIML and MI use the same effect definition. With `fixed.x = FALSE`,
estimated external moments participate in the joint transformation. With
`fixed.x = TRUE`, transformations condition on fitted external moments.
Products containing an endogenous mediator are modeled with auxiliary
moment equations and covariances with their upstream mediator
disturbances. This preserves the predictor moment structure when a
reference group changes. `fixed.x` applies to the remaining genuine
exogenous predictors; endogenous product moments are always estimated.

MI supports MC inference and evaluates effects at pooled primitive
parameters; its probing and centering reference is the first completed
dataset. With MI and `fixed.x = TRUE`, external moments from that
reference are held fixed. This does not introduce population-relative
moderator probing or a new imputation procedure.

For MI models with interactions involving mediator differences, wsMed
averages each marginal variance estimate over completed datasets. It
pools its covariance with the primitive coefficients using delta-method
within-imputation covariances and Rubin’s rules. MC samples the
variances jointly with the coefficients, so the denominator is not
treated as fixed. Pooling the variance itself avoids the coding
dependence of evaluating a nonlinear marginal variance only after
pooling covariance-model parameters. This additional variance-pooling
step is specific to those endogenous products; it is not applied to
every MI model. Other models obtain marginal scales from the jointly
drawn model parameters. The original coefficient pooling and imputation
procedure are retained.

Report the condition difference direction, model and moderated paths,
moderator coding/reference and raw probe values, marginal SD definition,
missing-data method, `fixed.x`, inference engine, number of valid draws
and interval type. Distinguish standardized interaction coefficients per
SD of W from conditional indirect effects at particular raw W values.

For serial and sparse models, see the [custom-model
tutorial](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCustom.md).
Their complete indirect effects follow the same endpoint scaling rule.

## More plots for reporting

Start with `plot(result)` for the default display. Optional named
helpers include
[`plot_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_effects.md)
for an effect forest,
[`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md)
for group or reference-level point intervals, and
[`plot_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/plot_contrasts.md)
for effect differences with their own confidence intervals. All three
support `standardized` and the MC/bootstrap `engine` selection. See
[Plotting mediation effects and
contrasts](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md)
for executed examples, selection of paths and labels, and export to PDF
or PNG.

## Imputation compatibility

Correct standardization does not repair an imputation model that omits
substantive interactions. Default raw-variable MI uses main effects. To
use model-compatible external imputations, pass a list of completed wide
datasets (or a `mice` mids object) through
`wsmed_fit(..., missing = "mi", mi = list(completed = completed))` or
`wsMed(..., Na = "MI", mi_args = list(completed = completed))`. The
difference scores and products are regenerated in each completion;
observed cells and factor levels are checked. See [the worked
example](https://yangzhen1999.github.io/wsMed/articles/CompatibleImputation.md)
for assumptions, an explicit SMC-FCS predictor matrix and convergence
guidance.

## Optional implementation checks

Expand numerical checks and legacy moderation-table details

These checks inspect stored internals. They are not required to request
standardized results through
[`summary()`](https://rdrr.io/r/base/summary.html),
[`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md)
or [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

### Check the stored point estimates

For this complete-data MC fit, the standardized overall effects must
equal the raw effects divided by the fitted marginal outcome SD:

``` r

sy <- sqrt(lavaan::fitted(result$mc$fit)$cov["Ydiff", "Ydiff"])
stopifnot(isTRUE(all.equal(
  result$moderation_std$conditional_overall$Estimate,
  result$moderation$conditional_overall$Estimate / sy,
  tolerance = 1e-7
)))
stopifnot(identical(result$moderation_std$theta_curve$W_raw,
                    result$moderation$theta_curve$W_raw))
```

This identity concerns point estimates. It does **not** justify dividing
raw confidence limits by the fitted SD.

### Legacy moderation tables

`summary(result, standardized = TRUE)` is sufficient for ordinary
reporting. The older
[`standardize_moderation()`](https://yangzhen1999.github.io/wsMed/reference/standardize_moderation.md)
helper uses the joint MC or bootstrap draws stored in a `wsMed` object
with a moderator. It returns the standardized moderation list:

``` r

converted <- standardize_moderation(result)
stopifnot(isTRUE(all.equal(converted, result$moderation_std)))
result$moderation_std <- converted
attr(converted, "standardization")
#> $effect_scale
#> [1] "marginal model-implied endpoint scales; IE / SD(Ydiff)"
#> 
#> $moderator_units
#> [1] "raw; fixed numerical probes; dummy coding unchanged"
#> 
#> $mod_coeff_units
#> [1] "per SD of continuous W; per 0/1 dummy contrast"
#> 
#> $interval
#> [1] "percentile"
#> 
#> $engine
#> [1] "mc"
#> 
#> $fixed.x
#> [1] FALSE
#> 
#> $MI_reference
#> NULL
#> 
#> $diagnostics
#> $diagnostics$requested
#> [1] 20000
#> 
#> $diagnostics$valid
#> [1] 20000
#> 
#> $diagnostics$invalid
#> [1] 0
#> 
#> $diagnostics$invalid_indices
#> integer(0)
#> 
#> $diagnostics$reasons
#> < table of extent 0 >
```

A result without the required stored draws cannot be converted by this
helper.

In standardized legacy parameter tables, `"bc"` and `"bca.simple"` apply
bias correction with zero acceleration; this is not a full BCa
calculation. Their bootstrap p-values require at least 1,000 valid
replicates. That threshold does not define the availability of
percentile effect CIs in the current interface.
