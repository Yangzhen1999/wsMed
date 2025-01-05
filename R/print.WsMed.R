# 定义 print.WsMed 方法
print.WsMed <- function(x, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # Variables Section
  if (!is.null(x$input_vars)) {
    # 从 WsMed 的返回值中提取变量名
    input_vars <- x$input_vars

    # 原始变量名称
    original_vars <- list(
      Y = c(Y_after = input_vars$Y_after, Y_before = input_vars$Y_before),
      M = lapply(seq_along(input_vars$M_before), function(i) {
        c(M_after = input_vars$M_after[i], M_before = input_vars$M_before[i])
      })
    )

    # 计算的变量信息
    computed_vars <- data.frame(
      Variable = c("Ydiff", paste0("M", seq_along(input_vars$M_before), "diff"), paste0("M", seq_along(input_vars$M_before), "avg")),
      Formula = c(
        paste(original_vars$Y, collapse = " - "),
        sapply(seq_along(original_vars$M), function(i) {
          paste(original_vars$M[[i]], collapse = " - ")
        }),
        sapply(seq_along(original_vars$M), function(i) {
          paste("(", paste(original_vars$M[[i]], collapse = " + "), ") / 2 Centered")
        })
      )
    )

    # 样本大小
    sample_size <- nrow(x$prepared_data)

    # 打印变量部分
    cat("\n*************** VARIABLES ***************\n")
    cat("Variables:\n")
    cat("Y = ", paste(original_vars$Y, collapse = " "), "\n")
    for (i in seq_along(original_vars$M)) {
      cat(paste0("M", i, " = "), paste(original_vars$M[[i]], collapse = " "), "\n")
    }
    cat("\nComputed Variables:\n")
    print(kable(computed_vars, align = c("l", "l"), row.names = FALSE))
    cat("\nSample Size: ", sample_size, "\n")
  } else {
    warning("Input variable names (input_vars) are not available.")
  }


  # 检查是否存在模型拟合结果
  if (is.null(fit)) {
    cat("No model fitting results available.\n")
    return(invisible(x))
  }

  # 提取参数估计
  param_estimates <- lavaan::parameterEstimates(fit)

  # SEM Model Fit Indices Section
  if (!is.null(fit)) {
    fit_measures <- lavaan::fitMeasures(fit, fit.measures = c(
      "chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"
    ))

    # 构建拟合指标表格
    fit_indices <- data.frame(
      Measure = c("Chi-Square", "Degrees of Freedom", "p-Value",
                  "CFI", "TLI",
                  "RMSEA", "RMSEA Lower CI", "RMSEA Upper CI",
                  "SRMR"),
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

    # 打印拟合指标部分
    cat("\n*************** MODEL FIT INDICES ***************\n")
    print(kable(fit_indices, align = c("l", "r"), row.names = FALSE))
  }

  #regresssion

  if (!is.null(fit)) {
    # 提取参数估计
    param_estimates <- lavaan::parameterEstimates(fit)

    # 提取回归系数部分
    regressions <- param_estimates[param_estimates$op == "~", ]
    if (nrow(regressions) > 0) {
      cat("\n*************** REGRESSION PATHS ***************\n")
      regression_table <- data.frame(
        Outcome = regressions$lhs,
        Predictor = regressions$rhs,
        Label = regressions$label,  # 保留标签值
        Estimate = regressions$est,
        SE = regressions$se,
        z = regressions$z,
        `P-value` = regressions$pvalue,
        LLCI = regressions$ci.lower,
        ULCI = regressions$ci.upper
      )
      print(kable(
        regression_table,
        align = c("l", "l", "l", "r", "r", "r", "r", "r", "r"),
        row.names = FALSE
      ))
    }

    # 提取截距部分
    intercepts <- param_estimates[param_estimates$op == "~1", ]
    if (nrow(intercepts) > 0) {
      cat("\n*************** INTERCEPTS ***************\n")
      intercept_table <- data.frame(
        Intercept = paste0(intercepts$lhs, "~1"),
        Label = intercepts$label,  # 保留标签值
        Estimate = intercepts$est,
        SE = intercepts$se,
        z = intercepts$z,
        `P-value` = intercepts$pvalue,
        LLCI = intercepts$ci.lower,
        ULCI = intercepts$ci.upper
      )
      print(kable(
        intercept_table,
        align = c("l", "l", "r", "r", "r", "r", "r", "r"),
        row.names = FALSE
      ))
    }

    # 提取方差部分
    variances <- param_estimates[param_estimates$op == "~~" & param_estimates$lhs == param_estimates$rhs, ]
    if (nrow(variances) > 0) {
      cat("\n*************** VARIANCES ***************\n")
      variance_table <- data.frame(
        Variance = paste0(variances$lhs, "~~", variances$rhs),
        Estimate = variances$est,
        SE = variances$se,
        z = variances$z,
        `P-value` = variances$pvalue,
        LLCI = variances$ci.lower,
        ULCI = variances$ci.upper
      )
      print(kable(
        variance_table,
        align = c("l", "r", "r", "r", "r", "r", "r"),
        row.names = FALSE
      ))
    }
  }



  # 总效应
  total_effect <- param_estimates[param_estimates$lhs == "total_effect", ]
  if (nrow(total_effect) > 0) {
    cat("\n")
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

  # Analysis Notes and Warnings Section
  if (!is.null(fit)) {
    # 提取引导方法和相关信息
    bootstrap_info <- list(
      method = if (!is.null(fit@Options$se) && fit@Options$se == "bootstrap") {
        "Percentile bootstrap"
      } else {
        "Not bootstrap"
      },
      num_samples = if (!is.null(fit@Options$bootstrap)) fit@Options$bootstrap else NA,
      confidence_level = if (!is.null(fit@Options$level)) fit@Options$level * 100 else 95
    )

    # 打印 Analysis Notes and Warnings 部分
    cat("\n")
    cat("\n*************** ANALYSIS NOTES AND WARNINGS ***************\n")
    cat("\n")
    cat("Bootstrap confidence interval method used: ", bootstrap_info$method, "\n")
    if (!is.na(bootstrap_info$num_samples)) {
      cat("Number of bootstrap samples for bootstrap confidence intervals: ", bootstrap_info$num_samples, "\n")
    }
    cat("Level of confidence for all confidence intervals in output: ", bootstrap_info$confidence_level, "\n")
  }


  # mi_result Section
  if (!is.null(x$mi_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (multiple imputation) ***************\n")
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
      ci.levels <- c(0.005, 0.01, 0.025, 0.975, 0.99, 0.995)  # 可自行调整为需要的所有百分位数

      # 确保列顺序一致
      ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
      rownames(ci.values) <- paste0(ci.levels * 100, "%")

      # 提取标准误
      se <- apply(thetahatstar, 2, sd)
      R <- nrow(thetahatstar)
      # 构建结果表
      result_table <- data.frame(
        Parameter = param_names,
        Estimate = estimates,
        SE = se,
        R = R
      )
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print(kable(result_table, align = c("l", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
    } else {
      warning("mi_result does not contain necessary components for Monte Carlo confidence intervals.")
    }
  }

  if (!is.null(x$fiml_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (FIML) ***************\n")
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
      ci.levels <- c(0.005, 0.01, 0.025, 0.975, 0.99, 0.995)  # 可自行调整为需要的所有百分位数

      # 确保列顺序一致
      ci.values <- t(sapply(ci.levels, function(level) apply(thetahatstar, 2, quantile, probs = level)))
      rownames(ci.values) <- paste0(ci.levels * 100, "%")

      # 提取标准误
      se <- apply(thetahatstar, 2, sd)
      R <- nrow(thetahatstar)
      # 构建结果表
      result_table <- data.frame(
        Parameter = param_names,
        Estimate = estimates,
        SE = se,
        R = R
      )
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print(kable(result_table, align = c("l", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
    } else {
      warning("fiml_result does not contain necessary components for Monte Carlo confidence intervals.")
    }
  }

  if (!is.null(x$std_result)) {
     cat("\n")
     cat("\n*************** STANDARDIZED RESULTS ***************\n")

    std_result <- x$std_result

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
    result_table <- std_result[, !(names(std_result) %in% c("lhs", "op", "rhs"))]

    # 重命名列
    colnames(result_table) <- c(
      "Label", "Estimate (Std)", "SE", "Z", "P-value",
      "CI Lower", "CI Upper", "Boot CI Lower", "Boot CI Upper", "Boot SE"
    )


    # 打印表格，确保列对齐
    print(kable(
      result_table,
      align = c("l", "r", "r", "r", "r", "r", "r", "r", "r", "r"),
      row.names = FALSE,
      format = "pipe"
    ))
  }

  if (!is.null(x$std_fiml_result)) {
    cat("\n")
    cat("\n***************MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")
    # Extract standardized FIML results
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
    ci_lower <- apply(thetahatstar, 2, function(x) quantile(x, probs = 0.025))
    ci_upper <- apply(thetahatstar, 2, function(x) quantile(x, probs = 0.975))

    # Calculate standard errors
    se <- apply(thetahatstar, 2, sd)

    # Construct result table
    result_table <- data.frame(
      Parameter = common_parameters_replaced,
      est = std_fiml_estimates,
      se = se,
      R = nrow(thetahatstar),
      `2.5%` = ci_lower,
      `97.5%` = ci_upper,
      check.names = FALSE  # 防止列名自动更改
    )

    # Print table in the desired format
    print(kable(result_table, align = c("l", "r", "r", "r", "r", "r"), row.names = FALSE))
  }

  if (!is.null(x$std_mi_result)) {
    cat("\n")
    cat("\n***************MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")
    # Extract standardized MIL results
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
    ci_lower <- apply(thetahatstar, 2, function(x) quantile(x, probs = 0.025))
    ci_upper <- apply(thetahatstar, 2, function(x) quantile(x, probs = 0.975))

    # Calculate standard errors
    se <- apply(thetahatstar, 2, sd)

    # Construct result table
    result_table <- data.frame(
      Parameter = common_parameters_replaced,
      est = std_mi_estimates,
      se = se,
      R = nrow(thetahatstar),
      `2.5%` = ci_lower,
      `97.5%` = ci_upper,
      check.names = FALSE  # 防止列名自动更改
    )

    # Print table in the desired format
    print(kable(result_table, align = c("l", "r", "r", "r", "r", "r"), row.names = FALSE))
  }
  # 返回原始对象
  invisible(x)
}
