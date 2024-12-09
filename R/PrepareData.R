PrepareData <- function(data, M_before, M_after, Y_before, Y_after) {
  # 检查输入长度是否匹配
  if (length(M_before) != length(M_after)) {
    stop("The number of M_before and M_after variables must match.")
  }

  # 检查 Y_before 和 Y_after 是否存在
  if (!(Y_before %in% colnames(data)) || !(Y_after %in% colnames(data))) {
    stop("Y variables not found in the dataset.")
  }

  # 计算 Y 的差异
  data$Ydiff <- data[[Y_after]] - data[[Y_before]]

  # 初始化存储差异和均值的列
  diffs <- list()
  avgs <- list()

  # 循环处理每对中介变量
  for (i in seq_along(M_before)) {
    M1 <- M_before[i]
    M2 <- M_after[i]

    # 检查 M1 和 M2 是否存在
    if (!(M1 %in% colnames(data)) || !(M2 %in% colnames(data))) {
      stop(paste0("M variables for ", M1, " and ", M2, " not found in the dataset."))
    }

    # 计算差异和中心化均值
    diff_name <- paste0("M", i, "diff")
    avg_name <- paste0("M", i, "avg")
    diffs[[diff_name]] <- data[[M2]] - data[[M1]]
    M1_centered <- data[[M1]] - mean(data[[M1]], na.rm = TRUE)
    M2_centered <- data[[M2]] - mean(data[[M2]], na.rm = TRUE)
    avgs[[avg_name]] <- (M1_centered + M2_centered) / 2
  }

  # 将生成的差异和均值列添加到数据框中
  data <- cbind(data, do.call(cbind, diffs), do.call(cbind, avgs))

  # 返回只包含 Ydiff 和所有差异与均值的列
  cols_to_return <- c("Ydiff", names(diffs), names(avgs))
  return(data[, cols_to_return])
}
