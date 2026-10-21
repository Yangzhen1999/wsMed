presentation_fixture <- local({
  cache <- new.env(parent = emptyenv())
  function(kind = "continuous", missing = "error") {
    key <- paste(kind, missing)
    if (exists(key, cache, inherits = FALSE)) return(cache[[key]])
    e <- new.env(); utils::data("example_data", package = "wsMed", envir = e)
    d <- as.data.frame(e$example_data)
    d$Group <- factor(d$Group, levels = c("low", "high", "med"))
    if (missing != "error") d$A2[c(2, 7, 35)] <- NA_real_
    m <- wsmed_model(c(before = "D1", after = "D2"),
      list(A = c(before = "A1", after = "A2"), B = c(before = "B1", after = "B2")),
      moderator = if (kind == "plain") NULL else list(
        variable = if (kind == "continuous") "D3" else "Group", interactions = "A -> Y"))
    run_fit <- function() wsmed_fit(m, d, missing = missing, mi = list(m = 3, seed = 51))
    if (missing == "mi" && kind != "plain") expect_warning(f <- run_fit(),
      class = "wsmed_mi_compatibility_warning") else f <- run_fit()
    cache[[key]] <- wsmed_infer(f, draws = 100, seed = 19, level = .90)
    cache[[key]]
  }
})

test_that("continuous defaults select a declared grid of fitted raw values", {
  i <- presentation_fixture()
  p <- plot(i, n = 13, title = "Requested title", x_label = "Moderator", y_label = "Effect size", ncol = 1)
  raw <- i$fit$data$D3[i$fit$diagnostics$case_indices[[1]]]
  expected_grid <- seq(min(raw), max(raw), length.out = 13)
  r <- wsmed_effects(i, at = list(D3 = expected_grid))
  expect_equal(unique(as.numeric(p$data$at)), expected_grid)
  expect_equal(p$data$estimate, r$table$estimate)
  expect_equal(p$data$conf.low, r$table$conf.low)
  expect_equal(p$data$conf.high, r$table$conf.high)
  expect_equal(attr(p, "wsmed_plot")$grid_range, range(raw))
  expect_identical(attr(p, "wsmed_plot")$view, "curve")
  expect_identical(p$labels$title, "Requested title")
  expect_identical(p$labels$x, "Moderator")
  expect_identical(p$labels$y, "Effect size")
  expect_match(p$labels$subtitle, "90% pointwise percentile")
  expect_match(p$labels$caption, "raw D3 units")
  expect_no_warning(ggplot2::ggplot_build(p))
  forest <- plot(i, view = "forest")
  expect_length(unique(forest$data$at), 1L)
  expect_equal(forest$data$estimate, wsmed_effects(i)$table$estimate)
})

test_that("automatic grids use fitted cases and the first MI reference", {
  for (na in c("listwise", "fiml", "mi")) {
    i <- presentation_fixture(missing = na)
    p <- plot(i, n = 7)
    raw <- i$fit$data$D3[i$fit$diagnostics$case_indices[[1]]]
    expect_equal(attr(p, "wsmed_plot")$grid_range, range(raw, na.rm = TRUE))
    r <- wsmed_effects(i, at = list(D3 = unique(as.numeric(p$data$at))))
    expect_equal(p$data$estimate, r$table$estimate)
    expect_equal(p$data$conf.low, r$table$conf.low)
    expect_no_warning(ggplot2::ggplot_build(p))
    if (na == "mi") expect_match(p$labels$caption, "first imputation")
  }
})

test_that("explicit probes, effect order and categorical order are preserved", {
  i <- presentation_fixture("categorical")
  p <- plot(i, at = list(Group = c("med", "low", "high")),
    terms = c("indirect_2", "indirect_1"), labels = c(indirect_2 = "Through B"), ncol = 1)
  expect_identical(levels(p$data$.level_label), c("med", "low", "high"))
  expect_identical(levels(p$data$.effect_label), c("Through B", "A"))
  expect_identical(attr(p, "wsmed_plot")$view, "conditional")
  built <- ggplot2::ggplot_build(p)
  expect_equal(built$layout$panel_scales_x[[1]]$get_labels(), c("med", "low", "high"))
  r <- wsmed_effects(i, at = list(Group = c("med", "low", "high")), terms = c("indirect_2", "indirect_1"))
  expect_equal(p$data$estimate, r$table$estimate)
  expect_equal(p$data$conf.high, r$table$conf.high)
  forest <- plot(r, view = "forest", title = "Results title")
  expect_equal(levels(forest$data$.row_label), rev(unique(as.character(forest$data$.row_label))))
  expect_identical(forest$labels$title, "Results title")
  selected <- plot(r, terms = "indirect_1")
  expect_true(all(selected$data$effect == "indirect_1"))
  probes <- c(.7, .1, .4)
  p <- plot(presentation_fixture(), at = list(D3 = probes), view = "conditional")
  expect_identical(levels(p$data$.level_label), as.character(probes))
})

