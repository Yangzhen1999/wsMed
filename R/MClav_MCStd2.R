#' @title Monte Carlo Summary for Standardized Estimates
#'
#' @description Computes standardized estimates, standard errors, and confidence intervals
#' based on Monte Carlo samples from a `semmcci` object. This function fully standardizes
#' both point estimates and sampling distributions (including intercepts).
#'
#' @param mc A Monte Carlo result object of class `semmcci`, typically from `MC()` or `MCMI()`.
#' @param alpha A numeric vector of significance levels (default: `c(0.001, 0.01, 0.05)`).
#'
#' @return A data frame containing:
#' \describe{
#'   \item{Parameter}{Parameter name}
#'   \item{Estimate}{Standardized point estimate}
#'   \item{SE}{Standard deviation of standardized samples}
#'   \item{R}{Number of valid joint Monte Carlo replications}
#'   \item{CI columns}{Multiple confidence intervals based on `alpha`}
#' }
#'
#' @details The function standardizes the sampling distribution using `StdLav2()` on each Monte Carlo draw,
#' then summarizes the distribution into SEs and quantile-based confidence intervals.
#' Invalid draws are excluded jointly and reported in the standardization_diagnostics
#' attribute (requested, valid, invalid, indices and reasons).
#' @keywords internal

MCStd2 <- function(mc, alpha = c(0.001, 0.01, 0.05)) {
  stopifnot(inherits(mc, "semmcci"), mc$fun %in% c("MC", "MCMI"))
  fit <- mc$args$lav
  z <- .wsmed_std_draws(fit, mc$thetahatstar)
  point <- StdLav2(mc$thetahat$est, fit)
  probs <- sort(c(alpha / 2, 1 - alpha / 2))
  ci <- t(apply(z$draws, 2, stats::quantile, probs = probs))
  colnames(ci) <- paste0(round(probs * 100, 1), "%")
  out <- data.frame(Parameter = colnames(mc$thetahatstar), Estimate = point,
                    SE = apply(z$draws, 2, stats::sd),
                    R = z$diagnostics$valid, ci, check.names = FALSE)
  attr(out, "standardization_diagnostics") <- z$diagnostics
  out
}
