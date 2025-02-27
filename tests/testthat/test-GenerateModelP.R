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

  # 基本检查
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 确保所有中介变量回归路径正确
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")

  # 检查中介链的回归项
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b1")

  # 检查间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect12 := a1 \\* b1 \\* b2")

  # 检查总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect12")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查间接效应对比
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")

  # 检查前后测系数
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) / 2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b12 := \\(2\\*b1,2 \\+ d1,2\\) / 2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d1,2")

  # 检查调节效应
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d1,2\\*M1avg")
})

test_that("GenerateModelCN correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelCN(test_data_3m)

  # 基本检查
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 确保所有中介变量回归路径正确
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")

  # 确保链式路径的回归项
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b1")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b2")

  # 检查间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect12 := a1 \\* b1 \\* b2")
  expect_match(model_syntax, "indirect123 := a1 \\* b1 \\* b2 \\* b3")

  # 检查间接效应对比
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI1vs123 := indirect1 - indirect123")
  expect_match(model_syntax, "CI12vs123 := indirect12 - indirect123")

  # 检查前后测系数
  expect_match(model_syntax, "X1_b23 := \\(2\\*b2,3 \\+ d2,3\\) / 2")
  expect_match(model_syntax, "X0_b23 := X1_b23 - d2,3")

  # 检查调节效应
  expect_match(model_syntax, "d2,3\\*M2avg")
})

test_that("GenerateModelCN correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelCN(test_data_4m)

  # 基本检查
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 确保所有中介变量回归路径正确
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")

  # 检查间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect12 := a1 \\* b1 \\* b2")
  expect_match(model_syntax, "indirect123 := a1 \\* b1 \\* b2 \\* b3")
  expect_match(model_syntax, "indirect1234 := a1 \\* b1 \\* b2 \\* b3 \\* b4")

  # 检查间接效应对比
  expect_match(model_syntax, "CI123vs1234 := indirect123 - indirect1234")

  # 检查前后测系数
  expect_match(model_syntax, "X1_b34 := \\(2\\*b3,4 \\+ d3,4\\) / 2")
  expect_match(model_syntax, "X0_b34 := X1_b34 - d3,4")

  # 检查调节效应
  expect_match(model_syntax, "d3,4\\*M3avg")
})

