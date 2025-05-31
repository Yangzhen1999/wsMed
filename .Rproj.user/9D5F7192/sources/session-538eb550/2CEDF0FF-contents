#' @title Extract Target Variables for Standardization
#'
#' @description
#' Extracts variable names from a fitted SEM model and a definition map that are required
#' for computing standardized estimates in Monte Carlo simulations.
#' Specifically, it identifies intercept terms (e.g., `~1`) involved in user-defined parameters
#' such as indirect effects (e.g., `indirect := a * b`) that require standard deviations for standardization.
#'
#' @param fit A \code{lavaan} model object. Must be fitted with labels for defined parameters.
#' @param definition_map A named list returned from \code{resolve_all_dependencies()}, mapping defined parameters (e.g., "indirect1") to their algebraic components (e.g., c("a1", "b1")).
#' @param data A data frame used to fit the model, typically the original observed dataset. Used to validate the existence of variables.
#'
#' @return A character vector of variable names whose standard deviations are needed to standardize the intercept estimates in Monte Carlo confidence interval analysis.
#' @keywords internal

get_sd_target_variables <- function(fit, definition_map, data) {
  pt <- as.data.frame(fit@ParTable)
  intercept_vars <- unique(pt$lhs[pt$op == "~1" & pt$free > 0])
  intercept_vars <- intersect(intercept_vars, names(data))  # 只保留数据中有的

  # 中介部分 —— 定义参数中出现 a1, a2 等
  a_paths <- unlist(definition_map[grepl("^indirect", names(definition_map))])
  a_paths <- a_paths[grepl("^a[0-9]+$", a_paths)]

  a_param_rows <- pt[pt$label %in% a_paths & pt$op == "~1", ]
  mediator_vars <- unique(a_param_rows$lhs)

  # 结果变量（例如 cp）→ 看是否有 Ydiff ~1 的自由项
  outcome_cp <- pt$lhs[pt$label == "cp" & pt$op == "~1" & pt$free > 0]

  # 合并所有需要的变量
  all_vars <- union(mediator_vars, outcome_cp)
  all_vars <- intersect(all_vars, intercept_vars)

  return(unique(all_vars))
}
