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

    # 调用 MCMI 进行 Monte Carlo 分析
    mi_result <- MCMI(
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
