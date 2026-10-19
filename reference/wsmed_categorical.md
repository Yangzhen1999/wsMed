# Categorical predictors and supported variable types

wsMed supports binary and multicategory between-subject covariates and
one categorical moderator in models with numeric outcomes and mediators.

## Supported roles

Outcomes, mediators, and within-subject covariates must be numeric
measures analyzed by the continuous-response SEM. Binary or ordinal
response models, thresholds, and categorical links are not implemented.
Storing a binary outcome as numbers does not turn the estimator into a
categorical-response model. Between-subject covariates and the single
moderator may instead be unordered factors. Ordered factors are rejected
by
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md);
explicitly convert them to unordered factors only if a nominal
interpretation is intended.

## Declaring categories

In both the one-call and staged workflows, use
[`base::factor()`](https://rdrr.io/r/base/factor.html) to declare
categorical between-subject covariates and moderators in the input data.
Specify levels explicitly: the first level is the reference group. For a
binary predictor, `factor(x, levels = c(0, 1))` selects 0 as the
reference; reversing the levels selects 1. Use unordered factors for
nominal categories. Every declared factor level must have observations
in the supplied data.

The existing default recognition rules are retained for compatibility.
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md)
treats numeric predictors, including 0/1 columns, as continuous. The
one-call
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md) and
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
interfaces retain automatic detection: factors, character columns, and
numeric columns whose observed values are exactly 0 and 1 are
categorical. Other numeric columns are continuous unless `C_type` or
`W_type` overrides detection. Explicit factors provide the same
categorical interpretation and reference coding in both interfaces
without relying on automatic recognition. The one-call type arguments
remain available to override its default rules.

## Reference coding and comparisons

A factor with K levels is represented by K - 1 treatment indicators. The
first factor level is the reference;
[`stats::relevel()`](https://rdrr.io/r/stats/relevel.html) changes it
before fitting. Indicators are not mean-centered. Coding does not depend
on the global `contrasts` option. Between-subject indicators use `Cb*`
names and moderator indicators use `W*` names. The `C_info` and `W_info`
attributes of prepared data record their mappings. Labels such as
`low vs high` identify the reference and comparison level: the indicator
is 0 at low and 1 at high, so its coefficient is high minus low.

[`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md)
accepts original factor labels in `at`; by default it extracts every
level.
[`wsmed_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_contrasts.md)
compares effects using their joint draws, preserving covariance. Do not
subtract the endpoints of separate confidence intervals to obtain an
interval for a difference. Marginally standardized conditional effects
use the common model-implied outcome-difference SD, not separate
within-category SDs; factor labels and dummy indicators retain their
coding. See
[`standardize_moderation()`](https://yangzhen1999.github.io/wsMed/reference/standardize_moderation.md).
Generated models account for the dependence of endogenous products on
upstream mediator disturbances. Reference changes preserve the implied
marginal scales of the same fitted model. MI pools marginal variance
estimates jointly with coefficients; compare the same completed datasets
when checking recoding. Refit saved models from before this covariance
correction.

## Missing values

The staged default `missing = "error"` rejects missing analysis values.
Listwise deletion and multiple imputation are available for incomplete
categorical predictors. FIML is allowed with fully observed categorical
predictors but
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md)
rejects missing categorical predictors; the one-call interface should
follow the same restriction. MI imputes the raw variables before
constructing dummy variables and interactions. The staged `mi$method`
argument selects the method for numeric variables (default `"pmm"`).
Factors use logistic regression for two levels and multinomial logistic
regression for more than two levels. This differs from the lower-level
[`ImputeData()`](https://yangzhen1999.github.io/wsMed/reference/ImputeData.md)
method argument. MI supports Monte Carlo inference only.

## See also

[`wsmed_model()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_model.md),
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md),
[`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md),
[`wsmed_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_contrasts.md),
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
[`ImputeData()`](https://yangzhen1999.github.io/wsMed/reference/ImputeData.md)

## Examples

``` r
data(example_data)
dat <- example_data
dat$Group <- factor(dat$Group, levels = c("low", "med", "high"))
prepared <- PrepareData(dat, M_C1 = "A1", M_C2 = "A2",
                        Y_C1 = "D1", Y_C2 = "D2",
                        W = "Group", W_type = "categorical")
attr(prepared, "W_info")
#> $raw
#> [1] "Group"
#> 
#> $dummy_names
#> [1] "W1" "W2"
#> 
#> $dummy_map
#> $dummy_map$W1
#> [1] "low vs med"
#> 
#> $dummy_map$W2
#> [1] "low vs high"
#> 
#> 
```
