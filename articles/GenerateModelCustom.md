# Specifying user-defined mediation models

Use `wsMed(form = "UD", paths = ...)` when the mediator connections do
not match a predefined model. Supply paired raw measurements, then list
the arrows among mediators and from mediators to the outcome. This
tutorial uses the package’s simulated data and the default inference and
reporting settings.

``` r

data(example_data)
```

## Mediator numbering

Mediator labels are assigned according to the order of the variables
supplied to `M_C1` and `M_C2`. For example:

| Construct | Condition 1 | Condition 2 | Model label |
|:----------|:------------|:------------|:------------|
| A         | `A1`        | `A2`        | `M1`        |
| B         | `B1`        | `B2`        | `M2`        |
| C         | `C1`        | `C2`        | `M3`        |
| D         | `D1`        | `D2`        | `Y`         |

Therefore, `"M1 -> M3"` represents a path from construct A to construct
C. Mediator numbering identifies variables; it does not determine path
direction.

## Specifying a custom model

Write one directed connection per string in `paths`. Use the model
labels `M1`, `M2`, and so on, plus `Y`, rather than raw column names
such as `A1`. For example, to connect A to C, C to the outcome, and B to
the outcome:

``` r

custom_paths <- c(
  "M1 -> M3",  # A to C
  "M3 -> Y",   # C to the outcome
  "M2 -> Y"    # B to the outcome
)
```

| Entry in `paths` | Connection in this example |
|------------------|----------------------------|
| `"M1 -> M3"`     | A predicts C               |
| `"M3 -> Y"`      | C predicts the outcome D   |
| `"M2 -> Y"`      | B predicts the outcome D   |

Each string represents one arrow, not a complete mediation route. For
example, specify `"M1 -> M3"` and `"M3 -> Y"` separately instead of
writing `"M1 -> M3 -> Y"`. Spaces around `->` are optional.

Only the listed mediator connections are included. In this example there
is no direct path from M1 to Y, and no directed path between M1 and M2.
Paths from the condition to **every mediator**, and the direct path from
the condition to the outcome, are added automatically. Do not add `X` to
the path vector.

## Fitting the complete model with wsMed

Pass the path vector to
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
along with the paired measurements:

``` r

result_custom <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  form = "UD",
  paths = custom_paths
)
print(result_custom)
#> wsMed analysis
#> Model: UD | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -3.00e-02   1.68e-02 -6.31e-02  2.90e-03
#> indirect_1_3: M1 -> M3                -2.25e-05   3.74e-04 -8.64e-04  7.36e-04
#> indirect_2: M2                        -1.40e-03   2.75e-03 -8.43e-03  2.98e-03
#> indirect_3: M3                        -1.85e-04   2.17e-03 -5.11e-03  4.38e-03
#> total_indirect: Total indirect effect -1.60e-03   3.54e-03 -9.79e-03  4.91e-03
#> total: Total effect                   -3.16e-02   1.69e-02 -6.48e-02  1.61e-03
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

This call uses the default Monte Carlo CIs and unstandardized output.
Use the usual summary method for effect and path-coefficient tables:

``` r

summary(result_custom)
#> wsMed statistical summary
#> Model: UD | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -3.00e-02   1.68e-02 -6.31e-02  2.90e-03
#> indirect_1_3: M1 -> M3                -2.25e-05   3.74e-04 -8.64e-04  7.36e-04
#> indirect_2: M2                        -1.40e-03   2.75e-03 -8.43e-03  2.98e-03
#> indirect_3: M3                        -1.85e-04   2.17e-03 -5.11e-03  4.38e-03
#> total_indirect: Total indirect effect -1.60e-03   3.54e-03 -9.79e-03  4.91e-03
#> total: Total effect                   -3.16e-02   1.69e-02 -6.48e-02  1.61e-03
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>       Estimate Std. Error CI lower CI upper
#> cp    -0.03000    0.01684 -0.06307  0.00290
#> b2    -0.09632    0.09303 -0.27662  0.08915
#> d2    -0.01377    0.08708 -0.18534  0.15458
#> b3    -0.01350    0.10245 -0.21287  0.18842
#> d3    -0.16325    0.10038 -0.35988  0.03574
#> a1    -0.02712    0.01757 -0.06167  0.00727
#> a2     0.01448    0.01798 -0.02044  0.04994
#> a3     0.01368    0.01641 -0.01819  0.04573
#> b_1_3 -0.06142    0.09198 -0.23967  0.12025
#> d_1_3 -0.07843    0.08705 -0.24852  0.09208
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

