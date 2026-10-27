library(semmcci)
library(lavaan)
library(testthat)
library(lavaan)
library(semboottools)
library(wsMed)

test_that("MCMI2 returns correct semmcci object structure", {
  # Build an example model
  model <- "
    Ydiff ~ b1 * M1diff + cp * 1
    M1diff ~ a1 * 1
    indirect := a1 * b1
    total := cp + indirect
  "

  # Construct imputed datasets
  set.seed(123)
  imputations <- list(
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
    data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
  )

  # Call the function
  result <- MCMI2(
    sem_model = model,
    imputations = imputations,
    R = 1000,
    alpha = c(0.05, 0.01),
    seed = 456
  )

  # Check the output class
  expect_s3_class(result, "semmcci")
  expect_true(all(c("call", "args", "thetahat", "thetahatstar", "fun") %in% names(result)))
  expect_equal(result$fun, "MCMI")

  # Check the parameter structure
  expect_type(result$thetahat$est, "double")
  expect_true(is.matrix(result$thetahatstar))
  expect_equal(nrow(result$thetahatstar), 1000)

  # Parameter names match the draw-matrix columns
  expect_equal(colnames(result$thetahatstar), names(result$thetahat$est))

  # Check argument metadata
  expect_true(is.list(result$args))
  expect_equal(result$args$R, 1000)
  expect_equal(result$args$alpha, c(0.05, 0.01))
  expect_equal(result$args$decomposition, "eigen")
  expect_equal(result$args$seed, 456)
})

test_that("MCMI2 fails with wrong input types", {
  bad_model <- 123
  bad_imputations <- list(1:10, 1:10)

  expect_error(MCMI2(bad_model, imputations = list(data.frame(x = 1:10))),
               "is.character")

  expect_error(MCMI2("x ~ y", imputations = bad_imputations),
               "is.list\\(imputations\\) && all\\(sapply\\(imputations, is.data.frame\\)\\)")
})
