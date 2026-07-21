# test-GenerateModelCustom.R

library(testthat)


## ======================================================================
## Helper functions
## ======================================================================

mock_data_custom <- function(
    n = 100,
    n_mediators = 3,
    include_C = FALSE,
    W_type = NULL
) {

  dat <- data.frame(
    Ydiff = rnorm(n)
  )

  for (i in seq_len(n_mediators)) {
    dat[[paste0("M", i, "diff")]] <- rnorm(n)
    dat[[paste0("M", i, "avg")]]  <- rnorm(n)
  }

  if (include_C) {
    dat$Cb1     <- rnorm(n)
    dat$Cw1diff <- rnorm(n)
    dat$Cw1avg  <- rnorm(n)
  }

  if (identical(W_type, "continuous")) {
    dat$W1 <- as.numeric(scale(rnorm(n)))

    for (i in seq_len(n_mediators)) {
      dat[[paste0("int_M", i, "diff_W1")]] <-
        dat[[paste0("M", i, "diff")]] * dat$W1

      dat[[paste0("int_M", i, "avg_W1")]] <-
        dat[[paste0("M", i, "avg")]] * dat$W1
    }

    attr(dat, "W_info") <- list(type = "continuous")
  }

  if (identical(W_type, "binary")) {
    dat$W1 <- rep(0:1, length.out = n)

    for (i in seq_len(n_mediators)) {
      dat[[paste0("int_M", i, "diff_W1")]] <-
        dat[[paste0("M", i, "diff")]] * dat$W1

      dat[[paste0("int_M", i, "avg_W1")]] <-
        dat[[paste0("M", i, "avg")]] * dat$W1
    }

    attr(dat, "W_info") <- list(type = "categorical")
  }

  if (identical(W_type, "factor3")) {
    dat$W1 <- rep(c(0, 1, 0), length.out = n)
    dat$W2 <- rep(c(0, 0, 1), length.out = n)

    for (i in seq_len(n_mediators)) {
      for (w in c("W1", "W2")) {
        dat[[paste0("int_M", i, "diff_", w)]] <-
          dat[[paste0("M", i, "diff")]] * dat[[w]]

        dat[[paste0("int_M", i, "avg_", w)]] <-
          dat[[paste0("M", i, "avg")]] * dat[[w]]
      }
    }

    attr(dat, "W_info") <- list(type = "categorical")
  }

  dat
}


get_model_lines <- function(model) {
  trimws(strsplit(model, "\n", fixed = TRUE)[[1]])
}


get_indirect_lines <- function(model) {
  lines <- get_model_lines(model)

  grep(
    "^indirect_[0-9_]+\\s*:=",
    lines,
    value = TRUE
  )
}


get_regression_line <- function(model, outcome) {
  lines <- get_model_lines(model)

  grep(
    paste0("^", outcome, "\\s*~"),
    lines,
    value = TRUE
  )
}


## ======================================================================
## T1: Custom parallel model
## ======================================================================

test_that("Custom parallel model is generated correctly", {

  dat <- mock_data_custom(n_mediators = 3)

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> Y",
      "M2 -> Y",
      "M3 -> Y"
    )
  )

  y_line <- get_regression_line(model, "Ydiff")

  expect_match(y_line, "cp\\*1")
  expect_match(y_line, "b1\\*M1diff")
  expect_match(y_line, "d1\\*M1avg")
  expect_match(y_line, "b2\\*M2diff")
  expect_match(y_line, "d2\\*M2avg")
  expect_match(y_line, "b3\\*M3diff")
  expect_match(y_line, "d3\\*M3avg")

  expect_equal(
    get_regression_line(model, "M1diff"),
    "M1diff ~ a1*1"
  )

  expect_equal(
    get_regression_line(model, "M2diff"),
    "M2diff ~ a2*1"
  )

  expect_equal(
    get_regression_line(model, "M3diff"),
    "M3diff ~ a3*1"
  )

  expect_setequal(
    get_indirect_lines(model),
    c(
      "indirect_1 := a1 * b1",
      "indirect_2 := a2 * b2",
      "indirect_3 := a3 * b3"
    )
  )

  total_indirect_line <- grep(
    "^total_indirect :=",
    get_model_lines(model),
    value = TRUE
  )

  expect_length(total_indirect_line, 1L)

  expect_equal(
    total_indirect_line,
    paste0(
      "total_indirect := ",
      "indirect_1 + indirect_2 + indirect_3"
    )
  )

})


## ======================================================================
## T2: Pure serial model
## ======================================================================

