#' Extract effects from fitted models or stored inference
#'
#' @param object A wsmed_fit, wsmed_inference, or wsMed result.
#' @param type Effect family: indirect, total, direct, total_indirect, paths,
#'   or parameters (primitive model parameters).
#' @param terms Optional coefficient or effect names within the selected family.
#' @param at Named list of raw moderator values, for example list(Age = c(30, 50)).
#'   Defaults to the centering reference for a continuous moderator, or all
#'   observed levels for a categorical moderator. Parameters ignore no probes:
#'   supplying at with type = "parameters" is an error.
#' @param scale raw or marginal model-implied endpoint standardization.
#' @param method Stored inference to use when object is wsMed: mc or bootstrap.
#'   Required if both are stored. A fit alone returns point estimates only.
#' @param level Confidence level; defaults to the stored inference level or .95.
#' @return A wsmed_results object with a full-precision table, joint effect draws,
#'   draw identities, query settings, and diagnostics.
#' @details Extraction never fits, imputes, or samples. Effect and contrast
#' intervals are percentile intervals from the stored joint draws, including
#' when bootstrap parameter tables were requested with bias correction.
#' For conditional standardization, moderator probes remain fixed in raw units.
#' Scales and coefficients vary jointly across draws. Invalid standardized draws
#' are excluded jointly and their original identities are recorded. For MI the
#' existing first-imputation reference and per-imputation centering are retained.
#' For product-term models, changing categorical reference coding can change
#' the joint model's implied marginal SDs. Standardized effects are not guaranteed
#' to be invariant to such recoding; retain and report the coding and standardizer.
#' The query interpretation records the plug-in outcome-difference SD.
#' @export
wsmed_effects <- function(object, type = c("indirect", "total", "direct",
                           "total_indirect", "paths", "parameters"), terms = NULL,
                           at = NULL, scale = c("raw", "marginal"),
                           method = NULL, level = NULL) {
  type <- match.arg(type); scale <- match.arg(scale)
  selected <- .wsmed_select(object, method)
  fit <- selected$fit; inference <- selected$inference
  if (is.null(level)) level <- inference$controls$level %||% .95
  .wsmed_level(level)
  if (type == "parameters" && !is.null(at)) stop("at is not used for primitive parameters.")
  v <- fit$model$input_vars
  probes <- .wsmed_probes(fit, if (type == "parameters") NULL else at,
                           parameters = type == "parameters")
  point <- fit$point$est
  draws <- if (is.null(inference)) matrix(numeric(), 0L, length(point),
    dimnames = list(NULL, names(point))) else .wsmed_full_draws(inference)
  ids <- inference$draw_ids %||% integer()
  diagnostics <- list(requested = length(ids), valid = length(ids),
                      invalid = 0L, invalid_draw_ids = integer())
  if (scale == "marginal") {
    lav <- fit$backend[[1]]
    roles <- .wsmed_roles(fit$data)
    if (type != "parameters") roles$dummy <- union(roles$dummy,
      attr(fit$data, "W_info")$dummy_names)
    lav@external$wsmed_roles <- roles
    point <- StdLav2(fit$coefficients, lav)
    names(point) <- fit$point$par_names
    if (nrow(draws)) {
      z <- .wsmed_std_draws(lav, draws[, names(fit$coefficients), drop = FALSE])
      draws <- z$draws; colnames(draws) <- names(point)
      diagnostics <- z$diagnostics
      diagnostics$invalid_draw_ids <- ids[z$diagnostics$invalid_indices]
      if (length(z$diagnostics$invalid_indices)) ids <- ids[-z$diagnostics$invalid_indices]
    }
  }
  theta <- rbind(point, draws)
  paths <- .cat_get_indirect_paths(colnames(theta))
  path_ids <- vapply(paths, `[[`, character(1), "path_name")
  available <- switch(type, indirect = path_ids, total = "total", direct = "cp",
    total_indirect = "total_indirect", parameters = names(fit$coefficients),
    paths = grep("^(a[0-9]+|[bd]([0-9]+|_[0-9]+_[0-9]+)|cp)$", colnames(theta), value = TRUE))
  if (is.null(terms)) terms <- available
  if (!is.character(terms) || !length(terms) || anyNA(terms) || anyDuplicated(terms) ||
      any(!terms %in% available)) stop("terms must name distinct effects in the selected family.")
  estimates <- tables <- vector("list", length(probes$values))
  for (i in seq_along(probes$values)) {
    value <- probes$values[[i]]
    slope <- function(base) {
      ans <- theta[, base]
      if (type == "parameters" || !length(v$W)) return(ans)
      if (v$W_type == "categorical")
        return(.cat_apply_mod(theta, fit$data, base, value, v$MP, v$W))
      label <- paste0(.cat_get_mod_prefix(base), "_W1")
      if (label %in% colnames(theta)) ans <- ans + theta[, label] * (value - probes$center)
      ans
    }
    effects <- if (type %in% c("parameters", "paths")) {
      stats::setNames(lapply(terms, slope), terms)
    } else {
      ies <- stats::setNames(lapply(paths, function(p)
        Reduce(`*`, lapply(p$coefs, slope))), path_ids)
      total_ie <- if (length(ies)) Reduce(`+`, ies) else rep(0, nrow(theta))
      c(ies, list(cp = slope("cp"), total_indirect = total_ie,
                  total = slope("cp") + total_ie))[terms]
    }
    estimates[[i]] <- do.call(cbind, effects)
    labels <- vapply(terms, function(term) {
      p <- match(term, path_ids)
      if (is.na(p)) return(term)
      ix <- as.integer(strsplit(paths[[p]]$mediators, " ", fixed = TRUE)[[1]])
      paste(fit$model$mediator_names[ix], collapse = " -> ")
    }, character(1))
    tables[[i]] <- data.frame(term = if (length(v$W) && type != "parameters")
        paste0(terms, "@", i) else terms,
      effect = terms, label = unname(labels),
      moderator = if (type == "parameters" || !length(v$W)) NA_character_ else v$W,
      at = if (type == "parameters" || !length(v$W)) NA_character_ else as.character(value),
      stringsAsFactors = FALSE)
  }
  evaluated <- do.call(cbind, estimates)
  table <- do.call(rbind, tables)
  colnames(evaluated) <- table$term
  .wsmed_result(table, evaluated[1, ], evaluated[-1, , drop = FALSE], ids,
    list(type = type, terms = terms, at = at, scale = scale,
      method = inference$method %||% "point", level = level, interval = "percentile",
      moderator_type = if (type == "parameters") NULL else v$W_type,
      reference = fit$reference, conditions = fit$model$conditions,
      interpretation = .wsmed_analysis_description(fit),
      reproducibility = .wsmed_repro_details(inference %||% fit),
      probe_reference = probes$center,
      inference_diagnostics = inference$diagnostics), diagnostics)
}

