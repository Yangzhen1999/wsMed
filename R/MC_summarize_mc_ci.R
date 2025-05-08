#' @title Summarize Monte Carlo Simulation Results
#'
#' @description Computes summary statistics for Monte Carlo simulation results, including
#' the mean estimate, standard error (SE), and confidence intervals (CIs).
#'
#' @param mc_result A data frame where each column corresponds to a parameter, and each row
#' represents one Monte Carlo replication of that parameter's estimate.
#' @param alpha Numeric. Significance level used to compute the (1 - alpha) confidence interval.
#' Default is 0.05 for a 95% confidence interval.
#'
#' @return A data frame with one row per parameter and the following columns:
#' \describe{
#'   \item{Parameter}{The name of the parameter.}
#'   \item{Estimate}{The average estimate across all Monte Carlo replications.}
#'   \item{SE}{The standard deviation of the estimates (standard error).}
#'   \item{CI_lower}{The lower bound of the confidence interval.}
#'   \item{CI_upper}{The upper bound of the confidence interval.}
#' }
#'
#' @export

summarize_mc_ci <- function(mc_result, alpha = 0.05) {
  stopifnot(is.data.frame(mc_result))
  lower <- alpha / 2
  upper <- 1 - alpha / 2

  summary_df <- data.frame(
    Parameter = colnames(mc_result),
    Estimate = apply(mc_result, 2, mean, na.rm = TRUE),
    SE = apply(mc_result, 2, sd, na.rm = TRUE),
    CI_lower = apply(mc_result, 2, quantile, probs = lower, na.rm = TRUE),
    CI_upper = apply(mc_result, 2, quantile, probs = upper, na.rm = TRUE),
    row.names = NULL
  )

  return(summary_df)
}
