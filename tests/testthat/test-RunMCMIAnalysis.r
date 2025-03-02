test_that("RunMCMIAnalysis correctly handles multiple imputation and Monte Carlo analysis", {
  # 1. 构造带有缺失值的示例数据
  set.seed(123)
  example_dataN <- mice::ampute(
    data = example_data,  # 输入完整数据
    prop = 0.1  # 缺失值比例 (10%)
  )$amp

  # 2. 定义 SEM 结构方程模型
  sem_model <- "
    Ydiff ~ cp * 1 + b1 * M1diff
    M1diff ~ a1 * 1
    indirect := a1 * b1
    total := cp + indirect
  "

  # 3. 运行 `RunMCMIAnalysis` 进行 Monte Carlo 多重插补分析
  result <- RunMCMIAnalysis(
    data_missing = example_dataN,
    m = 3,  # 设定较小的插补次数以加快测试
    method = "pmm",
    seed = 123,
    M_before = c("A2", "B2"),
    M_after = c("A1", "B1"),
    Y_before = "C2",
    Y_after = "C1",
    sem_model = sem_model,
    R = 1000,  # Monte Carlo 采样次数
    alpha = c(0.05, 0.01)
  )
  # **测试返回的结果结构**
  expect_true(is.list(result), info = "RunMCMIAnalysis 应该返回一个列表")
  expect_true("thetahat" %in% names(result), info = "结果应包含 'thetahat'")
  expect_true("thetahatstar" %in% names(result), info = "结果应包含 'thetahatstar'")

  # **检查 Monte Carlo 估计值是否存在**
  expect_true(is.numeric(result$thetahat$est), info = "thetahat$est 应该是数值向量")

  # **检查 Monte Carlo 参数名称是否匹配**
  expected_params <- c("b1", "cp", "a1", "Ydiff~~Ydiff","M1diff~~M1diff","indirect", "total")
  actual_params <- names(result$thetahat$est)
  missing_params <- setdiff(expected_params, actual_params)
  expect_true(length(missing_params) == 0, info = paste("缺少参数:", paste(missing_params, collapse = ", ")))

  # **检查 Monte Carlo 采样结果**
  expect_true(is.matrix(result$thetahatstar), info = "thetahatstar 应该是一个矩阵")
  expect_equal(ncol(result$thetahatstar), length(expected_params), info = "thetahatstar 列数应匹配参数数量")
  expect_equal(nrow(result$thetahatstar), 1000, info = "thetahatstar 行数应为 Monte Carlo 采样次数")

  # **检查参数估计值范围**
  expect_true(all(result$thetahat$est > -10 & result$thetahat$est < 10), 
              info = "所有参数估计值应在合理范围内")
})
