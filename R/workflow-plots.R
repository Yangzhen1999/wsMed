#' Plot mediation effects from workflow objects
#'
#' Plot stored effects without fitting, imputing, or drawing new samples.
#' The returned ggplot contains the full-precision plotted table in `data`.
#'
#' @param x A wsMed, wsmed_fit, wsmed_inference, or wsmed_results object.
#' @param type Effect family passed to [wsmed_effects()].
#' @param terms Effect identifiers to select, in display order. For a results
#'   object, use either effect identifiers or complete row identifiers.
#' @param at Named list of raw moderator values or factor labels.
#' @param scale,method Passed to [wsmed_effects()]. Select method explicitly
#'   when a one-call object contains both Monte Carlo and bootstrap inference.
#' @param level Confidence level. NULL retains the stored level. For an extracted
#'   results object, intervals can be recalculated from its stored effect draws.
#' @param view One of auto, forest, curve, or conditional. Auto uses a curve for
#'   a continuous moderator, separate category points for a categorical moderator,
#'   and a forest plot for unmoderated effects, single probes, and contrasts.
#' @param n Number of equally spaced probes for an automatic continuous curve
#'   (default 51). The range is the finite moderator range among cases used by
#'   the first fitted dataset. In MI this is the first completed dataset.
#' @param labels Named character vector mapping effect identifiers to labels.
#'   Labels must distinguish effects. Defaults use mediator role names.
#' @param title,x_label,y_label Optional title and axis labels.
#' @param ncol Number of facet columns, or NULL.
#' @param base_size Positive base font size.
#' @param rug Add observed raw moderator values along a continuous curve's
#'   horizontal axis. Available for fitted/inference/one-call objects only.
#'   Uses fitted cases with an observed moderator; imputed values are excluded.
#' @param ... Additional arguments are rejected to catch misspellings.
#' @return A ggplot. Its `wsmed_plot` attribute records the method, scale,
#'   confidence level, interval convention, view, and automatic-grid range.
#' @details Curves connect finite probes; bands are pointwise percentile
#' intervals, not simultaneous bands or Johnson--Neyman regions. Supplied probes
#' remain in raw units. A continuous conditional point plot requires explicit
#' `at` values. Forest plots without `at` use the usual reference value.
#' Category and effect selections retain their supplied order. A fitted object
#' without inference produces point estimates only, with no confidence band.
#'
#' Extracted results contain only their selected effects and probes: plotting
#' them never invents a new grid. Use [wsmed_effects()] again to change the scale,
#' method, or probes. [wsmed_contrasts()] constructs differences from joint draws.
#' Marginal standardization uses the same draw-specific scales as effect
#' extraction; it does not standardize a plotted table after computing intervals.
#'
#' The older [plot_effects()], [plot_conditional_effects()], [plot_contrasts()],
#' and [plot_moderation_curve()] calls remain available. For wsMed objects those
#' helpers preserve the stored legacy tables, including requested bootstrap
#' interval types. The plot methods here use the percentile convention of
#' [wsmed_effects()]. Plots explicitly identify their interval source.
#' @name wsmed_plots
#' @seealso [wsmed_effects()], [wsmed_contrasts()], [wsmed_methods]
#' @examples
#' data(example_data)
#' model <- wsmed_model(c(before = "D1", after = "D2"),
#'   list(A = c(before = "A1", after = "A2")),
#'   moderator = list(variable = "D3", interactions = "A -> Y"))
#' fit <- wsmed_fit(model, example_data)
#' plot(fit, n = 21, title = "Conditional point estimates")
#' @rdname wsmed_plots
#' @export
plot.wsMed <- function(x, type = "indirect", terms = NULL, at = NULL,
                       scale = "raw", method = NULL, level = NULL,
                       view = c("auto", "forest", "curve", "conditional"), n = 51L,
                       labels = NULL, title = NULL, x_label = NULL, y_label = NULL,
                       ncol = NULL, base_size = 12, rug = FALSE, ...) {
  .wsmed_unused_dots(...)
  view <- match.arg(view)
  if (!is.logical(rug) || length(rug) != 1L || is.na(rug)) stop("rug must be TRUE or FALSE.")
  type <- match.arg(type, c("indirect", "total", "direct", "total_indirect", "paths", "parameters"))
  assert_scalar_int(n, "n", lower = 2L)
  selected <- .wsmed_select(x, method)
  fit <- selected$fit
  v <- fit$model$input_vars
  grid <- NULL
  if (type != "parameters" && length(v$W) && v$W_type == "continuous" && is.null(at)) {
    if (view == "conditional") stop("Supply at for a continuous conditional point plot.", call. = FALSE)
    if (view %in% c("auto", "curve")) {
      assert_scalar_int(n, "n", lower = 2L)
      raw <- fit$data[[v$W]][fit$diagnostics$case_indices[[1]]]
      raw <- raw[is.finite(raw)]
      if (length(unique(raw)) < 2L) stop("A curve requires at least two distinct moderator values.", call. = FALSE)
      grid <- range(raw)
      at <- stats::setNames(list(seq(grid[1], grid[2], length.out = n)), v$W)
    }
  }
  result <- wsmed_effects(x, type = type, terms = terms, at = at,
                          scale = scale, method = method, level = level)
  p <- plot(result, view = view, labels = labels, title = title,
    x_label = x_label, y_label = y_label, ncol = ncol, base_size = base_size)
  attr(p, "wsmed_plot")$grid_range <- grid
  if (!is.null(grid)) p <- p + ggplot2::labs(caption = paste0(p$labels$caption,
    "\nAutomatic grid: ", format(grid[1], digits = 5), " to ", format(grid[2], digits = 5),
    " in raw ", v$W, " units; ", n, " probes",
    if (fit$Na == "MI") " (first imputation)." else " (fitted cases)."))
  if (rug) {
    if (attr(p, "wsmed_plot")$view != "curve") stop("rug requires a continuous curve.")
    observed <- fit$raw_data[[v$W]][fit$diagnostics$case_indices[[1]]]
    observed <- observed[is.finite(observed)]
    p <- p + ggplot2::geom_rug(data = data.frame(.probe = observed),
      mapping = ggplot2::aes(x = .data$.probe), inherit.aes = FALSE, sides = "b", alpha = .2) +
      ggplot2::labs(caption = paste0(p$labels$caption, "\nRug: ", length(observed),
        " observed moderator values among fitted cases; imputed values excluded."))
    attr(p, "wsmed_plot")$rug_n <- length(observed)
  }
  p
}

