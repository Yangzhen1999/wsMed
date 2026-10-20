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
| Serial pathways | `"CN"` | Each mediator predicts every later mediator in the supplied order. |
| Serial-parallel structure | `"CP"` | The first mediator (`M1`) predicts all remaining mediators. |
| Parallel-serial structure | `"PC"` | All remaining mediators predict the first mediator (`M1`). |
| User-defined pathways | `"UD"` | Set `form = "UD"` and list each mediator-to-mediator or mediator-to-outcome arrow in `paths`; see the example below. |

The four predefined models are shown below. Each includes paths from the
condition to every mediator and to the outcome, and from every mediator
to the outcome. Choose the structure and mediator order from your
research design; `CP` and `PC` place `M1` at opposite ends of the
mediator connections.

**P: Parallel**

[![P model: parallel mediator
pathways](Wa.png)](https://yangzhen1999.github.io/wsMed/articles/Wa.png)

No directed connections among mediators. [Model
equations](https://yangzhen1999.github.io/wsMed/articles/GenerateModelP.md).

**CN: Serial**

[![CN model: earlier mediators predict later
mediators](Wb.png)](https://yangzhen1999.github.io/wsMed/articles/Wb.png)

Each earlier mediator predicts every later mediator. [Model
equations](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCN.md).

**CP: Serial-parallel**

[![CP model: M1 predicts the remaining parallel
mediators](Wc.png)](https://yangzhen1999.github.io/wsMed/articles/Wc.png)

M1 predicts M2, M3, and so on. [Model
equations](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCP.md).

**PC: Parallel-serial**

[![PC model: the parallel mediators predict
M1](Wd.png)](https://yangzhen1999.github.io/wsMed/articles/Wd.png)

M2, M3, and so on predict M1. [Model
equations](https://yangzhen1999.github.io/wsMed/articles/GenerateModelPC.md).

Click a diagram to enlarge it. In these difference-score diagrams,
`diff` denotes condition 2 minus condition 1 and `avg` denotes the
centered average; the triangle represents the constant used to estimate
condition effects.

For **user-defined models**, `M1`, `M2`, and so on refer to the
positions in `M_C1` and `M_C2`; `Y` refers to the pair supplied through
`Y_C1` and `Y_C2`. For example, with `M_C1 = c("A1", "B1", "C1")` and
`M_C2 = c("A2", "B2", "C2")`, the following specifies A to C, C to the
outcome, and B to the outcome:

``` r

custom_paths <- c(
  "M1 -> M3",  # A to C
  "M3 -> Y",   # C to the outcome
  "M2 -> Y"    # B to the outcome
)
```

Pass this vector as `paths = custom_paths` together with `form = "UD"`
in [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md).
Write one arrow per string using these model labels, not the raw column
names. Only the listed mediator connections are included: this example
omits `M1 -> Y`. Condition-to-mediator paths and the direct
condition-to-outcome path are added automatically. The [worked UD
example](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCustom.md)
shows the complete call, input rules, and resulting indirect effects.

To add a moderator to this UD model, keep `custom_paths` and add
`W = "D3"` and `MP = c("b_1_3", "b3")` to the call. Here, D3 is the
moderator column; `b_1_3` and `b3` select the M1-to-M3 and M3-to-outcome
slopes. Use coefficient labels in `MP`, not the arrow strings used in
`paths`. The [UD moderation
example](https://yangzhen1999.github.io/wsMed/articles/GenerateModelCustom.html#add-a-moderator)
shows the complete call, how to choose other paths, and how to read
conditional effects at selected moderator values.

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
| Specify, fit, infer, and inspect or extract at each stage | [Staged workflow](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md) |
| Inspect generated SEM syntax | [Model syntax](https://yangzhen1999.github.io/wsMed/articles/printGM.md) |
| Check warnings, diagnostics and reproducibility | [Diagnostics and migration](https://yangzhen1999.github.io/wsMed/articles/WorkflowReliability.md) |
| Read mathematical definitions and software comparisons | [All articles](https://yangzhen1999.github.io/wsMed/articles/index.md) |

**Next:** [run a first
analysis](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)
or [read its
results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md).
