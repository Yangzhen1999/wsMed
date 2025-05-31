#' Generate Random Variates from the Gaussian Distribution
#' (Singular Value Decomposition)
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param Z Numeric matrix.
#'   `n` by `k` matrix of independent random variates
#'   from the standard univariate normal distribution
#'   \eqn{\mathbf{Z}}.
#' @param svd Object.
#'   Result of [svd()].
#'
#' @return Numeric matrix.
#'
#' @family Random Gaussian Functions
#' @keywords randomGaussian random svd internal
#' @export
RandomGaussianSVDwrapper <- function(Z,
                               svd) {
  return(
    Z %*% svd$u %*% (
      t(svd$v) * sqrt(
        pmax(
          svd$d,
          0
        )
      )
    )
  )
}
