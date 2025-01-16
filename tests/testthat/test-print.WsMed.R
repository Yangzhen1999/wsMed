library(testthat)
library(lavaan)
library(knitr)
library(semhelpinghands)
library(semmcci)

test_that("print.WsMed handles missing data correctly", {
  # 使用有缺失值的数据运行 WsMed
  result_with_na <- WsMed(
    data = example_data_with_na,
    M_before = c("A2", "B2"),
    M_after = c("A1", "B1"),
    Y_before = "C2",
    Y_after = "C1",
    form = "P",
    Na = "MI"
  )

  # 捕获输出
  printed_output <- capture.output(print(result_with_na))

  # 检查打印输出是否包含特定的字符串，正确处理缺失数据
  expect_true(
    grepl("*************** MONTE CARLO CONFIDENCE INTERVALS \\(MI\\) ***************", printed_output),
    info = "Expected '*************** MONTE CARLO CONFIDENCE INTERVALS (MI) ***************' in printed output"
  )
})
