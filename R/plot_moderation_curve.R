#' @title 绘制调节曲线并高亮 Johnson–Neyman 显著区段
#'
#' @description
#' `plot_moderation_curve()` 从 `wsMed` 对象的输出结果中提取
#' `theta_curve`（用于间接效应）或 `path_curve`（用于路径系数），
#' 并绘制效应随连续调节变量 *W* 变化的曲线图。函数将自动检出
#' 显著区间（置信区间不含 0），并以淡绿色区块和注释高亮显示。
#'
#' 图中包含：
#'
#' * 整体 Monte Carlo 置信带（淡红色）；
#' * 所有 `CI.LL * CI.UL > 0` 的连续显著区块（浅绿色）；
#' * 显著区起止百分位标注，如 `"sig 12.5%–38.3%"`；
#' * 路径曲线与 0 参考线；
#' * 自动匹配路径来源，无需用户指定数据框。
#'
#' @param result     `wsMed()` 返回结果，必须包含 `$moderation` 字段。
#' @param path_name  要绘制的路径名称；与 `theta_curve$Path` 或
#'                   `path_curve$Path` 完全匹配，如 `"indirect_effect_1_2"`
#'                   或 `"b_1_2"`。
#' @param title      图标题；默认为 `"Effect Curve: (<path_name>)"`。
#' @param x_label,y_label 横轴、纵轴标签。
#' @param ns_fill    整体置信区填充色（默认红色）。
#' @param sig_fill   显著区填充色（默认绿色）。
#' @param alpha_ci   整体置信区透明度（默认 0.35）。
#' @param alpha_sig  显著区透明度（默认 0.35）。
#' @param base_size  主题字体大小（传给 `theme_minimal()`）。
#'
#' @details
#' 显著性定义为：`Sig <- CI.LL * CI.UL > 0`，即置信区间上下限不跨 0。
#'
#' 函数使用 `rle()` 分段识别所有连续的显著区间（TRUE），并：
#'
#' 1. 将其左右端点映射到 `W_raw`；
#' 2. 将起止位置映射为网格百分位数并用于标签注释；
#' 3. 用 `geom_rect()` 高亮，并在区段正上方用 `geom_text()` 标注。
#'
#' 若整条曲线均不显著，则不绘制绿色区块，仅保留置信带和曲线。
#'
#' 若 `path_name` 同时存在于 `theta_curve` 和 `path_curve` 中，
#' 优先使用 `theta_curve`。
#'
#' @return
#' 一个 `ggplot` 对象，可使用 `+` 叠加图层，或用 `ggsave()` 导出。
#'
#' @author
#' Your Name <your@email.com>
#'
#' @examples
#' \dontrun{
#' # 假设 result 是 wsMed() 返回对象，已包含 moderation 输出
#'
#' # 绘制间接效应曲线（来自 theta_curve）
#' plot_moderation_curve(result, "indirect_effect_1_2")
#'
#' # 绘制路径系数曲线（来自 path_curve）
#' plot_moderation_curve(result, "b_1_2")
#' }
#'
#' @seealso
#' * [analyze_mm_continuous_v6_fix()] – 生成调节曲线数据
#' * [plot_jn_interval()] – 返回显著区起止端点（不绘图）
#'
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

  # --- 智能识别路径所在数据框 ---
  if (!is.null(mod$theta_curve) && path_name %in% mod$theta_curve$Path) {
    df <- mod$theta_curve
  } else if (!is.null(mod$path_curve) && path_name %in% mod$path_curve$Path) {
    df <- mod$path_curve
  } else {
    msg <- paste0("Path '", path_name, "' not found.\nAvailable:\n",
                  " - theta_curve: ", paste0(unique(mod$theta_curve$Path), collapse = ", "),
                  "\n - path_curve: ", paste0(unique(mod$path_curve$Path), collapse = ", "))
    stop(msg)
  }

  # --- 过滤 + 判定显著性 ---
  df_path <- df |>
    dplyr::filter(Path == path_name) |>
    dplyr::arrange(W_raw) |>
    dplyr::mutate(Sig = CI.LL * CI.UL > 0)

  if (nrow(df_path) == 0) stop("No data for path: ", path_name)
  y_max <- max(df_path$Estimate, na.rm = TRUE)

  # --- 构造显著区段 ---
  runs   <- rle(df_path$Sig)
  lens   <- runs$lengths
  vals   <- runs$values
  starts <- cumsum(c(1, head(lens, -1)))

  seg_df <- dplyr::tibble()
  n_pts  <- nrow(df_path)

  for (j in seq_along(vals)) if (vals[j]) {
    s <- starts[j]; e <- starts[j] + lens[j] - 1
    seg_df <- dplyr::bind_rows(
      seg_df,
      dplyr::tibble(
        xmin    = df_path$W_raw[s],
        xmax    = df_path$W_raw[e],
        label_x = mean(c(df_path$W_raw[s], df_path$W_raw[e])),
        label   = sprintf("sig %.1f%%–%.1f%%",
                          100*(s-1)/(n_pts-1),
                          100*(e-1)/(n_pts-1))
      )
    )
  }

  # --- 绘图 ---
  ggplot2::ggplot(df_path, ggplot2::aes(x = W_raw, y = Estimate)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = CI.LL, ymax = CI.UL, fill = "n.s."),
                         alpha = alpha_ci, colour = NA) +
    { if (nrow(seg_df)) ggplot2::geom_rect(data = seg_df,
                                           ggplot2::aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf,
                                                        fill = "p < .05"),
                                           inherit.aes = FALSE, alpha = alpha_sig, colour = NA) else NULL } +
    ggplot2::geom_line(linewidth = .6, colour = "indianred4") +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
    { if (nrow(seg_df)) ggplot2::geom_vline(xintercept = seg_df$xmin,
                                            linetype = "dashed", colour = "grey55") else NULL } +
    { if (nrow(seg_df)) ggplot2::geom_vline(xintercept = seg_df$xmax,
                                            linetype = "dashed", colour = "grey55") else NULL } +
    { if (nrow(seg_df)) ggplot2::geom_text(data = seg_df,
                                           ggplot2::aes(x = label_x, label = label),
                                           y = y_max,
                                           inherit.aes = FALSE,
                                           vjust = -0.8, size = 4, fontface = "italic") else NULL } +
    ggplot2::scale_fill_manual(values = c("n.s." = ns_fill, "sig" = sig_fill),
                               name = NULL) +
    ggplot2::labs(title = title %||% paste0("Effect Curve: (", path_name, ")"),
                  x = x_label, y = y_label) +
    ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(size = 13, hjust = 0.5),
      legend.position = "right",
      panel.border    = ggplot2::element_rect(colour = "black", fill = NA)
    )
}



