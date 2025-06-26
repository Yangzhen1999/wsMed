

library(testthat)

# 创建一个最简模型语法字符串
mock_model <- paste(
  "Ydiff ~ cp*1 + b1*M1diff + d1*M1avg",
  "M1diff ~ a1*1",
  "M2diff ~ a2*1 + b_1_2*M1diff + d_1_2*M1avg",
  "indirect_1 := a1 * b1",
  "indirect_1_2 := a1 * b_1_2 * b2",
  "total_indirect := indirect_1 + indirect_1_2",
  "total_effect := cp + total_indirect",
  sep = "\n"
)

test_that("printGM prints formatted output without error", {
  #expect_silent(out <- printGM(mock_model))  # 应该不会报错
  expect_invisible(printGM(mock_model))      # 返回值是 invisible
})

test_that("printGM classifies and displays all model sections", {
  output <- capture.output(printGM(mock_model))

  expect_true(any(grepl("Outcome Difference Model", output)))
  expect_true(any(grepl("Mediator Difference Model.*M1diff", output)))
  expect_true(any(grepl("Mediator Difference Model.*Other Mediators", output)))
  expect_true(any(grepl("Indirect Effects", output)))
  expect_true(any(grepl("Total Indirect Effect", output)))
  expect_true(any(grepl("Total Effect", output)))
})
