completed_fixture <- function() {
  data(example_data, package = "wsMed", envir = environment())
  d <- example_data[c("A1", "A2", "D1", "D2", "D3")]
  d$A1[c(5, 14, 29)] <- NA; d$D2[c(7, 21)] <- NA
  model <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2")),
    moderator = list(variable = "D3", interactions = "A -> Y"))
  expect_warning(internal <- wsmed_fit(model, d, missing = "mi", mi = list(m = 3, seed = 62)),
    class = "wsmed_mi_compatibility_warning")
  list(data = d, model = model, fit = internal,
    completed = mice::complete(internal$mi$prepared$mids, "all"))
}

test_that("external imputations reuse exactly the fitted pooling and MC engine", {
  a <- completed_fixture()
  local_mocked_bindings(PrepareMissingData = function(...) stop("Must not impute"))
  set.seed(65); before <- .Random.seed
  f <- wsmed_fit(a$model, a$data, missing = "mi", mi = list(completed = a$completed))
  expect_identical(.Random.seed, before)
  expect_equal(coef(f), coef(a$fit), tolerance = 1e-12)
  expect_equal(vcov(f), vcov(a$fit), tolerance = 1e-12)
  expect_equal(f$mi$pooled$marginal, a$fit$mi$pooled$marginal)
  expect_equal(f$reference, a$fit$reference)
  i <- wsmed_infer(f, draws = 200, seed = 66)
  internal <- wsmed_infer(a$fit, draws = 200, seed = 66)
  expect_equal(i$draws, internal$draws)
  expect_equal(coef(wsmed_effects(i, scale = "marginal")),
    coef(wsmed_effects(internal, scale = "marginal")))
  mids <- wsmed_fit(a$model, a$data, missing = "mi",
    mi = list(completed = a$fit$mi$prepared$mids))
  expect_equal(coef(mids), coef(f))
  report <- wsmed_reproducibility(f)
  expect_identical(report$analysis$imputation, list(engine = "external", m = 3L))
  expect_null(report$analysis$imputation$completed)
  expect_output(print(f), "External imputations")
  expect_output(print(a$fit), "Default MI uses main effects only")
  legacy <- wsMed(a$data, "A1", "A2", "D1", "D2", W = "D3",
    MP = c("a1", "b1", "cp"), Na = "MI", R = 200,
    mi_args = list(completed = a$completed, seed = 66), standardized = TRUE)
  expect_equal(coef(legacy$fit), coef(f))
  expect_equal(legacy$inference$mc$draws, i$draws)
  expect_equal(legacy$fit$mi$controls, list(engine = "external", m = 3L))
})

test_that("completed data validation protects observed records and controls", {
  a <- completed_fixture(); fit <- function(x, ...) wsmed_fit(a$model, a$data,
    missing = "mi", mi = c(list(completed = x), list(...)))
  expect_error(fit(a$completed[1]), "at least two")
  expect_error(fit(a$completed, m = 4), "number of supplied")
  expect_error(fit(a$completed, seed = 1), "omit them")
  expect_error(fit(a$completed, method = "norm"), "omit them")
  expect_error(wsmed_fit(a$model, a$data, mi = list(completed = a$completed)), "require missing")
  x <- a$completed; x[[1]]$A1[1] <- x[[1]]$A1[1] + .01
  expect_error(fit(x), "changes observed values")
  x <- a$completed; x[[1]] <- x[[1]][rev(seq_len(nrow(x[[1]]))), ]
  expect_error(fit(x), "participant rows")
  x <- a$completed; x[[1]]$A1[5] <- NA
  expect_error(fit(x), "missing/non-finite")
  x[[1]]$A1[5] <- Inf
  expect_error(fit(x), "missing/non-finite")
  x <- a$completed; x[[1]]$A1 <- as.character(x[[1]]$A1)
  expect_error(fit(x), "numeric analysis columns")
  x <- a$completed; x[[1]]$D1 <- NULL
  expect_error(fit(x), "analysis columns")
  d <- a$data; d$D3 <- factor(ifelse(d$D3 > median(d$D3), "high", "low"))
  x <- lapply(a$completed, function(z) { z$D3 <- d$D3; z })
  expect_length(.wsmed_completed(x, d, names(d)), 3)
  x[[2]]$D3 <- relevel(x[[2]]$D3, "low")
  expect_error(.wsmed_completed(x, d, names(d)), "factor levels")
  d$D3 <- as.character(d$D3)
  x <- lapply(a$completed, function(z) { z$D3 <- d$D3; z })
  expect_true(is.factor(.wsmed_completed(x, d, names(d))[[1]]$D3))
  x[[2]]$D3[1] <- "unexpected"
  expect_error(.wsmed_completed(x, d, names(d)), "missing/non-finite")
})
