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

make_base_data <- function(n = 20) {
    data.frame(
      A1 = rnorm(n), A2 = rnorm(n),
      B1 = rnorm(n), B2 = rnorm(n),
      Y1 = rnorm(n), Y2 = rnorm(n),
      W  = sample(c("low","high"), n, TRUE)
    )
  }

call_ws <- function(
    ...,
    .data = make_base_data(),
    .form = "P"
) {

  wsMed(
    data = .data,
    M_C1 = "A1",
    M_C2 = "A2",
    Y_C1 = "Y1",
    Y_C2 = "Y2",
    form = .form,
    Na = "DE",
    verbose = FALSE,
    ...
  )
}


test_that("wsMed input validation catches all invalid scenarios", {

    ## ── data-related ───────────────────────────────────────────────────────
    expect_error(call_ws(.data = NULL),                   "cannot be NULL")
    #expect_error(call_ws(.data = character()),            "must be a data frame")

    bad <- make_base_data(); bad$A2 <- NULL
    expect_error(call_ws(.data = bad),                    "Missing columns")

    ## ── mediator / outcome mismatch ───────────────────────────────────────
    expect_error(
      wsMed(data = make_base_data(),
            M_C1 = c("A1","B1"), M_C2 = "A2",
            Y_C1 = "Y1", Y_C2 = "Y2",
            form = "P", Na = "DE", R = 10,
            verbose = FALSE),
      "lengths of M_C1 and M_C2"
    )

    ## ── W & MP consistency ────────────────────────────────────────────────
    expect_error(call_ws(W = "W",              W_type = "categorical"),
                 "must also supply")

    expect_error(call_ws(MP = "a1"),
                 "MP specified but W is NULL")

    expect_error(call_ws(W = "noCol", MP = "a1"),
                 "not a column")

    expect_error(call_ws(W = c("W","W2"), MP = "a1"),
                 "Exactly one moderator")

    ## ── integer parameters ────────────────────────────────────────────────
    expect_error(call_ws(R = -5), "R must be >= 1")
    expect_error(call_ws(R = 3.5), "whole number")   # 非整数仍匹配原文本
    expect_error(call_ws(bootstrap = 3.2),    "whole number")

    ## ── form / Na / ci_method combo ───────────────────────────────────────
    expect_error(call_ws(.form = "XYZ"),      "arg")
    expect_error(call_ws(Na   = "ABC"),       "arg")
    #expect_error(call_ws(ci_method = "bootstrap"), "`bootstrap` = 0")
  })

test_that("wsMed handles continuous moderation (CP form)", {
  set.seed(2)

  res5 <- wsMed(
    data = example_data,
    M_C1 = c("A1","B1","C1"), M_C2 = c("A2","B2","C2"),
    Y_C1 = "D1", Y_C2 = "D2",
    form = "CP",
    W      = "D3",  W_type = "continuous",
    MP     = c("a1","b2","d1","cp","b_1_2","d_1_2"),
    R = 200,
    verbose = FALSE
  )

  expect_wsMed_structure(res5)
  mod  <- res5$moderation
  expect_equal(mod$type, "continuous")
  expect_true(is.data.frame(mod$conditional_overall))
  # 三水平 × 两条(total) = 6 行
  expect_equal(nrow(mod$conditional_overall), 6)
})

test_that("wsMed handles categorical moderation with covariates", {
  skip_on_cran()
  set.seed(3)

  res6 <- wsMed(
    data = example_data,
    M_C1 = c("A1","B1","C1"),
    M_C2 = c("A2","B2","C2"),
    Y_C1 = "D1", Y_C2 = "D2",
    W      = "Group", W_type = "categorical",
    MP     = c("a1","b1","d1","cp","b_1_2","b_2_3"),
    form   = "CN",
    C      = "D3",
    fixed.x = TRUE,
    R = 200,
    verbose = FALSE
  )

  expect_wsMed_structure(res6)
  mod <- res6$moderation
  expect_equal(mod$type, "categorical")
  g <- length(unique(example_data$Group))
  expect_equal(nrow(mod$conditional_overall), g * 2)
  expect_named(mod$extra, c("path_levels","path_contrasts"))
})


test_that("wsMed handles missing data with standardized effects (MI)", {
  skip_on_cran()                       # MICE + lavaan 稍慢
  set.seed(987)

  # ── 1. 造一个含缺失数据集 (10%) ──────────────────────────────
  dat_mis <- suppressWarnings(
    mice::ampute(example_data, prop = 0.10)$amp
  )

  # ── 2. 调 wsMed() — MI + standardized ─────────────────────
  res_mi <- wsMed(
    data = example_dataN,
    M_C1 = c("A1","B1"),  M_C2 = c("A2","B2"),
    Y_C1 = "C1",          Y_C2 = "C2",
    form = "P",
    Na   = "MI",
    mi_args = list(m = 3),
    R = 200,
    standardized = TRUE,
    verbose = FALSE
  )

  # ── 3. 结构断言 ─────────────────────────────────────────────
  expect_wsMed_structure(res_mi)
  expect_equal(res_mi$Na, "MI")

  # mc$std 应已填充
  expect_true(!is.null(res_mi$mc$std))
  expect_s3_class(res_mi$mc$std, "data.frame")

  # moderation 无调节 → type = "none"
  expect_equal(res_mi$moderation$type, "none")
})




