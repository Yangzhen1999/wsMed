compatibility_fit <- function(mi = FALSE, moderated = TRUE) {
  data(example_data, package = "wsMed", envir = environment())
  model <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2")),
    moderator = if (moderated) list(variable = "D3", interactions = "A -> Y") else NULL)
  d <- example_data
  if (mi) d$D1[seq(3, 100, 10)] <- NA
  wsmed_fit(model, d, missing = if (mi) "mi" else "error", mi = list(m = 2, seed = 18))
}

test_that("saved moderated fits require explicit compatible algorithm identities", {
  f <- compatibility_fit()
  frozen <- serialize(f, NULL)
  expect_no_error(wsmed_effects(unserialize(frozen), scale = "marginal"))
  expect_equal(wsmed_reproducibility(f)$fitting_versions$algorithms, .wsmed_fit_algorithms())
  old <- f; old$provenance$algorithms <- NULL
  set.seed(24); rng <- .Random.seed
  local_mocked_bindings(.wsmed_mi_mc = function(...) stop("Must not sample"))
  expect_error(wsmed_infer(old, draws = 10, seed = 2), "Refit from the original data")
  expect_error(wsmed_effects(old, scale = "marginal"), "incompatible algorithm metadata")
  expect_error(wsmed_effects(old, scale = "raw"), "Refit")
  expect_equal(coef(old), coef(f))
  expect_output(print(old), "wsMed fit")
  expect_identical(.Random.seed, rng)
  expect_identical(serialize(f, NULL), frozen)
  future <- f; future$schema_version <- 999L
  expect_error(wsmed_infer(future), "Unsupported saved-object schema")
  future <- f; future$provenance$algorithms$product_moments <- "future"
  expect_error(wsmed_effects(future), "incompatible algorithm")
})

test_that("old MI draws can be replaced without repeating a compatible fit", {
  f <- compatibility_fit(mi = TRUE)
  i <- wsmed_infer(f, draws = 40, seed = 25)
  expect_no_error(wsmed_effects(i, scale = "marginal"))
  old <- i; old$provenance$algorithms <- NULL
  local_mocked_bindings(.wsmed_fit_core = function(...) stop("Must not refit"))
  expect_error(wsmed_effects(old, scale = "marginal"), "rerun wsmed_infer")
  expect_error(summary(old), "sampler metadata")
  renewed <- wsmed_infer(old$fit, draws = 40, seed = 25)
  expect_equal(renewed$draws, i$draws)
  expect_equal(coef(wsmed_effects(renewed)), coef(wsmed_effects(i)))
  expect_identical(renewed$fit, f)
  legacy <- .wsmed_assemble(f, list(mc = i), .05, TRUE)
  legacy$fit$provenance$algorithms <- NULL
  expect_error(standardize_moderation(legacy), "Refit")
  expect_output(print(legacy, detail = "full"), "STANDARDIZED")
  legacy$fit <- NULL; legacy$inference <- NULL
  expect_error(standardize_moderation(legacy), "predates algorithm metadata")
})

test_that("unaffected unversioned non-product fits remain usable", {
  f <- compatibility_fit(moderated = FALSE)
  old <- f; old$provenance$algorithms <- NULL
  expect_equal(coef(wsmed_effects(old)), coef(wsmed_effects(f)))
  expect_no_error(wsmed_infer(old, draws = 20, seed = 14))
})
