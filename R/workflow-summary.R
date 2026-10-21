# Resolve one reporting preference without changing the fitted parameterization.
.wsmed_scale <- function(object, scale = NULL, standardized = NULL) {
  if (!is.null(standardized) && (!is.logical(standardized) ||
      length(standardized) != 1L || is.na(standardized)))
    stop("standardized must be TRUE, FALSE or NULL.", call. = FALSE)
  if (!is.null(scale)) {
    scale <- match.arg(scale, c("raw", "marginal"))
    if (!is.null(standardized) && !identical(standardized, scale == "marginal"))
      stop("scale and standardized specify conflicting settings.", call. = FALSE)
    return(scale)
  }
  if (is.null(standardized)) {
    standardized <- object$standardized %||% object$fit$standardized
    if (is.null(standardized) && inherits(object, "wsMed"))
      standardized <- !is.null(object$mc$std_mc) || !is.null(object$mc$std_boot) ||
        !is.null(object$moderation_std)
  }
  if (isTRUE(standardized)) "marginal" else "raw"
}

.wsmed_summary <- function(object, type = "all", at = NULL, scale = NULL,
                           method = NULL, standardized = NULL, terms = NULL,
                           level = NULL, ...) {
  .wsmed_unused_dots(...)
  scale <- .wsmed_scale(object, scale, standardized)
  effects <- wsmed_effects(object, type = type, terms = terms, at = at,
    scale = scale, method = method, level = level)
  # Reuse selected raw probes and suppress only duplicate support warnings.
  # Parameter-only queries do not evaluate or warn about moderator probes.
  coefficients <- if (type %in% c("paths", "parameters")) effects else
    withCallingHandlers(wsmed_effects(object, type = "paths", at = at,
      scale = scale, method = method, level = level),
      wsmed_extrapolation_warning = function(w) invokeRestart("muffleWarning"))
  selected <- .wsmed_select(object, method)
  effects$effects <- effects$table
  effects$coefficients <- coefficients$table
  effects$coefficient_results <- coefficients
  effects$info <- list(model = selected$fit$model$form, missing = selected$fit$Na,
    nobs = selected$fit$diagnostics$n_used, method = effects$query$method,
    standardized = scale == "marginal", level = effects$query$level,
    interval = effects$query$interval, type = type, at = effects$query$at,
    probes = unique(effects$table[c("moderator", "at")]),
    conditions = effects$query$conditions, interpretation = effects$query$interpretation)
  effects$fit_diagnostics <- selected$fit$diagnostics
  class(effects) <- c("summary_wsmed", "wsmed_results")
  effects
}

#' @rdname wsmed_methods
#' @export
print.summary_wsmed <- function(x, digits = 3, ...) {
  .wsmed_unused_dots(...)
  cat("wsMed statistical summary\n")
  cat("Model:", x$info$model, "| Missing:", x$info$missing,
    "| Observations:", paste(unique(x$info$nobs), collapse = ", "), "\n")
  cat(if (x$query$type %in% c("paths", "parameters")) "Selected coefficients:\n" else "Effects:\n")
  print.wsmed_results(x, digits = digits)
  if (!x$query$type %in% c("paths", "parameters")) {
    cat("\nPath coefficients:\n")
    .wsmed_print_result_table(x$coefficient_results, digits = digits)
  }
  .wsmed_print_fit_diagnostics(x$fit_diagnostics)
  cat("Tables: $effects, $coefficients; analysis settings: $info.\n")
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
summary.summary_wsmed <- function(object, level = NULL, ...) {
  .wsmed_unused_dots(...)
  object <- summary.wsmed_results(object, level = level)
  object$effects <- object$table
  object$coefficient_results <- summary.wsmed_results(object$coefficient_results,
    level = object$query$level)
  object$coefficients <- object$coefficient_results$table
  object$info$level <- object$query$level
  object
}
