# Package index

## Main functions

Core functions for within-subject mediation analysis

- [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md) :
  Analyze two-condition within-subject mediation

## Staged workflow

Specify, fit, infer, and extract without repeating earlier stages

- [`wsmed_model()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_model.md)
  : Specify a two-condition mediation model
- [`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md)
  : Fit a specified mediation model without simulation
- [`wsmed_infer()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_infer.md)
  : Apply uncertainty quantification to an existing fit
- [`wsmed_inspect()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_inspect.md)
  : Inspect a modular workflow without recomputation
- [`wsmed_reproducibility()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_reproducibility.md)
  : Export the settings and provenance of an analysis

## Reports, summaries, and effect comparisons

Use [print() and
summary()](https://yangzhen1999.github.io/wsMed/reference/wsmed_methods.md)
to read reports and extract structured tables, and
[plot()](https://yangzhen1999.github.io/wsMed/reference/wsmed_plots.md)
to visualize results. The functions below support focused effect queries
and comparisons.

- [`wsmed_effects()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_effects.md)
  : Extract effects from fitted models or stored inference
- [`wsmed_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_contrasts.md)
  : Contrast effects using their joint stored draws

## Model generation

Functions for generating SEM syntax for different mediation structures

- [`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md)
  : Print formatted SEM model syntax
- [`GenerateModelP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelP.md)
  : Generate a parallel mediation model
- [`GenerateModelCN()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCN.md)
  : Generate a serial mediation model
- [`GenerateModelCP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCP.md)
  : Generate a serial-parallel mediation model
- [`GenerateModelPC()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelPC.md)
  : Generate a parallel-serial mediation model
- [`GenerateModelCustom()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCustom.md)
  : Generate a user-defined mediation model

## Missing data and imputation

Functions to handle missing data with multiple imputation

- [`ImputeData()`](https://yangzhen1999.github.io/wsMed/reference/ImputeData.md)
  : Impute missing data using multiple imputation
- [`PrepareMissingData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md)
  : Prepare data with missing values for mediation analysis
- [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md) :
  Monte Carlo confidence intervals for multiple imputation SEM models
- [`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  : Prepare data for two-condition mediation

## Standardization and conditional effects

Standardize conditional results and visualize effect curves

- [`standardize_moderation()`](https://yangzhen1999.github.io/wsMed/reference/standardize_moderation.md)
  : Standardize conditional mediation results using existing joint draws
- [`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
  : Plot conditional effects across a continuous moderator
- [`plot_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_effects.md)
  : Forest plot of mediation effects
- [`plot_conditional_effects()`](https://yangzhen1999.github.io/wsMed/reference/plot_conditional_effects.md)
  : Plot conditional effects at moderator levels
- [`plot_contrasts()`](https://yangzhen1999.github.io/wsMed/reference/plot_contrasts.md)
  : Plot differences between mediation effects

## Data and variable types

Packaged datasets and supported categorical predictors

- [`wsmed_examples`](https://yangzhen1999.github.io/wsMed/reference/wsmed_examples.md)
  : Data for the manuscript examples
- [`example_data`](https://yangzhen1999.github.io/wsMed/reference/example_data.md)
  : Simulated data for mediation tutorials
- [`wsmed_categorical`](https://yangzhen1999.github.io/wsMed/reference/wsmed_categorical.md)
  : Categorical predictors and supported variable types