test_that("rendered geometry uses the exact effect estimates and confidence limits", {
  for (scale in c("raw", "marginal")) {
    i <- presentation_fixture()
    r <- wsmed_effects(i, at = list(D3 = c(.1, .4, .8)), scale = scale, level = .80)
    p <- plot(r, view = "forest")
    expect_equal(p$data$estimate, r$table$estimate)
    expect_equal(p$data$conf.low, r$table$conf.low)
    built <- ggplot2::ggplot_build(p)
    expect_equal(built$data[[2]]$x, r$table$conf.low)
    expect_equal(built$data[[2]]$xend, r$table$conf.high)
    expect_equal(built$data[[3]]$x, r$table$estimate)
    curve <- ggplot2::ggplot_build(plot(r, view = "curve"))
    expect_equal(sort(curve$data[[2]]$ymin), sort(r$table$conf.low))
    expect_equal(sort(curve$data[[2]]$ymax), sort(r$table$conf.high))
    expect_match(p$labels$subtitle, "80%")
    expect_identical(attr(p, "wsmed_plot")$scale, scale)
    revised <- plot(r, level = .90)
    ci <- confint(r, level = .90)
    expect_equal(revised$data$conf.low, unname(ci[, 1]))
    expect_equal(revised$data$conf.high, unname(ci[, 2]))
  }
})

test_that("contrasts display joint-draw differences and explicit direction", {
  i <- presentation_fixture("categorical")
  r <- wsmed_effects(i, at = list(Group = c("high", "low")), terms = "indirect_1")
  contrast <- wsmed_contrasts(r, list(high_minus_low = setNames(c(1, -1), r$table$term)))
  p <- plot(contrast, title = "High minus low")
  delta <- r$draws[, 1] - r$draws[, 2]
  expect_equal(p$data$estimate, unname(coef(r)[1] - coef(r)[2]))
  expect_equal(p$data$conf.low, unname(quantile(delta, .05)))
  expect_equal(p$data$conf.high, unname(quantile(delta, .95)))
  expect_match(as.character(p$data$.row_label), "high_minus_low")
  expect_match(p$labels$caption, "matched joint draws")
  expect_error(plot(contrast, view = "curve"), "continuous moderator")
})

test_that("plotting and summaries neither refit nor sample nor mutate results", {
  i <- presentation_fixture()
  frozen <- serialize(i, NULL)
  set.seed(938); rng <- .Random.seed
  local_mocked_bindings(.wsmed_fit_core = function(...) stop("Unexpected fit"),
    .wsmed_infer_core = function(...) stop("Unexpected sampling"))
  p <- plot(i, n = 7, scale = "marginal")
  ggplot2::ggplot_build(p)
  r <- summary(i, at = list(D3 = c(.2, .5)))
  before <- serialize(r, NULL)
  expect_output(print(r), "Std. Error")
  expect_output(print(r), "90% percentile")
  expect_output(print(r), "SE from effect draws")
  expect_identical(serialize(r, NULL), before)
  expect_identical(serialize(i, NULL), frozen)
  expect_identical(.Random.seed, rng)
  expect_identical(as.data.frame(r), r$table)
})

test_that("fit-only plots and summaries do not imply confidence intervals", {
  f <- presentation_fixture()$fit
  p <- plot(f, n = 5)
  expect_true(all(is.na(p$data$conf.low)))
  expect_null(attr(p, "wsmed_plot")$level)
  expect_match(p$labels$subtitle, "no confidence intervals")
  expect_false(any(vapply(p$layers, function(l) inherits(l$geom, "GeomRibbon"), logical(1))))
  r <- wsmed_effects(f)
  expect_output(print(r), "Point estimates only")
  expect_false(any(grepl("CI lower|Std. Error", capture.output(print(r)))))
  expect_output(print(summary(f)), "fitted parameter covariance")
  expect_output(print(summary(presentation_fixture(missing = "mi")$fit)), "Rubin-pooled")
})

