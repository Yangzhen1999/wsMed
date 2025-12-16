# Generate Parallel Mediation Model

Dynamically generates a structural equation modeling (SEM) syntax for
parallel mediation analysis based on the prepared dataset. The function
computes regression equations for mediators and the outcome variable,
indirect effects, total effects, contrasts between indirect effect, and
.

## Usage

``` r
GenerateModelP(prepared_data, MP = character(0))
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
  variable(s) W. Valid values include: - `"a1"`, `"a2"`, ...: moderation
  on the a paths (W → Mdiff). - `"b1"`, `"b2"`, ...: moderation on the b
  paths (Mdiff × W → Ydiff). - `"d1"`, `"d2"`, ...: moderation on the d
  paths (Mavg × W → Ydiff). - `"cp"`: moderation on the direct effect
  from X to Y (i.e., W → Ydiff).

            This argument controls which interaction terms (e.g., \code{int_Mdiff_W}, \code{int_Mavg_W}) are
            added to the corresponding regression equations.

## Value

A character string representing the SEM model syntax for the specified
parallel mediation analysis.

## Details

This function is used to construct SEM models for parallel mediation
analysis. It automatically parses variable names from the prepared
dataset and dynamically creates the necessary model syntax, including:

- **Outcome regression**: Defines the relationship between the
  difference scores of the outcome (`Ydiff`) and the mediators (`Mdiff`)
  as well as their average scores (`Mavg`).

- **Mediator regressions**: Defines the intercept models for each
  mediator's difference score.

- **Indirect effects**: Computes the indirect effects for each mediator
  using the product of path coefficients (e.g., `a * b`).

- **Total indirect effect**: Calculates the sum of all indirect effects.

- **Total effect**: Combines the direct effect (`cp`) and the total
  indirect effect.

- **Contrasts of indirect effects**: Optionally calculates the pairwise
  contrasts between the indirect effects when multiple mediators are
  present.

- **coefficients in different 'X' conditions**: Calculates path
  coefficients in different X conditions to observe the moderation
  effect of ‘X'.

This model is suitable for parallel mediation designs where multiple
mediators act independently.

## See also

[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md),
[`GenerateModelCN()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCN.md)

## Examples

``` r
# Example prepared data
prepared_data <- data.frame(
  M1diff = rnorm(100),
  M2diff = rnorm(100),
  M1avg = rnorm(100),
  M2avg = rnorm(100),
  Ydiff = rnorm(100)
)

# Generate SEM model syntax
sem_model <- GenerateModelP(prepared_data)
cat(sem_model)
#> Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + d2*M2avg
#> M1diff ~ a1*1
#> M2diff ~ a2*1
#> indirect_1 := a1 * b1
#> indirect_2 := a2 * b2
#> total_indirect := indirect_1 + indirect_2
#> total_effect := cp + total_indirect
```
