product_data <- function(n = 360L, categorical = TRUE) {
  set.seed(514)
  g <- factor(rep(c("high", "low", "med"), length.out = n))
  w <- if (categorical) c(-.6, .8, .2)[as.integer(g)] else rnorm(n)
  a <- matrix(rnorm(n * 3), ncol = 3)
  m1 <- .2 + .3 * w + rnorm(n)
  m2 <- -.1 + .2 * w + (.4 + .15 * w) * m1 + .2 * a[, 1] + rnorm(n)
  m3 <- .1 + .1 * w + .3 * m2 + .1 * a[, 2] + rnorm(n)
  y <- .3 + .2 * w + (.4 + .2 * w) * m1 + (.2 - .1 * w) * m2 +
    .3 * m3 + .2 * a[, 1] + rnorm(n)
  data.frame(y1 = rnorm(n), y2 = 0, m11 = a[, 1] - m1/2,
    m12 = a[, 1] + m1/2, m21 = a[, 2] - m2/2, m22 = a[, 2] + m2/2,
    m31 = a[, 3] - m3/2, m32 = a[, 3] + m3/2,
    W = if (categorical) g else w, C = rnorm(n)) |>
    transform(y2 = y1 + y)
}

product_model <- function(structure = "parallel", one = FALSE) {
  mediators <- list(A = c(before = "m11", after = "m12"),
    B = c(before = "m21", after = "m22"), C = c(before = "m31", after = "m32"))
  edges <- switch(structure, parallel = c("A -> Y", "B -> Y"),
    serial = c("A -> B", "B -> Y"), serial_parallel = c("A -> B", "B -> Y"),
    parallel_serial = c("B -> A", "A -> Y"), custom = c("C -> B", "B -> Y"))
  if (one) { mediators <- mediators[1]; edges <- "A -> Y" }
  wsmed_model(c(before = "y1", after = "y2"), mediators, structure = structure,
    paths = if (structure == "custom") c("C -> B", "B -> Y", "A -> Y") else NULL,
    covariates = list(between = "C"),
    moderator = list(variable = "W", interactions = edges))
}

product_effects <- function(fit, scale = "marginal") {
  wsmed_effects(fit, type = "total_indirect", at = list(W = c("high", "low", "med")),
    scale = scale)$table$estimate
}

test_that("all graph generators preserve conditional effects under reference changes", {
  d <- product_data()
  for (structure in c("parallel", "serial", "serial_parallel", "parallel_serial", "custom")) {
    model <- product_model(structure)
    f <- wsmed_fit(model, d)
    for (ref in c("low", "med")) {
      recoded <- d; recoded$W <- relevel(d$W, ref)
      g <- wsmed_fit(model, recoded)
      expect_equal(product_effects(g), product_effects(f), tolerance = 2e-5,
        info = paste(structure, ref))
      expect_equal(product_effects(g, "raw"), product_effects(f, "raw"), tolerance = 2e-5)
      expect_equal(lavaan::fitted(g$backend[[1]])$cov["Ydiff", "Ydiff"],
        lavaan::fitted(f$backend[[1]])$cov["Ydiff", "Ydiff"], tolerance = 2e-5)
      expect_equal(unname(lavaan::fitMeasures(g$backend[[1]], c("chisq", "df"))),
        unname(lavaan::fitMeasures(f$backend[[1]], c("chisq", "df"))), tolerance = 2e-5)
    }
  }
})

test_that("product moments include upstream errors and preserve exogenous fixing", {
  d <- product_data()
  model <- product_model("custom")
  for (fixed in c(FALSE, TRUE)) {
    f <- wsmed_fit(model, d, fixed.x = fixed)
    lav <- f$backend[[1]]; pt <- lavaan::parameterTable(lav)
    covs <- subset(pt, op == "~~")
    has_cov <- function(a, b) any(covs$lhs == a & covs$rhs == b |
                                  covs$lhs == b & covs$rhs == a)
    expect_true(has_cov("M3diff", "int_M2diff_W1"))
    expect_true(has_cov("M2diff", "int_M2diff_W1"))
    expect_false(has_cov("M1diff", "int_M2diff_W1"))
    expect_false(has_cov("M2diff", "int_M3diff_W1"))
    expect_false(any(grepl("^int_", lavaan::lavNames(lav, "ov.x"))))
    xmoments <- subset(pt, op %in% c("~~", "~1") & lhs == "W1" & rhs %in% c("", "W1", "W2"))
    expect_equal(xmoments$free == 0L, rep(fixed, nrow(xmoments)))
    expect_true(all(subset(pt, op == "~~" & grepl("^int_", lhs) & lhs == rhs)$free > 0))
    re <- d; re$W <- relevel(d$W, "low")
    expect_equal(product_effects(wsmed_fit(model, re, fixed.x = fixed)),
      product_effects(f), tolerance = 2e-5)
  }
})

