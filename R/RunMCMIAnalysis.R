#' @title Perform Monte Carlo Analysis with Multiple Imputation for SEM Models
#'
#' @description Automates the process of handling missing data with multiple imputation
#' and conducting Monte Carlo confidence interval (MCCI) analysis for structural equation modeling (SEM).
#' The function prepares the imputed datasets, fits the specified SEM model, and generates Monte Carlo
#' confidence intervals for the model parameters.
#'
#' @details This function streamlines the workflow for SEM analysis with missing data by integrating:
#'
#' - **Multiple Imputation**: Uses [PrepareMissingData()] to impute missing values and calculate the necessary
#' difference and centered average scores for mediators and the outcome variable.
#'
#' - **SEM Fitting and Monte Carlo Analysis**: Uses [MCMI2()] to fit the specified SEM model to the imputed datasets,
#' pool the parameter estimates, and compute Monte Carlo confidence intervals.
#'
#' This function is suitable for mediation or other SEM analyses where missing data need to be addressed
#' through multiple imputation and Monte Carlo methods for enhanced precision.
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
#' @param sem_model A character string specifying the SEM model syntax.
#' @param Na A character string specifying the missing data handling strategy. Currently, only `"MI"` (Multiple Imputation) is supported. Default is `"MI"`.
#' @param R An integer specifying the number of Monte Carlo samples. Default is `20000L`.
#' @param alpha A numeric vector specifying significance levels for the confidence intervals. Default is `c(0.001, 0.01, 0.05)`.
#' @param decomposition A character string specifying the decomposition method for the covariance matrix.
#' Default is `"eigen"`. Options include `"chol"`, `"eigen"`, or `"svd"`.
#' @param pd A logical value indicating whether to ensure positive definiteness of the covariance matrix. Default is `TRUE`.
#' @param tol A numeric value specifying the tolerance for positive definiteness checks. Default is `1e-06`.
#'
#' @return A `semmcci` object containing the Monte Carlo analysis results, including:
#' - `thetahat`: The pooled parameter estimates.
#' - `thetahatstar`: Monte Carlo samples for parameter estimates.
#' - Other components specific to the `semmcci` class.
#'
#' @seealso [PrepareMissingData()], [MCMI2()], [WsMed()]
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
#'
#' # Example SEM model
#' sem_model <- "
#'   Ydiff ~ cp * 1 + b1 * M1diff
#'   M1diff ~ a1 * 1
#'   indirect := a1 * b1
#'   total := cp + indirect
#' "
#'
#' # Perform Monte Carlo analysis with multiple imputation
#' result <- RunMCMIAnalysis(
#'   data_missing =  example_dataN,
#'   m = 5,
#'   method = "pmm",
#'   seed = 123,
#'   M_before = c("A2", "B2"),
#'   M_after = c("A1", "B1"),
#'   Y_before = "C2",
#'   Y_after = "C1",
#'   sem_model = sem_model,
#'   R = 1000,
#'   alpha = c(0.05, 0.01)
#' )
#'
#' @export

RunMCMIAnalysis <- function(data_missing,
                            m = 5,
                            method = "pmm",
                            seed = 123,
                            M_before,
                            M_after,
                            Y_before,
                            Y_after,
                            sem_model,
                            Na = "MI",
                            R = 20000L,
                            alpha = c(0.001, 0.01, 0.05),
                            decomposition = "eigen",
                            pd = TRUE,
                            tol = 1e-06) {
  # Step 1: 初始化结果变量
  mi_result <- NULL

  # Step 2: 检查是否启用 Monte Carlo (MC)
  if (Na == "MI") {
    # 插补并处理数据
    prepared_data <- PrepareMissingData(
      data_missing = data_missing,
      m = m,
      method = method,
      seed = seed,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after
    )

    # 获取处理后的插补数据集列表
    processed_data_list <- prepared_data$processed_data_list

    # 调用 MCMI2 进行 Monte Carlo 分析
    mi_result <- MCMI2(
      sem_model = sem_model,
      imputations = processed_data_list,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol,
      seed = seed
    )
  } else {
    stop("MI is set to FALSE. Currently, only MI = TRUE is supported.")
  }

  # 返回分析结果
  return(mi_result)
}
