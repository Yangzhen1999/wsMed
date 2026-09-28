# Shared fitting and inference engines for both public workflows.
.wsmed_preserve_rng <- function(code, preserve = TRUE) {
  if (!preserve) return(force(code))
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had) assign(".Random.seed", old, envir = .GlobalEnv) else
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv), add = TRUE)
  force(code)
}

.wsmed_legacy_model <- function(input_vars, form, paths = NULL) {
  structure(list(schema_version = 1L, input_vars = input_vars, form = form,
    paths = paths, conditions = c("C1", "C2"),
    mediator_names = paste0("M", seq_along(input_vars$M_C1)),
    reference_policy = "legacy: per-imputation centering; first-imputation probes"),
    class = "wsmed_model")
}

.wsmed_compile <- function(model, prep) {
  fun <- switch(model$form, P = GenerateModelP, CN = GenerateModelCN,
    CP = GenerateModelCP, PC = GenerateModelPC, UD = GenerateModelCustom)
  args <- list(prepared_data = prep, MP = model$input_vars$MP)
  if (model$form == "UD") args$paths <- model$paths
  do.call(fun, args)
}

.wsmed_point <- function(fit, coefficients) {
  ThetaHatWrapper(fit, est = lavaan::lav_model_get_parameters(
    lavaan::lav_model_set_parameters(fit@Model, x = coefficients),
    type = "user", extra = TRUE))
}

.wsmed_pool_fits <- function(fits) {
  coefs <- lapply(fits, lavaan::coef)
  vcovs <- lapply(fits, lavaan::vcov)
  ids <- names(coefs[[1]])
  if (anyDuplicated(ids) || !all(vapply(coefs, function(x)
      identical(names(x), ids), logical(1))))
    stop("Imputation parameter identities/order differ; pooling stopped.")
  out <- MICombineWrapper(coefs, vcovs, M = length(fits), k = length(ids), adj = TRUE)
  out$marginal <- .wsmed_pool_marginal(fits, coefs, vcovs)
  out
}

# Record the existing transformation coordinates without changing them.
.wsmed_reference_data <- function(model, raw, prepared) {
  v <- model$input_vars
  avg <- vapply(seq_along(v$M_C1), function(j)
    (mean(raw[[v$M_C1[j]]], na.rm = TRUE) + mean(raw[[v$M_C2[j]]], na.rm = TRUE)) / 2,
    numeric(1))
  names(avg) <- paste0("M", seq_along(avg), "avg")
  within <- lapply(seq_along(v$C_C1), function(j) c(
    difference = mean(raw[[v$C_C2[j]]] - raw[[v$C_C1[j]]], na.rm = TRUE),
    average = mean((raw[[v$C_C2[j]]] + raw[[v$C_C1[j]]]) / 2, na.rm = TRUE)))
  predictor <- function(name, map) {
    continuous <- length(map) == 1L && identical(map[[1]], "continuous")
    list(variable = name, center = if (continuous) mean(raw[[name]], na.rm = TRUE) else NULL,
      levels = if (!continuous) levels(factor(raw[[name]])) else NULL, coding = map)
  }
  c_map <- attr(prepared, "C_info")$dummy_map
  between <- lapply(seq_along(v$C), function(j) predictor(v$C[j],
    c_map[grepl(paste0("^Cb", j, "(_|$)"), names(c_map))]))
  list(mediator_average_centers = avg, within_covariate_centers = within,
    between_covariates = between, moderator = if (length(v$W))
      predictor(v$W, attr(prepared, "W_info")$dummy_map) else NULL)
}

