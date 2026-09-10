#' Forest plot of mediation effects
#'
#' Plot fitted indirect effects, the total indirect effect, the direct effect
#' (`cp`) and the total effect with their stored confidence intervals.
#' With a moderator these are effects at the model's reference value (centered
#' continuous W = 0, or the reference category), not averages across W.
#' Use [plot_conditional_effects()] to show selected moderator levels instead.
#'
#' @param result A result returned by [wsMed()].
#' @param paths Optional character vector of effect identifiers, in display
#'   order. NULL selects all available effects. Both `indirect_1` and
#'   `indirect_effect_1` are accepted when they identify an available effect.
#' @param standardized Use standardized results, requested when fitting with
#'   `standardized = TRUE`. No scaling is recomputed from interval endpoints.
#' @param engine For `ci_method = "both"`, select `"mc"` or `"boot"`.
#'   For a single engine its stored results are used.
#' @param labels Optional named character vector mapping effect identifiers
#'   to display labels. Partial mappings are allowed.
#' @param title Optional plot title.
#' @param x_label,y_label Optional axis labels.
#' @param base_size Base font size.
#' @return A ggplot object. Its `data` contains the plotted estimates and
#'   `CI.LL`/`CI.UL` limits. The `wsmed_plot` attribute records the selected
#'   engine, scale and confidence level. Use [ggplot2::ggsave()] to export it.
#' @details MC intervals come from the parameter draws (or the stored
#'   standardized parameter table). Bootstrap plots use the bootstrap limits,
#'   not the normal-theory limits that may also be present in the table.
#' @seealso [plot_conditional_effects()], [plot_contrasts()],
#'   [plot_moderation_curve()]
#' @md
#' @export
plot_effects <- function(result, paths = NULL, standardized = FALSE,
                         engine = c("mc", "boot"), labels = NULL,
                         title = NULL, x_label = NULL, y_label = NULL,
                         base_size = 12) {
  info <- .wsmed_plot_info(result, standardized, engine)
  tab <- .wsmed_plot_parameters(result, info)
  tab <- tab[grepl("^indirect_[0-9]+(_[0-9]+)*$", tab$Path) |
               tab$Path %in% c("cp", "total_indirect", "total_effect"), , drop = FALSE]
  tab <- .wsmed_plot_select(tab, paths)
  tab$PlotLabel <- .wsmed_plot_labels(tab$Path, labels)
  reference <- if (length(result$input_vars$W))
    "Effects at the model reference moderator value; not marginal averages." else NULL
  p <- .wsmed_forest(tab, "PlotLabel", info,
    title = if (is.null(title)) "Mediation effects" else title,
    x_label = x_label, y_label = y_label, base_size = base_size,
    caption = reference)
  .wsmed_plot_finish(p, info)
}

