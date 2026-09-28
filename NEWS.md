# Package News

## wsMed 1.1.0.9000

- Stabilize the MI Monte Carlo eigen sampler using the principal symmetric
  covariance square root. Equivalent eigenvector signs and repeated-eigenvalue
  bases no longer change draws beyond numerical precision. The target normal
  distribution and pooled point estimates are unchanged, but fixed-seed draws,
  Monte Carlo standard errors, and interval endpoints differ from wsMed 1.1.0.
  This change does not alter the non-MI sampler delegated to semmcci, and does
  not guarantee identical results across different fitted inputs or dependencies.

## wsMed 1.1.0

### New features

- Added user-defined mediation models through `form = "UD"`, `paths`, and
  `GenerateModelCustom()`, including sparse and reverse-order pathways.
- Added standardized conditional effects, contrasts, and curves for continuous
  and categorical moderators through `moderation_std` and
  `standardize_moderation()`. Probe values remain fixed in raw moderator units;
  standardization scales vary jointly with each Monte Carlo or bootstrap draw.
- Added forest plots (`plot_effects()`), categorical conditional-effect plots
  (`plot_conditional_effects()`), and contrast plots (`plot_contrasts()`).
- Added standardized curve selection and Monte Carlo/bootstrap selection in
  plotting, and improved moderation curve labels.

### Fixes and improvements

- Corrected interaction scaling in standardized Monte Carlo and bootstrap
  parameter tables while preserving dummy coding, difference-score intercepts,
  and scaled residual covariances. Invalid joint draws are counted and reported.
- Corrected conditional effects to use fitted plug-in estimates, all mediation
  paths, and fitted moderator main effects. Continuous probes are evaluated
  exactly; direct-path moderation and contrast signs are corrected.
- Multiple imputation now forwards `fixed.x` to every fit and evaluates nonlinear
  effects after pooling primitive coefficients. The Monte Carlo seed is forwarded.
- Improved printing for `ci_method = "both"` and clarified effect scales.
- Added case-insensitive values for `form`, `Na`, and `ci_method`, preserving
  existing defaults, unambiguous abbreviations, and validation rules.
- Updated tutorials, vignette rebuilding, and the pkgdown function index,
  including documentation for custom models, standardization, and plotting.
- Corrected the `ci_method` documentation to include `"both"` and the existing
  `"mc"` default, including when `NULL` is supplied.

## wsMed 1.0.2 (2025-12-06)
## wsMed 1.0.1 (2025-09-25)
## wsMed 1.0.0 (2025-09-19)
## wsMed 0.5.2 (2025-09-18)
## wsMed 0.5.1 (2025-07-11)

### New Features
- Added NEWS.md for tracking package changes.
- Improved print function for Monte Carlo and standardized results.
- Added regression information in print function.
- Replaced `standardizedSolution_boot_ci()` with `semboottools::standardizedSolution_boot()`
- Added bootstrap p-values and support for CI type selection
- Improved `print.wsMed()` output with detailed notes
- Added: `MCStd2()` function for fully standardized Monte Carlo inference
- Improved: Print method now supports `delta = TRUE` to show original SE and CI

### Enhancements
- Improved documentation and package description.
- Updated `print.wsMed()` function for better output format.
- Refined MC-based standardized results computation.

### Bug Fixes
- Fixed issues related to package installation and CRAN submission.
- Ensured better compatibility with `pkgdown`.

### Other Changes
- Merged pull request for `pkgdown` testing.
- Added GitHub links in `DESCRIPTION`.
- Incremented version number to `0.1.0`.


