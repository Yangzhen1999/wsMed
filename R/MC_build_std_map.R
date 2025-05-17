#' @title Build Standardization Maps
#'
#' @description Constructs mapping of parameter labels to variables for standardization.
#'
#' @param fit A fitted `lavaan` model.
#' @return A named list: intercepts (std_map).
#' @keywords internal
#' @importFrom stats setNames
#' @importFrom rlang .data

build_std_map <- function(fit) {
  pt <- as.data.frame(fit@ParTable)
  pt <- pt[pt[["op"]] == "~1" & pt[["free"]] > 0 & pt[["label"]] != "", ]
  setNames(pt[["lhs"]], pt[["label"]])
}


#' @title Build Standardization Maps PATH
#'
#' @description Constructs mapping of parameter labels to variables for standardization.
#'
#' @param fit A fitted `lavaan` model.
#' @return A named list: slopes (path_std_map).
#' @keywords internal
#' @importFrom stats setNames
#' @importFrom rlang .data

build_path_std_map <- function(fit) {
  pt <- as.data.frame(fit@ParTable)
  pt <- pt[pt[["op"]] == "~" & pt[["free"]] > 0 & pt[["label"]] != "", ]
  setNames(
    lapply(seq_len(nrow(pt)), function(i) c(pt[["rhs"]][i], pt[["lhs"]][i])),
    pt[["label"]]
  )
}

