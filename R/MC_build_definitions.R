#' @title Build Unstandardized Parameter Definitions
#'
#' @description Extracts parameter definition expressions from a fitted model.
#'
#' @param fit A `lavaan` model object.
#' @return A named list of parameter definitions.
#' @keywords internal
#' @importFrom lavaan parameterEstimates

build_definitions <- function(fit) {
  pe <- lavaan::parameterEstimates(fit)
  def_rows <- pe[pe[["op"]] == ":=", , drop = FALSE]
  definitions <- as.list(def_rows[["rhs"]])
  names(definitions) <- def_rows[["lhs"]]
  definitions
}




