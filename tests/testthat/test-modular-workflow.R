workflow_model <- function(moderator = NULL, ...) {
  wsmed_model(c(before = "D1", after = "D2"),
    list(A = c(before = "A1", after = "A2"), B = c(before = "B1", after = "B2")),
    moderator = moderator, ...)
}

workflow_data <- function() {
  e <- new.env()
  utils::data("example_data", package = "wsMed", envir = e)
  as.data.frame(e$example_data)
}

test_that("specifications validate paired roles, graph edges and explicit types", {
  m <- workflow_model()
  expect_s3_class(m, "wsmed_model")
  expect_identical(m$input_vars$M_C1, c(A = "A1", B = "B1"))
  expect_error(wsmed_model(c("D1", "D2"), list(A = c("A1", "A2"))), "conditions")
  expect_error(workflow_model(structure = "custom", paths = c("A -> B", "B -> A", "A -> Y")), "cycle|acyclic")
  expect_error(workflow_model(moderator = list(variable = "D3", interactions = "B -> A")), "absent")
  expect_error(workflow_model(covariates = list("D3")), "covariates")
  d <- workflow_data(); d$Group <- as.character(d$Group)
  mg <- workflow_model(moderator = list(variable = "Group"))
  expect_error(wsmed_fit(mg, d), "explicitly to factors")
  d$D1[1] <- NA_real_
  expect_error(wsmed_fit(m, d), "missing-data strategy")
  expect_error(wsmed_fit(m, d, missing = "mi", mi = list(m = 1)), "m must")
  expect_equal(3 %||% 5, 3)
  expect_equal(NULL %||% 5, 5)
  expect_error(wsMed(d, M_C1 = "A1", M_C2 = "A2", Y_C1 = "D1", Y_C2 = "D2",
    Na = "FIML", MCmethod = "bootSD"), "never implemented")
})

test_that("fitting does not sample and one-call MC uses the same fitted engine", {
  local_mocked_bindings(ThetaHatStarWrapper = function(...) stop("Unexpected sampling"))
  d <- workflow_data(); m <- workflow_model()
  f <- wsmed_fit(m, d)
  expect_s3_class(f, "wsmed_fit")
  expect_null(f$draws)
  expect_identical(names(coef(f)), rownames(vcov(f)))
  expect_equal(vcov(f), lavaan::vcov(f$backend[[1]]), ignore_attr = TRUE)
  expect_equal(nobs(f), nrow(d))
  expect_error(confint(f), "wsmed_infer")
  expect_true(all(is.na(as.data.frame(wsmed_effects(f))$std.error)))
  expect_s3_class(summary(f), "summary_wsmed_fit")
  expect_identical(wsmed_inspect(f, "syntax"), f$sem_model)
  set.seed(932); state <- .Random.seed
  i <- wsmed_infer(f, draws = 100, seed = 34)
  expect_identical(.Random.seed, state)
  unseeded <- wsmed_infer(f, draws = 10)
  expect_false(identical(.Random.seed, state))
  expect_false(identical(wsmed_infer(f, draws = 10)$draws, unseeded$draws))
  x <- wsMed(d, M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
    Y_C1 = "D1", Y_C2 = "D2", R = 100, seed = 34)
  expect_equal(i$draws, x$mc$result$thetahatstar)
  expect_equal(coef(x), coef(f))
  expect_equal(vcov(x), vcov(f))
  expect_s3_class(x$model, "wsmed_model")
  expect_s3_class(x$inference$mc, "wsmed_inference")
  expect_output(print(x), "Stored inference")
  expect_lt(length(capture.output(print(x))), 10)
  expect_output(print(x, detail = "full"), "VARIABLES")
  expect_s3_class(summary(x), "wsmed_results")
  expect_equal(wsmed_effects(i)$draws, i$draws[, c("indirect_1", "indirect_2")])
})

test_that("FIML and MI one-call and staged workflows agree, retaining every MI fit", {
  d <- workflow_data(); d$D1[1:8] <- NA; d$A2[10:15] <- NA
  m <- workflow_model()
  for (method in c("fiml", "mi")) {
    f <- wsmed_fit(m, d, missing = method, mi = list(m = 3, seed = 71))
    set.seed(732); rng <- .Random.seed
    i <- wsmed_infer(f, draws = 80, seed = 71)
    expect_identical(.Random.seed, rng)
    x <- wsMed(d, M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
      Y_C1 = "D1", Y_C2 = "D2", Na = toupper(method), R = 80,
      mi_args = list(m = 3), seed = 71)
    expect_equal(i$draws, x$mc$result$thetahatstar, tolerance = 1e-12)
    expect_equal(coef(f), coef(x))
    if (method == "mi") {
      expect_length(f$backend, 3L)
      expect_length(f$mi$prepared$processed_data_list, 3L)
      expect_length(f$reference$by_dataset, 3L)
      expect_equal(f$reference$by_dataset[[2]]$mediator_average_centers[1],
        (mean(mice::complete(f$mi$prepared$mids, 2)$A1) +
           mean(mice::complete(f$mi$prepared$mids, 2)$A2)) / 2, ignore_attr = TRUE)
      pooled <- MICombineWrapper(lapply(f$backend, lavaan::coef),
        lapply(f$backend, lavaan::vcov), M = 3, k = length(coef(f)), adj = TRUE)
      expect_equal(vcov(f), pooled$total, ignore_attr = TRUE)
      with_mocked_bindings({
        expect_s3_class(wsmed_infer(f, draws = 20, seed = 17), "wsmed_inference")
        expect_error(wsmed_infer(f, method = "bootstrap", draws = 20), "MI-bootstrap")
      }, .wsmed_fit_core = function(...) stop("Unexpected refit"),
        PrepareMissingData = function(...) stop("Unexpected imputation"))
    }
  }
})

