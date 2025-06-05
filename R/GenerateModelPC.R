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
#' @param MP A character vector specifying which paths are moderated by variable(s) W.
#'           Acceptable values include:
#'           - \code{"a2"}, \code{"a3"}, ...: moderation on the a paths (W → Mdiff).
#'           - \code{"b2"}, \code{"b3"}, ...: moderation on the b paths (Mdiff × W → Ydiff).
#'           - \code{"b_2_1"}, \code{"b_3_1"}, ...: moderation on the cross-paths from parallel mediators to the chain mediator (e.g., M2 → M1).
#'           - \code{"d_2_1"}, \code{"d_3_1"}, ...: moderation on the paths from parallel mediators’ centered means to M1.
#'           - \code{"cp"}: moderation on the direct effect of X on Y (i.e., W → Ydiff).
#'
#'           This argument controls which interaction terms (e.g., \code{int_Mdiff_W}, \code{int_Mavg_W}) are included
#'           in the regression equations. Variable names are automatically matched using the naming convention
#'           \code{"int_<predictor>_W<index>"}.

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
  chain_var <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_avg <- grep("^M1avg$", colnames(prepared_data), value = TRUE)
  all_mdiff <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_mavg  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  parallel_vars <- setdiff(all_mdiff, chain_var)
  parallel_avgs <- setdiff(all_mavg, chain_avg)
  n <- length(parallel_vars)

  if (length(chain_var) != 1) stop("The chain mediator should contain exactly one variable: M1diff.")

  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  y_rhs <- c(
    "cp*1",
    paste0("b1*", chain_var),
    if (n > 0) paste0("b", seq(2, n + 1), "*", parallel_vars),
    paste0("d1*", chain_avg),
    if (n > 0) paste0("d", seq(2, n + 1), "*", parallel_avgs),
    control_rhs
  )
  regression_y <- paste("Ydiff ~", paste(na.omit(y_rhs), collapse = " + "))

  regression_m <- c()

  if (n > 0) {
    chain_predictors <- c(
      paste0("b_", seq(2, n + 1), "_1*", parallel_vars),
      paste0("d_", seq(2, n + 1), "_1*", parallel_avgs)
    )
  } else {
    chain_predictors <- character(0)
  }

  rhs_chain <- c("a1*1", chain_predictors, control_rhs)
  regression_m <- c(paste(chain_var, "~", paste(na.omit(rhs_chain), collapse = " + ")))

  for (i in seq_along(parallel_vars)) {
    rhs <- c(paste0("a", i + 1, "*1"), control_rhs)
    regression_m <- c(regression_m, paste(parallel_vars[i], "~", paste(na.omit(rhs), collapse = " + ")))
  }

  indirect_effects <- c()
  indirect_effect_labels <- c()

  for (i in seq_along(parallel_vars)) {
    idx <- i + 1
    label_direct <- paste0("indirect_", idx)
    formula_direct <- paste0("a", idx, " * b", idx)
    label_cross <- paste0("indirect_", idx, "_1")
    formula_cross <- paste0("a", idx, " * b_", idx, "_1 * b1")

    indirect_effects <- c(
      indirect_effects,
      paste0(label_direct, " := ", formula_direct),
      paste0(label_cross, " := ", formula_cross)
    )
    indirect_effect_labels <- c(indirect_effect_labels, label_direct, label_cross)
  }

  indirect_effects <- c(indirect_effects, "indirect_1 := a1 * b1")
  indirect_effect_labels <- c(indirect_effect_labels, "indirect_1")

  total_indirect <- paste0("total_indirect := ", paste(indirect_effect_labels, collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          comparisons <- c(comparisons, paste0(
            "CI_", gsub("indirect_", "", indirect_effect_labels[i]), "_vs_",
            gsub("indirect_", "", indirect_effect_labels[j]), " := ",
            indirect_effect_labels[i], " - ", indirect_effect_labels[j]
          ))
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }

  pre_post_coefficients <- paste(
    c(
      paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
      }),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b_", i, "_1 := (2*b_", i, "_1 + d_", i, "_1)/2\n",
               "X0_b_", i, "_1 := X1_b_", i, "_1 - d_", i, "_1")
      })
    ),
    collapse = "\n"
  )

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
GenerateModelPC <- function(prepared_data, MP) {
  chain_var <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_avg <- grep("^M1avg$", colnames(prepared_data), value = TRUE)
  all_mdiff <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_mavg  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  parallel_vars <- setdiff(all_mdiff, chain_var)
  parallel_avgs <- setdiff(all_mavg, chain_avg)
  n <- length(parallel_vars)

  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  W_vars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  interaction_vars <- grep("^int_", colnames(prepared_data), value = TRUE)

  # 构造 Ydiff
  y_rhs <- c("cp*1")
  y_rhs <- c(y_rhs, paste0("b1*", chain_var), paste0("d1*", chain_avg))
  if (n > 0) {
    y_rhs <- c(y_rhs,
               paste0("b", 2:(n + 1), "*", parallel_vars),
               paste0("d", 2:(n + 1), "*", parallel_avgs))
  }

  # 调节 cp 路径
  if ("cp" %in% MP && length(W_vars) > 0) {
    y_rhs <- c(y_rhs, paste0("cpw1_", seq_along(W_vars), "*", W_vars))
  }

  # b 路径调节
  for (i in 2:(n + 1)) {
    if (paste0("b", i) %in% MP) {
      matched <- grep(paste0("^int_M", i, "diff_W\\d+$"), interaction_vars, value = TRUE)
      y_rhs <- c(y_rhs, paste0("bw", i, "_", seq_along(matched), "*", matched))
    }
    if (paste0("d", i) %in% MP) {
      matched <- grep(paste0("^int_M", i, "avg_W\\d+$"), interaction_vars, value = TRUE)
      y_rhs <- c(y_rhs, paste0("dw", i, "_", seq_along(matched), "*", matched))
    }
  }

  regression_y <- paste("Ydiff ~", paste(c(y_rhs, control_rhs), collapse = " + "))

  # 构造 M1diff 回归式
  rhs_chain <- c("a1*1")
  if (n > 0) {
    for (i in 2:(n + 1)) {
      rhs_chain <- c(rhs_chain,
                     paste0("b_", i, "_1*", parallel_vars[i - 1]),
                     paste0("d_", i, "_1*", parallel_avgs[i - 1]))
      if (paste0("b_", i, "_1") %in% MP) {
        matched <- grep(paste0("^int_", parallel_vars[i - 1], "_W\\d+$"), interaction_vars, value = TRUE)
        rhs_chain <- c(rhs_chain, paste0("bw_", i, "_1_", seq_along(matched), "*", matched))
      }
      if (paste0("d_", i, "_1") %in% MP) {
        matched <- grep(paste0("^int_", parallel_avgs[i - 1], "_W\\d+$"), interaction_vars, value = TRUE)
        rhs_chain <- c(rhs_chain, paste0("dw_", i, "_1_", seq_along(matched), "*", matched))
      }
    }
  }
  regression_m1 <- paste(chain_var, "~", paste(c(rhs_chain, control_rhs), collapse = " + "))

  # 构造并行 Mdiff 回归
  regression_m_par <- sapply(seq_along(parallel_vars), function(i) {
    idx <- i + 1
    rhs <- c(paste0("a", idx, "*1"))
    if (paste0("a", idx) %in% MP) {
      rhs <- c(rhs, paste0("aw", idx, "_", seq_along(W_vars), "*", W_vars))
    }
    paste(parallel_vars[i], "~", paste(c(rhs, control_rhs), collapse = " + "))
  })

  regression_m <- c(regression_m1, regression_m_par)

  # 间接效应
  indirect_effects <- c()
  indirect_effect_labels <- c()
  for (i in seq_along(parallel_vars)) {
    idx <- i + 1
    indirect_effects <- c(
      indirect_effects,
      paste0("indirect_", idx, " := a", idx, " * b", idx),
      paste0("indirect_", idx, "_1 := a", idx, " * b_", idx, "_1 * b1")
    )
    indirect_effect_labels <- c(indirect_effect_labels,
                                paste0("indirect_", idx),
                                paste0("indirect_", idx, "_1"))
  }
  indirect_effects <- c(indirect_effects, "indirect_1 := a1 * b1")
  indirect_effect_labels <- c(indirect_effect_labels, "indirect_1")

  total_indirect <- paste0("total_indirect := ", paste(indirect_effect_labels, collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  # 比较项
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    combs <- combn(indirect_effect_labels, 2)
    compare_indirect_effect <- paste(apply(combs, 2, function(pair) {
      paste0("CI_", gsub("indirect_", "", pair[1]), "_vs_",
             gsub("indirect_", "", pair[2]), " := ",
             pair[1], " - ", pair[2])
    }), collapse = "\n")
  }

  # 前后测转换
  pre_post_lines <- c(
    paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
    sapply(2:(n + 1), function(i) {
      paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
    }),
    sapply(2:(n + 1), function(i) {
      paste0("X1_b_", i, "_1 := (2*b_", i, "_1 + d_", i, "_1)/2\nX0_b_", i, "_1 := X1_b_", i, "_1 - d_", i, "_1")
    })
  )
  pre_post_coefficients <- paste(pre_post_lines, collapse = "\n")

  # 拼接模型
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


