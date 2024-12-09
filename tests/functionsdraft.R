test_that("draft", {
  skip("This test is skipped for demonstration purposes")


GenerateModelP <- function(prepared_data) {
  # 提取生成的变量名称
  Mdiff_vars <- grep("M\\ddiff", colnames(prepared_data), value = TRUE)
  Mavg_vars <- grep("M\\davg", colnames(prepared_data), value = TRUE)

  regression_y <- paste(
    "Ydiff ~ cp*1",  # 截距部分
    paste(
      c(
        paste0("b", seq_along(Mdiff_vars), "*", Mdiff_vars),  # 动态生成每个 Mdiff 的回归系数
        paste0("d", seq_along(Mavg_vars), "*", Mavg_vars)    # 动态生成每个 Mavg 的回归系数
      ),
      collapse = " + "  # 用 " + " 拼接所有部分
    ),
    sep = " + "  # 确保 cp*1 和后续项之间有分隔符
  )

  # 2. 每个 Mdiff 的截距模型
  regression_m <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0(Mdiff_vars[i], " ~ a", i, "*1")
    }),
    collapse = "\n"
  )

  # 3. 每个间接效应公式
  indirect_effects <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0("indirect", i, " := a", i, " * b", i)
    }),
    collapse = "\n"
  )

  # 4. 总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(paste0("indirect", seq_along(Mdiff_vars)), collapse = " + ")
  )

  # 5. 总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 6. 间接效应的对比公式
  indirect_contrasts <- ""
  if (length(Mdiff_vars) > 1) {
    indirect_combinations <- combn(seq_along(Mdiff_vars), 2)
    indirect_contrasts <- paste(
      apply(indirect_combinations, 2, function(pair) {
        paste0(
          "CI", pair[1],"vs", pair[2],
          " := indirect", pair[1], " - indirect", pair[2]
        )
      }),
      collapse = "\n"
    )
  }

  # 7. 前后测系数
  pre_post_coefficients <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      x1_bi <- paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2")
      x0_bi <- paste0("X0_b", i, " := X1_b", i, " - d", i)
      paste(x1_bi, x0_bi, sep = "\n")
    }),
    collapse = "\n"
  )

  # 合并所有公式
  sem_model <- paste(
    regression_y,
    regression_m,
    indirect_effects,
    total_indirect,
    total_effect,
    indirect_contrasts,
    pre_post_coefficients,
    sep = "\n"
  )

  return(sem_model)
}
GenerateModelCN <- function(prepared_data) {
  # 提取生成的变量名称
  Mdiff_vars <- grep("M\\ddiff", colnames(prepared_data), value = TRUE)
  Mavg_vars <- grep("M\\davg", colnames(prepared_data), value = TRUE)
  n <- length(Mdiff_vars)

  if (n < 1) {
    stop("The function requires at least one mediator.")
  }

  # 1. 因变量 Ydiff 的回归方程
  regression_y <- paste(
    "Ydiff ~ cp*1",
    paste0(" + ", paste0("b", 1:n, "*", Mdiff_vars, collapse = " + ")),
    paste0(" + ", paste0("d", 1:n, "*", Mavg_vars, collapse = " + ")),
    sep = ""
  )

  # 2. 中介变量的回归方程
  regression_m <- c()
  for (i in 1:n) {
    if (i == 1) {
      # M1diff 只有截距项
      regression_m <- c(regression_m, paste(Mdiff_vars[i], "~ a1*1"))
    } else {
      # 其他中介变量的回归方程
      predictors <- c(
        paste0("a", i, "*1"),
        paste0("b", (i-1):1, i, "*", Mdiff_vars[(i-1):1], collapse = " + "),
        paste0("d", (i-1):1, i, "*", Mavg_vars[(i-1):1], collapse = " + ")
      )
      regression_m <- c(
        regression_m,
        paste(Mdiff_vars[i], "~", paste(predictors, collapse = " + "))
      )
    }
  }

  # 3. 动态生成间接效应公式
  generate_path_effects <- function(paths) {
    paste0(
      "a1 * ",  # 起点系数固定为 a1
      paste(
        sapply(1:(length(paths) - 1), function(i) {
          paste0("b", paths[i], paths[i + 1])  # 生成路径上的中介系数
        }),
        collapse = " * "
      )
    )
  }

  # 动态生成所有可能的间接路径
  indirect_effects <- c()
  indirect_effect_labels <- c()  # 保存所有间接效应的标签

  for (length_path in 1:n) {
    # 生成长度为 length_path 的所有路径组合
    path_combinations <- combn(1:n, length_path, simplify = FALSE)

    for (path in path_combinations) {
      if (length(path) > 1) {
        # 多步链式路径的间接效应
        effect_formula <- generate_path_effects(path)
        label <- paste0("indirect", paste(path, collapse = ""))  # 不加下划线
        indirect_effects <- c(
          indirect_effects,
          paste0(label, " := ", effect_formula)
        )
        indirect_effect_labels <- c(indirect_effect_labels, label)
      } else {
        # 单步间接效应
        label <- paste0("indirect", path)
        indirect_effects <- c(
          indirect_effects,
          paste0(label, " := a", path, " * b", path)
        )
        indirect_effect_labels <- c(indirect_effect_labels, label)
      }
    }
  }

  # 4. 更新的总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(indirect_effect_labels, collapse = " + ")
  )

  # 5. 总效应
  total_effect <- "total_effect := cp + total_indirect"
  print(indirect_effect_labels)

  # 6. 间接效应两两比较
  # 6. 间接效应两两比较
  # 6. 使用指定的命名规则生成间接效应的两两比较
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          # 使用自定义命名规则，例如 CInt1vs1_2_3
          short_label_i <- gsub("indirect", "", indirect_effect_labels[i])
          short_label_j <- gsub("indirect", "", indirect_effect_labels[j])
          comparisons <- c(
            comparisons,
            paste0(
              "CI", short_label_i, "vs", short_label_j,
              " := ", indirect_effect_labels[i], " - ", indirect_effect_labels[j]
            )
          )
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }

  print(compare_indirect_effect)

  # 7. 前后测系数
  pre_post_coefficients <- paste(
    c(
      # 直接路径
      sapply(seq_along(Mdiff_vars), function(i) {
        x1 <- paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2")
        x0 <- paste0("X0_b", i, " := X1_b", i, " - d", i)
        paste(x1, x0, sep = "\n")
      }),
      # 链式路径
      sapply(2:n, function(i) {
        paste0("X1_b", (i-1), i, " := (2*b", (i-1), i, " + d", (i-1), i, ")/2\n",
               "X0_b", (i-1), i, " := X1_b", (i-1), i, " - d", (i-1), i)
      })
    ),
    collapse = "\n"
  )

  # 合并所有公式
  sem_model <- paste(
    regression_y,
    paste(regression_m, collapse = "\n"),
    paste(indirect_effects, collapse = "\n"),
    total_indirect,
    total_effect,
    compare_indirect_effect,
    pre_post_coefficients,
    sep = "\n"
  )

  return(sem_model)
}
GenerateModelCP <- function(prepared_data) {
  # 提取链式中介和并行中介变量名称
  chain_var <- grep("M1diff", colnames(prepared_data), value = TRUE)
  parallel_vars <- setdiff(grep("M\\ddiff", colnames(prepared_data), value = TRUE), chain_var)
  chain_avg <- grep("M1avg", colnames(prepared_data), value = TRUE)
  parallel_avgs <- setdiff(grep("M\\davg", colnames(prepared_data), value = TRUE), chain_avg)

  if (length(chain_var) != 1) {
    stop("The chain mediator should contain exactly one variable: M1diff.")
  }

  n <- length(parallel_vars)  # 并行中介的数量

  # 1. 因变量 Ydiff 的回归方程
  regression_y <- paste(
    "Ydiff ~ cp*1 + b1*", chain_var,
    paste0(" + ", paste0("b", 2:(n + 1), "*", parallel_vars, collapse = " + ")),
    paste0(" + d1*", chain_avg),
    paste0(" + ", paste0("d", 2:(n + 1), "*", parallel_avgs, collapse = " + ")),
    sep = ""
  )

  # 2. 中介变量的回归方程
  regression_m <- c()
  for (i in seq_along(parallel_vars)) {
    regression_m <- c(
      regression_m,
      paste0(parallel_vars[i], " ~ a", i + 1, "*1 + b1", i + 1, "*", chain_var,
             " + d1", i + 1, "*", chain_avg)
    )
  }
  regression_m <- c(
    paste0(chain_var, " ~ a1*1"),  # 链式中介回归方程
    regression_m
  )

  # 3. 动态生成间接效应公式
  indirect_effects <- c()
  indirect_effect_labels <- c()

  # 链式路径的直接间接效应
  indirect_effects <- c(indirect_effects, paste0("indirect1 := a1 * b1"))
  indirect_effect_labels <- c(indirect_effect_labels, "indirect1")

  # 并行中介的直接间接效应
  for (i in seq_along(parallel_vars)) {
    label <- paste0("indirect", i + 1)
    formula <- paste0("a", i + 1, " * b", i + 1)
    indirect_effects <- c(indirect_effects, paste0(label, " := ", formula))
    indirect_effect_labels <- c(indirect_effect_labels, label)
  }

  # 链式路径间接效应
  for (i in seq_along(parallel_vars)) {
    label <- paste0("indirect1", i + 1)
    formula <- paste0("a1 * b1", i + 1, " * b", i + 1)
    indirect_effects <- c(indirect_effects, paste0(label, " := ", formula))
    indirect_effect_labels <- c(indirect_effect_labels, label)
  }

  # 总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(indirect_effect_labels, collapse = " + ")
  )

  # 总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 4. 间接效应两两比较
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          # 使用自定义命名规则，例如 CInt1vs1_2_3
          short_label_i <- gsub("indirect", "", indirect_effect_labels[i])
          short_label_j <- gsub("indirect", "", indirect_effect_labels[j])
          comparisons <- c(
            comparisons,
            paste0(
              "CI", short_label_i, "vs", short_label_j,
              " := ", indirect_effect_labels[i], " - ", indirect_effect_labels[j]
            )
          )
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }


  # 5. 前后测系数
  pre_post_coefficients <- paste(
    c(
      # 对于直接路径的前后测系数
      paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
      }),
      # 对于链式路径的前后测系数
      sapply(seq_along(parallel_vars), function(i) {
        paste0("X1_b1", i + 1, " := (2*b1", i + 1, " + d1", i + 1, ")/2\n",
               "X0_b1", i + 1, " := X1_b1", i + 1, " - d1", i + 1)
      })
    ),
    collapse = "\n"
  )

  # 合并所有公式
  sem_model <- paste(
    regression_y,
    paste(regression_m, collapse = "\n"),
    paste(indirect_effects, collapse = "\n"),
    total_indirect,
    total_effect,
    compare_indirect_effect,
    pre_post_coefficients,
    sep = "\n"
  )

  return(sem_model)
}
GenerateModelPC <- function(prepared_data) {
  # 提取链式中介和并行中介变量名称
  chain_var <- grep("M1diff", colnames(prepared_data), value = TRUE)
  parallel_vars <- setdiff(grep("M\\ddiff", colnames(prepared_data), value = TRUE), chain_var)
  chain_avg <- grep("M1avg", colnames(prepared_data), value = TRUE)
  parallel_avgs <- setdiff(grep("M\\davg", colnames(prepared_data), value = TRUE), chain_avg)

  if (length(chain_var) != 1) {
    stop("The chain mediator should contain exactly one variable: M1diff.")
  }

  n <- length(parallel_vars)  # 并行中介的数量

  # 1. 因变量 Ydiff 的回归方程
  regression_y <- paste(
    "Ydiff ~ cp*1",
    paste0(" + b", seq(2, n + 1), "*", parallel_vars, collapse = " + "),
    paste0(" + b1*", chain_var),
    paste0(" + d", seq(2, n + 1), "*", parallel_avgs, collapse = " + "),
    paste0(" + d1*", chain_avg),
    sep = ""
  )

  # 2. 中介变量的回归方程
  regression_m <- c()

  # 平行中介的回归方程（仅包含截距项）
  for (i in seq_along(parallel_vars)) {
    regression_m <- c(
      regression_m,
      paste0(parallel_vars[i], " ~ a", i + 1, "*1")
    )
  }

  # 链式中介的回归方程（接收所有平行中介的路径）
  chain_predictors <- c(
    paste0("b", seq(2, n + 1), "1*", parallel_vars),
    paste0("d", seq(2, n + 1), "1*", parallel_avgs)
  )
  regression_m <- c(
    paste0(chain_var, " ~ a1*1 + ", paste(chain_predictors, collapse = " + ")),
    regression_m
  )

  # 3. 动态生成间接效应公式
  indirect_effects <- c()
  indirect_effect_labels <- c()

  # 平行中介的直接间接效应（M2diff -> Ydiff, M3diff -> Ydiff, ...）
  for (i in seq_along(parallel_vars)) {
    label <- paste0("indirect", i + 1)
    formula <- paste0("a", i + 1, " * b", i + 1)
    indirect_effects <- c(indirect_effects, paste0(label, " := ", formula))
    indirect_effect_labels <- c(indirect_effect_labels, label)
  }

  # 链式路径的直接间接效应（M1diff -> Ydiff）
  indirect_effects <- c(indirect_effects, paste0("indirect1 := a1 * b1"))
  indirect_effect_labels <- c(indirect_effect_labels, "indirect1")

  # 平行中介 -> 链式中介 -> Ydiff（M2diff -> M1diff -> Ydiff, M3diff -> M1diff -> Ydiff, ...）
  for (i in seq_along(parallel_vars)) {
    label <- paste0("indirect", i + 1, "1")
    formula <- paste0("a", i + 1, " * b", i + 1, "1 * b1")
    indirect_effects <- c(indirect_effects, paste0(label, " := ", formula))
    indirect_effect_labels <- c(indirect_effect_labels, label)
  }

  # 总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(indirect_effect_labels, collapse = " + ")
  )

  # 总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 4. 间接效应两两比较
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          # 使用命名规则 CI1vs2, CI1vs3 等
          short_label_i <- gsub("indirect", "", indirect_effect_labels[i])
          short_label_j <- gsub("indirect", "", indirect_effect_labels[j])
          comparisons <- c(
            comparisons,
            paste0(
              "CI", short_label_i, "vs", short_label_j,
              " := ", indirect_effect_labels[i], " - ", indirect_effect_labels[j]
            )
          )
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }

  # 5. 前后测系数
  pre_post_coefficients <- paste(
    c(
      # 对于直接路径的前后测系数
      paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
      }),
      # 对于链式路径的前后测系数
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, "1 := (2*b", i, "1 + d", i, "1)/2\nX0_b", i, "1 := X1_b", i, "1 - d", i, "1")
      })
    ),
    collapse = "\n"
  )

  # 合并所有公式
  sem_model <- paste(
    regression_y,
    paste(regression_m, collapse = "\n"),
    paste(indirect_effects, collapse = "\n"),
    total_indirect,
    total_effect,
    compare_indirect_effect,
    pre_post_coefficients,
    sep = "\n"
  )

  return(sem_model)
}
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
ImputeData <- function(data_missing, m = 5, method = "pmm", seed = 123, predictorMatrix = NULL) {
  # 替换 -999 为 NA
  data_missing[data_missing == -999] <- NA

  # 输入检查
  if (!is.data.frame(data_missing)) stop("Input data must be a data frame.")
  if (!all(sapply(data_missing, function(x) is.numeric(x) || is.factor(x)))) stop("All columns must be numeric or factor.")

  # 动态生成 predictorMatrix
  if (is.null(predictorMatrix)) {
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.1)
  }

  # 动态选择方法
  if (is.null(method)) {
    method <- ifelse(sapply(data_missing, is.numeric), "pmm", "logreg")
  }

  # 插补数据
  imp <- mice::mice(data_missing, m = m, method = method, seed = seed, predictorMatrix = predictorMatrix)

  # 获取插补结果列表
  imputed_data_list <- mice::complete(imp, "all")
  imputed_data_list <- lapply(imputed_data_list, as.data.frame)

  # 生成诊断信息
  summary_imp <- summary(imp)

  return(list(
    imputed_data_list = imputed_data_list,  # 插补后的数据列表
    summary = summary_imp                 # 插补结果的汇总信息
  ))
}


