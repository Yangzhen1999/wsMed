#' @title Standardize RAM Matrices
#'
#' @description Performs standardization of RAM matrices by rescaling path and variance structures
#' using the implied covariance matrix. Intercepts are also standardized.
#'
#' @param ram_est A RAM object list with matrices `A`, `S`, `F`, and `M` as returned by `Lav2RAM2()`.
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

StdRAM2 <- function(ram_est) {
  a_mat <- ram_est$A
  s_mat <- ram_est$S
  iden <- diag(nrow(a_mat))
  b_inv <- solve(iden - a_mat)

  # implied covariance matrix: Sigma = B * S * B'
  sigma <- b_inv %*% s_mat %*% t(b_inv)

  # standard deviation inverse matrix: D^{-1}
  sdinv <- diag(1 / sqrt(diag(sigma)))

  # standardize A and S
  a_matz <- sdinv %*% a_mat %*% solve(sdinv)
  s_matz <- sdinv %*% s_mat %*% sdinv

  # standardize M
  m_vec <- as.numeric(ram_est$M)         # intercept vector
  sd_vec <- sqrt(diag(sigma))            # SD of each variable
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
