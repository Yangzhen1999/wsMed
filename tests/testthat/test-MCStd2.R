library(semmcci)
library(lavaan)
library(testthat)
library(lavaan)
library(semboottools)
library(wsMed)

test_that("MCStd2 works correctly with valid semmcci object", {
  # Build a simple model
  model <- "
    m ~ a*x
    y ~ b*m + cp*x
    ab := a*b
    total := ab + cp
  "
  set.seed(123)
  n <- 200
  x <- rnorm(n)
  m <- 0.5 * x + rnorm(n)
  y <- 0.6 * m + 0.3 * x + rnorm(n)
  dat <- data.frame(x, m, y)

  fit <- lavaan::sem(model, data = dat, fixed.x = FALSE)

  # Generate a Monte Carlo object
  mc <- semmcci::MC(
    lav = fit,
    R = 200,
    alpha = c(0.05),
    decomposition = "eigen",
    pd = TRUE,
    seed = 123
  )

  # Call MCStd2
  std_result <- MCStd2(mc, alpha = c(0.05, 0.01))

  # Check the output class
  expect_s3_class(std_result, "data.frame")

  # Check required columns
  expected_cols <- c("Parameter", "Estimate", "SE", "R", "2.5%", "97.5%", "0.5%", "99.5%")
  expect_true(all(expected_cols %in% colnames(std_result)))

  # Check table dimensions
  expect_true(nrow(std_result) >= 4)
  expect_true(is.numeric(std_result$Estimate))
  expect_true(is.numeric(std_result$SE))
  expect_true(all(!is.na(std_result$Estimate)))

  # Check the draw count
  expect_equal(unique(std_result$R), 200)
})

test_that("MCStd2 gives error on non-semmcci input", {
  dummy <- list()
  class(dummy) <- "not_semmcci"

  expect_error(MCStd2(dummy), "inherits\\(mc, \"semmcci\"\\)")
})