MCMI <- function(sem_model,
                 imputations,
                 R = 20000L,
                 alpha = c(0.001, 0.01, 0.05),
                 decomposition = "eigen",
                 pd = TRUE,
                 tol = 1e-06,
                 seed = NULL,
                 estimator = "ML",
                 se = "standard",
                 missing = "listwise") {
  # 验证输入
  stopifnot(
    is.character(sem_model),
    is.list(imputations) && all(sapply(imputations, is.data.frame))
  )

  # 使用每个插补数据集重新拟合模型
  fits <- lapply(imputations, function(data) {
    lavaan::sem(
      model = sem_model,
      data = data,
      estimator = estimator,
      se = se,
      missing = missing
    )
  })

  # 提取系数和协方差矩阵
  coefs <- lapply(fits, lavaan::coef)
  vcovs <- lapply(fits, lavaan::vcov)

  # 使用 MICombine 合并插补结果
  pooled <- semmcci:::.MICombine(
    coefs = coefs,
    vcovs = vcovs,
    M = length(coefs),
    k = length(coefs[[1]]),
    adj = TRUE
  )
  scale <- pooled$total
  location <- pooled$est

  # 设置 Monte Carlo 采样
  if (!is.null(seed)) {
    set.seed(seed)
  }
  thetahatstar <- semmcci:::.ThetaHatStar(
    R = R,
    scale = scale,
    location = location,
    decomposition = decomposition,
    pd = pd,
    tol = tol
  )
  thetahatstar_orig <- thetahatstar$thetahatstar
  decomposition <- thetahatstar$decomposition

  # 更新估计值
  thetahat <- semmcci:::.ThetaHat(
    object = fits[[1]],
    est = colMeans(
      do.call(
        what = "rbind",
        args = lapply(fits, function(fit) fit@ParTable$est)
      )
    )
  )

  # 处理定义参数
  thetahatstar <- semmcci:::.MCDef(
    object = fits[[1]],
    thetahat = thetahat,
    thetahatstar_orig = thetahatstar_orig
  )

  # 使用第一个 fits 对象作为 `lav` 对象
  lav <- fits[[1]]

  # 输出结果
  out <- list(
    call = match.call(),
    args = list(
      lav = lav,
      sem_model = sem_model,
      imputations = imputations,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol,
      seed = seed,
      pooled = pooled
    ),
    thetahat = thetahat,
    thetahatstar = thetahatstar,
    fun = "MCMI"
  )
  class(out) <- c("semmcci", class(out))
  return(out)
}

