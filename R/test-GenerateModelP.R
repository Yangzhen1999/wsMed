# test-GenerateModelP.R
# 测试 GenerateModelP 是否根据 prepared_data 和 MP 正确构造模型语法

library(testthat)

# 构造测试数据函数
mock_data <- function(include_C = FALSE, W_type = NULL) {
  dat <- data.frame(
    Ydiff    = rnorm(100),
    M1diff   = rnorm(100),
    M1avg    = rnorm(100)
  )
  if (include_C) {
    dat$Cb1 <- rnorm(100)
    dat$Cw1diff <- rnorm(100)
    dat$Cw1avg  <- rnorm(100)
  }
  if (!is.null(W_type)) {
    if (W_type == "continuous") {
      dat$W1 <- scale(rnorm(100))
      dat$int_M1diff_W1 <- dat$M1diff * dat$W1
      dat$int_M1avg_W1  <- dat$M1avg  * dat$W1
    } else if (W_type == "binary") {
      dat$W1 <- rep(0:1, length.out = 100)
      dat$int_M1diff_W1 <- dat$M1diff * dat$W1
      dat$int_M1avg_W1  <- dat$M1avg  * dat$W1
    } else if (W_type == "factor3") {
      dat$W1 <- rep(0:1, 50)
      dat$W2 <- rep(c(0,1), each = 50)
      dat$int_M1diff_W1 <- dat$M1diff * dat$W1
      dat$int_M1diff_W2 <- dat$M1diff * dat$W2
      dat$int_M1avg_W1  <- dat$M1avg  * dat$W1
      dat$int_M1avg_W2  <- dat$M1avg  * dat$W2
    }
  }
  dat
}

# ---------- T1: 无 C 无 W ----------
test_that("T1: No C, No W – baseline model", {
  dat <- mock_data()
  out <- GenerateModelP(dat)

  expect_match(out, "Ydiff ~ cp\\*1 \\+ b1\\*M1diff \\+ d1\\*M1avg")
  expect_match(out, "M1diff ~ a1\\*1")
  expect_match(out, "indirect_1 := a1 \\* b1")
  expect_match(out, "total_indirect := indirect_1")
  expect_match(out, "total_effect := cp \\+ total_indirect")
})

# ---------- T2: 有控制变量 ----------
test_that("T2: Includes Cb and Cw variables", {
  dat <- mock_data(include_C = TRUE)
  out <- GenerateModelP(dat)

  expect_match(out, "Ydiff ~ .*Cb1.*Cw1diff.*Cw1avg", perl = TRUE)
  expect_match(out, "M1diff ~ .*Cb1.*Cw1diff.*Cw1avg", perl = TRUE)
})

# ---------- T3a: 连续 W + MP = b1 ----------
test_that("T3a: Continuous W with MP = b1", {
  dat <- mock_data(W_type = "continuous")
  out <- GenerateModelP(dat, MP = c("b1"))

  expect_match(out, "bw1_W1\\*int_M1diff_W1")
  expect_false(grepl("dw1", out))   # 不应出现 d 路径调节
  expect_false(grepl("cpw_", out))  # 不应出现 cp 调节
})

# ---------- T3b: 三分类 W + MP = b1, d1, cp ----------
test_that("T3b: Factor W (3-level) with MP = b1, d1, cp", {
  dat <- mock_data(W_type = "factor3")
  out <- GenerateModelP(dat, MP = c("b1", "d1", "cp"))

  expect_match(out, "bw1_W1\\*int_M1diff_W1")
  expect_match(out, "bw1_W2\\*int_M1diff_W2")
  expect_match(out, "dw1_W1\\*int_M1avg_W1")
  expect_match(out, "dw1_W2\\*int_M1avg_W2")
  expect_match(out, "cpw_W1\\*W1")
  expect_match(out, "cpw_W2\\*W2")
})

# ---------- T3c: 二分类 W + MP = a1 ----------
test_that("T3c: Binary W with MP = a1", {
  dat <- mock_data(W_type = "binary")
  out <- GenerateModelP(dat, MP = c("a1"))

  expect_match(out, "M1diff ~ a1\\*1 \\+ aw1_W1\\*W1")
})
