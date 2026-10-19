# Standardized effects

## Request standardized results

Standardization is available **with or without a moderator**. Set
`standardized = TRUE` in the analysis; subsequent summaries and generic
plots inherit that preference.

``` r

data(example_data)
standardized_intro <- wsMed(example_data,
  M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
  Y_C1 = "D1", Y_C2 = "D2", standardized = TRUE,
  R = 2000, seed = 123, verbose = FALSE)
standardized_table <- summary(standardized_intro)$effects
knitr::kable(standardized_table[c("label", "estimate", "conf.low", "conf.high")], digits = 4)
```

| label                 | estimate | conf.low | conf.high |
|:----------------------|---------:|---------:|----------:|
| Direct effect         |  -0.1879 |  -0.3878 |    0.0189 |
| M1                    |   0.0077 |  -0.0258 |    0.0509 |
| M2                    |  -0.0066 |  -0.0437 |    0.0184 |
| Total indirect effect |   0.0011 |  -0.0442 |    0.0515 |
| Total effect          |  -0.1867 |  -0.3799 |    0.0180 |

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

`moderation_std$mod_coeff` reports interaction coefficients per SD of a
continuous moderator. Conditional tables and curves evaluate effects at
fixed numerical moderator values in the **original units**. To recover a
conditional slope from fully standardized coefficients, use
$`b^*(w_c)=b^*+b_w^*(w_c/s_W)`$. The scale of an interaction is the
product of its component scale factors, not the SD of the observed
product column.

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
dat <- data.frame(M11 = avg1 - dm1/2, M12 = avg1 + dm1/2,
                  M21 = avg2 - dm2/2, M22 = avg2 + dm2/2,
                  Y1 = y1, Y2 = y1 + dy, W = w)
```

``` r

result <- wsMed(
  data = dat, M_C1 = c("M11", "M21"), M_C2 = c("M12", "M22"),
  Y_C1 = "Y1", Y_C2 = "Y2", form = "P",
  W = "W", W_type = "continuous", MP = c("b1", "d1"),
  Na = "DE", ci_method = "mc", R = 2000, seed = 2026,
  fixed.x = FALSE, standardized = TRUE, verbose = FALSE
)
head(result$moderation_std$beta_coef)
#>                Path Mediators Level W_value  Estimate         SE 2.5.%CI.Lo
#> 1 indirect_effect_1         1 -1 SD   1.264 0.3650760 0.03271513  0.3045721
#> 2 indirect_effect_1         1  0 SD   3.233 0.8544881 0.04991624  0.7618185
#> 3 indirect_effect_1         1 +1 SD   5.202 1.5488777 0.07684148  1.4009409
#> 4 indirect_effect_2         2 -1 SD   1.264 0.2808029 0.02410413  0.2355370
#> 5 indirect_effect_2         2  0 SD   3.233 0.4512197 0.03567798  0.3825366
#> 6 indirect_effect_2         2 +1 SD   5.202 0.6216366 0.04878867  0.5303888
#>   97.5.%CI.Up Sig
#> 1   0.4343538   *
#> 2   0.9574690   *
#> 3   1.7085247   *
#> 4   0.3281407   *
#> 5   0.5211855   *
#> 6   0.7199859   *
result$moderation_std$conditional_overall
#>           Effect Level W_value  Estimate         SE 2.5.%CI.Lo 97.5.%CI.Up Sig
#> 1 total_indirect -1 SD   1.264 0.6458789 0.04430771  0.5640013   0.7348572   *
#> 3 total_indirect  0 SD   3.233 1.3057078 0.06832314  1.1803575   1.4474992   *
#> 5 total_indirect +1 SD   5.202 2.1705143 0.10122286  1.9781866   2.3756559   *
#> 2   total_effect -1 SD   1.264 0.8339962 0.04039678  0.7570401   0.9185213   *
#> 4   total_effect  0 SD   3.233 1.6449140 0.06497096  1.5272517   1.7768975   *
#> 6   total_effect +1 SD   5.202 2.6608094 0.09780391  2.4802409   2.8631909   *
result$moderation_std$mod_coeff
#>     Path BaseCoef W_dummy     Estimate         SE   2.5%CI.Lo 97.5%CI.Up Sig
#> 1 bw1_W1       b1       W  0.120655183 0.00787400  0.10506398 0.13687092   *
#> 2 dw1_W1       d1       W -0.001564476 0.00755477 -0.01607491 0.01328741    
#> 3 cpw_W1       cp       W  0.150872919 0.02630338  0.09842712 0.20192575   *
#> 4 aw1_W1       a1       W  0.847008347 0.01512466  0.81523810 0.87509978   *
#> 5 aw2_W1       a2       W  0.811031129 0.01845675  0.77454680 0.84540806   *
```

`MP` requests interactions and focal paths. Moderator main effects
already included in the fitted regressions also enter conditional
intercepts, even when `a1` or `cp` is absent from `MP`. The total
indirect effect includes both mediator paths in this example, not just
the path with a requested interaction.

The original `result$moderation` remains available. Without a moderator,
`standardized = TRUE` supplies parameter tables such as
`result$mc$std_mc`, but there is no conditional moderation table.

``` r

