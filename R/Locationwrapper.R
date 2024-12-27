#' Add Location Parameter
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param X Numeric matrix.
#'   `n` by `k` matrix.
#' @param location Numeric vector of length `k`.
#'   Location parameter.
#' @param n Positive integer.
#'   Number of rows.
#' @param k Positive integer.
#'   Number of columns.
#'
#' @return Numeric matrix.
#'
#' @family Random Gaussian Functions
#' @keywords randomGaussian random location internal
#' @noRd
Locationwrapper <- function(X,
                      location,
                      n,
                      k) {
  return(
    X + rep(
      x = location,
      times = rep(
        x = n,
        times = k
      )
    )
  )
}
