#' Extract Target Variables for Standardization
#'
#' This function extracts the variable names from the definition map
#' that are required for standardization, i.e., variables whose
#' standard deviations are needed when computing standardized estimates
#' from Monte Carlo simulations.
#'
#' It cross-references the variables involved in user-defined parameters
#' (e.g., indirect := a * b) with the variables present in the observed dataset.
#'
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