test_that("single mediator agrees with independent regressions and covariance formulation", {
  data(example_data)
  model <- wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2")),
    moderator = list(variable = "Group", interactions = "A -> Y"))
  f <- wsmed_fit(model, example_data); d <- f$data
  base <- paste(
    "Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + bw1_W1*int_M1diff_W1 + bw1_W2*int_M1diff_W2 + cpw_W1*W1 + cpw_W2*W2",
    "M1diff ~ a1*1 + aw1_W1*W1 + aw1_W2*W2", sep = "\n")
  x <- c("M1avg", "W1", "W2", "int_M1diff_W1", "int_M1diff_W2")
  covs <- vapply(seq_along(x), function(i)
    paste(x[i], "~~", paste(x[i:length(x)], collapse = " + ")), character(1))
  reference <- lavaan::sem(paste(c(base, covs,
    "M1diff ~~ int_M1diff_W1 + int_M1diff_W2"), collapse = "\n"), d, fixed.x = FALSE)
  actual <- lavaan::fitted(f$backend[[1]])$cov
  expect_equal(actual, lavaan::fitted(reference)$cov[colnames(actual), colnames(actual)],
    tolerance = 2e-6)
  reg_m <- lm(M1diff ~ W1 + W2, d)
  reg_y <- lm(Ydiff ~ M1diff + M1avg + int_M1diff_W1 + int_M1diff_W2 + W1 + W2, d)
  expect_equal(unname(f$coefficients[c("a1", "aw1_W1", "aw1_W2")]),
    unname(coef(reg_m)), tolerance = 2e-6)
  expect_equal(unname(f$coefficients[c("cp", "b1", "d1", "bw1_W1", "bw1_W2", "cpw_W1", "cpw_W2")]),
    unname(coef(reg_y)), tolerance = 2e-6)
})

test_that("models without endogenous products retain their original syntax", {
  syntax <- "M1diff ~ a1*1 + W1\nYdiff ~ cp*1 + b1*M1diff + M1avg + W1 + int_M1avg_W1"
  expect_identical(.wsmed_product_covariances(syntax), syntax)
  syntax <- "M1diff ~ a1*1\nYdiff ~ cp*1 + b1*M1diff + M1avg"
  expect_identical(.wsmed_product_covariances(syntax), syntax)
})

test_that("FIML and listwise fits retain reference invariance with missing paired scores", {
  d <- product_data(); d$m11[seq(2, nrow(d), 11)] <- NA
  d$y2[seq(5, nrow(d), 17)] <- NA
  for (missing in c("fiml", "listwise")) for (fixed in c(FALSE, TRUE)) {
    f <- wsmed_fit(product_model("serial"), d, missing = missing, fixed.x = fixed)
    re <- d; re$W <- relevel(d$W, "low")
    g <- wsmed_fit(f$model, re, missing = missing, fixed.x = fixed)
    expect_equal(product_effects(g), product_effects(f), tolerance = 2e-5)
    expect_equal(product_effects(g, "raw"), product_effects(f, "raw"), tolerance = 2e-5)
  }
})

test_that("MC and bootstrap propagate the repaired covariance into every standardizer", {
  skip_on_cran()
  f <- wsmed_fit(product_model(one = TRUE), product_data())
  for (method in c("mc", "bootstrap")) {
    if (method == "bootstrap") {
      expect_warning(i <- wsmed_infer(f, method = method, draws = 60, seed = 171),
        "Bootstrap p-values are not computed")
    } else i <- wsmed_infer(f, method = method, draws = 60, seed = 171)
    raw <- wsmed_effects(i, at = list(W = "low"))
    std <- wsmed_effects(i, at = list(W = "low"), scale = "marginal")
    lav <- f$backend[[1]]; pt <- lavaan::parameterTable(lav)
    theta <- .wsmed_full_draws(i)
    free <- match(seq_len(lav@Model@nx.free), pt$free)
    index <- match("Ydiff", colnames(lavaan::fitted(lav)$cov))
    sy <- vapply(seq_len(nrow(theta)), function(j) {
      mod <- lavaan::lav_model_set_parameters(lav@Model, x = theta[j, free])
      sqrt(lavaan::lav_model_implied(mod)$cov[[1]][index, index])
    }, numeric(1))
    keep <- match(std$draw_ids, raw$draw_ids)
    expect_equal(unname(std$draws[, 1]), unname(raw$draws[keep, 1] / sy[keep]), tolerance = 1e-7)
    expect_equal(std$table$std.error, sd(std$draws[, 1]))
    expect_equal(unname(as.numeric(confint(std))),
      unname(quantile(std$draws[, 1], c(.025, .975))))
    expect_gt(sd(theta[, "M1diff~~int_M1diff_W1"]), 0)
    expect_gt(sd(sy), 0)
  }
})

