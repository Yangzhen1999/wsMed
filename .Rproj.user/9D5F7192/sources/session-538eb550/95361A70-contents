#' Adjusted Total Sampling Covariance Matrix
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @details The adjusted total sampling covariance matrix
#'   is given by
#'   \deqn{
#'     \tilde{\mathbf{V}}_{\mathrm{total}}
#'     =
#'     \left( 1 + \mathrm{ARIV} \right)
#'     \mathbf{V}_{\mathrm{within}}
#'   }
#'
#' @param ariv Numeric.
#'   Average relative increase in variance.
#' @param within Numeric matrix.
#'   Covariance within imputations
#'   \eqn{\mathbf{V}_{\mathrm{within}}}.
#' @keywords internal

TotalAdjwrapper <- function(ariv,
                      within) {
  return(
    (1 + ariv) * within
  )
}
