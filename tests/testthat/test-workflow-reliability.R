reliability_fixture <- local({
  cache <- new.env(parent = emptyenv())
  function(kind = "continuous", missing = "error") {
    key <- paste(kind, missing)
    if (exists(key, cache, inherits = FALSE)) return(cache[[key]])
    e <- new.env(); utils::data("example_data", package = "wsMed", envir = e)
    d <- as.data.frame(e$example_data)
    if (missing == "mi") { d$A2[c(2, 7)] <- NA; d$D3[c(4, 8, 9)] <- NA }
    m <- wsmed_model(c(before = "D1", after = "D2"),
      list(A = c(before = "A1", after = "A2")), moderator = if (kind == "plain") NULL else
        list(variable = if (kind == "categorical") "Group" else "D3", interactions = "A -> Y"))
    f <- wsmed_fit(m, d, missing = missing, mi = list(m = 3, seed = 92))
    cache[[key]] <- wsmed_infer(f, draws = 100, seed = 48, level = .90)
    cache[[key]]
  }
})

test_that("all interval entry points retain the selected level by default", {
  i <- reliability_fixture()
  x <- .wsmed_assemble(i$fit, list(mc = i), .10, FALSE)
  for (object in list(i, x)) {
    r <- summary(object, type = "parameters")
    expect_equal(confint(object), confint(r))
    expect_equal(confint(object, parm = 1), confint(r, parm = 1))
    expect_equal(confint(object, level = .80), confint(r, level = .80))
    expect_equal(unname(confint(object)[, 1]),
      unname(apply(i$draws[, names(coef(i)), drop = FALSE], 2, quantile, .05)))
    e <- summary(object)
    p <- plot(object, at = list(D3 = i$fit$reference$by_dataset[[1]]$moderator$center))
    expect_equal(p$data$conf.low, unname(confint(e)[, 1]))
    expect_equal(summary(e, level = NULL), e)
    expect_equal(confint(e, level = NULL), confint(e))
    expect_identical(e$query$level, .90)
  }
  expect_error(summary(i$fit, levell = .9), "Unused argument")
  expect_error(summary(summary(i), levell = .9), "Unused argument")
  expect_error(confint(summary(i), levell = .9), "Unused argument")
})

test_that("fit diagnostics distinguish dataset status and raw category counts", {
  i <- reliability_fixture(missing = "mi"); f <- i$fit
  d <- wsmed_inspect(f, "diagnostics")
  expect_identical(d$by_dataset$dataset, 1:3)
  expect_equal(d$by_dataset$n.used, rep(nrow(f$raw_data), 3))
  expect_true(all(d$by_dataset$converged & d$by_dataset$admissible))
  expect_true(all(d$by_dataset$covariance.finite))
  expect_equal(d$by_dataset$covariance.min.eigenvalue[1],
    min(eigen(lavaan::vcov(f$backend[[1]]), symmetric = TRUE, only.values = TRUE)$values))
  cfit <- reliability_fixture("categorical")$fit
  counts <- wsmed_inspect(cfit, "diagnostics")$category_counts
  expect_equal(counts$n, as.integer(table(cfit$raw_data$Group)))
  expect_output(print(f), "Post-fit admissibility: 3 of 3")
  expect_output(print(summary(f)), "first-imputation reporting reference")
  bad <- f; bad$diagnostics$admissible[2] <- FALSE
  expect_error(wsmed_infer(bad, draws = 5), "admissible fits; review dataset.*2")
  bad <- f; bad$diagnostics$converged[2] <- FALSE
  expect_error(wsmed_infer(bad, draws = 5), "converged fits")
  expect_equal(wsmed_inspect(i, "provenance"), i$provenance)
})