PrepareMissingData <- function(data_missing,
                               m = 5,
                               method = "pmm",
                               seed = 123,
                               M_before,
                               M_after,
                               Y_before,
                               Y_after) {
  # Step 1: 插补数据
  imputed_result <- ImputeData(
    data_missing = data_missing,
    m = m,
    method = method,
    seed = seed
  )

  # 获取插补后的数据集列表
  imputed_data_list <- imputed_result$imputed_data_list

  # Step 2: 对每个插补数据集进行数据处理
  processed_data_list <- lapply(imputed_data_list, function(imputed_data) {
    PrepareData(
      data = imputed_data,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after
    )
  })

  # 返回处理后的数据集列表
  return(list(
    processed_data_list = processed_data_list,
    imputation_summary = imputed_result$summary  # 插补过程的诊断信息
  ))
}

RunMCMIAnalysis <- function(data_missing,
                            m = 5,
                            method = "pmm",
                            seed = 123,
                            M_before,
                            M_after,
                            Y_before,
                            Y_after,
                            sem_model,
                            Na = "MI",
                            R = 20000L,
                            alpha = c(0.001, 0.01, 0.05),
                            decomposition = "eigen",
                            pd = TRUE,
                            tol = 1e-06) {
  # Step 1: 初始化结果变量
  mi_result <- NULL

  # Step 2: 检查是否启用 Monte Carlo (MC)
  if (Na == "MI") {
    # 插补并处理数据
    prepared_data <- PrepareMissingData(
      data_missing = data_missing,
      m = m,
      method = method,
      seed = seed,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after
    )

    # 获取处理后的插补数据集列表
    processed_data_list <- prepared_data$processed_data_list

    # 调用 MCMI 进行 Monte Carlo 分析
    mi_result <- MCMI(
      sem_model = sem_model,
      imputations = processed_data_list,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol,
      seed = seed
    )
  } else {
    stop("MI is set to FALSE. Currently, only MI = TRUE is supported.")
  }

  # 返回分析结果
  return(mi_result)
}

