#' @title Plot moderation curves with Johnson-Neyman highlights
#'
#' @description
#' `plot_moderation_curve()` plots how a conditional indirect effect or path
#' coefficient changes across values of a continuous moderator.
#'
#' @details
#' The function searches the moderation results for the effect specified by
#' `path_name`. It first searches `result$moderation$theta_curve`, which
#' contains conditional indirect effects, and then
#' `result$moderation$path_curve`, which contains conditional path
#' coefficients. If the same name appears in both components,
#' `theta_curve` is used.
#'
#' The selected records are ordered by the raw moderator values in `W_raw`.
#' The function then plots the conditional estimates in `Estimate` and the
#' confidence band defined by `CI.LL` and `CI.UL`.
#'
#' A moderator value is treated as statistically significant when the lower
#' and upper confidence limits have the same sign. Equivalently, the product
#' of `CI.LL` and `CI.UL` must be greater than zero. Consecutive significant
#' moderator values are combined into intervals and highlighted as
#' Johnson-Neyman regions.
#'
#' The red ribbon shows the complete confidence band, whereas the green
#' ribbon highlights regions in which the confidence interval excludes zero.
#' The solid line represents the conditional point estimate. The horizontal
#' dashed line marks zero, and the vertical dashed lines mark the boundaries
#' of the highlighted regions. Each highlighted region is annotated with the
#' percentile range of the moderator values that it covers.
#'
#' The interval boundaries are identified from the moderator grid stored in
#' the moderation results. They should therefore be interpreted as
#' grid-based approximations to the Johnson-Neyman boundaries. A denser
#' moderator grid produces more precise boundary locations.
#'
#' @param result A result object returned by `wsMed()` containing a
#'   `moderation` component.
#' @param path_name A single character string giving the exact name of the
#'   conditional effect to plot, such as `"indirect_1_2"` or `"b_1_2"`.
#'   When the name occurs in both `theta_curve` and `path_curve`,
#'   `theta_curve` is used.
#' @param title An optional character string giving the plot title. If
#'   `NULL`, a title is automatically constructed from `path_name`.
#' @param x_label A character string giving the horizontal-axis label.
#'   The default is `"Moderator (W)"`.
#' @param y_label A character string giving the vertical-axis label.
#'   The default is `"Estimate"`.
#' @param ns_fill A colour specification for the complete confidence band.
#' @param sig_fill A colour specification for the highlighted significant
#'   regions.
#' @param alpha_ci A numeric value between zero and one controlling the
#'   transparency of the complete confidence band.
#' @param alpha_sig A numeric value between zero and one controlling the
#'   transparency of the highlighted significant regions.
#' @param base_size A positive numeric value specifying the base font size
#'   passed to `ggplot2::theme_minimal()`.
#'
#' @return A `ggplot` object. Additional ggplot2 layers can be added to the
#'   returned object, and the plot can be saved using `ggplot2::ggsave()`.
#'
#' @importFrom dplyr arrange bind_rows filter mutate tibble
#' @importFrom ggplot2 aes element_rect element_text geom_hline geom_line
#' @importFrom ggplot2 geom_rect geom_ribbon geom_text geom_vline ggplot labs
#' @importFrom ggplot2 scale_fill_manual theme theme_minimal
#' @export
plot_moderation_curve <- function(result, path_name,
                                  title     = NULL,
                                  x_label   = "Moderator (W)",
                                  y_label   = "Estimate",
                                  ns_fill   = "#FEE0D2",
                                  sig_fill  = "#C7E9C0",
                                  alpha_ci  = 0.35,
                                  alpha_sig = 0.35,
                                  base_size = 14) {
  stopifnot(requireNamespace("ggplot2"), requireNamespace("dplyr"))

  `%||%` <- function(a, b) if (!is.null(a)) a else b
  mod <- result$moderation

  ## locate the curve ------------------------------------------------------
  if (!is.null(mod$theta_curve) && path_name %in% mod$theta_curve$Path) {
    df <- mod$theta_curve
  } else if (!is.null(mod$path_curve) && path_name %in% mod$path_curve$Path) {
    df <- mod$path_curve
  } else {
    msg <- paste0(
      "Path '", path_name, "' not found.\nAvailable:\n",
      " - theta_curve: ",
      paste0(unique(mod$theta_curve$Path), collapse = ", "),
      "\n - path_curve: ",
      paste0(unique(mod$path_curve$Path), collapse = ", ")
    )
    stop(msg, call. = FALSE)
  }

  ## filter & significance flag -------------------------------------------
  df_path <- df |>
    dplyr::filter(Path == path_name) |>
    dplyr::arrange(W_raw) |>
    dplyr::mutate(Sig = CI.LL * CI.UL > 0)

  if (nrow(df_path) == 0)
    stop("No data for path: ", path_name, call. = FALSE)

  y_max <- max(df_path$Estimate, na.rm = TRUE)

  ## build significant-segment data ---------------------------------------
  runs   <- rle(df_path$Sig)
  lens   <- runs$lengths
  vals   <- runs$values
  starts <- cumsum(c(1L, utils::head(lens, -1L)))

  seg_df <- dplyr::tibble()
  n_pts  <- nrow(df_path)

  for (j in seq_along(vals)) if (vals[j]) {
    s <- starts[j]; e <- starts[j] + lens[j] - 1L
    seg_df <- dplyr::bind_rows(
      seg_df,
      dplyr::tibble(
        xmin    = df_path$W_raw[s],
        xmax    = df_path$W_raw[e],
        label_x = mean(c(df_path$W_raw[s], df_path$W_raw[e])),
        label   = sprintf("sig %.1f%%-%.1f%%",
                          100 * (s - 1) / (n_pts - 1),
                          100 * (e - 1) / (n_pts - 1))
      )
    )
  }

  ## plotting --------------------------------------------------------------
  ggplot2::ggplot(df_path, ggplot2::aes(x = W_raw, y = Estimate)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = CI.LL, ymax = CI.UL, fill = "n.s."),
      alpha = alpha_ci, colour = NA
    ) +
    { if (nrow(seg_df))
      ggplot2::geom_rect(
        data = seg_df,
        ggplot2::aes(xmin = xmin, xmax = xmax,
                     ymin = -Inf, ymax = Inf,
                     fill = "p < .05"),
        inherit.aes = FALSE, alpha = alpha_sig, colour = NA)
      else NULL } +
    ggplot2::geom_line(linewidth = 0.6, colour = "indianred4") +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                        colour = "grey45") +
    { if (nrow(seg_df))
      ggplot2::geom_vline(xintercept = seg_df$xmin,
                          linetype = "dashed", colour = "grey55")
      else NULL } +
    { if (nrow(seg_df))
      ggplot2::geom_vline(xintercept = seg_df$xmax,
                          linetype = "dashed", colour = "grey55")
      else NULL } +
    { if (nrow(seg_df))
      ggplot2::geom_text(
        data = seg_df,
        ggplot2::aes(x = label_x, label = label),
        y = y_max, inherit.aes = FALSE,
        vjust = -0.8, size = 4, fontface = "italic")
      else NULL } +
    ggplot2::scale_fill_manual(
      values = c("n.s." = ns_fill, "p < .05" = sig_fill),
      name = NULL
    ) +
    ggplot2::labs(
      title = title %||% paste0("Effect Curve: (", path_name, ")"),
      x = x_label, y = y_label
    ) +
    ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(size = 13, hjust = 0.5),
      legend.position = "right",
      panel.border    = ggplot2::element_rect(colour = "black", fill = NA)
    )
}

## global variables for R CMD check ----------------------------------------
utils::globalVariables(c(
  "Path", "W_raw", "CI.LL", "CI.UL",
  "Estimate", "xmin", "xmax", "label_x", "label"
))
