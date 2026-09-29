phase1_data <- function(n = 450) {
  set.seed(918)
  w <- rnorm(n, 3, 2)
  a <- rnorm(n); b <- rnorm(n)
  d1 <- 2 + .8 * w + rnorm(n)
  d2 <- 1 + .4 * w + .3 * d1 + rnorm(n)
  y <- .5 + .6 * w + .5 * d1 + .7 * d2 + .2 * d1 * w + .3 * a + rnorm(n)
  data.frame(m11 = a-d1/2, m12 = a+d1/2, m21 = b-d2/2,
             m22 = b+d2/2, y1 = 0, y2 = y, W = w)
}
phase1_prep <- function(raw, type = "continuous") {
  PrepareData(raw, M_C1 = c("m11", "m21"), M_C2 = c("m12", "m22"),
              Y_C1 = "y1", Y_C2 = "y2", W = "W", W_type = type, keep_W_raw = TRUE)
}
phase1_fit <- function(type = "continuous", form = "P", fixed = FALSE) {
  raw <- phase1_data()
  if (type == "categorical") raw$W <- cut(raw$W, c(-Inf, 2, 4, Inf), labels = c("A", "B", "C"))
  prep <- phase1_prep(raw, type)
  gen <- get(paste0("GenerateModel", form), asNamespace("wsMed"))
  model <- gen(prep, MP = c("b1", "d1", "b_1_2", "d_1_2", "b_2_1", "d_2_1"))
  fit <- lavaan::sem(model, prep, fixed.x = fixed)
  fit@external$wsmed_roles <- wsMed:::.wsmed_roles(prep)
  list(fit = fit, prep = prep, model = model)
}

test_that("standardized tables equal fitting data on component scales in every form", {
  for (form in c("P", "CN", "CP", "PC")) for (type in c("continuous", "categorical")) {
    obj <- phase1_fit(type, form)
    fit <- obj$fit
    pt <- lavaan::parameterTable(fit)
    sdv <- sqrt(diag(lavaan::fitted(fit)$cov))
    roles <- fit@external$wsmed_roles
    sdv[intersect(roles$dummy, names(sdv))] <- 1
    for (nm in intersect(names(roles$products), names(sdv)))
      sdv[nm] <- prod(sdv[roles$products[[nm]]])
    scaled <- obj$prep
    for (nm in names(sdv)) scaled[[nm]] <- scaled[[nm]] / sdv[nm]
    refit <- lavaan::sem(obj$model, scaled, fixed.x = FALSE)
    actual <- wsMed:::StdLav2(lavaan::coef(fit), fit)
    expect_equal(unname(actual), lavaan::parameterTable(refit)$est, tolerance = 2e-5,
                 info = paste(form, type))
    ie <- pt$op == ":=" & grepl("^indirect|^total_", pt$lhs)
    expect_equal(unname(actual[ie]), pt$est[ie] / sdv[["Ydiff"]], tolerance = 1e-7)
    expect_equal(unname(actual[pt$label == "a1"]),
                 pt$est[pt$label == "a1"] / sdv[["M1diff"]], tolerance = 1e-7)
  }
})

test_that("residual covariance is not converted to residual correlation", {
  s <- matrix(c(.25, .1, .1, .36), 2, dimnames = list(c("u", "v"), c("u", "v")))
  ram <- list(A = s * 0, S = s, M = matrix(0, 1, 2, dimnames = list(NULL, c("u", "v"))))
  lav <- list(theta = s, psi = NULL, lambda = NULL, beta = NULL, alpha = NULL)
  expect_equal(wsMed:::RAM2Lav2(ram, lav, TRUE)$theta[1, 2], .1)
})

phase1_draws <- function() {
  point <- c(a1=2, b1=.5, aw1_W1=.4, bw1_W1=.2, a2=3, b2=.7, cp=1, cpw_W1=.6)
  draws <- matrix(rep(point, each = 40), 40, dimnames = list(NULL, names(point)))
  # Correlated nonlinear draws deliberately have a different product mean.
  draws[, "a1"] <- draws[, "a1"] + rep(c(-.5, .5), 20)
  draws[, "b1"] <- draws[, "b1"] + rep(c(-.1, .1), 20)
  list(point = point, draws = draws)
}