test_that("Custom serial model identifies all serial indirect effects", {

  dat <- mock_data_custom(n_mediators = 3)

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M2 -> M3",
      "M3 -> Y"
    )
  )

  m2_line <- get_regression_line(model, "M2diff")
  m3_line <- get_regression_line(model, "M3diff")
  y_line  <- get_regression_line(model, "Ydiff")

  expect_match(m2_line, "b_1_2\\*M1diff")
  expect_match(m2_line, "d_1_2\\*M1avg")

  expect_match(m3_line, "b_2_3\\*M2diff")
  expect_match(m3_line, "d_2_3\\*M2avg")

  expect_match(y_line, "b3\\*M3diff")
  expect_match(y_line, "d3\\*M3avg")

  expect_false(grepl("b1\\*M1diff", y_line))
  expect_false(grepl("b2\\*M2diff", y_line))

  expect_setequal(
    get_indirect_lines(model),
    c(
      "indirect_1_2_3 := a1 * b_1_2 * b_2_3 * b3",
      "indirect_2_3 := a2 * b_2_3 * b3",
      "indirect_3 := a3 * b3"
    )
  )
})


## ======================================================================
## T3: Branching custom model
## ======================================================================

test_that("All indirect effects are identified in a branching model", {

  dat <- mock_data_custom(n_mediators = 3)

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M1 -> M3",
      "M2 -> M3",
      "M2 -> Y",
      "M3 -> Y"
    )
  )

  expect_setequal(
    get_indirect_lines(model),
    c(
      "indirect_1_2 := a1 * b_1_2 * b2",
      "indirect_1_2_3 := a1 * b_1_2 * b_2_3 * b3",
      "indirect_1_3 := a1 * b_1_3 * b3",
      "indirect_2 := a2 * b2",
      "indirect_2_3 := a2 * b_2_3 * b3",
      "indirect_3 := a3 * b3"
    )
  )

  total_line <- grep(
    "^total_indirect :=",
    get_model_lines(model),
    value = TRUE
  )

  indirect_names <- sub(
    "\\s*:=.*$",
    "",
    get_indirect_lines(model)
  )

  for (indirect_name in indirect_names) {
    expect_match(
      total_line,
      paste0("\\b", indirect_name, "\\b")
    )
  }
})


## ======================================================================
## T4: Mediator numbering does not determine path direction
## ======================================================================

test_that("Paths can run from a higher-numbered to a lower-numbered mediator", {

  dat <- mock_data_custom(n_mediators = 3)

  expect_warning(
    model <- GenerateModelCustom(
      prepared_data = dat,
      paths = c(
        "M3 -> M1",
        "M1 -> Y"
      )
    ),
    "M2"
  )

  m1_line <- get_regression_line(model, "M1diff")

  expect_match(m1_line, "b_3_1\\*M3diff")
  expect_match(m1_line, "d_3_1\\*M3avg")

  expect_setequal(
    get_indirect_lines(model),
    c(
      "indirect_1 := a1 * b1",
      "indirect_3_1 := a3 * b_3_1 * b1"
    )
  )
})
## ======================================================================
## T5: Covariates
## ======================================================================

test_that("Between- and within-subject covariates are added to all regressions", {

  dat <- mock_data_custom(
    n_mediators = 2,
    include_C = TRUE
  )

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M2 -> Y"
    )
  )

  regression_lines <- c(
    get_regression_line(model, "Ydiff"),
    get_regression_line(model, "M1diff"),
    get_regression_line(model, "M2diff")
  )

  for (line in regression_lines) {
    expect_match(line, "\\bCb1\\b")
    expect_match(line, "\\bCw1diff\\b")
    expect_match(line, "\\bCw1avg\\b")
  }
})


## ======================================================================
## T6: Continuous moderation
## ======================================================================

test_that("Continuous moderator terms are added to the correct equations", {

  dat <- mock_data_custom(
    n_mediators = 2,
    W_type = "continuous"
  )

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M2 -> Y"
    ),
    MP = c(
      "a2",
      "b_1_2",
      "d_1_2",
      "b2",
      "d2",
      "cp"
    )
  )

  m1_line <- get_regression_line(model, "M1diff")
  m2_line <- get_regression_line(model, "M2diff")
  y_line  <- get_regression_line(model, "Ydiff")

  expect_match(m1_line, "\\+ W1")

  expect_match(m2_line, "aw2_W1\\*W1")
  expect_match(m2_line, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(m2_line, "dw_1_2_W1\\*int_M1avg_W1")

  expect_match(y_line, "cpw_W1\\*W1")
  expect_match(y_line, "bw2_W1\\*int_M2diff_W1")
  expect_match(y_line, "dw2_W1\\*int_M2avg_W1")

  expect_false(grepl("\\+ W1(?:\\s*\\+|\\s*$)", m2_line, perl = TRUE))
  expect_false(grepl("\\+ W1(?:\\s*\\+|\\s*$)", y_line, perl = TRUE))
})


## ======================================================================
## T7: Categorical moderator
## ======================================================================

