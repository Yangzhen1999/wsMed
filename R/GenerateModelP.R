#' @title Generate Parallel Mediation Model
#'
#' @description Dynamically generates a structural equation modeling (SEM) syntax for
#' parallel mediation analysis based on the prepared dataset. The function computes regression
#' equations for mediators and the outcome variable, indirect effects, total effects,
#' contrasts between indirect effect, and .
#'
#' @details This function is used to construct SEM models for parallel mediation analysis.
#' It automatically parses variable names from the prepared dataset and dynamically creates
#' the necessary model syntax, including:
#'
#' - **Outcome regression**: Defines the relationship between the difference scores of
#' the outcome (`Ydiff`) and the mediators (`Mdiff`) as well as their average scores (`Mavg`).
#'
#' - **Mediator regressions**: Defines the intercept models for each mediator's difference score.
#'
#' - **Indirect effects**: Computes the indirect effects for each mediator using the
#' product of path coefficients (e.g., `a * b`).
#'
#' - **Total indirect effect**: Calculates the sum of all indirect effects.
#'
#' - **Total effect**: Combines the direct effect (`cp`) and the total indirect effect.
#'
#' - **Contrasts of indirect effects**: Optionally calculates the pairwise contrasts between
#' the indirect effects when multiple mediators are present.
#'
#' - **coefficients in different 'X' conditions**: Calculates path coefficients in different X conditions
#' to observe the moderation effect of ‘X'.
#'
#' This model is suitable for parallel mediation designs where multiple mediators act independently.
#'
#' @param prepared_data A data frame returned by [PrepareData()], containing the processed
#' within-subject mediator and outcome variables. The data frame must include columns for
#' difference scores (`Mdiff`) and average scores (`Mavg`) of mediators, as well as the
#' outcome difference score (`Ydiff`).
#' @param MP A character vector specifying which paths are moderated by variable(s) W.
#'           Valid values include:
#'           - \code{"a1"}, \code{"a2"}, ...: moderation on the a paths (W → Mdiff).
#'           - \code{"b1"}, \code{"b2"}, ...: moderation on the b paths (Mdiff × W → Ydiff).
#'           - \code{"d1"}, \code{"d2"}, ...: moderation on the d paths (Mavg × W → Ydiff).
#'           - \code{"cp"}: moderation on the direct effect from X to Y (i.e., W → Ydiff).
#'
#'           This argument controls which interaction terms (e.g., \code{int_Mdiff_W}, \code{int_Mavg_W}) are
#'           added to the corresponding regression equations.
#' @return A character string representing the SEM model syntax for the specified parallel mediation analysis.
#'
#' @seealso [PrepareData()], [wsMed()], [GenerateModelCN()]
#'
#' @examples
#' # Example prepared data
#' prepared_data <- data.frame(
#'   M1diff = rnorm(100),
#'   M2diff = rnorm(100),
#'   M1avg = rnorm(100),
#'   M2avg = rnorm(100),
#'   Ydiff = rnorm(100)
#' )
#'
#' # Generate SEM model syntax
#' sem_model <- GenerateModelP(prepared_data)
#' cat(sem_model)
#' @importFrom stats na.omit
#' @export