test_that("continuous totals use all paths, exact probes, and plug-in points", {
  z <- phase1_draws()
  dat <- data.frame(W = c(1, 2, 3, 4, 5), W1 = -2:2)
  run <- function(n) wsMed:::analyze_mm_continuous(z$draws, dat, MP = "b1",
                  W_values = c(2, 3, 4), n_curve = n, point_estimates = z$point)
  a <- run(9); b <- run(120)
  expect_equal(a$conditional_overall, b$conditional_overall)
  ti <- subset(a$conditional_overall, Effect == "total_indirect")
  expect_equal(ti$Estimate, c(1.6*.3+2.1, 3.1, 2.4*.7+2.1))
  mid <- subset(a$beta_coef, Path == "indirect_effect_1" & Level == "W=3")
  expect_equal(mid$Estimate, 1)
  expect_equal(mid$SE, sd(z$draws[, "a1"] * z$draws[, "b1"]), tolerance = 1e-7)
  cp <- subset(a$path_HML, Path == "cp")
  expect_equal(cp$Estimate, c(.4, 1, 1.6))
  diff <- subset(a$IE_contrasts, Path == "indirect_effect_1" & Contrast == "W=4 - W=2")
  expect_equal(diff$Estimate, 1.2)
  cp_diff <- subset(a$path_contrasts, Path == "cp" & Contrast == "W=4 - W=2")
  expect_equal(cp_diff$Estimate, 1.2)
  onlycp <- wsMed:::analyze_mm_continuous(z$draws, dat, MP = "cp", point_estimates = z$point)
  expect_equal(nrow(onlycp$conditional_overall), 6L)
  dat$W[1] <- NA
  expect_no_error(wsMed:::analyze_mm_continuous(z$draws, dat, MP = "b1", point_estimates = z$point))
})

test_that("categorical main effects are used regardless of MP and CI level propagates", {
  z <- phase1_draws()
  dat <- data.frame(G = c("A", "B"), W1 = c(0, 1))
  attr(dat, "W_info") <- list(raw = "G")
  out <- wsMed:::analyze_mm_categorical(z$draws, dat, MP = "b1", ci_level = .9, point_estimates = z$point)
  expect_equal(subset(out$conditional_overall, Effect == "total_indirect")$Estimate, c(3.1, 3.78))
  expect_equal(subset(out$conditional_overall, Effect == "total_effect")$Estimate, c(4.1, 5.38))
  expect_equal(out$IE_contrasts$Estimate[1], .68)
  expect_true(any(grepl("5.0%CI.Lo", names(out$conditional_IE), fixed = TRUE)))
})

test_that("MC and bootstrap share their point transform and use only valid joint draws", {
  obj <- phase1_fit()
  fit <- obj$fit
  mc <- semmcci::MC(fit, R = 60, seed = 271, alpha = .05)
  std <- wsMed:::MCStd2(mc, .05)
  free <- lavaan::parameterTable(fit)$free > 0
  fit@external$sbt_boot_ustd <- mc$thetahatstar[, free, drop = FALSE]
  boot <- wsMed:::.wsmed_std_boot(fit, .05, "perc")
  expect_equal(boot$est.std, std$Estimate)
  expect_equal(boot$boot.se, std$SE)
  expect_equal(boot$boot.ci.lower, std[["2.5%"]])
  expect_equal(boot$boot.ci.upper, std[["97.5%"]])
  mc$thetahatstar[1, ] <- NA_real_
  expect_warning(bad <- wsMed:::MCStd2(mc, .05), "1 of 60")
  expect_equal(unique(bad$R), 59L)
  expect_equal(attr(bad, "standardization_diagnostics")$invalid_indices, 1L)
})

test_that("MI pools primitive parameters then recomputes nonlinear point estimates", {
  a <- phase1_fit()
  d1 <- a$prep; d2 <- d1
  d2$M1diff <- d2$M1diff + 2
  d2$Ydiff <- d2$Ydiff + d2$M1diff
  for (nm in grep("^int_", names(d2), value = TRUE)) {
    pieces <- strsplit(sub("^int_", "", nm), "_")[[1]]
    d2[[nm]] <- d2[[pieces[1]]] * d2[[pieces[2]]]
  }
  for (fixed in c(FALSE, TRUE)) {
    out <- MCMI2(a$model, list(d1, d2), R = 40, seed = 129, fixed.x = fixed)
    expect_identical(lavaan::lavInspect(out$args$lav, "options")$fixed.x, fixed)
    pt <- out$thetahat$est
    expect_equal(unname(pt["indirect_1"]), unname(pt["a1"] * pt["b1"]))
    ref <- lapply(list(d1, d2), function(d) lavaan::coef(lavaan::sem(a$model, d, fixed.x = fixed)))
    expect_equal(unname(pt["a1"]), mean(vapply(ref, function(x) x[["a1"]], numeric(1))))
  }
})

