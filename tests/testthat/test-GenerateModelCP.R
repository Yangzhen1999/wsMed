library(testthat)

# 生成测试数据
set.seed(123)

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

test_data_3m$Cb1 <- rnorm(100)
test_data_3m$Cw1diff <- rnorm(100)
test_data_3m$Cw1avg <- rnorm(100)

test_data_4m$Cb1 <- rnorm(100)
test_data_4m$Cb2 <- rnorm(100)
test_data_4m$Cw1diff <- rnorm(100)
test_data_4m$Cw1avg  <- rnorm(100)


test_that("GenerateModelCP correctly generates SEM model syntax for 3 mediators (with covariates)", {
  # 添加控制变量列
  test_data_3m$Cb1 <- rnorm(100)
  test_data_3m$Cb2 <- rnorm(100)
  test_data_3m$Cw1diff <- rnorm(100)
  test_data_3m$Cw1avg  <- rnorm(100)

  model_syntax <- GenerateModelCP(test_data_3m)

  # 核心结构检查
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")

  # 中介回归
  expect_match(model_syntax, "M1diff ~ a1\\*1")
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b13\\*M1diff \\+ d13\\*M1avg")

  # 间接效应定义
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")
  expect_match(model_syntax, "indirect12 := a1 \\* b12 \\* b2")
  expect_match(model_syntax, "indirect13 := a1 \\* b13 \\* b3")

  expect_match(model_syntax, "indirect1")
  expect_match(model_syntax, "indirect12")
  expect_match(model_syntax, "indirect3")
  expect_match(model_syntax, "indirect13")
  expect_match(model_syntax, "total_indirect")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 前后测路径
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")

  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
  expect_match(model_syntax, "X1_b13 := \\(2\\*b13 \\+ d13\\) ?/ ?2")
  expect_match(model_syntax, "X0_b13 := X1_b13 - d13")

  #
  expect_match(model_syntax, "Cb1")
  expect_match(model_syntax, "Cb2")
  expect_match(model_syntax, "Cw1diff")
  expect_match(model_syntax, "Cw1avg")
})

test_that("GenerateModelCP correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelCP(test_data_4m)

  # 确保 SEM 语法是字符串
  expect_type(model_syntax, "character")

  # 确保因变量的回归路径正确
  expect_match(model_syntax, "Ydiff ~ cp\\*1")
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")

  # 确保链式中介和并行中介的回归路径正确
  expect_match(model_syntax, "M1diff ~ a1\\*1")
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b13\\*M1diff \\+ d13\\*M1avg")
  expect_match(model_syntax, "M4diff ~ a4\\*1 \\+ b14\\*M1diff \\+ d14\\*M1avg")

  # 确保间接效应计算正确
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")
  expect_match(model_syntax, "indirect4 := a4 \\* b4")

  # 确保 M1 → M2 → Y, M1 → M3 → Y, M1 → M4 → Y 方向的间接效应正确
  expect_match(model_syntax, "indirect12 := a1 \\* b12 \\* b2")
  expect_match(model_syntax, "indirect13 := a1 \\* b13 \\* b3")
  expect_match(model_syntax, "indirect14 := a1 \\* b14 \\* b4")

  # 确保总间接效应计算正确
  expect_match(model_syntax, "total_indirect :=")
  expect_match(model_syntax, "indirect1")
  expect_match(model_syntax, "indirect2")
  expect_match(model_syntax, "indirect3")
  expect_match(model_syntax, "indirect4")
  expect_match(model_syntax, "indirect12")
  expect_match(model_syntax, "indirect13")
  expect_match(model_syntax, "indirect14")
  expect_match(model_syntax, "total_indirect")


  # 确保总效应计算正确
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
  expect_match(model_syntax, "X1_b13 := \\(2\\*b13 \\+ d13\\) ?/ ?2")
  expect_match(model_syntax, "X0_b13 := X1_b13 - d13")
  expect_match(model_syntax, "X1_b14 := \\(2\\*b14 \\+ d14\\) ?/ ?2")
  expect_match(model_syntax, "X0_b14 := X1_b14 - d14")

  expect_match(model_syntax, "Cb1")
  expect_match(model_syntax, "Cb2")
  expect_match(model_syntax, "Cw1diff")
  expect_match(model_syntax, "Cw1avg")

})


