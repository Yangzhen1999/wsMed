support_fixture <- function(categorical = FALSE) {
  data(example_data, package = "wsMed", envir = environment())
  d <- example_data
  m <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2")),
    moderator = list(variable = if (categorical) "Group" else "D3", interactions = "A -> Y"))
  list(data = d, model = m)
}

test_that("MI compatibility warning is emitted once per fit and stored", {
  a <- support_fixture(); a$data$A1[c(5, 14)] <- NA
  caught <- character()
  f <- withCallingHandlers(wsmed_fit(a$model, a$data, missing = "mi", mi = list(m = 2, seed = 62)),
    wsmed_mi_compatibility_warning = function(w) {
      caught <<- c(caught, conditionMessage(w)); invokeRestart("muffleWarning")
    })
  expect_length(caught, 1)
  expect_true(caught %in% f$diagnostics$warnings)
  expect_true(caught %in% wsmed_reproducibility(f)$fit_diagnostics$warnings)
  completed <- mice::complete(f$mi$prepared$mids, "all")
  expect_no_warning(external <- wsmed_fit(a$model, a$data, missing = "mi", mi = list(completed = completed)))
  expect_equal(coef(external), coef(f))
  expect_warning(x <- wsMed(a$data, "A1", "A2", "D1", "D2", W = "D3",
    MP = c("a1", "b1", "cp"), Na = "MI", R = 100,
    mi_args = list(m = 2, seed = 62)), class = "wsmed_mi_compatibility_warning")
  expect_equal(coef(x), coef(f))
  plain <- a$model; plain$input_vars$MP <- c("a1", "cp")
  expect_no_warning(wsmed_fit(plain, a$data, missing = "mi", mi = list(m = 2, seed = 62)))
})

test_that("binary type decisions remain explicit and interfaces agree for factors", {
  a <- support_fixture(); a$data$D3 <- rep(0:1, length.out = nrow(a$data))
  expect_message(f <- wsmed_fit(a$model, a$data), "continuous in wsmed_fit")
  expect_identical(f$model$input_vars$W_type, "continuous")
  expect_length(f$diagnostics$input_notes, 1)
  expect_message(auto <- wsMed(a$data, "A1", "A2", "D1", "D2", W = "D3",
    MP = c("a1", "b1", "cp"), R = 100, seed = 62), "automatically treats.*categorical")
  expect_identical(auto$fit$model$input_vars$W_type, "categorical")
  a$data$D3 <- factor(a$data$D3, levels = c(0, 1))
  expect_message(factor_fit <- wsmed_fit(a$model, a$data), NA)
  explicit <- wsMed(a$data, "A1", "A2", "D1", "D2", W = "D3", W_type = "categorical",
    MP = c("a1", "b1", "cp"), R = 100, seed = 62)
  staged <- wsmed_infer(factor_fit, draws = 100, seed = 62)
  expect_equal(coef(explicit), coef(staged))
  expect_equal(coef(auto), coef(explicit))
  expect_equal(auto$moderation$conditional_IE, explicit$moderation$conditional_IE)
  first <- as.data.frame(wsmed_effects(explicit)); second <- as.data.frame(wsmed_effects(staged))
  # The staged interface retains the user-defined mediator label A (legacy: M1).
  columns <- setdiff(names(first), c("label", "path"))
  expect_equal(first[columns], second[columns])
})

test_that("extrapolation uses observed used rows and survives extraction and plotting", {
  a <- support_fixture()
  # Still outside support, without introducing an unrelated ill-scaled fit.
  outside <- max(a$data$D3) + 1
  a$data$D3[1] <- outside; a$data$A1[1] <- NA
  f <- wsmed_fit(a$model, a$data, missing = "listwise")
  limits <- range(a$data$D3[-1])
  probes <- c(limits[1], mean(limits), limits[2], outside)
  expect_warning(r <- wsmed_effects(f, at = list(D3 = probes)), class = "wsmed_extrapolation_warning")
  expect_identical(r$table$extrapolated, c(FALSE, FALSE, FALSE, TRUE))
  expect_equal(r$query$support$observed_range, limits)
  set.seed(902); before <- .Random.seed
  expect_no_warning(p <- plot(r))
  expect_identical(.Random.seed, before)
  expect_match(p$labels$caption, "Extrapolation")
  expect_equal(p$data$extrapolated, r$table$extrapolated)
  expect_equal(attr(p, "wsmed_plot")$support, r$query$support)
  expect_no_warning(wsmed_effects(f, at = list(D3 = limits)))
  expect_no_warning(wsmed_effects(f, type = "parameters"))
  expect_output(print(r), "Extrapolation")
  expect_warning(plot(f, at = list(D3 = probes)), class = "wsmed_extrapolation_warning")
  contrasts <- wsmed_contrasts(r, list(inside = setNames(c(-1, 1), r$table$term[1:2]),
    outside = setNames(c(-1, 1), r$table$term[c(1, 4)])))
  expect_identical(contrasts$table$extrapolated, c(FALSE, TRUE))
  expect_false(grepl("extrapolated", plot(contrasts, terms = "inside")$labels$caption))
  expect_match(plot(contrasts, terms = "outside")$labels$caption, "extrapolated conditional")
})

test_that("categorical support retains per-imputation counts and observed counts", {
  a <- support_fixture(TRUE); a$data$Group[1:3] <- NA
  completed <- lapply(c("low", "high"), function(group) {
    d <- a$data; d$Group[1:3] <- group; d
  })
  f <- wsmed_fit(a$model, a$data, missing = "mi", mi = list(completed = completed))
  r <- wsmed_effects(f, at = list(Group = c("low", "high")))
  counts <- vapply(completed, function(d) as.integer(table(d$Group)[c("low", "high")]), integer(2))
  expect_equal(r$table$n.fitted.min, apply(counts, 1, min))
  expect_equal(r$table$n.fitted.max, apply(counts, 1, max))
  expect_equal(r$table$n.observed, as.integer(table(a$data$Group)[c("low", "high")]))
  p <- plot(r)
  expect_match(p$labels$caption, "range across completed datasets")
  expect_true(all(is.na(r$table$extrapolated)))
  # Imputed numeric extremes do not extend observed support.
  b <- support_fixture(); b$data$D3[1] <- NA
  complete <- lapply(c(2, 3), function(value) { d <- b$data; d$D3[1] <- value; d })
  g <- wsmed_fit(b$model, b$data, missing = "mi", mi = list(completed = complete))
  expect_warning(z <- wsmed_effects(g, at = list(D3 = max(b$data$D3, na.rm = TRUE) + 1)),
    class = "wsmed_extrapolation_warning")
  expect_equal(z$query$support$observed_n, nrow(b$data) - 1L)
})