.wsmed_fit_core <- function(model, data, Na, mi_args, fixed.x, verbose = FALSE) {
  vars <- model$input_vars
  .v("Preparing data ...", verbose = verbose)
  prep_args <- vars[setdiff(names(vars), "MP")]
  prep <- syntax <- NULL
  if (Na != "MI") {
    prep <- do.call(PrepareData, c(list(data = data), prep_args,
      list(keep_W_raw = TRUE, keep_C_raw = TRUE)))
    .v(sprintf("Building SEM syntax (%s) ...", model$form), verbose = verbose)
    syntax <- .wsmed_compile(model, prep)
  }
  imputation <- pooled <- NULL
  warnings_seen <- character()
  warnings_by_dataset <- list()
  fit_one <- function(d, j) {
    warnings_by_dataset[[j]] <<- character()
    .wsmed_preflight(d, syntax, Na, j)
    tryCatch(withCallingHandlers({
      if (Na == "MI") lavaan::sem(syntax, d, fixed.x = fixed.x) else
        .fit_and_mc(syntax, d, Na = Na, fixed.x = fixed.x,
          verbose = FALSE, run_mc = FALSE)$fit
    }, warning = function(w) warnings_by_dataset[[j]] <<-
      c(warnings_by_dataset[[j]], conditionMessage(w))),
      error = function(e) stop("Dataset ", j, ": ", conditionMessage(e), call. = FALSE))
  }
  fits <- withCallingHandlers({
    if (Na == "MI") {
      if (mi_args$m < 2L) stop("MI pooling requires at least two imputations.")
      invisible(utils::capture.output(imputation <- do.call(PrepareMissingData,
        c(list(data_missing = data, m = mi_args$m, method_num = mi_args$method_num,
               seed = mi_args$seed), prep_args,
          list(keep_W_raw = TRUE, keep_C_raw = TRUE)))))
      completed <- imputation$processed_data_list
      prep <- completed[[1]]
      .v(sprintf("Building SEM syntax (%s) ...", model$form), verbose = verbose)
      syntax <- .wsmed_compile(model, prep)
      lapply(seq_along(completed), function(j) fit_one(completed[[j]], j))
    } else {
      list(fit_one(prep, 1L))
    }
  }, warning = function(w) warnings_seen <<- c(warnings_seen, conditionMessage(w)))
  dataset_diagnostics <- .wsmed_fit_diagnostics(fits, warnings_by_dataset, nrow(data))
  if (Na == "MI" && any(!dataset_diagnostics$converged))
    stop("MI pooling stopped: non-converged dataset(s) ",
      paste(which(!dataset_diagnostics$converged), collapse = ", "), call. = FALSE)
  roles <- .wsmed_roles(prep)
  fits <- lapply(fits, function(x) { x@external$wsmed_roles <- roles; x })
  if (Na == "MI") {
    pooled <- .wsmed_pool_fits(fits)
    fits[[1]]@external$wsmed_mi_marginal <- if (!is.null(pooled$marginal))
      list(point = pooled$marginal$point) else NULL
  }
  if (length(vars$W)) {
    maps <- attr(prep, "W_info")$dummy_map
    model$input_vars$W_type <- if (length(maps) == 1L &&
      identical(maps[[1]], "continuous")) "continuous" else "categorical"
  }
  coefficients <- if (Na == "MI") pooled$est else lavaan::coef(fits[[1]])
  covariance <- if (Na == "MI") pooled$total else lavaan::vcov(fits[[1]])
  dimnames(covariance) <- list(names(coefficients), names(coefficients))
  converged <- vapply(fits, function(x) isTRUE(lavaan::lavInspect(x, "converged")), logical(1))
  references <- if (Na == "MI") lapply(seq_along(fits), function(j)
    .wsmed_reference_data(model, mice::complete(imputation$mids, j),
                          imputation$processed_data_list[[j]])) else
    list(.wsmed_reference_data(model, data, prep))
  category_counts <- do.call(rbind, lapply(seq_along(fits), function(j)
    .wsmed_category_counts(if (Na == "MI") completed[[j]] else prep,
      references[[j]], lavaan::lavInspect(fits[[j]], "case.idx"), j)))
  structure(list(schema_version = 1L, model = model, data = prep, raw_data = data,
    sem_model = syntax, Na = Na, fixed.x = fixed.x,
    coefficients = coefficients, covariance = covariance,
    point = .wsmed_point(fits[[1]], coefficients), backend = fits,
    mi = list(prepared = imputation, pooled = pooled, controls = mi_args),
    reference = list(policy = model$reference_policy,
      moderator = attr(prep, "W_info"), covariates = attr(prep, "C_info"),
      by_dataset = references, reporting_dataset = 1L),
    diagnostics = list(converged = converged, warnings = unique(warnings_seen),
      admissible = dataset_diagnostics$admissible, by_dataset = dataset_diagnostics,
      category_counts = category_counts,
      n_input = nrow(data), n_used = vapply(fits, function(x)
        as.numeric(lavaan::lavInspect(x, "nobs")), numeric(1)),
      case_indices = lapply(fits, function(x) lavaan::lavInspect(x, "case.idx"))),
    provenance = list(R = R.version.string, wsMed = utils::packageVersion("wsMed"),
      algorithms = .wsmed_fit_algorithms(),
      lavaan = utils::packageVersion("lavaan"),
      mice = if (Na == "MI") utils::packageVersion("mice") else NULL,
      platform = R.version$platform, RNGkind = RNGkind(),
      marginal_standardization = if (!is.null(pooled$marginal))
        "MI pooled marginal variances with joint Rubin covariance" else
        "Fitted model-implied marginal variances")),
    class = "wsmed_fit")
}

