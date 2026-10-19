# Fit a specified mediation model without simulation

Fit a specified mediation model without simulation

## Usage

``` r
wsmed_fit(
  model,
  data,
  missing = c("error", "listwise", "fiml", "mi"),
  mi = list(),
  fixed.x = FALSE,
  verbose = FALSE,
  standardized = FALSE
)
```

## Arguments

- model:

  A `wsmed_model` object.

- data:

  A wide data frame with one row per participant.

- missing:

  Missing-data strategy: error, listwise, fiml, or mi.

- mi:

  MI controls: m, method, seed, or completed. Supply `completed` as a
  list of at least two completed wide data frames or a `mice` mids
  object to use externally generated imputations. m is then inferred (or
  must match). Omit method and seed with completed data. Inference has
  its own seed.

- fixed.x:

  Whether exogenous moments are fixed in the SEM.

- verbose:

  Show progress messages.

- standardized:

  Logical default for effect extraction, summaries and plots. Does not
  change model fitting; inference inherits this setting.

## Value

A `wsmed_fit` containing all fits and pooled estimates for MI.

## Details

This release preserves the existing per-imputation centering and
first-imputation reporting reference. It does not implement
MI-bootstrap. Factor outcome, mediator, and within-subject covariate
columns are unsupported. See
[wsmed_categorical](https://yangzhen1999.github.io/wsMed/reference/wsmed_categorical.md)
for reference coding, numeric 0/1 predictors, and restrictions on
missing categorical predictors. `mi$method` specifies the method for
numeric variables; factors use logistic or multinomial regression.
Default imputation uses main effects and need not preserve
substantive-model interactions. For moderated models, consider
model-compatible external imputation (e.g., SMC-FCS) and pass its
completed datasets. Supplied datasets must preserve participant order,
row names, observed values and factor levels, and complete all analysis
variables. Difference scores and products are rebuilt separately in
every dataset, then the same Rubin/MC engine is used. Validation does
not establish imputation-model compatibility. Save the external
imputer's settings, convergence diagnostics and software versions
separately. Internal MI with moderator interactions signals one
`wsmed_mi_compatibility_warning` per fit and records it in fit
diagnostics. Numeric 0/1 moderators remain continuous in this interface;
a message explains this choice. For categorical predictors in either
interface, use unordered factors with explicit levels; the first level
is the reference group. Type messages are retained as
`diagnostics$input_notes` and do not change estimates or random-number
state. Diagnostics include dataset-level convergence/admissibility,
covariance checks, case counts, warnings, and fitted category counts.
Complete-case matrix rank is descriptive, not an identification test for
FIML. Counts below five receive a descriptive small-category flag, not a
universal validity cutoff. Constant transformed variables are named in
pre-fit errors. Non-converged MI datasets stop pooling; known
inadmissible fits cannot enter inference.
