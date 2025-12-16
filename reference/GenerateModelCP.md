# Generate Combined Parallel and Chained Mediation Model

Dynamically generates a structural equation modeling (SEM) syntax for
combined parallel and chained mediation analysis based on the prepared
dataset. The function computes regression equations for mediators and
the outcome variable, indirect effects for both parallel and chained
mediation paths, total effects, contrasts between indirect effects, and
coefficients in different X conditions.

## Usage

``` r
GenerateModelCP(prepared_data, MP = character(0))
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
  moderation on the a paths of parallel mediators (W → Mdiff). - `"b2"`,
  `"b3"`, ...: moderation on the b paths of parallel mediators (Mdiff ×
  W → Ydiff). - `"b_1_2"`, `"b_1_3"`, ...: moderation on the paths from
  the chain mediator to parallel mediators. - `"d_1_2"`, `"d_1_3"`, ...:
  moderation on the paths from the chain mediator’s Mavg to parallel
  mediators. - `"cp"`: moderation on the direct effect from X to Y
  (i.e., W → Ydiff).

            Each entry triggers inclusion of W’s main effect or interaction terms (e.g., \code{int_Mdiff_W}).

## Value

A character string representing the SEM model syntax for the specified
combined parallel and chained mediation analysis.

## Details

This function is used to construct SEM models that combine parallel and
chained mediation analysis. It automatically parses variable names from
the prepared dataset and dynamically creates the necessary model syntax,
including:

- **Outcome regression**: Defines the relationship between the
  difference scores of the outcome (`Ydiff`), the chained mediator
  (`M1diff`), and the parallel mediators (`M2diff`, `M3diff`, etc.).

- **Mediator regressions**: Defines the sequential regression models for
  the chained mediator and each parallel mediator.

- **Indirect effects**: Computes the indirect effects for both chained
  and parallel mediation paths, including multi-step indirect effects
  involving both chained and parallel mediators.

- **Total indirect effect**: Calculates the sum of all indirect effects
  from chained and parallel mediation paths.

- **Total effect**: Combines the direct effect (`cp`) and the total
  indirect effect.

- **Contrasts of indirect effects**: Optionally calculates the pairwise
  contrasts between the indirect effects for different mediation paths.

- **Coefficients in different 'X' conditions**: Calculates path
  coefficients in different `X` conditions to observe the moderation
  effect of `X`.

This model is suitable for designs where mediators include both a
sequential chain (chained mediation) and independent parallel mediators.

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
sem_model <- GenerateModelCP(prepared_data)
cat(sem_model)
#> Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + d2*M2avg + b3*M3diff + d3*M3avg
#> M1diff ~ a1*1
#> M2diff ~ a2*1 + b_1_2*M1diff + d_1_2*M1avg
#> M3diff ~ a3*1 + b_1_3*M1diff + d_1_3*M1avg
#> indirect_1 := a1 * b1
#> indirect_2 := a2 * b2
#> indirect_1_2 := a1 * b_1_2 * b2
#> indirect_3 := a3 * b3
#> indirect_1_3 := a1 * b_1_3 * b3
#> total_indirect := indirect_1 + indirect_2 + indirect_1_2 + indirect_3 + indirect_1_3
#> total_effect := cp + total_indirect
```
