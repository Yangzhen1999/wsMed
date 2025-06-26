library(testthat)
library(mice)
library(knitr)

library(testthat)

# 构造测试数据（含缺失值）
set.seed(123)
test_data <- data.frame(
  A1 = rnorm(100), A2 = rnorm(100),   # M_C1, M_C2
  B1 = rnorm(100), B2 = rnorm(100),   # M_C1, M_C2
  C1 = rnorm(100), C2 = rnorm(100),   # Y_C1, Y_C2
  D1 = rnorm(100), D2 = rnorm(100),   # C_C1, C_C2
  C3 = rnorm(100),                    # C (between-subject)
  W_cont = rnorm(100),               # W = continuous
  W_bin  = factor(sample(c("low", "high"), 100, TRUE)),     # W = binary
  W_fac3 = factor(sample(c("low", "med", "high"), 100, TRUE))  # W = 3-level
)

# 人为制造缺失值
test_data$A1[1:5] <- NA
test_data$C2[6:10] <- NA
test_data$W_fac3[11:15] <- NA

# 测试函数调用模板
run_prepare <- function(W, W_type) {
  PrepareMissingData(
    data_missing = test_data,
    m = 1,
    M_C1 = c("A1"), M_C2 = c("B1"),
    Y_C1 = "C1",    Y_C2 = "C2",
    C_C1 = "D1",    C_C2 = "D2",
    C     = "C3",   C_type = "auto",
    W     = W,      W_type = W_type,
    center_W = TRUE,
    keep_W_raw = TRUE,
    keep_C_raw = TRUE
  )
}

# --- T1：检查是否插补完成，且无 NA ---
test_that("No missing values after PrepareMissingData", {
  pm <- run_prepare("W_cont", "continuous")
  proc <- pm$processed_data_list[[1]]
  expect_false(anyNA(proc))
})

# --- T2：行数一致性 ---
test_that("Row count preserved after imputation", {
  pm <- run_prepare("W_cont", "continuous")
  proc <- pm$processed_data_list[[1]]
  expect_equal(nrow(proc), nrow(test_data))
})

# --- T3：生成 Ydiff / Mdiff / Mavg ---
test_that("Ydiff, Mdiff, Mavg are generated", {
  pm <- run_prepare("W_cont", "continuous")
  proc <- pm$processed_data_list[[1]]
  expect_true(all(c("Ydiff", "M1diff", "M1avg") %in% names(proc)))
})

# --- T4a：连续型 W 的交互项生成 ---
test_that("Continuous W generates centered W and interactions", {
  pm <- run_prepare("W_cont", "continuous")
  proc <- pm$processed_data_list[[1]]
  expect_true(all(c("W1", "int_M1diff_W1", "int_M1avg_W1") %in% names(proc)))
})

# --- T4b：二分类 W 的 dummy 与交互项 ---
test_that("Binary categorical W generates dummy and interactions", {
  pm <- run_prepare("W_bin", "categorical")
  proc <- pm$processed_data_list[[1]]
  Winfo <- attr(proc, "W_info")
  expect_true(length(Winfo$dummy_names) == 1)
  expect_true(Winfo$dummy_names[1] %in% names(proc))
  expect_true(any(grepl("int_M1diff_", names(proc))))
  expect_true(any(grepl("int_M1avg_", names(proc))))
})

# --- T4c：三分类 W 的 dummy 与交互项 ---
test_that("Three-level categorical W generates 2 dummy and interactions", {
  pm <- run_prepare("W_fac3", "categorical")
  proc <- pm$processed_data_list[[1]]
  Winfo <- attr(proc, "W_info")
  expect_equal(length(Winfo$dummy_names), 2)  # k - 1 dummies
  expect_true(all(Winfo$dummy_names %in% names(proc)))
  expect_true(all(grepl("^W\\d+$", Winfo$dummy_names)))
  expect_true(any(grepl("int_M1diff_", names(proc))))
  expect_true(any(grepl("int_M1avg_", names(proc))))
})

# --- T5：控制变量（被试内、被试间）是否生成 ---
test_that("Cw and Cb variables are generated from C_C1/C_C2/C", {
  pm <- run_prepare("W_cont", "continuous")
  proc <- pm$processed_data_list[[1]]
  expect_true(any(grepl("^Cw\\d+diff$", names(proc))))
  expect_true(any(grepl("^Cw\\d+avg$",  names(proc))))
  expect_true(any(grepl("^Cb\\d+",      names(proc))))
})
