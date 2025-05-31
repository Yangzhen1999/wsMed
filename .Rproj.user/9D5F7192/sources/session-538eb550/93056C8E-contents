test_that("run_mc_mediation works with intercept-only mediation model", {
  library(lavaan)

  # 模拟数据
  set.seed(123)
  n <- 100
  M1diff <- rnorm(n, mean = 2, sd = 1)
  Ydiff <- 0.5 * M1diff + rnorm(n, sd = 1)
  dat <- data.frame(M1diff = M1diff, Ydiff = Ydiff)

  # 模型定义
  model <- "
    Ydiff ~ cp*1 + b1*M1diff
    M1diff ~ a1*1
    M1diff ~~ M1diff
    indirect  := a1 * b1
    direct := cp
    total := cp + a1 * b1
  "

  # 拟合模型
  fit <- lavaan::sem(model, data = dat)

  # 执行函数（同时请求标准化和非标准化）
  result <- run_mc_mediation(
    fit = fit,
    data = dat,
    standardized = TRUE,
    R = 500,      # 测试用小规模模拟
    seed = 123
  )

  # 测试输出结构
  expect_type(result, "list")
  expect_true("unstd_result" %in% names(result))
  expect_true("unstd_summary" %in% names(result))
  expect_true("std_result" %in% names(result))
  expect_true("std_summary" %in% names(result))

  expect_s3_class(result$unstd_summary, "data.frame")
  expect_s3_class(result$std_summary, "data.frame")

  expect_true(all(c("indirect", "direct", "total") %in% result$unstd_summary$Parameter))
  expect_true(all(c("indirect", "direct", "total") %in% result$std_summary$Parameter))
})

test_that("run_mc_mediation works correctly with standardized = FALSE", {
  library(lavaan)

  # 模拟数据
  set.seed(456)
  n <- 100
  M1diff <- rnorm(n, mean = 2, sd = 1)
  Ydiff <- 0.5 * M1diff + rnorm(n, sd = 1)
  dat <- data.frame(M1diff = M1diff, Ydiff = Ydiff)

  # 模型定义
  model <- "
    Ydiff ~ cp*1 + b1*M1diff
    M1diff ~ a1*1
    M1diff ~~ M1diff
    indirect  := a1 * b1
    direct := cp
    total := cp + a1 * b1
  "

  # 拟合模型
  fit <- lavaan::sem(model, data = dat)

  # 执行函数，仅输出非标准化结果
  result <- run_mc_mediation(
    fit = fit,
    data = dat,
    standardized = FALSE,
    R = 500,      # 测试用较小模拟次数
    seed = 456
  )

  # 测试返回结构
  expect_type(result, "list")
  expect_true("unstd_result" %in% names(result))
  expect_true("unstd_summary" %in% names(result))

  expect_s3_class(result$unstd_summary, "data.frame")

  # 标准化结果不应存在
  expect_false("std_result" %in% names(result))
  expect_false("std_summary" %in% names(result))

  # 结果中应包含定义参数的估计
  expect_true(all(c("indirect", "direct", "total") %in% result$unstd_summary$Parameter))
})
