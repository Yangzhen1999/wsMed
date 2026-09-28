phase2_data <- function(n = 350) {
  set.seed(918)
  w <- rnorm(n, 3, 2); a <- rnorm(n); b <- rnorm(n)
  d1 <- 2 + .8 * w + rnorm(n)
  d2 <- 1 + .4 * w + .3 * d1 + rnorm(n)
  y <- .5 + .6 * w + .5 * d1 + .7 * d2 + .2 * d1 * w + .3 * a + rnorm(n)
  data.frame(m11 = a-d1/2, m12 = a+d1/2, m21 = b-d2/2,
             m22 = b+d2/2, y1 = 0, y2 = y, W = w)
}

phase2_result <- function(type = "continuous", form = "P", method = "mc", missing = "DE", fixed = FALSE, data = NULL) {
  raw <- if (is.null(data)) phase2_data() else data
  if (form %in% c("CP", "PC")) {
    set.seed(92)
    d3 <- 1 + .4 * raw$W + rnorm(nrow(raw))
    a3 <- rnorm(nrow(raw))
    raw$m31 <- a3 - d3 / 2; raw$m32 <- a3 + d3 / 2
  }
  if (type == "categorical") raw$W <- cut(raw$W, c(-Inf, 2, 4, Inf), labels = c("A", "B", "C"))
  if (missing != "DE") {
    set.seed(84); raw$y1 <- rnorm(nrow(raw)); raw$y2 <- raw$y2 + raw$y1
    raw$m11[seq(1, 340, 25)] <- NA
  }
  args <- list(data = raw, M_C1 = c("m11", "m21"), M_C2 = c("m12", "m22"),
    Y_C1 = "y1", Y_C2 = "y2", W = "W", W_type = type,
    form = form, Na = missing, ci_method = method, R = 100,
    bootstrap = 100, standardized = TRUE, verbose = FALSE,
    fixed.x = fixed, mi_args = list(m = 3), MP = c("b1", "d1"))
  if (form == "UD") { args$paths <- c("M2 -> M1", "M1 -> Y"); args$MP <- c("b_2_1", "b1") }
  if (form %in% c("CP", "PC")) {
    args$M_C1 <- c(args$M_C1, "m31"); args$M_C2 <- c(args$M_C2, "m32")
  }
  if (method == "both") expect_warning(out <- do.call(wsMed, args), "Bootstrap p-values are not computed") else out <- do.call(wsMed, args)
  out
}

test_that("conditional point estimates and curves use endpoint scales at raw W", {
  for (form in c("P", "CN", "CP", "PC", "UD")) for (type in c("continuous", "categorical")) {
    out <- phase2_result(type, form)
    sy <- sqrt(lavaan::fitted(out$mc$fit)$cov["Ydiff", "Ydiff"])
    std <- out$moderation_std; raw <- out$moderation
    expect_equal(std$conditional_overall$Estimate, raw$conditional_overall$Estimate / sy, tolerance = 1e-7)
    if (type == "continuous") {
      expect_equal(std$beta_coef$Estimate, raw$beta_coef$Estimate / sy, tolerance = 1e-7)
      expect_equal(std$IE_contrasts$Estimate, raw$IE_contrasts$Estimate / sy, tolerance = 1e-7)
      expect_equal(std$theta_curve$Estimate, raw$theta_curve$Estimate / sy, tolerance = 1e-7)
      expect_equal(std$theta_curve$W_raw, raw$theta_curve$W_raw)
      tab <- out$mc$std_mc
      expect_equal(std$mod_coeff$Estimate, tab$Estimate[match(std$mod_coeff$Path, tab$Parameter)], tolerance = 1e-7)
      sdm <- sqrt(lavaan::fitted(out$mc$fit)$cov["M1diff", "M1diff"])
      expect_equal(subset(std$path_HML, Path == "b1")$Estimate,
                   subset(raw$path_HML, Path == "b1")$Estimate * sdm / sy, tolerance = 1e-7)
    } else {
      expect_equal(std$conditional_IE$Estimate, raw$conditional_IE$Estimate / sy, tolerance = 1e-7)
      expect_equal(std$IE_contrasts$Estimate, raw$IE_contrasts$Estimate / sy, tolerance = 1e-7)
      expect_equal(std$overall_contrasts$Estimate, raw$overall_contrasts$Estimate / sy, tolerance = 1e-7)
    }
    expect_identical(attr(std, "standardization")$interval, "percentile")
  }
})

