# GenerateModelPC

## Introduction

The `GenerateModelPC` function dynamically generates a Structural
Equation Model (SEM) formula to analyze models with multiple parallel
mediators influencing a single chained mediator for ‘lavaan’ based on
the prepared dataset. This document explains the mathematical principles
and the structure of the generated model.

![parallel-serial within-subject mediation model](Wd.png)

\`

------------------------------------------------------------------------

## 1. Model Description

### 1.1 Regression for $Y_{\text{diff}}$ and $M_{\text{diff}}$

For a single chained mediator $M_{1}$ and $N$ parallel mediators
$M_{2},M_{3},\ldots,M_{N + 1}$, the model is defined as:

1.  **Outcome Difference Model ($Y_{\text{diff}}$):**
    $$Y_{\text{diff}} = cp + b_{1}M_{1\text{diff}} + \sum\limits_{i = 2}^{N + 1}\left( b_{i}M_{i\text{diff}} + d_{i}M_{i\text{avg}} \right) + d_{1}M_{1\text{avg}} + e$$

2.  **Mediator Difference Model ($M_{i\text{diff}}$):**

    - For the chained mediator ($M_{1}$):
      $$M_{1\text{diff}} = a_{1} + \sum\limits_{i = 2}^{N + 1}\left( b_{i1}M_{i\text{diff}} + d_{i1}M_{i\text{avg}} \right) + \epsilon_{1}$$
    - For the parallel mediators ($M_{2},\ldots,M_{N + 1}$):
      $$M_{i\text{diff}} = a_{i} + \epsilon_{i}$$

Where: - $cp$: Direct effect of the independent variable. -
$b_{1},b_{i},b_{i1}$: Effects of the chained and parallel mediators. -
$d_{1},d_{i},d_{i1}$: Moderating effects of mediator averages. -
$\epsilon_{i}$: Residuals.

------------------------------------------------------------------------

## 2. Indirect Effects

For each mediator, the indirect effects are calculated as:

1.  **Single-Mediator Effects:**
    - For the chained mediator:
      $$\text{indirect}_{1} = a_{1} \cdot b_{1}$$
    - For the parallel mediators ($M_{2},\ldots,M_{N + 1}$):
      $$\text{indirect}_{i} = a_{i} \cdot b_{i}$$
2.  **Parallel to Chained Path Effects:**
    - For paths from the parallel mediators to the chained mediator:
      $$\text{indirect}_{i1} = a_{i} \cdot b_{i1} \cdot b_{1}$$
3.  **Total Indirect Effect:** The total indirect effect is the sum of
    all individual indirect effects:
    $$\text{total\_indirect} = \sum\limits_{i = 1}^{N + 1}\text{indirect}_{i} + \sum\limits_{i = 2}^{N + 1}\text{indirect}_{i1}$$

------------------------------------------------------------------------

## 3. Total Effect

The total effect combines the direct effect and the total indirect
effect: $$\text{total\_effect} = cp + \text{total\_indirect}$$

Where $cp$ is the direct effect.

------------------------------------------------------------------------

## 4. Comparison of Indirect Effects

When comparing the strengths of indirect effects, the contrast between
two effects is calculated as:
$$CI_{\text{path}_{1}\text{vs}\text{path}_{2}} = \text{indirect}_{\text{path}_{1}} - \text{indirect}_{\text{path}_{2}}$$

### 4.1 Example: Three Mediators ($M_{1},M_{2},M_{3}$)

1.  **Indirect Effects:**

    $$\text{indirect}_{1} = a_{1} \cdot b_{1}$$

    $$\text{indirect}_{2} = a_{2} \cdot b_{2}$$

    $$\text{indirect}_{3} = a_{3} \cdot b_{3}$$

    $$\text{indirect}_{21} = a_{2} \cdot b_{21} \cdot b_{1}$$

    $$\text{indirect}_{31} = a_{3} \cdot b_{31} \cdot b_{1}$$

2.  **Comparisons:**

    $$CI_{1\text{vs}2} = \text{indirect}_{1} - \text{indirect}_{2}$$

    $$CI_{1\text{vs}3} = \text{indirect}_{1} - \text{indirect}_{3}$$

    $$CI_{1\text{vs}21} = \text{indirect}_{1} - \text{indirect}_{21}$$

    $$CI_{1\text{vs}31} = \text{indirect}_{1} - \text{indirect}_{31}$$

    $$CI_{2\text{vs}3} = \text{indirect}_{2} - \text{indirect}_{3}$$

    $$CI_{2\text{vs}21} = \text{indirect}_{2} - \text{indirect}_{21}$$

    $$CI_{3\text{vs}31} = \text{indirect}_{3} - \text{indirect}_{31}$$

    $$CI_{21\text{vs}31} = \text{indirect}_{21} - \text{indirect}_{31}$$

------------------------------------------------------------------------

## 5. C1- and C2-Measurement Coefficients

### Definitions

1.  **C2-Measurement Coefficient ($X1_{b,i}$):**
    $$X1_{b,i} = b_{i} + d_{i}$$

2.  **C1-Measurement Coefficient ($X0_{b,i}$):**
    $$X0_{b,i} = X1_{b,i} - d_{i}$$

### 5.1 Example: Three Mediators ($M_{1},M_{2},M_{3}$)

1.  **Mediator $M_{1}$:**

    $$X1_{b,1} = b_{1} + d_{1}$$

    $$X0_{b,1} = X1_{b,1} - d_{1}$$

2.  **Mediator $M_{2}$:**

    $$X1_{b,2} = b_{2} + d_{2}$$

    $$X0_{b,2} = X1_{b,2} - d_{2}$$

3.  **Mediator $M_{3}$:**

    $$X1_{b,3} = b_{3} + d_{3}$$

    $$X0_{b,3} = X1_{b,3} - d_{3}$$

4.  **Parallel to Chained Path
    ($\left. M_{2}\rightarrow M_{1} \right.$):**

    $$X1_{b,21} = b_{21} + d_{21}$$

    $$X0_{b,21} = X1_{b,21} - d_{21}$$

5.  **Parallel to Chained Path
    ($\left. M_{3}\rightarrow M_{1} \right.$):**

    $$X1_{b,31} = b_{31} + d_{31}$$

    $$X0_{b,31} = X1_{b,31} - d_{31}$$

------------------------------------------------------------------------

## 6. Summary of Regression Equations

This section summarizes all equations used in the model:

$$Y_{\text{diff}} = cp + b_{1}M_{1\text{diff}} + \sum\limits_{i = 2}^{N + 1}\left( b_{i}M_{i\text{diff}} + d_{i}M_{i\text{avg}} \right) + d_{1}M_{1\text{avg}} + e$$

$$M_{1\text{diff}} = a_{1} + \sum\limits_{i = 2}^{N + 1}\left( b_{i1}M_{i\text{diff}} + d_{i1}M_{i\text{avg}} \right) + \epsilon_{1}$$

$$M_{i\text{diff}} = a_{i} + \epsilon_{i}$$

$$\text{indirect}_{1} = a_{1} \cdot b_{1}$$

$$\text{indirect}_{i} = a_{i} \cdot b_{i}$$

$$\text{indirect}_{i1} = a_{i} \cdot b_{i1} \cdot b_{1}$$

$$CI_{\text{path}_{1}\text{vs}\text{path}_{2}} = \text{indirect}_{\text{path}_{1}} - \text{indirect}_{\text{path}_{2}}$$

$$X1_{b,i} = b_{i} + d_{i}$$

$$X0_{b,i} = X1_{b,i} - d_{i}$$

------------------------------------------------------------------------

This comprehensive approach supports models with parallel mediators
influencing a chained mediator, enabling detailed analysis of their
effects and interactions.