#' @rdname wsmed_plots
#' @export
plot.wsmed_inference <- plot.wsMed

#' @rdname wsmed_plots
#' @export
plot.wsmed_fit <- plot.wsMed

#' @rdname wsmed_plots
#' @export
plot.wsmed_results <- function(x, view = c("auto", "forest", "curve", "conditional"),
                               terms = NULL, level = NULL, labels = NULL,
                               title = NULL, x_label = NULL, y_label = NULL,
                               ncol = NULL, base_size = 12, ...) {
  .wsmed_unused_dots(...)
  view <- match.arg(view)
  if (!is.null(level)) x <- summary(x, level = level)
  d <- x$table
  if (!is.null(terms)) {
    if (!is.character(terms) || !length(terms) || anyNA(terms) || anyDuplicated(terms))
      stop("terms must contain distinct character identifiers.", call. = FALSE)
    key <- if (all(terms %in% d$effect)) "effect" else "term"
    d <- .wsmed_plot_select_values(d, key, terms)
  }
  if (!nrow(d)) stop("No effects available for this plot.", call. = FALSE)
  conditional <- !all(is.na(d$at)) && x$query$type != "contrasts"
  continuous <- conditional && identical(x$query$moderator_type, "continuous")
  enough_probes <- continuous && all(vapply(split(d$at, d$effect),
    function(z) length(unique(z)) >= 2L, logical(1)))
  if (view == "auto") view <- if (enough_probes) "curve" else
    if (conditional && !continuous) "conditional" else "forest"
  if (view == "curve" && !enough_probes)
    stop("A curve requires a continuous moderator and at least two probes per effect.", call. = FALSE)
  if (view == "conditional" && !conditional)
    stop("A conditional plot requires moderator probes; contrasts use forest plots.", call. = FALSE)
  defaults <- stats::setNames(d$label[!duplicated(d$effect)], unique(d$effect))
  if (!is.null(labels)) {
    .wsmed_plot_labels(d$effect, labels)
    keys <- .wsmed_plot_alias(names(labels), names(defaults))
    defaults[keys] <- labels
  }
  d$.effect_label <- .wsmed_plot_labels(d$effect, defaults, reverse = FALSE)
  display <- if (conditional) paste0(d$.effect_label, " [", d$at, "]") else as.character(d$.effect_label)
  if (anyDuplicated(display)) stop("Display labels must distinguish result rows.", call. = FALSE)
  d$.row_label <- factor(display, levels = rev(unique(display)))
  d$.level_label <- factor(d$at, levels = unique(d$at))
  d$.probe <- if (continuous) as.numeric(d$at) else NA_real_
  has_ci <- nrow(x$draws) > 0L
  .wsmed_plot_validate_table(d, has_ci)
  method <- switch(x$query$method, mc = "Monte Carlo", bootstrap = "Bootstrap",
                    point = "Point estimates", x$query$method)
  scale_label <- if (x$query$scale == "marginal") "Marginally standardized effect" else "Effect (raw units)"
  subtitle <- if (has_ci) paste0(100 * x$query$level, "% pointwise percentile intervals; ",
    method, "; ", if (x$query$scale == "marginal") "marginal scale" else "raw scale") else
    paste0("Point estimates only; no confidence intervals; ", x$query$scale, " scale")
  caption <- if (has_ci) "Pointwise intervals; differences require a contrast interval." else NULL
  if (x$query$type == "contrasts") {
    caption <- if (has_ci) "Contrasts use matched joint draws, not differences of interval endpoints." else
      "Point-estimate contrasts; inference has not been computed."
    scale_label <- paste(scale_label, "difference")
  }
  if (x$diagnostics$invalid > 0L) caption <- paste0(caption, "\n",
    x$diagnostics$invalid, " invalid draws excluded jointly; ", x$diagnostics$valid, " valid draws.")
  p <- .wsmed_render_effect_plot(d, view, has_ci, title, subtitle, caption,
    x_label %||% if (view == "forest") scale_label else unique(d$moderator),
    y_label %||% if (view == "forest") NULL else scale_label, ncol, base_size)
  attr(p, "wsmed_plot") <- list(method = x$query$method, scale = x$query$scale,
    level = if (has_ci) x$query$level else NULL, interval = if (has_ci) "percentile" else NULL,
    view = view, grid_range = NULL, draw_ids = x$draw_ids, diagnostics = x$diagnostics)
  p
}

