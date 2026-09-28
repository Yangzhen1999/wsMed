# Paired MI follow-up: 2026-09-28

Changing the imputation model substantially reduced the conditional indirect
effect bias in these scenarios while leaving the pooling and standardization
engine unchanged. **The study does not establish that interval undercoverage is
fully resolved.** More imputations did not uniformly improve coverage, and some
SMC-FCS runs issued rejection-sampling warnings.

## Design and complete accounting

Four scenarios crossed continuous/categorical W with n=150/500. Each had 200
underlying datasets with independent 20% MCAR deletion in M1 and Y2. Every dataset
was analyzed using default PMM (m=5), SMC-FCS (m=5), its underlying complete data,
and an added sensitivity arm SMC-FCS (m=20). All used 2000 MC draws. Thus there
were **800 independent datasets, 3200 analyses and 9600 correlated effect rows**,
not 9600 independent simulations. All planned attempts are retained; no fitting
or inference errors terminated an analysis. Warnings are accounted for below.

The m=20 arm was added after preliminary m=5 results, rather than being part of
the original three-arm design. It uses the same 200 seeds. Formula/configuration
development, frozen source snapshots and execution details are recorded in the
README and manifest. Every PMM conditional-effect row (2400 rows) reproduces the
original screening study to 1e-12. This rules out a changed downstream calculation
as an explanation of the imputation comparison.

## Bias at W=1 (high category)

Bias is in outcome-difference marginal SD units. Raw-effect results and every
probe are available in `summary.csv`.

| Moderator | n | PMM, m=5 | SMC-FCS, m=5 | SMC-FCS, m=20 | Complete data |
|---|---:|---:|---:|---:|---:|
| Continuous | 150 | -0.0349 | 0.0024 | 0.0011 | 0.0004 |
| Categorical | 150 | -0.0424 | -0.0034 | -0.0027 | -0.0004 |
| Continuous | 500 | -0.0340 | 0.0012 | 0.0015 | 0.0024 |
| Categorical | 500 | -0.0365 | -0.0002 | 0.0016 | 0.0032 |

The bias reduction is also present before standardization. The original PMM
marginal-SD bias was comparatively small (approximately -0.0091 to 0.0004).
Changing the imputer therefore addresses an important source of bias; this is
not evidence that changing a standardization denominator alone would fix it.
The comparison changes the imputation procedure as a whole and does not uniquely
identify the separate contribution of every omitted conditional-model feature.

## Nominal 95% interval coverage at W=1

| Moderator | n | PMM, m=5 | SMC-FCS, m=5 | SMC-FCS, m=20 | Complete data |
|---|---:|---:|---:|---:|---:|
| Continuous | 150 | 90.5% | 95.0% | 95.5% | 95.5% |
| Categorical | 150 | 94.0% | 94.0% | 92.5% | 95.5% |
| Continuous | 500 | 89.5% | 91.5% | 92.5% | 92.5% |
| Categorical | 500 | 93.5% | 93.0% | 93.5% | 95.0% |

With 200 repetitions, MCSE near 95% coverage is about 1.5 percentage points;
at 92.5% it is about 1.9 points. The 3-point increase from 89.5% to 92.5% has
paired MCSE about 2.0 points. The observed increase alone is insufficient for a
strong claim that nominal coverage has been restored. Conversely, a point estimate
of 92.5% is not by itself proof of a software defect; its Wilson interval includes
95%. In the categorical n=150 scenario, m=20 coverage was lower than m=5.

Across all probes, marginal-effect coverage ranges were 89.5%–99.0% (PMM),
91.5%–99.5% (SMC-FCS m=5), 92.5%–99.5% (SMC-FCS m=20), and 91.5%–99.0%
(the paired complete-data arm). The probes are dependent. `paired.csv` reports
paired changes with their simulation errors; `summary.csv` contains Wilson
intervals, empirical SDs, RMS model SEs, bias MCSE and all-attempt denominators.

## Numerical imputation diagnostics

The absence of a terminal analysis error is not absence of numerical warnings.
SMC-FCS reported at least one rejection-sampling failure in **47/800** m=5
analyses and **136/800** m=20 analyses. The rejection limit was 5000, with 20
iterations per imputation. These runs remain in the summaries; excluding them
after seeing outcomes would change the experiment. Consequently, the reported
SMC-FCS results evaluate this finite computational configuration, not an exact
or fully certified compatible-imputation sampler.

Invalid standardized MC draws were reported in 8/800 PMM analyses, 8/800
SMC-FCS m=5 analyses and 1/800 SMC-FCS m=20 analyses. The maximum excluded draw
fractions were 2.15%, 0.10% and 0.05%, respectively. The complete-data arm had
no such warnings. All warning strings are retained in `replicates.csv`.

The tutorial now stops on rejection-sampling failure warnings. Users must
resolve those warnings (for example, by increasing the rejection limit and
rerunning), inspect mixing and choose sufficient imputations before inference.
The external-completion interface cannot certify these properties from a list
of completed datasets. Eight first-dataset parameter traces are retained under
`traces/`; they do not establish convergence of every simulated analysis.

## What changed, and what remains

- Both public interfaces can consume externally generated completed data and
  enforce observed-cell, row and factor-coding integrity. Pooling and effect
  inference are unchanged and separately regression-tested.
- The worked SMC-FCS formula and explicit predictor matrix handle the stated
  one-mediator mechanism, including a continuous or categorical observed W.
- Bias is substantially reduced in this grid. Default main-effects imputation
  should not be treated as automatically compatible with moderated mediation.
- Universal nominal coverage, rejection-free sampling in every dataset, serial
  mediation, missing moderators, both outcomes missing, and general MAR/MNAR
  mechanisms are **not established** by this study. Further work should resolve
  numerical imputation warnings, increase independent repetitions and separately
  examine finite-sample interval calibration. No CI inflation rule or automatic
  imputation-model replacement was introduced based on these results.

Software validation: 1699 local test expectations passed; 14 tutorials rebuilt;
the original 820-row manuscript candidate baseline is unchanged. Local source
checking with --as-cran --no-manual had 0 errors, 0 warnings and 2 development/
environment notes. These software checks are distinct from statistical coverage.
