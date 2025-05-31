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
#' @seealso [PrepareData()], [wsMed()], [GenerateModelP()]
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
  Mdiff_vars <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  Mavg_vars  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))
  n <- length(Mdiff_vars)
  if (n < 1) stop("The function requires at least one mediator.")

  # 控制变量
  between_covs <- grep("^Cb\\d+$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)
  control_rhs  <- if (length(control_vars) > 0) paste(control_vars, collapse = " + ") else NULL

  # 构造 Ydiff 的回归方程
  y_rhs <- c(
    "cp*1",
    paste0("b", 1:n, "*", Mdiff_vars),
    paste0("d", 1:n, "*", Mavg_vars),
    control_rhs
  )
  regression_y <- paste("Ydiff ~", paste(na.omit(y_rhs), collapse = " + "))

  # 构造每个 Mdiff 的回归方程
  regression_m <- character(n)
  for (i in 1:n) {
    if (i == 1) {
      rhs <- c(paste0("a1*1"), control_rhs)
    } else {
      chain_b <- paste(
        sapply((i - 1):1, function(j) paste0("b_", j, "_", i, "*", Mdiff_vars[j])),
        collapse = " + "
      )
      chain_d <- paste(
        sapply((i - 1):1, function(j) paste0("d_", j, "_", i, "*", Mavg_vars[j])),
        collapse = " + "
      )
      rhs <- c(paste0("a", i, "*1"), chain_b, chain_d, control_rhs)
    }
    regression_m[i] <- paste(Mdiff_vars[i], "~", paste(na.omit(rhs), collapse = " + "))
  }

  # 构造间接效应
  generate_path_effects <- function(paths) {
    paste0("a", paths[1], " * ", paste(
      c(
        sapply(1:(length(paths) - 1), function(i) paste0("b_", paths[i], "_", paths[i + 1])),
        paste0("b", paths[length(paths)])
      ),
      collapse = " * "
    ))
  }

  indirect_effects <- c()
  indirect_effect_labels <- c()
  for (len in 1:n) {
    path_combinations <- utils::combn(1:n, len, simplify = FALSE)
    for (path in path_combinations) {
      label <- paste0("indirect_", paste(path, collapse = "_"))
      if (length(path) == 1) {
        indirect_effects <- c(indirect_effects, paste0(label, " := a", path, " * b", path))
      } else {
        indirect_effects <- c(indirect_effects, paste0(label, " := ", generate_path_effects(path)))
      }
      indirect_effect_labels <- c(indirect_effect_labels, label)
    }
  }

  total_indirect <- paste0("total_indirect := ", paste(indirect_effect_labels, collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  # 对比效应
  compare_indirect_effect <- ""
  if (length(indirect_effect_labels) > 1) {
    comparisons <- c()
    for (i in seq_along(indirect_effect_labels)) {
      for (j in seq_along(indirect_effect_labels)) {
        if (i < j) {
          label_i <- gsub("indirect_", "", indirect_effect_labels[i])
          label_j <- gsub("indirect_", "", indirect_effect_labels[j])
          comparisons <- c(comparisons, paste0(
            "CI_", label_i, "_vs_", label_j, " := ",
            indirect_effect_labels[i], " - ", indirect_effect_labels[j]
          ))
        }
      }
    }
    compare_indirect_effect <- paste(comparisons, collapse = "\n")
  }


  first_order <- sapply(1:n, function(i) {
    x1 <- paste0("X1_b", i)
    x0 <- paste0("X0_b", i)
    paste0(
      x1, " := (2*b", i, " + d", i, ")/2\n",
      x0, " := ", x1, " - d", i
    )
  })

  # 提取所有路径中出现的 b_ 和 d_ 标签（从 indirect_effects 中提取）
  # 新版：同时匹配一阶和多阶（b1、b_1_2、b_1_2_3...）
  b_labels <- unique(unlist(regmatches(indirect_effects, gregexpr("b[0-9_]+", indirect_effects))))
  d_labels <- unique(unlist(regmatches(indirect_effects, gregexpr("d[0-9_]+", indirect_effects))))
  all_labels <- union(b_labels, d_labels)

  # 为这些有效 label 构造对应的前后测公式
  higher_order <- sapply(all_labels, function(label) {
    x1 <- paste0("X1_", label)
    x0 <- paste0("X0_", label)
    paste0(
      x1, " := (2*", label, " + ", gsub("^b", "d", label), ")/2\n",
      x0, " := ", x1, " - ", gsub("^b", "d", label)
    )
  })



  model_text <- c(regression_y, regression_m, indirect_effects)


  used_b_labels <- unique(unlist(regmatches(model_text, gregexpr("b(\\d+|(_\\d+)+)", model_text))))
  used_d_labels <- unique(unlist(regmatches(model_text, gregexpr("d(\\d+|(_\\d+)+)", model_text))))


  b_label_keys <- gsub("^b", "", used_b_labels)
  d_label_keys <- gsub("^d", "", used_d_labels)
  shared_keys <- intersect(b_label_keys, d_label_keys)

  # 生成对应的 X1_bx 与 X0_bx
  pre_post_lines <- sapply(all_labels, function(label) {
    if (!grepl("^b", label)) return(NULL)  # 只对 b 标签生成
    d_label <- gsub("^b", "d", label)
    x1_name <- paste0("X1_", label)
    x0_name <- paste0("X0_", label)
    paste0(
      x1_name, " := (2*", label, " + ", d_label, ")/2\n",
      x0_name, " := ", x1_name, " - ", d_label
    )
  })

  pre_post_coefficients <- paste(pre_post_lines, collapse = "\n")


  # 拼接所有模型部分
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

