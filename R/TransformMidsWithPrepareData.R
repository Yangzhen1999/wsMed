#' @title Apply PrepareData to Imputed Datasets and Return New MIDS Object
#'
#' @description
#' This function applies the \code{PrepareData()} preprocessing step to each imputed dataset in a \code{mids} object
#' and returns a new \code{mids} object with the transformed data. It is designed for use in within-subject mediation analysis
#' pipelines when working with multiply imputed data.
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Extracts all imputed datasets from the original \code{mids} object.
#'   \item Applies \code{PrepareData()} to each imputed dataset using the specified within-subject mediator and outcome variables.
#'   \item Combines all processed datasets into a long format and reconstructs a new \code{mids} object via \code{mice::as.mids()}.
#' }
#' This enables subsequent analyses to operate on a version of the multiply imputed data where difference scores and averages
#' have already been computed.
#'
#' @param mids_obj A \code{mids} object created by the \code{mice} package, containing multiply imputed datasets.
#' @param M_C1 A character vector specifying the names of mediator variables under Condition 1 (e.g., pre-test).
#' @param M_C2 A character vector specifying the names of mediator variables under Condition 2 (e.g., post-test).
#' @param Y_C1 A character string specifying the outcome variable under Condition 1.
#' @param Y_C2 A character string specifying the outcome variable under Condition 2.
#'
#' @return A new \code{mids} object where each imputed dataset has been processed using \code{PrepareData()}.
#' @keywords internal

TransformMidsWithPrepareData <- function(mids_obj, M_C1, M_C2, Y_C1, Y_C2) {
  # Step 1: 提取插补数据列表
  imputed_list <- mice::complete(mids_obj, action = "all")

  # Step 2: 对每个数据集做 PrepareData()
  transformed_list <- lapply(imputed_list, function(dat) {
    PrepareData(
      data = dat,
      M_C1 = M_C1,
      M_C2 = M_C2,
      Y_C1 = Y_C1,
      Y_C2 = Y_C2
    )
  })

  # Step 3: 合并成 long format 数据
  long_data <- do.call(rbind, transformed_list)
  long_data$.imp <- rep(1:length(transformed_list), each = nrow(transformed_list[[1]]))
  long_data$.id <- rep(1:nrow(transformed_list[[1]]), times = length(transformed_list))

  # Step 4: 用 mice::as.mids 转换为新的 mids 对象
  new_mids <- mice::as.mids(long_data)

  return(new_mids)
}
