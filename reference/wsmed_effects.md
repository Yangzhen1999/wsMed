# Extract effects from fitted models or stored inference

Extract effects from fitted models or stored inference

## Usage

``` r
wsmed_effects(
  object,
  type = c("indirect", "all", "total", "direct", "total_indirect", "paths", "parameters"),
  terms = NULL,
  at = NULL,
  scale = NULL,
  method = NULL,
  level = NULL,
  standardized = NULL
)
```

## Arguments

- object:

  A wsmed_fit, wsmed_inference, or wsMed result.

- type:

  Effect family: indirect, all (direct, specific indirect, total
  indirect and total effects), total, direct, total_indirect, paths, or
  parameters (primitive model parameters).

- terms:

  Optional coefficient or effect names within the selected family.

- at:

  Named list of raw moderator values, for example list(Age = c(30, 50)).
  Defaults to the centering reference for a continuous moderator, or all
  observed levels for a categorical moderator. Parameters ignore no
  probes: supplying at with type = "parameters" is an error.

- scale:

  Compatibility spelling: raw or marginal. Explicit conflicting scale
  and standardized arguments are rejected.

- method:

  Stored inference to use when object is wsMed: mc or bootstrap.
  Required if both are stored. A fit alone returns point estimates only.

- level:

  Confidence level; defaults to the stored inference level or .95.

- standardized:

  NULL inherits the saved analysis setting (FALSE for older objects
  without a setting). TRUE uses model-implied marginal endpoint SDs,
  with or without moderation. FALSE returns raw effects.

## Value

A wsmed_results object with a full-precision table, joint effect draws,
draw identities, query settings, and diagnostics.

## Details

Extraction never fits, imputes, or samples. Effect and contrast
intervals are percentile intervals from the stored joint draws,
including when bootstrap parameter tables were requested with bias
correction. For conditional standardization, moderator probes remain
fixed in raw units. Scales and coefficients vary jointly across draws.
Invalid standardized draws are excluded jointly and their original
identities are recorded. For MI the existing first-imputation reference
and per-imputation centering are retained. Endogenous products have an
auxiliary moment model that retains the necessary upstream residual
covariances. MI moderated models jointly pool marginal variances with
coefficients, using a delta-method within-imputation covariance and
Rubin's rules; MC draws retain their covariance. Refit objects saved
before this correction. Finite MC draws or new imputations need not
match after recoding. The query interpretation records the plug-in
outcome-difference SD. Conditional result tables include `extrapolated`
flags relative to observed moderator values among used participants
(imputed values excluded). Out-of-range continuous probes signal
`wsmed_extrapolation_warning` once per extraction; this checks the
marginal range, not joint covariate overlap or data density. Categorical
tables include `n.observed`, `n.fitted.min`, and `n.fitted.max`; for MI
the latter span the completed datasets and are not effective sample
sizes. The descriptive support metadata are retained in `query$support`.
Incompatible saved fits stop before extraction. If a fit is compatible
but its MI sampler is unversioned or outdated, rerun
[`wsmed_infer()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_infer.md)
on that fit. Stored primitive coefficients and full legacy tables remain
inspectable.
