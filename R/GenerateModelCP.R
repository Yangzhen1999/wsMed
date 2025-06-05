#' @title Generate Combined Parallel and Chained Mediation Model
#'
#' @description Dynamically generates a structural equation modeling (SEM) syntax for
#' combined parallel and chained mediation analysis based on the prepared dataset. The function computes regression
#' equations for mediators and the outcome variable, indirect effects for both parallel and chained mediation paths,
#' total effects, contrasts between indirect effects, and coefficients in different X conditions.
#'
#' @details This function is used to construct SEM models that combine parallel and chained mediation analysis.
#' It automatically parses variable names from the prepared dataset and dynamically creates
#' the necessary model syntax, including:
#'
#' - **Outcome regression**: Defines the relationship between the difference scores of
#' the outcome (`Ydiff`), the chained mediator (`M1diff`), and the parallel mediators (`M2diff`, `M3diff`, etc.).
#'
#' - **Mediator regressions**: Defines the sequential regression models for the chained mediator and each parallel mediator.
#'
#' - **Indirect effects**: Computes the indirect effects for both chained and parallel mediation paths,
#' including multi-step indirect effects involving both chained and parallel mediators.
#'
#' - **Total indirect effect**: Calculates the sum of all indirect effects from chained and parallel mediation paths.
#'
#' - **Total effect**: Combines the direct effect (`cp`) and the total indirect effect.
#'
#' - **Contrasts of indirect effects**: Optionally calculates the pairwise contrasts between
#' the indirect effects for different mediation paths.
#'
#' - **Coefficients in different 'X' conditions**: Calculates path coefficients in different `X`
#' conditions to observe the moderation effect of `X`.
#'
#' This model is suitable for designs where mediators include both a sequential chain (chained mediation)
#' and independent parallel mediators.
#'
#' @param prepared_data A data frame returned by [PrepareData()], containing the processed
#' within-subject mediator and outcome variables. The data frame must include columns for
#' difference scores (`Mdiff`) and average scores (`Mavg`) of mediators, as well as the
#' outcome difference score (`Ydiff`).
#' @param MP A character vector specifying which paths are moderated by variable(s) W.
#'           Acceptable values include:
#'           - \code{"a2"}, \code{"a3"}, ...: moderation on the a paths of parallel mediators (W → Mdiff).
#'           - \code{"b2"}, \code{"b3"}, ...: moderation on the b paths of parallel mediators (Mdiff × W → Ydiff).
#'           - \code{"b_1_2"}, \code{"b_1_3"}, ...: moderation on the paths from the chain mediator to parallel mediators.
#'           - \code{"d_1_2"}, \code{"d_1_3"}, ...: moderation on the paths from the chain mediator’s Mavg to parallel mediators.
#'           - \code{"cp"}: moderation on the direct effect from X to Y (i.e., W → Ydiff).
#'
#'           Each entry triggers inclusion of W’s main effect or interaction terms (e.g., \code{int_Mdiff_W}).
#' @return A character string representing the SEM model syntax for the specified combined parallel and chained mediation analysis.
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
#' sem_model <- GenerateModelCP(prepared_data)
#' cat(sem_model)
#'
#' @export
GenerateModelCP <- function(prepared_data) {
  chain_var <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_avg <- grep("^M1avg$", colnames(prepared_data), value = TRUE)
  all_mdiff <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_mavg  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  parallel_vars  <- setdiff(all_mdiff, chain_var)
  parallel_avgs  <- setdiff(all_mavg, chain_avg)
  n <- length(parallel_vars)

  if (length(chain_var) != 1) stop("The chain mediator should contain exactly one variable: M1diff.")

  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  y_rhs <- c(
    "cp*1",
    paste0("b1*", chain_var),
    paste0("b", 2:(n + 1), "*", parallel_vars),
    paste0("d1*", chain_avg),
    paste0("d", 2:(n + 1), "*", parallel_avgs),
    control_rhs
  )
  regression_y <- paste("Ydiff ~", paste(na.omit(y_rhs), collapse = " + "))

  regression_m <- c(
    paste(chain_var, "~", paste(c("a1*1", control_rhs), collapse = " + "))
  )

  for (i in seq_along(parallel_vars)) {
    rhs <- c(
      paste0("a", i + 1, "*1"),
      paste0("b_1_", i + 1, "*", chain_var),
      paste0("d_1_", i + 1, "*", chain_avg),
      control_rhs
    )
    regression_m <- c(regression_m, paste(parallel_vars[i], "~", paste(na.omit(rhs), collapse = " + ")))
  }

  indirect_effects <- c("indirect_1 := a1 * b1")
  indirect_effect_labels <- c("indirect_1")

  for (i in seq_along(parallel_vars)) {
    label_direct <- paste0("indirect_", i + 1)
    formula_direct <- paste0("a", i + 1, " * b", i + 1)
    label_chain <- paste0("indirect_1_", i + 1)
    formula_chain <- paste0("a1 * b_1_", i + 1, " * b", i + 1)

    indirect_effects <- c(
      indirect_effects,
      paste0(label_direct, " := ", formula_direct),
      paste0(label_chain, " := ", formula_chain)
    )
    indirect_effect_labels <- c(indirect_effect_labels, label_direct, label_chain)
  }

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

  # 前后测转换系数
  pre_post_coefficients <- paste(
    c(
      paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
      sapply(2:(n + 1), function(i) {
        paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
      }),
      sapply(seq_along(parallel_vars), function(i) {
        idx <- i + 1
        paste0("X1_b_1_", idx, " := (2*b_1_", idx, " + d_1_", idx, ")/2\n",
               "X0_b_1_", idx, " := X1_b_1_", idx, " - d_1_", idx)
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
GenerateModelCP <- function(prepared_data, MP) {
  chain_var <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_avg <- grep("^M1avg$", colnames(prepared_data), value = TRUE)
  all_mdiff <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_mavg  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  parallel_vars  <- setdiff(all_mdiff, chain_var)
  parallel_avgs  <- setdiff(all_mavg, chain_avg)
  n <- length(parallel_vars)

  if (length(chain_var) != 1) stop("The chain mediator should contain exactly one variable: M1diff.")

  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  W_vars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  interaction_vars <- grep("^int_", colnames(prepared_data), value = TRUE)

  # 构造 Ydiff 回归项
  y_rhs <- c("cp*1", paste0("b1*", chain_var), paste0("d1*", chain_avg))
  for (i in seq_len(n)) {
    y_rhs <- c(y_rhs,
               paste0("b", i + 1, "*", parallel_vars[i]),
               paste0("d", i + 1, "*", parallel_avgs[i]))
  }

  # 添加调节项到 Ydiff
  if ("cp" %in% MP && length(W_vars) > 0) {
    for (j in seq_along(W_vars)) {
      y_rhs <- c(y_rhs, paste0("cpw", j, "_1*", W_vars[j]))
    }
  }
  for (i in seq_len(n)) {
    id <- i + 1
    if (paste0("b", id) %in% MP) {
      matched <- grep(paste0("^int_", parallel_vars[i], "_W\\d+$"), interaction_vars, value = TRUE)
      y_rhs <- c(y_rhs, paste0("bw", id, "_", seq_along(matched), "*", matched))
    }
    if (paste0("d", id) %in% MP) {
      matched <- grep(paste0("^int_", parallel_avgs[i], "_W\\d+$"), interaction_vars, value = TRUE)
      y_rhs <- c(y_rhs, paste0("dw", id, "_", seq_along(matched), "*", matched))
    }
  }

  regression_y <- paste("Ydiff ~", paste(c(y_rhs, control_rhs), collapse = " + "))

  # M1diff 回归式
  m_eqs <- paste(chain_var, "~", paste(c("a1*1", control_rhs,
                                         if ("a1" %in% MP) paste0("aw1_", seq_along(W_vars), "*", W_vars) else NULL),
                                       collapse = " + "))

  # 其他 Mdiff 回归式
  for (i in seq_len(n)) {
    rhs <- c(
      paste0("a", i + 1, "*1"),
      paste0("b_1_", i + 1, "*", chain_var),
      paste0("d_1_", i + 1, "*", chain_avg)
    )

    if (paste0("a", i + 1) %in% MP && length(W_vars) > 0) {
      rhs <- c(rhs, paste0("aw", i + 1, "_", seq_along(W_vars), "*", W_vars))
    }
    if (paste0("b_1_", i + 1) %in% MP) {
      int_b <- grep(paste0("^int_", chain_var, "_W\\d+$"), interaction_vars, value = TRUE)
      rhs <- c(rhs, paste0("bw_1_", i + 1, "_", seq_along(int_b), "*", int_b))
    }
    if (paste0("d_1_", i + 1) %in% MP) {
      int_d <- grep(paste0("^int_", chain_avg, "_W\\d+$"), interaction_vars, value = TRUE)
      rhs <- c(rhs, paste0("dw_1_", i + 1, "_", seq_along(int_d), "*", int_d))
    }

    m_eqs <- c(m_eqs, paste(parallel_vars[i], "~", paste(c(rhs, control_rhs), collapse = " + ")))
  }

  # 间接效应
  indirect_effects <- c("indirect_1 := a1 * b1")
  indirect_effect_labels <- "indirect_1"

  for (i in seq_len(n)) {
    id <- i + 1
    indirect_effects <- c(
      indirect_effects,
      paste0("indirect_", id, " := a", id, " * b", id),
      paste0("indirect_1_", id, " := a1 * b_1_", id, " * b", id)
    )
    indirect_effect_labels <- c(indirect_effect_labels,
                                paste0("indirect_", id),
                                paste0("indirect_1_", id))
  }

  total_indirect <- paste0("total_indirect := ", paste(indirect_effect_labels, collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  # 对比项
  compare_indirect <- ""
  if (length(indirect_effect_labels) > 1) {
    all_pairs <- utils::combn(indirect_effect_labels, 2)
    compare_indirect <- paste(apply(all_pairs, 2, function(pair) {
      paste0("CI_", gsub("indirect_", "", pair[1]),
             "_vs_", gsub("indirect_", "", pair[2]),
             " := ", pair[1], " - ", pair[2])
    }), collapse = "\n")
  }

  # 前后测转换系数
  pre_post <- c(
    paste0("X1_b1 := (2*b1 + d1)/2\nX0_b1 := X1_b1 - d1"),
    sapply(2:(n + 1), function(i) {
      paste0("X1_b", i, " := (2*b", i, " + d", i, ")/2\nX0_b", i, " := X1_b", i, " - d", i)
    }),
    sapply(2:(n + 1), function(i) {
      paste0("X1_b_1_", i, " := (2*b_1_", i, " + d_1_", i, ")/2\nX0_b_1_", i, " := X1_b_1_", i, " - d_1_", i)
    })
  )

  sem_model <- paste(
    regression_y,
    paste(m_eqs, collapse = "\n"),
    paste(indirect_effects, collapse = "\n"),
    total_indirect,
    total_effect,
    compare_indirect,
    paste(pre_post, collapse = "\n"),
    sep = "\n"
  )

  return(sem_model)
}
