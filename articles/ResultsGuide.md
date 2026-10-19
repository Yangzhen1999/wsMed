# Read and export results

**Goal:** obtain one organized table of all core effects, understand its
scale and intervals, and export it without copying numbers from the
console.

Use the [quick
start](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md)
first if you have not fitted a model. The short setup below makes this
page independently runnable.

Example setup: create result

``` r

data(example_data)
result <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
  Y_C1 = "D1", Y_C2 = "D2",
  form = "P", Na = "DE", ci_method = "mc",
  R = 2000, seed = 123, standardized = TRUE, verbose = FALSE
)
```

This example requests **standardized results** during analysis. The
reports, summary tables and generic plots below inherit that choice.

## Get the table you need

``` r

s <- summary(result)
knitr::kable(s$effects[c("label", "estimate", "std.error", "conf.low", "conf.high")],
  digits = 4, col.names = c("Effect / pathway", "Estimate", "SE", "CI lower", "CI upper"))
```

| Effect / pathway      | Estimate |     SE | CI lower | CI upper |
|:----------------------|---------:|-------:|---------:|---------:|
| Direct effect         |  -0.1879 | 0.1020 |  -0.3878 |   0.0189 |
| M1                    |   0.0077 | 0.0182 |  -0.0258 |   0.0509 |
| M2                    |  -0.0066 | 0.0148 |  -0.0437 |   0.0184 |
| Total indirect effect |   0.0011 | 0.0231 |  -0.0442 |   0.0515 |
| Total effect          |  -0.1867 | 0.1007 |  -0.3799 |   0.0180 |

The rows cover the direct effect, each specific indirect effect, the
total indirect effect and the total effect. In a single-mediator model,
the specific and total indirect effects are equal; both named rows
remain available.
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) rounds only
this display, while `s$effects` retains full precision.

| You want to… | Use |
|----|----|
| Read a core report in the console | `print(result)` |
| Include path coefficients in the report | `print(result, detail = "full")` |
| Save a statistical summary | `s <- summary(result)` |
| Get all selected effects as a data frame | `s$effects` or `as.data.frame(s)` |
| Get conditional path coefficients | `s$coefficients` |
| Check method, scale and confidence level | `s$info` |

[`print()`](https://rdrr.io/r/base/print.html) displays a report and
returns the original object invisibly.
[`summary()`](https://rdrr.io/r/base/summary.html) creates a structured
result that you can save, filter and plot; entering `s` displays its
ordinary R coefficient tables. Neither repeats fitting or sampling. With
moderation, `$coefficients` contains slopes evaluated at the selected
moderator values; use `type = "parameters"` for primitive parameters.

## Check the scale and intervals

``` r

s$info[c("standardized", "method", "level")]
#> $standardized
#> [1] TRUE
#> 
#> $method
#> [1] "mc"
#> 
#> $level
#> [1] 0.95
```

For these complete condition effects, standardization divides the
estimate by the model-implied **marginal SD of the outcome difference**.
It does not use a separate denominator for each moderator value or
category. See [standardized
effects](https://yangzhen1999.github.io/wsMed/articles/StandardizedModeratedMediation.md)
for the definition and conditional examples.

``` r

raw <- summary(result, standardized = FALSE)
raw$effects[c("effect", "estimate")]
#>           effect      estimate
#> 1             cp -0.0317954295
#> 2     indirect_1  0.0013113045
#> 3     indirect_2 -0.0011199168
#> 4 total_indirect  0.0001913877
#> 5          total -0.0316040417
```

The override affects this query only. `result` keeps its original
preference. Summary effect SEs come from the stored effect draws, and
intervals are percentile intervals. The older stored-table report may
use a different bootstrap interval convention; use the same convention
when comparing reports.

## Select effects or change confidence level

``` r

indirect <- summary(result, type = "indirect")
indirect$effects[c("effect", "label", "estimate", "conf.low", "conf.high")]
#>       effect label     estimate    conf.low  conf.high
#> 1 indirect_1    M1  0.007748230 -0.02579869 0.05091815
#> 2 indirect_2    M2 -0.006617359 -0.04369740 0.01837558
ci90 <- summary(result, level = .90)
ci90$effects[c("effect", "conf.low", "conf.high")]
#>           effect    conf.low   conf.high
#> 1             cp -0.35850086 -0.01930912
#> 2     indirect_1 -0.01843490  0.04134868
#> 3     indirect_2 -0.03354337  0.01277992
#> 4 total_indirect -0.03741600  0.03940504
#> 5          total -0.35134695 -0.01420823
```

Other choices are `type = "direct"`, `"total_indirect"`, `"total"`,
`"paths"` or `"parameters"`. `terms` selects identifiers listed in the
`effect` column. If the original analysis stored both engines
(`ci_method = "both"`), select `method = "mc"` or `"bootstrap"` in
[`summary()`](https://rdrr.io/r/base/summary.html);
[`print()`](https://rdrr.io/r/base/print.html) labels them separately.

For a moderated analysis, supply raw values with
`at = list(Age = c(30, 50))` or original category labels. Use your
moderator’s actual column name. Without `at`, continuous moderators use
their centering reference and categorical moderators use all observed
levels. These are **conditional effects**, not effects averaged over the
moderator. See the [analysis
guide](https://yangzhen1999.github.io/wsMed/articles/AnalysisGuide.html#add-moderation).

## Compare two pathways

``` r

effects <- wsmed_effects(result)
difference <- wsmed_contrasts(effects,
  list(B_minus_A = c(indirect_2 = 1, indirect_1 = -1)))
as.data.frame(difference)[c("label", "estimate", "conf.low", "conf.high")]
#>       label    estimate    conf.low  conf.high
#> 1 B_minus_A -0.01436559 -0.06939103 0.02830113
```

`B_minus_A` is the indirect effect through B minus the effect through A.
Its interval is computed from their matched joint draws. Do not subtract
confidence-interval endpoints or infer a difference merely because only
one of the separate intervals excludes zero.

## Export numbers and save a figure

``` r

write.csv(s$effects, "mediation-effects.csv", row.names = FALSE)
write.csv(s$coefficients, "path-coefficients.csv", row.names = FALSE)
p <- plot(s, title = "Standardized mediation effects")
ggplot2::ggsave("mediation-effects.png", p, width = 7, height = 4.5, dpi = 300)
```

The exported data retain full precision. CSV files include effect
identifiers, scale, inference method, confidence level and any moderator
information. The export examples write files to your working directory;
change the names before using them if those files already exist.

**Next:** [choose a
plot](https://yangzhen1999.github.io/wsMed/articles/PlottingEffects.md),
or learn to [reuse a
fit](https://yangzhen1999.github.io/wsMed/articles/ModularWorkflow.md)
and [record diagnostics and
provenance](https://yangzhen1999.github.io/wsMed/articles/WorkflowReliability.md).