plot_moderation_curve(result, "total_indirect", standardized = TRUE)
```

![plot of chunk
plot-continuous](figures/StandardizedModeratedMediation-plot-continuous-1.png)

plot of chunk plot-continuous

The horizontal axis retains raw moderator units. Shading marks stored
grid values whose pointwise confidence interval excludes zero; boundary
labels report raw W values. These are grid approximations, not exact
analytical Johnson–Neyman boundaries or simultaneous confidence regions.

### A check of the point estimates

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

## Categorical moderators

Categorical moderators retain their 0/1 dummy coding. There is no
SD-of-dummy multiplier, and all groups share the same marginal endpoint
scales. The factor levels below make the reference category explicit.

``` r

dat$Group <- cut(dat$W, c(-Inf, 2, 4, Inf), labels = c("A", "B", "C"))
levels(dat$Group)
#> [1] "A" "B" "C"
group_result <- wsMed(
  data = dat, M_C1 = c("M11", "M21"), M_C2 = c("M12", "M22"),
  Y_C1 = "Y1", Y_C2 = "Y2", form = "P",
  W = "Group", W_type = "categorical", MP = c("b1", "d1"),
  Na = "DE", ci_method = "mc", R = 2000, seed = 2026,
  fixed.x = FALSE, standardized = TRUE, verbose = FALSE
)
group_result$moderation_std$conditional_IE
#>           IE Group  Estimate         SE 2.5%CI.Lo 97.5%CI.Up Sig
#> 1 indirect_1     A 0.4184915 0.06133865 0.3035930  0.5445018   *
#> 2 indirect_1     B 0.8751952 0.09283580 0.6969977  1.0633826   *
#> 3 indirect_1     C 2.8136732 0.13467264 2.5569732  3.0829130   *
#> 4 indirect_2     A 0.4018768 0.03637889 0.3343063  0.4770116   *
#> 5 indirect_2     B 0.6406972 0.04595490 0.5549033  0.7363760   *
#> 6 indirect_2     C 0.9578364 0.06327426 0.8379816  1.0898480   *
group_result$moderation_std$IE_contrasts
#>           IE Contrast  Estimate         SE 2.5%CI.Lo 97.5%CI.Up Sig
#> 1 indirect_1    B - A 0.4567037 0.10655952 0.2575287  0.6705150   *
#> 2 indirect_1    C - A 2.3951818 0.13609898 2.1349499  2.6735862   *
#> 3 indirect_1    C - B 1.9384780 0.14590645 1.6426100  2.2252149   *
#> 4 indirect_2    B - A 0.2388204 0.03262885 0.1776572  0.3028650   *
#> 5 indirect_2    C - A 0.5559597 0.04390288 0.4741881  0.6472965   *
#> 6 indirect_2    C - B 0.3171392 0.03357895 0.2557334  0.3852625   *
group_result$moderation_std$conditional_overall
#>           Effect Group  Estimate         SE 2.5%CI.Lo 97.5%CI.Up Sig
#> 1 total_indirect     A 0.8203683 0.07570328 0.6771897  0.9756619   *
#> 3 total_indirect     B 1.5158924 0.10953121 1.3061032  1.7389931   *
#> 5 total_indirect     C 3.7715097 0.15957553 3.4599441  4.0930114   *
#> 2   total_effect     A 0.8008090 0.05550103 0.6963898  0.9182957   *
#> 4   total_effect     B 1.6155540 0.07417847 1.4806658  1.7727188   *
#> 6   total_effect     C 2.9812606 0.10178839 2.7930067  3.2047015   *
```

Use these group tables for categorical moderators. The
continuous-moderator curve example above should not be interpreted as
interpolating between groups.

## Convert a fitted result without refitting

[`standardize_moderation()`](https://yangzhen1999.github.io/wsMed/reference/standardize_moderation.md)
uses the joint MC or bootstrap draws stored in a `wsMed` object with a
moderator. It returns the standardized moderation list:

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
#> [1] 2000
#> 
#> $diagnostics$valid
#> [1] 2000
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

## Confidence intervals, bootstrap and both engines

Each valid joint draw supplies both regression coefficients and
model-implied SDs. Transform the effect using those draw-specific SDs,
then summarize the transformed draws. For continuous moderators, the
selected raw values (for example the reference mean and mean plus/minus
one reference SD) remain fixed across draws. If standardized
coefficients are used, evaluate them at $`w_c/s_W^{(r)}`$ in draw $`r`$,
not at one fixed standardized moderator value.

Point estimates evaluate the effect at the fitted parameters, or at
pooled primitive parameters for MI. For MI models containing endogenous
products, the marginal variance estimators are pooled separately and
jointly with those coefficients before taking square roots. They are not
averages of nonlinear draw effects. Invalid joint draws are excluded
with diagnostics; inspect the `standardization` attribute for their
counts, indices and reasons.

All **conditional** tables use percentile intervals, for both MC and
bootstrap. `boot_ci_type` controls parameter-table intervals; it does
not change conditional intervals. In standardized parameter tables,
`"bc"` and `"bca.simple"` use bias correction with zero acceleration,
not a full acceleration-adjusted BCa calculation. Standardized bootstrap
p-values require at least 1000 valid replicates; that is not a minimum
for conditional intervals.

The following longer bootstrap example is not run during vignette
rebuilding:

``` r

