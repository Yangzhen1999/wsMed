test_that("PrepareMissingData correctly imputes missing data and processes the dataset", {
  # 生成示例数据，并人为引入缺失值
  set.seed(123)
  data_missing <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    M2_before = rnorm(100), M2_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )
  
  # 引入缺失值
  data_missing$M1_before[sample(1:100, 10)] <- NA
  data_missing$M2_after[sample(1:100, 15)] <- NA
  data_missing$Y_before[sample(1:100, 5)] <- NA

  # 运行 PrepareMissingData
  prepared_data <- PrepareMissingData(
    data_missing = data_missing,
    m = 5,
    method = "pmm",
    M_before = c("M1_before", "M2_before"),
    M_after = c("M1_after", "M2_after"),
    Y_before = "Y_before",
    Y_after = "Y_after"
  )

  # 确保返回的对象是列表
  expect_type(prepared_data, "list")

  # 确保包含 `processed_data_list` 和 `imputation_summary`
  expect_true("processed_data_list" %in% names(prepared_data))
  expect_true("imputation_summary" %in% names(prepared_data))

  # 确保 `processed_data_list` 包含 `m` 组数据
  expect_length(prepared_data$processed_data_list, 5)

  # 取第一个插补数据集，检查数据格式
  first_processed_data <- prepared_data$processed_data_list[[1]]
  expect_s3_class(first_processed_data, "data.frame")

  # 确保包含正确的列名
  expected_cols <- c("Ydiff", "M1diff", "M2diff", "M1avg", "M2avg")
  expect_true(all(expected_cols %in% colnames(first_processed_data)))

  # 确保 imputation_summary 存在
  expect_true(!is.null(prepared_data$imputation_summary))
})

# 测试 M_before 和 M_after 长度不匹配时报错
test_that("PrepareMissingData throws an error when M_before and M_after lengths do not match", {
  data_missing <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  expect_error(
    PrepareMissingData(
      data_missing = data_missing,
      m = 5,
      method = "pmm",
      M_before = c("M1_before"),
      M_after = c("M1_after", "M2_after"),  # 长度不匹配
      Y_before = "Y_before",
      Y_after = "Y_after"
    ),
    "The number of M_before and M_after variables must match."
  )
})

# 测试数据缺少 Y_before / Y_after 时应报错
test_that("PrepareMissingData throws an error when Y variables are missing", {
  data_missing <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100)
  )

  expect_error(
    PrepareMissingData(
      data_missing = data_missing,
      m = 5,
      method = "pmm",
      M_before = c("M1_before"),
      M_after = c("M1_after"),
      Y_before = "Y_before",  # 这个变量不存在
      Y_after = "Y_after"
    ),
    "Y variables not found in the dataset."
  )
})

# 测试数据缺少 M_before / M_after 时应报错
test_that("PrepareMissingData throws an error when M variables are missing", {
  data_missing <- data.frame(
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  expect_error(
    PrepareMissingData(
      data_missing = data_missing,
      m = 5,
      method = "pmm",
      M_before = c("M1_before"),
      M_after = c("M1_after"),
      Y_before = "Y_before",
      Y_after = "Y_after"
    ),
    "M variables for M1_before and M1_after not found in the dataset."
  )
})

# 测试插补数据是否包含缺失值
test_that("PrepareMissingData ensures that imputed datasets have no missing values", {
  set.seed(123)
  data_missing <- data.frame(
    M1_before = rnorm(100), M1_after = rnorm(100),
    M2_before = rnorm(100), M2_after = rnorm(100),
    Y_before = rnorm(100), Y_after = rnorm(100)
  )

  # 人为引入缺失值
  data_missing$M1_before[sample(1:100, 10)] <- NA
  data_missing$M2_after[sample(1:100, 15)] <- NA

  # 运行 PrepareMissingData
  prepared_data <- PrepareMissingData(
    data_missing = data_missing,
    m = 5,
    method = "pmm",
    M_before = c("M1_before", "M2_before"),
    M_after = c("M1_after", "M2_after"),
    Y_before = "Y_before",
    Y_after = "Y_after"
  )

  # 确保所有插补数据集中无缺失值
  for (i in seq_along(prepared_data$processed_data_list)) {
    expect_false(anyNA(prepared_data$processed_data_list[[i]]))
  }
})
