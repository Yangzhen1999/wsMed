#' Average Relative Increase in Variance
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @details The average relative increase in variance
#'   is given by
#'   \deqn{
#'     \mathrm{ARIV}
#'     =
#'     \left( 1 + M^{-1} \right)
#'     \mathrm{tr}
#'     \left(
#'        \mathbf{V}_{\mathrm{between}}
#'        \mathbf{V}_{\mathrm{within}}^{-1}
#'     \right)
#'   }
#'
#' @param between Numeric matrix.
#'   Covariance between imputations
#'   \eqn{\mathbf{V}_{\mathrm{between}}}.
#' @param within Numeric matrix.
#'   Covariance within imputations
#'   \eqn{\mathbf{V}_{\mathrm{within}}}.
#' @param M Positive integer.
#'   Number of imputations.
#' @param k Positive integer.
#'   Number of parameters.
#'
#' @return Returns a numeric vector of length one.
#'
#
#' @keywords internal
ARIVwrapper <- function(between,
                  within,
                  M,
                  k) {
  return(
    (
      (
        1 + (
          1 / M
        )
      ) * sum(
        diag(
          between %*% chol2inv(
            chol(
              within
            )
          )
        )
      )
    ) / k
  )
}
