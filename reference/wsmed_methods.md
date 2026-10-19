# Methods for modular wsMed objects

Methods for modular wsMed objects

## Usage

``` r
# S3 method for class 'wsMed'
print(
  x,
  digits = 3,
  detail = c("effects", "full", "overview", "legacy"),
  type = "all",
  at = NULL,
  standardized = NULL,
  method = NULL,
  level = NULL,
  scale = NULL,
  ...
)

# S3 method for class 'wsmed_model'
print(x, ...)

# S3 method for class 'wsmed_fit'
print(x, digits = 3, ...)

# S3 method for class 'wsmed_inference'
print(x, ...)

# S3 method for class 'wsmed_fit'
summary(object, ...)

# S3 method for class 'summary_wsmed_fit'
print(x, digits = 3, ...)

# S3 method for class 'wsmed_inference'
summary(
  object,
  type = "all",
  at = NULL,
  scale = NULL,
  standardized = NULL,
  ...
)

# S3 method for class 'wsMed'
summary(
  object,
  type = "all",
  at = NULL,
  scale = NULL,
  method = NULL,
  standardized = NULL,
  ...
)

# S3 method for class 'wsmed_fit'
coef(object, ...)

# S3 method for class 'wsmed_fit'
vcov(object, ...)

# S3 method for class 'wsmed_fit'
nobs(object, ...)

# S3 method for class 'wsmed_inference'
coef(object, ...)

# S3 method for class 'wsmed_inference'
vcov(object, ...)

# S3 method for class 'wsmed_inference'
nobs(object, ...)

# S3 method for class 'wsMed'
coef(object, ...)

# S3 method for class 'wsMed'
vcov(object, ...)

# S3 method for class 'wsMed'
nobs(object, ...)

# S3 method for class 'wsmed_fit'
confint(object, parm, level = NULL, ...)

# S3 method for class 'wsmed_inference'
confint(object, parm, level = NULL, standardized = NULL, scale = NULL, ...)

# S3 method for class 'wsMed'
confint(
  object,
  parm,
  level = NULL,
  method = NULL,
  standardized = NULL,
  scale = NULL,
  ...
)

# S3 method for class 'wsmed_results'
print(x, digits = 3, ...)

# S3 method for class 'wsmed_results'
summary(object, level = NULL, ...)

# S3 method for class 'wsmed_results'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'wsmed_results'
coef(object, ...)

# S3 method for class 'wsmed_results'
vcov(object, ...)

# S3 method for class 'wsmed_results'
confint(object, parm, level = NULL, ...)

# S3 method for class 'summary_wsmed'
print(x, digits = 3, ...)

# S3 method for class 'summary_wsmed'
summary(object, level = NULL, ...)
```

## Arguments

- x, object:

  A wsMed or modular workflow object.

- digits:

  Number of displayed digits. Stored estimates are not rounded.

- detail:

  effects (default) for core effects, full for effects and path
  coefficients, overview for fit status, or legacy for original stored
  tables.

- type, at, scale, method:

  Passed to
  [`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md).
  Summaries default to all core effects. Select method when both
  inference engines are stored.

- standardized:

  NULL inherits the saved analysis setting; TRUE or FALSE overrides it
  without fitting or sampling. Applies with or without moderation.

- level:

  Confidence level. NULL uses the level saved in the selected inference
  or results object.

- ...:

  Additional arguments, passed to effect extraction by summary and
  confint methods. See
  [wsmed_plots](https://yangzhen1999.github.io/wsMed/reference/wsmed_plots.md)
  for plotting arguments.

- parm:

  Names or positions of parameters/effects to include in intervals.

- row.names, optional:

  Standard data-frame conversion arguments.

## Value

print methods return their input invisibly. summary returns a
summary_wsmed (also a wsmed_results) for inference/one-call objects, or
a summary_wsmed_fit for fits. Structured summaries contain effects and
coefficients data frames, info, diagnostics and selected joint effect
draws. as.data.frame, coef, confint, vcov and plot on the summary
concern the selected effects; coefficients contains conditional path
slopes (not all primitive parameters). Use type = 'parameters' for
primitive parameters. Summary display uses printCoefmat; tables retain
full precision. coef returns a named numeric vector. vcov returns the
fit covariance (Rubin-pooled for MI), or the empirical covariance of
stored draws for inference/results. confint recomputes percentile limits
from stored draws without sampling. Its default level is the saved
level, including when called on an inference or one-call object; use an
explicit level to override it. On those two classes confint concerns
native primitive parameters, matching coef and vcov regardless of the
reporting preference (explicit scale overrides are accepted). Fit-only
summaries also describe native parameters. Extract effects first to
obtain indirect/conditional-effect intervals. nobs returns the sample
size for each fitted dataset. as.data.frame returns a full-precision
results table. plot returns a ggplot.

## See also

[`wsmed_reproducibility()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_reproducibility.md)
for an exportable analysis manifest.
