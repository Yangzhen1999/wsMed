# Paired imputation-model comparison

This follow-up holds the wsMed fitting, Rubin pooling, marginal standardization
and MC effect procedure fixed while changing the completed datasets. It uses the
four incomplete-data scenarios (5–8), population targets and seeds of the earlier
screening study. Each scenario has 200 datasets. The three arms are default PMM
(m=5), SMC-FCS (m=5), and the underlying complete data before deletion. Inference
uses 2000 draws. Raw and standardized effects and marginal SDs are retained.

SMC-FCS follows [Bartlett et al. (2015)](https://doi.org/10.1177/0962280214521348)
using the optional smcfcs package. This recipe specifically assumes observed Y1,
M2 and W, independent Y1 in the generating model, and normal M1 conditional on
M2 and W. The substantive outcome formula is
`yd ~ I(m2-m1)*W + I((m1+m2)/2)`. An explicit predictor matrix specifies
`m1 ~ m2 + W`; the outcome is handled by the substantive-model step. Each
imputation uses 20 iterations and rejection limit 5000. These iteration settings
do not themselves establish convergence. A parameter trace for the first dataset
in each scenario is retained; users must inspect diagnostics for their own data.

Two development attempts exposed formula/configuration errors before the final
comparison was frozen: raw m1/m2 main effects plus a factor-by-difference term
produced redundant columns, and the nonredundant transformed formula required an
explicit predictor matrix because automatic discovery omitted m2 inside I(...).
Partial outputs from those attempts remain in the dated local audit directory;
they are not pooled with the final runs. The final specification was rerun from
the beginning for **all four** scenarios using the original planned 200 seeds.
No failed final attempt is silently discarded. Formula rank and predictor matrix
are checked independently before the pipeline smoke test.

## Reproduce

Install the development wsMed build and smcfcs. From the repository root:

```
Rscript .github/validation/mi-comparison/check.R
Rscript .github/validation/mi-comparison/run.R new-5 5 200
Rscript .github/validation/mi-comparison/run.R new-6 6 200
Rscript .github/validation/mi-comparison/run.R new-7 7 200
Rscript .github/validation/mi-comparison/run.R new-8 8 200
Rscript .github/validation/mi-comparison/summarize.R new-summary new-5/replicates.csv new-6/replicates.csv new-7/replicates.csv new-8/replicates.csv
```

Output directories must be new. `summary.csv` reports bias, empirical/model SEs,
coverage, binomial MCSE, Wilson coverage intervals, warnings and failure rates
separately for raw and marginal effects. `paired.csv` includes the MCSE of the
paired change in bias and coverage; failed analyses count as no interval for
coverage comparisons. Bias comparisons state the number of successful pairs.
`denominators.csv` summarizes the standardization SD separately. The three
probes within each dataset are dependent and are not independent repetitions.

More PMM imputations do not guarantee compatibility. A preliminary
30-dataset continuous n=500 comparison also examined m=20, but it is exploratory
and is not combined with the prespecified m=5 comparison.

After preliminary m=5 results suggested residual interval undercoverage despite
smaller bias, an additional **sensitivity** arm was added: SMC-FCS with m=20,
keeping the same 20 iterations, 200 dataset seeds and inference method. This
addition was not part of the original three-arm plan. Run it with a fourth
argument, for example `run.R new-7-m20 7 200 smcfcs20`, and include its CSV in
the summary command. Both m=5 and m=20 are reported; no result-dependent seeds
or repetitions are selected. More imputations do not by themselves ensure
model compatibility or nominal finite-sample coverage.

See `RESULTS.md` for findings, limitations and the recorded software environment.
Improvements in this grid do not establish performance for serial models,
missing moderators, both outcome conditions missing, or general MAR/MNAR data.