#' Plot conditional effects at moderator levels
#'
#' Draw point estimates and confidence intervals by categorical group or by
#' the stored low, mean and high levels of a continuous moderator. Each effect
#' is shown in its own panel. Categories are not joined by interpolating lines.
#'
#' @inheritParams plot_effects
#' @param type `"indirect"` for specific indirect effects, `"paths"` for
#'   available conditional path coefficients, or `"overall"` for total
#'   indirect and total effects.
#' @param levels Optional group/level labels to select, in display order.
#'   NULL uses their stored order. For continuous W the labels are `"-1 SD"`,
#'   `"0 SD"`, `"+1 SD"`; the axis also displays stored raw W probe values.
#' @param ncol Optional number of facet columns.
#' @return A ggplot object with plotted data and a `wsmed_plot` attribute.
#' @details Intervals are the stored percentile conditional intervals,
#'   including jointly transformed scales for standardized results. They are
#'   individual intervals, not simultaneous confidence intervals.
#' @seealso [plot_effects()], [plot_contrasts()]
#' @md
#' @export
plot_conditional_effects <- function(result, paths = NULL,
                                     type = c("indirect", "paths", "overall"),
                                     levels = NULL, standardized = FALSE,
                                     engine = c("mc", "boot"), labels = NULL,
                                     title = NULL, x_label = NULL, y_label = NULL,
                                     base_size = 12, ncol = NULL) {
  info <- .wsmed_plot_info(result, standardized, engine)
  mod <- .wsmed_plot_mod(result, info)
  type <- match.arg(type)
  tab <- .wsmed_plot_conditional_table(mod, type, contrast = FALSE)
  tab <- .wsmed_plot_select(tab, paths)
  key <- if (identical(mod$type, "categorical")) "Group" else "Level"
  if (!is.null(levels)) tab <- .wsmed_plot_select_values(tab, key, levels)
  .wsmed_plot_check_intervals(tab)
  tab$PlotLabel <- .wsmed_plot_labels(tab$Path, labels, reverse = FALSE)
  values <- unique(as.character(tab[[key]]))
  tab$LevelLabel <- factor(as.character(tab[[key]]), levels = values)
  axis_labels <- values
  if (key == "Level") {
    probes <- tab$W_value[match(values, tab$Level)]
    axis_labels <- paste0(values, "\nW = ", format(probes, trim = TRUE))
  }
  p <- ggplot2::ggplot(tab, ggplot2::aes(x = .data$LevelLabel, y = .data$Estimate)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$CI.LL, ymax = .data$CI.UL),
                          width = .12, colour = "#35618D") +
    ggplot2::geom_point(size = 2.5, colour = "#234866") +
    ggplot2::facet_wrap(ggplot2::vars(.data$PlotLabel), ncol = ncol) +
    ggplot2::scale_x_discrete(labels = stats::setNames(axis_labels, values)) +
    ggplot2::labs(title = if (is.null(title)) "Conditional effects" else title,
      x = if (is.null(x_label)) if (key == "Group") "Moderator group" else "Moderator (raw units)" else x_label,
      y = if (is.null(y_label)) .wsmed_plot_scale(info) else y_label,
      subtitle = .wsmed_plot_ci_label(info, conditional = TRUE),
      caption = "Individual intervals; differences require a contrast interval.") +
    ggplot2::theme_minimal(base_size = base_size)
  .wsmed_plot_finish(p, info)
}

#' Plot differences between mediation effects
#'
#' Draw contrast estimates and their confidence intervals relative to zero.
#' With a moderator, contrasts compare groups or stored moderator levels
#' within each effect. Without a moderator, specific indirect paths are
#' compared with one another. The displayed subtraction order is explicit.
#'
#' @inheritParams plot_effects
#' @inheritParams plot_conditional_effects
#' @param contrasts Optional exact contrast labels to select, in display order.
#'   NULL selects all. Inspect the corresponding result table or the returned
#'   plot's `data$Contrast` for available labels.
#' @return A ggplot object with plotted data and a `wsmed_plot` attribute.
#' @details Moderator contrasts use the existing joint-draw contrast tables.
#'   Without a moderator, only `type = "indirect"` is available: contrasts
#'   are computed from the stored joint draws, with point estimates evaluated
#'   at fitted/pooled parameters. Their intervals are percentile intervals.
#'   Standardized draws use the same draw-specific marginal endpoint scales
#'   as other standardized effects. No model is refitted. Interval endpoints
#'   for two separate effects are never subtracted to construct a contrast CI.
#'   `paths` and `labels` apply to effect panels when a moderator is present;
#'   without a moderator, `paths` selects the indirect effects to compare and
#'   `labels` maps the full contrast labels. Continuous overall contrasts are
#'   unavailable when the fitted result does not contain that contrast table.
#' @seealso [plot_effects()], [plot_conditional_effects()]
#' @md
#' @export
plot_contrasts <- function(result, paths = NULL,
                           type = c("indirect", "paths", "overall"),
                           contrasts = NULL, standardized = FALSE,
                           engine = c("mc", "boot"), labels = NULL,
                           title = NULL, x_label = NULL, y_label = NULL,
                           base_size = 12, ncol = NULL) {
  info <- .wsmed_plot_info(result, standardized, engine)
  type <- match.arg(type)
  moderated <- length(result$input_vars$W) > 0L
  if (moderated) {
    mod <- .wsmed_plot_mod(result, info)
    tab <- .wsmed_plot_conditional_table(mod, type, contrast = TRUE)
    tab <- .wsmed_plot_select(tab, paths)
    tab$PlotLabel <- .wsmed_plot_labels(tab$Path, labels, reverse = FALSE)
  } else {
    if (type != "indirect") stop("Without a moderator use type = 'indirect'.", call. = FALSE)
    tab <- .wsmed_plot_basic_contrasts(result, info, paths)
    tab$PlotLabel <- .wsmed_plot_labels(tab$Contrast, labels)
  }
  if (!is.null(contrasts)) tab <- .wsmed_plot_select_values(tab, "Contrast", contrasts)
  tab$ContrastLabel <- if (moderated) factor(tab$Contrast, levels = rev(unique(tab$Contrast))) else tab$PlotLabel
  p <- .wsmed_forest(tab, "ContrastLabel", info,
    title = if (is.null(title)) "Effect contrasts" else title,
    x_label = if (is.null(x_label)) paste(.wsmed_plot_scale(info), "difference") else x_label,
    y_label = y_label, base_size = base_size,
    caption = "Contrast = first term minus second term. Intervals use joint draws.",
    conditional = TRUE)
  if (moderated) p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$PlotLabel), ncol = ncol)
  .wsmed_plot_finish(p, info)
}

