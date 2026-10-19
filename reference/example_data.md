# Simulated data for mediation tutorials

Artificial data used to demonstrate model syntax, estimation, and
categorical predictors. The labels do not identify substantive
psychological constructs. This is distinct from the empirical manuscript
dataset
[`wsmed_examples()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_examples.md).

## Usage

``` r
example_data
```

## Format

A tibble (data frame) with 100 rows and 14 variables:

- A1, A2, A3:

  Numeric measurements for variable A at three conditions.

- B1, B2, B3:

  Numeric measurements for variable B at three conditions.

- C1, C2, C3:

  Numeric measurements for variable C at three conditions.

- D1, D2, D3:

  Numeric measurements for variable D at three conditions.

- Group:

  An unordered factor with levels high, med, and low, in that order.

- W_Group:

  An unordered factor with levels high, med, and low, in that order.

## Details

All columns are complete. A wsMed analysis selects two condition columns
per outcome or mediator. The factor labels are nominal categories; they
do not request an ordinal regression model. Set their level order
explicitly before fitting to select a different reference category.

## See also

[`wsmed_examples()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_examples.md),
[wsmed_categorical](https://yangzhen1999.github.io/wsMed/reference/wsmed_categorical.md)

## Examples

``` r
data(example_data)
dim(example_data)
#> [1] 100  14
levels(example_data$Group)
#> [1] "high" "med"  "low" 
```
