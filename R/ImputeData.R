#' @title Impute Missing Data Using Multiple Imputation
#'
#' @description The `ImputeData` function performs multiple imputation on a data frame with missing values using the \code{mice} package. It handles missing data by creating multiple imputed datasets based on a specified imputation method and returns a list of completed data frames.
#'
#' @details This function replaces specified missing value placeholders (e.g., \code{-999}) with \code{NA}, and then applies the multiple imputation by chained equations (MICE) procedure to generate multiple imputed datasets. It supports flexible imputation methods and allows for specifying a custom predictor matrix.
#'
#' @param data_missing A data frame containing missing values to be imputed. The function replaces values coded as \code{-999} with \code{NA} before imputation.
#' @param m An integer specifying the number of imputed datasets to generate.
#' @param method A character string specifying the imputation method. Default is \code{"pmm"} (predictive mean matching).
#' @param seed An integer for setting the random seed to ensure reproducibility. Default is \code{123}.
#' @param predictorMatrix An optional matrix specifying the predictor structure for the imputation model. Default is \code{NULL}, meaning that the function will use the default predictor matrix created by \code{mice}.
#'
#' @return A list of \code{m} imputed data frames.
#'
#' @author
#' Wendie Yang, Shufai Cheung
#'
#' @examples
#' # Example data with missing values
#' data <- data.frame(
#'   M1 = c(rnorm(99), rep(NA, 1)),
#'   M2 = c(rnorm(99), rep(NA, 1)),
#'   Y1 = rnorm(100),
#'   Y2 = rnorm(100)
#' )
#' # Perform multiple imputation
#' imputed_data_list <- ImputeData(data, m = 5)
#' # Display the first imputed dataset
#' head(imputed_data_list[[1]])
#'
#' @importFrom mice mice complete
#' @export

ImputeData<- function(data_missing, m, method = "pmm", seed = 123, predictorMatrix = NULL) {
  data_missing[data_missing == -999] <- NA

  # 检查数据是否包含至少两个非常数列（mice 需要至少两个变量）
  valid_vars <- sapply(data_missing, function(col) length(unique(na.omit(col))) > 1)

  if (sum(valid_vars) < 2) {
    stop("Error in ImputeData: Too few valid variables after removing constants or collinear variables.")
  }
  # if don't provide predictorMatrix，use NULL
  if (is.null(predictorMatrix)) {
    imp <- mice(data_missing, m = m, method = method, seed = seed)
  } else {
    imp <- mice(data_missing, m = m, method = method, seed = seed, predictorMatrix = predictorMatrix)
  }

  imputed_data_list <- complete(imp, "all")
  imputed_data_list <- lapply(imputed_data_list, as.data.frame)
  return(imputed_data_list)
}
ImputeData <- function(data_missing, m = 5, method = "pmm", seed = 123, predictorMatrix = NULL) {
  # 替换 -999 为 NA
  data_missing[data_missing == -999] <- NA

  # 输入检查
  if (!is.data.frame(data_missing)) stop("Input data must be a data frame.")
  if (!all(sapply(data_missing, function(x) is.numeric(x) || is.factor(x)))) stop("All columns must be numeric or factor.")

  # 动态生成 predictorMatrix
  if (is.null(predictorMatrix)) {
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.1)
  }

  # 动态选择方法
  if (is.null(method)) {
    method <- ifelse(sapply(data_missing, is.numeric), "pmm", "logreg")
  }

  # 插补数据
  imp <- mice::mice(data_missing, m = m, method = method, seed = seed, predictorMatrix = predictorMatrix)

  # 获取插补结果列表
  imputed_data_list <- mice::complete(imp, "all")
  imputed_data_list <- lapply(imputed_data_list, as.data.frame)

  # 生成诊断信息
  summary_imp <- summary(imp)

  return(list(
    imputed_data_list = imputed_data_list,  # 插补后的数据列表
    summary = summary_imp                 # 插补结果的汇总信息
  ))
}