test_that("Categorical moderator generates terms for all dummy variables", {

  dat <- mock_data_custom(
    n_mediators = 2,
    W_type = "factor3"
  )

  model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M2 -> Y"
    ),
    MP = c(
      "b_1_2",
      "d_1_2",
      "b2",
      "cp"
    )
  )

  expect_match(model, "bw_1_2_W1\\*int_M1diff_W1")
  expect_match(model, "bw_1_2_W2\\*int_M1diff_W2")

  expect_match(model, "dw_1_2_W1\\*int_M1avg_W1")
  expect_match(model, "dw_1_2_W2\\*int_M1avg_W2")

  expect_match(model, "bw2_W1\\*int_M2diff_W1")
  expect_match(model, "bw2_W2\\*int_M2diff_W2")

  expect_match(model, "cpw_W1\\*W1")
  expect_match(model, "cpw_W2\\*W2")
})


## ======================================================================
## T8: Reproduce existing parallel model
## ======================================================================

test_that("Custom model reproduces the core parallel model structure", {

  dat <- mock_data_custom(n_mediators = 3)

  custom_model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> Y",
      "M2 -> Y",
      "M3 -> Y"
    )
  )

  parallel_model <- GenerateModelP(dat)

  custom_lines   <- get_model_lines(custom_model)
  parallel_lines <- get_model_lines(parallel_model)

  expect_equal(
    get_regression_line(custom_model, "Ydiff"),
    get_regression_line(parallel_model, "Ydiff")
  )

  expect_setequal(
    grep("^M[0-9]+diff ~", custom_lines, value = TRUE),
    grep("^M[0-9]+diff ~", parallel_lines, value = TRUE)
  )

  expect_setequal(
    get_indirect_lines(custom_model),
    get_indirect_lines(parallel_model)
  )
})


## ======================================================================
## T9: Reproduce existing chained model
## ======================================================================

test_that("Custom model reproduces the core chained model structure", {

  dat <- mock_data_custom(n_mediators = 3)

  custom_model <- GenerateModelCustom(
    prepared_data = dat,
    paths = c(
      "M1 -> M2",
      "M1 -> M3",
      "M2 -> M3",
      "M1 -> Y",
      "M2 -> Y",
      "M3 -> Y"
    )
  )

  chained_model <- GenerateModelCN(dat)

  expect_equal(
    get_regression_line(custom_model, "Ydiff"),
    get_regression_line(chained_model, "Ydiff")
  )

  expect_setequal(
    grep(
      "^M[0-9]+diff ~",
      get_model_lines(custom_model),
      value = TRUE
    ),
    grep(
      "^M[0-9]+diff ~",
      get_model_lines(chained_model),
      value = TRUE
    )
  )

  expect_setequal(
    get_indirect_lines(custom_model),
    get_indirect_lines(chained_model)
  )
})


## ======================================================================
## T10: Input validation
## ======================================================================

test_that("Invalid path syntax produces an informative error", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = "M1 - M2"
    ),
    "Invalid path specification"
  )

  expect_error(
    GenerateModelCustom(
      dat,
      paths = "Y -> M1"
    ),
    "Invalid path specification"
  )
})


test_that("Unknown mediators produce an informative error", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M3",
        "M3 -> Y"
      )
    ),
    "not available"
  )
})


test_that("Duplicated paths are rejected", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M2",
        "M1->M2",
        "M2 -> Y"
      )
    ),
    "Duplicated path"
  )
})


test_that("Self-loops are rejected", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M1",
        "M1 -> Y"
      )
    ),
    "Self-loops"
  )
})


test_that("Cyclic models are rejected", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M2",
        "M2 -> M1",
        "M2 -> Y"
      )
    ),
    "acyclic|cycle"
  )
})


test_that("At least one path must end in Y", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = "M1 -> M2"
    ),
    "At least one mediator must have a path to `Y`"
  )
})


test_that("Missing level components are detected", {

  dat <- mock_data_custom(n_mediators = 2)
  dat$M2avg <- NULL

  expect_error(
    GenerateModelCustom(
      dat,
      paths = "M2 -> Y"
    ),
    "level components are missing"
  )
})


test_that("Unknown MP labels are rejected", {

  dat <- mock_data_custom(
    n_mediators = 2,
    W_type = "continuous"
  )

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M2",
        "M2 -> Y"
      ),
      MP = "b_2_1"
    ),
    "Unknown path label"
  )
})


test_that("MP requires a moderator variable", {

  dat <- mock_data_custom(n_mediators = 2)

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M2",
        "M2 -> Y"
      ),
      MP = "b_1_2"
    ),
    "no moderator variables"
  )
})


test_that("Missing interaction variables are detected", {

  dat <- mock_data_custom(n_mediators = 2)
  dat$W1 <- rnorm(nrow(dat))

  expect_error(
    GenerateModelCustom(
      dat,
      paths = c(
        "M1 -> M2",
        "M2 -> Y"
      ),
      MP = "b_1_2"
    ),
    "interaction variables.*missing"
  )
})
