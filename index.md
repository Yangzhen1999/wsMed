# wsMed

Analyze mediation and moderated mediation in **two-condition
within-subject designs**. Fit a model, read an organized effect table,
and plot the results in R.

**Development documentation · 1.1.0.9000**  
These tutorials use `feature/modular-api`. The published CRAN version
has a different reporting interface.

## Start here

Step 1: Run your first analysis

Use paired data and one call to obtain a mediation model.

[Get started
→](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)

Step 2: Choose your model

Find the guide for your pathways, moderator and missing data.

[Choose an analysis
→](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.md)

Step 3: Read and present results

Extract all core effects, export tables and choose a figure.

[Read the results
→](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md)

## Install the version used here

``` r

# install.packages("pak")
pak::pak("Yangzhen1999/wsMed@feature/modular-api")
```

Restart R after updating. For the published release, use
`install.packages("wsMed")`. These development features require the
branch above.

## A complete first example

Each row is one participant. `A1` / `A2` and `B1` / `B2` are the two
mediator measurements; `D1` / `D2` are the outcome measurements. The
condition contrast is **condition 2 minus condition 1**.

``` r

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

This complete simulated dataset needs no imputation. The example uses
2,000 Monte Carlo draws for speed; assess interval stability with more
draws for a final analysis. The [quick
start](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)
walks through the actual table and its interpretation.

## What would you like to do next?

| Task | Guide |
|----|----|
| Add serial pathways or a moderator | [Choose an analysis](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.md) |
| Get standardized effects or export a table | [Read and export results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md) |
| Choose a forest plot, curve or group comparison | [Plot gallery](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md) |
| Reuse a fit or check an analysis | [Staged workflow](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md) · [Diagnostics](https://yangzhen1999.github.io/wsMed/articles/WorkflowReliability.md) |

See the [function
reference](https://yangzhen1999.github.io/wsMed/reference/index.md) for
arguments and return values, and [all
articles](https://yangzhen1999.github.io/wsMed/articles/index.md) for
equations, imputation and software comparisons.

For the empirical manuscript data, use `data(wsmed_examples)` and read
[`help("wsmed_examples")`](https://yangzhen1999.github.io/wsMed/reference/wsmed_examples.md)
for the source, variable definitions and missingness. [Report an
issue](https://github.com/Yangzhen1999/wsMed/issues) or [contribute to
the
package](https://github.com/Yangzhen1999/wsMed/blob/feature/modular-api/.github/CONTRIBUTING.md).
