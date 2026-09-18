# Plot conditional effects across a continuous moderator

Plot a conditional indirect effect, total effect or path coefficient
with its pointwise confidence band. Highlight stored grid values whose
interval excludes zero. Boundary labels use raw moderator units, not
sample percentiles.

## Usage

``` r
plot_moderation_curve(
  result,
  path_name,
  title = NULL,
  x_label = "Moderator (W, raw units)",
  y_label = "Estimate",
  ns_fill = "#FEE0D2",
  sig_fill = "#C7E9C0",
  alpha_ci = 0.35,
  alpha_sig = 0.35,
  base_size = 14,
  standardized = FALSE,
  engine = c("mc", "boot")
)
```

## Arguments

- result:

  A result returned by
  [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
  with a continuous moderator.

- path_name:

  One stored effect identifier, such as `"indirect_effect_1_2"`,
  `"total_indirect"` or `"b_1_2"`. `"indirect_1_2"` is also accepted as
  an alias.

- title:

  Optional plot title.

- x_label, y_label:

  Axis labels. The default x axis uses raw W units.

- ns_fill:

  Colour of the complete confidence band.

- sig_fill:

  Colour of the regions whose pointwise CI excludes zero.

- alpha_ci, alpha_sig:

  Opacity of the band and highlighted regions.

- base_size:

  Base font size.

- standardized:

  Use the stored standardized conditional results.

- engine:

  For `ci_method = "both"`, select `"mc"` or `"boot"`.

## Value

A ggplot object. Its `data` contains the selected curve; the
`wsmed_regions` attribute contains raw-unit grid interval endpoints. The
`wsmed_plot` attribute records engine, scale and confidence level.

## Details

Highlighted intervals are approximate ranges on the stored grid, not
exact Johnson–Neyman boundaries or simultaneous confidence regions. A
label `[a, b]` reports the first and last qualifying grid values. An
isolated qualifying point is marked by a vertical line. Missing
confidence limits break a highlighted range. The displayed confidence
level follows `result$alpha`; no fixed p-value threshold is implied.

## See also

[`plot_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_effects.md),
[`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md),
[`plot_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/plot_contrasts.md)