# ============================================================================
# User-defined mediation model
# ============================================================================

test_that("wsMed handles a user-defined mediation model", {

  ## Ensure that normal verbose output is separated from debug output
  old_debug <- getOption("wsMed.debug")
  options(wsMed.debug = FALSE)

  on.exit(
    options(wsMed.debug = old_debug),
    add = TRUE
  )

  paths_ud <- c(
    "M1 -> M3",
    "M3 -> Y",
    "M2 -> Y"
  )

  ## Capture progress messages while fitting the model
  messages <- capture.output(
    res_ud <- wsMed(
      data = example_data,
      M_C1 = c("A1", "B1", "C1"),
      M_C2 = c("A2", "B2", "C2"),
      Y_C1 = "D1",
      Y_C2 = "D2",
      form = "UD",
      paths = paths_ud,
      Na = "DE",
      ci_method = "mc",
      R = 100,
      standardized = FALSE,
      verbose = TRUE
    ),
    type = "message"
  )

  ## ----------------------------------------------------------------
  ## Check the returned wsMed object
  ## ----------------------------------------------------------------

  expect_wsMed_structure(res_ud)

  expect_s3_class(
    res_ud,
    "wsMed"
  )

  expect_equal(
    res_ud$form,
    "UD"
  )

  expect_equal(
    res_ud$paths,
    paths_ud
  )

  expect_equal(
    res_ud$Na,
    "DE"
  )

  expect_equal(
    res_ud$ci_method,
    "mc"
  )

  ## ----------------------------------------------------------------
  ## Check progress messages
  ## ----------------------------------------------------------------

  expect_true(
    any(grepl(
      "Preparing data",
      messages
    ))
  )

  expect_true(
    any(grepl(
      "Building SEM syntax \\(UD\\)",
      messages
    ))
  )

  expect_true(
    any(grepl(
      "Na = DE",
      messages
    ))
  )

  expect_true(
    any(grepl(
      "ci_method = mc",
      messages
    ))
  )

  expect_true(
    any(grepl(
      "Monte-Carlo draws",
      messages
    ))
  )

  expect_true(
    any(grepl(
      "Analysis completed successfully",
      messages
    ))
  )

  ## Debug information should not be displayed by default
  expect_false(
    any(grepl(
      "\\[DBG\\]",
      messages
    ))
  )

  ## ----------------------------------------------------------------
  ## Check lavaan model estimation
  ## ----------------------------------------------------------------

  expect_s4_class(
    res_ud$mc$fit,
    "lavaan"
  )

  expect_true(
    lavaan::lavInspect(
      res_ud$mc$fit,
      "converged"
    )
  )

  expect_true(
    lavaan::lavInspect(
      res_ud$mc$fit,
      "post.check"
    )
  )

  expect_true(
    !is.null(res_ud$mc$result)
  )

  expect_equal(
    nrow(res_ud$mc$result$thetahatstar),
    100
  )

  ## ----------------------------------------------------------------
  ## Check the generated regression equations
  ## ----------------------------------------------------------------

  model_lines <- trimws(
    strsplit(
      res_ud$sem_model,
      "\n",
      fixed = TRUE
    )[[1]]
  )

  y_line <- grep(
    "^Ydiff ~",
    model_lines,
    value = TRUE
  )

  m1_line <- grep(
    "^M1diff ~",
    model_lines,
    value = TRUE
  )

  m2_line <- grep(
    "^M2diff ~",
    model_lines,
    value = TRUE
  )

  m3_line <- grep(
    "^M3diff ~",
    model_lines,
    value = TRUE
  )

  expect_length(y_line, 1L)
  expect_length(m1_line, 1L)
  expect_length(m2_line, 1L)
  expect_length(m3_line, 1L)

  ## M2 -> Y
  expect_match(
    y_line,
    "b2\\*M2diff"
  )

  expect_match(
    y_line,
    "d2\\*M2avg"
  )

  ## M3 -> Y
  expect_match(
    y_line,
    "b3\\*M3diff"
  )

  expect_match(
    y_line,
    "d3\\*M3avg"
  )

  ## M1 -> M3
  expect_match(
    m3_line,
    "b_1_3\\*M1diff"
  )

  expect_match(
    m3_line,
    "d_1_3\\*M1avg"
  )

  ## Each mediator has an a-path represented by its intercept
  expect_match(
    m1_line,
    "a1\\*1"
  )

  expect_match(
    m2_line,
    "a2\\*1"
  )

  expect_match(
    m3_line,
    "a3\\*1"
  )

  ## ----------------------------------------------------------------
  ## Check that unspecified paths were not added
  ## ----------------------------------------------------------------

  ## No M1 -> Y
  expect_false(
    grepl(
      "b1\\*M1diff",
      y_line
    )
  )

  expect_false(
    grepl(
      "d1\\*M1avg",
      y_line
    )
  )

  ## No M1 -> M2
  expect_false(
    grepl(
      "b_1_2\\*M1diff",
      m2_line
    )
  )

  expect_false(
    grepl(
      "d_1_2\\*M1avg",
      m2_line
    )
  )

  ## No M2 -> M3
  expect_false(
    grepl(
      "b_2_3\\*M2diff",
      m3_line
    )
  )

  expect_false(
    grepl(
      "d_2_3\\*M2avg",
      m3_line
    )
  )

  ## ----------------------------------------------------------------
  ## Check indirect-effect syntax
  ## ----------------------------------------------------------------

  indirect_lines <- grep(
    "^indirect_[0-9_]+ :=",
    model_lines,
    value = TRUE
  )

  expect_setequal(
    indirect_lines,
    c(
      "indirect_1_3 := a1 * b_1_3 * b3",
      "indirect_2 := a2 * b2",
      "indirect_3 := a3 * b3"
    )
  )

  total_indirect_line <- grep(
    "^total_indirect :=",
    model_lines,
    value = TRUE
  )

  total_effect_line <- grep(
    "^total_effect :=",
    model_lines,
    value = TRUE
  )

  expect_length(
    total_indirect_line,
    1L
  )

  expect_length(
    total_effect_line,
    1L
  )

  expect_match(
    total_indirect_line,
    "\\bindirect_1_3\\b"
  )

  expect_match(
    total_indirect_line,
    "\\bindirect_2\\b"
  )

  expect_match(
    total_indirect_line,
    "\\bindirect_3\\b"
  )

  expect_equal(
    total_effect_line,
    "total_effect := cp + total_indirect"
  )

  ## ----------------------------------------------------------------
  ## Check indirect effects in the Monte Carlo output
  ## ----------------------------------------------------------------

  effect_names <- names(
    res_ud$mc$result$thetahat$est
  )

  indirect_names <- grep(
    "^indirect_",
    effect_names,
    value = TRUE
  )

  expect_setequal(
    indirect_names,
    c(
      "indirect_1_3",
      "indirect_2",
      "indirect_3"
    )
  )

  expect_true(
    "total_indirect" %in% effect_names
  )

  expect_true(
    "total_effect" %in% effect_names
  )

  ## ----------------------------------------------------------------
  ## Check the no-moderator result
  ## ----------------------------------------------------------------

  expect_equal(
    res_ud$moderation$type,
    "none"
  )

  expect_true(
    is.data.frame(
      res_ud$moderation$IE_contrasts
    )
  )

  expect_equal(
    nrow(res_ud$moderation$IE_contrasts),
    3L
  )
})


