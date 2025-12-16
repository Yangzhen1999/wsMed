# Fix legacy CI column names in a data.frame

Converts columns like `CI[LL]` / `CI[UL]` or `CI.LL` / `CI.UL` to the
standard produced by
[`.make_ci_names()`](https://yangzhen1999.github.io/wsMed/reference/dot-make_ci_names.md).

## Usage

``` r
fix_ci_names(df, ci = 0.95)
```
