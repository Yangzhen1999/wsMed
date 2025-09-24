#' @title Wrapper for Internal Multiple Imputation Combining Function
#'
#' @description A wrapper function for the internal `.MICombine()` function from the `semmcci` package.
#' This function pools parameter estimates and covariance matrices from multiple imputed datasets
#' using Rubin's rules.
#'
#' @details This wrapper provides an abstraction over the internal `.MICombine()` function from the `semmcci` package,
#' allowing it to be used within your package without directly exposing the internal function.
#' It is primarily designed for use within workflows that involve multiple imputation and structural
#' equation modeling (SEM). Rubin's rules are applied to compute pooled parameter estimates and their
#' covariance matrices.
#'
#' @param coefs A list of numeric vectors, where each vector contains the parameter estimates from one
#' imputed dataset.
#' @param vcovs A list of numeric matrices, where each matrix represents the covariance matrix of the
#' parameter estimates for one imputed dataset.
#' @param M An integer indicating the number of imputations.
#' @param k An integer specifying the number of parameters in the SEM model.
#' @param adj A logical value indicating whether to apply an adjustment for finite samples. Default is `TRUE`.
#'
#' @return A list containing the pooled estimates and covariance matrix:
#' - `est`: A numeric vector of pooled parameter estimates.
#' - `total`: A numeric matrix representing the pooled covariance matrix.
#'
#' @seealso [RunMCMIAnalysis()]
#'
#'
#' @keywords internal

MICombineWrapper <- function(coefs, vcovs, M, k, adj = FALSE) {
  est <- colMeans(
    do.call(
      what = "rbind",
      args = coefs
    )
  )
  within <- (
    1 / M
  ) * Reduce(
    f = `+`,
    x = vcovs
  )
  between <- (
    1 / (
      M - 1
    )
  ) * Reduce(
    f = `+`,
    x = lapply(
      X = coefs,
      FUN = function(i,
                     est) {
        tcrossprod(i - est)
      },
      est = est
    )
  )
  colnames(between) <- rownames(between) <- rownames(within)
  total <- within + between + (1 / M) * between
  if (adj) {
    ariv <- ARIVwrapper(
      between = between,
      within = within,
      M = M,
      k = length(est)
    )
    total_adj <- TotalAdjwrapper(
      ariv = ariv,
      within = within
    )
  } else {
    ariv <- NA
    total_adj <- NA
  }
  return(
    list(
      M = M,
      est = est,
      within = within,
      between = between,
      total = total,
      ariv = ariv,
      total_adj = total_adj
    )
  )
}
