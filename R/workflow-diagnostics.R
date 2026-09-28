# Checks and descriptions shared by one-call and staged analyses.
.wsmed_preflight <- function(data, syntax, missing, dataset) {
  columns <- lavaan::lavNames(lavaan::lavaanify(syntax), "ov")
  d <- data[columns]
  if (missing == "DE") d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) < 2L) stop("Dataset ", dataset,
    ": fewer than two cases remain after missing-data handling.", call. = FALSE)
  constant <- names(d)[vapply(d, function(x) length(unique(x[!is.na(x)])) < 2L, logical(1))]
  if (length(constant)) stop("Dataset ", dataset,
    ": no usable variation in transformed variable(s): ", paste(constant, collapse = ", "),
    ". Check the condition pairs and predictor coding in the model.", call. = FALSE)
  invisible(NULL)
}

.wsmed_fit_diagnostics <- function(fits, warnings_by_dataset, input_n) {
  rows <- lapply(seq_along(fits), function(j) {
    fit <- fits[[j]]
    check_warnings <- character()
    admissible <- tryCatch(withCallingHandlers(lavaan::lavInspect(fit, "post.check"),
      warning = function(w) {
        check_warnings <<- c(check_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }), error = function(e) { check_warnings <<- conditionMessage(e); NA })
    vc <- tryCatch(lavaan::vcov(fit), error = function(e) NULL)
    finite <- !is.null(vc) && length(vc) > 0L && all(is.finite(vc))
    smallest <- if (finite) min(eigen((vc + t(vc))/2, symmetric = TRUE,
                                     only.values = TRUE)$values) else NA_real_
    warnings <- unique(c(warnings_by_dataset[[j]], check_warnings))
    observed <- lavaan::lavInspect(fit, "data")
    observed <- observed[stats::complete.cases(observed), , drop = FALSE]
    rank <- if (nrow(observed) > 1L && all(apply(observed, 2, stats::sd) > 0))
      qr(cbind(1, scale(observed)))$rank else NA_integer_
    data.frame(dataset = j, n.used = as.numeric(lavaan::lavInspect(fit, "nobs")),
      converged = isTRUE(lavaan::lavInspect(fit, "converged")),
      admissible = as.logical(admissible), covariance.finite = finite,
      covariance.min.eigenvalue = smallest, complete.cases = nrow(observed),
      complete.case.rank = rank, complete.case.columns = ncol(observed) + 1L,
      warnings = length(warnings),
      message = paste(warnings, collapse = " | "), stringsAsFactors = FALSE)
  })
  table <- do.call(rbind, rows)
  table$n.excluded <- input_n - table$n.used
  table
}

.wsmed_category_counts <- function(data, reference, indices, dataset) {
  predictors <- c(reference$between_covariates, list(reference$moderator))
  rows <- lapply(predictors, function(x) {
    if (is.null(x$levels)) return(NULL)
    tab <- table(factor(data[[x$variable]][indices], levels = x$levels))
    data.frame(dataset = dataset, variable = x$variable,
      level = names(tab), n = as.integer(tab), stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

.wsmed_print_fit_diagnostics <- function(d) {
  if (!is.null(d$by_dataset)) {
    bad <- with(d$by_dataset, !converged | is.na(admissible) | !admissible |
      !covariance.finite | warnings > 0L)
    cat("Post-fit admissibility:", sum(d$by_dataset$admissible %in% TRUE), "of",
      nrow(d$by_dataset), "; excluded rows:", paste(unique(d$by_dataset$n.excluded), collapse = ", "), "\n")
    if (any(bad)) {
      cat("Review dataset(s):", paste(d$by_dataset$dataset[bad], collapse = ", "), "\n")
      print(d$by_dataset[bad, c("dataset", "n.used", "converged", "admissible", "message")],
            row.names = FALSE)
    }
  }
  if (length(d$warnings)) cat("Recorded warnings:", length(d$warnings),
    "(see wsmed_inspect(object, 'diagnostics')).\n")
  if (!is.null(d$category_counts) && any(d$category_counts$n < 5L)) {
    cat("Small fitted category counts (<5; descriptive flag, not a validity cutoff):\n")
    print(d$category_counts[d$category_counts$n < 5L, , drop = FALSE], row.names = FALSE)
  }
}

.wsmed_analysis_description <- function(fit) {
  v <- fit$model$input_vars
  model <- lavaan::lav_model_set_parameters(fit$backend[[1]]@Model, x = fit$coefficients)
  sigma <- lavaan::lav_model_implied(model)$cov[[1]]
  index <- match("Ydiff", lavaan::lavNames(fit$backend[[1]], "ov"))
  variance <- sigma[index, index]
  list(conditions = fit$model$conditions,
    outcome = stats::setNames(c(v$Y_C1, v$Y_C2), fit$model$conditions),
    marginal_outcome_sd = if (is.finite(variance) && variance > 0) sqrt(variance) else NA_real_,
    moderator = fit$reference$by_dataset[[1]]$moderator,
    covariates = fit$reference$by_dataset[[1]]$between_covariates,
    missing = fit$Na, reference_policy = fit$reference$policy)
}

.wsmed_print_interpretation <- function(description, scale = "raw", type = NULL) {
  if (is.null(description)) return(invisible(NULL))
  cat("Condition contrast:", description$conditions[2], "-", description$conditions[1], "\n")
  mod <- description$moderator
  if (!is.null(mod)) {
    if (!is.null(mod$center)) cat("Moderator:", mod$variable,
      "in raw units; centering reference =", format(mod$center, digits = 6), "\n") else
      cat("Moderator:", mod$variable, "; reference category =", mod$levels[1], "\n")
  }
  for (cov in description$covariates) if (!is.null(cov$levels))
    cat("Covariate:", cov$variable, "; reference category =", cov$levels[1], "\n")
  if (identical(description$missing, "MI"))
    cat("MI: per-imputation centering; first-imputation reporting reference.\n")
  if (scale == "marginal") {
    if (length(type) && type %in% c("indirect", "direct", "total", "total_indirect")) {
      cat("Standardization: effect / marginal model-implied SD(",
        description$outcome[2], " - ", description$outcome[1],
        "); condition contrast is unscaled.\n", sep = "")
      cat("Plug-in marginal outcome-difference SD:",
        format(description$marginal_outcome_sd, digits = 6), "\n")
    } else cat("Standardization: marginal model-implied endpoint SDs; inspect term roles for path/parameter scales.\n")
    cat("The denominator is not a moderator-specific conditional SD.\n")
  }
  invisible(NULL)
}

.wsmed_print_contrast_definitions <- function(query) {
  if (query$type != "contrasts") return(invisible(NULL))
  source <- query$source_terms
  labels <- ifelse(is.na(source$at), source$label,
    paste0(source$label, " [", source$moderator, " = ", source$at, "]"))
  names(labels) <- source$term
  cat("Contrast direction (signed weights):\n")
  for (name in names(query$contrasts)) {
    w <- query$contrasts[[name]]
    cat(" ", name, ": ", paste(sprintf("%+g * %s", w, labels[names(w)]), collapse = " "), "\n", sep = "")
  }
}

.wsmed_print_draw_diagnostics <- function(inference, standardization = NULL) {
  if (!is.null(inference)) {
    cat("Inference draws:", inference$valid, "retained of", inference$requested,
      ";", inference$invalid, "excluded before effect extraction.\n")
    if (length(inference$warnings)) cat("Inference warnings:",
      paste(inference$warnings, collapse = " | "), "\n")
  }
  if (!is.null(standardization) && standardization$invalid > 0L) {
    cat("Standardization:", standardization$invalid, "invalid draws excluded jointly;",
      standardization$valid, "retained.\n")
    if (length(standardization$reasons)) cat("Reasons:",
      paste(names(standardization$reasons), as.integer(standardization$reasons),
            sep = " = ", collapse = "; "), "\n")
  }
}