test_that("invalid paired data and sparse categories have useful diagnostics", {
  f <- reliability_fixture("plain")$fit; d <- f$raw_data
  d$A2 <- d$A1
  expect_error(wsmed_fit(f$model, d), "Dataset 1.*no usable variation.*M1diff")
  d <- f$raw_data; d$A2[-1] <- NA
  expect_error(wsmed_fit(f$model, d, missing = "listwise"), "fewer than two cases")
  d <- f$raw_data; d$D1 <- 0
  expect_s3_class(wsmed_fit(f$model, d), "wsmed_fit")
  m <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2"), B = c(before = "B1", after = "B2")))
  d <- f$raw_data; d$B1 <- d$A1; d$B2 <- d$A2
  expect_error(suppressWarnings(wsmed_fit(m, d)), "Dataset 1")
  m <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2")), moderator = list(variable = "Group"))
  d <- f$raw_data; d$Group <- factor(c(rep("rare", 3), rep("common", nrow(d)-3)))
  sparse <- wsmed_fit(m, d)
  expect_output(print(sparse), "Small fitted category counts")
  expect_equal(subset(sparse$diagnostics$category_counts, level == "rare")$n, 3L)
})

test_that("reference recoding preserves raw effects and each standardizer matches its model", {
  f <- reliability_fixture("categorical")$fit
  d <- f$raw_data; d$Group <- stats::relevel(d$Group, "low")
  recoded <- wsmed_fit(f$model, d)
  groups <- c("high", "low", "med")
  original <- wsmed_effects(f, at = list(Group = groups))
  revised <- wsmed_effects(recoded, at = list(Group = groups))
  expect_equal(coef(original), coef(revised), tolerance = 1e-6)
  # Product-term SEMs need not imply the same marginal covariance after recoding.
  # Check the declared definition independently, without assuming invariance.
  for (fit in list(f, recoded)) {
    raw <- wsmed_effects(fit, at = list(Group = groups))
    std <- wsmed_effects(fit, at = list(Group = groups), scale = "marginal")
    sy <- sqrt(lavaan::fitted(fit$backend[[1]])$cov["Ydiff", "Ydiff"])
    expect_equal(coef(std), coef(raw)/sy, tolerance = 1e-6)
    expect_equal(std$query$interpretation$marginal_outcome_sd, sy)
  }
  r <- wsmed_effects(recoded, at = list(Group = c("high", "low")))
  contrast <- wsmed_contrasts(r, list(difference = setNames(c(1, -1), names(coef(r)))))
  expect_output(print(contrast), "reference category = low")
  expect_output(print(contrast), "\\+1 \\* A \\[Group = high\\] -1 \\* A \\[Group = low\\]")
})

test_that("unit changes preserve new workflow standardized effects at corresponding probes", {
  f <- reliability_fixture()$fit; d <- f$raw_data
  d[c("A1", "A2")] <- d[c("A1", "A2")] * 3
  d[c("D1", "D2")] <- d[c("D1", "D2")] * 7
  d$D3 <- 4 * d$D3 + 100
  transformed <- wsmed_fit(f$model, d)
  probes <- c(.2, .5)
  raw <- wsmed_effects(f, at = list(D3 = probes))
  rescaled <- wsmed_effects(transformed, at = list(D3 = 4*probes+100))
  expect_equal(coef(rescaled), 7*coef(raw), tolerance = 1e-6)
  std <- wsmed_effects(f, at = list(D3 = probes), scale = "marginal")
  std2 <- wsmed_effects(transformed, at = list(D3 = 4*probes+100), scale = "marginal")
  expect_equal(coef(std2), coef(std), tolerance = 1e-6)
  expect_output(print(std), "SD\\(D2 - D1\\)")
  expect_output(print(std), "Moderator: D3 in raw units")
})