test_that("public both mode prints raw conditional tables and standardized tables", {
  expect_warning(out <- wsMed(phase1_data(180), M_C1 = c("m11", "m21"), M_C2 = c("m12", "m22"),
               Y_C1 = "y1", Y_C2 = "y2", W = "W", W_type = "continuous",
               MP = "b1", form = "P", Na = "DE", ci_method = "both", R = 40,
               bootstrap = 100, standardized = TRUE, verbose = FALSE), "Bootstrap p-values are not computed")
  expect_false(is.null(out$mc$std_mc))
  expect_false(is.null(out$mc$std_boot))
  expect_equal(out$mc$std_mc$Estimate, out$mc$std_boot$est.std)
  expect_output(print(out, detail = "full"), "UNSTANDARDIZED CONDITIONAL EFFECTS")
})

test_that("changing measurement units preserves standardized estimates", {
  raw <- phase1_data()
  for (type in c("continuous", "categorical")) {
    d <- raw
    if (type == "categorical") d$W <- ifelse(d$W > 3, "B", "A")
    fit_one <- function(d) {
      prep <- phase1_prep(d, type)
      fit <- lavaan::sem(GenerateModelP(prep, MP = c("b1", "d1")), prep, fixed.x = TRUE)
      fit@external$wsmed_roles <- wsMed:::.wsmed_roles(prep)
      wsMed:::StdLav2(lavaan::coef(fit), fit)
    }
    original <- fit_one(d)
    d[c("m11", "m12")] <- d[c("m11", "m12")] * 3
    d[c("y1", "y2")] <- d[c("y1", "y2")] * 7
    if (type == "continuous") d$W <- d$W * 5
    scaled <- withCallingHandlers(fit_one(d), warning = function(w) {
      # Deliberate unit inflation can trigger lavaan's descriptive scale warning.
      if (grepl("factor 1000", conditionMessage(w), fixed = TRUE))
        invokeRestart("muffleWarning")
    })
    expect_equal(scaled, original, tolerance = 2e-5)
  }
})

test_that("inadmissible covariance draws are rejected even with positive variances", {
  s <- matrix(c(1, 2, 2, 1), 2, dimnames = list(c("u", "v"), c("u", "v")))
  ram <- list(A = s * 0, S = s, F = diag(2), M = matrix(0, 1, 2))
  expect_error(wsMed:::StdRAM2(ram), "covariance matrix")
})

test_that("unmoderated and FIML models retain intercept and endpoint scales", {
  raw <- phase1_data()
  raw$m11[seq(1, 400, 20)] <- NA
  out <- wsMed(raw, M_C1 = c("m11", "m21"), M_C2 = c("m12", "m22"),
               Y_C1 = "y1", Y_C2 = "y2", form = "P", Na = "FIML", ci_method = "mc",
               R = 80, standardized = TRUE, verbose = FALSE)
  fit <- out$mc$fit
  pt <- lavaan::parameterTable(fit)
  sy <- sqrt(lavaan::fitted(fit)$cov["Ydiff", "Ydiff"])
  take <- pt$label %in% c("cp", "indirect_1", "indirect_2", "total_indirect", "total_effect")
  expect_equal(out$mc$std_mc$Estimate[take], pt$est[take] / sy, tolerance = 1e-7)
  expect_output(print(out, detail = "full"), "UNSTANDARDIZED CONDITIONAL EFFECTS")
})

test_that("public moderated MI forwards fixed.x to pooled fitting", {
  raw <- phase1_data(250)
  set.seed(82)
  raw$y1 <- rnorm(nrow(raw))
  raw$y2 <- raw$y2 + raw$y1
  raw$m11[seq(1, 240, 20)] <- NA
  for (fixed in c(FALSE, TRUE)) {
    expect_warning(out <- wsMed(raw, M_C1 = c("m11", "m21"), M_C2 = c("m12", "m22"),
                 Y_C1 = "y1", Y_C2 = "y2", W = "W", W_type = "continuous", MP = "b1",
                 form = "P", Na = "MI", ci_method = "mc", fixed.x = fixed,
                 mi_args = list(m = 3), R = 80, standardized = TRUE, verbose = FALSE),
      class = "wsmed_mi_compatibility_warning")
    expect_identical(lavaan::lavInspect(out$mc$result$args$lav, "options")$fixed.x, fixed)
    expect_false(is.null(out$mc$std_mc))
    p <- out$mc$result$thetahat$est
    mid <- subset(out$moderation$conditional_overall, Effect == "total_indirect" & Level == "0 SD")
    expect_equal(mid$Estimate, unname(p["a1"]*p["b1"] + p["a2"]*p["b2"]), tolerance = 1e-7)
  }
})

