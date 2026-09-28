# Endogenous products and marginal standardization

## Why the covariance specification changed

Let `M = mu(G) + u` and let `I_g` indicate category `g`. Under
`E(u | G) = 0`, `Cov(u, M I_g) = P(G = g) Var(M | G = g)`, which is generally
nonzero. Recoding the reference replaces an omitted product by
`M - sum(other category products)`. Fixing every mediator-disturbance/product
covariance to zero therefore imposes different joint moment restrictions under
different reference groups, even when the conditional regression estimates agree.

All five generators now identify only endogenous products actually used in the
regressions. Each such product is an auxiliary response regressed on every
remaining exogenous predictor. Product disturbances freely covary with each
other and with the disturbances of their source mediator and its ancestors in
the directed mediator graph. Non-ancestor disturbance/product covariances remain
zero. Existing regression paths and other residual restrictions are retained.
The generated models are recursive and have no user-specified correlated
mediator disturbances; extending this rule to other residual structures would
require revisiting the covariance closure.

These auxiliary regressions describe moments, not causal pathways or a new
substantive stochastic definition of an observed product. Conditional on the
genuine exogenous predictors, their coefficient and residual covariance blocks
are unrestricted. With `fixed.x = FALSE` this reparameterizes the unrestricted
predictor covariance block plus the necessary mediator-disturbance/product
covariances. It also lets lavaan identify the genuine exogenous predictors when
`fixed.x = TRUE`; product moments remain estimated in that setting.

This avoids lavaan's change in automatic exogenous covariance handling after
directly covarying an endogenous disturbance with an exogenous predictor.
The issue and the need to retain the complete exogenous covariance structure
are discussed in [Cheung and Cheung's manymome paper, Stage 1](https://pmc.ncbi.nlm.nih.gov/articles/PMC11289038/).
The auxiliary regression parameterization is wsMed's implementation of that
moment structure. An independently written explicit covariance model is tested
against it; unchanged zero constraints are not removed simply to saturate a model.

## Multiple imputation

The marginal standardizer remains `sqrt(Var(Ydiff))`, common across moderator
levels. In a serial product model, computing this variance only after pooling
the covariance-model parameters can introduce another coding dependence because
the nuisance reparameterization is nonlinear.

For each completed dataset `j`, let `theta_j` denote its primitive estimates and
let `v_j` contain the model-implied marginal variances used for standardization.
We estimate `v_j` and the Jacobian `J_j = d v_j / d theta_j`. The joint within-
imputation covariance is

```
            [ I ]           [ I ]'
U_joint,j = [ J_j ] U_j     [ J_j ]
```

Rubin's rules pool `(theta_j, v_j)` and its joint covariance. The primitive
parameter point estimates and their original unadjusted total covariance block
are unchanged by this augmentation. For marginal standardization, square roots
are taken after pooling the variances. Genuine fixed exogenous moments retain
the first-imputation convention; they are not assigned extra sampling variance.

MC first generates the existing primitive parameter draws. It then draws the
variance estimators from their conditional normal distribution given those
draws, using the pooled cross-covariance and the Schur-complement covariance.
The latter can be singular by construction, so its symmetric eigen square root
`Q sqrt(D) Q'` is used. This removes arbitrary eigenvector signs and rotations
from fixed-seed realizations across numerical libraries;
only negative eigenvalues within numerical roundoff tolerance are truncated.
Materially indefinite matrices error. Nonpositive variance draws are rejected
through the existing joint standardization diagnostics. This retains uncertainty
in the denominator and its dependence on coefficients.

The Jacobian uses symmetric finite differences. Tests verify the pooled variance
against the independent mean of per-imputation fitted variances, reference
invariance on paired completed datasets, the target MC cross-covariance, and
draw-by-draw endpoint standardization. These are implementation checks, not a
claim of exact finite-sample confidence-interval coverage.

## Compatibility and validation

- Models without endogenous products keep their original syntax and inference.
- Differences, dummies and product scaling conventions are unchanged.
- `wsMed()` and the staged workflow use the same corrected generators and pooling.
- Earlier fitted moderated objects must be refitted and their inference rerun.
- Fixed-seed draws and corrected fitted estimates may differ from version 1.1.0.
- Reference comparisons use identical data/imputations or paired bootstrap
  resamples. Independent finite MC runs need not produce identical intervals.
- Regression tests cover parallel, serial, both mixed structures, custom reverse
  paths, genuine fixed exogenous predictors, FIML, listwise deletion, MI, and
  participant bootstrap; existing unit-rescaling and continuous-probe tests run
  with the corrected model.

See `tests/testthat/test-product-covariances.R` for executable checks. The
manuscript replication workflow records the new fitted results separately from
the originally submitted analysis; changes are not treated as rounding errors.
