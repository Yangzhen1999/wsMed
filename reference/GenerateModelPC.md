# Generate Parallel and Chained Mediation Model

Dynamically generates a structural equation modeling (SEM) syntax for
mediation analysis that integrates both parallel and chained mediators.
Unlike the Combined Parallel and Chained mediation model
(`GenerateModelCP`), this function assumes that the chained mediator
receives inputs from the parallel mediators and directly influences the
outcome variable, emphasizing a downstream role for the chained
mediator.

## Usage

``` r
GenerateModelPC(prepared_data, MP = character(0))
```

## Arguments

- prepared_data:

  A data frame returned by
  [`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
  containing the processed within-subject mediator and outcome
  variables. The data frame must include columns for difference scores
  (`Mdiff`) and average scores (`Mavg`) of mediators, as well as the
  outcome difference score (`Ydiff`).

- MP:

  A character vector specifying which paths are moderated by
  variable(s) W. Acceptable values include: - `"a2"`, `"a3"`, ...:
  moderation on the a paths (W → Mdiff). - `"b2"`, `"b3"`, ...:
  moderation on the b paths (Mdiff × W → Ydiff). - `"b_2_1"`, `"b_3_1"`,
  ...: moderation on the cross-paths from parallel mediators to the
  chain mediator (e.g., M2 → M1). - `"d_2_1"`, `"d_3_1"`, ...:
  moderation on the paths from parallel mediators’ centered means to
  M1. - `"cp"`: moderation on the direct effect of X on Y (i.e., W →
  Ydiff).

            This argument controls which interaction terms (e.g., \code{int_Mdiff_W}, \code{int_Mavg_W}) are included
            in the regression equations. Variable names are automatically matched using the naming convention
            \code{"int_<predictor>_W<index>"}.

## Value

A character string representing the SEM model syntax for the specified
parallel and chained mediation analysis.

## Details

This function is designed to build SEM models that integrate parallel
and chained mediation structures. It automatically identifies variable
names from the prepared dataset and generates the necessary model
syntax, including:

- **Outcome regression**: Defines the relationship between the
  difference scores of the outcome (`Ydiff`), the chained mediator
  (`M1diff`), and the parallel mediators (`M2diff`, `M3diff`, etc.).

- **Mediator regressions**: Constructs separate regression models for
  the parallel mediators and the chained mediator. The chained mediator
  incorporates predictors from all parallel mediators.

- **Indirect effects**: Computes indirect effects for:

  - Parallel mediators (`M2diff`, `M3diff`, etc.) directly influencing
    the outcome.

  - The chained mediator (`M1diff`) directly influencing the outcome.

  - Combined paths where parallel mediators influence the chained
    mediator, which in turn influences the outcome.

- **Total indirect effect**: Summarizes all indirect effects from
  parallel and chained mediation paths.

- **Total effect**: Combines the direct effect (`cp`) and the total
  indirect effect.

- **Contrasts of indirect effects**: Optionally computes pairwise
  contrasts between indirect effects for different mediation paths.

- **Coefficients in different 'X' conditions**: Computes path
  coefficients under different `X` conditions to analyze moderation
  effects.

This model is suitable for designs where mediators include both
independent parallel paths and sequential chained paths, providing a
comprehensive mediation analysis framework.

## See also

[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md),
[`GenerateModelP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelP.md),
[`GenerateModelCN()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCN.md)

## Examples

``` r
# Example prepared data
prepared_data <- data.frame(
  M1diff = rnorm(100),
  M2diff = rnorm(100),
  M3diff = rnorm(100),
  M1avg = rnorm(100),
  M2avg = rnorm(100),
  M3avg = rnorm(100),
  Ydiff = rnorm(100)
)

# Generate SEM model syntax
sem_model <- GenerateModelPC(prepared_data)
cat(sem_model)
#> Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + b3*M3diff + d2*M2avg + d3*M3avg
#> M2diff ~ a2*1
#> M3diff ~ a3*1
#> M1diff ~ a1*1 + b_2_1*M2diff + d_2_1*M2avg + b_3_1*M3diff + d_3_1*M3avg
#> indirect_1 := a1 * b1
#> indirect_2 := a2 * b2
#> indirect_2_1 := a2 * b_2_1 * b1
#> indirect_3 := a3 * b3
#> indirect_3_1 := a3 * b_3_1 * b1
#> total_indirect := indirect_1 + indirect_2 + indirect_2_1 + indirect_3 + indirect_3_1
#> total_effect := cp + total_indirect
```
