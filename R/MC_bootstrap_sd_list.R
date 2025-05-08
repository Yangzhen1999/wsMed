#' @title Bootstrap Standard Deviations for Standardization
#'
#' @description Performs bootstrap sampling to estimate SDs of variables used in standardization.
#'
#' @param data A data frame.
#' @param var_names A character vector of variable names.
#' @param nboot Integer. Number of bootstrap samples.
#' @param seed Integer. Random seed.
#' @return A named list of numeric vectors (bootstrapped SD samples).
#' @keywords internal
bootstrap_sd_list <- function(data, var_names, nboot = 20000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  out <- list()
  for (v in var_names) {
    values <- data[[v]]
    values <- values[!is.na(values)]
    sd_samples <- replicate(nboot, {
      sample_v <- sample(values, replace = TRUE)
      sd(sample_v)
    })
    out[[v]] <- sd_samples
  }
  out
}


