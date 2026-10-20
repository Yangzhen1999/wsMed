# wsMed

Analyze mediation and moderated mediation in **two-condition
within-subject designs**. Specify the paired measurements, read the
results, and plot the effects in R.

Documentation for **wsMed 1.2.0**.

## Start here

Run your first analysis

Start with parallel mediation, then add a moderator.

[Get started
→](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)

Choose your model

Find the options for pathways, covariates and missing data.

[Choose an analysis
→](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.md)

Read and present results

Use the default reports and plots, then customize when needed.

[Read the results
→](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md)

## Install

These tutorials describe **wsMed 1.2.0**. Install the released package
from CRAN:

``` r

install.packages("wsMed")
```

Or install the version on the GitHub `master` branch:

``` r

# install.packages("pak")
pak::pak("Yangzhen1999/wsMed@master")
```

Restart R after updating. `packageVersion("wsMed")` shows the installed
version.

## A first analysis

Each row is one participant. `A1` / `A2` and `B1` / `B2` are the two
mediator measurements; `D1` / `D2` are the outcome measurements. The
condition contrast is **condition 2 minus condition 1**.

``` r

library(wsMed)
data(example_data)

result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "D1",
  Y_C2 = "D2"
)

print(result)
summary(result)
plot(result)
```

The defaults give a parallel mediation model, 20,000 Monte Carlo draws,
95% CIs and unstandardized output. The simulated data are complete. [Get
started](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)
explains the output and then adds a continuous moderator in a second
example.

## What would you like to do next?

| Task | Guide |
|----|----|
| Add serial pathways or a moderator | [Choose an analysis](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.md) |
| Add covariates or handle missing data | [Analysis options](https://yangzhen1999.github.io/wsMed/articles/WsMed.md) |
| Standardize, select or export results | [Read and export results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md) |
| Customize a forest plot, curve or group comparison | [Plot gallery](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md) |
| Reuse a fit or inspect an analysis | [Staged workflow](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md) · [Diagnostics](https://yangzhen1999.github.io/wsMed/articles/WorkflowReliability.md) |

See the [function
reference](https://yangzhen1999.github.io/wsMed/reference/index.md) for
arguments and return values, and [all
articles](https://yangzhen1999.github.io/wsMed/articles/index.md) for
model equations and further methods. The empirical manuscript data are
included as `wsmed_examples`; their help page describes the source,
variables and missingness.

[Report an issue](https://github.com/Yangzhen1999/wsMed/issues) or
[contribute to the
package](https://github.com/Yangzhen1999/wsMed/blob/master/.github/CONTRIBUTING.md).
