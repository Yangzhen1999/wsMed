library(testthat)
library(mice) # 确保 mice 包可用
library(wsMed) # 加载你的 R 包（如果包名更改，修改此处）

test_that("PrepareMissingData detects mismatched M_C1 and M_C2 lengths", {
  data_test <- data.frame(
    M1_before = rnorm(100),
    M1_after = rnorm(100),
    Y_C1 = rnorm(100),
    Y_C2 = rnorm(100)
  )

  expect_error(
    PrepareMissingData(
      data_missing = data_test,
      M_C1 = c("M1_before"),
      M_C2 = c("M1_after", "M2_after"),  # ❌ 长度不匹配
      Y_C1 = "Y_C1",
      Y_C2 = "Y_C2"
    ),
    "M_C1 and M_C2 must have the same length."
  )
})

test_that("PrepareMissingData detects missing Y variables", {
  data_test <- data.frame(
    M1_before = rnorm(100),
    M1_after = rnorm(100)
  ) # ❌ Y_C1 和 Y_C2 缺失

  expect_error(
    PrepareMissingData(
      data_missing = data_test,
      M_C1 = c("M1_before"),
      M_C2 = c("M1_after"),
      Y_C1 = "Y_C1",  # ❌ 这个变量不存在
      Y_C2 = "Y_C2"
    ),
    "Y_C1 or Y_C2 is missing in the dataset."
  )
})

test_that("PrepareMissingData correctly imputes and processes data", {
  # 创建一个带缺失值的数据集
  set.seed(123)
  data_test <- data.frame(
    M1_before = c(rnorm(95), rep(NA, 5)), # 5% 缺失值
    M1_after = c(rnorm(95), rep(NA, 5)),
    Y_C1 = rnorm(100),
    Y_C2 = rnorm(100)
  )

  # 运行函数
  result <- PrepareMissingData(
    data_missing = data_test,
    m = 5,
    method = "pmm",
    seed = 123,
    M_C1 = c("M1_before"),
    M_C2 = c("M1_after"),
    Y_C1 = "Y_C1",
    Y_C2 = "Y_C2"
  )

  # 验证返回结果
  expect_type(result, "list")
  expect_true("processed_data_list" %in% names(result))
  expect_true("imputation_summary" %in% names(result))

  # 确保插补数据集的数量正确
  expect_length(result$processed_data_list, 5)
})
