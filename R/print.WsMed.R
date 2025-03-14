#' @title Print Method for wsMed Objects
#'
#' @description Provides a comprehensive summary of results from a \code{wsMed} object, including:
#' - Input and computed variables with sample size.
#' - Model fit indices, regression paths, and variance estimates.
#' - Total, direct, and indirect effects with pairwise contrasts.
#' - Moderation effects and Monte Carlo confidence intervals for raw and standardized estimates (if applicable).
#' - Diagnostic notes for bootstrapping, imputation, and analysis parameters.
#'
#' The output is formatted for clarity, ensuring an intuitive presentation of mediation analysis results,
#' including dynamic confidence intervals, moderation keys, and C1-C2 coefficients.
#'
#' @details This function is specifically designed to display results from the within-subject mediation
#' analysis conducted using the \code{wsMed} function. Key features include:
#'
#' - **Variables**:
#'   - Shows input variables (`M_C1`, `M_C2`, `Y_C1`, `Y_C2`) and computed variables like `Ydiff`, `Mdiff`, and `Mavg`.
#'   - Reports the sample size used in the analysis.
#'
#' - **Model Fit Indices**:
#'   - Displays SEM fit indices (e.g., Chi-square, CFI, TLI, RMSEA, SRMR) to assess model quality.
#'
#' - **Regression Paths and Variance Estimates**:
#'   - Summarizes path coefficients, intercepts, variances, and confidence intervals.
#'
#' - **Effects**:
#'   - Reports total, direct, and indirect effects with their significance.
#'   - Highlights pairwise contrasts between indirect effects for mediation paths.
#'
#' - **Moderation Effects**:
#'   - Provides moderation results for identified variables with corresponding coefficients and paths.
#'
#' - **Monte Carlo Confidence Intervals**:
#'   - Includes results for raw and standardized estimates obtained using methods such as MI or FIML.
#'
#' - **Diagnostics**:
#'   - Summarizes analysis parameters like bootstrapping, imputation settings, Monte Carlo iterations, and random seeds.
#'
#' @param x A \code{wsMed} object containing the results of within-subject mediation analysis.
#' @param level Numeric. Confidence level for the intervals (default = 0.95).
#' @param digits Numeric. Number of digits to display in the results.
#' @param ... Additional arguments (not used currently).
#'
#' @return Invisibly returns the input \code{wsMed} object for further use.
#'
#' @seealso \code{\link{wsMed}}, \code{\link[lavaan]{sem}}, \code{\link[semhelpinghands]{standardizedSolution_boot_ci}}
#'
#' @examples
#' # Example dataset with missing values
#' data(example_data)
#' set.seed(123)
#' example_dataN <- mice::ampute(
#'   data = example_data,
#'   prop = 0.1
#' )$amp
#'
#' # Perform within-subject mediation analysis
#' result1 <- wsMed(
#'   data = example_dataN,
#'   M_C1 = c("A1", "B1"),
#'   M_C2 = c("A2", "B2"),
#'   Y_C1 = "C1",
#'   Y_C2 = "C2",
#'   form = "P",
#'   Na = "DE",
#'   standardized = FALSE,
#'   bootstrap = 100
#' )
#'
#' # Print the results
#' print(result1)
#' 
#' @importFrom stats quantile sd
#' @importFrom knitr kable
#' @export


