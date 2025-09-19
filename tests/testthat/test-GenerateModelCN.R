# test-GenerateModelCN.R
# 精细测试高阶路径调节项在 GenerateModelCN 中是否被正确建模且出现在正确方程中

library(testthat)

# 构造模拟数据
mock_data_cn <- function(W_type = "continuous") {
  dat <- data.frame(
    Ydiff = rnorm(100),
    M1diff = rnorm(100), M2diff = rnorm(100), M3diff = rnorm(100),
    M1avg  = rnorm(100), M2avg  = rnorm(100), M3avg  = rnorm(100)
  )
  if (W_type == "continuous") {
    dat$W1 <- scale(rnorm(100))
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]]  * dat$W1
    }
    attr(dat, "W_info") <- list(type = "continuous")
  } else if (W_type == "binary") {
    dat$W1 <- rep(0:1, 50)
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]]  * dat$W1
    }
    attr(dat, "W_info") <- list(type = "categorical")
  } else if (W_type == "factor3") {
    dat$W1 <- rep(c(0, 1), 50)
    dat$W2 <- rep(c(0, 0, 1, 1), length.out = 100)
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "diff_W2")]] <- dat[[paste0("M", m, "diff")]] * dat$W2
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]]  * dat$W1
      dat[[paste0("int_M", m, "avg_W2")]]  <- dat[[paste0("M", m, "avg")]]  * dat$W2
    }
    attr(dat, "W_info") <- list(type = "categorical")
  }
  dat
}

# --- 连续变量下的高阶路径调节项 ---
test_that("High-order moderation with continuous W are in correct equations", {
  dat <- mock_data_cn("continuous")
  mod <- GenerateModelCN(dat, MP = c("b_1_2", "d_1_2", "b_2_3", "d_2_3"))

  m2 <- gsub(".*M2diff ~ (.*?)\\n.*", "\\1", mod)
  expect_match(m2, "b_1_2\\*M1diff")
  expect_match(m2, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(m2, "d_1_2\\*M1avg")
  expect_match(m2, "dw_1_2_W1\\*int_M1avg_W1")

  m3 <- gsub(".*M3diff ~ (.*?)\\n.*", "\\1", mod)
  expect_match(m3, "b_2_3\\*M2diff")
  expect_match(m3, "bw_2_3_W1\\*int_M2diff_W1")
  expect_match(m3, "d_2_3\\*M2avg")
  expect_match(m3, "dw_2_3_W1\\*int_M2avg_W1")
})

# --- 二分类 W 的高阶路径调节 ---
test_that("High-order moderation with binary W generates single dummy-based moderation terms", {
  dat <- mock_data_cn("binary")
  mod <- GenerateModelCN(dat, MP = c("b_1_2", "d_2_3"))

  expect_match(mod, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(mod, "dw_2_3_W1\\*int_M2avg_W1")
  expect_false(grepl("bw_1_2_W2", mod))
  expect_false(grepl("dw_2_3_W2", mod))
})

# --- 三分类 W 的高阶路径调节 ---
test_that("High-order moderation with factor W generates two dummy-based moderation terms", {
  dat <- mock_data_cn("factor3")
  mod <- GenerateModelCN(dat, MP = c("b_1_2", "d_2_3"))

  expect_match(mod, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(mod, "bw_1_2_W2\\*int_M1diff_W2")
  expect_match(mod, "dw_2_3_W1\\*int_M2avg_W1")
  expect_match(mod, "dw_2_3_W2\\*int_M2avg_W2")
})

# --- 检查是否出现在错误方程（例如 b_1_2 不应出现在 M3） ---
test_that("Moderated terms do not appear in unrelated regression equations", {
  dat <- mock_data_cn("continuous")
  mod <- GenerateModelCN(dat, MP = c("b_1_2", "d_1_2"))
  lines <- strsplit(mod, "\\n")[[1]]
  m3line <- lines[grepl("^M3diff ~", lines)]
  expect_false(grepl("b_1_2|bw_1_2", m3line))
  expect_false(grepl("d_1_2|dw_1_2", m3line))
})

# --- 间接效应项生成是否正确 ---
test_that("Indirect effects are correctly computed for serial paths", {
  dat <- mock_data_cn("continuous")
  mod <- GenerateModelCN(dat)

  expect_match(mod, "indirect_1 := a1 \\* b1")
  expect_match(mod, "indirect_1_2 := a1 \\* b_1_2 \\* b2")
  expect_match(mod, "indirect_1_2_3 := a1 \\* b_1_2 \\* b_2_3 \\* b3")
  expect_match(mod, "total_indirect :=")
  expect_match(mod, "total_effect := cp \\+ total_indirect")
})

# --- 主效应W不重复添加 ---
test_that("Main effect W is not duplicated when modulation term exists", {
  dat <- mock_data_cn("continuous")
  mod <- GenerateModelCN(dat, MP = c("a2", "cp"))
  m2line <- grep("^M2diff ~", strsplit(mod, "\\n")[[1]], value = TRUE)
  yline  <- grep("^Ydiff ~",  strsplit(mod, "\\n")[[1]], value = TRUE)
  expect_equal(length(grep("\\bW1\\b", m2line)), 1)
  expect_equal(length(grep("\\bW1\\b", yline)), 1)
})


