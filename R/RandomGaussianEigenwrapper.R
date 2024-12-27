#' Generate Random Variates from the Gaussian Distribution
#' (Eigen Decomposition)
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param Z Numeric matrix.
#'   `n` by `k` matrix of independent random variates
#'   from the standard univariate normal distribution
#'   \eqn{\mathbf{Z}}.
#' @param eigen Object.
#'   Result of [eigen()].
#'
#' @return Numeric matrix.
#'
#' @family Random Gaussian Functions
#' @keywords randomGaussian random eigen internal
#' @noRd
RandomGaussianEigenwrapper <- function(Z,
                                 eigen) {
  return(
    Z %*% (
      t(eigen$vectors) * sqrt(
        pmax(
          eigen$values,
          0
        )
      )
    )
  )
}
