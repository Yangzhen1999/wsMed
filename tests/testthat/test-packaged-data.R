test_that("manuscript data preserve prepared values and missingness", {
  e <- new.env(parent = emptyenv())
  utils::data("wsmed_examples", package = "wsMed", envir = e)
  d <- e$wsmed_examples
  expect_identical(class(d), "data.frame")
  expect_identical(dim(d), c(123L, 14L))
  expect_true(all(vapply(d, is.numeric, logical(1))))
  counts <- c(TSRQ_T1 = 1, TSRQ_T2 = 22, WEMBS_T1 = 0, WEMBS_T2 = 22,
    SMUF_T1 = 8, SMUF_T2 = 18, ISI_T1 = 0, ISI_T2 = 19, DASSS_T1 = 0,
    DASSS_T2 = 23, HES_T1 = 0, HES_T2 = 20, Age = 0, BMI = 13)
  expect_identical(names(d), names(counts))
  expect_equal(colSums(is.na(d)), counts)
  expect_equal(sum(!stats::complete.cases(d)), 55)
  expect_equal(colSums(d, na.rm = TRUE), c(
    TSRQ_T1 = 3218, TSRQ_T2 = 2655, WEMBS_T1 = 2891, WEMBS_T2 = 2507,
    SMUF_T1 = 522.15, SMUF_T2 = 518.633333333333, ISI_T1 = 528, ISI_T2 = 298,
    DASSS_T1 = 1748, DASSS_T2 = 1114, HES_T1 = 2595, HES_T2 = 2158,
    Age = 2432, BMI = 2753.38444034956), tolerance = 1e-12)
})

test_that("manuscript data can be fitted through the public staged workflow", {
  e <- new.env(parent = emptyenv())
  utils::data("wsmed_examples", package = "wsMed", envir = e)
  model <- wsmed_model(
    outcome = c(T1 = "DASSS_T1", T2 = "DASSS_T2"),
    mediators = list(motivation = c(T1 = "TSRQ_T1", T2 = "TSRQ_T2")))
  expect_error(wsmed_fit(model, e$wsmed_examples), "missing-data strategy")
  fit <- wsmed_fit(model, e$wsmed_examples, missing = "listwise")
  cols <- c("DASSS_T1", "DASSS_T2", "TSRQ_T1", "TSRQ_T2")
  expect_equal(stats::nobs(fit), sum(stats::complete.cases(e$wsmed_examples[cols])))
  expect_true(all(is.finite(stats::coef(fit))))
  expect_true(is.finite(wsmed_effects(fit)$table$estimate))
})
