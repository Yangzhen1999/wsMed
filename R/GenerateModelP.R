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


GenerateModelP <- function(prepared_data,
                           MP = character(0)) {

  ## ---------- 识别变量 ----------
  Mdiff_vars <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  Mavg_vars  <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))

  between_covs <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within_covs  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  control_vars <- c(between_covs, within_covs)

  W_vars          <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  interaction_vars <- grep("^int_", colnames(prepared_data), value = TRUE)

  ## ---------- Ydiff 回归 ----------
  y_terms <- c("cp*1")
  for (i in seq_along(Mdiff_vars)) {
    y_terms <- c(y_terms,
                 paste0("b", i, "*", Mdiff_vars[i]),
                 paste0("d", i, "*", Mavg_vars[i]))
  }

  for (mp in MP) {
    if (grepl("^b\\d+$", mp)) {
      idx <- sub("^b", "", mp)
      for (w in W_vars)
        if (length(match <- grep(paste0("^int_M", idx, "diff_", w, "$"),
                                 interaction_vars, value = TRUE)))
          y_terms <- c(y_terms, paste0("bw", idx, "_", w, "*", match))
    }
    if (grepl("^d\\d+$", mp)) {
      idx <- sub("^d", "", mp)
      for (w in W_vars)
        if (length(match <- grep(paste0("^int_M", idx, "avg_", w, "$"),
                                 interaction_vars, value = TRUE)))
          y_terms <- c(y_terms, paste0("dw", idx, "_", w, "*", match))
    }
  }
  if ("cp" %in% MP && length(W_vars))
    y_terms <- c(y_terms, paste0("cpw_", W_vars, "*", W_vars))
  else if (length(W_vars))
    y_terms <- c(y_terms, W_vars)

  if (length(control_vars))
    y_terms <- c(y_terms, control_vars)

  regression_y <- paste("Ydiff ~", paste(unique(y_terms), collapse = " + "))

  ## ---------- 每个 Mdiff 回归 ----------
  regression_m <- sapply(seq_along(Mdiff_vars), function(i) {
    rhs <- c(paste0("a", i, "*1"))
    if (paste0("a", i) %in% MP && length(W_vars)) {
      rhs <- c(rhs, paste0("aw", i, "_", W_vars, "*", W_vars))
    } else if (length(W_vars)) {
      rhs <- c(rhs, W_vars)
    }
    if (length(control_vars))
      rhs <- c(rhs, control_vars)
    paste0(Mdiff_vars[i], " ~ ", paste(unique(rhs), collapse = " + "))
  })
  regression_m <- paste(regression_m, collapse = "\n")

  ## ---------- 基础间接效应 ----------
  indirect_effects <- paste(
    sapply(seq_along(Mdiff_vars),
           function(i) paste0("indirect_", i, " := a", i, " * b", i)),
    collapse = "\n"
  )
  total_indirect <- paste0("total_indirect := ",
                           paste0("indirect_", seq_along(Mdiff_vars), collapse = " + "))
  total_effect <- "total_effect := cp + total_indirect"

  sem_model <- paste(regression_y,
                     regression_m,
                     indirect_effects,
                     total_indirect,
                     total_effect,
                     sep = "\n")

  return(sem_model)
}

