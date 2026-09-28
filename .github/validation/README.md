# Standardized moderated-mediation simulation

This study evaluates the implemented procedure, including its default MI
imputation model. It does not establish validity for all mediation models or
missingness mechanisms. Planning and reporting follow the ADEMP structure in
[Morris, White and Crowther (2019)](https://doi.org/10.1002/sim.8086).

## Aim and estimand

Evaluate bias, empirical SD versus reported SE, nominal 95% percentile interval
coverage, and excluded MC draws for the conditional indirect effect divided by
the population **marginal** SD of the outcome difference. Probes are fixed at
W = -1, 0, 1 (low/mid/high for the categorical moderator). This evaluates the
one-mediator case with an a-path main moderator effect and a moderated b path.

## Data-generating mechanism

W is standard normal or discrete uniform on {-1,0,1}. Independently,
A, eM, eY and Y1 are standard normal. Generate

```
M = 0.4 + 0.3 W + eM
Y = 0.2 + 0.1 W + (0.4 + 0.2 W) M + 0.2 A + eY
M1 = A - M/2; M2 = A + M/2; Y2 = Y1 + Y
```

The raw indirect effect is `(0.4+0.3w)(0.4+0.2w)`.
Writing a=.4, aw=.3, b=.4, bw=.2, cpw=.1 and d=.2, its denominator is the
square root of

```
Var(Y) = (cpw+b*aw+bw*a)^2 E(W^2)
       + (bw*aw)^2 {E(W^4)-E(W^2)^2}
       + b^2 + bw^2 E(W^2) + d^2 + 1.
```

E(W^2), E(W^4) are (1,3) or (2/3,2/3). Targets are analytical population
quantities, not estimates from the simulated samples. A separate large generated
sample checks the variance calculation. Each category is sampled independently;
group counts are not artificially held fixed.

## Scenarios and methods

Eight scenarios cross moderator type, n=150/500, and missingness 0/20%.
Missingness is independent MCAR in M1 and Y2, each with probability .20;
approximately 36% of rows then have at least one missing value. W is observed.
Complete data use ML; incomplete data use default PMM with five completed
datasets. The corrected product moment model is used throughout. Marginal
variances are pooled jointly in MI; their draws vary with the coefficient draws.
Inference uses 2000 MC draws per dataset and 200 repetitions per scenario.

Default imputation is not guaranteed to preserve the interaction and conditional
heteroskedasticity in this mechanism. Results assess the end-to-end default
workflow, not just the standardization formula. Poor MI performance must be
reported rather than removed or attributed solely to MC error. At 95% coverage,
200 repetitions yield a Monte Carlo SE of about 1.5 percentage points. This is
a finite screening study, not a precise coverage certification. Larger runs,
alternative imputation strategies, serial models, and MAR/MNAR missingness are
separate extensions.

## Reproduce and inspect

From a checkout with its package installed:

```
Rscript .github/validation/check-simulation.R
Rscript .github/validation/standardization-simulation.R new-output 200 2000
Rscript .github/validation/summarize-simulation.R .github/validation/standardization-replicates.csv new-summary.csv
```

An optional fourth argument selects scenario IDs, such as `1,5`. Seeds depend
on scenario and repetition, so splitting work does not change the draws.
Existing output directories are rejected. `replicates.csv` contains every attempt,
seed, warning, failure and exclusion rate. `summary.csv` reports coverage among
successful analyses and over all attempts (failed analyses count as no interval),
plus bias MCSE, binomial coverage MCSE and Wilson coverage intervals. The last
command recomputes the recorded summaries without repeating the simulations.
Summaries are checkpointed every ten
repetitions; `sessionInfo.txt` records the environment.

The lightweight CI check verifies targets and runs all eight pipelines; it does
not assert a coverage threshold from one repetition. Full simulation is outside
routine CRAN checks. See `RESULTS.md` for the recorded study.
