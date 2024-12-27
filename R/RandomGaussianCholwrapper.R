#' Generate Random Variates from the Gaussian Distribution
#' (Cholesky Decomposition)
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param Z Numeric matrix.
#'   `n` by `k` matrix of independent random variates
#'   from the standard univariate normal distribution
#'   \eqn{\mathbf{Z}}.
#' @param chol Object.
#'   Result of [chol()].
#'
#' @return Numeric matrix.
#'
#' @family Random Gaussian Functions
#' @keywords randomGaussian random cholesky internal
#' @noRd
RandomGaussianCholwrapper <- function(Z,
                                chol) {
  return(
    Z %*% chol
  )
}