# ============================================================================
# Validation of paths in wsMed
# ============================================================================

test_that("form UD requires paths", {

  expect_error(
    wsMed(
      data = example_data,
      M_C1 = c("A1", "B1", "C1"),
      M_C2 = c("A2", "B2", "C2"),
      Y_C1 = "D1",
      Y_C2 = "D2",
      form = "UD",
      paths = NULL,
      Na = "DE",
      R = 10,
      verbose = FALSE
    ),
    "paths.*must be supplied"
  )
})


test_that("form UD requires paths to be a character vector", {

  expect_error(
    wsMed(
      data = example_data,
      M_C1 = c("A1", "B1", "C1"),
      M_C2 = c("A2", "B2", "C2"),
      Y_C1 = "D1",
      Y_C2 = "D2",
      form = "UD",
      paths = 123,
      Na = "DE",
      R = 10,
      verbose = FALSE
    ),
    "paths.*non-empty character vector"
  )
})


test_that("form UD rejects an empty paths vector", {

  expect_error(
    wsMed(
      data = example_data,
      M_C1 = c("A1", "B1", "C1"),
      M_C2 = c("A2", "B2", "C2"),
      Y_C1 = "D1",
      Y_C2 = "D2",
      form = "UD",
      paths = character(0),
      Na = "DE",
      R = 10,
      verbose = FALSE
    ),
    "paths.*non-empty character vector"
  )
})


test_that("paths cannot be supplied to predefined model forms", {

  expect_error(
    wsMed(
      data = example_data,
      M_C1 = c("A1", "B1"),
      M_C2 = c("A2", "B2"),
      Y_C1 = "C1",
      Y_C2 = "C2",
      form = "P",
      paths = c(
        "M1 -> Y",
        "M2 -> Y"
      ),
      Na = "DE",
      R = 10,
      verbose = FALSE
    ),
    "paths.*only be supplied"
  )
})
