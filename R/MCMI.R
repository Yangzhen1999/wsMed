MCMI <- function(sem_model,
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
  pooled <- semmcci:::.MICombine(
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
  thetahatstar <- semmcci:::.ThetaHatStar(
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
  thetahat <- semmcci:::.ThetaHat(
    object = fits[[1]],
    est = colMeans(
      do.call(
        what = "rbind",
        args = lapply(fits, function(fit) fit@ParTable$est)
      )
    )
  )

  # 处理定义参数
  thetahatstar <- semmcci:::.MCDef(
    object = fits[[1]],
    thetahat = thetahat,
    thetahatstar_orig = thetahatstar_orig
  )

  # 输出结果
  out <- list(
    call = match.call(),
    args = list(
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
