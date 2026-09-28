# Manuscript replication audit

The workflow runs on relevant main/master pushes and pull requests as well as
the development branches. It validates the actual package being checked out.

Runs the four fitted models in manuscript Examples 1-3, including the PC and
UD versions of Example 2, and generates the three Example 3 plots. The current
branch's wsMed is installed; this is a candidate revision, not the released
wsMed 1.1.0 output. No paper values are silently replaced.

Two profiles are compared on Windows, Linux, and macOS:

- `reference-core`: R 4.4.3 and the ten versions recorded in `run.R`, including
  historical xfun 0.51 for compatibility with knitr 1.49.
  Other transitive dependencies are resolved separately and recorded. This
  is not a byte-for-byte recreation of the full historical environment.
- `current-cran`: current R-release and currently available CRAN dependencies.

Only required analysis dependencies are installed. Suggested documentation/
development tools are not needed to source the examples; current rmarkdown
requires a newer knitr than the historical reference version.

The analysis settings and calls are retained from the local candidate script.
Warnings and invalid standardized draws are recorded, not suppressed. Each
run exports numerical imputation values, pooled means/covariances, the first
64 joint MC draws, full conditional/standardized tables, and printed results.
Cross-platform comparisons distinguish upstream fitting differences from
downstream Monte Carlo differences. Figures are rendered, but their bitmap
or PDF bytes are not used as a cross-platform numerical equality criterion.

`compare.py` checks every current table row between environments and maps 86
manuscript rows using the historical verification manifest. Rows are matched
by model, table header/scale occurrence, and parameter or probe labels, not
absolute line numbers. The original 812-row submission and local candidate
remain unchanged; the covariance correction adds auxiliary parameters (820
current rows). Added, removed, and changed rows are reported separately.

Each run also prints the tables to ten decimal places for numerical comparison.
Within-profile differences fail if they exceed
`max(1e-5, 1e-5 * max(abs(left), abs(right)))` (Python `math.isclose`).
This allows small optimizer differences across platforms without treating a
three-decimal rounding boundary as a statistical discrepancy. All differences
in the ordinary three-decimal output are still reported. Missing environments,
missing precise output, missing manuscript rows, ambiguous row identities, and
within-profile label/structure differences fail. Between-profile and original-
paper differences are reported without automatically declaring the changed
numerical method wrong. Comparison tests inject missing rows, genuine numerical
changes, and display-only differences to verify these checks.

## Frozen candidate baseline

`candidate-baseline.json` freezes both profiles from the fully passing commit
`670ace191570316830c2da0db6482c44375437f7`, including source run, environment and
snapshot hashes. Every current ten-decimal table is compared with this baseline
using the same numerical tolerance. A change shared by all platforms therefore
still fails. Baseline mismatches and historical manuscript differences have
separate CSV reports; the original submission fixtures are never overwritten.

This is a reviewed **package candidate** baseline, not a claim that the manuscript
already contains those values. Once the manuscript is updated, verify its exact
displayed values against this candidate. Update the baseline only after explicit
review of numerical changes, with a new source commit/run and explanation;
normal checks never regenerate it. Tests inject a shared regression across all
six environments and require this independent comparison to fail.

## Data attribution

`wsMed_examples.sav` is the prepared 123-participant, 14-variable analysis
dataset already used in the supplied manuscript replication materials.
Source: Roberto Sagaribay (2025), *iWeek: A Week-Long Social Media Abstinence
Intervention and its Impact on Well-Being, Mental Health, Body Image, and
Sleep in Latina College Students*, Mendeley Data, version 1,
https://doi.org/10.17632/fn9n95bsh5.1 . Licensed under CC BY 4.0:
https://creativecommons.org/licenses/by/4.0/ . BMI was recalculated; 13
ambiguous BMI observations remain missing. This is a derived analysis dataset,
not the unchanged repository download. MD5: ce2bcbd3fde83a793e94b226892f7453.

The two unmodified development dependency source archives retain their own
licenses and author information:

- semmcci 1.1.4.9000: jeksterslab/semmcci commit
  44470036aa9ff3a0bd553fa2e2fc4eef44d182e5.
- semboottools 0.0.0.9011: Yangzhen1999/semboottools commit
  b41c315b98f90c0e3cc0756940d9e582573482a3.

The scripts are distributed under the package's GPL (>= 3) license. All these
audit fixtures live under `.github` and are excluded from the R package build.
