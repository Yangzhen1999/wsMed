# Plot moderation curves with Johnson-Neyman highlights

\`plot_moderation_curve()\` plots how a conditional indirect effect or
path coefficient changes across values of a continuous moderator.

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

  A result object returned by \`wsMed()\` containing a \`moderation\`
  component.

- path_name:

  A single character string giving the exact name of the conditional
  effect to plot, such as \`"indirect_1_2"\` or \`"b_1_2"\`. When the
  name occurs in both \`theta_curve\` and \`path_curve\`,
  \`theta_curve\` is used.

- title:

  An optional character string giving the plot title. If \`NULL\`, a
  title is automatically constructed from \`path_name\`.

- x_label:

  A character string giving the horizontal-axis label. The default is
  \`"Moderator (W)"\`.

- y_label:

  A character string giving the vertical-axis label. The default is
  \`"Estimate"\`.

- ns_fill:

  A colour specification for the complete confidence band.

- sig_fill:

  A colour specification for the highlighted significant regions.

- alpha_ci:

  A numeric value between zero and one controlling the transparency of
  the complete confidence band.

- alpha_sig:

  A numeric value between zero and one controlling the transparency of
  the highlighted significant regions.

- base_size:

  A positive numeric value specifying the base font size passed to
  \`ggplot2::theme_minimal()\`.

## Value

A \`ggplot\` object. Additional ggplot2 layers can be added to the
returned object, and the plot can be saved using \`ggplot2::ggsave()\`.

## Details

The function searches the moderation results for the effect specified by
\`path_name\`. It first searches \`result\$moderation\$theta_curve\`,
which contains conditional indirect effects, and then
\`result\$moderation\$path_curve\`, which contains conditional path
coefficients. If the same name appears in both components,
\`theta_curve\` is used.

The selected records are ordered by the raw moderator values in
\`W_raw\`. The function then plots the conditional estimates in
\`Estimate\` and the confidence band defined by \`CI.LL\` and \`CI.UL\`.

A moderator value is treated as statistically significant when the lower
and upper confidence limits have the same sign. Equivalently, the
product of \`CI.LL\` and \`CI.UL\` must be greater than zero.
Consecutive significant moderator values are combined into intervals and
highlighted as Johnson-Neyman regions.

The red ribbon shows the complete confidence band, whereas the green
ribbon highlights regions in which the confidence interval excludes
zero. The solid line represents the conditional point estimate. The
horizontal dashed line marks zero, and the vertical dashed lines mark
the boundaries of the highlighted regions. Each highlighted region is
annotated with the percentile range of the moderator values that it
covers.

The interval boundaries are identified from the moderator grid stored in
the moderation results. They should therefore be interpreted as
grid-based approximations to the Johnson-Neyman boundaries. A denser
moderator grid produces more precise boundary locations.
