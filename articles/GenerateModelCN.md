# GenerateModelCN

## Introduction

The `GenerateModelCN` function dynamically generates a Structural
Equation Model (SEM) formula to analyze chained or nested mediation for
‘lavaan’ based on the prepared dataset. This document explains the
mathematical principles and the structure of the generated model.

![serial within-subject mediation model](Wb.png)

------------------------------------------------------------------------

## 1. Difference Model Description

### 1.1 Regression for $Y_{\text{diff}}$ and $M_{\text{diff}}$

For $N$ mediators $M_{1},M_{2},\ldots,M_{N}$, the difference model is
defined as:

1.  **Outcome Difference Model ($Y_{\text{diff}}$):**
    $$Y_{\text{diff}} = cp + \sum\limits_{i = 1}^{N}\left( b_{i}M_{\text{diff},i} + d_{i}M_{\text{avg},i} \right) + e$$

2.  **Mediator Difference Model ($M_{\text{diff},i}$):**
    $$M_{\text{diff},i} = a_{i} + \sum\limits_{j < i}\left( b_{ji}M_{\text{diff},j} + d_{ji}M_{\text{avg},j} \right) + \epsilon_{i}$$

Where: - $cp$: Intercept term for the outcome difference model. -
$b_{i}$: Average effect of mediator $M_{i}$ on $Y_{\text{diff}}$. -
$d_{i}$: Moderator effect for $M_{\text{avg},i}$ in $Y_{\text{diff}}$. -
$b_{ji}$ and $d_{ji}$: Regression coefficients for $M_{\text{diff},j}$
and $M_{\text{avg},j}$ on $M_{\text{diff},i}$, respectively. -
$\epsilon_{i}$: Residual for $M_{\text{diff},i}$.

------------------------------------------------------------------------

## 2. Indirect Effects

For each mediator $M_{i}$, the indirect effect is defined as:
$$\text{indirect}_{i} = a_{i} \cdot b_{i}$$

For chained mediators, the indirect effects follow the paths through the
mediators: 1. For a single mediator $M_{i}$:
$$\text{indirect}_{i} = a_{i} \cdot b_{i}$$

2.  For a chained pathway
    $\left. M_{1}\rightarrow M_{2}\rightarrow\ldots\rightarrow M_{k} \right.$:
    $$\text{indirect}_{1\ldots k} = a_{1} \cdot b_{12} \cdot b_{23} \cdot \ldots \cdot b_{k}$$

The total indirect effect is:
$$\text{total\_indirect} = \sum\limits_{\text{all paths}}\text{indirect}_{\text{path}}$$

------------------------------------------------------------------------

### 2.1 Examples of Indirect Effects

For three mediators
$\left. M_{1}\rightarrow M_{2}\rightarrow M_{3} \right.$, the indirect
effects include:

1.  The direct path through $M_{1},M_{2},andM_{3}$:
    $$\text{indirect}_{1} = a_{1} \cdot b_{1}$$$$\text{indirect}_{2} = a_{2} \cdot b_{2}$$$$\text{indirect}_{3} = a_{3} \cdot b_{3}$$
2.  The chained path through $\left. M_{1}\rightarrow M_{2} \right.$:
    $$\text{indirect}_{12} = a_{1} \cdot b_{12} \cdot b_{2}$$
3.  The chained path through $\left. M_{2}\rightarrow M_{3} \right.$:
    $$\text{indirect}_{23} = a_{2} \cdot b_{23} \cdot b_{3}$$
4.  The chained path through
    $\left. M_{1}\rightarrow M_{2}\rightarrow M_{3} \right.$:
    $$\text{indirect}_{123} = a_{1} \cdot b_{12} \cdot b_{23} \cdot b_{3}$$

------------------------------------------------------------------------

## 3. Total Effect

The total effect combines the direct effect and the total indirect
effect: $$\text{total\_effect} = cp + \text{total\_indirect}$$

Where $cp$ is the direct effect.

------------------------------------------------------------------------

## 4. Comparison of Indirect Effects

When there are multiple mediators or pathways, comparing their indirect
effects provides insights into the relative influence of each mediator
or chain.

------------------------------------------------------------------------

### 4.1 Comparing Indirect Effects

The contrast between two indirect effects,
$\text{indirect}_{\text{path}_{1}}$ and
$\text{indirect}_{\text{path}_{2}}$, is calculated as:
$$CI_{\text{path}_{1}\text{vs}\text{path}_{2}} = \text{indirect}_{\text{path}_{1}} - \text{indirect}_{\text{path}_{2}}$$

#### Interpretation:

- $CI_{\text{path}_{1}\text{vs}\text{path}_{2}} > 0$: Pathway
  $\text{path}_{1}$ has a stronger indirect effect.
- $CI_{\text{path}_{1}\text{vs}\text{path}_{2}} < 0$: Pathway
  $\text{path}_{2}$ has a stronger indirect effect.

------------------------------------------------------------------------

### 4.2 Example: Three Mediators $M_{1},M_{2},M_{3}$

#### Indirect Effects

For three mediators, the following indirect effects are defined:

1.  **Direct Path Effects:**
    $$\text{indirect}_{1} = a_{1} \cdot b_{1}$$$$\text{indirect}_{2} = a_{2} \cdot b_{2}$$$$\text{indirect}_{3} = a_{3} \cdot b_{3}$$

