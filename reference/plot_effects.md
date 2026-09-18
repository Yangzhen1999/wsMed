# Forest plot of mediation effects

Plot fitted indirect effects, the total indirect effect, the direct
effect (`cp`) and the total effect with their stored confidence
intervals. With a moderator these are effects at the model's reference
value (centered continuous W = 0, or the reference category), not
averages across W. Use
[`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md)
to show selected moderator levels instead.

## Usage

``` r
plot_effects(
  result,
  paths = NULL,
  standardized = FALSE,
  engine = c("mc", "boot"),
  labels = NULL,
  title = NULL,
  x_label = NULL,
  y_label = NULL,
  base_size = 12
)
```

## Arguments

- result:

  A result returned by
  [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md).

- paths:

  Optional character vector of effect identifiers, in display order.
  NULL selects all available effects. Both `indirect_1` and
  `indirect_effect_1` are accepted when they identify an available
  effect.

- standardized:

  Use standardized results, requested when fitting with
  `standardized = TRUE`. No scaling is recomputed from interval
  endpoints.

- engine:

  For `ci_method = "both"`, select `"mc"` or `"boot"`. For a single
  engine its stored results are used.

- labels:

  Optional named character vector mapping effect identifiers to display
  labels. Partial mappings are allowed.

- title:

  Optional plot title.

- x_label, y_label:

  Optional axis labels.

- base_size:

  Base font size.

## Value

A ggplot object. Its `data` contains the plotted estimates and
`CI.LL`/`CI.UL` limits. The `wsmed_plot` attribute records the selected
engine, scale and confidence level. Use
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
to export it.

## Details

MC intervals come from the parameter draws (or the stored standardized
parameter table). Bootstrap plots use the bootstrap limits, not the
normal-theory limits that may also be present in the table.

## See also

[`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md),
[`plot_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/plot_contrasts.md),
[`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
