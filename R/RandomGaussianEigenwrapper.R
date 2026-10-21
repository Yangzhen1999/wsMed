#' Generate Gaussian random variates using eigendecomposition
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
  # The principal symmetric square root is invariant to eigenvector signs
  # and rotations within eigenspaces with repeated eigenvalues. Multiplying
  # Z by Q sqrt(D) alone would expose fixed-seed draws to those choices.
  # Preserve the existing treatment of small negative eigenvalues as zero.
  root <- tcrossprod(
    sweep(eigen$vectors, 2L, sqrt(pmax(eigen$values, 0)), `*`),
    eigen$vectors
  )
  Z %*% root
}
