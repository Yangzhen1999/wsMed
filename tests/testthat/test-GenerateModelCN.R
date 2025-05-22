library(testthat)

# 生成测试数据
set.seed(123)
test_data_2m <- data.frame(
  M1diff = rnorm(100),
  M2diff = rnorm(100),
  M1avg = rnorm(100),
  M2avg = rnorm(100),
  Ydiff = rnorm(100)
)

test_data_3m <- data.frame(
  M1diff = rnorm(100),
  M2diff = rnorm(100),
  M3diff = rnorm(100),
  M1avg = rnorm(100),
  M2avg = rnorm(100),
  M3avg = rnorm(100),
  Ydiff = rnorm(100)
)

test_data_4m <- data.frame(
  M1diff = rnorm(100),
  M2diff = rnorm(100),
  M3diff = rnorm(100),
  M4diff = rnorm(100),
  M1avg = rnorm(100),
  M2avg = rnorm(100),
  M3avg = rnorm(100),
  M4avg = rnorm(100),
  Ydiff = rnorm(100)
)

test_that("GenerateModelCN correctly generates SEM model syntax for 2 mediators", {
  model_syntax <- GenerateModelCN(test_data_2m)

  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b_1_2\\*M1diff \\+ d_1_2\\*M1avg")

  expect_match(model_syntax, "indirect_1 := a1 \\* b1")
  expect_match(model_syntax, "indirect_2 := a2 \\* b2")
  expect_match(model_syntax, "indirect_1_2 := a1 \\* b_1_2 \\* b2")

  expect_match(model_syntax, "total_indirect := indirect_1 \\+ indirect_2 \\+ indirect_1_2")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  expect_match(model_syntax, "CI_1_vs_1_2 := indirect_1 - indirect_1_2")
  expect_match(model_syntax, "CI_2_vs_1_2 := indirect_2 - indirect_1_2")

  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\)/2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\)/2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b_1_2 := \\(2\\*b_1_2 \\+ d_1_2\\)/2")
  expect_match(model_syntax, "X0_b_1_2 := X1_b_1_2 - d_1_2")
})

test_that("GenerateModelCN correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelCN(test_data_3m)

  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")

  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b_1_2\\*M1diff \\+ d_1_2\\*M1avg")
  expect_true(grepl("M3diff ~ a3\\*1", model_syntax))
  expect_true(grepl("b_1_3\\*M1diff", model_syntax))
  expect_true(grepl("b_2_3\\*M2diff", model_syntax))
  expect_true(grepl("d_1_3\\*M1avg", model_syntax))
  expect_true(grepl("d_2_3\\*M2avg", model_syntax))

  expect_match(model_syntax, "indirect_1 := a1 \\* b1")
  expect_match(model_syntax, "indirect_2 := a2 \\* b2")
  expect_match(model_syntax, "indirect_3 := a3 \\* b3")
  expect_match(model_syntax, "indirect_1_2 := a1 \\* b_1_2 \\* b2")
  expect_match(model_syntax, "indirect_1_3 := a1 \\* b_1_3 \\* b3")
  expect_match(model_syntax, "indirect_2_3 := a2 \\* b_2_3 \\* b3")
  expect_match(model_syntax, "indirect_1_2_3 := a1 \\* b_1_2 \\* b_2_3 \\* b3")

  expect_match(model_syntax, "total_indirect := indirect_1 \\+ indirect_2 \\+ indirect_3 \\+ indirect_1_2 \\+ indirect_1_3 \\+ indirect_2_3 \\+ indirect_1_2_3")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  expect_match(model_syntax, "CI_1_vs_2 := indirect_1 - indirect_2")
  expect_match(model_syntax, "CI_1_vs_1_2 := indirect_1 - indirect_1_2")
  expect_match(model_syntax, "CI_1_2_vs_1_2_3 := indirect_1_2 - indirect_1_2_3")

  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\)/2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\)/2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\)/2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")
  expect_match(model_syntax, "X1_b_1_2 := \\(2\\*b_1_2 \\+ d_1_2\\)/2")
  expect_match(model_syntax, "X0_b_1_2 := X1_b_1_2 - d_1_2")
})

test_that("GenerateModelCN correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelCN(test_data_4m)

  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 回归路径
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")
  expect_match(model_syntax, "d4\\*M4avg")

  # 链式结构回归
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b_1_2\\*M1diff \\+ d_1_2\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b_2_3\\*M2diff \\+ b_1_3\\*M1diff \\+ d_2_3\\*M2avg \\+ d_1_3\\*M1avg")
  expect_match(model_syntax, "M4diff ~ a4\\*1 \\+ b_3_4\\*M3diff \\+ b_2_4\\*M2diff \\+ b_1_4\\*M1diff \\+ d_3_4\\*M3avg \\+ d_2_4\\*M2avg \\+ d_1_4\\*M1avg")

  # 间接效应
  expect_match(model_syntax, "indirect_1 := a1 \\* b1")
  expect_match(model_syntax, "indirect_2 := a2 \\* b2")
  expect_match(model_syntax, "indirect_3 := a3 \\* b3")
  expect_match(model_syntax, "indirect_4 := a4 \\* b4")

  expect_match(model_syntax, "indirect_1_2 := a1 \\* b_1_2 \\* b2")
  expect_match(model_syntax, "indirect_1_3 := a1 \\* b_1_3 \\* b3")
  expect_match(model_syntax, "indirect_1_4 := a1 \\* b_1_4 \\* b4")
  expect_match(model_syntax, "indirect_2_3 := a2 \\* b_2_3 \\* b3")
  expect_match(model_syntax, "indirect_2_4 := a2 \\* b_2_4 \\* b4")
  expect_match(model_syntax, "indirect_3_4 := a3 \\* b_3_4 \\* b4")

  expect_match(model_syntax, "indirect_1_2_3 := a1 \\* b_1_2 \\* b_2_3 \\* b3")
  expect_match(model_syntax, "indirect_1_2_4 := a1 \\* b_1_2 \\* b_2_4 \\* b4")
  expect_match(model_syntax, "indirect_1_3_4 := a1 \\* b_1_3 \\* b_3_4 \\* b4")
  expect_match(model_syntax, "indirect_2_3_4 := a2 \\* b_2_3 \\* b_3_4 \\* b4")

  expect_match(model_syntax, "indirect_1_2_3_4 := a1 \\* b_1_2 \\* b_2_3 \\* b_3_4 \\* b4")

  expect_match(model_syntax, "total_indirect := .*indirect_1.*\\+.*indirect_2.*\\+.*indirect_3.*\\+.*indirect_4.*")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  expect_match(model_syntax, "CI_1_vs_1_2 := indirect_1 - indirect_1_2")
  expect_match(model_syntax, "CI_1_2_3_vs_1_2_3_4 := indirect_1_2_3 - indirect_1_2_3_4")

  # 前后测系数定义
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\)/2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b_1_2 := \\(2\\*b_1_2 \\+ d_1_2\\)/2")
  expect_match(model_syntax, "X0_b_1_2 := X1_b_1_2 - d_1_2")
})


