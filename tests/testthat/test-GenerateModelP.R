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


test_that("GenerateModelP correctly generates SEM model syntax for 2 mediators", {
  model_syntax <- GenerateModelP(test_data_2m)

  # 检查模型语法是否为字符类型
  expect_type(model_syntax, "character")

  # 检查是否包含 Ydiff ~ cp
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 检查是否正确生成 Mdiff 和 Mavg 相关的回归项
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")

  # 检查是否正确生成间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")

  # 检查是否正确生成总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查是否生成了间接效应对比项
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")

  # 检查是否正确生成前后测系数
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) / 2")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) / 2")
})
test_that("GenerateModelP correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelP(test_data_3m)

  # 检查是否包含 Ydiff ~ cp
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 检查是否包含所有中介变量的回归项
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")

  # 检查是否正确生成间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")

  # 检查是否正确生成总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查是否生成了所有间接效应对比项
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")

  # 检查是否正确生成前后测系数
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) / 2")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) / 2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) / 2")
})
test_that("GenerateModelP correctly generates SEM model syntax for 4 mediators", {
  # 运行 GenerateModelP()
  model_syntax <- GenerateModelP(test_data_4m)

  # 基本检查：确保输出是字符串
  expect_type(model_syntax, "character")

  # 确保 `Ydiff ~ cp*1` 这一回归项存在
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 确保包含所有中介变量的回归项
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")
  expect_match(model_syntax, "d4\\*M4avg")

  # 确保正确生成间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")
  expect_match(model_syntax, "indirect4 := a4 \\* b4")

  # 确保正确生成总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect4")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查所有间接效应对比
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs4 := indirect1 - indirect4")
  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs4 := indirect2 - indirect4")
  expect_match(model_syntax, "CI3vs4 := indirect3 - indirect4")

  # 检查是否正确生成前后测系数
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) / 2")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) / 2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) / 2")
  expect_match(model_syntax, "X1_b4 := \\(2\\*b4 \\+ d4\\) / 2")
})

