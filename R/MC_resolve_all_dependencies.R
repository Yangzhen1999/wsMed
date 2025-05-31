#' @title Resolve Dependencies of Defined Parameters
#'
#' @description Recursively resolves all free parameters involved in each defined parameter.
#'
#' @param def_map A definition map produced by [extract_all_parameters()].
#' @return A list mapping each defined parameter to its dependent free parameters.
#' @keywords internal
resolve_all_dependencies <- function(def_map) {
  resolve_one <- function(param, def_map, visited = character()) {
    if (param %in% visited) return(character(0))
    visited <- c(visited, param)
    if (!(param %in% names(def_map))) return(param)
    deps <- def_map[[param]]
    flat <- unlist(lapply(deps, function(p) resolve_one(p, def_map, visited)))
    unique(flat)
  }

  resolved_map <- lapply(names(def_map), function(param) {
    resolve_one(param, def_map)
  })
  names(resolved_map) <- names(def_map)
  resolved_map
}
