# Plot differences between mediation effects

Draw contrast estimates and their confidence intervals relative to zero.
With a moderator, contrasts compare groups or stored moderator levels
within each effect. Without a moderator, specific indirect paths are
compared with one another. The displayed subtraction order is explicit.

## Usage

``` r
plot_contrasts(
  result,
  paths = NULL,
  type = c("indirect", "paths", "overall"),
  contrasts = NULL,
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

- contrasts:

  Optional exact contrast labels to select, in display order. NULL
  selects all. Inspect the corresponding result table or the returned
  plot's `data$Contrast` for available labels.

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

Moderator contrasts use the existing joint-draw contrast tables. Without
a moderator, only `type = "indirect"` is available: contrasts are
computed from the stored joint draws, with point estimates evaluated at
fitted/pooled parameters. Their intervals are percentile intervals.
Standardized draws use the same draw-specific marginal endpoint scales
as other standardized effects. No model is refitted. Interval endpoints
for two separate effects are never subtracted to construct a contrast
CI. `paths` and `labels` apply to effect panels when a moderator is
present; without a moderator, `paths` selects the indirect effects to
compare and `labels` maps the full contrast labels. Continuous overall
contrasts are unavailable when the fitted result does not contain that
contrast table.

## See also

[`plot_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_effects.md),
[`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md)
