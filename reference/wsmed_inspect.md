# Inspect a modular workflow without recomputation

Inspect a modular workflow without recomputation

## Usage

``` r
wsmed_inspect(
  object,
  component = c("model", "syntax", "data", "fits", "diagnostics", "provenance")
)
```

## Arguments

- object:

  A wsmed_model, wsmed_fit, wsmed_inference, or wsMed object.

- component:

  model, syntax, data, fits, diagnostics, or provenance.

## Value

The requested specification, syntax, data, backend fits, or metadata.