test_that("invalid plot arguments are rejected instead of silently ignored", {
  i <- presentation_fixture(); r <- wsmed_effects(i)
  expect_error(plot(i, titlle = "typo"), "Unused argument.*titlle")
  expect_error(plot(r, titlle = "typo"), "Unused argument.*titlle")
  expect_error(plot(i, base_size = 0), "base_size")
  expect_error(plot(i, ncol = 0), "ncol")
  expect_error(plot(i, n = 1), "n must")
  expect_error(plot(i, title = NA_character_), "Titles")
  expect_error(plot(i, view = "conditional"), "Supply at")
  expect_error(plot(r, view = "curve"), "at least two")
  expect_error(plot(r, at = list(D3 = 1)), "Unused argument")
  expect_error(plot(r, terms = NA_character_), "terms")
  expect_error(plot(r, labels = c(indirect_1 = "Same", indirect_2 = "Same")), "distinguish")
  expect_error(plot(presentation_fixture("categorical"), view = "curve"), "continuous moderator")
  two <- wsmed_effects(i, at = list(D3 = c(.2, .5)))
  selected <- c("indirect_1@1", "indirect_2@2")
  single <- plot(two, terms = selected)
  expect_identical(attr(single, "wsmed_plot")$view, "forest")
  expect_no_warning(ggplot2::ggplot_build(single))
  expect_error(plot(two, terms = selected, view = "curve"), "two probes per effect")
})

test_that("standardized invalid draws are disclosed in plots and summaries", {
  i <- presentation_fixture("plain")
  i$draws[5, "Ydiff~~Ydiff"] <- -1000
  expect_warning(r <- wsmed_effects(i, scale = "marginal"), "invalid|1 of")
  p <- plot(r)
  expect_equal(attr(p, "wsmed_plot")$draw_ids, r$draw_ids)
  expect_false(5L %in% attr(p, "wsmed_plot")$draw_ids)
  expect_match(p$labels$caption, "invalid draws excluded jointly")
  expect_output(print(r), "invalid draws excluded jointly")
})

test_that("legacy bootstrap limits and new percentile plots remain distinguished", {
  skip_on_cran()
  mc <- presentation_fixture("plain")
  boot <- suppressWarnings(wsmed_infer(mc$fit, method = "bootstrap", draws = 40,
                                       seed = 41, interval = "bc", level = .90))
  x <- .wsmed_assemble(mc$fit, list(mc = mc, bootstrap = boot), .10, FALSE)
  expect_error(plot(x), "Choose method")
  p <- plot(x, method = "bootstrap", title = "Bootstrap")
  r <- wsmed_effects(boot)
  expect_equal(p$data$estimate, r$table$estimate)
  expect_equal(p$data$conf.low, unname(apply(r$draws, 2, quantile, .05)))
  expect_match(p$labels$subtitle, "percentile.*Bootstrap")
  old <- plot_effects(x, paths = "indirect_1", engine = "boot")
  idx <- match("indirect_1", x$param_boot$lhs)
  expect_equal(old$data$CI.LL, x$param_boot$boot.ci.lower[idx])
  expect_equal(old$data$estimate, old$data$Estimate)
  expect_match(old$labels$subtitle, "bias-corrected intervals")
  saved_old <- x; saved_old$fit <- saved_old$inference <- NULL
  expect_no_warning(ggplot2::ggplot_build(plot_effects(saved_old, engine = "boot")))
  expect_no_warning(ggplot2::ggplot_build(p))
  standardized <- plot(boot, scale = "marginal", terms = "indirect_1")
  lav <- boot$fit$backend[[1]]
  y_index <- match("Ydiff", lavaan::lavNames(lav, "ov"))
  sy <- vapply(seq_len(nrow(boot$draws)), function(j) {
    model <- lavaan::lav_model_set_parameters(lav@Model,
      x = boot$draws[j, names(coef(boot))])
    sqrt(lavaan::lav_model_implied(model)$cov[[1]][y_index, y_index])
  }, numeric(1))
  independent <- boot$draws[, "indirect_1"] / sy
  expect_equal(standardized$data$conf.low, unname(quantile(independent, .05)), tolerance = 1e-8)
  expect_equal(standardized$data$conf.high, unname(quantile(independent, .95)), tolerance = 1e-8)
})
