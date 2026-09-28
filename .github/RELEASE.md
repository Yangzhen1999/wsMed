# Release preparation

The current development line is `feature/modular-api`, version 1.1.0.9000.
Do not reuse an archive built before the covariance/MI sampler correction.

1. Review NEWS and choose the final release version. Update DESCRIPTION, NEWS,
   installation instructions and explicit replication version checks together.
   Algorithm identifiers are independent of package version; change them when
   an incompatible model or inference algorithm changes.
2. Run `source("rebuild_vignettes.R"); rebuild_vignettes()` on the release checkout.
   Edit only `.Rmd.original` sources (temporarily `.Rmd` while editing/testing).
   Commit the appropriate generated release outputs after rebuilding.
3. Run tests and replication. The frozen candidate baseline must pass; do not
   overwrite it to hide an unexplained difference. Synchronize manuscript tables
   and figures with the reviewed candidate and verify their displayed values.
   The candidate baseline does not mean the old manuscript is already updated.
4. Build with `devtools::build()` and check that exact archive with
   `rcmdcheck::rcmdcheck(path_to_archive, args = "--as-cran")`, including the manual.
   Record actual ERROR/WARNING/NOTE counts and environments in `cran-comments.md`;
   rerun win-builder for this archive and record its checksum.
5. Check the package website on the pull request. Merge/publish when ready, then
   pin the matching package archive and dependency information in the manuscript
   replication materials.

Validation scripts do not release, submit to CRAN, deploy a site or edit the
manuscript. The study under `.github/validation` is outside CRAN's test runtime.
