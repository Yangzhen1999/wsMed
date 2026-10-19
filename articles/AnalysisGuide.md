# Choose an analysis

Start with your research question, then follow the relevant guide. For a
first analysis, complete [Get
started](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md);
it uses
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
throughout. All models here require two within-subject conditions with
paired measurements.

## Prepare your data

Use one row per participant, separate columns for the two conditions,
and the same mediator order in both conditions. Decide which condition
is subtracted from which before fitting: wsMed uses **condition 2 minus
condition 1**.

- **Column layout:** [a small worked
  example](https://yangzhen1999.github.io/wsMed/articles/GetStarted.html#match-your-columns-to-the-two-conditions).
- **Within- and between-subject covariates:** [analysis
  options](https://yangzhen1999.github.io/wsMed/articles/WsMed.html#covariates).
- **Category coding and reference groups:** [categorical
  predictors](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.md).

## Choose your model

| Research structure | `form` | Meaning / next step |
|----|----|----|
| Parallel pathways | `"P"` | Each mediator forms a separate pathway; start with the [quick start](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md). |
| Serial pathways | `"CN"` | Mediators are connected in order; see [model selection](https://yangzhen1999.github.io/wsMed/articles/WsMed.html#predefined-models). |
| Serial-parallel structure | `"CP"` | A serial component feeds parallel pathways; inspect the diagram in [the model description](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCP.md). |
| Parallel-serial structure | `"PC"` | Parallel pathways feed a later mediator; inspect the diagram in [the model description](https://yangzhen1999.github.io/wsMed/articles/GenerateModelPC.md). |
| User-defined pathways | `"UD"` | Specify the directed mediator connections; see [custom models](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCustom.md). |

Choose the structure using your research design and substantive
assumptions. Check mediator ordering against the diagram and generated
equations; the two mixed structures are not interchangeable. Their
[equation
articles](https://yangzhen1999.github.io/wsMed/articles/index.md)
provide definitions rather than additional required steps for an
ordinary fit.

## Add moderation

| Moderator | Guide | What to report |
|----|----|----|
| Continuous | [Specify moderated paths](https://yangzhen1999.github.io/wsMed/articles/WsMed.html#moderators) | Conditional effects at meaningful raw values, with a [curve or selected-level plot](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md). |
| Categorical | [Fit and compare groups](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.html#fit-categorical-moderated-mediation) | Reference coding, group-specific effects and intervals for group differences. |

Declare categorical between-subject covariates and moderators as
unordered factors before using either interface. Set factor levels
explicitly; the first level is the reference group. The [categorical
predictor
guide](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.md)
shows binary and multicategory coding. Specify which paths are moderated
rather than assuming that every path includes an interaction.

## Handle missing data

| Situation | Where to start |
|----|----|
| Complete data or deliberate complete-case analysis | `Na = "DE"`; inspect the number of retained participants. |
| Full-information maximum likelihood | `Na = "FIML"`; see [options and restrictions](https://yangzhen1999.github.io/wsMed/articles/WsMed.html#missing-data-and-confidence-intervals). |
| Multiple imputation | `Na = "MI"`; see [imputation options](https://yangzhen1999.github.io/wsMed/articles/WsMed.html#missing-data-and-confidence-intervals). |
| Multiple imputation with moderation interactions | [Model-compatible imputation](https://yangzhen1999.github.io/wsMed/articles/CompatibleImputation.md), including external completed datasets. |

The choice depends on the missing-data assumptions and variable types.
Default main-effects imputation may not preserve moderation
interactions. Do not treat successful fitting or reproducible output as
proof that an imputation model is suitable. Missing categorical
predictors have additional
[restrictions](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.html#missing-categorical-predictors).

## Read, compare and present results

- [Read and export
  results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md):
  all core effects in one table.
- [Standardized
  effects](https://yangzhen1999.github.io/wsMed/articles/StandardizedModeratedMediation.md):
  with or without moderation.
- [Plot
  gallery](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md):
  forest plots, curves, group effects and differences.

## Go further when you need it

| Task | Guide |
|----|----|
| Fit once, then compare inference methods | [Staged workflow](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md) |
| Inspect generated SEM syntax | [Model syntax](https://yangzhen1999.github.io/wsMed/articles/printGM.md) |
| Check warnings, diagnostics and reproducibility | [Diagnostics and migration](https://yangzhen1999.github.io/wsMed/articles/WorkflowReliability.md) |
| Read mathematical definitions and software comparisons | [All articles](https://yangzhen1999.github.io/wsMed/articles/index.md) |

**Next:** [run a first
analysis](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)
or [read its
results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md).
