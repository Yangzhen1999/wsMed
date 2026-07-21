library(testthat)

data("example_data", package = "wsMed")

set.seed(123)

example_dataN <- suppressWarnings(
  mice::ampute(
    data = example_data,
    prop = 0.1
  )$amp
)

expect_wsMed_structure <- function(obj) {

  expect_s3_class(obj, "wsMed")

  expect_setequal(
    names(obj),
    c(
      "Na",
      "alpha",
      "ci_method",
      "data",
      "fit_u",
      "form",
      "paths",
      "input_vars",
      "mc",
      "moderation",
      "param_boot",
      "sem_model"
    )
  )

  expect_true(
    !is.null(obj$mc$result$thetahatstar)
  )
}


# ── helper: 生成 wsMed 对象 (快速) ------------------------------------------
quick_ws <- function(..., .data = example_data) {

  wsMed(
    data = .data,
    M_C1 = c("A1", "B1"),
    M_C2 = c("A2", "B2"),
    Y_C1 = "C1",
    Y_C2 = "C2",
    form = "P",
    Na = "DE",
    ci_method = "mc",
    R = 80,
    verbose = FALSE,
    ...
  )
}

# ── 1. No-moderation print smoke-test --------------------------------------
test_that("print.wsMed works without moderator", {
  obj <- quick_ws()
  expect_invisible( out <- capture.output(print(obj, digits = 2)) )
  expect_true(any(grepl("VARIABLES",          out)))
  expect_true(any(grepl("MODEL FIT",          out)))
  expect_true(any(grepl("TOTAL / DIRECT",     out)))
  # 无调节 → 不应出现 MODERATION RESULTS
  expect_false(any(grepl("MODERATION RESULTS", out)))
})

# ── 2. Continuous moderation ------------------------------------------------
test_that("print.wsMed shows continuous moderation sections", {
  obj <- quick_ws(W = "D3", W_type = "continuous", MP = "a1")
  out <- capture.output(print(obj, digits = 2))
  expect_true(any(grepl("MODERATION RESULTS \\(Continuous", out)))
  expect_true(any(grepl("Conditional Total Effect",         out)))
})

# ── 3. Categorical moderation ---------------------------------------------
test_that("print.wsMed shows categorical moderation sections", {
  skip_on_cran()
  obj <- quick_ws(W = "Group", W_type = "categorical",
                  MP = "a1")
  out <- capture.output(print(obj, digits = 2))
  expect_true(any(grepl("MODERATION RESULTS \\(Categorical", out)))
  expect_true(any(grepl("Conditional Indirect Effects",      out)))
})


# tests/testthat/test-wsMed-structure.R  （或你喜欢的文件）

test_that("wsMed handles missing data with standardized effects (FIML)", {
  set.seed(4242)

  res_fiml <- wsMed(
    data = example_dataN,
    M_C1 = c("A1","B1"),
    M_C2 = c("A2","B2"),
    Y_C1 = "C1",
    Y_C2 = "C2",
    W      = "D3",
    W_type = "continuous",
    MP     = "a1",
    form   = "P",
    Na     = "FIML",
    R      = 200,
    standardized = TRUE
  )

  # ---- 结构与关键插槽断言 -------------------------------
  expect_wsMed_structure(res_fiml)
  expect_equal(res_fiml$Na, "FIML")
  expect_true(!is.null(res_fiml$mc$std))            # standardized 结果应存在
  expect_equal(res_fiml$moderation$type, "continuous")
})


# ============================================================================
# User-defined model
# ============================================================================

test_that("print.wsMed works for a user-defined model", {

  paths_ud <- c(
    "M1 -> M3",
    "M3 -> Y",
    "M2 -> Y"
  )

  obj <- wsMed(
    data = example_data,
    M_C1 = c("A1", "B1", "C1"),
    M_C2 = c("A2", "B2", "C2"),
    Y_C1 = "D1",
    Y_C2 = "D2",
    form = "UD",
    paths = paths_ud,
    Na = "DE",
    ci_method = "mc",
    R = 80,
    standardized = FALSE,
    verbose = FALSE
  )

  ## Check the object before testing the print method
  expect_wsMed_structure(obj)

  expect_equal(
    obj$form,
    "UD"
  )

  expect_equal(
    obj$paths,
    paths_ud
  )

  ## Capture console output produced by print.wsMed()
  out <- capture.output(
    print(
      obj,
      digits = 2
    )
  )

  ## Basic output sections
  expect_true(
    any(grepl(
      "VARIABLES",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "MODEL FIT",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "TOTAL / DIRECT / TOTAL-IND",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "REGRESSION PATHS",
      out,
      fixed = TRUE
    ))
  )

  ## Check the three indirect-effect labels
  expect_true(
    any(grepl(
      "ind_1_3",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "ind_2",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "ind_3",
      out,
      fixed = TRUE
    ))
  )

  ## Check the indirect-effect key
  expect_true(
    any(grepl(
      "X -> M1diff -> M3diff -> Ydiff",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "X -> M2diff -> Ydiff",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "X -> M3diff -> Ydiff",
      out,
      fixed = TRUE
    ))
  )

  ## Check the user-defined regression paths
  expect_true(
    any(grepl(
      "M3diff ~ M1diff",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "Ydiff ~ M2diff",
      out,
      fixed = TRUE
    ))
  )

  expect_true(
    any(grepl(
      "Ydiff ~ M3diff",
      out,
      fixed = TRUE
    ))
  )

  ## Paths that were not specified should not be printed
  expect_false(
    any(grepl(
      "Ydiff ~ M1diff",
      out,
      fixed = TRUE
    ))
  )

  expect_false(
    any(grepl(
      "M2diff ~ M1diff",
      out,
      fixed = TRUE
    ))
  )

  expect_false(
    any(grepl(
      "M3diff ~ M2diff",
      out,
      fixed = TRUE
    ))
  )
})
