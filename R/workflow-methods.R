#' Methods for modular wsMed objects
#'
#' @param x,object A wsMed or modular workflow object.
#' @param detail overview (default) or full for the original wsMed printed tables.
#' @param digits Number of displayed digits. Stored estimates are not rounded.
#' @param parm Names or positions of parameters/effects to include in intervals.
#' @param level Confidence level. NULL uses the level saved in the selected inference or results object.
#' @param type,at,scale,method Passed to [wsmed_effects()].
#' @param row.names,optional Standard data-frame conversion arguments.
#' @param ... Additional arguments, passed to effect extraction by summary and
#'   confint methods. See [wsmed_plots] for plotting arguments.
#' @return print methods return their input invisibly. summary returns a
#'   wsmed_results for inference or a summary_wsmed_fit for fits; coef returns
#'   a named numeric vector. vcov returns the fit covariance (Rubin-pooled for
#'   MI), or the empirical covariance of stored draws for inference/results.
#'   confint recomputes percentile limits from stored draws without sampling.
#'   Its default level is the saved level, including when called on an inference
#'   or one-call object; use an explicit level to override it. On those two
#'   classes confint concerns primitive parameters; extract effects first to
#'   obtain indirect/conditional-effect intervals.
#'   nobs returns the sample size for each fitted dataset. as.data.frame returns
#'   a full-precision results table. plot returns a ggplot.
#' @name wsmed_methods
#' @seealso [wsmed_reproducibility()] for an exportable analysis manifest.
#' @importFrom stats coef vcov confint nobs quantile sd
#' @importFrom utils combn
#' @importFrom graphics plot
NULL

