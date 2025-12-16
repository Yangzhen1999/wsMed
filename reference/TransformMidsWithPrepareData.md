# Apply PrepareData to Imputed Datasets and Return New MIDS Object

This function applies the
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
preprocessing step to each imputed dataset in a `mids` object and
returns a new `mids` object with the transformed data. It is designed
for use in within-subject mediation analysis pipelines when working with
multiply imputed data.

## Usage

``` r
TransformMidsWithPrepareData(mids_obj, M_C1, M_C2, Y_C1, Y_C2)
```

## Arguments

- mids_obj:

  A `mids` object created by the `mice` package, containing multiply
  imputed datasets.

- M_C1:

  A character vector specifying the names of mediator variables under
  Condition 1 (e.g., pre-test).

- M_C2:

  A character vector specifying the names of mediator variables under
  Condition 2 (e.g., post-test).

- Y_C1:

  A character string specifying the outcome variable under Condition 1.

- Y_C2:

  A character string specifying the outcome variable under Condition 2.

## Value

A new `mids` object where each imputed dataset has been processed using
[`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md).

## Details

The function performs the following steps:

- Extracts all imputed datasets from the original `mids` object.

- Applies
  [`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  to each imputed dataset using the specified within-subject mediator
  and outcome variables.

- Combines all processed datasets into a long format and reconstructs a
  new `mids` object via
  [`mice::as.mids()`](https://amices.org/mice/reference/as.mids.html).

This enables subsequent analyses to operate on a version of the multiply
imputed data where difference scores and averages have already been
computed.
