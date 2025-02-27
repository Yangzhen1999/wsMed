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

test_that("GenerateModelCP correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelCP(test_data_3m)

  # 确保 SEM 语法是字符串
  expect_type(model_syntax, "character")

  # 确保因变量的回归路径正确
  expect_match(model_syntax, "Ydiff ~ cp\\*1")
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")

  # 确保链式中介和并行中介的回归路径正确
  expect_match(model_syntax, "M1diff ~ a1\\*1")
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b13\\*M1diff \\+ d13\\*M1avg")

  # 确保间接效应计算正确
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")

  # 确保 M1 → M2 → Y 和 M1 → M3 → Y 方向的间接效应正确
  expect_match(model_syntax, "indirect12 := a1 \\* b12 \\* b2")
  expect_match(model_syntax, "indirect13 := a1 \\* b13 \\* b3")

  # 确保总间接效应计算正确
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect12 \\+ indirect13")

  # 确保总效应计算正确
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # **确保间接效应对比计算完整**
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI1vs13 := indirect1 - indirect13")

  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs12 := indirect2 - indirect12")
  expect_match(model_syntax, "CI2vs13 := indirect2 - indirect13")

  expect_match(model_syntax, "CI3vs12 := indirect3 - indirect12")
  expect_match(model_syntax, "CI3vs13 := indirect3 - indirect13")

  expect_match(model_syntax, "CI12vs13 := indirect12 - indirect13")

  # 确保前后测系数计算正确
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")

  # 确保 M1 → M2 → Y 和 M1 → M3 → Y 的前后测系数
  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
  expect_match(model_syntax, "X1_b13 := \\(2\\*b13 \\+ d13\\) ?/ ?2")
  expect_match(model_syntax, "X0_b13 := X1_b13 - d13")
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
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect4 \\+ indirect12 \\+ indirect13 \\+ indirect14")

  # 确保总效应计算正确
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # **确保间接效应对比计算完整**
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs4 := indirect1 - indirect4")
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI1vs13 := indirect1 - indirect13")
  expect_match(model_syntax, "CI1vs14 := indirect1 - indirect14")

  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs4 := indirect2 - indirect4")
  expect_match(model_syntax, "CI2vs12 := indirect2 - indirect12")
  expect_match(model_syntax, "CI2vs13 := indirect2 - indirect13")
  expect_match(model_syntax, "CI2vs14 := indirect2 - indirect14")

  expect_match(model_syntax, "CI3vs4 := indirect3 - indirect4")
  expect_match(model_syntax, "CI3vs12 := indirect3 - indirect12")
  expect_match(model_syntax, "CI3vs13 := indirect3 - indirect13")
  expect_match(model_syntax, "CI3vs14 := indirect3 - indirect14")

  expect_match(model_syntax, "CI4vs12 := indirect4 - indirect12")
  expect_match(model_syntax, "CI4vs13 := indirect4 - indirect13")
  expect_match(model_syntax, "CI4vs14 := indirect4 - indirect14")

  expect_match(model_syntax, "CI12vs13 := indirect12 - indirect13")
  expect_match(model_syntax, "CI12vs14 := indirect12 - indirect14")
  expect_match(model_syntax, "CI13vs14 := indirect13 - indirect14")

  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
  expect_match(model_syntax, "X1_b13 := \\(2\\*b13 \\+ d13\\) ?/ ?2")
  expect_match(model_syntax, "X0_b13 := X1_b13 - d13")
  expect_match(model_syntax, "X1_b14 := \\(2\\*b14 \\+ d14\\) ?/ ?2")
  expect_match(model_syntax, "X0_b14 := X1_b14 - d14")
})


