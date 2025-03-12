#' @title Monte Carlo Confidence Intervals for Multiple Imputation SEM Models
#'
#' @description Computes Monte Carlo confidence intervals (MCCI) for structural equation models (SEM)
#' fitted to multiple imputed datasets. This function integrates SEM fitting across imputed datasets,
#' pools the results, and generates confidence intervals through Monte Carlo sampling.
#'
#' @details This function is designed for SEM models that require multiple imputation to handle missing data.
#' It performs the following steps:
#'
#' - **SEM Fitting**: Fits the specified SEM model to each imputed dataset using [lavaan::sem()].
#'
#' - **Pooling Results**: Combines parameter estimates and covariance matrices across imputations
#' using Rubin's rules.
#'
#' - **Monte Carlo Sampling**: Generates Monte Carlo samples based on the pooled estimates and covariance matrices,
#' and calculates confidence intervals for model parameters.
#'
#' This function supports custom estimators, handling of missing data, and precision adjustments for
#' Monte Carlo sampling. It is particularly useful for mediation analysis or complex SEM models
#' where missing data are addressed using multiple imputation.
#'
#' @param sem_model A character string specifying the SEM model syntax.
#' @param imputations A list of data frames, where each data frame represents an imputed dataset.
#' @param R An integer specifying the number of Monte Carlo samples. Default is `20000L`.
#' @param alpha A numeric vector specifying significance levels for the confidence intervals. Default is `c(0.001, 0.01, 0.05)`.
#' @param decomposition A character string specifying the decomposition method for the covariance matrix.
#' Default is `"eigen"`. Options include `"chol"`, `"eigen"`, or `"svd"`.
#' @param pd A logical value indicating whether to ensure positive definiteness of the covariance matrix. Default is `TRUE`.
#' @param tol A numeric value specifying the tolerance for positive definiteness checks. Default is `1e-06`.
#' @param seed An optional integer specifying the random seed for reproducibility. Default is `NULL`.
#' @param estimator A character string specifying the estimator for SEM fitting. Default is `"ML"` (Maximum Likelihood).
#' @param se A character string specifying the type of standard errors to compute. Default is `"standard"`.
#' @param missing A character string specifying the method for handling missing data in SEM fitting. Default is `"listwise"`.
#'
#' @return An object of class `semmcci` containing:
#' - `call`: The matched function call.
#' - `args`: A list of input arguments.
#' - `thetahat`: The pooled parameter estimates.
#' - `thetahatstar`: Monte Carlo samples for parameter estimates.
#' - `fun`: The name of the function (`"MCMI2"`).
#'
#' @seealso [lavaan::sem()], [semmcci::MC()], [semmcci::MCStd()]
#'
#' @examples
#' # Example SEM model
#' sem_model <- "
#'   Ydiff ~ b1 * M1diff + cp * 1
#'   M1diff ~ a1 * 1
#'   indirect := a1 * b1
#'   total := cp + indirect
#' "
#'
#' # Example imputed datasets
#' imputations <- list(
#'   data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
#'   data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
#' )
#'
#' # Compute Monte Carlo confidence intervals
#' result <- MCMI2(
#'   sem_model = sem_model,
#'   imputations = imputations,
#'   R = 1000,
#'   alpha = c(0.05, 0.01),
#'   seed = 123
#' )
#' @import semmcci
#' @export

MCMI2 <- function(sem_model,
                 imputations,
                 R = 20000L,
                 alpha = c(0.001, 0.01, 0.05),
                 decomposition = "eigen",
                 pd = TRUE,
                 tol = 1e-06,
                 seed = NULL,
                 estimator = "ML",
                 se = "standard",
                 missing = "listwise") {
  # 验证输入
  stopifnot(
    is.character(sem_model),
    is.list(imputations) && all(sapply(imputations, is.data.frame))
  )

  # 使用每个插补数据集重新拟合模型
  fits <- lapply(imputations, function(data) {
    lavaan::sem(
      model = sem_model,
      data = data,
      estimator = estimator,
      se = se,
      missing = missing
    )
  })

  # 提取系数和协方差矩阵
  coefs <- lapply(fits, lavaan::coef)
  vcovs <- lapply(fits, lavaan::vcov)

  # 使用 MICombine 合并插补结果
  pooled <- MICombineWrapper(
    coefs = coefs,
    vcovs = vcovs,
    M = length(coefs),
    k = length(coefs[[1]]),
    adj = TRUE
  )
  scale <- pooled$total
  location <- pooled$est

  # 设置 Monte Carlo 采样
  if (!is.null(seed)) {
    set.seed(seed)
  }
  thetahatstar <- ThetaHatStarWrapper(
    R = R,
    scale = scale,
    location = location,
    decomposition = decomposition,
    pd = pd,
    tol = tol
  )
  thetahatstar_orig <- thetahatstar$thetahatstar
  decomposition <- thetahatstar$decomposition

  # 更新估计值
  thetahat <- ThetaHatWrapper(
    object = fits[[1]],
    est = colMeans(
      do.call(
        what = "rbind",
        args = lapply(fits, function(fit) fit@ParTable$est)
      )
    )
  )

  # 处理定义参数
  thetahatstar <- MCDefWrapper(
    object = fits[[1]],
    thetahat = thetahat,
    thetahatstar_orig = thetahatstar_orig
  )

  # 使用第一个 fits 对象作为 `lav` 对象
  lav <- fits[[1]]

  # 输出结果
  out <- list(
    call = match.call(),
    args = list(
      lav = lav,
      sem_model = sem_model,
      imputations = imputations,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol,
      seed = seed,
      pooled = pooled
    ),
    thetahat = thetahat,
    thetahatstar = thetahatstar,
    fun = "MCMI"
  )
  class(out) <- c("semmcci", class(out))
  return(out)
}
