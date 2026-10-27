#' @title Standardize RAM matrices
#'
#' @description Performs standardization of RAM matrices by rescaling path and variance structures
#' using the implied covariance matrix. Intercepts are also standardized.
#'
#' @param ram_est A RAM object list with matrices `A`, `S`, `F`, and `M` as returned by `Lav2RAM2()`.
#' @param roles Internal list of dummy variable names and interaction components.
#' @param marginal_variances Optional jointly pooled MI marginal variances.
#'
#' @return A list of standardized RAM matrices:
#' \describe{
#'   \item{A}{Standardized asymmetric path matrix}
#'   \item{S}{Standardized symmetric path matrix}
#'   \item{F}{Unchanged filter matrix}
#'   \item{M}{Standardized intercept vector}
#' }
#'
#' @details The function computes the implied covariance matrix \eqn{\Sigma = (I - A)^{-1} S (I - A)^{-T}},
#' extracts standard deviations, and performs standardization via \eqn{D^{-1}} scaling.
#' @keywords internal

StdRAM2 <- function(ram_est, roles = NULL, marginal_variances = NULL) {
  a_mat <- ram_est$A
  s_mat <- ram_est$S
  iden <- diag(nrow(a_mat))
  b_inv <- solve(iden - a_mat)

  # implied covariance matrix: Sigma = B * S * B'
  sigma <- b_inv %*% s_mat %*% t(b_inv)
  if (any(!is.finite(sigma)) || any(!is.finite(s_mat)))
    stop("Non-finite covariance matrix.")
  if (min(eigen(s_mat, symmetric = TRUE, only.values = TRUE)$values) <
      -1e-10 * max(1, max(abs(s_mat))))
    stop("Non-positive-semidefinite residual/exogenous covariance matrix.")
  tryCatch(chol(sigma), error = function(e)
    stop("Non-positive-definite implied covariance matrix."))

  # Marginal implied SDs; dummy contrasts retain their original units.
  variances <- diag(sigma)
  if (!is.null(marginal_variances)) {
    if (is.null(names(marginal_variances)) ||
        !all(names(marginal_variances) %in% names(variances)))
      stop("Unknown MI marginal variance identities.")
    variances[names(marginal_variances)] <- marginal_variances
  }
  if (any(!is.finite(variances)) || any(variances <= 0))
    stop("Non-positive or non-finite implied variance.")
  sd_vec <- sqrt(variances)
  names(sd_vec) <- colnames(a_mat)
  for (nm in intersect(roles$dummy, names(sd_vec))) sd_vec[nm] <- 1
  for (nm in intersect(names(roles$products), names(sd_vec))) {
    components <- roles$products[[nm]]
    if (!all(components %in% names(sd_vec)))
      stop("Missing interaction component in standardization: ", nm)
    sd_vec[nm] <- prod(sd_vec[components])
  }
  sdinv <- diag(1 / sd_vec)

  # standardize A and S
  a_matz <- sdinv %*% a_mat %*% solve(sdinv)
  s_matz <- sdinv %*% s_mat %*% sdinv

  # standardize M
  m_vec <- as.numeric(ram_est$M)         # intercept vector
  m_std <- m_vec / sd_vec                # element-wise division
  m_matz <- matrix(m_std, nrow = 1)      # back to 1-row matrix
  colnames(m_matz) <- colnames(a_mat)

  # return standardized RAM
  colnames(a_matz) <- rownames(a_matz) <- colnames(a_mat)
  colnames(s_matz) <- rownames(s_matz) <- colnames(s_mat)

  return(
    list(
      A = a_matz,
      S = s_matz,
      F = ram_est$F,
      M = m_matz
    )
  )
}
