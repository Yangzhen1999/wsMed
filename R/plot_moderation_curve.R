#' @title Plot moderation curves with Johnson-Neyman highlights
#'
#' @description
#' `plot_moderation_curve()` visualises how an indirect effect
#' (`theta_curve`) or a path coefficient (`path_curve`) varies along a
#' continuous moderator *W*.
#'
#' The routine
#' * extracts the requested record (`path_name`) from `result$moderation`,
#'   preferring `theta_curve` when it is available in both curves;
#' * draws the conditional effect (`Estimate`) against the raw moderator grid
#'   (`W_raw`);
#' * overlays the Monte-Carlo confidence band (`CI.LL`, `CI.UL`) and finds every
#'   Johnson–Neyman segment whose 95 % CI excludes zero
#'   (`CI.LL * CI.UL > 0`);
#' * shades these significant regions and annotates each with its start /
#'   end percentiles (for example, `"sig 12.5%-38.3%"`).
#'
#' Visual elements
#' * **Red ribbon**   – overall 95 % confidence band (`ns_fill`);
#' * **Green ribbon** – significant Johnson–Neyman intervals (`sig_fill`);
#' * **Solid line**   – point estimate;
#' * **Dashed h-line** – zero reference;
#' * **Dashed v-lines** – J–N bounds.
#'
#' @param result A `wsMed()` result that contains a `$moderation` element.
#' @param path_name Exact name of the path to plot (e.g. `"indirect_1_2"` or
#'   `"b_1_2"`).  When the name exists in both curves, `theta_curve` is used.
#' @param title   Optional plot title (default
#'   `sprintf("Effect Curve: (%s)", path_name)`).
#' @param x_label,y_label Axis labels.  Defaults are `"Moderator (W)"` and
#'   `"Estimate"`.
#' @param ns_fill,sig_fill  Fill colours for the confidence band and the
#'   significant regions.
#' @param alpha_ci,alpha_sig Alpha values for the two ribbons.
#' @param base_size Base font size passed to `ggplot2::theme_minimal()`.
#'
#' @return A `ggplot` object (add layers or save with `ggsave()`).
#'
#' @examples
#'
#' data("example_data", package = "wsMed")
#' result <- wsMed(
#'                 data = example_data,
#'                 M_C1 = c("A1","B1","C1"),
#'                 M_C2 = c("A2","B2","C2"),
#'                 Y_C1 = "D1",
#'                 Y_C2 = "D2",
#'                 form = "CP",
#'                 W      = "D3",
#'                 W_type = "continuous",
#'                 MP     = c("a1","b2","d1","cp","b_1_2","d_1_2"),
#'                 )
#' plot_moderation_curve(result, "indirect_effect_1_2") # indirect
#' plot_moderation_curve(result, "b_1_2")               # direct path
#'
#'
#' @importFrom dplyr filter arrange mutate bind_rows tibble
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon geom_rect
#' @importFrom ggplot2 geom_hline geom_vline geom_text scale_fill_manual
#' @importFrom ggplot2 labs theme_minimal theme element_text element_rect
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
