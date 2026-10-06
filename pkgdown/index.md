# wsMed

Analyze mediation and moderated mediation in **two-condition within-subject designs**.
Fit a model, read an organized effect table, and plot the results in R.

<div class="wsmed-version-note">
<strong>Development documentation · 1.1.0.9000</strong><br>
These tutorials use <code>feature/modular-api</code>. The published CRAN version
has a different reporting interface.
</div>

## Start here

<div class="wsmed-start-grid">
<div class="wsmed-start-card">
<p class="wsmed-card-title">Step 1: Run your first analysis</p>
<p>Use paired data and one call to obtain a mediation model.</p>
<p><a href="articles/GetStarted.html">Get started →</a></p>
</div>
<div class="wsmed-start-card">
<p class="wsmed-card-title">Step 2: Choose your model</p>
<p>Find the guide for your pathways, moderator and missing data.</p>
<p><a href="articles/AnalysisGuide.html">Choose an analysis →</a></p>
</div>
<div class="wsmed-start-card">
<p class="wsmed-card-title">Step 3: Read and present results</p>
<p>Extract all core effects, export tables and choose a figure.</p>
<p><a href="articles/ResultsGuide.html">Read the results →</a></p>
</div>
</div>

## Install the version used here

```r
# install.packages("pak")
pak::pak("Yangzhen1999/wsMed@feature/modular-api")
```

Restart R after updating. For the published release, use
`install.packages("wsMed")`. These development features require the branch above.

## A complete first example

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
final analysis. The [quick start](articles/GetStarted.html) walks through the
actual table and its interpretation.

## What would you like to do next?

| Task | Guide |
|---|---|
| Add serial pathways or a moderator | [Choose an analysis](articles/AnalysisGuide.html) |
| Get standardized effects or export a table | [Read and export results](articles/ResultsGuide.html) |
| Choose a forest plot, curve or group comparison | [Plot gallery](articles/PlottingEffects.html) |
| Reuse a fit or check an analysis | [Staged workflow](articles/ModularWorkflow.html) · [Diagnostics](articles/WorkflowReliability.html) |

See the [function reference](reference/index.html) for arguments and return values,
and [all articles](articles/index.html) for equations, imputation and software comparisons.

For the empirical manuscript data, use `data(wsmed_examples)` and read
`help("wsmed_examples")` for the source, variable definitions and missingness.
[Report an issue](https://github.com/Yangzhen1999/wsMed/issues) or
[contribute to the package](https://github.com/Yangzhen1999/wsMed/blob/feature/modular-api/.github/CONTRIBUTING.md).
