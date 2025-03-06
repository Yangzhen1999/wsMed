#' @title Prepare Data with Missing Values for Mediation Analysis
#'
#' @description Handles missing values in the dataset through multiple imputation
#' and prepares the imputed datasets for within-subject mediation analysis. The function
#' imputes missing data, processes each imputed dataset, and provides diagnostics for the imputation process.
#'
#' @details This function is designed to preprocess datasets with missing values for mediation analysis.
#' It performs the following steps:
#'
#' - **Multiple Imputation**: Uses specified imputation methods (e.g., predictive mean matching) to generate
#' `m` imputed datasets.
#'
#' - **Data Preparation**: Applies [PrepareData()] to each of the `m` imputed datasets to calculate difference scores
#' and centered averages for mediators and the outcome variable.
#'
#' - **Imputation Diagnostics**: Provides summary diagnostics for the imputation process, including
#' information about missing data patterns and convergence.
#'
#' This function integrates imputation and data preparation, ensuring that the resulting datasets
#' are ready for subsequent mediation analysis.
#'
#' @param data_missing A data frame containing the raw dataset with missing values.
#' @param m An integer specifying the number of imputations to perform. Default is `5`.
#' @param method A character string specifying the imputation method. Default is `"pmm"`
#' (predictive mean matching). Other methods supported by [mice()] can be used.
#' @param seed An integer specifying the random seed for reproducibility. Default is `123`.
#' @param M_before A character vector of column names representing mediators "before" the intervention.
#' @param M_after A character vector of column names representing mediators "after" the intervention.
#' Must match the length of `M_before`.
#' @param Y_before A character string representing the column name of the outcome variable "before" the intervention.
#' @param Y_after A character string representing the column name of the outcome variable "after" the intervention.
#'
#' @return A list containing:
#' - `processed_data_list`: A list of `m` data frames, each representing an imputed and processed dataset,
#' ready for within-subject mediation analysis.
#' - `imputation_summary`: A summary of the imputation process, including diagnostics and convergence information.
#'
#' @seealso [PrepareData()], [ImputeData()], [wsMed()]
#'
#' @examples
#' # Example dataset with missing values
#' data(example_data)
#' set.seed(123) # 确保结果可重复
#' example_dataN <- mice::ampute(
#'    data = example_data,       # 输入完整数据
#'    prop = 0.1,      # 缺失值比例 (20%)
#'    )$amp
#'
#' # Prepare the dataset with multiple imputations
#' prepared_missing_data <- PrepareMissingData(
#'   data_missing = example_dataN,
#'   m = 5,
#'   method = "pmm",
#'   M_before = c("A2", "B2"),
#'   M_after = c("A1", "B1"),
#'   Y_before = "C2",
#'   Y_after = "C1",
#' )
#'
#' # Access processed datasets
#' processed_data_list <- prepared_missing_data$processed_data_list
#' imputation_summary <- prepared_missing_data$imputation_summary
#'
#' @export

PrepareMissingData <- function(data_missing,
                               m = 5,
                               method = "pmm",
                               seed = 123,
                               M_before,
                               M_after,
                               Y_before,
                               Y_after) {
  #  检查 M_before 和 M_after 长度是否匹配
  if (length(M_before) != length(M_after)) {
    stop("Error in PrepareMissingData: M_before and M_after must have the same length.")
  }

  #  确保 Y_before 和 Y_after 存在
  if (!(Y_before %in% colnames(data_missing)) || !(Y_after %in% colnames(data_missing))) {
    stop("Error in PrepareMissingData: Y_before or Y_after is missing in the dataset.")
  }

   # Step 1: 插补数据
  imputed_result <- ImputeData(
    data_missing = data_missing,
    m = m,
    method = method,
    seed = seed
  )

  # 获取插补后的数据集列表
  imputed_data_list <- imputed_result$imputed_data_list

  # Step 2: 对每个插补数据集进行数据处理
  processed_data_list <- lapply(imputed_data_list, function(imputed_data) {
    PrepareData(
      data = imputed_data,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after
    )
  })

  # 返回处理后的数据集列表
  return(list(
    processed_data_list = processed_data_list,
    imputation_summary = imputed_result$summary  # 插补过程的诊断信息
  ))
}
