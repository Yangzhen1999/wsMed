reporting_fixture <- local({
  cache <- new.env(parent = emptyenv())
  function(kind = "plain", standardized = FALSE) {
    key <- paste(kind, standardized)
    if (exists(key, cache, inherits = FALSE)) return(cache[[key]])
    e <- new.env(); utils::data("example_data", package = "wsMed", envir = e)
    d <- e$example_data
    m <- wsmed_model(c(before = "D1", after = "D2"),
      list(A = c(before = "A1", after = "A2"), B = c(before = "B1", after = "B2")),
      moderator = if (kind == "plain") NULL else list(variable =
        if (kind == "categorical") "Group" else "D3", interactions = "A -> Y"))
    f <- wsmed_fit(m, d, standardized = standardized)
    cache[[key]] <- wsmed_infer(f, draws = 100, seed = 36, level = .9)
    cache[[key]]
  }
})

test_that("summary stores every core effect with exact joint inference and accessible tables", {
  for (kind in c("plain", "continuous", "categorical")) {
    i <- reporting_fixture(kind)
    s <- summary(i)
    expect_s3_class(s, "summary_wsmed")
    expect_setequal(unique(s$effects$effect), c("cp", "indirect_1", "indirect_2", "total_indirect", "total"))
    expect_equal(s$effects, as.data.frame(s))
    expect_equal(s$effects, s$table)
    expect_equal(s$coefficients, as.data.frame(wsmed_effects(i, type = "paths")))
    for (family in c("direct", "indirect", "total_indirect", "total")) {
      independent <- wsmed_effects(i, type = family)
      rows <- match(independent$table$term, s$table$term)
      expect_equal(unname(s$draws[, rows, drop = FALSE]), unname(independent$draws))
      expect_equal(s$effects$conf.low[rows], independent$table$conf.low)
      expect_equal(s$effects$conf.high[rows], independent$table$conf.high)
      expect_equal(s$effects$effect_type[rows], rep(family, length(rows)))
    }
    expect_equal(s$info$level, .9)
    expect_output(print(s), "Path coefficients")
    expect_output(print(s), "Std. Error")
    revised <- summary(s, level = .8)
    expect_equal(revised$effects, revised$table)
    expect_equal(revised$coefficients, as.data.frame(summary(s$coefficient_results, level = .8)))
    expect_equal(revised$info$level, .8)
    expect_equal(revised$effects$conf.low, unname(confint(s, level = .8)[, 1]))
    expect_equal(s$info$level, .9)
  }
})

test_that("analysis standardization is inherited and overrides never mutate or resample", {
  prepared <- lapply(c("plain", "continuous", "categorical"), function(kind) reporting_fixture(kind, TRUE))
  local_mocked_bindings(.wsmed_fit_core = function(...) stop("Unexpected fit"),
    .wsmed_infer_core = function(...) stop("Unexpected sampling"))
  for (i in prepared) {
    x <- .wsmed_assemble(i$fit, list(mc = i), .1, TRUE)
    frozen <- serialize(x, NULL)
    set.seed(324); rng <- .Random.seed
    s <- summary(x)
    expect_true(s$info$standardized)
    expect_equal(confint(x), confint(wsmed_effects(x, type = "parameters", standardized = FALSE)))
    expect_equal(confint(x, standardized = TRUE),
      confint(wsmed_effects(x, type = "parameters", standardized = TRUE)))
    expect_equal(s$draws, wsmed_effects(x, type = "all", scale = "marginal")$draws)
    expect_equal(wsmed_effects(x)$draws, wsmed_effects(x, standardized = TRUE)$draws)
    expect_equal(summary(x, standardized = FALSE)$draws,
      wsmed_effects(x, type = "all", scale = "raw")$draws)
    expect_identical(summary(i)$query$scale, "marginal")
    expect_identical(plot(x, view = "forest")$data$scale, rep("marginal", nrow(plot(x, view = "forest")$data)))
    expect_true(all(plot(x, view = "forest", standardized = FALSE)$data$scale == "raw"))
    expect_output(print(x), "Standardization:")
    expect_output(print(x, detail = "full"), "Path coefficients")
    expect_output(print(x, detail = "overview"), "standardized")
    expect_output(print(x, standardized = FALSE), "raw scale")
    expect_identical(serialize(x, NULL), frozen)
    expect_identical(.Random.seed, rng)
    expect_error(summary(x, standardized = FALSE, scale = "marginal"), "conflicting")
    expect_error(summary(x, standardized = NA), "standardized")
    expect_error(summary(x, levell = .9), "Unused argument")
    old <- x; old$standardized <- NULL; old$fit$standardized <- NULL
    expect_true(summary(old)$info$standardized)
  }
})

test_that("summary supports filtering, exported tables, contrasts, plots and legacy reports", {
  i <- reporting_fixture()
  x <- .wsmed_assemble(i$fit, list(mc = i), .1, FALSE)
  expect_false(summary(x)$info$standardized)
  s <- summary(x, type = "indirect", terms = "indirect_2")
  expect_identical(s$effects$term, "indirect_2")
  expect_equal(coef(s), coef(wsmed_effects(x, terms = "indirect_2")))
  expect_equal(vcov(s), vcov(wsmed_effects(x, terms = "indirect_2")))
  expect_s3_class(plot(summary(x)), "ggplot")
  difference <- wsmed_contrasts(summary(x), list(B_minus_A = c(indirect_2 = 1, indirect_1 = -1)))
  expect_equal(unname(difference$draws[, 1]),
    unname(i$draws[, "indirect_2"] - i$draws[, "indirect_1"]))
  expect_invisible(print(x))
  expect_output(print(x, detail = "legacy"), "VARIABLES")
  expect_error(print(x, detail = "legacy", standardized = TRUE), "saved tables")
  expect_error(summary(i$fit, levell = .9), "Unused argument")
  expect_error(wsmed_fit(i$fit$model, i$fit$raw_data, standardized = "yes"), "standardized")
})

test_that("multiple inference engines are labelled in reports and never silently mixed", {
  i <- reporting_fixture()
  expect_warning(boot <- wsmed_infer(i$fit, method = "bootstrap", draws = 30, seed = 81, level = .9),
    "Bootstrap p-values are not computed")
  x <- .wsmed_assemble(i$fit, list(mc = i, bootstrap = boot), .1, FALSE)
  expect_error(summary(x), "Choose method")
  expect_equal(summary(x, method = "bootstrap")$draws, wsmed_effects(boot, type = "all")$draws)
  out <- capture.output(print(x))
  expect_true(any(grepl("mc", out)))
  expect_true(any(grepl("bootstrap", out)))
})


test_that("conditional summaries preserve probes and issue a single support warning", {
  i <- reporting_fixture("continuous")
  outside <- max(i$fit$raw_data$D3) + .1
  count <- 0L
  s <- withCallingHandlers(summary(i, at = list(D3 = outside)),
    wsmed_extrapolation_warning = function(w) {
      count <<- count + 1L; invokeRestart("muffleWarning")
    })
  expect_equal(count, 1L)
  expect_true(all(s$effects$extrapolated))
  expect_equal(s$info$probes$at, as.character(outside))
  expect_equal(s$effects$at, rep(as.character(outside), nrow(s$effects)))
  cat <- summary(reporting_fixture("categorical"))
  expect_true(all(c("n.observed", "n.fitted.min", "n.fitted.max") %in% names(cat$effects)))
})
