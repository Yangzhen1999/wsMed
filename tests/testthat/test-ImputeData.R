# 测试 ImputeData() 函数的结构与方法自动识别逻辑

# 构造含缺失的 toy 数据集
set.seed(123)
toy <- data.frame(
  num1 = c(rnorm(10), NA, rnorm(9)),                         # numeric → pmm
  num2 = c(rnorm(5), NA, rnorm(14)),                         # numeric → pmm
  fac2 = factor(sample(c("A", "B"), 20, TRUE)),              # 2-level factor → logreg
  fac3 = factor(sample(c("low", "med", "high"), 20, TRUE))   # 3-level factor → polyreg
)
toy$num1[3] <- NA
toy$fac2[6] <- NA
toy$fac3[7] <- NA

# 测试 1：结构与返回值
test_that("ImputeData returns mids + list + summary", {
  out <- ImputeData(toy, m = 2, method = NULL)
  expect_s3_class(out$mids, "mids")
  expect_equal(length(out$imputed_data_list), 2)
  expect_true(is.list(out$summary))
})

# 测试 2：插补后的数据中无 NA
test_that("Imputed data contains no NA", {
  out <- ImputeData(toy, m = 2, method = NULL)
  for (d in out$imputed_data_list)
    expect_false(anyNA(d))
})

# 测试 3：method = NULL 时自动选择合适方法
test_that("Auto method selection: pmm, logreg, polyreg", {
  out <- ImputeData(toy, m = 1, method = NULL)
  methods_used <- out$mids$method

  expect_equal(unname(methods_used["num1"]), "pmm",    ignore_attr = TRUE)
  expect_equal(unname(methods_used["num2"]), "pmm",    ignore_attr = TRUE)
  expect_equal(unname(methods_used["fac2"]), "logreg", ignore_attr = TRUE)
  expect_equal(unname(methods_used["fac3"]), "polyreg", ignore_attr = TRUE)
})

# 测试 4：method = "pmm" 单值会广播
test_that("Single method string is broadcast", {
  out <- ImputeData(toy, m = 1, method = "pmm")
  methods_used <- out$mids$method
  expect_true(all(methods_used == "pmm"))
})

# 测试 5：method 向量长度不符时报错
test_that("Method length mismatch triggers error", {
  expect_error(
    ImputeData(toy, m = 1, method = rep("pmm", 2)),
    "Length of 'method'"
  )
})

# 测试 6：非法输入对象时报错
test_that("Non-data.frame input raises error", {
  expect_error(
    ImputeData(list(a = 1:3, b = 4:6), m = 1),
    "data.frame"
  )
})

# 测试 7：predictorMatrix 维度正确
test_that("predictorMatrix is correctly generated", {
  out <- ImputeData(toy, m = 1, method = NULL)
  pm <- out$mids$predictorMatrix
  expect_equal(dim(pm), c(ncol(toy), ncol(toy)))
})
