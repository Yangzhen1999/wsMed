# Apply uncertainty quantification to an existing fit

Apply uncertainty quantification to an existing fit

## Usage

``` r
wsmed_infer(
  object,
  method = c("mc", "bootstrap"),
  draws = NULL,
  seed = NULL,
  level = 0.95,
  interval = "perc",
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06
)
```

## Arguments

- object:

  A `wsmed_fit`, or a new `wsMed` one-call result.

- method:

  mc or bootstrap. MI currently supports mc only.

- draws:

  Number of draws; defaults to 20000 for mc and 2000 for bootstrap.

- seed:

  Random seed, independent of the imputation seed.

- level:

  Confidence level.

- interval:

  Bootstrap interval type: perc, bc, or bca.simple. This controls the
  legacy parameter table stored in the inference backend. Effect
  extraction and confint methods always use percentile intervals.
  bca.simple uses zero acceleration, rather than a full BCa calculation.

- decomposition:

  MI covariance factorization: eigen, chol, or svd.

- pd, tol:

  MI covariance checks; passed to the existing sampler.

## Value

A `wsmed_inference` storing draws and the original fit.

## Details

Inference never reimputes or changes the supplied fit. Bootstrap
necessarily fits resampled datasets. No new statistical engine is
introduced. Seeded calls restore the caller's random state; seed = NULL
consumes the current random stream and advances it normally. Fits with
endogenous products must record compatible model and MI pooling
algorithm identifiers. Older unversioned moderated fits require
refitting from the original data; package version alone cannot identify
their algorithms.
