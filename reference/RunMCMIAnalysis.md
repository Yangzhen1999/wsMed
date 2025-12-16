# Monte Carlo SEM with Multiple Imputation (WsMed Workflow)

`RunMCMIAnalysis()` is a helper that:

1.  imputes missing data via
    [`PrepareMissingData`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md);

2.  generates all WsMed variables in each completed data set;

3.  fits the user-supplied SEM model to each replicate; and

4.  pools the results via
    [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md),
    producing Monte Carlo confidence intervals (MCCI) for all model
    parameters.

## Usage

``` r
RunMCMIAnalysis(
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
  keep_W_raw = TRUE,
  keep_C_raw = TRUE,
  sem_model,
  Na = "MI",
  R = 20000L,
  alpha = c(0.001, 0.01, 0.05),
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06
)
```

## Arguments

- data_missing:

  Data frame with missing values.

- m:

  Integer, number of imputations. Default `5`.

- method_num:

  Character, imputation method for numeric variables (e.g., `"pmm"`,
  `"norm"`). Default `"pmm"`.

- seed:

  Integer random seed (passed to `mice` and `MCMI2`).

- M_C1, M_C2:

  Character vectors: mediator names at condition 1 & 2 (same length).

- Y_C1, Y_C2:

  Character scalars: outcome names at condition 1 & 2.

- C_C1, C_C2:

  Optional character vectors: within-subject controls.

- C:

  Optional character vector: between-subject controls.

- C_type:

  Optional vector (length = `C`); each element `"continuous"`,
  `"categorical"`, or `"auto"` (default).

- W:

  Optional character vector: moderator name(s).

- W_type:

  Optional vector (length = `W`); same coding as `C_type`.

- keep_W_raw, keep_C_raw:

  Logical; keep raw W / C columns in the processed data? Defaults
  `TRUE`.

- sem_model:

  Character string, lavaan syntax of the SEM to be fitted.

- Na:

  Character, missing-data strategy. Currently only `"MI"` is
  implemented.

- R:

  Integer, number of Monte Carlo samples (default `20000L`).

- alpha:

  Numeric vector, significance levels for two-sided CIs (default
  `c(0.001, 0.01, 0.05)`).

- decomposition:

  Decomposition used by
  [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md)
  (`"eigen"` \| `"chol"` \| `"svd"`). Default `"eigen"`.

- pd:

  Logical, enforce positive-definite covariance (default `TRUE`).

- tol:

  Numeric tolerance for PD checks. Default `1e-6`.

## Value

A list with three elements:

- `mc_result`:

  A `semmcci` object returned by
  [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md).

- `first_imputed_data`:

  The first processed data frame (useful for inspection or plotting).

- `imputation_summary`:

  Diagnostics from
  [`PrepareMissingData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md).

## Details

Internally the function calls:

- [`PrepareMissingData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md)
  – performs multiple imputation (**logreg** / **polyreg** for
  categorical variables, and `method_num` for numeric) and applies
  [`PrepareData`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  to each imputed set;

- [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md) –
  pools parameter estimates across the `m` imputations and draws `R`
  Monte Carlo samples.

Only the missing-data strategy `Na = "MI"` is supported.

## See also

[`PrepareMissingData`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md),
[`PrepareData`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md),
`MCMI2`, `wsMed`
