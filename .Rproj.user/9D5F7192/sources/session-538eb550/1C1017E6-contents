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
#' @param M_C1 A character vector of column names representing mediators "before" the intervention.
#' @param M_C2 A character vector of column names representing mediators "after" the intervention.
#' Must match the length of `M_C1`.
#' @param Y_C1 A character string representing the column name of the outcome variable "before" the intervention.
#' @param Y_C2 A character string representing the column name of the outcome variable "after" the intervention.
#' @param C_C1 Character vector of within-subject control variable names (condition 1).
#' @param C_C2 Character vector of within-subject control variable names (condition 2).
#' @param C Character vector of between-subject control variable names.
#'
#' @return A data frame containing the following columns:
#' - `Ydiff`: Difference score for the outcome variable.
#' - `M1diff`, `M2diff`, ...: Difference scores for each mediator.
#' - `M1avg`, `M2avg`, ...: Centered average scores for each mediator.
#'
#' @seealso [GenerateModelP()], [GenerateModelCN()], [GenerateModelPC()], [wsMed()]
#'
#' @examples
#' # Example raw data
#' data <- data.frame(
#'   M1_before = rnorm(100), M1_after = rnorm(100),
#'   M2_before = rnorm(100), M2_after = rnorm(100),
#'   Y_C1 = rnorm(100), Y_C2 = rnorm(100)
#' )
#'
#' # Prepare the dataset
#' prepared_data <- PrepareData(
#'   data = data,
#'   M_C1 = c("M1_before", "M2_before"),
#'   M_C2 = c("M1_after", "M2_after"),
#'   Y_C1 = "Y_C1",
#'   Y_C2 = "Y_C2"
#' )
#'
#' head(prepared_data)
#'
#' @export


PrepareData <- function(data, M_C1, M_C2, Y_C1, Y_C2,
                        C_C1 = NULL, C_C2 = NULL, C = NULL) {
  # 检查中介变量匹配
  if (length(M_C1) != length(M_C2)) {
    stop("The number of M_C1 and M_C2 variables must match.")
  }

  if (!(Y_C1 %in% colnames(data)) || !(Y_C2 %in% colnames(data))) {
    stop("Y variables not found in the dataset.")
  }

  # 构造 Ydiff
  data$Ydiff <- data[[Y_C2]] - data[[Y_C1]]

  # 中介变量差值与中心均值
  diffs <- list()
  avgs <- list()
  for (i in seq_along(M_C1)) {
    M1 <- M_C1[i]
    M2 <- M_C2[i]

    if (!(M1 %in% colnames(data)) || !(M2 %in% colnames(data))) {
      stop(paste0("M variables for ", M1, " and ", M2, " not found in the dataset."))
    }

    diff_name <- paste0("M", i, "diff")
    avg_name <- paste0("M", i, "avg")

    diffs[[diff_name]] <- data[[M2]] - data[[M1]]

    M1_centered <- data[[M1]] - mean(data[[M1]], na.rm = TRUE)
    M2_centered <- data[[M2]] - mean(data[[M2]], na.rm = TRUE)
    avgs[[avg_name]] <- (M1_centered + M2_centered) / 2
  }

  # 被试间控制变量中心化并命名为 Cb1, Cb2, ...
  between_centered <- list()
  if (!is.null(C)) {
    for (i in seq_along(C)) {
      var <- C[i]
      if (!var %in% colnames(data)) {
        stop(paste0("Between-subject covariate ", var, " not found in the dataset."))
      }
      new_name <- paste0("Cb", i)
      between_centered[[new_name]] <- data[[var]] - mean(data[[var]], na.rm = TRUE)
    }
  }

  # 被试内控制变量处理（diff + avg），命名为 Cw1diff, Cw1avg, ...
  within_diffs <- list()
  within_avgs <- list()
  if (!is.null(C_C1) && !is.null(C_C2)) {
    if (length(C_C1) != length(C_C2)) {
      stop("The number of C_C1 and C_C2 variables must match.")
    }

    for (i in seq_along(C_C1)) {
      W1 <- C_C1[i]
      W2 <- C_C2[i]

      if (!(W1 %in% colnames(data)) || !(W2 %in% colnames(data))) {
        stop(paste0("Within-subject covariate pair ", W1, "/", W2, " not found."))
      }

      diff_name <- paste0("Cw", i, "diff")
      avg_name <- paste0("Cw", i, "avg")

      wdiff <- data[[W2]] - data[[W1]]
      wavg <- (data[[W1]] + data[[W2]]) / 2

      within_diffs[[diff_name]] <- wdiff - mean(wdiff, na.rm = TRUE)
      within_avgs[[avg_name]] <- wavg - mean(wavg, na.rm = TRUE)
    }
  }

  # 合并所有结果
  all_vars <- c(diffs, avgs, between_centered, within_diffs, within_avgs)
  data <- cbind(data, as.data.frame(all_vars))

  # 返回结果列
  cols_to_return <- c("Ydiff", names(diffs), names(avgs),
                      names(between_centered), names(within_diffs), names(within_avgs))
  return(data[, cols_to_return, drop = FALSE])
}
