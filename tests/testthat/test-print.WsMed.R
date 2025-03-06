library(testthat)
library(lavaan)
library(knitr)
library(semhelpinghands)
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
  result <- wsMed(
    data = example_data,
    M_before = c("A1", "B1"),
    M_after = c("A2", "B2"),
    Y_before = "C1",
    Y_after = "C2",
    form = "P",
    standardized = TRUE,
    Na = "DE",
    bootstrap = 1000,
    seed = 123
  )

  # 捕获输出
  printed_output <- capture.output(print(result))
  # 验证关键输出部分
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("REGRESSION PATHS, INTERCEPTS AND VARIANCES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("CONTRAST INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("MODERATION EFFECTS of X", printed_output)))
  expect_true(any(grepl("PRE-POST COEFFICIENTS", printed_output)))
  expect_true(any(grepl("STANDARDIZED RESULTS", printed_output)))
  expect_true(any(grepl("Bootstrapping NOTES", printed_output)))
})

test_that("print.wsMed handles missing data correctly with MI", {
  # 使用有缺失值的数据运行 wsMed
  result_with_na <- wsMed(
    data = example_dataN,
    M_before = c("A2", "B2"),
    M_after = c("A1", "B1"),
    Y_before = "C2",
    Y_after = "C1",
    form = "P",
    Na = "MI",
    standardized = TRUE,
    m = 5,
    R = 50,
    seed = 123
  )

  # 捕获输出
  printed_output <- capture.output(print(result_with_na))

  # 检查打印输出是否包含特定的字符串，正确处理缺失数据
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("REGRESSION PATHS, INTERCEPTS AND VARIANCES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("CONTRAST INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("MODERATION EFFECTS of X", printed_output)))
  expect_true(any(grepl("PRE-POST COEFFICIENTS", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS \\(MI\\)", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS \\(STANDARDIZED\\)", printed_output)))
  expect_true(any(grepl("Number of imputations", printed_output)))
  expect_true(any(grepl("Confidence Level", printed_output)))
  expect_true(any(grepl("Decomposition method for covariance matrices", printed_output)))
  expect_true(any(grepl("Check positive definiteness of covariance matrices", printed_output)))
  expect_true(any(grepl("Tolerance for positive definiteness checks", printed_output)))
  expect_true(any(grepl("Significance levels for confidence intervals", printed_output)))
  expect_true(any(grepl("Significance levels for standardized confidence intervals", printed_output)))
})

test_that("print.wsMed correctly handles FIML missing data method", {
  # 生成带有缺失值的数据
  set.seed(456)
  example_dataN <- mice::ampute(
    data = example_data,
    prop = 0.1
  )$amp

  # 执行 mediation 分析
  result <- wsMed(
    data = example_dataN,
    M_before = c("A1", "B1","C1"),
    M_after = c("A2", "B2","C2"),
    Y_before = "D1",
    Y_after = "D2",
    form = "CP",
    standardized = TRUE,
    Na = "FIML",
    R = 500,
    seed = 123
  )

  # 捕获输出
  printed_output <- capture.output(print(result))

  # 确保包含 FIML 输出
  expect_true(any(grepl("VARIABLES", printed_output)))
  expect_true(any(grepl("MODEL FIT INDICES", printed_output)))
  expect_true(any(grepl("REGRESSION PATHS, INTERCEPTS AND VARIANCES", printed_output)))
  expect_true(any(grepl("TOTAL AND DIRECT EFFECT", printed_output)))
  expect_true(any(grepl("INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("CONTRAST INDIRECT EFFECTS", printed_output)))
  expect_true(any(grepl("MODERATION EFFECTS of X", printed_output)))
  expect_true(any(grepl("PRE-POST COEFFICIENTS", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS \\(FIML\\)", printed_output)))
  expect_true(any(grepl("MONTE CARLO CONFIDENCE INTERVALS \\(STANDARDIZED\\)", printed_output)))
  expect_true(any(grepl("Confidence Level", printed_output)))
  expect_true(any(grepl("Decomposition method for covariance matrices", printed_output)))
  expect_true(any(grepl("Check positive definiteness of covariance matrices", printed_output)))
  expect_true(any(grepl("Tolerance for positive definiteness checks", printed_output)))
  expect_true(any(grepl("Significance levels for confidence intervals", printed_output)))
  expect_true(any(grepl("Significance levels for standardized confidence intervals", printed_output)))
})
