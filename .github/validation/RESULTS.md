# Standardization screening study: 2026-09-28

A [paired follow-up](mi-comparison/RESULTS.md) now compares the same incomplete
datasets with model-compatible external imputation and complete-data controls.
It substantially reduces bias, but coverage and numerical imputation warnings
remain explicit limitations. The original screening results below are retained.

The eight prespecified scenarios used 200 independent datasets each, five
imputations in incomplete-data scenarios, and 2000 MC draws per analysis.
All 1600 fits/inferences completed. Each dataset contributed three conditional
effects; these three estimates are correlated and are not 4800 independent
datasets. The source, seeds, every attempted estimate, warnings, summaries,
environment and checksums accompany this report.

| Moderator | n | Missing per affected variable | Coverage at W=-1 | W=0 | W=1 |
|---|---:|---:|---:|---:|---:|
| Continuous | 150 | 0% | 99.0% | 95.5% | 94.5% |
| Categorical | 150 | 0% | 97.0% | 96.0% | 93.5% |
| Continuous | 500 | 0% | 95.0% | 96.5% | 94.0% |
| Categorical | 500 | 0% | 96.5% | 95.5% | 97.0% |
| Continuous | 150 | 20% | 96.0% | 91.5% | 90.5% |
| Categorical | 150 | 20% | 99.0% | 97.5% | 94.0% |
| Continuous | 500 | 20% | 95.5% | 94.5% | 89.5% |
| Categorical | 500 | 20% | 95.5% | 98.0% | 93.5% |

Coverage is for nominal 95% intervals. The summary CSV includes binomial MCSE
and Wilson intervals for the estimated coverage (uncertainty across simulation
repetitions, not another effect CI). With 200 repetitions, MCSE near 95% is
approximately 1.5 percentage points; the lowest observed coverage has MCSE
about 2.2 percentage points. Interpretation is limited to this small scenario
grid, with no multiple-comparison claim across its 24 dependent summaries.

Complete-data standardized-effect bias ranged from about -0.0075 to 0.0057.
For incomplete data at W=1, bias was approximately -0.0349/-0.0340 (continuous,
n=150/500) and -0.0424/-0.0365 (categorical). These are substantive warning
signals for the default end-to-end MI procedure in this data-generating model;
they must not be described as successful validation of nominal coverage.

The default PMM imputation does not explicitly encode the generating interaction
or its heteroskedastic conditional residuals. This is a plausible contributor,
not a causal diagnosis established by this study. Isolating imputation-model
misspecification, pooling and variance estimation needs additional comparisons
with congenial imputation and/or known completed-data inputs. Do not silently
change the default estimator based on this one experiment.

Invalid standardized draws were rare: average fractions were 0.0001125 and
0.000025 for continuous/categorical n=150 MI, and zero in the other scenarios.
Thus merely checking that draws were accepted would not detect the coverage
problem. Any accompanying warnings are retained in the replicate CSV/manifest.

## Implications

- The corrected implementation preserves algebraic/reference-coding identities
  and reproduces the same fitted procedure across platforms.
- This screening study does **not** certify 95% coverage for default MI in
  moderated models. Document this limitation for users and in the manuscript.
- Before making stronger statistical claims, expand repetitions and compare
  imputation strategies that preserve the substantive interaction model. Serial
  mediation, other effect strengths, categorical missingness and MAR/MNAR are
  outside this experiment.

The CI smoke test checks the analytic target, execution and failure accounting;
it intentionally cannot turn these finite-sample findings into an artificial
pass/fail coverage certification.
