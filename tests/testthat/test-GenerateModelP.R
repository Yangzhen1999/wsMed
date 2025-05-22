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

test_data_2m$Cb1 <- rnorm(100)
test_data_2m$Cw1diff <- rnorm(100)
test_data_2m$Cw1avg  <- rnorm(100)
test_data_3m$Cb1 <- rnorm(100)
test_data_3m$Cw1diff <- rnorm(100)
test_data_3m$Cw1avg  <- rnorm(100)
test_data_4m$Cb1 <- rnorm(100)
test_data_4m$Cw1diff <- rnorm(100)
test_data_4m$Cw1avg  <- rnorm(100)


test_that("GenerateModelP correctly generates SEM model syntax for 2 mediators", {
  test_data_2m$Cb1 <- rnorm(100)
  test_data_2m$Cw1diff <- rnorm(100)
  test_data_2m$Cw1avg  <- rnorm(100)

  model_syntax <- GenerateModelP(test_data_2m)

  expect_type(model_syntax, "character")

  # 回归路径
  expect_match(model_syntax, "Ydiff ~ cp*1", fixed = TRUE)
  expect_match(model_syntax, "b1*M1diff", fixed = TRUE)
  expect_match(model_syntax, "b2*M2diff", fixed = TRUE)
  expect_match(model_syntax, "d1*M1avg", fixed = TRUE)
  expect_match(model_syntax, "d2*M2avg", fixed = TRUE)

  # 间接效应
  expect_match(model_syntax, "indirect_1 := a1 * b1", fixed = TRUE)
  expect_match(model_syntax, "indirect_2 := a2 * b2", fixed = TRUE)
  expect_match(model_syntax, "total_indirect := indirect_1 + indirect_2", fixed = TRUE)
  expect_match(model_syntax, "total_effect := cp + total_indirect", fixed = TRUE)
  expect_match(model_syntax, "CI_1_vs_2 := indirect_1 - indirect_2", fixed = TRUE)

  # 前后测系数
  expect_match(model_syntax, "X1_b1 := (2*b1 + d1) / 2", fixed = TRUE)
  expect_match(model_syntax, "X0_b1 := X1_b1 - d1", fixed = TRUE)
  expect_match(model_syntax, "X1_b2 := (2*b2 + d2) / 2", fixed = TRUE)
  expect_match(model_syntax, "X0_b2 := X1_b2 - d2", fixed = TRUE)

  # 控制变量
  expect_match(model_syntax, "Cb1", fixed = TRUE)
  expect_match(model_syntax, "Cw1diff", fixed = TRUE)
  expect_match(model_syntax, "Cw1avg", fixed = TRUE)
})
test_that("GenerateModelP correctly generates SEM model syntax for 3 mediators", {
  model_syntax <- GenerateModelP(test_data_3m)

  expect_type(model_syntax, "character")

  expect_match(model_syntax, "Ydiff ~ cp*1", fixed = TRUE)
  for (i in 1:3) {
    expect_match(model_syntax, paste0("b", i, "*M", i, "diff"), fixed = TRUE)
    expect_match(model_syntax, paste0("d", i, "*M", i, "avg"), fixed = TRUE)
    expect_match(model_syntax, paste0("indirect_", i, " := a", i, " * b", i), fixed = TRUE)
    expect_match(model_syntax, paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b", i, " := X1_b", i, " - d", i), fixed = TRUE)
  }

  expect_match(model_syntax, "total_indirect := indirect_1 + indirect_2 + indirect_3", fixed = TRUE)
  expect_match(model_syntax, "total_effect := cp + total_indirect", fixed = TRUE)

  # 所有对比
  expect_match(model_syntax, "CI_1_vs_2 := indirect_1 - indirect_2", fixed = TRUE)
  expect_match(model_syntax, "CI_1_vs_3 := indirect_1 - indirect_3", fixed = TRUE)
  expect_match(model_syntax, "CI_2_vs_3 := indirect_2 - indirect_3", fixed = TRUE)

  expect_match(model_syntax, "Cb1", fixed = TRUE)
  expect_match(model_syntax, "Cw1diff", fixed = TRUE)
  expect_match(model_syntax, "Cw1avg", fixed = TRUE)
})
test_that("GenerateModelP correctly generates SEM model syntax for 4 mediators", {
  model_syntax <- GenerateModelP(test_data_4m)

  expect_type(model_syntax, "character")
  expect_match(model_syntax, "Ydiff ~ cp*1", fixed = TRUE)

  for (i in 1:4) {
    expect_match(model_syntax, paste0("b", i, "*M", i, "diff"), fixed = TRUE)
    expect_match(model_syntax, paste0("d", i, "*M", i, "avg"), fixed = TRUE)
    expect_match(model_syntax, paste0("indirect_", i, " := a", i, " * b", i), fixed = TRUE)
    expect_match(model_syntax, paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2"), fixed = TRUE)
    expect_match(model_syntax, paste0("X0_b", i, " := X1_b", i, " - d", i), fixed = TRUE)
  }

  expect_match(
    model_syntax,
    "total_indirect := indirect_1 + indirect_2 + indirect_3 + indirect_4",
    fixed = TRUE
  )
  expect_match(model_syntax, "total_effect := cp + total_indirect", fixed = TRUE)

  # 所有 6 个 pairwise 对比
  expect_match(model_syntax, "CI_1_vs_2 := indirect_1 - indirect_2", fixed = TRUE)
  expect_match(model_syntax, "CI_1_vs_3 := indirect_1 - indirect_3", fixed = TRUE)
  expect_match(model_syntax, "CI_1_vs_4 := indirect_1 - indirect_4", fixed = TRUE)
  expect_match(model_syntax, "CI_2_vs_3 := indirect_2 - indirect_3", fixed = TRUE)
  expect_match(model_syntax, "CI_2_vs_4 := indirect_2 - indirect_4", fixed = TRUE)
  expect_match(model_syntax, "CI_3_vs_4 := indirect_3 - indirect_4", fixed = TRUE)

  expect_match(model_syntax, "Cb1", fixed = TRUE)
  expect_match(model_syntax, "Cw1diff", fixed = TRUE)
  expect_match(model_syntax, "Cw1avg", fixed = TRUE)
})


