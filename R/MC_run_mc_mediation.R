#' @title Run Monte Carlo-Based Mediation Inference
#'
#' @description Performs Monte Carlo simulation to estimate confidence intervals for both
#' unstandardized and (optionally) standardized mediation parameters, based on fitted SEM models.
#'
#' @param fit A fitted `lavaan` model.
#' @param data The dataset used for the fitted model.
#' @param standardized Logical. If TRUE, standardized results will also be returned. Default is FALSE.
#' @param R Integer. Number of Monte Carlo replications. Default is 20000.
#' @param seed Integer. Random seed for reproducibility. Default is 123.
#'
#' @return A list with unstandardized and (if requested) standardized results.
#' Each result includes Monte Carlo estimates, SEs, and CIs.
#' @export
run_mc_mediation <- function(fit,
                             data,
                             standardized = FALSE,
                             R = 20000,
                             seed = 123,
                             alpha = 0.05,         # non-standardized CI level
                             alphastd = 0.05       # standardized CI level
                             ) {
  # 1. Extract parameter maps
  all_params <- extract_all_parameters(fit)
  resolved_map <- resolve_all_dependencies(all_params$definition_map)
  definitions_unstd <- build_definitions(fit)
  theta_star <- generate_mc_samples(fit, resolved_map, R = R, seed = seed)

  # 2. Evaluate unstandardized results
  result_unstd <- evaluate_definitions_unstd_v2(theta_star, definitions_unstd)
  summary_unstd <- summarize_mc_ci(result_unstd, alpha = alpha)

  if (!standardized) {
    return(list(
      unstd_result = result_unstd,
      unstd_summary = summary_unstd
    ))
  }

  # 3. Standardization preparation
  std_map <- build_std_map(fit)
  path_std_map <- build_path_std_map(fit)
  definitions_std <- apply_standardization(
    definitions = definitions_unstd,
    std_map = std_map,
    path_std_map = path_std_map
  )

  # 4. Bootstrap SDs for standardization
  sd_boot_list <- bootstrap_sd_list(
    data = data,
    var_names = get_sd_target_variables(fit, all_params$definition_map, data),
    nboot = R,
    seed = seed
  )
  sd_var_boot <- bootstrap_sd_list(
    data = data,
    var_names = get_all_variables_from_path_map(path_std_map),
    nboot = R,
    seed = seed
  )

  # 5. Evaluate standardized results
  result_std <- evaluate_definitions_v3(
    theta_star = theta_star,
    definitions = definitions_std,
    std_map = std_map,
    sd_boot_list = sd_boot_list,
    sd_var_boot = sd_var_boot,
    path_std_map = path_std_map
  )
  summary_std <- summarize_mc_ci(result_std, alpha = alphastd)

  return(list(
    unstd_result = result_unstd,
    unstd_summary = summary_unstd,
    std_result = result_std,
    std_summary = summary_std
  ))
}


#' @title Extract All Variables Needed for Standardization
#'
#' @description Extracts predictor and outcome variable names from a path standardization map.
#' @param path_std_map A named list returned by [build_path_std_map()].
#' @return A character vector of variable names.
#' @keywords internal
#' @export
get_all_variables_from_path_map <- function(path_std_map) {
  unique(unlist(path_std_map))
}