test_that("raw conditional effects use fitted interaction algebra at a single raw probe", {
  f <- wsmed_fit(workflow_model(moderator = list(variable = "D3",
    interactions = c("A -> Y", "B -> Y"))), workflow_data())
  i <- wsmed_infer(f, draws = 120, seed = 2)
  p <- .35; wc <- p - mean(f$data$D3 - f$data$W1)
  r <- wsmed_effects(i, at = list(D3 = p))
  expected <- (i$draws[, "a1"] + i$draws[, "aw1_W1"] * wc) *
              (i$draws[, "b1"] + i$draws[, "bw1_W1"] * wc)
  expect_equal(unname(r$draws[, 1]), unname(expected))
  expect_equal(unname(coef(r)[1]), unname((i$point["a1"] + i$point["aw1_W1"] * wc) *
    (i$point["b1"] + i$point["bw1_W1"] * wc)))
  expect_error(wsmed_effects(i, at = list(wrong = p)), "named list")
  expect_error(wsmed_effects(i, type = "parameters", at = list(D3 = p)), "not used")
  total <- wsmed_effects(i, type = "total", at = list(D3 = p))
  direct <- wsmed_effects(i, type = "direct", at = list(D3 = p))
  expect_equal(unname(total$draws[, 1]), unname(rowSums(r$draws) + direct$draws[, 1]))
})

test_that("standardization uses joint scales and fixed probes without changing RNG or fits", {
  d <- workflow_data()
  x <- wsMed(d, M_C1 = c("A1", "B1"), M_C2 = c("A2", "B2"),
    Y_C1 = "D1", Y_C2 = "D2", W = "D3", W_type = "continuous",
    MP = c("b1", "b2"), R = 120, seed = 5)
  i <- x$inference$mc
  frozen <- serialize(i, NULL)
  set.seed(916); state <- .Random.seed
  r <- with_mocked_bindings(
    wsmed_effects(i, at = list(D3 = c(.2, .4)), scale = "marginal"),
    .wsmed_fit_core = function(...) stop("Unexpected fit"),
    .wsmed_infer_core = function(...) stop("Unexpected inference"))
  lav <- i$fit$backend[[1]]
  pt <- lavaan::parameterTable(lav)
  for (j in c(1, 3, 7)) {
    model <- lavaan::lav_model_set_parameters(lav@Model, x = i$draws[j, names(coef(i))])
    implied <- lavaan::lav_model_implied(model)$cov[[1]]
    ov <- lavaan::lavNames(lav, "ov")
    sy <- sqrt(implied[match("Ydiff", ov), match("Ydiff", ov)])
    raw <- wsmed_effects(i, at = list(D3 = c(.2, .4)))
    expect_equal(unname(r$draws[match(j, r$draw_ids), ]), unname(raw$draws[j, ] / sy), tolerance = 1e-9)
  }
  ci90 <- confint(r, level = .90)
  expect_equal(unname(ci90[1, ]), unname(quantile(r$draws[, 1], c(.05, .95))))
  expect_identical(.Random.seed, state)
  expect_identical(serialize(i, NULL), frozen)
  expect_s3_class(plot(r), "ggplot")
  expect_s3_class(ggplot2::ggplot_build(plot(r)), "ggplot_built")
  file <- tempfile(fileext = ".rds"); on.exit(unlink(file))
  saveRDS(i, file)
  expect_equal(wsmed_effects(readRDS(file), at = list(D3 = c(.2, .4)), scale = "marginal"), r)
})

test_that("categorical probes and contrasts retain joint draw identities", {
  d <- workflow_data(); d$Group <- factor(d$Group)
  f <- wsmed_fit(workflow_model(moderator = list(variable = "Group",
    interactions = "A -> Y")), d)
  i <- wsmed_infer(f, draws = 150, seed = 9)
  r <- wsmed_effects(i, terms = "indirect_1")
  expect_equal(r$table$at, levels(d$Group))
  weights <- stats::setNames(c(-1, 1), r$table$term[1:2])
  contrast <- wsmed_contrasts(r, list(second_minus_first = weights))
  expect_equal(unname(contrast$draws[, 1]), unname(r$draws[, 2] - r$draws[, 1]))
  expect_equal(unname(coef(contrast)), unname(coef(r)[2] - coef(r)[1]))
  expect_identical(contrast$draw_ids, r$draw_ids)
  expect_equal(unname(confint(contrast)[1, ]), unname(quantile(r$draws[, 2] - r$draws[, 1], c(.025, .975))))
  expect_s3_class(ggplot2::ggplot_build(plot(contrast)), "ggplot_built")
  expect_error(wsmed_effects(i, at = list(Group = "nonexistent")), "Unknown")
})

