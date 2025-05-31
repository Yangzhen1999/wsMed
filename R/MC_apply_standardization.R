#' @title Apply Standardization to Parameter Definitions
#'
#' @description Replaces parameters in expressions with their standardized versions.
#'
#' @param definitions A list of user-defined parameter expressions.
#' @param std_map A named list mapping intercept parameter names to their observed variables.
#' @param path_std_map A named list mapping slope parameters to predictor/outcome variables.
#' @return A list of standardized parameter expressions.
#' @keywords internal
apply_standardization <- function(definitions, std_map, path_std_map = list()) {
  out <- definitions
  for (param in unique(c(names(std_map), names(path_std_map)))) {
    std_expr <- if (param %in% names(std_map)) {
      paste0("std('", param, "')")
    } else if (param %in% names(path_std_map)) {
      px <- path_std_map[[param]][1]
      py <- path_std_map[[param]][2]
      paste0("std('", param, "', '", px, "', '", py, "')")
    } else {
      next
    }

    out <- lapply(out, function(expr) {
      gsub(paste0("\\b", param, "\\b"), std_expr, expr)
    })
  }
  out
}