.wsmed_select <- function(object, method = NULL) {
  if (inherits(object, "wsMed")) {
    if (!inherits(object$fit, "wsmed_fit"))
      stop("This saved wsMed object predates the modular API; use its existing accessors.")
    methods <- names(object$inference)
    if (is.null(method) && length(methods) != 1L)
      stop("Choose method = 'mc' or 'bootstrap' explicitly.")
    if (is.null(method)) method <- methods[1]
    if (length(method) != 1L || !method %in% methods) stop("Requested inference is not stored.")
    object <- object$inference[[method]]
  }
  if (inherits(object, "wsmed_inference")) {
    if (!is.null(method) && !identical(method, object$method)) stop("Requested inference is not stored.")
    return(list(fit = object$fit, inference = object))
  }
  if (inherits(object, "wsmed_fit")) {
    if (!is.null(method)) stop("A fit contains no stored inference; call wsmed_infer().")
    return(list(fit = object, inference = NULL))
  }
  stop("Expected a wsmed_fit, wsmed_inference, or wsMed result.")
}

.wsmed_full_draws <- function(object) {
  point <- object$fit$point$est
  out <- matrix(rep(point, each = nrow(object$draws)), nrow = nrow(object$draws),
                dimnames = list(NULL, names(point)))
  nm <- colnames(object$draws)
  if (is.null(nm) || !all(nm %in% names(point))) stop("Stored parameter identities do not match the fit.")
  out[, nm] <- object$draws
  out
}

.wsmed_probes <- function(fit, at, parameters = FALSE) {
  v <- fit$model$input_vars
  if (parameters || !length(v$W)) {
    if (!is.null(at)) stop("at requires a moderator.")
    return(list(values = list(NA_real_), center = NULL))
  }
  if (!is.null(at) && (!is.list(at) || !identical(names(at), v$W)))
    stop("at must be a named list for moderator ", v$W, ".")
  raw <- fit$data[[v$W]]
  if (v$W_type == "continuous") {
    center <- mean(raw - fit$data$W1, na.rm = TRUE)
    values <- if (is.null(at)) center else at[[1]]
    if (!is.numeric(values) || !length(values) || any(!is.finite(values)) || anyDuplicated(values))
      stop("Moderator values must be distinct finite numbers in raw units.")
  } else {
    center <- NULL
    levels <- if (is.factor(raw)) levels(raw) else unique(as.character(raw[!is.na(raw)]))
    values <- if (is.null(at)) levels else as.character(at[[1]])
    if (!length(values) || anyNA(values) || anyDuplicated(values) || any(!values %in% levels))
      stop("Unknown or duplicate moderator levels.")
  }
  list(values = as.list(values), center = center)
}

