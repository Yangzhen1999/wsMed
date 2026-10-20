# wsMed

Analyze mediation and moderated mediation in **two-condition within-subject designs**.
Specify the paired measurements, read the results, and plot the effects in R.

Documentation for **wsMed 1.2.0**.

## Start here

<div class="wsmed-start-grid">
<div class="wsmed-start-card">
<p class="wsmed-card-title">Run your first analysis</p>
<p>Start with parallel mediation, then add a moderator.</p>
<p><a href="articles/GetStarted.html">Get started →</a></p>
</div>
<div class="wsmed-start-card">
<p class="wsmed-card-title">Choose your model</p>
<p>Find the options for pathways, covariates and missing data.</p>
<p><a href="articles/AnalysisGuide.html">Choose an analysis →</a></p>
</div>
<div class="wsmed-start-card">
<p class="wsmed-card-title">Read and present results</p>
<p>Use the default reports and plots, then customize when needed.</p>
<p><a href="articles/ResultsGuide.html">Read the results →</a></p>
</div>
</div>

## Install

These tutorials describe **wsMed 1.2.0**. Install the released package from CRAN:

```r
install.packages("wsMed")
```

Or install the version on the GitHub `master` branch:

```r
# install.packages("pak")
pak::pak("Yangzhen1999/wsMed@master")
```

Restart R after updating. `packageVersion("wsMed")` shows the installed version.

## A first analysis

Each row is one participant. `A1` / `A2` and `B1` / `B2` are the two mediator
measurements; `D1` / `D2` are the outcome measurements. The condition contrast
is **condition 2 minus condition 1**.

```r
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
95% CIs and unstandardized output. The simulated data are complete.
[Get started](articles/GetStarted.html) explains the output and then adds a
continuous moderator in a second example.

## What would you like to do next?

| Task | Guide |
|---|---|
| Add serial pathways or a moderator | [Choose an analysis](articles/AnalysisGuide.html) |
| Add covariates or handle missing data | [Analysis options](articles/WsMed.html) |
| Standardize, select or export results | [Read and export results](articles/ResultsGuide.html) |
| Customize a forest plot, curve or group comparison | [Plot gallery](articles/PlottingEffects.html) |
| Reuse a fit or inspect an analysis | [Staged workflow](articles/ModularWorkflow.html) · [Diagnostics](articles/WorkflowReliability.html) |

See the [function reference](reference/index.html) for arguments and return values,
and [all articles](articles/index.html) for model equations and further methods.
The empirical manuscript data are included as `wsmed_examples`; their help page
describes the source, variables and missingness.

[Report an issue](https://github.com/Yangzhen1999/wsMed/issues) or
[contribute to the package](https://github.com/Yangzhen1999/wsMed/blob/master/.github/CONTRIBUTING.md).
