# Package News

## Development version

- `wsMed()` now accepts case-insensitive values for `form`, `Na`, and
  `ci_method`. Existing defaults, unambiguous abbreviations, and validation
  rules are preserved; returned settings retain their canonical spelling.
- Corrected the `ci_method` documentation to include `"both"` and the existing
  `"mc"` default, including when `NULL` is supplied.

## Unreleased: phase 1 standardization repairs

- Standardized MC and bootstrap parameter tables now share component-based
  interaction scaling and preserve 0/1 dummy coding, difference-score intercepts,
  and scaled residual covariances. Invalid joint draws are counted and reported.
- Conditional effects use fitted plug-in estimates, all mediation paths, and all
  fitted moderator main effects. Continuous probes are evaluated exactly;
  direct-path moderation and contrast signs are corrected.
- MI forwards `fixed.x` to every fit and evaluates nonlinear effects after pooling
  primitive coefficients. The MC seed is now forwarded.
- Extended these repairs to sparse and reverse-order user-defined models (`UD`),
  preserving the existing `paths` interface and case-insensitive choices.
- Printing handles `ci_method = "both"` and identifies conditional outputs as
  unstandardized. Standardized conditional curves remain outside this change.

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