test_that("analysis manifests round-trip without recomputation or participant data", {
  i <- reliability_fixture(missing = "mi")
  r <- wsmed_effects(i, at = list(D3 = c(.2, .6)))
  contrast <- wsmed_contrasts(r, list(high_minus_low = setNames(c(-1, 1), names(coef(r)))))
  frozen <- serialize(i, NULL); set.seed(317); rng <- .Random.seed
  local_mocked_bindings(.wsmed_fit_core = function(...) stop("Unexpected fit"),
    .wsmed_infer_core = function(...) stop("Unexpected inference"))
  report <- wsmed_reproducibility(i)
  expect_equal(report$analysis$imputation$seed, 92)
  expect_equal(report$inference$mc$controls$seed, 48)
  expect_identical(report$inference$mc$effect_interval, "percentile")
  expect_equal(report$fitting_versions, i$fit$provenance)
  expect_equal(wsmed_reproducibility(contrast)$query$contrasts, contrast$query$contrasts)
  field_names <- function(x) if (is.list(x)) c(names(x), unlist(lapply(unclass(x), field_names))) else character()
  expect_false(any(c("raw_data", "backend", "case_indices", "call") %in% field_names(report)))
  expect_false("raw_data" %in% names(report))
  expect_null(report$inference$mc$draws)
  file <- tempfile(fileext = ".rds"); on.exit(unlink(file), add = TRUE)
  expect_invisible(wsmed_reproducibility(i, file))
  expect_equal(readRDS(file), report)
  expect_error(wsmed_reproducibility(i, file), "already exists")
  expect_error(wsmed_reproducibility(i, tempfile()), "new .rds")
  expect_error(wsmed_reproducibility(1), "workflow object")
  expect_equal(wsmed_reproducibility(i$fit$model)$model$conditions, c("before", "after"))
  expect_identical(serialize(i, NULL), frozen)
  expect_identical(.Random.seed, rng)
})

test_that("rug marks are observed fitted-case moderator values", {
  for (missing in c("error", "mi")) {
    i <- reliability_fixture(missing = missing)
    p <- plot(i, n = 7, rug = TRUE)
    marks <- p$layers[[length(p$layers)]]$data$.probe
    raw <- i$fit$raw_data$D3[i$fit$diagnostics$case_indices[[1]]]
    expect_equal(marks, raw[is.finite(raw)])
    expect_equal(attr(p, "wsmed_plot")$rug_n, sum(is.finite(raw)))
    expect_match(p$labels$caption, "imputed values excluded")
    expect_no_warning(ggplot2::ggplot_build(p))
  }
  expect_error(plot(reliability_fixture(), view = "forest", rug = TRUE), "continuous curve")
  expect_error(plot(reliability_fixture(), rug = NA), "rug must")
})

test_that("bootstrap diagnostics and manifests retain the distinct interval conventions", {
  skip_on_cran()
  mc <- reliability_fixture("plain")
  boot <- suppressWarnings(wsmed_infer(mc$fit, method = "bootstrap", draws = 30,
    seed = 37, interval = "bc", level = .80))
  x <- .wsmed_assemble(mc$fit, list(mc = mc, bootstrap = boot), .10, FALSE)
  expect_error(confint(x), "Choose method")
  expect_equal(confint(x, method = "bootstrap"), confint(boot))
  expect_equal(confint(x, method = "mc"), confint(mc))
  expect_match(colnames(confint(boot))[1], "10")
  report <- wsmed_reproducibility(x)
  expect_identical(names(report$inference), c("mc", "bootstrap"))
  expect_identical(report$inference$bootstrap$controls$interval, "bc")
  expect_identical(report$inference$bootstrap$effect_interval, "percentile")
  expect_output(print(boot), "80% effect intervals: percentile")
  expect_output(print(summary(boot)), "excluded before effect extraction")
  bad <- boot; bad$draws[3, "Ydiff~~Ydiff"] <- -1000
  expect_warning(r <- wsmed_effects(bad, scale = "marginal"), "invalid")
  expect_output(print(r), "Reasons:")
  expect_equal(r$query$inference_diagnostics$requested, 30L)
  expect_equal(r$diagnostics$invalid, 1L)
})