.wsmed_unused_dots <- function(...) {
  dots <- list(...)
  if (length(dots)) stop("Unused argument(s): ",
    paste(if (is.null(names(dots))) rep("<unnamed>", length(dots)) else
      ifelse(nzchar(names(dots)), names(dots), "<unnamed>"), collapse = ", "), call. = FALSE)
}

.wsmed_plot_validate_table <- function(d, has_ci) {
  if (!all(is.finite(d$estimate))) stop("Plot estimates must be finite.", call. = FALSE)
  if (has_ci && (any(!is.finite(d$conf.low)) || any(!is.finite(d$conf.high)) ||
                 any(d$conf.low > d$conf.high)))
    stop("Plot confidence limits must be finite and ordered.", call. = FALSE)
}

# Both legacy-table adapters and modular methods use this renderer.
.wsmed_render_effect_plot <- function(d, view, has_ci, title, subtitle, caption,
                                      x_label, y_label, ncol, base_size,
                                      x_tick_labels = ggplot2::waiver()) {
  for (label in list(title, x_label, y_label)) if (!is.null(label) &&
    (!is.character(label) || length(label) != 1L || is.na(label)))
      stop("Titles and axis labels must be single character strings or NULL.", call. = FALSE)
  if (!is.numeric(base_size) || length(base_size) != 1L || !is.finite(base_size) || base_size <= 0)
    stop("base_size must be a positive finite number.", call. = FALSE)
  assert_scalar_int(ncol, "ncol", lower = 1L, allow_null = TRUE)
  if (view == "forest") {
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$estimate, y = .data$.row_label)) +
      ggplot2::geom_vline(xintercept = 0, linetype = 2, colour = "grey60")
    if (has_ci) p <- p + ggplot2::geom_segment(ggplot2::aes(x = .data$conf.low,
      xend = .data$conf.high, yend = .data$.row_label), linewidth = .7, colour = "#35618D")
    p <- p + ggplot2::geom_point(size = 2.5, colour = "#234866")
  } else if (view == "conditional") {
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$.level_label, y = .data$estimate)) +
      ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey60")
    if (has_ci) p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$conf.low,
      ymax = .data$conf.high), width = .12, colour = "#35618D")
    p <- p + ggplot2::geom_point(size = 2.5, colour = "#234866") +
      ggplot2::scale_x_discrete(labels = x_tick_labels) +
      ggplot2::facet_wrap(ggplot2::vars(.data$.effect_label), ncol = ncol)
  } else {
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$.probe, y = .data$estimate)) +
      ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey60")
    if (has_ci) p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$conf.low,
      ymax = .data$conf.high), alpha = .15, fill = "#35618D")
    p <- p + ggplot2::geom_line(colour = "#234866") +
      ggplot2::geom_point(size = 1, colour = "#234866") +
      ggplot2::facet_wrap(ggplot2::vars(.data$.effect_label), ncol = ncol)
  }
  p + ggplot2::labs(title = title, subtitle = subtitle, caption = caption,
                     x = x_label, y = y_label) + ggplot2::theme_minimal(base_size = base_size)
}

# Preserve legacy values and interval endpoints while adding common columns.
.wsmed_legacy_plot_frame <- function(tab, labels, levels = NULL, validate_ci = TRUE) {
  tab$estimate <- tab$Estimate; tab$conf.low <- tab$CI.LL; tab$conf.high <- tab$CI.UL
  tab$.effect_label <- labels
  tab$.row_label <- if (is.factor(labels)) labels else factor(labels, levels = rev(unique(labels)))
  if (!is.null(levels)) tab$.level_label <- levels
  .wsmed_plot_validate_table(tab, validate_ci)
  tab
}
