# Read and export results

Start by reading the default report. Use more specific queries only when
you need a different effect, reporting scale or confidence level.

The example below is the parallel mediation model from [Get
started](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md).

Example setup

``` r

data(example_data)
result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "D1",
  Y_C2 = "D2"
)
```

## Read the default report

``` r

print(result)
#> wsMed analysis
#> Model: P | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -0.031795   0.017000 -0.064525  0.001864
#> indirect_1: M1                         0.001311   0.003208 -0.004601  0.008917
#> indirect_2: M2                        -0.001120   0.002570 -0.007617  0.003084
#> total_indirect: Total indirect effect  0.000191   0.004111 -0.008172  0.008783
#> total: Total effect                   -0.031604   0.017015 -0.064740  0.001839
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

[`print()`](https://rdrr.io/r/base/print.html) displays the core effects
and analysis information. The report gives the estimate, SE and CI for
each specific indirect effect, the total indirect effect, the direct
effect and the total effect. Here the default output is unstandardized,
with 95% Monte Carlo CIs.

## Get a statistical summary

``` r

summary(result)
#> wsMed statistical summary
#> Model: P | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -0.031795   0.017000 -0.064525  0.001864
#> indirect_1: M1                         0.001311   0.003208 -0.004601  0.008917
#> indirect_2: M2                        -0.001120   0.002570 -0.007617  0.003084
#> total_indirect: Total indirect effect  0.000191   0.004111 -0.008172  0.008783
#> total: Total effect                   -0.031604   0.017015 -0.064740  0.001839
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>    Estimate Std. Error CI lower CI upper
#> cp -0.03180    0.01700 -0.06453  0.00186
#> b1 -0.04834    0.09555 -0.23422  0.13918
#> d1 -0.06905    0.09508 -0.25772  0.11690
#> b2 -0.07732    0.09387 -0.26459  0.10461
#> d2 -0.03676    0.08692 -0.20641  0.13385
#> a1 -0.02712    0.01772 -0.06242  0.00737
#> a2  0.01448    0.01796 -0.02033  0.04929
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