# Helpers deliberately keep estimation separate from presentation.
.wsmed_plot_info <- function(result, standardized, engine) {
  if (!inherits(result, "wsMed")) stop("result must be a wsMed object.", call. = FALSE)
  if (!is.logical(standardized) || length(standardized) != 1L || is.na(standardized))
    stop("standardized must be TRUE or FALSE.", call. = FALSE)
  alpha <- result$alpha
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1)
    stop("Plotting requires a single alpha in (0, 1).", call. = FALSE)
  method <- result$ci_method
  if (!method %in% c("mc", "bootstrap", "both")) stop("Unknown inference engine.", call. = FALSE)
  engine <- if (method == "both") match.arg(engine, c("mc", "boot")) else if (method == "bootstrap") "boot" else "mc"
  list(engine = engine, standardized = standardized, level = 1 - alpha)
}

.wsmed_plot_mod <- function(result, info) {
  if (!length(result$input_vars$W)) stop("This plot requires a moderator.", call. = FALSE)
  mod <- if (info$standardized) result$moderation_std else result$moderation
  if (identical(result$ci_method, "both")) mod <- mod[[info$engine]]
  if (is.null(mod)) stop(if (info$standardized)
    "Standardized conditional results are unavailable; request standardized = TRUE in wsMed(), or use standardize_moderation()."
    else "Conditional results are unavailable.", call. = FALSE)
  mod
}

.wsmed_plot_scale <- function(info) if (info$standardized) "Standardized effect" else "Effect"
.wsmed_plot_ci_label <- function(info, conditional = FALSE) {
  paste0(format(100 * info$level, trim = TRUE), "% ",
    if (conditional) "percentile " else "", "confidence intervals; ",
    if (info$engine == "mc") "Monte Carlo" else "bootstrap")
}
.wsmed_plot_finish <- function(p, info) {
  attr(p, "wsmed_plot") <- info
  p
}

.wsmed_plot_intervals <- function(tab) {
  if (is.null(tab) || !nrow(tab)) stop("Requested results are unavailable.", call. = FALSE)
  # Bootstrap tables may also contain normal-theory limits: prefer boot.*.
  pairs <- list(c("boot.ci.lower", "boot.ci.upper"), c("CI.LL", "CI.UL"),
                c("ci.lower", "ci.upper"))
  pair <- NULL
  for (candidate in pairs) if (all(candidate %in% names(tab))) { pair <- candidate; break }
  if (is.null(pair)) {
    lo <- grep("CI[.]Lo$", names(tab), value = TRUE)
    hi <- grep("CI[.]Up$", names(tab), value = TRUE)
    if (length(lo) == 1L && length(hi) == 1L) pair <- c(lo, hi)
  }
  if (is.null(pair)) {
    pct <- grep("^[0-9.]+%$", names(tab), value = TRUE)
    if (length(pct) == 2L) pair <- pct[order(as.numeric(sub("%", "", pct)))]
  }
  if (length(pair) != 2L) stop("Cannot identify a unique confidence interval.", call. = FALSE)
  tab$CI.LL <- tab[[pair[1]]]; tab$CI.UL <- tab[[pair[2]]]
  tab
}

