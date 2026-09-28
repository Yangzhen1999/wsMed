library(testthat)

# Construct test data
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

# No covariates or moderator
test_that("T1: No C, No W – baseline model", {
  dat <- mock_data()
  out <- GenerateModelP(dat)

  expect_match(out, "Ydiff ~ cp\\*1 \\+ b1\\*M1diff \\+ d1\\*M1avg")
  expect_match(out, "M1diff ~ a1\\*1")
  expect_match(out, "indirect_1 := a1 \\* b1")
  expect_match(out, "total_indirect := indirect_1")
  expect_match(out, "total_effect := cp \\+ total_indirect")
})

# Include covariates
test_that("T2: Includes Cb and Cw variables", {
  dat <- mock_data(include_C = TRUE)
  out <- GenerateModelP(dat)

  expect_match(out, "Ydiff ~ .*Cb1.*Cw1diff.*Cw1avg", perl = TRUE)
  expect_match(out, "M1diff ~ .*Cb1.*Cw1diff.*Cw1avg", perl = TRUE)
})

# Continuous moderator with MP = b1
test_that("T3a: Continuous W with MP = b1", {
  dat <- mock_data(W_type = "continuous")
  out <- GenerateModelP(dat, MP = c("a1","b1" ))

  expect_match(out, "bw1_W1\\*int_M1diff_W1")

  y_line <- strsplit(out, "\n")[[1]][1]
  m1_line <- grep("^M1diff ~", strsplit(out, "\n")[[1]], value = TRUE)

  # Check the direct-path moderator term
  if (!"cp" %in% c("b1")) {
    expect_true(grepl("cpw_W1*W1", y_line, fixed = TRUE))
  } else {
    expect_true(grepl("cpw_W1*W1", y_line, fixed = TRUE))
  }

  # Keep the moderator main effect when a1 is not listed
  expect_true(grepl("\\+\\s*(\\w+\\*)?W1", m1_line))

})

# Three-level moderator with MP = b1, d1, and cp
test_that("T3b: Factor W (3-level) with MP = b1, d1, cp", {
  dat <- mock_data(W_type = "factor3")
  out <- GenerateModelP(dat, MP = c("a1", "b1", "d1", "cp"))

  expect_match(out, "bw1_W1\\*int_M1diff_W1")
  expect_match(out, "bw1_W2\\*int_M1diff_W2")
  expect_match(out, "dw1_W1\\*int_M1avg_W1")
  expect_match(out, "dw1_W2\\*int_M1avg_W2")
  expect_match(out, "cpw_W1\\*W1")
  expect_match(out, "cpw_W2\\*W2")
})

# Binary moderator with MP = a1
test_that("T3c: Binary W with MP = a1", {
  dat <- mock_data(W_type = "binary")
  out <- GenerateModelP(dat, MP = c("a1"))

  expect_match(out, "M1diff ~ a1\\*1 \\+ aw1_W1\\*W1")

  y_line <- strsplit(out, "\n")[[1]][1]
  expect_true(grepl("cpw_W1*W1", y_line, fixed = TRUE))  # Keep the W1 main effect in the outcome-difference equation
})