[`summary()`](https://rdrr.io/r/base/summary.html) returns a structured
report containing effects, path coefficients and analysis settings; its
default display shows the statistical tables. Unlike
[`print()`](https://rdrr.io/r/base/print.html), it creates a summary
object that can be saved and reused:

``` r

s <- summary(result)
```

Typing `s` displays the same summary. Neither operation repeats fitting
or sampling. The stored tables retain full precision even though the
printed values are rounded.

## Plot the results

``` r

plot(result)
```

![plot of chunk default-plot](figures/ResultsGuide-default-plot-1.png)

plot of chunk default-plot

The default plot of this model shows the specific indirect effects. To
plot all effects selected in the summary, use `plot(s)`. Both inherit
the reporting scale saved during the analysis. See the [plot
gallery](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md)
for the available displays and optional settings.

## Choose more specific output

Start with the calls above. The following options change one part of the
report without fitting again.

### Request standardized effects

``` r

summary(
  result,
  standardized = TRUE
)
#> wsMed statistical summary
#> Model: P | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | marginal scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Standardization: effect / marginal model-implied SD(D2 - D1); condition contrast is unscaled.
#> Plug-in marginal outcome-difference SD: 0.169239 
#> The denominator is not a moderator-specific conditional SD.
#>                                       Estimate Std. Error CI lower CI upper
#> cp: Direct effect                     -0.18787    0.10051 -0.38202  0.01096
#> indirect_1: M1                         0.00775    0.01858 -0.02674  0.05159
#> indirect_2: M2                        -0.00662    0.01480 -0.04360  0.01801
#> total_indirect: Total indirect effect  0.00113    0.02378 -0.04770  0.05070
#> total: Total effect                   -0.18674    0.10054 -0.38189  0.01043
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>    Estimate Std. Error CI lower CI upper
#> cp  -0.1879     0.1005  -0.3820   0.0110
#> b1  -0.0501     0.0972  -0.2381   0.1427
#> d1  -0.0751     0.1012  -0.2724   0.1253
#> b2  -0.0821     0.0973  -0.2710   0.1092
#> d2  -0.0438     0.1014  -0.2392   0.1566
#> a1  -0.1546     0.1026  -0.3598   0.0419
#> a2   0.0806     0.1013  -0.1133   0.2817
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

For complete condition effects, standardization uses the model-implied
marginal SD of the outcome difference. See [standardized
effects](https://yangzhen1999.github.io/wsMed/articles/StandardizedModeratedMediation.md)
for the treatment of paths, interactions and conditional effects.

If the original call used `standardized = TRUE`, plain `print(result)`,
`summary(result)` and `plot(result)` already use standardized output.

### Select an effect family

``` r

summary(
  result,
  type = "indirect"
)
#> wsMed statistical summary
#> Model: P | Missing: DE | Observations: 100 
#> Effects:
#> wsMed indirect | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                Estimate Std. Error CI lower CI upper
#> indirect_1: M1  0.00131    0.00321 -0.00460  0.00892
#> indirect_2: M2 -0.00112    0.00257 -0.00762  0.00308
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>    Estimate Std. Error CI lower CI upper
#> cp -0.03180    0.01700 -0.06453  0.00186
#> b1 -0.04834    0.09555 -0.23422  0.13918
#> d1 -0.06905    0.09508 -0.25772  0.11690
#> b2 -0.07732    0.09387 -0.26459  0.10461
#> d2 -0.03676    0.08692 -0.20641  0.13385
#> a1 -0.02712    0.01772 -0.06242  0.00737
#> a2  0.01448    0.01796 -0.02033  0.04929
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

Other selections include `"direct"`, `"total_indirect"`, `"total"`,
`"paths"` and `"parameters"`. Use `terms` only when selecting particular
named effects.

### Change the confidence level

``` r

summary(
  result,
  level = 0.90
)
#> wsMed statistical summary
#> Model: P | Missing: DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | mc 
#> 90% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -0.031795   0.017000 -0.059453 -0.003589
#> indirect_1: M1                         0.001311   0.003208 -0.003280  0.007212
#> indirect_2: M2                        -0.001120   0.002570 -0.006018  0.002135
#> total_indirect: Total indirect effect  0.000191   0.004111 -0.006502  0.007132
#> total: Total effect                   -0.031604   0.017015 -0.059271 -0.003342
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> 
#> Path coefficients:
#>    Estimate Std. Error CI lower CI upper
#> cp -0.03180    0.01700 -0.05945 -0.00359
#> b1 -0.04834    0.09555 -0.20435  0.10967
#> d1 -0.06905    0.09508 -0.22726  0.08711
#> b2 -0.07732    0.09387 -0.23305  0.07588
#> d2 -0.03676    0.08692 -0.17820  0.10673
#> a1 -0.02712    0.01772 -0.05642  0.00200
#> a2  0.01448    0.01796 -0.01508  0.04391
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0 
#> Tables: $effects, $coefficients; analysis settings: $info.
```

The interval is recalculated from the stored draws. Effect SEs are
sample SDs of the joint effect draws, and effect CIs are percentile
intervals.

For a model that stored both inference engines, choose `method = "mc"`
or `method = "bootstrap"` in
[`summary()`](https://rdrr.io/r/base/summary.html). The default
[`print()`](https://rdrr.io/r/base/print.html) reports both.

### Choose moderator values

For moderated mediation, the default report uses the centering reference
for a continuous moderator and all observed levels for a categorical
moderator. Use `at` to choose raw values or category labels. For
example, after fitting the second [Get started
example](https://yangzhen1999.github.io/wsMed/articles/GetStarted.html#example-2-add-a-continuous-moderator):

``` r

summary(
  moderated,
  at = list(D3 = mean(example_data$D3))
)
```

These are conditional effects at specified values, not effects averaged
over the moderator distribution.

## Compare two pathways

A difference between effects needs its own CI. Use the stored joint
draws to form that difference, then print the result directly:

``` r

effects <- wsmed_effects(result)
difference <- wsmed_contrasts(
  effects,
  list(B_minus_A = c(indirect_2 = 1, indirect_1 = -1))
)
print(difference)
#> wsMed contrasts | raw scale | mc 
#> 95% percentile intervals; 20000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#> Contrast direction (signed weights):
#>  B_minus_A: +1 * M2 -1 * M1
#>           Estimate Std. Error CI lower CI upper
#> B_minus_A -0.00243    0.00411 -0.01178  0.00492
#> Inference draws: 20000 retained of 20000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
```

`B_minus_A` is the indirect effect through B minus the effect through A.
Do not subtract separate CI endpoints, or infer a difference simply
because only one of the separate intervals excludes zero.

## Extract or export results when needed

Extraction is useful for further calculations or export; it is not
required for ordinary reports and plots.

| Task                               | Call                      |
|------------------------------------|---------------------------|
| Effects as a data frame            | `as.data.frame(s)`        |
| Selected result columns            | `effect_table[, columns]` |
| Effect estimates                   | `coef(s)`                 |
| Effect CIs                         | `confint(s)`              |
| Covariance of effect draws         | `vcov(s)`                 |
| Path-coefficient table             | `s$coefficients`          |
| Method, scale and confidence level | `s$info`                  |
| Sample size of the fitted data     | `nobs(result)`            |

The methods on `s` concern its selected effects. In contrast,
`coef(result)`, `vcov(result)` and `confint(result)` concern primitive
model parameters.

To choose which columns to display, list their names in the order you
want. For example, keep the effect name, estimate, SE and both CI
limits:

``` r

effect_table <- as.data.frame(s)
columns <- c(
  "label",
  "estimate",
  "std.error",
  "conf.low",
  "conf.high"
)
effect_table[, columns]
#>                   label      estimate   std.error     conf.low   conf.high
#> 1         Direct effect -0.0317954295 0.016999696 -0.064525051 0.001863739
#> 2                    M1  0.0013113045 0.003207828 -0.004600745 0.008917406
#> 3                    M2 -0.0011199168 0.002569908 -0.007616873 0.003084259
#> 4 Total indirect effect  0.0001913877 0.004111147 -0.008172032 0.008783391
#> 5          Total effect -0.0316040417 0.017015460 -0.064739552 0.001838718
```

Remove `"std.error"` from `columns` to omit SEs, or remove `"conf.low"`
and `"conf.high"` to omit CIs. `names(effect_table)` lists all available
columns; for moderated mediation, retain `moderator` and `at` to
identify the evaluated values or groups. Use `s$coefficients[, columns]`
for the path-coefficient table.

To export the same selected columns:

``` r

write.csv(
  effect_table[, columns],
  "mediation-effects.csv",
  row.names = FALSE
)

p <- plot(result)
ggplot2::ggsave(
  "mediation-effects.png",
  plot = p,
  width = 7,
  height = 4.5,
  dpi = 300
)
```

The CSV contains the selected columns at full precision. Use
`as.data.frame(s)` instead to export the complete effect table,
including analysis settings. Choose your own filenames when saving
results.

**Next:** [customize a
plot](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md),
or [reuse a
fit](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md)
for another inference method.