test_that("MC conditional intervals use each joint draw's own SD and fixed raw W", {
  out <- phase2_result()
  fit <- out$mc$result$args$lav
  th <- out$mc$result$thetahatstar
  pt <- lavaan::parameterTable(fit)
  free <- match(seq_len(fit@Model@nx.free), pt$free)
  yi <- match("Ydiff", rownames(lavaan::fitted(fit)$cov))
  sy <- vapply(seq_len(nrow(th)), function(i) {
    model <- lavaan::lav_model_set_parameters(fit@Model, x = th[i, free])
    sqrt(lavaan::lav_model_implied(model)$cov[[1]][yi, yi])
  }, numeric(1))
  wc <- sd(out$data$W)
  expected <- (th[, "a1"] + th[, "aw1_W1"] * wc) *
              (th[, "b1"] + th[, "bw1_W1"] * wc) / sy
  meta <- attr(out$moderation_std, "standardization")
  valid <- setdiff(seq_len(nrow(th)), meta$diagnostics$invalid_indices)
  expected <- expected[valid]
  row <- subset(out$moderation_std$beta_coef, Path == "indirect_effect_1" & Level == "+1 SD")
  expect_equal(row$SE, sd(expected), tolerance = 1e-7)
  ci <- unlist(row[, grep("CI", names(row)), drop = FALSE], use.names = FALSE)
  expect_equal(ci, unname(quantile(expected, c(.025, .975))), tolerance = 1e-7)
})

test_that("MI and FIML standardization use their own point estimates and fixed.x", {
  for (na in c("MI", "FIML")) for (fixed in c(FALSE, TRUE)) {
    out <- phase2_result(missing = na, fixed = fixed)
    std <- out$moderation_std
    expect_identical(attr(std, "standardization")$fixed.x, fixed)
    # MI pools the marginal variance itself; FIML uses its fitted implied SD.
    fit <- out$mc$result$args$lav; pt <- lavaan::parameterTable(fit)
    point <- out$mc$result$thetahat$est
    model <- lavaan::lav_model_set_parameters(fit@Model, x = point[match(seq_len(fit@Model@nx.free), pt$free)])
    yi <- match("Ydiff", rownames(lavaan::fitted(fit)$cov))
    sy <- sqrt(lavaan::lav_model_implied(model)$cov[[1]][yi, yi])
    if (na == "MI") sy <- sqrt(mean(vapply(out$fit$backend, function(z)
      lavaan::fitted(z)$cov["Ydiff", "Ydiff"], numeric(1))))
    expect_equal(std$conditional_overall$Estimate, out$moderation$conditional_overall$Estimate / sy, tolerance = 1e-7)
  }
})

test_that("stored-draw API, both printing and standardized plotting work", {
  out <- phase2_result(form = "UD", method = "both")
  expect_equal(out$moderation_std$mc$conditional_overall$Estimate, out$moderation_std$boot$conditional_overall$Estimate)
  expect_equal(standardize_moderation(out), out$moderation_std)
  saved <- out; saved$moderation_std <- NULL
  expect_equal(standardize_moderation(saved), out$moderation_std)
  expect_output(print(out, detail = "full"), "STANDARDIZED CONDITIONAL EFFECTS")
  g <- plot_moderation_curve(out, "total_indirect", standardized = TRUE, engine = "boot")
  expect_s3_class(g, "ggplot")
  expect_equal(g$data$Estimate, subset(out$moderation_std$boot$theta_curve, Path == "total_indirect")$Estimate)
  expect_equal(g$labels$y, "Standardized effect")
  fit <- out$fit_u; th <- fit@external$sbt_boot_ustd
  yi <- match("Ydiff", rownames(lavaan::fitted(fit)$cov))
  sy <- vapply(seq_len(nrow(th)), function(i) {
    model <- lavaan::lav_model_set_parameters(fit@Model, x = th[i, ])
    sqrt(lavaan::lav_model_implied(model)$cov[[1]][yi, yi])
  }, numeric(1))
  expected <- (th[, "a1"] + th[, "a2"] * th[, "b_2_1"]) * th[, "b1"] / sy
  meta <- attr(out$moderation_std$boot, "standardization")
  expected <- expected[setdiff(seq_along(expected), meta$diagnostics$invalid_indices)]
  row <- subset(out$moderation_std$boot$conditional_overall, Effect == "total_indirect" & Level == "0 SD")
  expect_equal(row$SE, sd(expected), tolerance = 1e-7)
  expect_equal(unlist(row[, grep("CI", names(row)), drop = FALSE], use.names = FALSE),
               unname(quantile(expected, c(.025, .975))), tolerance = 1e-7)
  expect_error(standardize_moderation(list()), "wsMed")
  out$input_vars$W <- NULL
  expect_error(standardize_moderation(out), "moderator")
})

test_that("standardized conditional effects are invariant to measurement units", {
  original <- phase2_result()
  raw <- phase2_data()
  raw[c("m11", "m12")] <- raw[c("m11", "m12")] * 3
  raw[c("y1", "y2")] <- raw[c("y1", "y2")] * 7
  raw$W <- raw$W * 5
  rescaled <- phase2_result(data = raw)
  expect_equal(original$moderation_std$conditional_overall$Estimate,
               rescaled$moderation_std$conditional_overall$Estimate, tolerance = 2e-5)
  expect_equal(original$moderation_std$mod_coeff$Estimate,
               rescaled$moderation_std$mod_coeff$Estimate, tolerance = 2e-5)
})
