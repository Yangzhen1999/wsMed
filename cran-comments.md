## Development validation (not a CRAN resubmission record)

Package version: 1.1.0.9000; branch: feature/modular-api.
This file records development checks. It must be refreshed against the final
source archive before submitting a release to CRAN.

## Test environments

* Local Windows, R 4.4.3: package tests, executable tutorials and manuscript examples.
* GitHub Actions: Windows and macOS R-release; Linux R-release, R-devel,
  R-oldrel-1, and a dependencies-only check.
* Manuscript replication: Windows/Linux/macOS with both R 4.4.3 reference
  dependencies and current R-release/CRAN dependencies.

## Verified prior checkpoint

Commit 670ace191570316830c2da0db6482c44375437f7 passed all 22 remote jobs:
https://github.com/Yangzhen1999/wsMed/actions/runs/36412576529
https://github.com/Yangzhen1999/wsMed/actions/runs/36412576455
https://github.com/Yangzhen1999/wsMed/actions/runs/36412576476

The local complete test suite at that checkpoint passed 1647 expectations,
with no failures or warnings. These are checkpoint results, not a claim that
the eventual release archive or a later commit has been checked.

## Local development validation: 2026-09-28

* Complete suite: 1699 passing expectations; zero failures, warnings or skips.
* All 14 executable tutorial sources rebuilt successfully in an isolated output
  directory; the source archive used those regenerated tutorials.
* Ten replication-comparison tests passed. The full manuscript analysis matched
  all 820 rows in the frozen reference-core candidate baseline.
* Source-archive R CMD check --as-cran --no-manual: 0 ERRORs, 0 WARNINGs,
  2 NOTEs. Incoming feasibility reported the development version and unavailable
  HTTPS/ORCID checks (local Schannel credentials); current time could not be
  verified. The PDF manual was not checked. These are not zero-NOTE release results.
* The recorded 1600-dataset simulation had no analysis failures but identified
  undercoverage in some default-MI moderated scenarios (minimum observed 89.5%
  for nominal 95% intervals). See .github/validation/RESULTS.md; successful
  execution and platform agreement do not certify inferential coverage.
* External completed-data input is now validated in both public workflows.
  Identical internal/external completions give identical pooled estimates and
  MC draws. The model-compatible MI tutorial and four SMC-FCS pipeline checks
  passed; the paired follow-up report records its separate statistical results.

## Changes since CRAN 1.1.0

* Add staged model, fit, inference, extraction and plotting methods while
  retaining the one-call wsMed() interface.
* Correct endogenous-product covariance modeling and MI marginal standardization;
  stabilize fixed-seed MC draws across numerical libraries.
* Add the documented empirical dataset, categorical-variable guidance,
  diagnostics, analysis manifests, and migration tutorials.

## Before release submission

Set the final release version, rebuild tutorials, build and check the exact
source archive (including the PDF manual), and record its checksum and actual
ERROR/WARNING/NOTE counts here. Run fresh win-builder checks on that archive.
Do not carry forward the old 1.1.0 win-builder results or claim zero NOTEs
without reading the final logs. Development-version and local network/time
NOTEs from earlier checks must be reassessed for the release environment.
