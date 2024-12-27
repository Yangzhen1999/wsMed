#' @title Generate Chained Mediation Model
#'
#' @description Dynamically generates a structural equation modeling (SEM) syntax for
#' chained mediation analysis based on the prepared dataset. The function computes regression
#' equations for mediators and the outcome variable, indirect effects along multi-step mediation paths,
#' total effects, contrasts between indirect effects, and coefficients in different conditions.
#'
#' @details This function is used to construct SEM models for chained mediation analysis.
#' It automatically parses variable names from the prepared dataset and dynamically creates
#' the necessary model syntax, including:
#'
#' - **Outcome regression**: Defines the relationship between the difference scores of
#' the outcome (`Ydiff`) and the mediators (`Mdiff`) as well as their average scores (`Mavg`).
#'
#' - **Mediator regressions**: Defines the sequential regression models for each mediator's
#' difference score, incorporating prior mediators as predictors.
#'
#' - **Indirect effects**: Computes the indirect effects along all possible multi-step
#' mediation paths using the product of path coefficients.
#'
#' - **Total indirect effect**: Calculates the sum of all indirect effects from the chained
#' mediation paths.
#'
#' - **Total effect**: Combines the direct effect (`cp`) and the total indirect effect.
#'
#' - **Contrasts of indirect effects**: Optionally calculates the pairwise contrasts between
#' the indirect effects for different mediation paths.
#'
#' - **Coefficients in different 'X' conditions**: Calculates path coefficients in different `X`
#' conditions to observe the moderation effect of `X`.
#'
#' This model is suitable for chained mediation designs where mediators influence each other in
#' a sequential manner, forming multi-step mediation paths.
#'
#' @param prepared_data A data frame returned by [PrepareData()], containing the processed
#' within-subject mediator and outcome variables. The data frame must include columns for
#' difference scores (`Mdiff`) and average scores (`Mavg`) of mediators, as well as the
#' outcome difference score (`Ydiff`).
#'
#' @return A character string representing the SEM model syntax for the specified chained mediation analysis.
#'
#' @seealso [PrepareData()], [WsMed()], [GenerateModelP()]
#'
#' @examples
#' # Example prepared data
#' prepared_data <- data.frame(
#'   M1diff = rnorm(100),
#'   M2diff = rnorm(100),
#'   M3diff = rnorm(100),
#'   M1avg = rnorm(100),
#'   M2avg = rnorm(100),
#'   M3avg = rnorm(100),
#'   Ydiff = rnorm(100)
#' )
#'
#' # Generate SEM model syntax
#' sem_model <- GenerateModelCN(prepared_data)
#' cat(sem_model)
#'
#' @export

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
    path_combinations <- utils::combn(1:n, length_path, simplify = FALSE)

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
