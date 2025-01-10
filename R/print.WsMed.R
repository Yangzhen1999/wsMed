#' @title Print Method for WsMed Objects
#'
#' @description Provides a detailed summary of the results from a \code{WsMed} object, including
#' variables, model fit indices, regression paths, total, direct, and indirect effects,
#' contrast effects, moderation effects, and Monte Carlo confidence intervals (if applicable).
#' It also generates diagnostic information and analysis notes for further interpretation.
#'
#' @details This function is specifically designed to display results from the within-subject mediation
#' analysis conducted using the \code{WsMed} function. Key features include:
#'
#' - **Variables**: Displays input variables, computed variables, and sample size.
#' - **Model Fit Indices**: Includes common SEM fit indices like chi-square, CFI, TLI, RMSEA, and SRMR.
#' - **Regression Paths**: Summarizes regression paths, intercepts, and variances with estimates and confidence intervals.
#' - **Effects**:
#'   - Total, direct, and indirect effects.
#'   - Contrast effects for pairwise comparisons of indirect effects.
#' - **Moderation Effects**: Displays effects related to moderator variables.
#' - **Monte Carlo Confidence Intervals**: Provides detailed Monte Carlo results for both raw and standardized estimates.
#' - **Diagnostic Notes**: Summarizes bootstrapping, imputation, and Monte Carlo settings used in the analysis.
#'
#' The output is formatted for readability and includes dynamic confidence intervals, moderation keys,
#' and pre-post coefficients.
#'
#' @param x A \code{WsMed} object containing results of within-subject mediation analysis.
#' @param level Numeric. Confidence level for the intervals (default = 0.95).
#' @param ... Additional arguments (not used currently).
#'
#' @return Invisibly returns the input \code{WsMed} object.
#'
#' @seealso \code{\link{WsMed}}, \code{\link[lavaan]{sem}}, \code{\link[semhelpinghands]{standardizedSolution_boot_ci}}
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
#' result1 <- WsMed(
#'   data = example_dataN,
#'   M_before = c("A1", "B1"),
#'   M_after = c("A2", "B2"),
#'   Y_before = "C1",
#'   Y_after = "C2",
#'   form = "P",
#'   Na = "MI",
#'   standardized = TRUE,
#'   bootstrap = 1000,
#'   iseed = 123,
#'   se = "boot",
#'   R = 20000L,  # Monte Carlo repetitions
#'   alpha = c(0.001, 0.01, 0.05),  # Significance levels
#'   m = 5,  # Number of imputations
#'   method = "pmm",  # Imputation method
#'   decomposition = "eigen",
#'   pd = TRUE,
#'   tol = 1e-06,
#'   seed = 123,
#'   alphastd = c(0.001, 0.01, 0.05)
#' )
#'
#' # Print the results
#' print(result1)
#'
#' @importFrom stats quantile sd
#' @importFrom knitr kable
#' @export

print.WsMed <- function(x, level = 0.95, ...) {
  # 检查输入对象是否为 WsMed 类
  if (!inherits(x, "WsMed")) {
    stop("The input object must be of class 'WsMed'.")
  }

  # 提取 lavaan_fit
  fit <- x$lavaan_fit

  # 变量部分
  if (!is.null(x$input_vars)) {
    input_vars <- x$input_vars
    original_vars <- list(
      Y = c(Y_after = input_vars$Y_after, Y_before = input_vars$Y_before),
      M = lapply(seq_along(input_vars$M_before), function(i) {
        c(M_after = input_vars$M_after[i], M_before = input_vars$M_before[i])
      })
    )
    computed_vars <- data.frame(
      Variable = c("Ydiff", paste0("M", seq_along(input_vars$M_before), "diff"), paste0("M", seq_along(input_vars$M_before), "avg")),
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
    print(kable(computed_vars, align = c("l", "l"), row.names = FALSE))
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
  print(kable(fit_indices, align = c("l", "r"), row.names = FALSE))

  # 回归路径部分
  regressions <- param_estimates[param_estimates$op == "~", ]
  if (nrow(regressions) > 0) {
    cat("\n*************** REGRESSION PATHS, INTERCEPTS AND VARIANCES ***************\n")
    regression_table <- data.frame(
      Outcome = regressions$lhs,
      Predictor = regressions$rhs,
      Label = regressions$label,
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
    print(kable(
      intercept_table,
      align = c("l", "l", "r", "r", "r", "r", "r", "r"),
      row.names = FALSE
    ))
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
    print(kable(
      variance_table,
      align = c("l", "r", "r", "r", "r", "r", "r"),
      row.names = FALSE
    ))
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
    print(kable(combined_effects, align = c("c", "c", "c", "c", "c", "c", "c"), row.names = FALSE))
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
    alpha <- x$alpha  # 假设在 WsMed 输出中包含 alpha 参数
    if (is.null(alpha)) {
      stop("The 'alpha' parameter is missing from the WsMed object.")
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
        SE = se,
        R = R
      )

      # 添加动态生成的置信区间列
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      colnames(ci.columns) <- ci.names
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print(kable(result_table, align = c("l", "r", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
    } else {
      warning("mi_result does not contain necessary components for Monte Carlo confidence intervals.")
    }
  }

  if (!is.null(x$fiml_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (FIML) ***************\n")
    # 提取 alpha 参数
    alpha <- x$alpha  # 假设在 WsMed 输出中包含 alpha 参数
    if (is.null(alpha)) {
      stop("The 'alpha' parameter is missing from the WsMed object.")
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
        SE = se,
        R = R
      )

      # 添加动态生成的置信区间列
      ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
      colnames(ci.columns) <- ci.names
      result_table <- cbind(result_table, ci.columns)

      # 打印表格
      print(kable(result_table, align = c("l", "r", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
    } else {
      warning("fiml_result does not contain necessary components for Monte Carlo confidence intervals.")
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
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")

    # 提取 alphastd 参数
    alphastd <- x$alphastd  # 假设在 WsMed 输出中包含 alphastd 参数
    if (is.null(alphastd)) {
      stop("The 'alphastd' parameter is missing from the WsMed object.")
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
      R = nrow(thetahatstar),
      check.names = FALSE  # 防止列名自动更改
    )

    # 动态添加置信区间列
    ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
    colnames(ci.columns) <- ci.names
    result_table <- cbind(result_table, ci.columns)

    # 打印表格
    print(kable(result_table, align = c("l", "r", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
  }
  if (!is.null(x$std_mi_result)) {
    cat("\n")
    cat("\n*************** MONTE CARLO CONFIDENCE INTERVALS (STANDARDIZED) ***************\n")

    # 提取 alphastd 参数
    alphastd <- x$alphastd  # 假设在 WsMed 输出中包含 alphastd 参数
    if (is.null(alphastd)) {
      stop("The 'alphastd' parameter is missing from the WsMed object.")
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
      R = nrow(thetahatstar),
      check.names = FALSE  # 防止列名自动更改
    )

    # 动态添加置信区间列
    ci.columns <- as.data.frame(t(ci.values))  # 转置为列格式
    colnames(ci.columns) <- ci.names
    result_table <- cbind(result_table, ci.columns)

    # 打印表格
    print(kable(result_table, align = c("l", "r", "r", "r", rep("r", ncol(ci.columns))), row.names = FALSE))
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