2.  **Chained Path Effects:**
    $$\text{indirect}_{12} = a_{1} \cdot b_{12} \cdot b_{2}$$$$\text{indirect}_{23} = a_{2} \cdot b_{23} \cdot b_{3}$$$$\text{indirect}_{123} = a_{1} \cdot b_{12} \cdot b_{23} \cdot b_{3}$$

#### Comparisons

The indirect effects are compared as follows:
$$CI_{1\text{vs}2} = \text{indirect}_{1} - \text{indirect}_{2}$$$$CI_{1\text{vs}3} = \text{indirect}_{1} - \text{indirect}_{3}$$$$CI_{2\text{vs}3} = \text{indirect}_{2} - \text{indirect}_{3}$$$$CI_{1\text{vs}12} = \text{indirect}_{1} - \text{indirect}_{12}$$$$CI_{1\text{vs}23} = \text{indirect}_{1} - \text{indirect}_{23}$$$$CI_{1\text{vs}123} = \text{indirect}_{1} - \text{indirect}_{123}$$$$CI_{2\text{vs}12} = \text{indirect}_{2} - \text{indirect}_{12}$$$$CI_{2\text{vs}23} = \text{indirect}_{2} - \text{indirect}_{23}$$$$CI_{2\text{vs}123} = \text{indirect}_{2} - \text{indirect}_{123}$$$$CI_{3\text{vs}12} = \text{indirect}_{3} - \text{indirect}_{12}$$$$CI_{3\text{vs}23} = \text{indirect}_{3} - \text{indirect}_{23}$$$$CI_{3\text{vs}123} = \text{indirect}_{3} - \text{indirect}_{123}$$$$CI_{12\text{vs}23} = \text{indirect}_{12} - \text{indirect}_{23}$$$$CI_{12\text{vs}123} = \text{indirect}_{12} - \text{indirect}_{123}$$$$CI_{23\text{vs}123} = \text{indirect}_{23} - \text{indirect}_{123}$$
—

## 5. C1 and C2 Coefficients

For C1- and C2-measurement conditions, the coefficients are calculated
as follows:

1.  **C2-Measurement Coefficient ($X1_{b,i}$):**
    $$X1_{b,i} = b_{i} + d_{i}$$

2.  **C1-Measurement Coefficient ($X0_{b,i}$):**
    $$X0_{b,i} = X1_{b,i} - d_{i}$$

For chained pathways: 1. **C2-Measurement Coefficient ($X1_{b,ij}$):**
$$X1_{b,ij} = b_{ij} + d_{ij}$$

2.  **C1-Measurement Coefficient ($X0_{b,ij}$):**
    $$X0_{b,ij} = X1_{b,ij} - d_{ij}$$ — For three mediators
    $M_{1},M_{2},M_{3}$, the coefficients are calculated as follows:

    - C2-Measurement Coefficient: $$X1_{b,1} = b_{1} + d_{1}$$

    - C1-Measurement Coefficient: $$X0_{b,1} = X1_{b,1} - d_{1}$$

    - C2-Measurement Coefficient: $$X1_{b,2} = b_{2} + d_{2}$$

    - C1-Measurement Coefficient: $$X0_{b,2} = X1_{b,2} - d_{2}$$

    - C2-Measurement Coefficient: $$X1_{b,3} = b_{3} + d_{3}$$

    - C1-Measurement Coefficient: $$X0_{b,3} = X1_{b,3} - d_{3}$$

    - C2-Measurement Coefficient: $$X1_{b,12} = b_{12} + d_{12}$$

    - C1-Measurement Coefficient: $$X0_{b,12} = X1_{b,12} - d_{12}$$ —

## 6. Summary of Regression Equations

This section summarizes all the regression equations:

1.  **Outcome Difference Model ($Y_{\text{diff}}$):**
    $$Y_{\text{diff}} = cp + \sum\limits_{i = 1}^{N}\left( b_{i}M_{\text{diff},i} + d_{i}M_{\text{avg},i} \right) + e$$

2.  **Mediator Difference Model ($M_{\text{diff},i}$):**
    $$M_{\text{diff},i} = a_{i} + \sum\limits_{j < i}\left( b_{ji}M_{\text{diff},j} + d_{ji}M_{\text{avg},j} \right) + \epsilon_{i}$$

3.  **Indirect Effects:**
    $$\text{indirect}_{1\ldots k} = a_{1} \cdot b_{12} \cdot b_{23} \cdot \ldots \cdot b_{k}$$

4.  **Comparison of Indirect Effects**
    $$CI_{\text{path}_{1}\text{vs}\text{path}_{2}} = \text{indirect}_{\text{path}_{1}} - \text{indirect}_{\text{path}_{2}}$$

5.  **C1- and C2-Measurement Coefficients:**
    $$X1_{b,i} = b_{i} + d_{i},\quad X0_{b,i} = X1_{b,i} - d_{i}$$$$X1_{b,ij} = b_{ij} + d_{ij},\quad X0_{b,ij} = X1_{b,ij} - d_{ij}$$

By combining these equations, the `GenerateModelCN` function supports
chained mediation analysis with flexibility in handling nested pathways.

------------------------------------------------------------------------
