#' Matrix of Standard Normal Random Variates
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param n Positive integer.
#'   Number of rows.
#' @param k Positive integer.
#'   Number of columns.
#'
#' @return Numeric matrix.
#'
#' @family Random Gaussian Functions
#' @keywords randomGaussian random z internal
#' @noRd
RandomGaussianZwrapper <- function(n,
                             k) {
  return(
    matrix(
      data = stats::rnorm(
        n = n * k
      ),
      nrow = n,
      ncol = k
    )
  )
}
