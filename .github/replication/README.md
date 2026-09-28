# Manuscript replication audit

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

`compare.py` checks all 812 table rows between environments, compares to the
local candidate reference, and maps 86 manuscript rows using the historical
verification manifest. It fails on missing runs or within-profile numeric/
label differences. Whitespace and signed-zero display differences are
reported separately. Between-profile and original-paper differences are
reported without automatically declaring the changed numerical method wrong.

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
