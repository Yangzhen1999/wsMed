
test_that("MCMI2 returns correct semmcci object structure", {
  # 构建示例模型
  model <- "
    Ydiff ~ b1 * M1diff + cp * 1
    M1diff ~ a1 * 1
    indirect := a1 * b1
    total := cp + indirect
  "

  # 构建插补数据集
  set.seed(123)
  imputations <- list(
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
  )

  # 调用函数
  result <- MCMI2(
    sem_model = model,
    imputations = imputations,
    R = 1000,
    alpha = c(0.05, 0.01),
    seed = 456
  )

  # 类型检查
  expect_s3_class(result, "semmcci")
  expect_true(all(c("call", "args", "thetahat", "thetahatstar", "fun") %in% names(result)))
  expect_equal(result$fun, "MCMI")

  # 参数结构检查
  expect_type(result$thetahat$est, "double")
  expect_true(is.matrix(result$thetahatstar))
  expect_equal(nrow(result$thetahatstar), 1000)

  # 参数名称与列一致
  expect_equal(colnames(result$thetahatstar), names(result$thetahat$est))

  # 检查 args 信息完整性
  expect_true(is.list(result$args))
  expect_equal(result$args$R, 1000)
  expect_equal(result$args$alpha, c(0.05, 0.01))
  expect_equal(result$args$decomposition, "eigen")
  expect_equal(result$args$seed, 456)
})

test_that("MCMI2 fails with wrong input types", {
  bad_model <- 123
  bad_imputations <- list(1:10, 1:10)

  expect_error(MCMI2(bad_model, imputations = list(data.frame(x = 1:10))),
               "is.character")

  expect_error(MCMI2("x ~ y", imputations = bad_imputations),
               "is.list\\(imputations\\) && all\\(sapply\\(imputations, is.data.frame\\)\\)")
})
