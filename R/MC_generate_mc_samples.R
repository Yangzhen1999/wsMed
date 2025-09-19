#' @title Generate Monte Carlo Samples
#'
#' @description Generates a Monte Carlo sample of model parameters from a multivariate normal distribution.
#'
#' @param fit A fitted `lavaan` model.
#' @param resolved_map A dependency map from [resolve_all_dependencies()].
#' @param R Integer. Number of Monte Carlo samples to generate.
#' @param seed Integer. Random seed.
#' @return A numeric matrix of Monte Carlo samples.
#' @keywords internal
generate_mc_samples <- function(fit, resolved_map, R = 20000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  param_names <- unique(unlist(resolved_map))
  coef_all <- lavaan::coef(fit)
  vcov_all <- lavaan::vcov(fit)

  missing <- setdiff(param_names, names(coef_all))
  if (length(missing) > 0) {
    stop("Parameters not found in model: ", paste(missing, collapse = ", "))
  }

  coef_vec <- coef_all[param_names]
  vcov_mat <- vcov_all[param_names, param_names, drop = FALSE]
  samples <- MASS::mvrnorm(n = R, mu = coef_vec, Sigma = vcov_mat)
  colnames(samples) <- param_names
  samples
}
