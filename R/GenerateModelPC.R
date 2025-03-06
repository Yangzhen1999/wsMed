#' @title Generate Parallel and Chained Mediation Model
#'
#' @description Dynamically generates a structural equation modeling (SEM) syntax for
#' mediation analysis that integrates both parallel and chained mediators. Unlike the
#' Combined Parallel and Chained mediation model (`GenerateModelCP`), this function assumes
#' that the chained mediator receives inputs from the parallel mediators and directly influences
#' the outcome variable, emphasizing a downstream role for the chained mediator.
#'
#' @details This function is designed to build SEM models that integrate parallel and chained mediation structures.
#' It automatically identifies variable names from the prepared dataset and generates the necessary model syntax, including:
#'
#' - **Outcome regression**: Defines the relationship between the difference scores of the outcome (`Ydiff`),
#' the chained mediator (`M1diff`), and the parallel mediators (`M2diff`, `M3diff`, etc.).
#'
#' - **Mediator regressions**: Constructs separate regression models for the parallel mediators and the chained mediator.
#' The chained mediator incorporates predictors from all parallel mediators.
#'
#' - **Indirect effects**: Computes indirect effects for:
#'   - Parallel mediators (`M2diff`, `M3diff`, etc.) directly influencing the outcome.
#'   - The chained mediator (`M1diff`) directly influencing the outcome.
#'   - Combined paths where parallel mediators influence the chained mediator, which in turn influences the outcome.
#'
#' - **Total indirect effect**: Summarizes all indirect effects from parallel and chained mediation paths.
#'
#' - **Total effect**: Combines the direct effect (`cp`) and the total indirect effect.
#'
#' - **Contrasts of indirect effects**: Optionally computes pairwise contrasts between indirect effects
#' for different mediation paths.
#'
#' - **Coefficients in different 'X' conditions**: Computes path coefficients under different `X` conditions
#' to analyze moderation effects.
#'
#' This model is suitable for designs where mediators include both independent parallel paths and
#' sequential chained paths, providing a comprehensive mediation analysis framework.
#'
#' @param prepared_data A data frame returned by [PrepareData()], containing the processed
#' within-subject mediator and outcome variables. The data frame must include columns for
#' difference scores (`Mdiff`) and average scores (`Mavg`) of mediators, as well as the
#' outcome difference score (`Ydiff`).
#'
#' @return A character string representing the SEM model syntax for the specified parallel and chained mediation analysis.
#'
#' @seealso [PrepareData()], [wsMed()], [GenerateModelP()], [GenerateModelCN()]
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
#' sem_model <- GenerateModelPC(prepared_data)
#' cat(sem_model)
#'
#' @export

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
    paste0(" + b1*", chain_var),  # 先放 b1*M1diff
    if (length(parallel_vars) > 0) paste0(" + b", seq(2, n + 1), "*", parallel_vars, collapse = " + ") else "",
    paste0(" + d1*", chain_avg),
    if (length(parallel_avgs) > 0) paste0(" + d", seq(2, n + 1), "*", parallel_avgs, collapse = " + ") else "",
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
  chain_predictors <- c()
  if (length(parallel_vars) > 0) {
    chain_predictors <- c(
      paste0("b", seq(2, n + 1), "1*", parallel_vars),
      paste0("d", seq(2, n + 1), "1*", parallel_avgs)
    )
  }
  regression_m <- c(
    paste0(chain_var, " ~ a1*1", if (length(chain_predictors) > 0) paste0(" + ", paste(chain_predictors, collapse = " + ")) else ""),
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

  # **确保 indirect1 总是在最前面**
  first_label <- "indirect1"
  other_labels <- setdiff(indirect_effect_labels, first_label)

  # **重新组合 total_indirect 计算顺序**
  total_indirect <- paste0(
    "total_indirect := ", first_label, " + ", paste(other_labels, collapse = " + ")
  )
  # 总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 4. 间接效应两两比较
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()

    # **确保 indirect1 先被比较**
    first_label <- "indirect1"
    other_labels <- setdiff(indirect_effect_labels, first_label)

    # **优先计算 CI1vsX**
    for (label in other_labels) {
      short_label_i <- gsub("indirect", "", first_label)
      short_label_j <- gsub("indirect", "", label)
      comparisons <- c(
        comparisons,
        paste0("CI", short_label_i, "vs", short_label_j,
               " := ", first_label, " - ", label)
      )
    }

    # **比较所有其余的间接效应**
    for (i in seq_along(other_labels)) {
      for (j in seq_along(other_labels)) {
        if (i < j) {
          short_label_i <- gsub("indirect", "", other_labels[i])
          short_label_j <- gsub("indirect", "", other_labels[j])
          comparisons <- c(
            comparisons,
            paste0("CI", short_label_i, "vs", short_label_j,
                   " := ", other_labels[i], " - ", other_labels[j])
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