GenerateModelP <- function(prepared_data) {
  # 提取变量
  Mdiff_vars <- sort(grep("M\\d+diff", colnames(prepared_data), value = TRUE))
  Mavg_vars  <- sort(grep("M\\d+avg",  colnames(prepared_data), value = TRUE))

  # 提取控制变量
  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)

  # 控制变量公式
  controls_formula <- if (length(control_vars) > 0) {
    paste(control_vars, collapse = " + ")
  } else {
    NULL
  }

  # 构造 Y 回归
  y_terms <- c(
    "cp*1",
    paste0("b", seq_along(Mdiff_vars), "*", Mdiff_vars),
    paste0("d", seq_along(Mavg_vars), "*", Mavg_vars)
  )
  if (!is.null(controls_formula)) {
    y_terms <- c(y_terms, controls_formula)
  }

  regression_y <- paste("Ydiff ~", paste(y_terms, collapse = " + "))

  # 构造每个 Mdiff 回归
  regression_m <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      rhs <- c(paste0("a", i, "*1"), controls_formula)
      paste0(Mdiff_vars[i], " ~ ", paste(rhs, collapse = " + "))
    }),
    collapse = "\n"
  )

  # 构造间接效应
  indirect_effects <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0("indirect_", i, " := a", i, " * b", i)
    }),
    collapse = "\n"
  )

  # 构造总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(paste0("indirect_", seq_along(Mdiff_vars)), collapse = " + ")
  )

  # 构造总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 构造间接效应对比（两两组合）
  indirect_contrasts <- ""
  if (length(Mdiff_vars) > 1) {
    indirect_combinations <- utils::combn(seq_along(Mdiff_vars), 2)
    indirect_contrasts <- paste(
      apply(indirect_combinations, 2, function(pair) {
        paste0(
          "CI_", pair[1], "_vs_", pair[2],
          " := indirect_", pair[1], " - indirect_", pair[2]
        )
      }),
      collapse = "\n"
    )
  }

  # 构造前后测系数
  pre_post_coefficients <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      x1_bi <- paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2")
      x0_bi <- paste0("X0_b", i, " := X1_b", i, " - d", i)
      paste(x1_bi, x0_bi, sep = "\n")
    }),
    collapse = "\n"
  )

  # 合并模型语法
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
GenerateModelP <- function(prepared_data, MP) {
  # 提取变量
  Mdiff_vars <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  Mavg_vars  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)

  W_vars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  interaction_vars <- grep("^int_", colnames(prepared_data), value = TRUE)

  # 控制变量公式
  controls_formula <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  # 构造 Ydiff 回归项
  y_terms <- c("cp*1")
  for (i in seq_along(Mdiff_vars)) {
    y_terms <- c(y_terms,
                 paste0("b", i, "*", Mdiff_vars[i]),
                 paste0("d", i, "*", Mavg_vars[i]))
  }

  # 添加调节项（b 路径、d 路径）
  for (mp in MP) {
    if (grepl("^b\\d+$", mp)) {
      index <- sub("^b", "", mp)
      matched <- grep(paste0("^int_M", index, "diff_W\\d+$"), interaction_vars, value = TRUE)
      if (length(matched) > 0) {
        terms <- paste0("bw", index, "_", seq_along(matched), "*", matched)
        y_terms <- c(y_terms, terms)
      }
    }
    if (grepl("^d\\d+$", mp)) {
      index <- sub("^d", "", mp)
      matched <- grep(paste0("^int_M", index, "avg_W\\d+$"), interaction_vars, value = TRUE)
      if (length(matched) > 0) {
        terms <- paste0("dw", index, "_", seq_along(matched), "*", matched)
        y_terms <- c(y_terms, terms)
      }
    }
  }

  # 添加 cp 路径调节项（具名）
  if ("cp" %in% MP && length(W_vars) > 0) {
    cp_terms <- paste0("cpw1_", seq_along(W_vars), "*", W_vars)
    y_terms <- c(y_terms, cp_terms)
  }

  if (!is.null(controls_formula)) y_terms <- c(y_terms, controls_formula)
  regression_y <- paste("Ydiff ~", paste(y_terms, collapse = " + "))

  # 构造 Mdiff 回归（含调节）
  regression_m <- sapply(seq_along(Mdiff_vars), function(i) {
    rhs <- c(paste0("a", i, "*1"))
    mp_label <- paste0("a", i)
    if (mp_label %in% MP && length(W_vars) > 0) {
      rhs <- c(rhs, paste0("aw", i, "_", seq_along(W_vars), "*", W_vars))
    }
    if (!is.null(controls_formula)) rhs <- c(rhs, controls_formula)
    paste0(Mdiff_vars[i], " ~ ", paste(rhs, collapse = " + "))
  })
  regression_m <- paste(regression_m, collapse = "\n")

  # 间接效应定义
  indirect_effects <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0("indirect_", i, " := a", i, " * b", i)
    }),
    collapse = "\n"
  )

  total_indirect <- paste0("total_indirect := ",
                           paste0("indirect_", seq_along(Mdiff_vars), collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  # 对比间接效应
  indirect_contrasts <- ""
  if (length(Mdiff_vars) > 1) {
    indirect_combinations <- utils::combn(seq_along(Mdiff_vars), 2)
    indirect_contrasts <- paste(
      apply(indirect_combinations, 2, function(pair) {
        paste0("CI_", pair[1], "_vs_", pair[2],
               " := indirect_", pair[1], " - indirect_", pair[2])
      }),
      collapse = "\n"
    )
  }

  # 前后测转换系数
  pre_post_coefficients <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      x1_bi <- paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2")
      x0_bi <- paste0("X0_b", i, " := X1_b", i, " - d", i)
      paste(x1_bi, x0_bi, sep = "\n")
    }),
    collapse = "\n"
  )

  # 汇总并输出模型语法
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

