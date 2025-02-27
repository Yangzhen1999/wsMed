library(testthat)
library(mice)

# 生成测试数据
set.seed(123)
test_data <- data.frame(
  M1 = c(rnorm(98), NA, NA),
  M2 = c(rnorm(98), NA, NA),
  Y1 = rnorm(100),
  Y2 = rnorm(100)
)

test_that("ImputeData correctly imputes missing values", {
  imputed_result <- ImputeData(test_data, m = 5, method = "pmm", seed = 123)

  # 确保返回的数据集数量正确
  expect_length(imputed_result$imputed_data_list, 5)

  # 确保插补数据中没有 NA
  for (i in seq_along(imputed_result$imputed_data_list)) {
    expect_false(any(is.na(imputed_result$imputed_data_list[[i]])))
  }

  # 确保数据类型未改变
  expect_true(all(sapply(imputed_result$imputed_data_list[[1]], is.numeric)))
})
test_that("ImputeData produces consistent results with fixed seed", {
  imputed_result1 <- ImputeData(test_data, m = 5, method = "pmm", seed = 123)
  imputed_result2 <- ImputeData(test_data, m = 5, method = "pmm", seed = 123)

  # 确保相同随机种子时插补数据完全一致
  for (i in 1:5) {
    expect_equal(imputed_result1$imputed_data_list[[i]], imputed_result2$imputed_data_list[[i]])
  }
})
test_that("ImputeData handles different imputation methods", {
  imputed_result_pmm <- ImputeData(test_data, m = 5, method = "pmm", seed = 123)
  imputed_result_norm <- ImputeData(test_data, m = 5, method = "norm", seed = 123)

  # 确保不同方法返回的结果不同
  expect_false(identical(imputed_result_pmm$imputed_data_list, imputed_result_norm$imputed_data_list))
})
