# Plot moderation curves with Johnson-Neyman highlights

`plot_moderation_curve()` visualises how an indirect effect
(`theta_curve`) or a path coefficient (`path_curve`) varies along a
continuous moderator *W*.

The routine

- extracts the requested record (`path_name`) from `result$moderation`,
  preferring `theta_curve` when it is available in both curves;

- draws the conditional effect (`Estimate`) against the raw moderator
  grid (`W_raw`);

- overlays the Monte-Carlo confidence band (`CI.LL`, `CI.UL`) and finds
  every Johnson–Neyman segment whose 95 % CI excludes zero
  (`CI.LL * CI.UL > 0`);

- shades these significant regions and annotates each with its start /
  end percentiles (for example, `"sig 12.5%-38.3%"`).

Visual elements

- **Red ribbon** – overall 95 % confidence band (`ns_fill`);

- **Green ribbon** – significant Johnson–Neyman intervals (`sig_fill`);

- **Solid line** – point estimate;

- **Dashed h-line** – zero reference;

- **Dashed v-lines** – J–N bounds.

## Usage

``` r
plot_moderation_curve(
  result,
  path_name,
  title = NULL,
  x_label = "Moderator (W)",
  y_label = "Estimate",
  ns_fill = "#FEE0D2",
  sig_fill = "#C7E9C0",
  alpha_ci = 0.35,
  alpha_sig = 0.35,
  base_size = 14
)
```

## Arguments

- result:

  A [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)
  result that contains a `$moderation` element.

- path_name:

  Exact name of the path to plot (e.g. `"indirect_1_2"` or `"b_1_2"`).
  When the name exists in both curves, `theta_curve` is used.

- title:

  Optional plot title (default
  `sprintf("Effect Curve: (%s)", path_name)`).

- x_label, y_label:

  Axis labels. Defaults are `"Moderator (W)"` and `"Estimate"`.

- ns_fill, sig_fill:

  Fill colours for the confidence band and the significant regions.

- alpha_ci, alpha_sig:

  Alpha values for the two ribbons.

- base_size:

  Base font size passed to
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).

## Value

A `ggplot` object (add layers or save with `ggsave()`).
