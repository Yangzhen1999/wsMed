test_that("PrepareData correctly computes difference and average scores", {
  # 生成示例数据
  set.seed(123)
  data <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    M2_before = rnorm(100), M2_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  # 运行 PrepareData 函数
  prepared_data <- PrepareData(
    data = data,
    M_before = c("M1_before", "M2_before"),
    M_after = c("M1_after", "M2_after"),
    Y_before = "Y_before",
    Y_after = "Y_after"
  )

  # 确保返回的数据是数据框
  expect_s3_class(prepared_data, "data.frame")

  # 确保包含正确的列名
  expected_cols <- c("Ydiff", "M1diff", "M2diff", "M1avg", "M2avg")
  expect_true(all(expected_cols %in% colnames(prepared_data)))

  # 验证 Ydiff 计算是否正确
  expect_equal(prepared_data$Ydiff, data$Y_after - data$Y_before, tolerance = 1e-6)

  # 验证 Mdiff 计算是否正确
  expect_equal(prepared_data$M1diff, data$M1_after - data$M1_before, tolerance = 1e-6)
  expect_equal(prepared_data$M2diff, data$M2_after - data$M2_before, tolerance = 1e-6)

  # 验证 Mavg 计算是否正确（中心化）
  expect_equal(prepared_data$M1avg, (data$M1_before - mean(data$M1_before) +
                                     data$M1_after - mean(data$M1_after)) / 2, tolerance = 1e-6)
  expect_equal(prepared_data$M2avg, (data$M2_before - mean(data$M2_before) +
                                     data$M2_after - mean(data$M2_after)) / 2, tolerance = 1e-6)
})

# 测试 M_before 和 M_after 长度不匹配时应报错
test_that("PrepareData throws an error when M_before and M_after lengths do not match", {
  data <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  expect_error(
    PrepareData(
      data = data,
      M_before = c("M1_before"),
      M_after = c("M1_after", "M2_after"),  # 长度不匹配
      Y_before = "Y_before",
      Y_after = "Y_after"
    ),
    "The number of M_before and M_after variables must match."
  )
})

# 测试数据缺少 Y_before / Y_after 时应报错
test_that("PrepareData throws an error when Y variables are missing", {
  data <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100)
  )

  expect_error(
    PrepareData(
      data = data,
      M_before = c("M1_before"),
      M_after = c("M1_after"),
      Y_before = "Y_before",  # 这个变量不存在
      Y_after = "Y_after"
    ),
    "Y variables not found in the dataset."
  )
})

# 测试数据缺少 M_before / M_after 时应报错
test_that("PrepareData throws an error when M variables are missing", {
  data <- data.frame(
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  expect_error(
    PrepareData(
      data = data,
      M_before = c("M1_before"),
      M_after = c("M1_after"),
      Y_before = "Y_before",
      Y_after = "Y_after"
    ),
    "M variables for M1_before and M1_after not found in the dataset."
  )
})

# 测试处理包含缺失值的数据
test_that("PrepareData correctly handles missing values", {
  set.seed(123)
  data <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    M2_before = rnorm(100), M2_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  # 人为引入缺失值
  data$M1_before[1:10] <- NA
  data$M1_after[5:15] <- NA

  # 运行 PrepareData
  prepared_data <- PrepareData(
    data = data,
    M_before = c("M1_before", "M2_before"),
    M_after = c("M1_after", "M2_after"),
    Y_before = "Y_before",
    Y_after = "Y_after"
  )

  # 确保包含正确的列名
  expected_cols <- c("Ydiff", "M1diff", "M2diff", "M1avg", "M2avg")
  expect_true(all(expected_cols %in% colnames(prepared_data)))

  # 允许 NA 但不应影响数据框格式
  expect_s3_class(prepared_data, "data.frame")
})
