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
#' (predictive mean matching).
#' @param seed An integer specifying the random seed for reproducibility. Default is `123`.
#' @param M_C1 A character vector of column names representing mediators "before" the intervention.
#' @param M_C2 A character vector of column names representing mediators "after" the intervention.
#' Must match the length of `M_C1`.
#' @param Y_C1 A character string representing the column name of the outcome variable "before" the intervention.
#' @param Y_C2 A character string representing the column name of the outcome variable "after" the intervention.
#' @param sem_model A character string specifying the SEM model syntax.
#' @param Na A character string specifying the missing data handling strategy. Currently, only `"MI"` (Multiple Imputation) is supported. Default is `"MI"`.
#' @param R An integer specifying the number of Monte Carlo samples. Default is `20000L`.
#' @param alpha A numeric vector specifying significance levels for the confidence intervals. Default is `c(0.001, 0.01, 0.05)`.
#' @param decomposition A character string specifying the decomposition method for the covariance matrix.
#' Default is `"eigen"`. Options include `"chol"`, `"eigen"`, or `"svd"`.
#' @param pd A logical value indicating whether to ensure positive definiteness of the covariance matrix. Default is `TRUE`.
#' @param tol A numeric value specifying the tolerance for positive definiteness checks. Default is `1e-06`.
#' @param C_C1 Character vector of within-subject control variable names (condition 1).
#' @param C_C2 Character vector of within-subject control variable names (condition 2).
#' @param C Character vector of between-subject control variable names.
#' @param W A character vector specifying the names of moderator variable(s)
#'   that are used to generate interaction terms with mediators.
#'
#' @return A `semmcci` object containing the Monte Carlo analysis results, including:
#' - `thetahat`: The pooled parameter estimates.
#' - `thetahatstar`: Monte Carlo samples for parameter estimates.
#' - Other components specific to the `semmcci` class.
#'
#' @seealso [PrepareMissingData()], [MCMI2()], [wsMed()]
#' @keywords internal

RunMCMIAnalysis <- function(data_missing,
                            m = 5,
                            method = "pmm",
                            seed = 123,
                            M_C1,
                            M_C2,
                            Y_C1,
                            Y_C2,
                            C_C1 = NULL,
                            C_C2 = NULL,
                            C = NULL,
                            W = NULL,  # <-- 添加对 W 的支持
                            sem_model,
                            Na = "MI",
                            R = 20000L,
                            alpha = c(0.001, 0.01, 0.05),
                            decomposition = "eigen",
                            pd = TRUE,
                            tol = 1e-06) {

  mi_result <- NULL
  first_imputed_data <- NULL

  if (Na == "MI") {
    prepared_data <- PrepareMissingData(
      data_missing = data_missing,
      m = m,
      method = method,
      seed = seed,
      M_C1 = M_C1,
      M_C2 = M_C2,
      Y_C1 = Y_C1,
      Y_C2 = Y_C2,
      C_C1 = C_C1,
      C_C2 = C_C2,
      C = C,
      W = W  # <-- 传递调节变量
    )

    processed_data_list <- prepared_data$processed_data_list
    first_imputed_data <- processed_data_list[[1]]

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

  return(list(
    mc_result = mi_result,
    first_imputed_data = first_imputed_data
  ))
}