#' @rdname wsmed_methods
#' @export
print.wsMed <- function(x, digits = 3, detail = c("overview", "full"), ...) {
  detail <- match.arg(detail)
  if (detail == "full") return(.print_wsmed_full(x, digits = digits, ...))
  cat("wsMed analysis\n")
  if (inherits(x$fit, "wsmed_fit")) {
    print(x$fit, digits = digits)
    cat("Stored inference:", paste(names(x$inference), collapse = ", "), "\n")
  } else cat("Model:", x$form, " Missing-data method:", x$Na, "\n")
  cat("Use summary() for effects; print(detail = 'full') for all legacy tables.\n")
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
print.wsmed_model <- function(x, ...) {
  cat("wsMed model:", x$form, "\n")
  cat("Difference:", x$conditions[2], "-", x$conditions[1], "\n")
  cat("Mediators:", paste(x$mediator_names, collapse = ", "), "\n")
  if (length(x$input_vars$W)) cat("Moderator:", x$input_vars$W,
    "(main effects in all difference equations)\n")
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
print.wsmed_fit <- function(x, digits = 3, ...) {
  cat("wsMed fit:", x$model$form, "|", x$Na, "|", length(x$backend), "fitted dataset(s)\n")
  cat("Observations:", paste(unique(x$diagnostics$n_used), collapse = ", "),
      "of", x$diagnostics$n_input, "input rows\n")
  cat("Converged:", sum(x$diagnostics$converged), "of", length(x$backend), "\n")
  .wsmed_print_interpretation(.wsmed_analysis_description(x))
  .wsmed_print_fit_diagnostics(x$diagnostics)
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
print.wsmed_inference <- function(x, ...) {
  cat("wsMed inference:", x$method, "|", nrow(x$draws), "valid draws of",
      x$controls$draws, "requested\n")
  cat(100 * x$controls$level, "% effect intervals: percentile; stored parameter-table convention: ",
    x$controls$interval, "\n", sep = "")
  .wsmed_print_draw_diagnostics(x$diagnostics)
  cat("Use summary() or wsmed_effects() to select effects.\n")
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
summary.wsmed_fit <- function(object, ...) {
  .wsmed_unused_dots(...)
  structure(list(coefficients = cbind(Estimate = object$coefficients,
    `Std. Error` = sqrt(diag(object$covariance))), diagnostics = object$diagnostics,
    missing = object$Na, interpretation = .wsmed_analysis_description(object)), class = "summary_wsmed_fit")
}

#' @rdname wsmed_methods
#' @export
print.summary_wsmed_fit <- function(x, digits = 3, ...) {
  .wsmed_unused_dots(...)
  cat("wsMed fitted parameters (", x$missing, ")\n", sep = "")
  cat("Standard errors from ", if (x$missing == "MI") "Rubin-pooled" else "fitted",
      " parameter covariance; confidence intervals require inference.\n", sep = "")
  .wsmed_print_interpretation(x$interpretation)
  .wsmed_print_fit_diagnostics(x$diagnostics)
  stats::printCoefmat(x$coefficients, digits = digits, has.Pvalue = FALSE,
                      signif.stars = FALSE, cs.ind = 1:2, tst.ind = integer())
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
summary.wsmed_inference <- function(object, type = "indirect", at = NULL,
                                     scale = "raw", ...) {
  wsmed_effects(object, type = type, at = at, scale = scale, ...)
}

#' @rdname wsmed_methods
#' @export
summary.wsMed <- function(object, type = "indirect", at = NULL, scale = "raw",
                           method = NULL, ...) {
  wsmed_effects(object, type = type, at = at, scale = scale, method = method, ...)
}

#' @rdname wsmed_methods
#' @export
coef.wsmed_fit <- function(object, ...) object$coefficients

#' @rdname wsmed_methods
#' @export
vcov.wsmed_fit <- function(object, ...) object$covariance

#' @rdname wsmed_methods
#' @export
nobs.wsmed_fit <- function(object, ...) object$diagnostics$n_used

#' @rdname wsmed_methods
#' @export
coef.wsmed_inference <- function(object, ...) stats::coef(object$fit)

#' @rdname wsmed_methods
#' @export
vcov.wsmed_inference <- function(object, ...) {
  stats::cov(object$draws[, names(stats::coef(object)), drop = FALSE])
}

#' @rdname wsmed_methods
#' @export
nobs.wsmed_inference <- function(object, ...) stats::nobs(object$fit)

#' @rdname wsmed_methods
#' @export
coef.wsMed <- function(object, ...) {
  if (!inherits(object$fit, "wsmed_fit")) stop("Use existing accessors for this pre-modular saved object.")
  stats::coef(object$fit)
}

#' @rdname wsmed_methods
#' @export
vcov.wsMed <- function(object, ...) {
  if (!inherits(object$fit, "wsmed_fit")) stop("Use existing accessors for this pre-modular saved object.")
  stats::vcov(object$fit)
}

#' @rdname wsmed_methods
#' @export
nobs.wsMed <- function(object, ...) {
  if (!inherits(object$fit, "wsmed_fit")) stop("Use existing accessors for this pre-modular saved object.")
  stats::nobs(object$fit)
}

#' @rdname wsmed_methods
#' @export
confint.wsmed_fit <- function(object, parm, level = NULL, ...) {
  stop("A fit stores no simulation; call wsmed_infer() before confint().")
}

#' @rdname wsmed_methods
#' @export
confint.wsmed_inference <- function(object, parm, level = NULL, ...) {
  result <- wsmed_effects(object, type = "parameters", level = level, ...)
  if (missing(parm)) stats::confint(result) else
    stats::confint(result, parm = parm)
}

#' @rdname wsmed_methods
#' @export
confint.wsMed <- function(object, parm, level = NULL, method = NULL, ...) {
  result <- wsmed_effects(object, type = "parameters", method = method, level = level, ...)
  if (missing(parm)) stats::confint(result) else
    stats::confint(result, parm = parm)
}

#' @rdname wsmed_methods
#' @export
print.wsmed_results <- function(x, digits = 3, ...) {
  .wsmed_unused_dots(...)
  cat("wsMed", x$query$type, "|", x$query$scale, "scale |", x$query$method, "\n")
  if (nrow(x$draws)) cat(100 * x$query$level, "% percentile intervals; ",
    nrow(x$draws), " joint draws; SE from effect draws\n", sep = "") else
      cat("Point estimates only; no simulation-based SE or intervals.\n")
  .wsmed_print_interpretation(x$query$interpretation, x$query$scale,
    if (x$query$type == "contrasts") x$query$source_type else x$query$type)
  .wsmed_print_contrast_definitions(x$query)
  d <- x$table
  display <- ifelse(d$label == d$term, d$term, paste0(d$term, ": ", d$label))
  probes <- if (identical(x$query$moderator_type, "continuous"))
    format(signif(as.numeric(d$at), digits), trim = TRUE) else d$at
  if (any(!is.na(d$at))) display <- paste0(display, " [", d$moderator, " = ", probes, "]")
  mat <- cbind(Estimate = d$estimate)
  if (nrow(x$draws)) mat <- cbind(mat, `Std. Error` = d$std.error,
    `CI lower` = d$conf.low, `CI upper` = d$conf.high)
  rownames(mat) <- display
  stats::printCoefmat(mat, digits = digits, has.Pvalue = FALSE, signif.stars = FALSE,
                      cs.ind = seq_len(ncol(mat)), tst.ind = integer())
  .wsmed_print_draw_diagnostics(x$query$inference_diagnostics, x$diagnostics)
  cat("Use as.data.frame() for the full-precision table and metadata.\n")
  invisible(x)
}

#' @rdname wsmed_methods
#' @export
summary.wsmed_results <- function(object, level = NULL, ...) {
  .wsmed_unused_dots(...)
  if (is.null(level)) level <- object$query$level
  .wsmed_level(level)
  object$query$level <- level
  if (nrow(object$draws)) {
    ci <- .wsmed_quantiles(object$draws, level)
    object$table$conf.low <- ci[, 1]; object$table$conf.high <- ci[, 2]
    object$table$conf.level <- level
  }
  object
}

#' @rdname wsmed_methods
#' @export
as.data.frame.wsmed_results <- function(x, row.names = NULL, optional = FALSE, ...) {
  out <- x$table
  if (!is.null(row.names)) rownames(out) <- row.names
  out
}

#' @rdname wsmed_methods
#' @export
coef.wsmed_results <- function(object, ...) object$point

#' @rdname wsmed_methods
#' @export
vcov.wsmed_results <- function(object, ...) {
  if (!nrow(object$draws)) stop("No inference is stored; call wsmed_infer() first.")
  stats::cov(object$draws)
}

#' @rdname wsmed_methods
#' @export
confint.wsmed_results <- function(object, parm, level = NULL, ...) {
  .wsmed_unused_dots(...)
  if (is.null(level)) level <- object$query$level
  out <- .wsmed_quantiles(object$draws, level)
  if (missing(parm)) return(out)
  if (is.character(parm) && any(!parm %in% rownames(out)) ||
      is.numeric(parm) && any(!parm %in% seq_len(nrow(out)))) stop("Unknown interval term.")
  out[parm, , drop = FALSE]
}

#' Inspect a modular workflow without recomputation
#' @param object A wsmed_model, wsmed_fit, wsmed_inference, or wsMed object.
#' @param component model, syntax, data, fits, diagnostics, or provenance.
#' @return The requested specification, syntax, data, backend fits, or metadata.
#' @export
wsmed_inspect <- function(object, component = c("model", "syntax", "data", "fits",
                                               "diagnostics", "provenance")) {
  component <- match.arg(component)
  if (inherits(object, "wsmed_model")) {
    if (component == "model") return(object)
    stop("This component requires fitted data.")
  }
  if (inherits(object, "wsMed")) object <- object$fit
  if (inherits(object, "wsmed_inference")) {
    if (component == "diagnostics") return(object$diagnostics)
    if (component == "provenance") return(object$provenance)
    object <- object$fit
  }
  if (!inherits(object, "wsmed_fit")) stop("A modular workflow object is required.")
  switch(component, model = object$model, syntax = object$sem_model,
    data = object$data, fits = object$backend, diagnostics = object$diagnostics,
    provenance = object$provenance)
}