# This accepts already fitted/pooled MI quantities. It never fits or imputes.
.wsmed_mi_mc <- function(fit, R, alpha, seed, decomposition, pd, tol) {
  raw <- ThetaHatStarWrapper(R = R, location = fit$coefficients,
    scale = fit$covariance, decomposition = decomposition, pd = pd, tol = tol)
  lav <- fit$backend[[1]]
  lav@external$wsmed_mi_marginal <- .wsmed_draw_marginal(fit$mi$pooled$marginal,
    fit$coefficients, fit$covariance, raw$thetahatstar)
  structure(list(call = match.call(), args = list(lav = lav, fixed.x = fit$fixed.x,
    sem_model = fit$sem_model, imputations = fit$mi$prepared$processed_data_list,
    R = R, alpha = alpha, decomposition = raw$decomposition, pd = pd, tol = tol,
    seed = seed, pooled = fit$mi$pooled), thetahat = fit$point,
    thetahatstar = MCDefWrapper(lav, fit$point, raw$thetahatstar), fun = "MCMI"),
    class = c("semmcci", "list"))
}

.wsmed_infer_core <- function(fit, method, draws, seed, level, boot_ci_type,
                              decomposition, pd, tol, verbose = FALSE) {
  .wsmed_check_fit(fit)
  if (!all(fit$diagnostics$converged)) stop("Inference requires converged fits.")
  bad <- which(!fit$diagnostics$admissible)
  if (length(bad)) stop("Inference requires admissible fits; review dataset(s): ",
    paste(bad, collapse = ", "), ". See wsmed_inspect(fit, 'diagnostics').", call. = FALSE)
  if (!all(is.finite(fit$covariance))) stop("Inference requires a finite parameter covariance matrix.")
  if (fit$Na == "MI" && method == "bootstrap")
    stop("MI-bootstrap is not supported; use method = 'mc'.")
  alpha <- 1 - level
  lav <- fit$backend[[1]]
  mc <- boot_fit <- boot_table <- NULL
  warnings_seen <- character()
  mat <- withCallingHandlers({
    if (method == "mc") {
      .v(sprintf("Monte-Carlo draws (R = %d) ...", draws), verbose = verbose)
      if (fit$Na == "MI") {
        if (!is.null(seed)) set.seed(seed)
        mc <- .wsmed_mi_mc(fit, draws, alpha, seed, decomposition, pd, tol)
      } else {
        mc <- semmcci::MC(lav = lav, R = draws, alpha = alpha, seed = seed)
      }
      mc$thetahatstar
    } else {
      .v(sprintf("Bootstrap draws (B = %d) ...", draws), verbose = verbose)
      boot_fit <- semboottools::store_boot(lav, R = draws, iseed = seed,
        do_bootstrapping = TRUE, ncpus = min(2L, draws), parallel = "snow")
      raw <- boot_fit@external$sbt_boot_ustd
      keep <- apply(raw, 1L, function(z) all(is.finite(z)))
      if (!all(keep)) .v(sprintf("Filtered %d replicates with non-finite parameter estimates.", sum(!keep)), verbose = verbose)
      boot_table <- semboottools::parameterEstimates_boot(boot_fit, level = level,
        boot_ci_type = boot_ci_type, boot_pvalue = TRUE)
      .add_indirect_boot(raw[keep, , drop = FALSE], fit$sem_model)
    }
  }, warning = function(w) warnings_seen <<- c(warnings_seen, conditionMessage(w)))
  if (nrow(mat) < 2L) stop("Inference requires at least two valid draws.")
  if (method == "mc") ids <- seq_len(nrow(mat)) else ids <- which(keep)
  structure(list(schema_version = 1L, fit = fit, method = method,
    draws = mat, draw_ids = ids, point = fit$point$est,
    controls = list(draws = draws, seed = seed, level = level,
      interval = if (method == "mc") "percentile" else boot_ci_type,
      decomposition = if (fit$Na == "MI") mc$args$decomposition else NULL,
      pd = pd, tol = tol, RNGkind = RNGkind()),
    provenance = list(fit = fit$provenance, semmcci = utils::packageVersion("semmcci"),
      algorithms = .wsmed_inference_algorithms(),
      semboottools = utils::packageVersion("semboottools"),
      sampler = if (method == "bootstrap") "semboottools participant bootstrap" else
        if (fit$Na == "MI") paste("pooled MI", mc$args$decomposition) else "semmcci::MC"),
    backend = list(mc = mc, fit_u = boot_fit, bootstrap = boot_table),
    diagnostics = list(requested = draws, valid = nrow(mat),
      invalid = draws - nrow(mat),
      reasons = if (method == "bootstrap" && any(!keep))
        c(nonfinite_bootstrap_parameters = sum(!keep)) else integer(),
      invalid_draw_ids = if (method == "bootstrap") which(!keep) else integer(),
      warnings = unique(warnings_seen))),
    class = "wsmed_inference")
}