test_that("formatted syntax keeps auxiliary equations separate from mediation paths", {
  f <- wsmed_fit(product_model("serial"), product_data())
  output <- capture.output(printGM(f))
  expect_true(any(grepl("Auxiliary Product Moment Equations", output)))
  expect_true(any(grepl("Variances and Residual Covariances", output)))
  lines <- strsplit(f$sem_model, "\n", fixed = TRUE)[[1]]
  for (line in lines) expect_equal(sum(trimws(output) == line), 1L)
})

test_that("MI pools new product parameters and retains reference coding for paired imputations", {
  d <- product_data(); d$m11[seq(2, nrow(d), 13)] <- NA
  expect_warning(f <- wsmed_fit(product_model(one = TRUE), d, missing = "mi", mi = list(m = 3, seed = 11)),
    class = "wsmed_mi_compatibility_warning")
  nuisance <- "M1diff~~int_M1diff_W1"
  expect_true(nuisance %in% names(f$coefficients))
  expect_equal(unname(f$coefficients[nuisance]),
    mean(vapply(f$backend, function(z) lavaan::coef(z)[nuisance], numeric(1))))
  expect_true(all(is.finite(f$covariance)))
  # Reuse exactly the same imputations: a new stochastic imputation is not a
  # reference-coding equivalence check, even if it uses the same RNG seed.
  paired <- lapply(seq_along(f$backend), function(j) {
    completed <- mice::complete(f$mi$prepared$mids, j)
    completed$W <- relevel(completed$W, "low")
    wsmed_fit(f$model, completed)
  })
  for (j in seq_along(paired)) {
    original <- wsmed_fit(f$model, mice::complete(f$mi$prepared$mids, j))
    expect_equal(product_effects(paired[[j]]), product_effects(original), tolerance = 2e-5)
  }
  g <- paired[[1]]
  pooled <- .wsmed_pool_fits(lapply(paired, function(z) z$backend[[1]]))
  g$coefficients <- pooled$est; g$covariance <- pooled$total
  g$point <- .wsmed_point(g$backend[[1]], pooled$est)
  g$mi$pooled <- pooled
  g$backend[[1]]@external$wsmed_mi_marginal <- list(point = pooled$marginal$point)
  expect_equal(product_effects(g), product_effects(f), tolerance = 2e-5)
  i <- wsmed_infer(f, draws = 80, seed = 128)
  std <- wsmed_effects(i, at = list(W = "low"), scale = "marginal")
  expect_true(all(is.finite(std$table$std.error)))
  expect_equal(std$table$estimate, product_effects(f)[2], tolerance = 1e-7)
  expect_gt(sd(i$draws[, nuisance]), 0)
})

test_that("serial MI pools marginal variances before standardization and samples their joint covariance", {
  d <- product_data(n = 300)
  d$m11[seq(2, nrow(d), 5)] <- NA; d$m21[seq(4, nrow(d), 6)] <- NA
  expect_warning(f <- wsmed_fit(product_model("parallel_serial"), d, missing = "mi", mi = list(m = 4, seed = 18)),
    class = "wsmed_mi_compatibility_warning")
  moments <- f$mi$pooled$marginal
  expected <- mean(vapply(f$backend, function(z) lavaan::fitted(z)$cov["Ydiff", "Ydiff"], numeric(1)))
  expect_equal(moments$point[["Ydiff"]], expected, tolerance = 1e-12)
  expect_equal(product_effects(f), product_effects(f, "raw") / sqrt(expected), tolerance = 1e-7)
  paired <- lapply(seq_along(f$backend), function(j) {
    d <- mice::complete(f$mi$prepared$mids, j); d$W <- relevel(d$W, "low")
    wsmed_fit(f$model, d)
  })
  g <- paired[[1]]; pooled <- .wsmed_pool_fits(lapply(paired, function(x) x$backend[[1]]))
  g$coefficients <- pooled$est; g$point <- .wsmed_point(g$backend[[1]], pooled$est)
  g$mi$pooled <- pooled; g$backend[[1]]@external$wsmed_mi_marginal <- list(point = pooled$marginal$point)
  expect_equal(product_effects(g), product_effects(f), tolerance = 2e-5)
  expect_equal(pooled$marginal$point[["Ydiff"]], expected, tolerance = 2e-6)
  # Check joint MC generation directly, without thousands of effect transforms.
  set.seed(912)
  theta <- ThetaHatStarWrapper(R = 12000, location = f$coefficients,
    scale = f$covariance)$thetahatstar
  draws <- .wsmed_draw_marginal(moments, f$coefficients, f$covariance, theta)$draws
  j <- match("Ydiff~~Ydiff", names(f$coefficients)); k <- match("Ydiff", names(moments$point))
  expected_correlation <- moments$cross[k, j] /
    sqrt(moments$total[k, k] * f$covariance[j, j])
  expect_equal(unname(cor(draws[, k], theta[, j])), unname(expected_correlation), tolerance = .035)
  expect_equal(unname(var(draws[, k])/moments$total[k, k]), 1, tolerance = .06)
  i <- wsmed_infer(f, draws = 70, seed = 2)
  raw <- wsmed_effects(i, type = "total_indirect", at = list(W = "low"))
  std <- wsmed_effects(i, type = "total_indirect", at = list(W = "low"), scale = "marginal")
  sd_draws <- sqrt(i$backend$mc$args$lav@external$wsmed_mi_marginal$draws[, "Ydiff"])
  keep <- match(std$draw_ids, raw$draw_ids)
  expect_equal(std$draws[, 1], raw$draws[keep, 1]/sd_draws[keep], tolerance = 1e-7)
})

