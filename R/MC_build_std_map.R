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
