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
  # 提取变量
  chain_var <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_avg <- grep("^M1avg$", colnames(prepared_data), value = TRUE)
  all_mdiff <- grep("^M\\ddiff$", colnames(prepared_data), value = TRUE)
  all_mavg  <- grep("^M\\davg$", colnames(prepared_data), value = TRUE)

  parallel_vars <- setdiff(all_mdiff, chain_var)
  parallel_avgs <- setdiff(all_mavg, chain_avg)
  n <- length(parallel_vars)

  if (length(chain_var) != 1) {
    stop("The chain mediator should contain exactly one variable: M1diff.")
  }

  # 控制变量
  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  # 构建 Y 回归
  y_rhs <- c(
    "cp*1",
    paste0("b1*", chain_var),
    if (n > 0) paste0("b", seq(2, n + 1), "*", parallel_vars),
    paste0("d1*", chain_avg),
    if (n > 0) paste0("d", seq(2, n + 1), "*", parallel_avgs),
    control_rhs
  )
  regression_y <- paste("Ydiff ~", paste(na.omit(y_rhs), collapse = " + "))

  # 构建 M 回归
  regression_m <- c()

  # 链式中介 M1diff
  chain_predictors <- if (n > 0) {
    c(
      paste0("b", seq(2, n + 1), "1*", parallel_vars),
      paste0("d", seq(2, n + 1), "1*", parallel_avgs)
    )
  } else {
    character(0)
  }

  rhs_chain <- c("a1*1", chain_predictors, control_rhs)
  regression_m <- c(paste(chain_var, "~", paste(na.omit(rhs_chain), collapse = " + ")))

  # 并行中介 M2diff, M3diff...
  for (i in seq_along(parallel_vars)) {
    rhs <- c(paste0("a", i + 1, "*1"), control_rhs)
    regression_m <- c(regression_m, paste(parallel_vars[i], "~", paste(na.omit(rhs), collapse = " + ")))
  }

  # 构建间接效应
  indirect_effects <- c()
  indirect_effect_labels <- c()

  for (i in seq_along(parallel_vars)) {
    label_direct <- paste0("indirect", i + 1)
    formula_direct <- paste0("a", i + 1, " * b", i + 1)
    label_cross <- paste0("indirect", i + 1, "1")
    formula_cross <- paste0("a", i + 1, " * b", i + 1, "1 * b1")

    indirect_effects <- c(
      indirect_effects,
      paste0(label_direct, " := ", formula_direct),
      paste0(label_cross, " := ", formula_cross)
    )
    indirect_effect_labels <- c(indirect_effect_labels, label_direct, label_cross)
  }

  # M1 自身路径
  indirect_effects <- c(indirect_effects, "indirect1 := a1 * b1")
  indirect_effect_labels <- c(indirect_effect_labels, "indirect1")

  # 构建总效应与对比
  total_indirect <- paste0(
    "total_indirect := ",
    paste(indirect_effect_labels, collapse = " + ")
  )
  total_effect <- "total_effect := cp + total_indirect"

  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          comparisons <- c(comparisons, paste0(
            "CI", gsub("indirect", "", indirect_effect_labels[i]), "vs",
            gsub("indirect", "", indirect_effect_labels[j]), " := ",
            indirect_effect_labels[i], " - ", indirect_effect_labels[j]
          ))
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }

  # 前后测系数转换
  pre_post_coefficients <- paste(
    c(
      paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
      }),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, "1 := (2*b", i, "1 + d", i, "1)/2\nX0_b", i, "1 := X1_b", i, "1 - d", i, "1")
      })
    ),
    collapse = "\n"
  )

  # 合并为完整模型语法
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
