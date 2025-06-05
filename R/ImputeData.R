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

ImputeData <- function(data_missing,
                       m = 5,
                       method = "pmm",
                       seed = 123,
                       predictorMatrix = NULL) {
  data_missing[data_missing == -999] <- NA

  if (!is.data.frame(data_missing)) stop("Input data must be a data frame.")
  if (!all(sapply(data_missing, function(x) is.numeric(x) || is.factor(x)))) {
    stop("All columns must be numeric or factor.")
  }

  # 自动构建 predictorMatrix
  if (is.null(predictorMatrix)) {
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.1)
  }

  # 扩展 method 为每列一项
  if (is.null(method)) {
    method <- sapply(data_missing, function(x) if (is.numeric(x)) "pmm" else "logreg")
  } else if (length(method) == 1 && is.character(method)) {
    method <- rep(method, ncol(data_missing))
    names(method) <- names(data_missing)
  } else if (length(method) != ncol(data_missing)) {
    stop("Length of 'method' must be 1 or equal to number of variables.")
  }

  # 执行插补
  imp <- mice::mice(
    data_missing,
    m = m,
    method = method,
    seed = seed,
    predictorMatrix = predictorMatrix
  )

  imputed_data_list <- mice::complete(imp, "all")
  imputed_data_list <- lapply(imputed_data_list, as.data.frame)

  return(list(
    mids = imp,
    imputed_data_list = imputed_data_list,
    summary = summary(imp)
  ))
}