WSMed <- function(data,
                      M_before,
                      M_after,
                      Y_before,
                      Y_after,
                      form = "P",
                      standardized = FALSE,
                      Na = "DE",
                      bootstrap = 1000,
                      iseed = 123,
                      se = "standard",
                      R = 20000L,  # Monte Carlo 重复次数
                      alpha = c(0.001, 0.01, 0.05),  # 显著性水平
                      m = 5,  # 插补次数
                      method = "pmm",  # 插补方法
                      decomposition = "eigen",
                      pd = TRUE,
                      tol = 1e-06,
                      seed = 123,
                      alphastd = 0.05) {


  if (Na == "DE") {
    data <- na.omit(data)}

  # Step 1: 数据预处理
  prepared_data <- PrepareData(data = data,
                               M_before = M_before,
                               M_after = M_after,
                               Y_before = Y_before,
                               Y_after = Y_after)

  # Step 2: 构建模型
  # P is parallel mediation, CN is chained mediation, CP/PC is parallel + chain mediation
  if (form == "P") {
    sem_model <- GenerateModelP(prepared_data)
  } else if (form == "CP") {
    sem_model <- GenerateModelCP(prepared_data)
  } else if (form == "PC") {
    sem_model <- GenerateModelPC(prepared_data)
  } else if (form == "CN") {
    sem_model <- GenerateModelCN(prepared_data)
  } else {
    stop("Invalid 'form' parameter. Use 'CP', 'PC' or 'CN'.")
  }

  # fit the model
  if (Na == "DE") {
    # 删除缺失值的模型拟合
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      se = se,
      bootstrap = bootstrap,
      iseed = iseed
    )
    } else if (Na == "FIML") {
    # 使用 FIML 方法处理缺失值
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      missing = "fiml",
    )
    } else if (Na == "MI") {
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
    )
    if (!inherits(fit, "lavaan")) {
      stop("Model fitting failed. Check your input model and data.")
    }
    }
  cat("fit\n")

  # Monte Carlo
  mi_result <- NULL
  fiml_result <- NULL
  if (Na == "MI") {
    # Step 4: MCMI 分析（可选）
    mi_result <- RunMCMIAnalysis(
      data_missing = data,
      m = m,
      method = method,
      seed = seed,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after,
      sem_model = sem_model,
      Na = Na,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol
    )
  }
  if (Na == "FIML"){
    fiml_result <- MC(fit,
                        R = R,
                        alpha = alpha)
  }

  # Step 5: 标准化结果
  std_result <- NULL
  std_mi_result <- NULL
  std_fiml_result <- NULL

  if (standardized){
  if (Na == "DE") {
    std_result <- standardizedSolution_boot_ci(fit)
  }
  if (Na == "MI") {
    std_mi_result <- semmcci::MCStd(mi_result, alpha = alphastd)
    }
  if (Na == "FIML") {
    std_fiml_result <- semmcci::MCStd(fiml_result, alpha = alphastd)
  }
  }
  # Step 6: 返回结果
  return(list(
    prepared_data = prepared_data,
    model_summary = summary(fit, fit.measures = TRUE, standardized = standardized),
    lavaan_fit = fit,
    sem_model = sem_model,
    mi_result = mi_result,
    fiml_result = fiml_result,
    std_result = std_result,
    std_mi_result = std_mi_result,
    std_fiml_result = std_fiml_result
  ))
}


})


