library(testthat)

mock_data_pc <- function(W_type = "continuous") {
  dat <- data.frame(
    Ydiff = rnorm(100),
    M1diff = rnorm(100), M1avg = rnorm(100),
    M2diff = rnorm(100), M2avg = rnorm(100),
    M3diff = rnorm(100), M3avg = rnorm(100)
  )
  if (W_type == "continuous") {
    dat$W1 <- scale(rnorm(100))
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]] * dat$W1
    }
    attr(dat, "W_info") <- list(type = "continuous")
  } else if (W_type == "binary") {
    dat$W1 <- rep(0:1, 50)
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]] * dat$W1
    }
    attr(dat, "W_info") <- list(type = "categorical")
  } else if (W_type == "factor3") {
    dat$W1 <- rep(c(0, 1), 50)
    dat$W2 <- rep(c(0, 0, 1, 1), length.out = 100)
    for (m in 1:3) {
      dat[[paste0("int_M", m, "diff_W1")]] <- dat[[paste0("M", m, "diff")]] * dat$W1
      dat[[paste0("int_M", m, "diff_W2")]] <- dat[[paste0("M", m, "diff")]] * dat$W2
      dat[[paste0("int_M", m, "avg_W1")]]  <- dat[[paste0("M", m, "avg")]] * dat$W1
      dat[[paste0("int_M", m, "avg_W2")]]  <- dat[[paste0("M", m, "avg")]] * dat$W2
    }
    attr(dat, "W_info") <- list(type = "categorical")
  }
  dat
}

# Place continuous-moderator interactions in the correct regressions
test_that("PC model with continuous W generates correct moderated paths", {
  dat <- mock_data_pc("continuous")
  mod <- GenerateModelPC(dat, MP = c("b1", "d2", "cp", "a3", "b_2_1"))
  lines <- strsplit(mod, "\n")[[1]]

  # Check the Ydiff equation
  yline <- lines[grepl("^Ydiff ~", lines)]
  expect_match(yline, "cpw_W1\\*W1")
  expect_match(yline, "bw1_W1\\*int_M1diff_W1")
  expect_match(yline, "dw2_W1\\*int_M2avg_W1")

  # Check aw3 in the M3diff equation
  m3line <- lines[grepl("^M3diff ~ ", lines)]
  expect_match(m3line, "aw3_W1\\*W1")

  # Check bw_2_1 in the M1diff equation
  m1line <- lines[grepl("^M1diff ~ ", lines)]
  expect_match(m1line, "bw_2_1_W1\\*int_M2diff_W1")
})



# Binary-moderator interaction names
test_that("PC model with binary W uses correct dummy interaction names", {
  dat <- mock_data_pc("binary")
  mod <- GenerateModelPC(dat, MP = c("b1", "d2", "b_2_1"))
  expect_match(mod, "bw1_W1\\*int_M1diff_W1")
  expect_match(mod, "dw2_W1\\*int_M2avg_W1")
  expect_match(mod, "bw_2_1_W1\\*int_M2diff_W1")
  expect_false(grepl("bw1_W2", mod))
})


# Three-level moderator with multiple dummy interactions
test_that("PC model with factor W generates multiple dummy-based moderated paths", {
  dat <- mock_data_pc("factor3")
  mod <- GenerateModelPC(dat, MP = c("b1", "d2", "b_2_1"))
  expect_match(mod, "bw1_W1\\*int_M1diff_W1")
  expect_match(mod, "bw1_W2\\*int_M1diff_W2")
  expect_match(mod, "dw2_W1\\*int_M2avg_W1")
  expect_match(mod, "dw2_W2\\*int_M2avg_W2")
  expect_match(mod, "bw_2_1_W1\\*int_M2diff_W1")
  expect_match(mod, "bw_2_1_W2\\*int_M2diff_W2")
})
