#' Plot conditional effects across a continuous moderator
#'
#' Plot a conditional indirect effect, total effect or path coefficient with
#' its pointwise confidence band. Highlight stored grid values whose interval
#' excludes zero. Boundary labels use raw moderator units, not sample percentiles.
#'
#' @details Highlighted intervals are approximate ranges on the stored grid,
#'   not exact Johnson--Neyman boundaries or simultaneous confidence regions.
#'   A label `[a, b]` reports the first and last qualifying grid values. An
#'   isolated qualifying point is marked by a vertical line. Missing confidence
#'   limits break a highlighted range. The displayed confidence level follows
#'   `result$alpha`; no fixed p-value threshold is implied.
#' @param result A result returned by [wsMed()] with a continuous moderator.
#' @param path_name One stored effect identifier, such as
#'   `"indirect_effect_1_2"`, `"total_indirect"` or `"b_1_2"`.
#'   `"indirect_1_2"` is also accepted as an alias.
#' @param title Optional plot title.
#' @param x_label,y_label Axis labels. The default x axis uses raw W units.
#' @param ns_fill Colour of the complete confidence band.
#' @param sig_fill Colour of the regions whose pointwise CI excludes zero.
#' @param alpha_ci,alpha_sig Opacity of the band and highlighted regions.
#' @param base_size Base font size.
#' @param standardized Use the stored standardized conditional results.
#' @param engine For `ci_method = "both"`, select `"mc"` or `"boot"`.
#' @return A ggplot object. Its `data` contains the selected curve;
#'   the `wsmed_regions` attribute contains raw-unit grid interval endpoints.
#'   The `wsmed_plot` attribute records engine, scale and confidence level.
#' @seealso [plot_effects()], [plot_conditional_effects()], [plot_contrasts()]
#' @md
#' @importFrom dplyr arrange bind_rows filter mutate tibble
#' @importFrom ggplot2 aes element_rect element_text geom_hline geom_line
#' @importFrom ggplot2 geom_rect geom_ribbon geom_text geom_vline ggplot labs
#' @importFrom ggplot2 scale_fill_manual theme theme_minimal
#' @export
plot_moderation_curve <- function(result, path_name,
                                  title = NULL,
                                  x_label = "Moderator (W, raw units)",
                                  y_label = "Estimate",
                                  ns_fill = "#FEE0D2", sig_fill = "#C7E9C0",
                                  alpha_ci = 0.35, alpha_sig = 0.35,
                                  base_size = 14, standardized = FALSE,
                                  engine = c("mc", "boot")) {
  info <- .wsmed_plot_info(result, standardized, engine)
  mod <- .wsmed_plot_mod(result, info)
  if (!identical(mod$type, "continuous"))
    stop("A curve requires a continuous moderator; use plot_conditional_effects() for groups.", call. = FALSE)
  if (!is.character(path_name) || length(path_name) != 1L || is.na(path_name))
    stop("path_name must be one effect identifier.", call. = FALSE)
  available <- unique(c(mod$theta_curve$Path, mod$path_curve$Path))
  path_name <- .wsmed_plot_alias(path_name, available)
  if (!path_name %in% available) stop("Path '", path_name,
    "' not found. Available: ", paste(available, collapse = ", "), call. = FALSE)
  tab <- if (path_name %in% mod$theta_curve$Path) mod$theta_curve else mod$path_curve
  tab <- tab[tab$Path == path_name, , drop = FALSE]
  tab <- tab[order(tab$W_raw), , drop = FALSE]
  if (!nrow(tab) || any(!is.finite(tab$W_raw)) || any(!is.finite(tab$Estimate)))
    stop("Curve values must be finite.", call. = FALSE)
  if (any(tab$CI.LL > tab$CI.UL, na.rm = TRUE)) stop("Confidence limits are reversed.", call. = FALSE)
  valid_ci <- is.finite(tab$CI.LL) & is.finite(tab$CI.UL)
  if (any(!valid_ci)) {
    warning("Missing curve intervals are shown as gaps and break highlighted ranges.", call. = FALSE)
    tab$CI.LL[!valid_ci] <- tab$CI.UL[!valid_ci] <- NA_real_
  }
  tab$Sig <- valid_ci & ((tab$CI.LL > 0 & tab$CI.UL > 0) |
                          (tab$CI.LL < 0 & tab$CI.UL < 0))
  # Opposite signs at adjacent grid points must not bridge an unobserved
  # zero crossing, even though both individual intervals exclude zero.
  state <- ifelse(tab$Sig, ifelse(tab$CI.LL > 0, 1L, -1L), 0L)
  runs <- rle(state)
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1L
  chosen <- which(runs$values != 0L)
  regions <- data.frame(xmin = tab$W_raw[starts[chosen]],
                        xmax = tab$W_raw[ends[chosen]])
  regions$label_x <- (regions$xmin + regions$xmax)/2
  regions$label <- if (nrow(regions)) paste0("W in [",
    format(signif(regions$xmin, 4), trim = TRUE), ", ",
    format(signif(regions$xmax, 4), trim = TRUE), "]") else character()
  if (standardized && missing(y_label)) y_label <- "Standardized effect"
  band_label <- paste0(format(100 * info$level, trim = TRUE), "% pointwise CI")
  region_label <- "Pointwise CI excludes 0"
  p <- ggplot2::ggplot(tab, ggplot2::aes(x = .data$W_raw, y = .data$Estimate)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$CI.LL, ymax = .data$CI.UL,
                                   fill = "band"), alpha = alpha_ci, na.rm = TRUE) +
    ggplot2::geom_line(linewidth = .6, colour = "indianred4") +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45")
  if (nrow(regions)) p <- p +
    ggplot2::geom_rect(data = regions,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = -Inf, ymax = Inf,
                   fill = "region"), inherit.aes = FALSE, alpha = alpha_sig) +
    ggplot2::geom_vline(xintercept = unique(c(regions$xmin, regions$xmax)),
                        linetype = "dashed", colour = "grey55") +
    ggplot2::geom_text(data = regions,
      ggplot2::aes(x = .data$label_x, label = .data$label), y = Inf,
      inherit.aes = FALSE, vjust = 1.3, size = 3.2)
  p <- p + ggplot2::scale_fill_manual(
    values = c(band = ns_fill, region = sig_fill),
    breaks = c("band", "region"), labels = c(band_label, region_label), name = NULL) +
    ggplot2::labs(title = if (is.null(title)) paste0("Effect curve: ", path_name) else title,
      x = x_label, y = y_label,
      subtitle = .wsmed_plot_ci_label(info, conditional = TRUE),
      caption = "Shading and raw-W boundaries follow the stored grid.\nPointwise intervals, not simultaneous confidence regions.") +
    ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(legend.position = "bottom",
      panel.border = ggplot2::element_rect(colour = "grey70", fill = NA))
  p <- .wsmed_plot_finish(p, info)
  attr(p, "wsmed_regions") <- regions
  p
}