print.wsMed <- function(x, level = 0.95,digits=3, ...) {

  print_table_dynamic <- function(data, digits_local = digits, width = 10) {
    # 动态设置 columns_per_row
    columns_per_row <- ifelse(digits_local <= 4, 9, 7)

    # 确保数据是数据框格式
    data <- as.data.frame(data)

    # 获取总列数
    total_columns <- ncol(data)
    current_col <- 1

    # 循环按列分块打印
    while (current_col <= total_columns) {
      # 当前需要打印的列范围
      sub_data <- data[, current_col:min(current_col + columns_per_row - 1, total_columns), drop = FALSE]

      # 格式化当前子集的数值列
      numeric_cols <- sapply(sub_data, is.numeric)
      sub_data[numeric_cols] <- lapply(sub_data[numeric_cols], function(col) {
        formatC(col, format = "f", digits = digits_local, width = width, flag = " ")
      })

      # 强制将所有列转为字符，以确保对齐效果
      sub_data[] <- lapply(sub_data, as.character)

      # 打印当前子集表格
      print(knitr::kable(sub_data, align = rep("r", ncol(sub_data)), row.names = FALSE))

      # 更新当前列索引
      current_col <- current_col + columns_per_row
    }
  }
  print_table_dynamic2 <- function(data, digits_local = digits, width = 10) {
    # 动态设置 columns_per_row
    columns_per_row <- ifelse(digits_local <= 4, 9, 6)

    # 确保数据是数据框格式
    data <- as.data.frame(data)

    # 获取总列数
    total_columns <- ncol(data)
    current_col <- 1

    # 循环按列分块打印
    while (current_col <= total_columns) {
      # 当前需要打印的列范围
      sub_data <- data[, current_col:min(current_col + columns_per_row - 1, total_columns), drop = FALSE]

      # 格式化当前子集的数值列
      numeric_cols <- sapply(sub_data, is.numeric)
      sub_data[numeric_cols] <- lapply(sub_data[numeric_cols], function(col) {
        formatC(col, format = "f", digits = digits_local, width = width, flag = " ")
      })

      # 强制将所有列转为字符，以确保对齐效果
      sub_data[] <- lapply(sub_data, as.character)

      # 打印当前子集表格
      print(knitr::kable(sub_data, align = rep("r", ncol(sub_data)), row.names = FALSE))

      # 更新当前列索引
      current_col <- current_col + columns_per_row
    }
  }
  # 检查输入对象是否为 wsMed 类
  if (!inherits(x, "wsMed")) {
    stop("The input object must be of class 'wsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 变量部分
  if (!is.null(x$input_vars)) {
    input_vars <- x$input_vars
    original_vars <- list(
      Y = c(Y_C2 = input_vars$Y_C2, Y_C1 = input_vars$Y_C1),
      M = lapply(seq_along(input_vars$M_C1), function(i) {
        c(M_C2 = input_vars$M_C2[i], M_C1 = input_vars$M_C1[i])
      })
    )
    computed_vars <- data.frame(
      Variable = c("Ydiff", paste0("M", seq_along(input_vars$M_C1), "diff"), paste0("M", seq_along(input_vars$M_C1), "avg")),
      Formula = c(
        paste(original_vars$Y, collapse = " - "),
        sapply(seq_along(original_vars$M), function(i) paste(original_vars$M[[i]], collapse = " - ")),
        sapply(seq_along(original_vars$M), function(i) paste("(", paste(original_vars$M[[i]], collapse = " + "), ") / 2 Centered"))
      )
    )
    sample_size <- nrow(x$prepared_data)

    cat("\n*************** VARIABLES ***************\n")
    cat("Variables:\n")
    cat("Y = ", paste(original_vars$Y, collapse = " "), "\n")
    for (i in seq_along(original_vars$M)) {
      cat(paste0("M", i, " = "), paste(original_vars$M[[i]], collapse = " "), "\n")
    }
    cat("\nComputed Variables:\n")
    print_table_dynamic(computed_vars)
    cat("\nSample Size: ", sample_size, "\n")}
  confidence_level <- level * 100
  cat("Confidence Level: ", confidence_level, "%\n")

  # 如果没有模型拟合结果，退出函数
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # SEM 模型拟合指标
  param_estimates <- lavaan::parameterEstimates(fit, ci = TRUE, level = level)
  fit_measures <- lavaan::fitMeasures(fit, fit.measures = c(
    "chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"
  ))
  fit_indices <- data.frame(
    Measure = c("Chi-Square", "Degrees of Freedom", "p-Value",
                "CFI", "TLI", "RMSEA", "RMSEA Lower CI", "RMSEA Upper CI", "SRMR"),
    Value = c(
      fit_measures["chisq"],
      fit_measures["df"],
      fit_measures["pvalue"],
      fit_measures["cfi"],
      fit_measures["tli"],
      fit_measures["rmsea"],
      fit_measures["rmsea.ci.lower"],
      fit_measures["rmsea.ci.upper"],
      fit_measures["srmr"]
    )
  )
  cat("\n")
  cat("\n*************** MODEL FIT INDICES ***************\n")
  print_table_dynamic(fit_indices)

  # 回归路径部分
  regressions <- param_estimates[param_estimates$op == "~", ]
  if (nrow(regressions) > 0) {
    cat("\n*************** REGRESSION PATHS, INTERCEPTS AND VARIANCES ***************\n")

    # 创建新的 "Path" 列，合并 Outcome 和 Predictor
    regression_table <- data.frame(
      Path = paste(regressions$lhs, "~", regressions$rhs),  # 使用箭头符号合并
      Label = regressions$label,
      Estimate = regressions$est,
      SE = regressions$se,
      z = regressions$z,
      `P-value` = regressions$pvalue,
      LLCI = regressions$ci.lower,
      ULCI = regressions$ci.upper
    )

    # 打印表格
    print_table_dynamic2(regression_table)
  }

  # 截距部分
  intercepts <- param_estimates[param_estimates$op == "~1", ]
  if (nrow(intercepts) > 0) {
    intercept_table <- data.frame(
      Intercept = paste0(intercepts$lhs, "~1"),
      Label = intercepts$label,
      Estimate = intercepts$est,
      SE = intercepts$se,
      z = intercepts$z,
      `P-value` = intercepts$pvalue,
      LLCI = intercepts$ci.lower,
      ULCI = intercepts$ci.upper
    )
    print_table_dynamic2(intercept_table)
  }

  # 方差部分
  variances <- param_estimates[param_estimates$op == "~~" & param_estimates$lhs == param_estimates$rhs, ]
  if (nrow(variances) > 0) {
    variance_table <- data.frame(
      Variance = paste0(variances$lhs, "~~", variances$rhs),
      Estimate = variances$est,
      SE = variances$se,
      z = variances$z,
      `P-value` = variances$pvalue,
      LLCI = variances$ci.lower,
      ULCI = variances$ci.upper
    )
    print_table_dynamic(variance_table)
  }

  # 总效应和直接效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  direct_effect <- param_estimates[param_estimates$lhs == "Ydiff" & param_estimates$op == "~1", ]

  # 合并两个表格
  combined_effects <- data.frame(
    Name = c(if (nrow(total_effect) > 0) "Total effect" else NULL,
             if (nrow(direct_effect) > 0) "Direct effect" else NULL),
    Effect = c(if (nrow(total_effect) > 0) total_effect$est else NULL,
               if (nrow(direct_effect) > 0) direct_effect$est else NULL),
    SE = c(if (nrow(total_effect) > 0) total_effect$se else NULL,
           if (nrow(direct_effect) > 0) direct_effect$se else NULL),
    z = c(if (nrow(total_effect) > 0) total_effect$z else NULL,
          if (nrow(direct_effect) > 0) direct_effect$z else NULL),
    p = c(if (nrow(total_effect) > 0) total_effect$pvalue else NULL,
          if (nrow(direct_effect) > 0) direct_effect$pvalue else NULL),
    LLCI = c(if (nrow(total_effect) > 0) total_effect$ci.lower else NULL,
             if (nrow(direct_effect) > 0) direct_effect$ci.lower else NULL),
    ULCI = c(if (nrow(total_effect) > 0) total_effect$ci.upper else NULL,
             if (nrow(direct_effect) > 0) direct_effect$ci.upper else NULL)
  )

  # 打印合并后的表格
  if (nrow(combined_effects) > 0) {
    cat("\n")
    cat("\n*************** TOTAL AND DIRECT EFFECT ***************\n")
    print_table_dynamic(combined_effects)
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
    print_table_dynamic(combined_effects)
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
    print_table_dynamic(contrast_table)
  }

  # Moderation Effects
  moderation_effects <- param_estimates[
    param_estimates$rhs %in% grep("M\\davg", colnames(x$prepared_data), value = TRUE) &
      grepl("^d", param_estimates$label),
  ]
  if (nrow(moderation_effects) > 0) {
    cat("\n")
    cat("\n*************** MODERATION EFFECTS of X ***************\n")
    moderation_table <- data.frame(
      Name = moderation_effects$label,
      Effect = moderation_effects$est,
      SE = moderation_effects$se,
      z = moderation_effects$z,
      p = moderation_effects$pvalue,
      LLCI = moderation_effects$ci.lower,
      ULCI = moderation_effects$ci.upper
    )
    print_table_dynamic(moderation_table)
  }

  # Moderation Effects Key
  if (!is.null(x$prepared_data)) {
    Mavg_vars <- grep("M\\davg", colnames(x$prepared_data), value = TRUE)
    Mdiff_vars <- grep("M\\ddiff", colnames(x$prepared_data), value = TRUE)
    moderation_key <- data.frame()

    # Add all moderation effects based on labels starting with "d"
    d_labels <- grep("^d", param_estimates$label, value = TRUE)
    for (label in d_labels) {
      if (nchar(label) == 2) {
        # Single moderation effects (e.g., d1, d2, ...)
        index <- as.numeric(substr(label, 2, 2))
        if (!is.na(index) && index <= length(Mdiff_vars)) {
          moderation_key <- rbind(moderation_key, data.frame(
            Coefficient = label,
            Path = paste0(Mdiff_vars[index], " -> Ydiff")
          ))
        }
      } else if (nchar(label) > 2) {
        # Cross-variable moderation effects (e.g., d12, d23, ...)
        indices <- as.numeric(unlist(strsplit(substr(label, 2, nchar(label)), split = "")))
        if (all(!is.na(indices)) && all(indices <= length(Mdiff_vars)) && length(indices) == 2) {
          moderation_key <- rbind(moderation_key, data.frame(
            Coefficient = label,
            Path = paste0(Mdiff_vars[indices[1]], " -> ", Mdiff_vars[indices[2]])
          ))
        }
      }
    }

    if (nrow(moderation_key) > 0) {
      print(kable(moderation_key, align = c("c", "c"), row.names = FALSE))
    }
  }


  # 前后测系数对比
  pre_post_coeff <- param_estimates[grep("^X[01]_b", param_estimates$lhs), ]
  if (nrow(pre_post_coeff) > 0) {
    cat("\n")
    cat("\n*************** C1-C2 COEFFICIENTS ***************\n")
    prepost_table <- data.frame(
      Name = pre_post_coeff$lhs,
      Effect = pre_post_coeff$est,
      SE = pre_post_coeff$se,
      z = pre_post_coeff$z,
      p = pre_post_coeff$pvalue,
      LLCI = pre_post_coeff$ci.lower,
      ULCI = pre_post_coeff$ci.upper
    )
    print_table_dynamic(prepost_table)
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

    #cat("\n*************** C1-C2 COEFFICIENTS KEY ***************\n")
    print(kable(pre_post_key, align = c("c", "c"), row.names = FALSE))
  }


  # Analysis Notes and Warnings
  if (!is.null(fit) && !is.null(x$Na) && x$Na == "DE") {
    bootstrap_info <- list(
      method = if (!is.null(fit@Options$se) && fit@Options$se == "bootstrap") {
        "Percentile bootstrap"
      } else {
        "Not bootstrap"
      },
      num_samples = if (!is.null(fit@Options$bootstrap)) fit@Options$bootstrap else NA
    )
    cat("\n")
    cat("\n*************** Bootstrapping NOTES ***************\n")
    cat("\n")
    cat("Bootstrap confidence interval method used: ", bootstrap_info$method, "\n")
    if (!is.na(bootstrap_info$num_samples)) {
      cat("Number of bootstrap samples: ", bootstrap_info$num_samples, "\n")
    }
    cat("Confidence level: ", level * 100, "%\n")
    if (!is.null(x$iseed)) {
      cat("Random seed used: ", x$iseed, "\n")
    }
  }

  # mi_result Section
  if (!is.null(x$mi_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (MI) ***************\n")
    # 提取 alpha 参数
    alpha <- x$alpha  # 假设在 wsMed 输出中包含 alpha 参数
    if (is.null(alpha)) {
      stop("The 'alpha' parameter is missing from the wsMed object.")
    }

    # 动态生成置信区间的概率值
    lower_bounds <- alpha / 2
    upper_bounds <- 1 - lower_bounds
    ci.levels <- sort(c(lower_bounds, upper_bounds))  # 确保排序

    mi_result <- x$mi_result

    if (!is.null(mi_result$thetahat$est) && !is.null(mi_result$thetahatstar)) {
      # 提取参数估计
      estimates <- mi_result$thetahat$est
      param_names <- names(estimates)

      # 修改参数名称
      param_names <- gsub("^cp$", "direct effect", param_names)                     # 替换 cp 为 Direct effect
      param_names <- gsub("^total_effect$", "total effect", param_names)           # 替换 total_effect 为 Total effect
      param_names <- gsub("^indirect", "ind", param_names)                         # 替换 indirect 为 ind
      param_names <- gsub("^total_indirect$", "total ind", param_names)            # 替换 total_indirect 为 total ind
      param_names <- gsub("^CI(\\d+)vs(\\d+)$", "ind\\1-ind\\2", param_names)      # 替换 CI1vs2 为 ind1-ind2

      # 更新参数名称到 thetahatstar
      colnames(mi_result$thetahatstar) <- param_names

      # 使用 thetahatstar 计算所有的置信区间百分位数
      thetahatstar <- mi_result$thetahatstar

      # 计算置信区间值
      ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
      ci.names <- paste0(sprintf("%.1f", pmin(pmax(ci.levels * 100, 0.1), 99.9)), "%")
      rownames(ci.values) <- ci.names

      # 提取标准误
      se <- apply(thetahatstar, 2, sd)
      R <- nrow(thetahatstar)

      # 构建结果表
      result_table <- data.frame(
        Parameter = param_names,
        Estimate = estimates,
        SE = se
      )

      # 添加动态生成的置信区间列
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      colnames(ci.columns) <- ci.names
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print_table_dynamic(result_table)
    }
  }
  if (!is.null(x$fiml_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (FIML) ***************\n")
    # 提取 alpha 参数
    alpha <- x$alpha  # 假设在 wsMed 输出中包含 alpha 参数
    if (is.null(alpha)) {
      stop("The 'alpha' parameter is missing from the wsMed object.")
    }

    # 动态生成置信区间的概率值
    lower_bounds <- alpha / 2
    upper_bounds <- 1 - lower_bounds
    ci.levels <- sort(c(lower_bounds, upper_bounds))  # 确保排序

    fiml_result <- x$fiml_result

    if (!is.null(fiml_result$thetahat$est) && !is.null(fiml_result$thetahatstar)) {
      # 提取参数估计
      estimates <- fiml_result$thetahat$est
      param_names <- names(estimates)

      # 修改参数名称
      param_names <- gsub("^cp$", "direct effect", param_names)                     # 替换 cp 为 Direct effect
      param_names <- gsub("^total_effect$", "total effect", param_names)           # 替换 total_effect 为 Total effect
      param_names <- gsub("^indirect", "ind", param_names)                         # 替换 indirect 为 ind
      param_names <- gsub("^total_indirect$", "total ind", param_names)            # 替换 total_indirect 为 total ind
      param_names <- gsub("^CI(\\d+)vs(\\d+)$", "ind\\1-ind\\2", param_names)      # 替换 CI1vs2 为 ind1-ind2

      # 更新参数名称到 thetahatstar
      colnames(fiml_result$thetahatstar) <- param_names

      # 使用 thetahatstar 计算所有的置信区间百分位数
      thetahatstar <- fiml_result$thetahatstar

      # 计算置信区间值
      ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
      ci.names <- paste0(sprintf("%.1f", pmin(pmax(ci.levels * 100, 0.1), 99.9)), "%")
      rownames(ci.values) <- ci.names

      # 提取标准误
      se <- apply(thetahatstar, 2, sd)
      R <- nrow(thetahatstar)

      # 构建结果表
      result_table <- data.frame(
        Parameter = param_names,
        Estimate = estimates,
        SE = se
      )

      # 添加动态生成的置信区间列
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      colnames(ci.columns) <- ci.names
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print_table_dynamic(result_table)
    }
  }
  if (!is.null(x$std_result)) {
    cat("\n")
    cat("\n*************** STANDARDIZED RESULTS ***************\n")

    if (level == 0.95){std_result <- x$std_result} else {
      std_result <- semhelpinghands::standardizedSolution_boot_ci(fit,level =level)}

    alphastd <- x$alphastd  # 提取 alphastd
    lower_bound <- alphastd / 2
    upper_bound <- 1 - lower_bound

    # 提取并重命名参数名称
    std_result$label <- gsub("^cp$", "Direct effect", std_result$label)                     # 替换 cp 为 Direct effect
    std_result$label <- gsub("^total_effect$", "Total effect", std_result$label)           # 替换 total_effect 为 Total effect
    std_result$label <- gsub("^indirect", "ind", std_result$label)                         # 替换 indirect 为 ind
    std_result$label <- gsub("^total_indirect$", "total ind", std_result$label)            # 替换 total_indirect 为 total ind
    std_result$label <- gsub("^CI(\\d+)vs(\\d+)$", "ind\\1-ind\\2", std_result$label)      # 替换 CI1vs2 为 ind1-ind2

    # 检查并生成新的 label
    std_result$label <- ifelse(
      is.na(std_result$label) | std_result$label == "",
      paste(std_result$lhs, std_result$op, std_result$rhs, sep = " "),
      std_result$label
    )

    # 删除 lhs, op, rhs 列
    result_table <- std_result[, !(names(std_result) %in% c("lhs", "op", "rhs", "se", "ci.lower", "ci.upper"))]

    # 重命名列
    colnames(result_table) <- c(
      "Label", "Estimate (Std)", "Z", "P-value",
      "LLCI", "ULCI", "Boot SE"
    )


    # 打印表格，确保列对齐
    print_table_dynamic(result_table)
  }
  if (!is.null(x$std_fiml_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")

    # 提取 alphastd 参数
    alphastd <- x$alphastd  # 假设在 wsMed 输出中包含 alphastd 参数
    if (is.null(alphastd)) {
      stop("The 'alphastd' parameter is missing from the wsMed object.")
    }

    # 动态生成置信区间的概率值
    lower_bounds <- alphastd / 2
    upper_bounds <- 1 - lower_bounds
    ci.levels <- sort(c(lower_bounds, upper_bounds))  # 确保排序

    # 提取标准化结果
    std_fiml_estimates <- x$std_fiml_result$thetahat$est
    parameter_names <- names(std_fiml_estimates)
    thetahatstar <- x$std_fiml_result$thetahatstar

    # Align estimates with Monte Carlo results
    common_parameters <- intersect(parameter_names, colnames(thetahatstar))
    std_fiml_estimates <- std_fiml_estimates[common_parameters]
    thetahatstar <- thetahatstar[, common_parameters, drop = FALSE]

    # Replace parameter names
    common_parameters_replaced <- gsub("^cp$", "direct effect", common_parameters)                     # 替换 cp 为 Direct effect
    common_parameters_replaced <- gsub("^total_effect$", "total effect", common_parameters_replaced)   # 替换 total_effect 为 Total effect
    common_parameters_replaced <- gsub("^indirect", "ind", common_parameters_replaced)                 # 替换 indirect 为 ind
    common_parameters_replaced <- gsub("^total_indirect$", "total ind", common_parameters_replaced)    # 替换 total_indirect 为 total ind
    common_parameters_replaced <- gsub("^CI(\\d+)vs(\\d+)$", "ind\\1-ind\\2", common_parameters_replaced)  # 替换 CI1vs2 为 ind1-ind2

    # Ensure names align
    colnames(thetahatstar) <- common_parameters_replaced

    # Calculate confidence intervals
    ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
    ci.names <- paste0(sprintf("%.1f", pmin(pmax(ci.levels * 100, 0.1), 99.9)), "%")
    rownames(ci.values) <- ci.names

    # Calculate standard errors
    se <- apply(thetahatstar, 2, sd)

    # 构建结果表
    result_table <- data.frame(
      Parameter = common_parameters_replaced,
      Estimate = std_fiml_estimates,
      SE = se,
      check.names = FALSE  # 防止列名自动更改
    )

    # 动态添加置信区间列
    ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
    colnames(ci.columns) <- ci.names
    result_table <- cbind(result_table, ci.columns)

    # 打印表格
    print_table_dynamic(result_table)
  }
  if (!is.null(x$std_mi_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")

    # 提取 alphastd 参数
    alphastd <- x$alphastd  # 假设在 wsMed 输出中包含 alphastd 参数
    if (is.null(alphastd)) {
      stop("The 'alphastd' parameter is missing from the wsMed object.")
    }

    # 动态生成置信区间的概率值
    lower_bounds <- alphastd / 2
    upper_bounds <- 1 - lower_bounds
    ci.levels <- sort(c(lower_bounds, upper_bounds))  # 确保排序

    # 提取标准化结果
    std_mi_estimates <- x$std_mi_result$thetahat$est
    parameter_names <- names(std_mi_estimates)
    thetahatstar <- x$std_mi_result$thetahatstar

    # Align estimates with Monte Carlo results
    common_parameters <- intersect(parameter_names, colnames(thetahatstar))
    std_mi_estimates <- std_mi_estimates[common_parameters]
    thetahatstar <- thetahatstar[, common_parameters, drop = FALSE]

    # Replace parameter names
    common_parameters_replaced <- gsub("^cp$", "direct effect", common_parameters)                     # 替换 cp 为 Direct effect
    common_parameters_replaced <- gsub("^total_effect$", "total effect", common_parameters_replaced)   # 替换 total_effect 为 Total effect
    common_parameters_replaced <- gsub("^indirect", "ind", common_parameters_replaced)                 # 替换 indirect 为 ind
    common_parameters_replaced <- gsub("^total_indirect$", "total ind", common_parameters_replaced)    # 替换 total_indirect 为 total ind
    common_parameters_replaced <- gsub("^CI(\\d+)vs(\\d+)$", "ind\\1-ind\\2", common_parameters_replaced)  # 替换 CI1vs2 为 ind1-ind2

    # Ensure names align
    colnames(thetahatstar) <- common_parameters_replaced

    # Calculate confidence intervals
    ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
    ci.names <- paste0(sprintf("%.1f", pmin(pmax(ci.levels * 100, 0.1), 99.9)), "%")
    rownames(ci.values) <- ci.names

    # Calculate standard errors
    se <- apply(thetahatstar, 2, sd)

    # 构建结果表
    result_table <- data.frame(
      Parameter = common_parameters_replaced,
      Estimate = std_mi_estimates,
      SE = se,
      check.names = FALSE  # 防止列名自动更改
    )

    # 动态添加置信区间列
    ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
    colnames(ci.columns) <- ci.names
    result_table <- cbind(result_table, ci.columns)

    print_table_dynamic(result_table)

  }

  # Monte Carlo Notes
  if (!is.null(x$mi_result) || !is.null(x$fiml_result)){
    if (!is.null(x$paras)) {
      cat("\n")
      cat("\n*************** IMPUTATION AND MONTE CARLO NOTES ***************\n")
      cat("\n")
      paras <- x$paras  # 提取参数列表
      if (!is.null(x$mi_result)){cat("Number of imputations (m): ", paras$m, "\n")}
      if (!is.null(x$mi_result)){cat("Imputation method: ", paras$method, "\n")}
      cat("Random seed: ", paras$seed, "\n")
      cat("Number of Monte Carlo repetitions (R): ", R, "\n")
      cat("Decomposition method for covariance matrices: ", paras$decomposition, "\n")
      cat("Check positive definiteness of covariance matrices: ", ifelse(paras$pd, "Yes", "No"), "\n")
      cat("Tolerance for positive definiteness checks : ", paras$tol, "\n")
      cat("Significance levels for confidence intervals: ", paste(paras$alpha, collapse = ", "), "\n")
      if (!is.null(x$std_mi_result) || !is.null(x$std_fiml_result)){cat("Significance levels for standardized confidence intervals: ", paste(paras$alphastd, collapse = ", "), "\n")}
    }
  }

  # 返回对象
  invisible(x)
}
