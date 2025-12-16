# Prepare Data with Missing Values for Mediation Analysis

Handles missing values in the dataset through multiple imputation and
prepares the imputed datasets for within-subject mediation analysis. The
function imputes missing data, processes each imputed dataset, and
provides diagnostics for the imputation process.

## Usage

``` r
PrepareMissingData(
  data_missing,
  m = 5,
  method_num = "pmm",
  seed = 123,
  M_C1,
  M_C2,
  Y_C1,
  Y_C2,
  C_C1 = NULL,
  C_C2 = NULL,
  C = NULL,
  C_type = NULL,
  W = NULL,
  W_type = NULL,
  center_W = TRUE,
  keep_W_raw = TRUE,
  keep_C_raw = TRUE
)
```

## Arguments

- data_missing:

  A data frame containing the raw dataset with missing values.

- m:

  An integer specifying the number of imputations to perform. Default is
  `5`.

- method_num:

  Character; imputation method for numeric variables (for example,
  `"pmm"`, `"norm"`). Default is `"pmm"`.

- seed:

  An integer specifying the random seed for reproducibility. Default is
  `123`.

- M_C1:

  A character vector of column names representing mediators at condition
  1.

- M_C2:

  A character vector of column names representing mediators at
  condition 2. Must match the length of `M_C1`.

- Y_C1:

  A character string representing the column name of the outcome
  variable at condition 1.

- Y_C2:

  A character string representing the column name of the outcome
  variable at condition 2.

- C_C1:

  Character vector of within-subject control variable names (condition
  1).

- C_C2:

  Character vector of within-subject control variable names (condition
  2).

- C:

  Character vector of between-subject control variable names.

- C_type:

  Optional vector of the same length as `C`. Each element is
  `"continuous"`, `"categorical"`, or `"auto"` (default). Ignored when
  `C = NULL`.

- W:

  Optional character vector: moderator names (at most J).

- W_type:

  Optional vector of the same length as `W`. Same coding as `C_type`.
  Ignored when `W = NULL`.

- center_W:

  Logical. Whether to center the moderator variable W.

- keep_W_raw, keep_C_raw:

  Logical; keep the original W / C columns in the returned data?

## Value

A list containing:

- `processed_data_list`:

  A list of `m` data frames, each representing an imputed and processed
  dataset ready for within-subject mediation analysis.

- `imputation_summary`:

  A summary of the imputation process, including diagnostics and
  convergence information.

## Details

This function is designed to preprocess datasets with missing values for
mediation analysis. It performs the following steps:

- Multiple imputation: Uses specified imputation methods (for example,
  predictive mean matching) to generate `m` imputed datasets.

- Data preparation: Applies
  [`PrepareData`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  to each of the `m` imputed datasets to calculate difference scores and
  centered averages for mediators and the outcome variable.

- Imputation diagnostics: Provides summary diagnostics for the
  imputation process, including information about missing data patterns
  and convergence.

This function integrates imputation and data preparation, ensuring that
the resulting datasets are ready for subsequent mediation analysis.

## See also

[`PrepareData`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
[`ImputeData`](https://yangzhen1999.github.io/wsMed/reference/ImputeData.md),
[`wsMed`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md)

## Examples

``` r
# Example dataset with missing values
data("example_data", package = "wsMed")
set.seed(123)
example_dataN <- mice::ampute(
  data = example_data,
  prop = 0.1
)$amp
#> Warning: Data is made numeric internally, because the calculation of weights requires numeric data

# Prepare the dataset with multiple imputations
prepared_missing_data <- PrepareMissingData(
  data_missing = example_dataN,
  m = 5,
  M_C1 = c("A2", "B2"),
  M_C2 = c("A1", "B1"),
  Y_C1 = "C2",
  Y_C2 = "C1"
)
#> Class: mids
#> Number of multiple imputations:  5 
#> Imputation methods:
#>    C2    C1    A2    B2    A1    B1 
#> "pmm" "pmm"    "" "pmm"    "" "pmm" 
#> PredictorMatrix:
#>    C2 C1 A2 B2 A1 B1
#> C2  0  1  1  1  1  1
#> C1  1  0  1  1  1  1
#> A2  1  1  0  1  1  1
#> B2  1  1  1  0  1  1
#> A1  1  1  1  1  0  1
#> B1  1  1  1  1  1  0

# Access processed datasets
processed_data_list <- prepared_missing_data$processed_data_list
imputation_summary  <- prepared_missing_data$imputation_summary
```
