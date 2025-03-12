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

test_that("GenerateModelCP correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelPC(test_data_4m)

  # 确保 SEM 语法是字符串
  expect_type(model_syntax, "character")

  # 确保因变量的回归路径正确
  expect_match(model_syntax, "Ydiff ~ cp\\*1")
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")

  # 确保并行中介对 M1 的回归路径正确 (M2 → M1 → Y)
  expect_match(model_syntax, "M1diff ~ a1\\*1 \\+ b21\\*M2diff \\+ b31\\*M3diff \\+ b41\\*M4diff \\+ d21\\*M2avg \\+ d31\\*M3avg \\+ d41\\*M4avg")
  # 确保独立的中介变量回归项
  expect_match(model_syntax, "M2diff ~ a2\\*1")
  expect_match(model_syntax, "M3diff ~ a3\\*1")
  expect_match(model_syntax, "M4diff ~ a4\\*1")

  # 确保间接效应计算正确
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")
  expect_match(model_syntax, "indirect4 := a4 \\* b4")

  # 确保 M2 → M1 → Y 方向的间接效应正确
  expect_match(model_syntax, "indirect21 := a2 \\* b21 \\* b1")
  expect_match(model_syntax, "indirect31 := a3 \\* b31 \\* b1")
  expect_match(model_syntax, "indirect41 := a4 \\* b41 \\* b1")

  # 确保总间接效应计算正确
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect4 \\+ indirect21 \\+ indirect31 \\+ indirect41")

  # 确保总效应计算正确
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")


  # **确保间接效应对比计算完整**
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs4 := indirect1 - indirect4")
  expect_match(model_syntax, "CI1vs21 := indirect1 - indirect21")
  expect_match(model_syntax, "CI1vs31 := indirect1 - indirect31")
  expect_match(model_syntax, "CI1vs41 := indirect1 - indirect41")

  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs4 := indirect2 - indirect4")
  expect_match(model_syntax, "CI2vs21 := indirect2 - indirect21")
  expect_match(model_syntax, "CI2vs31 := indirect2 - indirect31")
  expect_match(model_syntax, "CI2vs41 := indirect2 - indirect41")

  expect_match(model_syntax, "CI3vs4 := indirect3 - indirect4")
  expect_match(model_syntax, "CI3vs21 := indirect3 - indirect21")
  expect_match(model_syntax, "CI3vs31 := indirect3 - indirect31")
  expect_match(model_syntax, "CI3vs41 := indirect3 - indirect41")

  expect_match(model_syntax, "CI4vs21 := indirect4 - indirect21")
  expect_match(model_syntax, "CI4vs31 := indirect4 - indirect31")
  expect_match(model_syntax, "CI4vs41 := indirect4 - indirect41")

  expect_match(model_syntax, "CI21vs31 := indirect21 - indirect31")
  expect_match(model_syntax, "CI21vs41 := indirect21 - indirect41")
  expect_match(model_syntax, "CI31vs41 := indirect31 - indirect41")

  # 确保前后测系数计算正确
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")
  expect_match(model_syntax, "X1_b4 := \\(2\\*b4 \\+ d4\\) ?/ ?2")
  expect_match(model_syntax, "X0_b4 := X1_b4 - d4")

  # 确保 M2 → M1 → Y 的前后测系数
  expect_match(model_syntax, "X1_b21 := \\(2\\*b21 \\+ d21\\) ?/ ?2")
  expect_match(model_syntax, "X0_b21 := X1_b21 - d21")
  expect_match(model_syntax, "X1_b31 := \\(2\\*b31 \\+ d31\\) ?/ ?2")
  expect_match(model_syntax, "X0_b31 := X1_b31 - d31")
  expect_match(model_syntax, "X1_b41 := \\(2\\*b41 \\+ d41\\) ?/ ?2")
  expect_match(model_syntax, "X0_b41 := X1_b41 - d41")
})
test_that("GenerateModelCP correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelPC(test_data_3m)

  # 确保 SEM 语法是字符串
  expect_type(model_syntax, "character")

  # 确保因变量的回归路径正确
  expect_match(model_syntax, "Ydiff ~ cp\\*1")
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")

  # 确保并行中介对 M1 的回归路径正确 (M2 → M1 → Y)
  # 确保并行中介对 M1 的回归路径正确 (M2 → M1 → Y)
  expect_match(model_syntax, "M1diff ~ a1\\*1 \\+ b21\\*M2diff \\+ b31\\*M3diff \\+ d21\\*M2avg \\+ d31\\*M3avg")

  # 确保独立的中介变量回归项
  expect_match(model_syntax, "M2diff ~ a2\\*1")
  expect_match(model_syntax, "M3diff ~ a3\\*1")

  # 确保间接效应计算正确
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")

  # 确保 M2 → M1 → Y 方向的间接效应正确
  expect_match(model_syntax, "indirect21 := a2 \\* b21 \\* b1")
  expect_match(model_syntax, "indirect31 := a3 \\* b31 \\* b1")

  # 确保总间接效应计算正确
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect21 \\+ indirect31")

  # 确保总效应计算正确
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # **确保间接效应对比计算完整**
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs21 := indirect1 - indirect21")
  expect_match(model_syntax, "CI1vs31 := indirect1 - indirect31")

  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs21 := indirect2 - indirect21")
  expect_match(model_syntax, "CI2vs31 := indirect2 - indirect31")

  expect_match(model_syntax, "CI3vs21 := indirect3 - indirect21")
  expect_match(model_syntax, "CI3vs31 := indirect3 - indirect31")

  expect_match(model_syntax, "CI21vs31 := indirect21 - indirect31")

  # 确保前后测系数计算正确
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")

  # 确保 M2 → M1 → Y 的前后测系数
  expect_match(model_syntax, "X1_b21 := \\(2\\*b21 \\+ d21\\) ?/ ?2")
  expect_match(model_syntax, "X0_b21 := X1_b21 - d21")
  expect_match(model_syntax, "X1_b31 := \\(2\\*b31 \\+ d31\\) ?/ ?2")
  expect_match(model_syntax, "X0_b31 := X1_b31 - d31")
})
