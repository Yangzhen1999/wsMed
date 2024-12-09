WSMed <- function(data,
                  M_before,
                  M_after,
                  Y_before,
                  Y_after,
                  form = "P",
                  standardized = FALSE,
                  Na = "DE",
                  bootstrap = 1000,
                  iseed = 123,
                  se = "standard",
                  R = 20000L,  # Monte Carlo 重复次数
                  alpha = c(0.001, 0.01, 0.05),  # 显著性水平
                  m = 5,  # 插补次数
                  method = "pmm",  # 插补方法
                  decomposition = "eigen",
                  pd = TRUE,
                  tol = 1e-06,
                  seed = 123,
                  alphastd = 0.05) {


  if (Na == "DE") {
    data <- na.omit(data)}

  # Step 1: 数据预处理
  prepared_data <- PrepareData(data = data,
                               M_before = M_before,
                               M_after = M_after,
                               Y_before = Y_before,
                               Y_after = Y_after)

  # Step 2: 构建模型
  # P is parallel mediation, CN is chained mediation, CP/PC is parallel + chain mediation
  if (form == "P") {
    sem_model <- GenerateModelP(prepared_data)
  } else if (form == "CP") {
    sem_model <- GenerateModelCP(prepared_data)
  } else if (form == "PC") {
    sem_model <- GenerateModelPC(prepared_data)
  } else if (form == "CN") {
    sem_model <- GenerateModelCN(prepared_data)
  } else {
    stop("Invalid 'form' parameter. Use 'CP', 'PC' or 'CN'.")
  }

  # fit the model
  if (Na == "DE") {
    # 删除缺失值的模型拟合
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      se = se,
      bootstrap = bootstrap,
      iseed = iseed
    )
  } else if (Na == "FIML") {
    # 使用 FIML 方法处理缺失值
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      missing = "fiml",
    )
  } else if (Na == "MI") {
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
    )
    if (!inherits(fit, "lavaan")) {
      stop("Model fitting failed. Check your input model and data.")
    }
  }
  cat("fit\n")

  # Monte Carlo
  mi_result <- NULL
  fiml_result <- NULL
  if (Na == "MI") {
    # Step 4: MCMI 分析（可选）
    mi_result <- RunMCMIAnalysis(
      data_missing = data,
      m = m,
      method = method,
      seed = seed,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after,
      sem_model = sem_model,
      Na = Na,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol
    )
  }
  if (Na == "FIML"){
    fiml_result <- MC(fit,
                      R = R,
                      alpha = alpha)
  }

  # Step 5: 标准化结果
  std_result <- NULL
  std_mi_result <- NULL
  std_fiml_result <- NULL

  if (standardized){
    if (Na == "DE") {
      std_result <- standardizedSolution_boot_ci(fit)
    }
    if (Na == "MI") {
      std_mi_result <- semmcci::MCStd(mi_result, alpha = alphastd)
    }
    if (Na == "FIML") {
      std_fiml_result <- semmcci::MCStd(fiml_result, alpha = alphastd)
    }
  }
  # Step 6: 返回结果
  return(list(
    prepared_data = prepared_data,
    model_summary = summary(fit, fit.measures = TRUE, standardized = standardized),
    lavaan_fit = fit,
    sem_model = sem_model,
    mi_result = mi_result,
    fiml_result = fiml_result,
    std_result = std_result,
    std_mi_result = std_mi_result,
    std_fiml_result = std_fiml_result
  ))
}