test_that("MI variance innovations are stable across equivalent eigenvector bases", {
  # An arbitrarily small off-diagonal perturbation rotates the eigenvectors
  # of an identity covariance by 45 degrees. The symmetric root stays close.
  moments <- list(point = c(A = 2, B = 3), cross = matrix(0, 2, 2), total = diag(2))
  perturbed <- moments
  perturbed$total[1, 2] <- perturbed$total[2, 1] <- 1e-12
  theta <- matrix(0, 400, 2)
  set.seed(123)
  a <- .wsmed_draw_marginal(moments, c(0, 0), diag(2), theta)$draws
  set.seed(123)
  b <- .wsmed_draw_marginal(perturbed, c(0, 0), diag(2), theta)$draws
  expect_equal(a, b, tolerance = 1e-9)
  set.seed(123)
  expected <- sweep(matrix(rnorm(800), 400, 2), 2, moments$point, `+`)
  expect_equal(unname(a), unname(expected), tolerance = 1e-12)
  # A singular conditional covariance is valid; it must preserve the exact
  # linear relation rather than add independent noise in its nullspace.
  moments$total[,] <- 1
  set.seed(123)
  singular <- .wsmed_draw_marginal(moments, c(0, 0), diag(2), theta)$draws
  expect_equal(singular[, 1] - 2, singular[, 2] - 3, tolerance = 1e-12)
})

test_that("paired participant bootstrap refits are reference invariant", {
  skip_on_cran()
  d <- product_data(); f <- wsmed_fit(product_model(one = TRUE), d)
  re <- d; re$W <- relevel(d$W, "med")
  g <- wsmed_fit(f$model, re)
  results <- lapply(list(f, g), function(x) {
    expect_warning(i <- withCallingHandlers(
      wsmed_infer(x, method = "bootstrap", draws = 60, seed = 291,
        interval = "perc", level = .80),
      warning = function(w) {
        # A numerical refit can fail on one platform/reference coding. Its
        # warning and original replicate ID remain in inference diagnostics.
        if (grepl("bootstrap runs failed or did not converge", conditionMessage(w), fixed = TRUE))
          invokeRestart("muffleWarning")
      }),
      "Bootstrap p-values are not computed")
    expect_equal(sort(c(i$draw_ids, i$diagnostics$invalid_draw_ids)), seq_len(60))
    if (i$diagnostics$invalid > 0L)
      expect_true(any(grepl("bootstrap runs failed or did not converge",
        i$diagnostics$warnings, fixed = TRUE)))
    out <- wsmed_effects(i, at = list(W = c("high", "low", "med")), scale = "marginal")
    expect_equal(unname(confint(out)),
      unname(t(apply(out$draws, 2, quantile, probs = c(.1, .9)))))
    out
  })
  # Compare the same participant resamples, never two differently filtered
  # sequences (e.g., 59 versus 60 successful refits). Keep the numerical
  # tolerance unchanged and fail if more than two paired refits are lost.
  common <- intersect(results[[1]]$draw_ids, results[[2]]$draw_ids)
  expect_gte(length(common), 58L)
  paired <- lapply(results, function(x) {
    x$draws <- x$draws[match(common, x$draw_ids), , drop = FALSE]
    x$draw_ids <- common
    x
  })
  expect_equal(paired[[1]]$draws, paired[[2]]$draws, tolerance = 2e-5)
  expect_equal(confint(paired[[1]]), confint(paired[[2]]), tolerance = 2e-5)
})
