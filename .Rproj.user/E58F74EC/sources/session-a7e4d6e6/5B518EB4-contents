library(testthat)
library(lavaan)
library(semboottools)
library(wsMed)

data(example_data)
  set.seed(123)
  example_dataN <- mice::ampute(
    data = example_data,
    prop = 0.1,
  )$amp

## 小工具：断言顶层字段齐全
expect_wsMed_structure <- function(obj) {
    expect_s3_class(obj, "wsMed")
    expect_named(obj,
                 c("data","sem_model","input_vars","mc",
                   "moderation","alpha","Na","form"),
                 ignore.order = TRUE)

    expect_true(!is.null(obj$mc$result$thetahatstar))
  }


make_base_data <- function(n = 20) {
    data.frame(
      A1 = rnorm(n), A2 = rnorm(n),
      B1 = rnorm(n), B2 = rnorm(n),
      Y1 = rnorm(n), Y2 = rnorm(n),
      W  = sample(c("low","high"), n, TRUE)
    )
  }

call_ws <- function(..., .data = make_base_data()) {
    wsMed(data   = .data,
          M_C1   = "A1",
          M_C2   = "A2",
          Y_C1   = "Y1",
          Y_C2   = "Y2",
          form   = "P",
          Na     = "DE",
          verbose = FALSE,
          ...)
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
    expect_error(call_ws(form = "XYZ"),       "arg")
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
