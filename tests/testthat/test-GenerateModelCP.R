library(testthat)

mock_data_cp <- function(W_type = "continuous") {
  dat <- data.frame(
    Ydiff = rnorm(100),
    M1diff = rnorm(100), M1avg = rnorm(100),
    M2diff = rnorm(100), M2avg = rnorm(100)
  )

  if (W_type == "continuous") {
    dat$W1 <- scale(rnorm(100))
    dat$int_M1diff_W1 <- dat$M1diff * dat$W1
    dat$int_M1avg_W1  <- dat$M1avg  * dat$W1
    dat$int_M2diff_W1 <- dat$M2diff * dat$W1
    dat$int_M2avg_W1  <- dat$M2avg  * dat$W1
    attr(dat, "W_info") <- list(type = "continuous")
  } else if (W_type == "factor") {
    dat$W1 <- rep(0:1, 50)
    dat$W2 <- rep(c(0,1), each = 50)
    for (m in c("M1diff", "M2diff")) {
      dat[[paste0("int_", m, "_W1")]] <- dat[[m]] * dat$W1
      dat[[paste0("int_", m, "_W2")]] <- dat[[m]] * dat$W2
    }
    for (m in c("M1avg", "M2avg")) {
      dat[[paste0("int_", m, "_W1")]] <- dat[[m]] * dat$W1
      dat[[paste0("int_", m, "_W2")]] <- dat[[m]] * dat$W2
    }
    attr(dat, "W_info") <- list(type = "categorical")
  }
  dat
}

# --- 基础模型 ---
test_that("CP model baseline structure is correct", {
  dat <- mock_data_cp()
  mod <- GenerateModelCP(dat)

  expect_match(mod, "Ydiff ~ cp\\*1")
  expect_match(mod, "M1diff ~ a1\\*1")
  expect_match(mod, "M2diff ~ a2\\*1")
  expect_match(mod, "b_1_2\\*M1diff")
  expect_match(mod, "d_1_2\\*M1avg")
})

test_that("CP model with continuous moderator and interaction terms", {
  dat <- mock_data_cp("continuous")
  mod <- GenerateModelCP(dat, MP = c("a2", "b_1_2"))
  mod_lines <- strsplit(mod, "\\n")[[1]]
  m2_line <- mod_lines[grepl("^M2diff ~", mod_lines)]

  expect_match(m2_line, "aw2_W1\\*W1")
  expect_match(m2_line, "bw_1_2_W1\\*int_M1diff_W1")
  expect_false(grepl(" \\+ W1( |$)", m2_line))  # 不应出现重复主效应项
})


# --- 分类 W + 全部路径调节 ---
test_that("CP model with factor moderator includes dummy-coded interactions", {
  dat <- mock_data_cp("factor")
  mod <- GenerateModelCP(dat, MP = c("b_1_2", "d_1_2", "a2", "cp"))

  expect_match(mod, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(mod, "bw_1_2_W2\\*int_M1diff_W2")
  expect_match(mod, "dw_1_2_W1\\*int_M1avg_W1")
  expect_match(mod, "cpw_W1\\*W1")
  expect_match(mod, "cpw_W2\\*W2")
})
