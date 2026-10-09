# wsMed

Mediation and moderated mediation for two-condition within-subject designs.

## Install

The tutorials in this branch target **version 1.2.0**.

```r
# install.packages("pak")
pak::pak("Yangzhen1999/wsMed@feature/modular-api")
```

Restart R after updating. Use `install.packages("wsMed")` for the published
CRAN release; its reporting interface differs from this development branch.

## First analysis


Each row is one participant. `A1` / `A2` and `B1` / `B2` are the two mediator
measurements; `D1` / `D2` are the outcome measurements. The condition contrast
is **condition 2 minus condition 1**.

```r
library(wsMed)
data(example_data)
result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
  Y_C1 = "D1", Y_C2 = "D2",
  form = "P", Na = "DE", ci_method = "mc",
  R = 2000, seed = 123, verbose = FALSE
)
s <- summary(result)
s$effects
plot(s)
```

This complete simulated dataset needs no imputation. The example uses 2,000
Monte Carlo draws for speed; assess interval stability with more draws for a
final analysis. The [quick start](vignettes/GetStarted.Rmd.original) walks through the
actual table and its interpretation.

## Categorical predictors

Use unordered factors for categorical between-subject covariates and moderators
in both `wsMed()` and the staged workflow. Set levels explicitly; the first level
is the reference group. For example:

```r
example_data$Group <- factor(example_data$Group,
                             levels = c("low", "med", "high"))
```

For a binary predictor, use `factor(x, levels = c(0, 1))` to select 0 as the
reference. Existing numeric 0/1 recognition defaults are retained for
compatibility; the [categorical predictor guide](vignettes/CategoricalPredictors.Rmd.original)
explains those defaults and missing-data restrictions.

## Find a guide

- [Get started](vignettes/GetStarted.Rmd.original): a complete analysis using paired example data.
- [Choose an analysis](vignettes/AnalysisGuide.Rmd.original): models, moderators and missing data.
- [Read and export results](vignettes/ResultsGuide.Rmd.original): core effect tables and reporting.
- [Plot gallery](vignettes/PlottingEffects.Rmd.original): forests, curves, categories and differences.
- [Standardized effects](vignettes/StandardizedModeratedMediation.Rmd.original): with or without moderation.

These links point to the executable tutorial sources in this branch. The
[published website](https://yangzhen1999.github.io/wsMed/) may still describe the
CRAN version until the development website is released.

For the empirical manuscript data, use `data(wsmed_examples)` and read
`help("wsmed_examples")`. For code contributions and tutorial rebuilding,
see [the maintainer guide](.github/CONTRIBUTING.md).