To include a direct M1-to-outcome connection, add its arrow to the
vector:

``` r

expanded_paths <- c(
  custom_paths,
  "M1 -> Y"
)
```

Refit the same call with `paths = expanded_paths` to include that
connection. This changes the fitted model and adds the indirect route
through M1 alone.

## Input requirements

- Reference only mediator labels defined by the supplied column pairs.
- Use one arrow per string, starting at a mediator and ending at another
  mediator or `Y`. At least one arrow must end at `Y`.
- Do not repeat an arrow or use a self-loop such as `"M1 -> M1"`.
- Do not create a cycle, such as both `"M1 -> M2"` and `"M2 -> M1"`.

Every mediator intended to contribute an indirect effect needs a route
to `Y`, either directly or through other mediators. The package warns if
a supplied mediator has no such route.

## Indirect effects

[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
identifies all indirect routes implied by the specified arrows. In the
following notation, `X` denotes the within-subject condition; it is not
an entry to add to `paths`. The model defined by `custom_paths` contains
three indirect effects:

| Route                | Parameter label | Product           |
|----------------------|-----------------|-------------------|
| `X -> M1 -> M3 -> Y` | `indirect_1_3`  | `a1 * b_1_3 * b3` |
| `X -> M2 -> Y`       | `indirect_2`    | `a2 * b2`         |
| `X -> M3 -> Y`       | `indirect_3`    | `a3 * b3`         |

The last effect exists because the path from the condition to every
mediator, including $`M_3`$, is added automatically. All identified
indirect effects are summed to form `total_indirect`, and the total
effect is defined as `cp + total_indirect`.

## Parameter labels

The generated model uses the following labels:

| Path                    | Difference component | Level component |
|:------------------------|:---------------------|:----------------|
| $`X \rightarrow M_i`$   | `ai`                 | –               |
| $`M_i \rightarrow Y`$   | `bi`                 | `di`            |
| $`M_j \rightarrow M_i`$ | `b_j_i`              | `d_j_i`         |
| $`X \rightarrow Y`$     | `cp`                 | –               |

For example, the path $`M_1 \rightarrow M_3`$ uses `b_1_3` and `d_1_3`,
whereas $`M_3 \rightarrow Y`$ uses `b3` and `d3`.

## Add a moderator

Keep `form = "UD"` and the same `custom_paths`. Add `W` to identify the
between-subject moderator column and `MP` to select the path
coefficients to moderate. You do not need to construct product terms
yourself.

| Argument | What to supply                            | Example            |
|----------|-------------------------------------------|--------------------|
| `paths`  | The mediator connections in the model     | `custom_paths`     |
| `W`      | The moderator’s column name in the data   | `"D3"`             |
| `MP`     | Coefficient labels for the selected paths | `c("b_1_3", "b3")` |

### Choose the moderated paths

`paths` uses arrows such as `"M1 -> M3"`, whereas `MP` uses coefficient
labels such as `"b_1_3"`. For the current custom model:

| Path to moderate | Entry in `MP` | Meaning |
|----|----|----|
| M1 to M3 | `"b_1_3"` | The M1-difference slope in the M3-difference equation varies with W. |
| M3 to the outcome | `"b3"` | The M3-difference slope in the outcome equation varies with W. |
| M2 to the outcome | `"b2"` | The M2-difference slope in the outcome equation varies with W. |

Thus, `MP = "b3"` selects only the M3-to-outcome slope, while
`MP = c("b_1_3", "b3")` selects both slopes along the
M1-to-M3-to-outcome route. To add moderation of the M2-to-outcome slope,
use `MP = c("b_1_3", "b3", "b2")`. Each label must exist in the model:
`"b1"` is unavailable here because `"M1 -> Y"` is absent from
`custom_paths`. Do not put an indirect-effect label such as
`"indirect_1_3"` in `MP`; select the coefficients that form that effect.

The corresponding average-component slopes can be selected with
`"d_1_3"`, `"d3"`, and `"d2"`. These are distinct coefficients:
selecting `"b3"` does not also select `"d3"`.

The condition-to-mediator labels `"a1"`, `"a2"`, `"a3"`, and the
direct-effect label `"cp"` are also accepted. With W present, wsMed
includes its main effect in every mediator-difference and
outcome-difference equation. Consequently, these condition effects can
vary with W even when their labels are omitted from `MP`. For the b and
d slopes, `MP` controls which interaction terms are added.

### Fit and read the results

Here, D3 is a continuous moderator. This call selects the M1-to-M3 and
M3-to-outcome slopes and keeps the default Monte Carlo CIs and
unstandardized output:

``` r

custom_moderated <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  form = "UD",
  paths = custom_paths,
  W = "D3",
  MP = c("b_1_3", "b3")
)
print(custom_moderated)
#> wsMed analysis
#> Model: UD | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: D3 in raw units; centering reference = 0.452271 
#>                                                       Estimate Std. Error
#> cp@1: Direct effect [D3 = 0.452]                     -0.029850   0.016991
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.000022   0.000367
#> indirect_2@1: M2 [D3 = 0.452]                        -0.001400   0.002744
#> indirect_3@1: M3 [D3 = 0.452]                        -0.000183   0.002168
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.001605   0.003581
#> total@1: Total effect [D3 = 0.452]                   -0.031455   0.017152
#>                                                       CI lower  CI upper
#> cp@1: Direct effect [D3 = 0.452]                     -0.063464  0.003219
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.000838  0.000719
#> indirect_2@1: M2 [D3 = 0.452]                        -0.008152  0.003015
#> indirect_3@1: M3 [D3 = 0.452]                        -0.005150  0.004257
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.009945  0.004960
#> total@1: Total effect [D3 = 0.452]                   -0.065383  0.002083
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

[`print()`](https://rdrr.io/r/base/print.html) reports the conditional
effects. [`summary()`](https://rdrr.io/r/base/summary.html) also shows
the conditional path coefficients:

``` r

summary(custom_moderated)
#> wsMed statistical summary
#> Model: UD | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: D3 in raw units; centering reference = 0.452271 
#>                                                       Estimate Std. Error
#> cp@1: Direct effect [D3 = 0.452]                     -0.029850   0.016991
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.000022   0.000367
#> indirect_2@1: M2 [D3 = 0.452]                        -0.001400   0.002744
#> indirect_3@1: M3 [D3 = 0.452]                        -0.000183   0.002168
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.001605   0.003581
#> total@1: Total effect [D3 = 0.452]                   -0.031455   0.017152
#>                                                       CI lower  CI upper
#> cp@1: Direct effect [D3 = 0.452]                     -0.063464  0.003219
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.000838  0.000719
#> indirect_2@1: M2 [D3 = 0.452]                        -0.008152  0.003015
#> indirect_3@1: M3 [D3 = 0.452]                        -0.005150  0.004257
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.009945  0.004960
#> total@1: Total effect [D3 = 0.452]                   -0.065383  0.002083
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>                             Estimate Std. Error CI lower CI upper
#> cp@1: cp [D3 = 0.452]       -0.02985    0.01699 -0.06346  0.00322
#> b2@1: b2 [D3 = 0.452]       -0.09668    0.09286 -0.27706  0.08467
#> d2@1: d2 [D3 = 0.452]       -0.00641    0.08965 -0.18213  0.16843
#> b3@1: b3 [D3 = 0.452]       -0.01370    0.10379 -0.21420  0.19224
#> d3@1: d3 [D3 = 0.452]       -0.15680    0.10278 -0.35544  0.04381
#> a1@1: a1 [D3 = 0.452]       -0.02712    0.01728 -0.06113  0.00670
#> a2@1: a2 [D3 = 0.452]        0.01448    0.01791 -0.02029  0.04996
#> a3@1: a3 [D3 = 0.452]        0.01336    0.01623 -0.01834  0.04508
#> b_1_3@1: b_1_3 [D3 = 0.452] -0.05915    0.09216 -0.24131  0.12014
#> d_1_3@1: d_1_3 [D3 = 0.452] -0.05761    0.09046 -0.23376  0.11900
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

For this continuous moderator, the default tables evaluate effects at
the centering reference shown in the output. The default plot instead
shows the indirect effects across the observed moderator range:

``` r

plot(custom_moderated)
```

![plot of chunk
custom-moderation-plot](figures/GenerateModelCustom-custom-moderation-plot-1.png)

plot of chunk custom-moderation-plot

Each indirect effect uses all coefficients along its route, evaluated at
the same moderator value. For example, `indirect_1_3` combines the
condition-to-M1, M1-to-M3, and M3-to-outcome coefficients. The total
indirect effect includes all routes in `custom_paths`, including those
without a selected b-path interaction. A model that includes moderation
need not show evidence that an effect varies; interpret the estimates
and their uncertainty.

### Choose moderator values

To request particular values, add `at` when reporting results. The
following uses the 25th, 50th, and 75th percentiles of D3 as
illustrative probes:

``` r

probe_values <- quantile(
  example_data$D3,
  probs = c(0.25, 0.50, 0.75)
)
summary(
  custom_moderated,
  type = "indirect",
  at = list(D3 = probe_values)
)
#> wsMed statistical summary
#> Model: UD | Missing: DE | Observations: 100 
#> Effects:
#> wsMed indirect | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: D3 in raw units; centering reference = 0.452271 
#>                                        Estimate Std. Error  CI lower  CI upper
#> indirect_1_3@1: M1 -> M3 [D3 = 0.288] -7.61e-05   7.42e-04 -1.79e-03  1.41e-03
#> indirect_2@1: M2 [D3 = 0.288]         -2.31e-03   3.68e-03 -1.14e-02  3.47e-03
#> indirect_3@1: M3 [D3 = 0.288]         -4.06e-04   3.35e-03 -7.90e-03  6.61e-03
#> indirect_1_3@2: M1 -> M3 [D3 = 0.462] -1.99e-05   3.62e-04 -8.21e-04  7.13e-04
#> indirect_2@2: M2 [D3 = 0.462]         -1.35e-03   2.72e-03 -8.05e-03  3.09e-03
#> indirect_3@2: M3 [D3 = 0.462]         -1.73e-04   2.16e-03 -5.11e-03  4.25e-03
#> indirect_1_3@3: M1 -> M3 [D3 = 0.605] -4.42e-08   4.89e-04 -1.01e-03  1.05e-03
#> indirect_2@3: M2 [D3 = 0.605]         -5.60e-04   2.92e-03 -7.43e-03  5.28e-03
#> indirect_3@3: M3 [D3 = 0.605]         -5.49e-05   2.79e-03 -6.26e-03  5.93e-03
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>                              Estimate Std. Error  CI lower  CI upper
#> cp@1: cp [D3 = 0.288]       -0.025502   0.021699 -0.068032  0.017184
#> b2@1: b2 [D3 = 0.288]       -0.096683   0.092856 -0.277064  0.084672
#> d2@1: d2 [D3 = 0.288]       -0.006408   0.089646 -0.182134  0.168425
#> b3@1: b3 [D3 = 0.288]       -0.020509   0.118303 -0.248059  0.213903
#> d3@1: d3 [D3 = 0.288]       -0.156803   0.102775 -0.355442  0.043808
#> a1@1: a1 [D3 = 0.288]       -0.030228   0.021483 -0.072126  0.012219
#> a2@1: a2 [D3 = 0.288]        0.023870   0.022105 -0.019499  0.067463
#> a3@1: a3 [D3 = 0.288]        0.019788   0.020417 -0.019758  0.059997
#> b_1_3@1: b_1_3 [D3 = 0.288] -0.122735   0.115591 -0.349926  0.102452
#> d_1_3@1: d_1_3 [D3 = 0.288] -0.057606   0.090456 -0.233756  0.118996
#> cp@2: cp [D3 = 0.462]       -0.030101   0.016985 -0.063845  0.002871
#> b2@2: b2 [D3 = 0.462]       -0.096683   0.092856 -0.277064  0.084672
#> d2@2: d2 [D3 = 0.462]       -0.006408   0.089646 -0.182134  0.168425
#> b3@2: b3 [D3 = 0.462]       -0.013311   0.104543 -0.215033  0.194371
#> d3@2: d3 [D3 = 0.462]       -0.156803   0.102775 -0.355442  0.043808
#> a1@2: a1 [D3 = 0.462]       -0.026945   0.017289 -0.060974  0.006947
#> a2@2: a2 [D3 = 0.462]        0.013941   0.017923 -0.020877  0.049342
#> a3@2: a3 [D3 = 0.462]        0.012991   0.016235 -0.018635  0.044618
#> b_1_3@2: b_1_3 [D3 = 0.462] -0.055471   0.092270 -0.237402  0.124112
#> d_1_3@2: d_1_3 [D3 = 0.462] -0.057606   0.090456 -0.233756  0.118996
#> cp@3: cp [D3 = 0.605]       -0.033877   0.020525 -0.074733  0.005715
#> b2@3: b2 [D3 = 0.605]       -0.096683   0.092856 -0.277064  0.084672
#> d2@3: d2 [D3 = 0.605]       -0.006408   0.089646 -0.182134  0.168425
#> b3@3: b3 [D3 = 0.605]       -0.007402   0.133446 -0.271143  0.254797
#> d3@3: d3 [D3 = 0.605]       -0.156803   0.102775 -0.355442  0.043808
#> a1@3: a1 [D3 = 0.605]       -0.024249   0.020896 -0.065307  0.016484
#> a2@3: a2 [D3 = 0.605]        0.005790   0.021547 -0.035794  0.048020
#> a3@3: a3 [D3 = 0.605]        0.007411   0.019648 -0.031067  0.045667
#> b_1_3@3: b_1_3 [D3 = 0.605] -0.000246   0.113022 -0.218961  0.222366
#> d_1_3@3: d_1_3 [D3 = 0.605] -0.057606   0.090456 -0.233756  0.118996
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

The name `D3` in `at` must match the column supplied to `W`. Supply
values on the original scale, even though wsMed centers continuous
moderators internally. Choose values that are meaningful for your study
and supported by the data. Changing `at` reuses the fitted model and
inference draws. See [Read and export
results](https://yangzhen1999.github.io/wsMed/articles/ResultsGuide.md)
for selecting and comparing effects.

### Use a categorical moderator

The same `paths` and `MP` specification works with a binary or
multicategory moderator. Store it as an unordered factor with the
desired reference group as its first level, then supply its column name
through `W`; for example, use `W = "Group"` if that factor is named
Group. The default tables report effects for all observed groups, and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) displays
group-specific effects with CIs. The [categorical predictor
tutorial](https://yangzhen1999.github.io/wsMed/articles/CategoricalPredictors.md)
shows how to declare the factor and compare groups.

### Standardized moderated custom models

After the default analysis, request standardized results with:

``` r

summary(
  custom_moderated,
  standardized = TRUE
)
#> wsMed statistical summary
#> Model: UD | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Moderator: D3 in raw units; centering reference = 0.452271 
#> Standardization: effect / marginal model-implied SD(D2 - D1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 0.169551 
#> The denominator is not a moderator-specific conditional SD.
#>                                                      Estimate Std. Error
#> cp@1: Direct effect [D3 = 0.452]                     -0.17605    0.09921
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.00013    0.00210
#> indirect_2@1: M2 [D3 = 0.452]                        -0.00826    0.01566
#> indirect_3@1: M3 [D3 = 0.452]                        -0.00108    0.01242
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.00947    0.02047
#> total@1: Total effect [D3 = 0.452]                   -0.18552    0.10010
#>                                                      CI lower CI upper
#> cp@1: Direct effect [D3 = 0.452]                     -0.37298  0.01861
#> indirect_1_3@1: M1 -> M3 [D3 = 0.452]                -0.00481  0.00410
#> indirect_2@1: M2 [D3 = 0.452]                        -0.04678  0.01749
#> indirect_3@1: M3 [D3 = 0.452]                        -0.02938  0.02437
#> total_indirect@1: Total indirect effect [D3 = 0.452] -0.05665  0.02834
#> total@1: Total effect [D3 = 0.452]                   -0.38315  0.01184
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>                             Estimate Std. Error CI lower CI upper
#> cp@1: cp [D3 = 0.452]       -0.17605    0.09921 -0.37298  0.01861
#> b2@1: b2 [D3 = 0.452]       -0.10242    0.09570 -0.28644  0.08721
#> d2@1: d2 [D3 = 0.452]       -0.00762    0.10379 -0.21175  0.19580
#> b3@1: b3 [D3 = 0.452]       -0.01312    0.09834 -0.20399  0.18269
#> d3@1: d3 [D3 = 0.452]       -0.16174    0.10200 -0.35126  0.04594
#> a1@1: a1 [D3 = 0.452]       -0.15463    0.09977 -0.35401  0.03847
#> a2@1: a2 [D3 = 0.452]        0.08064    0.10039 -0.11299  0.28036
#> a3@1: a3 [D3 = 0.452]        0.08230    0.09945 -0.11224  0.27691
#> b_1_3@1: b_1_3 [D3 = 0.452] -0.06390    0.09788 -0.25431  0.12881
#> d_1_3@1: d_1_3 [D3 = 0.452] -0.06531    0.10064 -0.25939  0.13360
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

Alternatively, include `standardized = TRUE` in the original
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
call to make standardized reporting the default. `at` still uses raw
moderator values. See [standardized
effects](https://yangzhen1999.github.io/wsMed/articles/StandardizedModeratedMediation.md)
for the scaling rules and CIs.

## Optional: inspect the generated equations

The call to
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
performs data preparation and model generation for you. Use
`printGM(result_custom)` to inspect the fitted model specification. If
you want to generate the equations without fitting, the lower-level
functions below provide that option.

[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
converts the raw condition-specific variables into mediator difference
and centered level components and an outcome difference score.

``` r

prepared_data <- PrepareData(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2"
)

names(prepared_data)
#> [1] "Ydiff"  "M1diff" "M2diff" "M3diff" "M1avg"  "M2avg"  "M3avg"
```

For mediator $`M_i`$, the two components are

``` math
M_{i,\mathrm{diff}} = M_{i2} - M_{i1}
```

and

``` math
M_{i,\mathrm{avg}}
=
\widetilde M_{i,\mathrm{avg}}-\overline{\widetilde M}_{i,\mathrm{avg}},
\qquad
\widetilde M_{i,\mathrm{avg}}=\frac{M_{i1} + M_{i2}}{2},
```

where the bar is the sample mean used by
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
to center the average component. The difference component is not
centered.

The corresponding model syntax is generated as follows:

``` r

custom_model <- GenerateModelCustom(
  prepared_data = prepared_data,
  paths = custom_paths
)

cat(custom_model)
#> Ydiff ~ cp*1 + b2*M2diff + d2*M2avg + b3*M3diff + d3*M3avg
#> M1diff ~ a1*1
#> M2diff ~ a2*1
#> M3diff ~ a3*1 + b_1_3*M1diff + d_1_3*M1avg
#> indirect_1_3 := a1 * b_1_3 * b3
#> indirect_2 := a2 * b2
#> indirect_3 := a3 * b3
#> total_indirect := indirect_1_3 + indirect_2 + indirect_3
#> total_effect := cp + total_indirect
```

For every specified structural edge, the generated regression includes
both the difference and level components of the predictor mediator.
Thus, `"M1 -> M3"` contributes

``` r

b_1_3*M1diff + d_1_3*M1avg
```

to the regression equation for `M3diff`.

Only specified structural paths are added. Because `"M1 -> Y"` is absent
from `custom_paths`, `M1diff` and `M1avg` do not appear directly in the
regression equation for `Ydiff`.
