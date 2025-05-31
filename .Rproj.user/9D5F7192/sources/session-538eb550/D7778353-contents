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

test_that("GenerateModelPC correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelPC(test_data_4m)

  expect_type(model_syntax, "character")

  # Y 回归路径
  expect_match(model_syntax, "Ydiff ~ cp*1", fixed = TRUE)
  expect_match(model_syntax, "b1*M1diff", fixed = TRUE)
  expect_match(model_syntax, "b2*M2diff", fixed = TRUE)
  expect_match(model_syntax, "b3*M3diff", fixed = TRUE)
  expect_match(model_syntax, "b4*M4diff", fixed = TRUE)

  # M1 被其他中介预测（并行→链式）
  expect_match(model_syntax, "M1diff ~ a1*1", fixed = TRUE)
  expect_match(model_syntax, "b_2_1*M2diff", fixed = TRUE)
  expect_match(model_syntax, "b_3_1*M3diff", fixed = TRUE)
  expect_match(model_syntax, "b_4_1*M4diff", fixed = TRUE)
  expect_match(model_syntax, "d_2_1*M2avg", fixed = TRUE)
  expect_match(model_syntax, "d_3_1*M3avg", fixed = TRUE)
  expect_match(model_syntax, "d_4_1*M4avg", fixed = TRUE)

  # M2–M4 回归
  expect_match(model_syntax, "M2diff ~ a2*1", fixed = TRUE)
  expect_match(model_syntax, "M3diff ~ a3*1", fixed = TRUE)
  expect_match(model_syntax, "M4diff ~ a4*1", fixed = TRUE)

  # 间接效应（包含交叉路径）
  expect_match(model_syntax, "indirect_2 := a2 * b2", fixed = TRUE)
  expect_match(model_syntax, "indirect_2_1 := a2 * b_2_1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_3 := a3 * b3", fixed = TRUE)
  expect_match(model_syntax, "indirect_3_1 := a3 * b_3_1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_4 := a4 * b4", fixed = TRUE)
  expect_match(model_syntax, "indirect_4_1 := a4 * b_4_1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_1 := a1 * b1", fixed = TRUE)

  # total_indirect 和 total_effect
  expect_match(model_syntax, "total_indirect := indirect_", fixed = TRUE)
  expect_match(model_syntax, "total_effect := cp + total_indirect", fixed = TRUE)

  # 前后测系数
  expect_match(model_syntax, "X1_b1 := (2*b1 + d1)/2", fixed = TRUE)
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1", fixed = TRUE)
  for (i in 2:4) {
    expect_match(model_syntax, paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b", i, " := X1_b", i, " - d", i), fixed = TRUE)
    expect_match(model_syntax, paste0("X1_b_", i, "_1 := (2*b_", i, "_1 + d_", i, "_1)/2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b_", i, "_1 := X1_b_", i, "_1 - d_", i, "_1"), fixed = TRUE)
  }
})

test_that("GenerateModelPC correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelPC(test_data_3m)

  expect_type(model_syntax, "character")

  expect_match(model_syntax, "Ydiff ~ cp*1", fixed = TRUE)
  expect_match(model_syntax, "b1*M1diff", fixed = TRUE)
  expect_match(model_syntax, "b2*M2diff", fixed = TRUE)
  expect_match(model_syntax, "b3*M3diff", fixed = TRUE)

  expect_match(model_syntax, "M1diff ~ a1*1", fixed = TRUE)
  expect_match(model_syntax, "b_2_1*M2diff", fixed = TRUE)
  expect_match(model_syntax, "b_3_1*M3diff", fixed = TRUE)
  expect_match(model_syntax, "d_2_1*M2avg", fixed = TRUE)
  expect_match(model_syntax, "d_3_1*M3avg", fixed = TRUE)

  expect_match(model_syntax, "M2diff ~ a2*1", fixed = TRUE)
  expect_match(model_syntax, "M3diff ~ a3*1", fixed = TRUE)

  expect_match(model_syntax, "indirect_2 := a2 * b2", fixed = TRUE)
  expect_match(model_syntax, "indirect_2_1 := a2 * b_2_1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_3 := a3 * b3", fixed = TRUE)
  expect_match(model_syntax, "indirect_3_1 := a3 * b_3_1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_1 := a1 * b1", fixed = TRUE)
  expect_match(model_syntax, "total_effect := cp + total_indirect", fixed = TRUE)

  expect_match(model_syntax, "X1_b1 := (2*b1 + d1)/2", fixed = TRUE)
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1", fixed = TRUE)
  for (i in 2:3) {
    expect_match(model_syntax, paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b", i, " := X1_b", i, " - d", i), fixed = TRUE)
    expect_match(model_syntax, paste0("X1_b_", i, "_1 := (2*b_", i, "_1 + d_", i, "_1)/2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b_", i, "_1 := X1_b_", i, "_1 - d_", i, "_1"), fixed = TRUE)
  }
})


