#' @title Build Unstandardized Parameter Definitions
#'
#' @description Extracts parameter definition expressions from a fitted model.
#'
#' @param fit A `lavaan` model object.
#' @return A named list of parameter definitions.
#' @keywords internal

build_definitions <- function(fit) {
  pe <- lavaan::parameterEstimates(fit)
  def_rows <- subset(pe, op == ":=")
  definitions <- as.list(def_rows$rhs)
  names(definitions) <- def_rows$lhs
  definitions
}

#' @title Build Standardization Maps
#'
#' @description Constructs mapping of parameter labels to variables for standardization.
#'
#' @param fit A fitted `lavaan` model.
#' @return A named list: intercepts (std_map) or slopes (path_std_map).
#' @keywords internal

build_std_map <- function(fit) {
  pt <- as.data.frame(fit@ParTable)
  pt <- subset(pt, op == "~1" & free > 0 & label != "")
  setNames(pt$lhs, pt$label)
}

build_path_std_map <- function(fit) {
  pt <- as.data.frame(fit@ParTable)
  pt <- subset(pt, op == "~" & free > 0 & label != "")
  setNames(
    lapply(seq_len(nrow(pt)), function(i) c(pt$rhs[i], pt$lhs[i])),
    pt$label
  )
}