.wsmed_plot_check_intervals <- function(tab) {
  if (!nrow(tab)) stop("No effects selected.", call. = FALSE)
  if (any(!is.finite(tab$Estimate)) || any(!is.finite(tab$CI.LL)) || any(!is.finite(tab$CI.UL)))
    stop("Selected estimates or confidence limits are unavailable/non-finite.", call. = FALSE)
  if (any(tab$CI.LL > tab$CI.UL)) stop("Confidence limits are reversed.", call. = FALSE)
}

.wsmed_plot_parameters <- function(result, info) {
  if (info$standardized) {
    tab <- if (info$engine == "mc") result$mc$std_mc else result$mc$std_boot
    if (is.null(tab)) stop("Standardized parameter results are unavailable; request standardized = TRUE in wsMed().", call. = FALSE)
  } else if (info$engine == "mc") {
    if (is.null(result$mc$result)) stop("Monte Carlo results are unavailable.", call. = FALSE)
    tab <- .mc_param_table(result$mc$result, 1 - info$level)
  } else tab <- result$param_boot
  tab <- .wsmed_plot_intervals(as.data.frame(tab))
  if (info$engine == "boot") {
    tab$Path <- ifelse(tab$op == ":=", tab$lhs, tab$label)
    tab$Estimate <- if (info$standardized) tab$est.std else tab$est
  } else tab$Path <- if (info$standardized) tab$Parameter else tab$name
  tab
}

.wsmed_plot_alias <- function(values, available) {
  alternate <- ifelse(grepl("^indirect_effect_", values),
    sub("^indirect_effect_", "indirect_", values), sub("^indirect_", "indirect_effect_", values))
  values[!values %in% available & alternate %in% available] <- alternate[!values %in% available & alternate %in% available]
  values
}
.wsmed_plot_select_values <- function(tab, key, values) {
  if (!is.character(values) || !length(values) || anyNA(values) || anyDuplicated(values))
    stop(key, " selection must contain distinct character labels.", call. = FALSE)
  available <- unique(as.character(tab[[key]]))
  if (any(!values %in% available)) stop("Unknown ", key, ": ",
    paste(setdiff(values, available), collapse = ", "), ". Available: ",
    paste(available, collapse = ", "), call. = FALSE)
  tab[order(match(tab[[key]], values), na.last = NA), , drop = FALSE]
}
.wsmed_plot_select <- function(tab, paths) {
  if (!is.null(paths)) {
    if (!is.character(paths)) stop("paths must be a character vector.", call. = FALSE)
    tab <- .wsmed_plot_select_values(tab, "Path", .wsmed_plot_alias(paths, tab$Path))
  }
  if (!nrow(tab)) stop("No effects available for this plot.", call. = FALSE)
  tab
}
.wsmed_plot_labels <- function(values, labels, reverse = TRUE) {
  display <- as.character(values)
  if (!is.null(labels)) {
    if (!is.character(labels) || is.null(names(labels)) || anyNA(labels) ||
        anyNA(names(labels)) || any(!nzchar(names(labels))) || anyDuplicated(names(labels)))
      stop("labels must be a named character vector with unique names.", call. = FALSE)
    keys <- .wsmed_plot_alias(names(labels), values)
    if (any(!keys %in% values) || anyDuplicated(keys)) stop("Unknown or duplicate effect names in labels.", call. = FALSE)
    idx <- match(values, keys)
    display[!is.na(idx)] <- labels[idx[!is.na(idx)]]
  }
  # Duplicate labels would silently merge distinct effects in a facet or axis.
  if (anyDuplicated(display[!duplicated(values)])) stop("Display labels must distinguish effects.", call. = FALSE)
  factor(display, levels = if (reverse) rev(unique(display)) else unique(display))
}

