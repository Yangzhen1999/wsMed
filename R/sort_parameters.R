#' @title Sort Parameters for Printing in SEM Output
#' @description Sorts a parameter table by conceptual priority for presentation purposes.
#' This function is designed to support formatted output of mediation and SEM results
#' by organizing parameters such as a-paths, b-paths, indirect effects, contrasts, etc.
#'
#' @param df A data frame that contains a column named \code{Parameter} (e.g., from Monte Carlo CI output).
#' @return A reordered version of the same data frame, with rows sorted according to
#' a predefined logical structure:
#' \enumerate{
#'   \item a-paths (e.g., a1, a2, ...)
#'   \item b-paths (e.g., b1, b2, ...)
#'   \item d-paths (e.g., d1, d2, ...)
#'   \item indirect effects (e.g., ind1, ind2, ...)
#'   \item direct effect
#'   \item total indirect
#'   \item total effect
#'   \item contrasts (e.g., ind1-ind2, ind2-ind3)
#'   \item X-condition path terms (e.g., X1_b1, X0_b1, ...)
#' }
#'
#' @details This is an internal helper function used by \code{print.WsMed()} to ensure that printed
#' tables of standardized or unstandardized estimates appear in a logical and human-readable order.
#'
#' @examples
#' df <- data.frame(Parameter = c("b2", "a1", "direct effect", "ind2", "total effect"))
#' sort_parameters(df)
#'
#' @keywords internal
#' @export


sort_parameters <- function(df) {
  if (!"Parameter" %in% colnames(df)) return(df)

  # 获取参数名
  param <- df$Parameter

  # 定义排序优先级规则
  priority <- rep(99, length(param))
  priority[grepl("^a\\d+$", param)] <- 1
  priority[grepl("^b\\d+$", param)] <- 2
  priority[grepl("^d\\d+$", param)] <- 3
  priority[grepl("^ind\\d+$", param)] <- 4
  priority[grepl("^direct effect$", param)] <- 5
  priority[grepl("^total ind$", param)] <- 6
  priority[grepl("^total effect$", param)] <- 7
  priority[grepl("^ind\\d+-ind\\d+$", param)] <- 8
  priority[grepl("^X[01]_b\\d+$", param)] <- 9

  df$..sort_order <- priority
  df <- df[order(df$..sort_order, param), , drop = FALSE]
  df$..sort_order <- NULL
  return(df)
}
