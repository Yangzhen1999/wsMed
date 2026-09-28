# wsMed 1.1.0.9000

- Keep the selected inference level in every confint method unless explicitly
  overridden. Explain the percentile effect-query convention separately from
  stored bootstrap parameter-table intervals; correct bca.simple labeling to
  bias correction with zero acceleration.
- Record per-dataset fit diagnostics, category counts, and separate inference
  versus standardization exclusions. Report contrast direction, raw moderator
  coordinates, reference coding, and the plug-in marginal outcome-difference SD.
  Name constant transformed variables in pre-fit errors and stop MI pooling for
  non-converged fits; reject known inadmissible fits before inference.
- Add wsmed_reproducibility() to return or save an analysis manifest without
  participant-level data or draw matrices. Add a migration/diagnostics tutorial
  and optional observed-moderator rug marks for continuous curves.
- Document a model-level limitation identified by the new reference-coding
  checks: the current product-term SEM can imply different marginal SDs after
  changing the reference category. Raw conditional effects agree in the checked
  example; reference-invariance of standardized effects is not guaranteed.

- Plot methods now select continuous curves, categorical points, or forests
  according to the extracted effects. They support titles, axis labels, effect
  selection and ordering, facets, and confidence-level changes from stored draws.
  Automatic curves report their fitted-case range; MI uses the first imputation.
  Fits without inference show point estimates only. Unknown plot arguments error.
- Share plot-table columns and forest/category rendering with the legacy helpers,
  retaining legacy bootstrap interval limits. Plot subtitles distinguish these
  from the new effect-query percentile convention. No plotting step fits or samples.
- Print effect summaries with `printCoefmat()` and identify the source of standard
  errors, confidence level, interval method, and excluded standardized draws.
  Stored numerical tables retain full precision; full legacy printing is unchanged.

- Include `wsmed_examples`, the 123-participant prepared manuscript dataset,
  with source attribution, its CC BY 4.0 license, variable roles, preprocessing,
  and missing-value documentation. Its values match the replication SAV file.
- Document categorical predictor support, reference coding, and missing-data
  restrictions; add an executable tutorial with group effects and contrasts.
- Use sentence-case help titles and descriptive tutorial titles. Translate code
  comments into English and correct the simulated dataset's 14-column description.

- Add a staged workflow through `wsmed_model()`, `wsmed_fit()`, and
  `wsmed_infer()`. `wsMed()` remains the one-call entry point and now uses the
  same engines, retaining the existing result fields alongside structured
  `model`, `fit`, and `inference` components. MI fits retain all imputation fits
  and pooled parameter covariance; inference can reuse them without reimputation.
- Add `wsmed_effects()`, `wsmed_contrasts()`, and standard object methods.
  Effect queries, raw-unit moderator probes, standardization, confidence-level
  changes, and plotting reuse stored joint draws. Result tables retain full
  precision and draw identities. Effect and contrast intervals are percentile
  intervals, independently of legacy bootstrap parameter-table settings.
- Default printing is now concise. Use `print(result, detail = "full")` for
  the existing complete tables. New saved objects retain their structured fits;
  old saved objects can still use full printing and the existing plotting helpers.
- New specifications require named condition pairs and explicit factors for
  categorical predictors. Seeded workflow calls preserve the caller's random
  state; unseeded calls advance it. The existing MI centering/probing convention
  and the restriction against MI-bootstrap are unchanged.
- Correct the internal NULL-default helper so supplied values are retained.
- Reject `MCmethod = "bootSD"` explicitly: earlier versions validated this
  option but did not apply an SD correction. No new correction is introduced.
- For MI, generate model syntax from completed data after raw-variable
  imputation. This avoids constructing multi-level dummy interactions with
  missing categories before imputation. Per-dataset centering and factor coding
  are retained in the fit metadata.
- Multi-level categorical coding now retains missing rows until the chosen
  missing-data method acts, and uses explicit treatment contrasts rather than
  depending on global R contrast options. The first factor level is the reference.

- Stabilize the MI Monte Carlo eigen sampler using the principal symmetric
  covariance square root. Equivalent eigenvector signs and repeated-eigenvalue
  bases no longer change draws beyond numerical precision. The target normal
  distribution and pooled point estimates are unchanged, but fixed-seed draws,
  Monte Carlo standard errors, and interval endpoints differ from wsMed 1.1.0.
  This change does not alter the non-MI sampler delegated to semmcci, and does
  not guarantee identical results across different fitted inputs or dependencies.

# wsMed 1.1.0

## New features

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

## Fixes and improvements

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

# wsMed 1.0.2 (2025-12-06)
# wsMed 1.0.1 (2025-09-25)
# wsMed 1.0.0 (2025-09-19)
# wsMed 0.5.2 (2025-09-18)
# wsMed 0.5.1 (2025-07-11)

## New Features
- Added NEWS.md for tracking package changes.
- Improved print function for Monte Carlo and standardized results.
- Added regression information in print function.
- Replaced `standardizedSolution_boot_ci()` with `semboottools::standardizedSolution_boot()`
- Added bootstrap p-values and support for CI type selection
- Improved `print.wsMed()` output with detailed notes
- Added: `MCStd2()` function for fully standardized Monte Carlo inference
- Improved: Print method now supports `delta = TRUE` to show original SE and CI

## Enhancements
- Improved documentation and package description.
- Updated `print.wsMed()` function for better output format.
- Refined MC-based standardized results computation.

## Bug Fixes
- Fixed issues related to package installation and CRAN submission.
- Ensured better compatibility with `pkgdown`.

## Other Changes
- Merged pull request for `pkgdown` testing.
- Added GitHub links in `DESCRIPTION`.
- Incremented version number to `0.1.0`.


