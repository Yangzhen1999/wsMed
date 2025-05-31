#' @title Extract All Parameters and Definitions
#'
#' @description Extracts free and defined parameters from a fitted `lavaan` model,
#' and builds a dependency map of user-defined parameters.
#'
#' @param fit A `lavaan` model object.
#' @return A list with:
#' - `free`: Names of free parameters.
#' - `defined`: Names of defined parameters.
#' - `definition_map`: A list mapping defined parameters to their dependencies.
#' @keywords internal
extract_all_parameters <- function(fit) {
  pt <- as.data.frame(fit@ParTable)
  pe <- lavaan::parameterEstimates(fit)

  free_rows <- pt[pt$free > 0, ]
  free_params <- paste0(free_rows$lhs, free_rows$op, free_rows$rhs)

  def_rows <- subset(pe, pe[["op"]] == ":=")
  def_names <- def_rows$lhs

  extract_symbols <- function(rhs_expr) {
    tokens <- unlist(strsplit(rhs_expr, "[^a-zA-Z0-9_]+"))
    tokens <- tokens[nzchar(tokens)]
    tokens <- tokens[!grepl("^[0-9.]+$", tokens)]
    unique(tokens)
  }

  def_map <- lapply(def_rows$rhs, extract_symbols)
  names(def_map) <- def_names

  list(
    free = unique(free_params),
    defined = def_names,
    definition_map = def_map
  )
}
