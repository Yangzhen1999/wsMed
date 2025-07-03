library(testthat)
library(lavaan)
library(semboottools)
library(wsMed)

data(example_data)

# 统一参数 ---------------------------------------------------------
args_core <- list(
  data = example_data,
  M_C1 = c("A1", "A2"),
  M_C2 = c("B1", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  C_C1 = "D1",
  C_C2 = "D2",
  C     = "C3",
  C_type = "auto"
)

# -----------------------------------------------------------------
# 测试 1：numeric W 连续型，开启中心化
# -----------------------------------------------------------------
pd_num_cent <- do.call(PrepareData, c(args_core,
                                      list(W = "A3", W_type = "continuous", center_W = TRUE)))

test_that("Numeric W is centred and named W1", {
  expect_true("W1" %in% names(pd_num_cent))
  expect_lt(abs(mean(pd_num_cent$W1)), 1e-10)
})

# -----------------------------------------------------------------
# 测试 2：numeric W 关闭中心化
# -----------------------------------------------------------------
pd_num_raw <- do.call(PrepareData, c(args_core,
                                     list(W = "A3", W_type = "continuous", center_W = FALSE)))

test_that("Numeric W remains un‑centred when centre_W = FALSE", {
  expect_gt(abs(mean(pd_num_raw$W1)), 1e-3)
})

# -----------------------------------------------------------------
# 测试 3：factor W → dummy 列
# -----------------------------------------------------------------
pd_fac <- do.call(PrepareData, c(args_core,
                                 list(W = "Group", W_type = "categorical", center_W = TRUE)))

test_that("Factor W converted to (k‑1) dummy columns", {
  dummies <- attr(pd_fac, "W_info")$dummy_names
  expect_equal(length(dummies), length(levels(example_data$Group)) - 1)
  expect_true(all(dummies %in% names(pd_fac)))
})

# -----------------------------------------------------------------
# 测试 4：Ydiff / Mdiff / Mavg 正确
# -----------------------------------------------------------------
test_that("Core diff/avg columns are correct", {
  expect_equal(pd_num_cent$Ydiff, example_data$C2 - example_data$C1)
  expect_equal(pd_num_cent$M1diff, example_data$B1 - example_data$A1)
  m1_avg_truth <- (example_data$A1 - mean(example_data$A1) +
                     example_data$B1 - mean(example_data$B1)) / 2
  expect_equal(pd_num_cent$M1avg, m1_avg_truth)
})

# -----------------------------------------------------------------
# 测试 5：一次传入两个 W 必须报错
# -----------------------------------------------------------------
test_that("Supplying more than one W triggers error", {
  expect_error(
    PrepareData(example_data,
                M_C1 = c("A1"), M_C2 = c("B1"),
                Y_C1 = "C1", Y_C2 = "C2",
                W     = c("A3", "Group")),
    "Exactly one moderator"
  )
})
