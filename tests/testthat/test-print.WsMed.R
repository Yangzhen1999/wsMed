rm(list = ls())

library(testthat)
library(lavaan)
library(knitr)
library(semboottools)
library(semmcci)

data(example_data)
set.seed(123)
example_dataN <- mice::ampute(
  data = example_data,
  prop = 0.1,
)$amp

test_that("print.wsMed prints correct output for complete data", {
  # 加载示例数据
  data(example_data)

  # 强制禁用并行（保险）
  options(mc.cores = 1)
  options(lavaan.bootstrap.ncpus = 1)

  result <- wsMed(
    data = example_data,
    M_C1 = c("A1", "B1"),
    M_C2 = c("A2", "B2"),
    Y_C1 = "C1",
    Y_C2 = "C2",
    form = "P",
    standardized = FALSE,  # 关闭标准化，避免 semhelpinghands::standardizedSolution_boot_ci() 启动 bootstrap
    Na = "DE"
  )

  # 捕获打印输出
  printed_output <- capture.output(print(result))

  # 必定出现的核心部分
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("REGRESSION PATHS, INTERCEPTS AND VARIANCES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))

  # 条件性检查
  if (any(grepl("CONTRAST INDIRECT EFFECTS", printed_output))) {
    expect_true(any(grepl("ind_\\d+ - ind_\\d+", printed_output)))
  }

  if (any(grepl("MODERATION EFFECTS of X", printed_output))) {
    expect_true(any(grepl("d\\d+", printed_output)))
  }

  if (any(grepl("C1-C2 COEFFICIENTS", printed_output))) {
    expect_true(any(grepl("X[01]_b\\d+", printed_output)))
  }
})


test_that("print.wsMed handles missing data correctly with MI", {
  result_with_na <- wsMed(
    data = example_dataN,
    M_C1 = c("A2", "B2"),
    M_C2 = c("A1", "B1"),
    Y_C1 = "C2",
    Y_C2 = "C1",
    form = "P",
    Na = "MI",
    standardized = TRUE,
    m = 5,
    R = 50,
    seed = 123
  )

  printed_output <- capture.output(print(result_with_na))

  # 一定存在的输出
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS.*MC \\(MI\\)", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS.*STANDARDIZED.*MC \\(MI\\)", printed_output)))

  # 可选项使用条件判断
  if (any(grepl("REGRESSION PATHS", printed_output))) {
    expect_true(TRUE)
  }
  if (any(grepl("CONTRAST INDIRECT EFFECTS", printed_output))) {
    expect_true(any(grepl("ind_\\d+ - ind_\\d+", printed_output)))
  }
  if (any(grepl("MODERATION EFFECTS of X", printed_output))) {
    expect_true(any(grepl("d\\d+", printed_output)))
  }
  if (any(grepl("C1-C2 COEFFICIENTS", printed_output))) {
    expect_true(any(grepl("X[01]_b\\d+", printed_output)))
  }
})


test_that("print.wsMed correctly handles FIML missing data method", {
  set.seed(456)
  example_dataN <- mice::ampute(
    data = example_data,
    prop = 0.1
  )$amp

  result <- wsMed(
    data = example_dataN,
    M_C1 = c("A1", "B1", "C1"),
    M_C2 = c("A2", "B2", "C2"),
    Y_C1 = "D1",
    Y_C2 = "D2",
    form = "CP",
    Na = "FIML",
    ci_method = "mc",
    standardized = TRUE,
    R = 500,
    seed = 123
  )

  printed_output <- capture.output(print(result))

  # 必定存在的结构
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))

  # FIML 的 MC 输出检查
  expect_true(any(grepl("REGRESSION PATHS.*MC \\(FIML\\)", printed_output)))
  expect_true(any(grepl("INTERCEPTS.*MC \\(FIML\\)", printed_output)))
  expect_true(any(grepl("VARIANCES.*MC \\(FIML\\)", printed_output)))

  # 标准化部分
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS \\(STANDARDIZED\\) \\(MC \\(FIML\\)\\)", printed_output)))

  # 可选部分
  if (any(grepl("CONTRAST INDIRECT EFFECTS", printed_output))) {
    expect_true(any(grepl("ind_\\d+ - ind_\\d+", printed_output)))
  }

  if (any(grepl("MODERATION EFFECTS of X", printed_output))) {
    expect_true(any(grepl("d\\d+", printed_output)))
  }

  if (any(grepl("C1-C2 COEFFICIENTS", printed_output))) {
    expect_true(any(grepl("X[01]_b\\d+", printed_output)))
  }
})



