test_that("RunMCMIAnalysis performs MI and Monte Carlo correctly", {
  set.seed(123)
  data_with_na <- mice::ampute(data = example_data, prop = 0.1)$amp

  sem_model <- "
    Ydiff ~ cp * 1 + b1 * M1diff
    M1diff ~ a1 * 1
    indirect := a1 * b1
    total := cp + indirect
  "

  result <- RunMCMIAnalysis(
    data_missing = data_with_na,
    m = 3,
    method = "pmm",
    seed = 123,
    M_C1 = c("A2", "B2"),
    M_C2 = c("A1", "B1"),
    Y_C1 = "C2",
    Y_C2 = "C1",
    sem_model = sem_model,
    R = 1000,
    alpha = c(0.05, 0.01)
  )

  # 检查主结构
  expect_true(is.list(result), info = "RunMCMIAnalysis 应该返回一个列表")
  expect_true(all(c("mc_result", "first_imputed_data") %in% names(result)))

  # 检查 Monte Carlo 输出
  mc <- result$mc_result
  expect_s3_class(result$mc_result, "semmcci")
  expect_true(is.list(mc$thetahat))
  expect_true(is.matrix(mc$thetahatstar))
  expect_equal(nrow(mc$thetahatstar), 1000)

  # 参数名称一致性
  param_names <- names(mc$thetahat$est)
  expect_true(all(param_names %in% colnames(mc$thetahatstar)))

  # 参数估计值合理性
  expect_true(all(is.finite(mc$thetahat$est)))
  expect_true(all(mc$thetahat$est > -100 & mc$thetahat$est < 100)) # 防止异常爆炸值

  # 标准误范围合理
  se_vals <- mc$thetahat$se
  expect_true(all(is.finite(se_vals)))
  expect_true(all(se_vals >= 0))

  # 检查是否包含定义参数
  expect_true(all(c("indirect", "total") %in% names(mc$thetahat$est)))

  # 检查插补后的第一组数据格式
  expect_s3_class(result$first_imputed_data, "data.frame")
  expect_true(all(c("Ydiff", "M1diff", "M2diff", "M1avg", "M2avg") %in% names(result$first_imputed_data)))
})

