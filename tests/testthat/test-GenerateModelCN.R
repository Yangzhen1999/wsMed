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

  # 确保 SEM 语法正确
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 确保所有中介变量回归路径正确
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")

  # 检查中介链的回归项
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")

  # 检查间接效应（变量名修正）
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect12 := a1 \\* b12")

  # 检查总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect12")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查间接效应对比
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI2vs12 := indirect2 - indirect12")

  # 前后测系数匹配问题
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
})
test_that("GenerateModelCN correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelCN(test_data_3m)

  # 确保 SEM 语法正确
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 检查中介变量回归路径
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")

  # 检查中介链的回归方程
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b23\\*M2diff \\+ b13\\*M1diff \\+ d23\\*M2avg \\+ d13\\*M1avg")

  # 检查所有间接效应（直接路径 + 链式路径）
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")

  expect_match(model_syntax, "indirect12 := a1 \\* b12 \\* b2")
  expect_match(model_syntax, "indirect23 := a2 \\* b23 \\* b3")
  expect_match(model_syntax, "indirect13 := a1 \\* b13 \\* b3")
  expect_match(model_syntax, "indirect123 := a1 \\* b12 \\* b23 \\* b3")

  # 检查总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect12 \\+ indirect13 \\+ indirect23 \\+ indirect123")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查间接效应对比
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI1vs23 := indirect1 - indirect23")
  expect_match(model_syntax, "CI1vs123 := indirect1 - indirect123")
  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs12 := indirect2 - indirect12")
  expect_match(model_syntax, "CI2vs23 := indirect2 - indirect23")
  expect_match(model_syntax, "CI2vs123 := indirect2 - indirect123")
  expect_match(model_syntax, "CI3vs12 := indirect3 - indirect12")
  expect_match(model_syntax, "CI3vs23 := indirect3 - indirect23")
  expect_match(model_syntax, "CI3vs123 := indirect3 - indirect123")
  expect_match(model_syntax, "CI12vs23 := indirect12 - indirect23")
  expect_match(model_syntax, "CI12vs123 := indirect12 - indirect123")
  expect_match(model_syntax, "CI23vs123 := indirect23 - indirect123")


  # 前后测系数匹配问题
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")
  expect_match(model_syntax, "X1_b12 := \\(2\\*b12 \\+ d12\\) ?/ ?2")
  expect_match(model_syntax, "X0_b12 := X1_b12 - d12")
  expect_match(model_syntax, "X1_b23 := \\(2\\*b23 \\+ d23\\) ?/ ?2")
  expect_match(model_syntax, "X0_b23 := X1_b23 - d23")
})
test_that("GenerateModelCN correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelCN(test_data_4m)

  # 确保 SEM 语法正确
  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp\\*1")

  # 检查所有中介变量回归路径正确
  expect_match(model_syntax, "b1\\*M1diff")
  expect_match(model_syntax, "b2\\*M2diff")
  expect_match(model_syntax, "b3\\*M3diff")
  expect_match(model_syntax, "b4\\*M4diff")
  expect_match(model_syntax, "d1\\*M1avg")
  expect_match(model_syntax, "d2\\*M2avg")
  expect_match(model_syntax, "d3\\*M3avg")
  expect_match(model_syntax, "d4\\*M4avg")

  # 检查中介链的回归方程
  expect_match(model_syntax, "M2diff ~ a2\\*1 \\+ b12\\*M1diff \\+ d12\\*M1avg")
  expect_match(model_syntax, "M3diff ~ a3\\*1 \\+ b23\\*M2diff \\+ b13\\*M1diff \\+ d23\\*M2avg \\+ d13\\*M1avg")
  expect_match(model_syntax, "M4diff ~ a4\\*1 \\+ b34\\*M3diff \\+ b24\\*M2diff \\+ b14\\*M1diff \\+ d34\\*M3avg \\+ d24\\*M2avg \\+ d14\\*M1avg")

  # 检查完整的间接效应
  expect_match(model_syntax, "indirect1 := a1 \\* b1")
  expect_match(model_syntax, "indirect2 := a2 \\* b2")
  expect_match(model_syntax, "indirect3 := a3 \\* b3")
  expect_match(model_syntax, "indirect4 := a4 \\* b4")

  expect_match(model_syntax, "indirect12 := a1 \\* b12 \\* b2")
  expect_match(model_syntax, "indirect13 := a1 \\* b13 \\* b3")
  expect_match(model_syntax, "indirect14 := a1 \\* b14 \\* b4")
  expect_match(model_syntax, "indirect23 := a2 \\* b23 \\* b3")
  expect_match(model_syntax, "indirect24 := a2 \\* b24 \\* b4")
  expect_match(model_syntax, "indirect34 := a3 \\* b34 \\* b4")

  expect_match(model_syntax, "indirect123 := a1 \\* b12 \\* b23 \\* b3")
  expect_match(model_syntax, "indirect124 := a1 \\* b12 \\* b24 \\* b4")
  expect_match(model_syntax, "indirect134 := a1 \\* b13 \\* b34 \\* b4")
  expect_match(model_syntax, "indirect234 := a2 \\* b23 \\* b34 \\* b4")

  expect_match(model_syntax, "indirect1234 := a1 \\* b12 \\* b23 \\* b34 \\* b4")

  # 检查总间接效应
  expect_match(model_syntax, "total_indirect := indirect1 \\+ indirect2 \\+ indirect3 \\+ indirect4 \\+ indirect12 \\+ indirect13 \\+ indirect14 \\+ indirect23 \\+ indirect24 \\+ indirect34 \\+ indirect123 \\+ indirect124 \\+ indirect134 \\+ indirect234 \\+ indirect1234")
  expect_match(model_syntax, "total_effect := cp \\+ total_indirect")

  # 检查间接效应对比
  expect_match(model_syntax, "CI1vs2 := indirect1 - indirect2")
  expect_match(model_syntax, "CI1vs3 := indirect1 - indirect3")
  expect_match(model_syntax, "CI1vs4 := indirect1 - indirect4")
  expect_match(model_syntax, "CI1vs12 := indirect1 - indirect12")
  expect_match(model_syntax, "CI1vs13 := indirect1 - indirect13")
  expect_match(model_syntax, "CI1vs14 := indirect1 - indirect14")
  expect_match(model_syntax, "CI1vs23 := indirect1 - indirect23")
  expect_match(model_syntax, "CI1vs24 := indirect1 - indirect24")
  expect_match(model_syntax, "CI1vs34 := indirect1 - indirect34")
  expect_match(model_syntax, "CI1vs123 := indirect1 - indirect123")
  expect_match(model_syntax, "CI1vs124 := indirect1 - indirect124")
  expect_match(model_syntax, "CI1vs134 := indirect1 - indirect134")
  expect_match(model_syntax, "CI1vs234 := indirect1 - indirect234")
  expect_match(model_syntax, "CI1vs1234 := indirect1 - indirect1234")

  expect_match(model_syntax, "CI2vs3 := indirect2 - indirect3")
  expect_match(model_syntax, "CI2vs4 := indirect2 - indirect4")
  expect_match(model_syntax, "CI2vs12 := indirect2 - indirect12")
  expect_match(model_syntax, "CI2vs13 := indirect2 - indirect13")
  expect_match(model_syntax, "CI2vs14 := indirect2 - indirect14")
  expect_match(model_syntax, "CI2vs23 := indirect2 - indirect23")
  expect_match(model_syntax, "CI2vs24 := indirect2 - indirect24")
  expect_match(model_syntax, "CI2vs34 := indirect2 - indirect34")
  expect_match(model_syntax, "CI2vs123 := indirect2 - indirect123")
  expect_match(model_syntax, "CI2vs124 := indirect2 - indirect124")
  expect_match(model_syntax, "CI2vs134 := indirect2 - indirect134")
  expect_match(model_syntax, "CI2vs234 := indirect2 - indirect234")
  expect_match(model_syntax, "CI2vs1234 := indirect2 - indirect1234")

  expect_match(model_syntax, "CI12vs34 := indirect12 - indirect34")
  expect_match(model_syntax, "CI12vs123 := indirect12 - indirect123")
  expect_match(model_syntax, "CI12vs124 := indirect12 - indirect124")
  expect_match(model_syntax, "CI12vs134 := indirect12 - indirect134")
  expect_match(model_syntax, "CI12vs234 := indirect12 - indirect234")
  expect_match(model_syntax, "CI12vs1234 := indirect12 - indirect1234")

  # 前后测系数匹配
  expect_match(model_syntax, "X1_b1 := \\(2\\*b1 \\+ d1\\) ?/ ?2")
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1")
  expect_match(model_syntax, "X1_b2 := \\(2\\*b2 \\+ d2\\) ?/ ?2")
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2")
  expect_match(model_syntax, "X1_b3 := \\(2\\*b3 \\+ d3\\) ?/ ?2")
  expect_match(model_syntax, "X0_b3 := X1_b3 - d3")
  expect_match(model_syntax, "X1_b4 := \\(2\\*b4 \\+ d4\\) ?/ ?2")
  expect_match(model_syntax, "X0_b4 := X1_b4 - d4")
})

