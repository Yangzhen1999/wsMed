#' Test for a Positive Definite Matrix
#'
#' Returns `TRUE` if input
#' is a positive definite matrix,
#' and `FALSE` otherwise.
#'
#' A
#' \eqn{k \times k}
#' symmetric matrix
#' \eqn{\mathbf{A}}
#' is positive definite
#' if all of its eigenvalues are positive.
#'
#' @param eigen output of the [eigen()] function.
#' @param tol Numeric.
#'   Tolerance.
#'
#' @references
#'   [Wikipedia: Definite matrix](https://en.wikipedia.org/wiki/Definite_matrix)
#'
#' @return Logical.
#' @keywords internal

TestPositiveDefinitewrapper <- function(eigen,
                                  tol = 1e-06) {
  return(
    all(
      eigen$values >= -tol * abs(
        eigen$values[1L]
      )
    )
  )
}
