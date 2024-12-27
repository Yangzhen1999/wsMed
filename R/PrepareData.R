#' @title Prepare Data for Within-Subject Mediation Analysis
#'
#' @description Prepares a dataset for within-subject mediation analysis by calculating
#' difference scores and centered average scores for specified mediators and the outcome variable.
#' The function ensures that the input data meets the necessary requirements and generates
#' new variables required for subsequent mediation analysis.
#'
#' @details This function processes raw data to create variables essential for within-subject
#' mediation analysis. It performs the following operations:
#'
#' - **Difference scores**: Calculates the difference between "before" and "after" values for
#' the outcome variable (`Ydiff`) and each mediator (`Mdiff`).
#'
#' - **Centered average scores**: Computes the centered average of "before" and "after"
#' values for each mediator (`Mavg`), providing a measure of their mean level relative to
#' their centered baseline.
#'
#' - **Input validation**: Checks that the number of "before" and "after" mediators match,
#' and ensures all specified variables exist in the dataset.
#'
#' This function is a prerequisite for generating structural equation modeling (SEM)
#' syntax and conducting mediation analysis.
#'
#' @param data A data frame containing the raw dataset with mediator and outcome variables.
#' @param M_before A character vector of column names representing mediators "before" the intervention.
#' @param M_after A character vector of column names representing mediators "after" the intervention.
#' Must match the length of `M_before`.
#' @param Y_before A character string representing the column name of the outcome variable "before" the intervention.
#' @param Y_after A character string representing the column name of the outcome variable "after" the intervention.
#'
#' @return A data frame containing the following columns:
#' - `Ydiff`: Difference score for the outcome variable.
#' - `M1diff`, `M2diff`, ...: Difference scores for each mediator.
#' - `M1avg`, `M2avg`, ...: Centered average scores for each mediator.
#'
#' @seealso [GenerateModelP()], [GenerateModelCN()], [GenerateModelPC()], [WsMed()]
#'
#' @examples
#' # Example raw data
#' data <- data.frame(
#'   M1_before = rnorm(100), M1_after = rnorm(100),
#'   M2_before = rnorm(100), M2_after = rnorm(100),
#'   Y_before = rnorm(100), Y_after = rnorm(100)
#' )
#'
#' # Prepare the dataset
#' prepared_data <- PrepareData(
#'   data = data,
#'   M_before = c("M1_before", "M2_before"),
#'   M_after = c("M1_after", "M2_after"),
#'   Y_before = "Y_before",
#'   Y_after = "Y_after"
#' )
#'
#' head(prepared_data)
#'
#' @export

PrepareData <- function(data, M_before, M_after, Y_before, Y_after) {
  # 检查输入长度是否匹配
  if (length(M_before) != length(M_after)) {
    stop("The number of M_before and M_after variables must match.")
  }

  # 检查 Y_before 和 Y_after 是否存在
  if (!(Y_before %in% colnames(data)) || !(Y_after %in% colnames(data))) {
    stop("Y variables not found in the dataset.")
  }

  # 计算 Y 的差异
  data$Ydiff <- data[[Y_after]] - data[[Y_before]]

  # 初始化存储差异和均值的列
  diffs <- list()
  avgs <- list()

  # 循环处理每对中介变量
  for (i in seq_along(M_before)) {
    M1 <- M_before[i]
    M2 <- M_after[i]

    # 检查 M1 和 M2 是否存在
    if (!(M1 %in% colnames(data)) || !(M2 %in% colnames(data))) {
      stop(paste0("M variables for ", M1, " and ", M2, " not found in the dataset."))
    }

    # 计算差异和中心化均值
    diff_name <- paste0("M", i, "diff")
    avg_name <- paste0("M", i, "avg")
    diffs[[diff_name]] <- data[[M2]] - data[[M1]]
    M1_centered <- data[[M1]] - mean(data[[M1]], na.rm = TRUE)
    M2_centered <- data[[M2]] - mean(data[[M2]], na.rm = TRUE)
    avgs[[avg_name]] <- (M1_centered + M2_centered) / 2
  }

  # 将生成的差异和均值列添加到数据框中
  data <- cbind(data, do.call(cbind, diffs), do.call(cbind, avgs))

  # 返回只包含 Ydiff 和所有差异与均值的列
  cols_to_return <- c("Ydiff", names(diffs), names(avgs))
  return(data[, cols_to_return])
}
