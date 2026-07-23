# Package index

## Main Functions

Core functions for within-subject mediation analysis

- [`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md) :
  Within-Subject Mediation Analysis (Two-Condition)
- [`print(`*`<wsMed>`*`)`](https://yangzhen1999.github.io/wsMed/reference/print.wsMed.md)
  : Print Method for wsMed Objects
- [`printGM()`](https://yangzhen1999.github.io/wsMed/reference/printGM.md)
  : Print Formatted SEM Model Syntax

## Model Generation

Functions for generating SEM syntax for different mediation structures

- [`GenerateModelP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelP.md)
  : Generate Parallel Mediation Model
- [`GenerateModelCN()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCN.md)
  : Generate Chained Mediation Model
- [`GenerateModelCP()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCP.md)
  : Generate Combined Parallel and Chained Mediation Model
- [`GenerateModelPC()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelPC.md)
  : Generate Parallel and Chained Mediation Model
- [`GenerateModelCustom()`](https://yangzhen1999.github.io/wsMed/reference/GenerateModelCustom.md)
  : Generate a User-Defined Within-Subject Mediation Model

## Missing Data and Imputation

Functions to handle missing data with multiple imputation

- [`ImputeData()`](https://yangzhen1999.github.io/wsMed/reference/ImputeData.md)
  : Impute Missing Data Using Multiple Imputation
- [`PrepareMissingData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareMissingData.md)
  : Prepare Data with Missing Values for Mediation Analysis
- [`MCMI2()`](https://yangzhen1999.github.io/wsMed/reference/MCMI2.md) :
  Monte Carlo Confidence Intervals for Multiple Imputation SEM Models
- [`PrepareData()`](https://yangzhen1999.github.io/wsMed/reference/PrepareData.md)
  : Prepare Data for Two-Condition Within-Subject Mediation (WsMed)

## Plotting Conditional Indirect Effects

Functions for visualizing conditional indirect effect curves

- [`plot_moderation_curve()`](https://yangzhen1999.github.io/wsMed/reference/plot_moderation_curve.md)
  : Plot moderation curves with Johnson-Neyman highlights
