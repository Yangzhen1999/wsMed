library(testthat)


# Test ImputeData structure and automatic method selection

# Toy data with missing values
set.seed(123)
toy <- data.frame(
  num1 = c(rnorm(10), NA, rnorm(9)),                         # numeric → pmm
  num2 = c(rnorm(5), NA, rnorm(14)),                         # numeric → pmm
  fac2 = factor(sample(c("A", "B"), 20, TRUE)),              # 2-level factor → logreg
  fac3 = factor(sample(c("low", "med", "high"), 20, TRUE))   # 3-level factor → polyreg
)
toy$num1[3] <- NA
toy$fac2[6] <- NA
toy$fac3[7] <- NA

# Check output structure and return values
test_that("ImputeData returns mids + list + summary", {
  out <- ImputeData(toy, m = 2, method = NULL)
  expect_s3_class(out$mids, "mids")
  expect_equal(length(out$imputed_data_list), 2)
  expect_true(is.list(out$summary))
})

# Completed datasets contain no missing values
test_that("Imputed data contains no NA", {
  out <- ImputeData(toy, m = 2, method = NULL)
  for (d in out$imputed_data_list)
    expect_false(anyNA(d))
})

# Select methods automatically when method is NULL
test_that("Auto method selection: pmm, logreg, polyreg", {
  out <- ImputeData(toy, m = 1, method = NULL)
  methods_used <- out$mids$method

  expect_equal(unname(methods_used["num1"]), "pmm",    ignore_attr = TRUE)
  expect_equal(unname(methods_used["num2"]), "pmm",    ignore_attr = TRUE)
  expect_equal(unname(methods_used["fac2"]), "logreg", ignore_attr = TRUE)
  expect_equal(unname(methods_used["fac3"]), "polyreg", ignore_attr = TRUE)
})

# Expand a single pmm method across variables
test_that("Single method string is broadcast", {
  out <- ImputeData(toy, m = 1, method = "pmm")
  methods_used <- out$mids$method
  expect_true(all(methods_used == "pmm"))
})

# Reject a method vector of the wrong length
test_that("Method length mismatch triggers error", {
  expect_error(
    ImputeData(toy, m = 1, method = rep("pmm", 2)),
    "Length of 'method'"
  )
})

# Reject invalid input types
test_that("Non-data.frame input raises error", {
  expect_error(
    ImputeData(list(a = 1:3, b = 4:6), m = 1),
    "data.frame"
  )
})

# Check predictor-matrix dimensions
test_that("predictorMatrix is correctly generated", {
  out <- ImputeData(toy, m = 1, method = NULL)
  pm <- out$mids$predictorMatrix
  expect_equal(dim(pm), c(ncol(toy), ncol(toy)))
})
