# Pool marginal variance estimators alongside primitive coefficients. Computing
# a variance only after pooling nonlinear covariance-model parameters need not
# commute with a change of categorical reference in a serial moderated model.
.wsmed_pool_marginal <- function(fits, coefs, vcovs) {
  first <- fits[[1]]
  ov <- lavaan::lavNames(first, "ov")
  if (!any(grepl("^int_M[0-9]+diff_W", ov))) return(NULL)
  excluded <- c(grep("^int_", ov, value = TRUE), first@external$wsmed_roles$dummy)
  if (isTRUE(lavaan::lavInspect(first, "options")$fixed.x))
    excluded <- union(excluded, lavaan::lavNames(first, "ov.x"))
  variables <- setdiff(ov, excluded)
  estimates <- covariances <- vector("list", length(fits))
  for (i in seq_along(fits)) {
    fit <- fits[[i]]; theta <- coefs[[i]]
    indices <- match(variables, lavaan::lavNames(fit, "ov"))
    variance <- function(x) {
      model <- lavaan::lav_model_set_parameters(fit@Model, x = x)
      diag(lavaan::lav_model_implied(model)$cov[[1]])[indices]
    }
    h <- .Machine$double.eps^(1/3) * pmax(1, abs(theta))
    jacobian <- vapply(seq_along(theta), function(j) {
      plus <- minus <- theta; plus[j] <- plus[j] + h[j]; minus[j] <- minus[j] - h[j]
      (variance(plus) - variance(minus)) / (2 * h[j])
    }, numeric(length(variables)))
    jacobian <- rbind(diag(length(theta)), jacobian)
    estimates[[i]] <- c(theta, stats::setNames(variance(theta), paste0("marginal::", variables)))
    covariances[[i]] <- jacobian %*% vcovs[[i]] %*% t(jacobian)
    dimnames(covariances[[i]]) <- list(names(estimates[[i]]), names(estimates[[i]]))
  }
  # The augmented within-imputation covariance can be singular by construction.
  # Rubin's unadjusted total covariance (also used for primitive MC) needs no inverse.
  pooled <- MICombineWrapper(estimates, covariances, M = length(fits),
    k = length(estimates[[1]]), adj = FALSE)
  ix <- length(coefs[[1]]) + seq_along(variables)
  list(point = stats::setNames(pooled$est[ix], variables),
    cross = pooled$total[ix, seq_along(coefs[[1]]), drop = FALSE],
    total = pooled$total[ix, ix, drop = FALSE],
    within = pooled$within[ix, ix, drop = FALSE],
    between = pooled$between[ix, ix, drop = FALSE])
}

# Draw the variance estimators conditionally on the primitive joint MC draws.
# This preserves their covariance without attempting Cholesky decomposition of
# an intentionally rank-deficient augmented covariance matrix.
.wsmed_draw_marginal <- function(moments, coefficients, covariance, draws) {
  if (is.null(moments)) return(NULL)
  slope <- t(solve(covariance, t(moments$cross)))
  residual <- moments$total - slope %*% t(moments$cross)
  residual <- (residual + t(residual))/2
  eig <- eigen(residual, symmetric = TRUE)
  tolerance <- 1e-8 * max(abs(moments$total), .Machine$double.eps)
  if (min(eig$values) < -tolerance)
    stop("MI marginal-variance conditional covariance is not positive semidefinite.")
  root <- sweep(eig$vectors, 2, sqrt(pmax(eig$values, 0)), `*`)
  innovations <- matrix(stats::rnorm(nrow(draws) * nrow(root)), nrow(draws)) %*% t(root)
  values <- sweep(sweep(draws, 2, coefficients) %*% t(slope) + innovations,
                  2, moments$point, `+`)
  colnames(values) <- names(moments$point)
  list(point = moments$point, draws = values)
}
