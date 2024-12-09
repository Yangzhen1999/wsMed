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