test_that("custom reverse paths preserve named mediator roles", {
  m <- workflow_model(structure = "custom", paths = c("B -> A", "A -> Y", "B -> Y"))
  i <- wsmed_infer(wsmed_fit(m, workflow_data()), draws = 50, seed = 8)
  r <- wsmed_effects(i, terms = "indirect_2_1")
  expect_identical(r$table$label, "B -> A")
  expect_equal(unname(r$draws[, 1]), unname(i$draws[, "a2"] * i$draws[, "b_2_1"] * i$draws[, "b1"]))
})

test_that("invalid standardized draws are excluded jointly with original identities", {
  i <- wsmed_infer(wsmed_fit(workflow_model(), workflow_data()), draws = 40, seed = 12)
  i$draws[5, "Ydiff~~Ydiff"] <- -1000
  expect_warning(r <- wsmed_effects(i, scale = "marginal"), "1 of 40")
  expect_identical(r$diagnostics$invalid_draw_ids, 5L)
  expect_identical(r$draw_ids, seq_len(40L)[-5])
  expect_equal(nrow(r$draws), 39L)
  expect_equal(coef(r), stats::setNames(StdLav2(i$fit$coefficients,
    i$fit$backend[[1]])[match(c("indirect_1", "indirect_2"), i$fit$point$par_names)],
    c("indirect_1", "indirect_2")))
})

test_that("MI imputes raw categorical predictors before creating dummy interactions", {
  d <- workflow_data()
  d$Group <- factor(rep(c("L", "M", "H"), length.out = nrow(d)), levels = c("L", "M", "H"))
  d$Group[c(1, 4, 8)] <- NA
  m <- wsmed_model(c(T1 = "D1", T2 = "D2"), list(A = c(T1 = "A1", T2 = "A2")),
    moderator = list(variable = "Group", interactions = "A -> Y"))
  f <- wsmed_fit(m, d, missing = "mi", mi = list(m = 2, seed = 123))
  expect_equal(unname(nobs(f)), c(100, 100))
  expect_identical(f$reference$by_dataset[[1]]$moderator$levels, c("L", "M", "H"))
  expect_identical(f$reference$by_dataset[[2]]$moderator$coding,
                   f$reference$by_dataset[[1]]$moderator$coding)
  expect_false(anyNA(f$data))
  r <- wsmed_effects(wsmed_infer(f, draws = 40, seed = 42))
  expect_identical(r$table$at, c("L", "M", "H"))
  expect_error(wsmed_fit(m, d, missing = "fiml"), "missing categorical")
  deleted <- wsmed_fit(m, d, missing = "listwise")
  expect_equal(nobs(deleted), 97)
  expect_identical(deleted$diagnostics$case_indices[[1]], setdiff(seq_len(100), c(1L, 4L, 8L)))
  old_options <- options(contrasts = c("contr.sum", "contr.poly"))
  changed_options <- tryCatch(wsmed_fit(m, d, missing = "listwise"),
    finally = options(old_options))
  expect_equal(coef(changed_options), coef(deleted))
  expect_true(all(na.omit(changed_options$data$W1) %in% c(0, 1)))
  expect_true(all(na.omit(changed_options$data$W2) %in% c(0, 1)))
  mc <- wsmed_model(c(T1 = "D1", T2 = "D2"), list(A = c(T1 = "A1", T2 = "A2")),
    covariates = list(between = "Group"))
  fc <- wsmed_fit(mc, d, missing = "listwise")
  expect_equal(nobs(fc), 97)
  expect_true(all(na.omit(fc$data$Cb1_1) %in% c(0, 1)))
})

test_that("bootstrap is reusable and dual-inference selection is explicit", {
  skip_on_cran()
  d <- workflow_data()
  f <- wsmed_fit(workflow_model(), d)
  i <- suppressWarnings(wsmed_infer(f, method = "bootstrap", draws = 40, seed = 32))
  r <- wsmed_effects(i)
  expect_identical(r$query$method, "bootstrap")
  expect_identical(r$query$interval, "percentile")
  expect_true(all(as.data.frame(r)$method == "bootstrap"))
  expect_true(all(as.data.frame(r)$n.valid == nrow(r$draws)))
  expect_equal(nrow(r$draws), length(i$draw_ids))
  expect_equal(r$draws, i$draws[, c("indirect_1", "indirect_2")], ignore_attr = TRUE)
  mc <- wsmed_infer(f, draws = 40, seed = 32)
  x <- .wsmed_assemble(f, list(mc = mc, bootstrap = i), .05, FALSE)
  expect_error(summary(x), "Choose method")
  expect_equal(coef(wsmed_effects(x, method = "bootstrap")), coef(r))
  expect_equal(confint(i, parm = "a1"), confint(wsmed_effects(i, type = "parameters"), parm = "a1"))
})
