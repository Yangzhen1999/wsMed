# wsMed

Mediation and moderated mediation for two-condition within-subject designs.

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

## First analysis

Each row is one participant. The paired mediator columns are `A1` / `A2` and
`B1` / `B2`; the paired outcome columns are `D1` / `D2`. The contrast is
**condition 2 minus condition 1**.

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

This uses the defaults: parallel mediation, listwise deletion, Monte Carlo
inference with 20,000 draws, 95% CIs and unstandardized output. The dataset is
complete. The [Get started guide](https://yangzhen1999.github.io/wsMed/articles/GetStarted.html)
explains the report and adds a moderator in a second example.

## Learn more

- [Choose an analysis](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.html)
- [Read and export results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.html)
- [Plot gallery](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.html)
- [Analysis in separate steps](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.html)

Use unordered factors for categorical between-subject covariates and moderators,
with the first level as the reference. The
[categorical predictor guide](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.html)
explains coding and missing-data restrictions.

The empirical manuscript data are included as `wsmed_examples`.
For source editing and tutorial rebuilding, see the [maintainer guide](.github/CONTRIBUTING.md).
