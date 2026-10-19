# Specify a two-condition mediation model

Specify a two-condition mediation model

## Usage

``` r
wsmed_model(
  outcome,
  mediators,
  conditions = names(outcome),
  covariates = list(),
  structure = "parallel",
  paths = NULL,
  moderator = NULL
)
```

## Arguments

- outcome:

  Named pair of outcome columns, in condition order.

- mediators:

  Named list of pairs of mediator columns.

- conditions:

  Two condition names. Defaults to the outcome pair names.

- covariates:

  List with `between` column names and `within` named pairs.

- structure:

  One of parallel, serial, serial_parallel, parallel_serial, or custom.
  Mediator order matters for predefined serial structures.

- paths:

  Directed edges using mediator role names and Y, for custom models.

- moderator:

  NULL or a list with `variable`, `main_effects`, `interactions`, and
  optionally `average_interactions`. Only main_effects = "all_equations"
  is currently supported. Interactions name edges such as "stress -\>
  Y".

## Value

A `wsmed_model` specification, without data or fitted estimates.

## Details

All moderator main effects are explicitly included in all difference
equations. Difference-slope and average-slope interactions are separate.
Categorical between-subject predictors must be unordered factors in the
staged workflow. Use the same explicit factor declaration with
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md).
Set factor levels explicitly; the first level is the reference group.

## See also

[wsmed_categorical](https://yangzhen1999.github.io/wsMed/reference/wsmed_categorical.md)
for supported variable roles and factor coding.