.wsmed_result <- function(table, point, draws, ids, query, diagnostics) {
  rownames(draws) <- NULL
  table$estimate <- unname(point)
  table$std.error <- NA_real_
  table$conf.low <- NA_real_
  table$conf.high <- NA_real_
  if (nrow(draws)) {
    if (nrow(draws) < 2L || any(!is.finite(draws))) stop("At least two finite joint draws are required.")
    table$std.error <- apply(draws, 2, stats::sd)
    ci <- .wsmed_quantiles(draws, query$level)
    table$conf.low <- ci[, 1]; table$conf.high <- ci[, 2]
  }
  rownames(table) <- NULL
  table$effect_type <- query$type
  table$path <- if (query$type == "indirect") table$label else NA_character_
  table$conf.level <- if (nrow(draws)) query$level else NA_real_
  table$method <- query$method
  table$interval <- if (nrow(draws)) query$interval else NA_character_
  table$scale <- query$scale
  table$n.valid <- nrow(draws)
  table$status <- if (nrow(draws)) "inference" else "point_only"
  table$moderator.value <- if (identical(query$moderator_type, "continuous"))
    as.numeric(table$at) else NA_real_
  table$moderator.level <- if (identical(query$moderator_type, "categorical"))
    table$at else NA_character_
  structure(list(schema_version = 1L, table = table, point = stats::setNames(unname(point), table$term),
    draws = draws, draw_ids = ids, query = query, diagnostics = diagnostics), class = "wsmed_results")
}

.wsmed_quantiles <- function(draws, level) {
  .wsmed_level(level)
  if (!nrow(draws)) stop("No inference is stored; call wsmed_infer() first.")
  out <- t(vapply(seq_len(ncol(draws)), function(j) stats::quantile(draws[, j],
    c((1 - level) / 2, (1 + level) / 2), names = FALSE), numeric(2)))
  dimnames(out) <- list(colnames(draws), paste0(format(100 * c((1 - level) / 2,
    (1 + level) / 2), trim = TRUE), " %"))
  out
}

#' Contrast effects using their joint stored draws
#'
#' @param object A wsmed_results object, containing every effect to compare.
#' @param contrasts Named list of named numeric weight vectors. Weight names
#'   must match the term column of as.data.frame(object).
#' @param level Confidence level; defaults to the input result's level.
#' @return A wsmed_results object. Intervals are percentile intervals of the
#'   jointly evaluated contrasts, not differences between confidence limits.
#' @export
wsmed_contrasts <- function(object, contrasts, level = object$query$level) {
  if (!inherits(object, "wsmed_results")) stop("object must be wsmed_results.")
  .wsmed_level(level)
  if (!is.list(contrasts) || !length(contrasts) || is.null(names(contrasts)) ||
      anyNA(names(contrasts)) || any(!nzchar(names(contrasts))) || anyDuplicated(names(contrasts)))
    stop("contrasts must be a list with distinct nonempty names.")
  weights <- vapply(contrasts, function(w) {
    if (!is.numeric(w) || !length(w) || any(!is.finite(w)) || is.null(names(w)) ||
        anyDuplicated(names(w)) || any(!names(w) %in% names(object$point)))
      stop("Contrast weights must name existing terms.")
    out <- stats::setNames(numeric(length(object$point)), names(object$point))
    out[names(w)] <- w
    out
  }, numeric(length(object$point)))
  weights <- matrix(weights, nrow = length(object$point),
    dimnames = list(names(object$point), names(contrasts)))
  draws <- object$draws %*% weights
  query <- object$query; query$level <- level
  query$source_type <- query$source_type %||% query$type; query$type <- "contrasts"
  query$contrasts <- contrasts; query$source_terms <- object$table
  .wsmed_result(data.frame(term = names(contrasts), effect = names(contrasts),
    label = names(contrasts), moderator = NA_character_, at = NA_character_,
    contrast_definition = vapply(contrasts, function(w)
      paste(sprintf("%+.15g * %s", w, names(w)), collapse = " "), character(1))),
    as.vector(object$point %*% weights), draws, object$draw_ids, query, object$diagnostics)
}