both_result <- wsMed(
  data = dat, M_C1 = c("M11", "M21"), M_C2 = c("M12", "M22"),
  Y_C1 = "Y1", Y_C2 = "Y2", form = "P",
  W = "W", W_type = "continuous", MP = c("b1", "d1"),
  Na = "DE", ci_method = "both", R = 5000, bootstrap = 2000,
  seed = 2026, iseed = 2026, boot_ci_type = "perc",
  standardized = TRUE
)
both_result$moderation_std$mc$conditional_overall
both_result$moderation_std$boot$conditional_overall
plot_moderation_curve(both_result, "total_indirect",
                      standardized = TRUE, engine = "boot")
```

For a single engine (`"mc"` or `"bootstrap"`), tables are directly
inside `moderation_std`. For `"both"`, they are nested under `$mc` and
`$boot`; the plotting `engine` argument selects between them.

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

For MI moderated models, wsMed averages each marginal variance estimate
over completed datasets. It pools its covariance with the primitive
coefficients using delta-method within-imputation covariances and
Rubin’s rules. MC samples the variances jointly with the coefficients,
so the denominator is not treated as fixed. Pooling the variance itself
avoids the coding dependence of evaluating a nonlinear marginal variance
only after pooling covariance-model parameters. The original coefficient
pooling and imputation procedure are retained. Refit earlier saved
moderated models before using this correction.

Report the condition difference direction, model and moderated paths,
moderator coding/reference and raw probe values, marginal SD definition,
missing-data method, `fixed.x`, inference engine, number of valid draws
and interval type. Distinguish standardized interaction coefficients per
SD of W from conditional indirect effects at particular raw W values.

For serial and sparse models, see the [custom-model
tutorial](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCustom.md).
Their complete indirect effects follow the same endpoint scaling rule.

## More plots for reporting

Use
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
