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


test_that("GenerateModelCP works correctly for 3 mediators (with covariates)", {
  model <- GenerateModelCP(test_data_3m)

  expect_type(model, "character")

  expect_match(model, "Ydiff ~ cp*1", fixed = TRUE)
  expect_match(model, "b1*M1diff", fixed = TRUE)
  expect_match(model, "b2*M2diff", fixed = TRUE)
  expect_match(model, "b3*M3diff", fixed = TRUE)
  expect_match(model, "d1*M1avg", fixed = TRUE)
  expect_match(model, "d2*M2avg", fixed = TRUE)
  expect_match(model, "d3*M3avg", fixed = TRUE)

  expect_match(model, "M1diff ~ a1*1", fixed = TRUE)
  expect_match(model, "M2diff ~ a2*1 + b_1_2*M1diff + d_1_2*M1avg", fixed = TRUE)
  expect_match(model, "M3diff ~ a3*1 + b_1_3*M1diff + d_1_3*M1avg", fixed = TRUE)

  expect_match(model, "indirect_1 := a1 * b1", fixed = TRUE)
  expect_match(model, "indirect_2 := a2 * b2", fixed = TRUE)
  expect_match(model, "indirect_3 := a3 * b3", fixed = TRUE)
  expect_match(model, "indirect_1_2 := a1 * b_1_2 * b2", fixed = TRUE)
  expect_match(model, "indirect_1_3 := a1 * b_1_3 * b3", fixed = TRUE)
  expect_match(model, "total_indirect := indirect_1 +", fixed = TRUE)
  expect_match(model, "total_indirect", fixed = TRUE)

  expect_match(model, "X1_b_1_2 := (2*b_1_2 + d_1_2)/2", fixed = TRUE)
  expect_match(model, "X1_b_1_3 := (2*b_1_3 + d_1_3)/2", fixed = TRUE)

  expect_match(model, "Cb1", fixed = TRUE)
  expect_match(model, "Cw1diff", fixed = TRUE)
  expect_match(model, "Cw1avg", fixed = TRUE)
})

test_that("GenerateModelCP works correctly for 4 mediators (with covariates)", {
  model <- GenerateModelCP(test_data_4m)

  expect_type(model, "character")

  for (i in 1:4) {
    expect_match(model, paste0("b", i, "*M", i, "diff"), fixed = TRUE)
    expect_match(model, paste0("d", i, "*M", i, "avg"), fixed = TRUE)
    expect_match(model, paste0("indirect_", i, " := a", i, " * b", i), fixed = TRUE)
    expect_match(model, paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2"), fixed = TRUE)
  }

  for (i in 2:4) {
    expect_match(model, paste0("b_1_", i, "*M1diff"), fixed = TRUE)
    expect_match(model, paste0("d_1_", i, "*M1avg"), fixed = TRUE)
    expect_match(model, paste0("indirect_1_", i, " := a1 * b_1_", i, " * b", i), fixed = TRUE)
    expect_match(model, paste0("X1_b_1_", i, " := (2*b_1_", i, " + d_1_", i, ")/2"), fixed = TRUE)
    expect_match(model, paste0("X0_b_1_", i, " := X1_b_1_", i, " - d_1_", i), fixed = TRUE)
  }

  expect_match(model, "total_indirect := indirect_1 + indirect_2 + indirect_1_2 + indirect_3 + indirect_1_3 + indirect_4 + indirect_1_4", fixed = TRUE)
  expect_match(model, "total_effect := cp + total_indirect", fixed = TRUE)

  expect_match(model, "Cb1", fixed = TRUE)
  expect_match(model, "Cb2", fixed = TRUE)
  expect_match(model, "Cw1diff", fixed = TRUE)
  expect_match(model, "Cw1avg", fixed = TRUE)
})


