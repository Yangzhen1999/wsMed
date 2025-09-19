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
                       m      = 5,
                       method = "pmm",
                       seed   = 123,
                       predictorMatrix = NULL) {


  if (!is.data.frame(data_missing))
    stop("Input data must be a data.frame")   # ← 提到最前


  `%||%` <- function(a,b) if (is.null(a)) b else a
  nullfile <- if (.Platform$OS.type == "windows") "NUL" else "/dev/null"

  ## ---- 0 预处理 --------------------------------------------------------
  data_missing[data_missing == -999] <- NA
  if (!is.data.frame(data_missing))
    stop("Input data must be a data.frame")
  if (!all(vapply(data_missing,
                  function(z) is.numeric(z) || is.factor(z),
                  logical(1))))
    stop("All columns must be numeric or factor")

  ## ---- 1 predictorMatrix ----------------------------------------------
  if (is.null(predictorMatrix))
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.10)

  ## ---- 2 method 向量化 -------------------------------------------------
  if (is.null(method)) {
    method <- vapply(data_missing, function(z) {
      if (is.numeric(z)) {
        "pmm"                   # 连续变量用 PMM
      } else if (is.factor(z)) {
        if (nlevels(z) == 2) {
          "logreg"              # 二分类因子 → 逻辑回归插补
        } else {
          "polyreg"             # 多分类因子 → 多项逻辑回归插补
        }
      } else {
        stop("Unsupported variable type for imputation: must be numeric or factor.")
      }
    }, character(1))
  } else if (length(method) == 1L) {
    method <- rep(method, ncol(data_missing))
  } else if (length(method) != ncol(data_missing)) {
    stop("Length of 'method' must be 1 or equal to number of variables")
  }
  names(method) <- names(data_missing)


  ## ---- 3 完全静音调用 mice ---------------------------------------------
  imp <- local({
    zz <- file(nullfile, open = "wt")
    sink(zz)                      # stdout
    sink(zz, type = "message")    # stderr
    on.exit({ sink(type = "message"); sink(); close(zz) }, add = TRUE)

    suppressWarnings(
      suppressMessages(
        mice::mice(
          data_missing,
          m               = m,
          method          = method,
          seed            = seed,
          predictorMatrix = predictorMatrix,
          printFlag       = FALSE)))
  })

  ## ---- 4 完全静音 summary(mids) ---------------------------------------
  summary_imp <- local({
    zz <- file(nullfile, open = "wt")
    sink(zz)
    sink(zz, type = "message")
    on.exit({ sink(type = "message"); sink(); close(zz) }, add = TRUE)

    summary(imp)        # 返回对象，但所有打印被吞掉
  })

  ## ---- 5 返回 ----------------------------------------------------------
  imputed_list <- lapply(mice::complete(imp, "all"), as.data.frame)

  list(
    mids              = imp,            # 静默 mids 对象
    imputed_data_list = imputed_list,   # data.frame 列表
    summary           = summary_imp     # summary 结果（无控制台输出）
  )
}


