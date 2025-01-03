
# 定义 print.WsMed
# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(data.frame(
      Name = "Total effect of X on Y",
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(data.frame(
      Name = "Direct effect of X on Y)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ))
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ))
  }

  # 返回原始对象
  invisible(x)
}
# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)
    indirect_key <- data.frame(
      Ind = paste0("indirect", seq_along(Mdiff_vars)),
      Path = paste("X ->", Mdiff_vars, "-> Ydiff")
    )
    cat("\n*************** INDIRECT KEY ***************\n")
    print(indirect_key)
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ))
  }

  # 返回原始对象
  invisible(x)
}
# 定义 print.WsMed 方法
# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- as.numeric(unlist(regmatches(ind, gregexpr("\\d", ind))))
        if (all(!is.na(indices))) {
          path <- paste(c("X", Mdiff_vars[indices], "Ydiff"), collapse = " -> ")
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind, Path = path))
        }
      }

      # 打印 Indirect Key
      cat("\n*************** INDIRECT KEY ***************\n")
      print(indirect_key)
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ))
  }

  # 返回原始对象
  invisible(x)
}



# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(format(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), justify = "left"))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(format(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), justify = "left"))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(format(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ), justify = "left"))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- as.numeric(unlist(regmatches(ind, gregexpr("\\d", ind))))
        if (all(!is.na(indices))) {
          path <- paste(c("X", Mdiff_vars[indices], "Ydiff"), collapse = " -> ")
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind, Path = path))
        }
      }

      # 打印 Indirect Key
      cat("\n*************** INDIRECT KEY ***************\n")
      print(format(indirect_key, justify = "left"))
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(format(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ), justify = "left"))
  }

  # 返回原始对象
  invisible(x)
}

# 示例调用
# 假设 result 是 WsMed 函数的输出
# print(result)

# 示例调用
# 假设 result 是 WsMed 函数的输出
# print(result)

# 示例调用
# 假设 result 是 WsMed 函数的输出
# print(result4)
# 定义 print.WsMed 方法
library(knitr)

# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "l", "l", "l", "l", "l", "l")))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "l", "l", "l", "l", "l", "l")))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ), align = c("c", "l", "l", "l", "l", "l")))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- as.numeric(unlist(regmatches(ind, gregexpr("\\d", ind))))
        if (all(!is.na(indices))) {
          path <- paste(c("X", Mdiff_vars[indices], "Ydiff"), collapse = " -> ")
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind, Path = path))
        }
      }

      # 打印 Indirect Key
      cat("\n*************** INDIRECT KEY ***************\n")
      print(kable(indirect_key, align = c("c", "l")))
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ), align = c("c", "l", "l", "l", "l", "l")))
  }

  # 返回原始对象
  invisible(x)
}
library(knitr)

# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c")))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c")))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  if (nrow(indirect_effects) > 0) {
    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(data.frame(
      Name = indirect_effects$lhs,
      Effect = indirect_effects$est,
      SE = indirect_effects$se,
      LLCI = indirect_effects$ci.lower,
      ULCI = indirect_effects$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c")))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- as.numeric(unlist(regmatches(ind, gregexpr("\\d", ind))))
        if (all(!is.na(indices))) {
          path <- paste(c("X", Mdiff_vars[indices], "Ydiff"), collapse = " -> ")
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind, Path = path))
        }
      }

      # 打印 Indirect Key
      cat("\n*************** INDIRECT KEY ***************\n")
      print(kable(indirect_key, align = c("c", "c")))
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(data.frame(
      Name = contrast_effects$lhs,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c")))
  }

  # 返回原始对象
  invisible(x)
}



# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Total_effect",
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Direct effect",
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  total_indirect_effect <- param_estimates[param_estimates$lhs == "total_indirect", ]

  if (nrow(indirect_effects) > 0 || nrow(total_indirect_effect) > 0) {
    # 缩写名称
    indirect_names <- gsub("indirect", "ind", indirect_effects$lhs)
    total_ind_name <- "total ind"

    # 合并间接效应和总间接效应
    combined_effects <- rbind(
      data.frame(
        Name = indirect_names,
        Effect = indirect_effects$est,
        SE = indirect_effects$se,
        LLCI = indirect_effects$ci.lower,
        ULCI = indirect_effects$ci.upper
      ),
      if (nrow(total_indirect_effect) > 0) {
        data.frame(
          Name = total_ind_name,
          Effect = total_indirect_effect$est,
          SE = total_indirect_effect$se,
          LLCI = total_indirect_effect$ci.lower,
          ULCI = total_indirect_effect$ci.upper
        )
      } else {
        NULL
      }
    )

    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- as.numeric(unlist(regmatches(ind, gregexpr("\\d+", ind))))
        if (all(!is.na(indices))) {
          path <- paste(c("X", Mdiff_vars[indices], "Ydiff"), collapse = " -> ")
          ind_name <- gsub("indirect", "ind", ind)  # 缩写名称
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind_name, Path = path))
        }
      }

      # 打印 Indirect Key
      if (nrow(indirect_key) > 0) {
        cat("\n*************** INDIRECT KEY ***************\n")
        print(kable(indirect_key, align = c("c", "c"), row.names = FALSE))
      }
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    # 修改对比效应的名称
    contrast_names <- sapply(contrast_effects$lhs, function(name) {
      indices <- unlist(regmatches(name, gregexpr("\\d+", name)))  # 提取完整数字组
      if (length(indices) == 2) {
        paste0("ind", indices[1], " vs ind", indices[2])  # 生成 indX vs indY 格式
      } else {
        name  # 如果解析失败，保留原名称
      }
    })

    # 构建对比效应表
    contrast_table <- data.frame(
      Name = contrast_names,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    )

    # 打印对比效应
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(contrast_table, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 返回原始对象
  invisible(x)
}




library(knitr)

# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  total_indirect_effect <- param_estimates[param_estimates$lhs == "total_indirect", ]

  if (nrow(indirect_effects) > 0 || nrow(total_indirect_effect) > 0) {
    # 缩写名称
    indirect_names <- gsub("indirect", "ind", indirect_effects$lhs)
    total_ind_name <- "total ind"

    # 合并间接效应和总间接效应
    combined_effects <- rbind(
      data.frame(
        Name = indirect_names,
        Effect = indirect_effects$est,
        SE = indirect_effects$se,
        LLCI = indirect_effects$ci.lower,
        ULCI = indirect_effects$ci.upper
      ),
      if (nrow(total_indirect_effect) > 0) {
        data.frame(
          Name = total_ind_name,
          Effect = total_indirect_effect$est,
          SE = total_indirect_effect$se,
          LLCI = total_indirect_effect$ci.lower,
          ULCI = total_indirect_effect$ci.upper
        )
      } else {
        NULL
      }
    )

    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- unlist(strsplit(gsub("indirect", "", ind), split = ""))
        indices <- as.numeric(indices)  # 转换为数字

        if (all(!is.na(indices))) {
          # 匹配对应的变量名称，生成路径
          path_vars <- Mdiff_vars[indices]
          path <- paste(c("X", path_vars, "Ydiff"), collapse = " -> ")

          # 添加到 Indirect Key 表格
          ind_name <- gsub("indirect", "ind", ind)  # 缩写名称
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind_name, Path = path))
        }
      }

      # 打印 Indirect Key
      if (nrow(indirect_key) > 0) {
        cat("\n*************** INDIRECT KEY ***************\n")
        print(kable(indirect_key, align = c("c", "c"), row.names = FALSE))
      }
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    # 修改对比效应的名称
    contrast_names <- sapply(contrast_effects$lhs, function(name) {
      indices <- unlist(regmatches(name, gregexpr("\\d+", name)))  # 提取完整数字组
      if (length(indices) == 2) {
        paste0("ind", indices[1], " - ind", indices[2])  # 生成 indX vs indY 格式
      } else {
        name  # 如果解析失败，保留原名称
      }
    })

    # 构建对比效应表
    contrast_table <- data.frame(
      Name = contrast_names,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    )

    # 打印对比效应
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(contrast_table, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 返回原始对象
  invisible(x)
}






library(knitr)

# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  total_indirect_effect <- param_estimates[param_estimates$lhs == "total_indirect", ]

  if (nrow(indirect_effects) > 0 || nrow(total_indirect_effect) > 0) {
    # 缩写名称
    indirect_names <- gsub("indirect", "ind", indirect_effects$lhs)
    total_ind_name <- "total ind"

    # 合并间接效应和总间接效应
    combined_effects <- rbind(
      data.frame(
        Name = indirect_names,
        Effect = indirect_effects$est,
        SE = indirect_effects$se,
        LLCI = indirect_effects$ci.lower,
        ULCI = indirect_effects$ci.upper
      ),
      if (nrow(total_indirect_effect) > 0) {
        data.frame(
          Name = total_ind_name,
          Effect = total_indirect_effect$est,
          SE = total_indirect_effect$se,
          LLCI = total_indirect_effect$ci.lower,
          ULCI = total_indirect_effect$ci.upper
        )
      } else {
        NULL
      }
    )

    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- unlist(strsplit(gsub("indirect", "", ind), split = ""))
        indices <- as.numeric(indices)  # 转换为数字

        if (all(!is.na(indices))) {
          # 匹配对应的变量名称，生成路径
          path_vars <- Mdiff_vars[indices]
          path <- paste(c("X", path_vars, "Ydiff"), collapse = " -> ")

          # 添加到 Indirect Key 表格
          ind_name <- gsub("indirect", "ind", ind)  # 缩写名称
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind_name, Path = path))
        }
      }

      # 打印 Indirect Key
      if (nrow(indirect_key) > 0) {
        cat("\n*************** INDIRECT KEY ***************\n")
        print(kable(indirect_key, align = c("c", "c"), row.names = FALSE))
      }
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    # 修改对比效应的名称
    contrast_names <- sapply(contrast_effects$lhs, function(name) {
      indices <- unlist(regmatches(name, gregexpr("\\d+", name)))  # 提取完整数字组
      if (length(indices) == 2) {
        paste0("ind", indices[1], " - ind", indices[2])  # 生成 indX vs indY 格式
      } else {
        name  # 如果解析失败，保留原名称
      }
    })

    # 构建对比效应表
    contrast_table <- data.frame(
      Name = contrast_names,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    )

    # 打印对比效应
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(contrast_table, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 前后测系数对比
  pre_post_coeff <- param_estimates[grep("^X[01]_b", param_estimates$lhs), ]
  if (nrow(pre_post_coeff) > 0) {
    cat("\n*************** PRE-POST COEFFICIENTS ***************\n")
    print(kable(data.frame(
      Name = pre_post_coeff$lhs,
      Effect = pre_post_coeff$est,
      SE = pre_post_coeff$se,
      z = pre_post_coeff$z,
      p = pre_post_coeff$pvalue,
      LLCI = pre_post_coeff$ci.lower,
      ULCI = pre_post_coeff$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 返回原始对象
  invisible(x)
}



library(knitr)

# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n*************** TOTAL EFFECT ***************\n")
    print(kable(data.frame(
      Name = total_effect$lhs,
      Effect = total_effect$est,
      SE = total_effect$se,
      z = total_effect$z,
      p = total_effect$pvalue,
      LLCI = total_effect$ci.lower,
      ULCI = total_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 直接效应（截距项）
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
  if (nrow(direct_effect) > 0) {
    cat("\n*************** DIRECT EFFECT ***************\n")
    print(kable(data.frame(
      Name = "Intercept (Direct Effect)",  # 固定名称
      Effect = direct_effect$est,
      SE = direct_effect$se,
      z = direct_effect$z,
      p = direct_effect$pvalue,
      LLCI = direct_effect$ci.lower,
      ULCI = direct_effect$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 间接效应
  indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
  total_indirect_effect <- param_estimates[param_estimates$lhs == "total_indirect", ]

  if (nrow(indirect_effects) > 0 || nrow(total_indirect_effect) > 0) {
    # 缩写名称
    indirect_names <- gsub("indirect", "ind", indirect_effects$lhs)
    total_ind_name <- "total ind"

    # 合并间接效应和总间接效应
    combined_effects <- rbind(
      data.frame(
        Name = indirect_names,
        Effect = indirect_effects$est,
        SE = indirect_effects$se,
        LLCI = indirect_effects$ci.lower,
        ULCI = indirect_effects$ci.upper
      ),
      if (nrow(total_indirect_effect) > 0) {
        data.frame(
          Name = total_ind_name,
          Effect = total_indirect_effect$est,
          SE = total_indirect_effect$se,
          LLCI = total_indirect_effect$ci.lower,
          ULCI = total_indirect_effect$ci.upper
        )
      } else {
        NULL
      }
    )

    cat("\n*************** INDIRECT EFFECTS ***************\n")
    print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 动态生成 Indirect Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

    if (length(Mdiff_vars) == 0) {
      warning("No mediator variables found. Unable to generate Indirect Key.")
    } else {
      indirect_key <- data.frame()

      # 遍历所有间接效应名称（如 indirect1, indirect12）
      for (ind in indirect_effects$lhs) {
        # 提取路径中的索引
        indices <- unlist(strsplit(gsub("indirect", "", ind), split = ""))
        indices <- as.numeric(indices)  # 转换为数字

        if (all(!is.na(indices))) {
          # 匹配对应的变量名称，生成路径
          path_vars <- Mdiff_vars[indices]
          path <- paste(c("X", path_vars, "Ydiff"), collapse = " -> ")

          # 添加到 Indirect Key 表格
          ind_name <- gsub("indirect", "ind", ind)  # 缩写名称
          indirect_key <- rbind(indirect_key, data.frame(Ind = ind_name, Path = path))
        }
      }

      # 打印 Indirect Key
      if (nrow(indirect_key) > 0) {
        cat("\n*************** INDIRECT KEY ***************\n")
        print(kable(indirect_key, align = c("c", "c"), row.names = FALSE))
      }
    }
  }

  # 对比效应
  contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
  if (nrow(contrast_effects) > 0) {
    # 修改对比效应的名称
    contrast_names <- sapply(contrast_effects$lhs, function(name) {
      indices <- unlist(regmatches(name, gregexpr("\\d+", name)))  # 提取完整数字组
      if (length(indices) == 2) {
        paste0("ind", indices[1], " - ind", indices[2])  # 生成 indX vs indY 格式
      } else {
        name  # 如果解析失败，保留原名称
      }
    })

    # 构建对比效应表
    contrast_table <- data.frame(
      Name = contrast_names,
      Effect = contrast_effects$est,
      SE = contrast_effects$se,
      LLCI = contrast_effects$ci.lower,
      ULCI = contrast_effects$ci.upper
    )

    # 打印对比效应
    cat("\n*************** CONTRAST EFFECTS ***************\n")
    print(kable(contrast_table, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 前后测系数对比
  pre_post_coeff <- param_estimates[grep("^X[01]_b", param_estimates$lhs), ]
  if (nrow(pre_post_coeff) > 0) {
    cat("\n*************** PRE-POST COEFFICIENTS ***************\n")
    print(kable(data.frame(
      Name = pre_post_coeff$lhs,
      Effect = pre_post_coeff$est,
      SE = pre_post_coeff$se,
      z = pre_post_coeff$z,
      p = pre_post_coeff$pvalue,
      LLCI = pre_post_coeff$ci.lower,
      ULCI = pre_post_coeff$ci.upper
    ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
  }

  # 前后测系数 Key
  if (!is.null(x$prepared_data)) {
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)
    pre_post_key <- data.frame()

    for (i in seq_along(Mdiff_vars)) {
      pre_post_key <- rbind(pre_post_key, data.frame(
        Coefficient = paste0("b", i),
        Path = paste0(Mdiff_vars[i], " -> Ydiff")
      ))
    }

    if (length(Mdiff_vars) > 1) {
      for (i in 1:(length(Mdiff_vars) - 1)) {
        for (j in (i + 1):length(Mdiff_vars)) {
          pre_post_key <- rbind(pre_post_key, data.frame(
            Coefficient = paste0("b", i, j),
            Path = paste0(Mdiff_vars[i], " -> ", Mdiff_vars[j])
          ))
        }
      }
    }

    cat("\n*************** PRE-POST COEFFICIENTS KEY ***************\n")
    print(kable(pre_post_key, align = c("c", "c"), row.names = FALSE))
  }

  # 返回原始对象
  invisible(x)
}



library(knitr)
library(knitr)



  # 定义 print.WsMed 方法
  print.WsMed <- function(x, ...) {
    # 检查输入对象是否为 WsMed 类
    if (!inherits(x, "WsMed")) {
      stop("The input object must be of class 'WsMed'.")
    }

    # 提取 lavaan_fit
    fit <- x$lavaan_fit
    input_vars <- x$input_vars

    # 检查是否存在模型拟合结果
    if (is.null(fit)) {
      cat("No model fitting results available.\n")
      return(invisible(x))
    }

    # 提取参数估计
    param_estimates <- lavaan::parameterEstimates(fit)

    # 总效应
    total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
    if (nrow(total_effect) > 0) {
      cat("\n*************** TOTAL EFFECT ***************\n")
      print(kable(data.frame(
        Name = "Total effect",
        Effect = total_effect$est,
        SE = total_effect$se,
        z = total_effect$z,
        p = total_effect$pvalue,
        LLCI = total_effect$ci.lower,
        ULCI = total_effect$ci.upper
      ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # 直接效应（截距项）
    direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]
    if (nrow(direct_effect) > 0) {
      cat("\n")
      cat("\n*************** DIRECT EFFECT ***************\n")
      print(kable(data.frame(
        Name = "Direct effect",  # 固定名称
        Effect = direct_effect$est,
        SE = direct_effect$se,
        z = direct_effect$z,
        p = direct_effect$pvalue,
        LLCI = direct_effect$ci.lower,
        ULCI = direct_effect$ci.upper
      ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # 间接效应
    indirect_effects <- param_estimates[grep("^indirect", param_estimates$lhs), ]
    total_indirect_effect <- param_estimates[param_estimates$lhs == "total_indirect", ]

    if (nrow(indirect_effects) > 0 || nrow(total_indirect_effect) > 0) {
      # 缩写名称
      indirect_names <- gsub("indirect", "ind", indirect_effects$lhs)
      total_ind_name <- "total ind"

      # 合并间接效应和总间接效应
      combined_effects <- rbind(
        data.frame(
          Name = indirect_names,
          Effect = indirect_effects$est,
          SE = indirect_effects$se,
          LLCI = indirect_effects$ci.lower,
          ULCI = indirect_effects$ci.upper
        ),
        if (nrow(total_indirect_effect) > 0) {
          data.frame(
            Name = total_ind_name,
            Effect = total_indirect_effect$est,
            SE = total_indirect_effect$se,
            LLCI = total_indirect_effect$ci.lower,
            ULCI = total_indirect_effect$ci.upper
          )
        } else {
          NULL
        }
      )
      cat("\n")
      cat("\n*************** INDIRECT EFFECTS ***************\n")
      print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # 动态生成 Indirect Key
    if (!is.null(x$prepared_data)) {
      Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)

      if (length(Mdiff_vars) == 0) {
        warning("No mediator variables found. Unable to generate Indirect Key.")
      } else {
        indirect_key <- data.frame()

        # 遍历所有间接效应名称（如 indirect1, indirect12）
        for (ind in indirect_effects$lhs) {
          # 提取路径中的索引
          indices <- unlist(strsplit(gsub("indirect", "", ind), split = ""))
          indices <- as.numeric(indices)  # 转换为数字

          if (all(!is.na(indices))) {
            # 匹配对应的变量名称，生成路径
            path_vars <- Mdiff_vars[indices]
            path <- paste(c("X", path_vars, "Ydiff"), collapse = " -> ")

            # 添加到 Indirect Key 表格
            ind_name <- gsub("indirect", "ind", ind)  # 缩写名称
            indirect_key <- rbind(indirect_key, data.frame(Ind = ind_name, Path = path))
          }
        }

        # 打印 Indirect Key
        if (nrow(indirect_key) > 0) {
          #cat("\n*************** INDIRECT KEY ***************\n")
          print(kable(indirect_key, align = c("c", "c"), row.names = FALSE))
        }
      }
    }

    # 对比效应
    contrast_effects <- param_estimates[grep("^CI", param_estimates$lhs), ]
    if (nrow(contrast_effects) > 0) {
      # 修改对比效应的名称
      contrast_names <- sapply(contrast_effects$lhs, function(name) {
        indices <- unlist(regmatches(name, gregexpr("\\d+", name)))  # 提取完整数字组
        if (length(indices) == 2) {
          paste0("ind", indices[1], " - ind", indices[2])  # 生成 indX vs indY 格式
        } else {
          name  # 如果解析失败，保留原名称
        }
      })

      # 构建对比效应表
      contrast_table <- data.frame(
        Name = contrast_names,
        Effect = contrast_effects$est,
        SE = contrast_effects$se,
        LLCI = contrast_effects$ci.lower,
        ULCI = contrast_effects$ci.upper
      )

      # 打印对比效应
      cat("\n")
      cat("\n*************** CONTRAST INDIRECT EFFECTS ***************\n")
      print(kable(contrast_table, align = c("c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # Moderation Effects
    moderation_effects <- param_estimates[
      param_estimates$rhs %in% grep("M\\davg", colnames(x$prepared_data), value = TRUE) &
        grepl("^d", param_estimates$label),
    ]
    if (nrow(moderation_effects) > 0) {
      cat("\n")
      cat("\n*************** MODERATION EFFECTS of X ***************\n")
      print(kable(data.frame(
        Name = moderation_effects$label,
        Effect = moderation_effects$est,
        SE = moderation_effects$se,
        z = moderation_effects$z,
        p = moderation_effects$pvalue,
        LLCI = moderation_effects$ci.lower,
        ULCI = moderation_effects$ci.upper
      ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # Moderation Effects Key
    if (!is.null(x$prepared_data)) {
      Mavg_vars <- grep("M\\davg", colnames(x$prepared_data), value = TRUE)
      Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)
      moderation_key <- data.frame()

      # Add single moderation effects (d1, d2, ...)
      for (i in seq_along(Mavg_vars)) {
        moderation_key <- rbind(moderation_key, data.frame(
          Coefficient = paste0("d", i),
          Path = paste0(Mavg_vars[i], " -> Ydiff")
        ))
      }

      # Add cross-variable moderation effects (d12, d23, ...)
      for (i in seq_along(Mavg_vars)) {
        if (i < length(Mdiff_vars)) {
          moderation_key <- rbind(moderation_key, data.frame(
            Coefficient = paste0("d", i, i + 1),
            Path = paste0(Mavg_vars[i], " -> ", Mdiff_vars[i + 1])
          ))
        }
      }

      if (nrow(moderation_key) > 0) {
        #cat("\n*************** MODERATION EFFECTS KEY ***************\n")
        print(kable(moderation_key, align = c("c", "c"), row.names = FALSE))
      }
    }



    # 前后测系数对比
    pre_post_coeff <- param_estimates[grep("^X[01]_b", param_estimates$lhs), ]
    if (nrow(pre_post_coeff) > 0) {
      cat("\n")
      cat("\n*************** PRE-POST COEFFICIENTS ***************\n")
      print(kable(data.frame(
        Name = pre_post_coeff$lhs,
        Effect = pre_post_coeff$est,
        SE = pre_post_coeff$se,
        z = pre_post_coeff$z,
        p = pre_post_coeff$pvalue,
        LLCI = pre_post_coeff$ci.lower,
        ULCI = pre_post_coeff$ci.upper
      ), align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
    }

    # 前后测系数 Key
    if (!is.null(x$prepared_data)) {
      Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)
      pre_post_key <- data.frame()

      for (i in seq_along(Mdiff_vars)) {
        pre_post_key <- rbind(pre_post_key, data.frame(
          Coefficient = paste0("b", i),
          Path = paste0(Mdiff_vars[i], " -> Ydiff")
        ))
      }

      if (length(Mdiff_vars) > 1) {
        for (i in 1:(length(Mdiff_vars) - 1)) {
          for (j in (i + 1):length(Mdiff_vars)) {
            pre_post_key <- rbind(pre_post_key, data.frame(
              Coefficient = paste0("b", i, j),
              Path = paste0(Mdiff_vars[i], " -> ", Mdiff_vars[j])
            ))
          }
        }
      }

      #cat("\n*************** PRE-POST COEFFICIENTS KEY ***************\n")
      print(kable(pre_post_key, align = c("c", "c"), row.names = FALSE))
    }




    # 返回原始对象
    invisible(x)
  }
  print(result4)
