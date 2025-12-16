# Sort Parameters for Printing in SEM Output

Sorts a parameter table by conceptual priority for presentation
purposes. This function is designed to support formatted output of
mediation and SEM results by organizing parameters such as a-paths,
b-paths, indirect effects, contrasts, etc.

## Usage

``` r
sort_parameters(df)
```

## Arguments

- df:

  A data frame that contains a column named `Parameter` (e.g., from
  Monte Carlo CI output).

## Value

A reordered version of the same data frame, with rows sorted according
to a predefined logical structure:

1.  a-paths (e.g., a1, a2, ...)

2.  b-paths (e.g., b1, b2, ...)

3.  d-paths (e.g., d1, d2, ...)

4.  indirect effects (e.g., ind1, ind2, ...)

5.  direct effect

6.  total indirect

7.  total effect

8.  contrasts (e.g., ind1-ind2, ind2-ind3)

9.  X-condition path terms (e.g., X1_b1, X0_b1, ...)

## Details

This is an internal helper function used by `print.WsMed()` to ensure
that printed tables of standardized or unstandardized estimates appear
in a logical and human-readable order.
