# Generate a User-Defined Within-Subject Mediation Model

Generates lavaan model syntax for a user-defined within-subject
mediation model. Users specify directed paths among mediators and from
mediators to the outcome. The function automatically adds the
corresponding difference and level components and identifies all
indirect effects.

## Usage

``` r
GenerateModelCustom(prepared_data, paths, MP = character(0))
```

## Arguments

- prepared_data:

  A data frame returned by \[PrepareData()\]. It must contain
  \`M1diff\`, \`M1avg\`, ..., and \`Ydiff\`.

- paths:

  A character vector defining directed paths among mediators and from
  mediators to the outcome. For example: \`c("M1 -\> M2", "M2 -\> Y")\`.

- MP:

  A character vector identifying moderated paths. Supported labels
  follow the existing wsMed convention: \`a1\`, \`b1\`, \`d1\`,
  \`b_1_2\`, \`d_1_2\`, and \`cp\`.

## Value

A character string containing lavaan model syntax.

## Examples

``` r
prepared_data <- data.frame(
  M1diff = rnorm(100),
  M1avg  = rnorm(100),
  M2diff = rnorm(100),
  M2avg  = rnorm(100),
  M3diff = rnorm(100),
  M3avg  = rnorm(100),
  Ydiff  = rnorm(100)
)

model <- GenerateModelCustom(
 prepared_data = prepared_data,
 paths = c(
   "M1 -> M3",
   "M1 -> Y",
   "M3 -> Y",
   "M2 -> Y"
 )
)

cat(model)
#> Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + d2*M2avg + b3*M3diff + d3*M3avg
#> M1diff ~ a1*1
#> M2diff ~ a2*1
#> M3diff ~ a3*1 + b_1_3*M1diff + d_1_3*M1avg
#> indirect_1_3 := a1 * b_1_3 * b3
#> indirect_1 := a1 * b1
#> indirect_2 := a2 * b2
#> indirect_3 := a3 * b3
#> total_indirect := indirect_1_3 + indirect_1 + indirect_2 + indirect_3
#> total_effect := cp + total_indirect
```
