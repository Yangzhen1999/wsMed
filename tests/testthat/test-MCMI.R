library(testthat)
library(lavaan)
library(semmcci)

test_that("MCMI2 correctly computes Monte Carlo confidence intervals for SEM models with multiple imputations", {

  # 设定随机种子，确保结果可复现
  set.seed(123)

  # 示例 SEM 模型
  sem_model <- "
    Ydiff ~ b1 * M1diff + cp * 1
    M1diff ~ a1 * 1
    indirect := a1 * b1
    total := cp + indirect
  "

  # 生成插补数据集
  imputations <- list(
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
  )

  # 运行 MCMI 计算
  result <- MCMI2(
    sem_model = sem_model,
    imputations = imputations,
    R = 1000,  # 设为 1000 以加快测试
    alpha = c(0.05, 0.01),
    seed = 123
  )

  # 基本结构检查
  expect_s3_class(result, "semmcci")
  expect_named(result, c("call", "args", "thetahat", "thetahatstar", "fun"))
  
  # 检查 Monte Carlo 采样结果
  expect_true(is.matrix(result$thetahatstar))
  expect_equal(ncol(result$thetahatstar), length(result$thetahat))
  expect_equal(nrow(result$thetahatstar), 1000)  # 应该有 R=1000 个 Monte Carlo 采样

  # 检查参数估计是否为合理值
  expect_true(is.list(result$thetahat), info = "thetahat 应该是一个列表")
  expect_true("est" %in% names(result$thetahat), info = "thetahat 应该包含 'est' 字段")
  expect_true(is.numeric(result$thetahat$est), info = "thetahat$est 应该是数值向量")

  # 检查插补数据是否被正确使用
  expect_equal(length(result$args$imputations), length(imputations))
  expect_true(all(sapply(result$args$imputations, is.data.frame)))
})
