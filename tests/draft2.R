test_that("draft", {
  skip("This test is skipped for demonstration purposes")

    # 定义验证函数
ValidateStep4Logic <- function(mi, premi, predata, M_before, M_after, Y_before, Y_after) {
  m <- mi$m # 插补次数
  for (i in 1:m) {
    cat("\n=== 开始处理插补数据集", i, "===\n")

    # 从 mi 中提取第 i 个插补数据集
    imputed_data <- mice::complete(mi, action = i)
    cat("提取插补数据集成功。\n")
    cat("插补数据集行数：", nrow(imputed_data), "\n")

    # 对插补数据集应用 PrepareData
    processed_data <- PrepareData(imputed_data, M_before, M_after, Y_before, Y_after)
    cat("PrepareData 处理成功。\n")
    cat("处理后数据行数：", nrow(processed_data), "\n")

    # 验证行数一致性
    if (nrow(processed_data) != nrow(predata)) {
      stop(paste("Error: Processed data for imputation", i, "has incorrect number of rows."))
    } else {
      cat("行数一致。\n")
    }

    # 替换 premi 中的对应数据集
    for (col_name in colnames(processed_data)) {
      cat("正在处理列：", col_name, "\n")
      # 如果列不在 premi$imp 中，初始化列表
      if (!col_name %in% names(premi$imp)) {
        premi$imp[[col_name]] <- vector("list", m)
        cat("新增列：", col_name, "\n")
      }

      # 检查替换的数据长度
      if (length(processed_data[[col_name]]) != nrow(predata)) {
        stop(paste("Error: Column", col_name, "in processed_data has incorrect length for imputation", i))
      }

      # 替换数据
      premi$imp[[col_name]][[i]] <- processed_data[[col_name]]
      cat("列", col_name, "替换成功。\n")
    }
  }
  cat("\n=== 所有插补数据处理完成 ===\n")
  return(premi)
}
# Step 1: 使用 mice 进行插补生成 mi
mi <- mice::mice(data = eaN, m = 5L, seed = 123)
# Step 2: 使用 PrepareData 处理原始数据
predata <- PrepareData(data, M_before = c("A2", "B2"),
                       M_after = c("A1", "B1"),
                       Y_before = "C2",
                       Y_after = "C1")
# Step 3: 基于 PrepareData 的结果重新生成 premi
premi <- mice::mice(data = predata, m = 5L, seed = 123)

# 示例调用
validated_premi <- ValidateStep4Logic(
  mi = mi,
  premi = premi,
  predata = predata,
  M_before = c("A2", "B2"),
  M_after = c("A1", "B1"),
  Y_before = "D2",
  Y_after = "D1"
)


mi <- mice::mice(data = eaN, m = 5L, seed = 123)

# Step 2: 使用 PrepareData 处理原始数据
predata <- PrepareData(eaN, M_before = c("A2", "B2"),
                       M_after = c("A1", "B1"),
                       Y_before = "D2",
                       Y_after = "D1")

# Step 3: 基于 PrepareData 的结果重新生成 premi
premi <- mice::mice(data = predata,m = 5L, seed = 123)
mi$imp
# Step 4: 对每个插补数据集应用 PrepareData 并替换 premi 中的数据集


  # 获取插补后的数据集列表
  imputed_data_list <- imputed_result$imputed_data_list

  # 对每个插补数据集进行数据处理
  processed_data_list <- lapply(imputed_data_list, function(imputed_data) {
    PrepareData(
      data = imputed_data,
      M_before = c("A2", "B2"),
      M_after = c("A1", "B1"),
      Y_before = "D2",
      Y_after = "D1"
    )
  })

  result <- MCMI(
    sem_model = results$sem_model,
    imputations = processed_data_list,
    R = 20000L,
    alpha = c(0.001, 0.01, 0.05),
    decomposition = "eigen",
    pd = TRUE,
    tol = 1e-06,
    seed = 123
  )
  result$args$lav
    result2 <- MCStd(result, alpha = 0.05)


library(semmcci)
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




)})



