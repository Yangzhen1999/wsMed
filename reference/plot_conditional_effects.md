# Plot conditional effects at moderator levels

Draw point estimates and confidence intervals by categorical group or by
the stored low, mean and high levels of a continuous moderator. Each
effect is shown in its own panel. Categories are not joined by
interpolating lines.

## Usage

``` r
plot_conditional_effects(
  result,
  paths = NULL,
  type = c("indirect", "paths", "overall"),
  levels = NULL,
  standardized = FALSE,
  engine = c("mc", "boot"),
  labels = NULL,
  title = NULL,
  x_label = NULL,
  y_label = NULL,
  base_size = 12,
  ncol = NULL
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

- type:

  `"indirect"` for specific indirect effects, `"paths"` for available
  conditional path coefficients, or `"overall"` for total indirect and
  total effects.

- levels:

  Optional group/level labels to select, in display order. NULL uses
  their stored order. For continuous W the labels are `"-1 SD"`,
  `"0 SD"`, `"+1 SD"`; the axis also displays stored raw W probe values.

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

- ncol:

  Optional number of facet columns.

## Value

A ggplot object with plotted data and a `wsmed_plot` attribute.

## Details

Intervals are the stored percentile conditional intervals, including
jointly transformed scales for standardized results. They are individual
intervals, not simultaneous confidence intervals.

## See also

[`plot_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_effects.md),
[`plot_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/plot_contrasts.md)