.wsmed_plot_conditional_table <- function(mod, type, contrast) {
  categorical <- identical(mod$type, "categorical")
  if (contrast) tab <- switch(type, indirect = mod$IE_contrasts,
    paths = if (categorical) mod$extra$path_contrasts else mod$path_contrasts,
    overall = mod$overall_contrasts)
  else tab <- switch(type,
    indirect = if (categorical) mod$conditional_IE else mod$beta_coef,
    paths = if (categorical) mod$extra$path_levels else mod$path_HML,
    overall = mod$conditional_overall)
  if (is.null(tab) || !nrow(tab)) stop("Requested ", type,
    if (contrast) " contrasts" else " conditional effects", " are unavailable in this result.", call. = FALSE)
  tab <- .wsmed_plot_intervals(tab)
  if ("IE" %in% names(tab)) tab$Path <- tab$IE
  if ("Effect" %in% names(tab)) tab$Path <- tab$Effect
  tab
}

.wsmed_forest <- function(tab, axis, info, title, x_label, y_label,
                          base_size, caption = NULL, conditional = FALSE) {
  .wsmed_plot_check_intervals(tab)
  ggplot2::ggplot(tab, ggplot2::aes(x = .data$Estimate, y = .data[[axis]])) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
    ggplot2::geom_segment(ggplot2::aes(x = .data$CI.LL, xend = .data$CI.UL,
                                     yend = .data[[axis]]), colour = "#35618D", linewidth = .7) +
    ggplot2::geom_point(size = 2.5, colour = "#234866") +
    ggplot2::labs(title = title,
      x = if (is.null(x_label)) .wsmed_plot_scale(info) else x_label,
      y = if (is.null(y_label)) NULL else y_label,
      subtitle = .wsmed_plot_ci_label(info, conditional), caption = caption) +
    ggplot2::theme_minimal(base_size = base_size)
}

.wsmed_plot_basic_contrasts <- function(result, info, paths) {
  # Require the requested scale to exist, consistent with the other plots.
  tab <- .wsmed_plot_parameters(result, info)
  tab <- tab[grepl("^indirect_[0-9]+(_[0-9]+)*$", tab$Path), , drop = FALSE]
  tab <- .wsmed_plot_select(tab, paths)
  if (nrow(tab) < 2L) stop("At least two indirect effects are required for a contrast.", call. = FALSE)
  if (info$engine == "mc") {
    fit <- result$mc$result$args$lav
    draws <- result$mc$result$thetahatstar
    point <- result$mc$result$thetahat$est
  } else {
    fit <- result$fit_u
    if (is.null(fit)) stop("Stored bootstrap fit is unavailable.", call. = FALSE)
    draws <- if (info$standardized) fit@external$sbt_boot_ustd else result$mc$theta_boot
    point <- ThetaHatWrapper(fit)$est
  }
  if (is.null(draws)) stop("Stored joint draws are unavailable.", call. = FALSE)
  diagnostics <- NULL
  if (info$standardized) {
    z <- .wsmed_std_draws(fit, draws)
    draws <- z$draws; diagnostics <- z$diagnostics
    point <- StdLav2(point, fit)
    colnames(draws) <- names(point) <- ThetaHatWrapper(fit)$par_names
  }
  ids <- tab$Path
  if (!all(ids %in% colnames(draws)) || !all(ids %in% names(point)))
    stop("Stored draws do not contain the selected indirect effects.", call. = FALSE)
  valid <- apply(draws[, ids, drop = FALSE], 1, function(x) all(is.finite(x)))
  if (any(!valid)) warning(sum(!valid), " non-finite joint draws excluded from contrasts.", call. = FALSE)
  draws <- draws[valid, , drop = FALSE]
  if (nrow(draws) < 2L) stop("At least two valid joint draws are required.", call. = FALSE)
  out <- do.call(rbind, lapply(utils::combn(ids, 2, simplify = FALSE), function(pair) {
    v <- draws[, pair[2]] - draws[, pair[1]]
    ci <- stats::quantile(v, c((1 - info$level)/2, (1 + info$level)/2), names = FALSE)
    data.frame(Contrast = paste(pair[2], "-", pair[1]),
      Estimate = unname(point[pair[2]] - point[pair[1]]),
      SE = stats::sd(v), CI.LL = ci[1], CI.UL = ci[2])
  }))
  attr(out, "standardization") <- diagnostics
  out
}