test_that("UD sparse and reverse-order paths use the same standardization rules", {
  for (type in c("continuous", "categorical")) for (reverse in c(FALSE, TRUE)) {
    raw <- phase1_data()
    if (type == "categorical") raw$W <- cut(raw$W, c(-Inf, 2, 4, Inf), labels = c("A", "B", "C"))
    prep <- phase1_prep(raw, type)
    from <- if (reverse) "2" else "1"
    to <- if (reverse) "1" else "2"
    edge <- paste0("b_", from, "_", to)
    terminal <- paste0("b", to)
    paths <- c(paste0("M", from, " -> M", to), paste0("M", to, " -> Y"))
    model <- GenerateModelCustom(prep, paths, MP = c(edge, terminal))
    fit <- lavaan::sem(model, prep, fixed.x = FALSE)
    fit@external$wsmed_roles <- wsMed:::.wsmed_roles(prep)
    pt <- lavaan::parameterTable(fit)
    scales <- sqrt(diag(lavaan::fitted(fit)$cov))
    roles <- fit@external$wsmed_roles
    scales[intersect(roles$dummy, names(scales))] <- 1
    for (nm in intersect(names(roles$products), names(scales)))
      scales[nm] <- prod(scales[roles$products[[nm]]])
    scaled <- prep
    for (nm in names(scales)) scaled[[nm]] <- scaled[[nm]] / scales[nm]
    refit <- lavaan::sem(model, scaled, fixed.x = FALSE)
    actual <- wsMed:::StdLav2(lavaan::coef(fit), fit)
    expect_equal(unname(actual), lavaan::parameterTable(refit)$est, tolerance = 2e-5)
    ie <- pt$op == ":="
    expect_equal(unname(actual[ie]), pt$est[ie] / scales[["Ydiff"]], tolerance = 1e-7)
    # Labels change discovery, never the fitted design or number of parameters.
    unlabeled <- gsub("(aw[0-9]+|cpw)_W[0-9]+\\*", "", model)
    ref_raw <- lavaan::sem(unlabeled, prep, fixed.x = FALSE)
    expect_equal(unname(lavaan::coef(fit)), unname(lavaan::coef(ref_raw)), tolerance = 1e-7)
    expect_true(all(c("aw1_W1", "aw2_W1", "cpw_W1") %in% pt$label))

    p <- wsMed:::ThetaHatWrapper(fit)$est
    draws <- matrix(rep(p, each = 20), 20, dimnames = list(NULL, names(p)))
    suffix <- if (type == "continuous") "W1" else "W2"
    coef_at <- function(base, value) {
      mod <- if (base == "cp") paste0("cpw_", suffix) else
        paste0(sub("^([ab])", "\\1w", base), "_", suffix)
      p[[base]] + if (mod %in% names(p)) p[[mod]] * value else 0
    }
    expected <- (coef_at(paste0("a", from), 1) * coef_at(edge, 1) +
                 coef_at(paste0("a", to), 1)) * coef_at(terminal, 1)
    if (type == "continuous") {
      center <- mean(prep$W - prep$W1)
      out <- wsMed:::analyze_mm_continuous(draws, prep, MP = c(edge, terminal),
               W_values = center + c(0, 1), point_estimates = p)
      got <- subset(out$conditional_overall, Effect == "total_indirect")$Estimate[2]
      expect_equal(length(unique(out$beta_coef$Path)), 2L)
    } else {
      out <- wsMed:::analyze_mm_categorical(draws, prep, MP = c(edge, terminal), point_estimates = p)
      got <- subset(out$conditional_overall, Effect == "total_indirect" & Group == "C")$Estimate
      expect_equal(length(unique(out$conditional_IE$IE)), 2L)
    }
    expect_equal(got, unname(expected), tolerance = 1e-7)
  }
})

test_that("UD public both mode preserves paths and standardized MC/bootstrap agreement", {
  paths <- c("M2 -> M1", "M1 -> Y")
  expect_warning(out <- wsMed(phase1_data(300), M_C1 = c("m11", "m21"),
    M_C2 = c("m12", "m22"), Y_C1 = "y1", Y_C2 = "y2", W = "W",
    W_type = "continuous", MP = c("b_2_1", "b1"), form = "ud", paths = paths,
    Na = "de", ci_method = "Both", R = 80, bootstrap = 100,
    standardized = TRUE, verbose = FALSE), "Bootstrap p-values are not computed")
  expect_identical(out$form, "UD")
  expect_identical(out$paths, paths)
  expect_false(is.null(out$mc$std_mc))
  expect_false(is.null(out$mc$std_boot))
  expect_equal(out$mc$std_mc$Estimate, out$mc$std_boot$est.std)
  expect_equal(out$moderation$mc$conditional_overall$Estimate,
               out$moderation$boot$conditional_overall$Estimate)
  expect_output(print(out, detail = "full"), "UNSTANDARDIZED CONDITIONAL EFFECTS")
})
