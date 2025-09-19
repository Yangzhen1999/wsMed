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


GenerateModelPC <- function(prepared_data, MP = character(0)) {

  ## ---------- 变量 ----------
  chain_md <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_ma <- grep("^M1avg$",  colnames(prepared_data), value = TRUE)
  all_md   <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_ma   <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))
  par_md   <- setdiff(all_md, chain_md)
  par_ma   <- setdiff(all_ma, chain_ma)
  n_par    <- length(par_md)

  between <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  controls<- c(between, within)
  ctrl_rhs<- if (length(controls)) paste(controls, collapse = " + ") else NULL

  Wvars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  ints  <- grep("^int_", colnames(prepared_data), value = TRUE)

  add_int <- function(pat_stub, coef_stub) {
    hits <- grep(pat_stub, ints, value = TRUE)
    if (!length(hits)) return(NULL)
    wtag <- sub("^.*_(W\\d+)$", "\\1", hits)
    paste0(coef_stub, "_", wtag, "*", hits)
  }

  ## ---------- Ydiff ----------
  y_rhs <- c("cp*1", paste0("b1*", chain_md), paste0("d1*", chain_ma),
             paste0("b", 2:(n_par+1), "*", par_md),
             paste0("d", 2:(n_par+1), "*", par_ma))
  if ("cp" %in% MP && length(Wvars))
    y_rhs <- c(y_rhs, paste0("cpw_", Wvars, "*", Wvars))
  if ("b1" %in% MP)
    y_rhs <- c(y_rhs, add_int(paste0("^int_", chain_md, "_"), "bw1"))
  if ("d1" %in% MP)
    y_rhs <- c(y_rhs, add_int(paste0("^int_", chain_ma, "_"), "dw1"))
  for (i in seq_len(n_par)) {
    idx <- i + 1
    if (paste0("b", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("^int_", par_md[i], "_"), paste0("bw", idx)))
    if (paste0("d", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("^int_", par_ma[i], "_"), paste0("dw", idx)))
  }
  if (!is.null(ctrl_rhs)) y_rhs <- c(y_rhs, ctrl_rhs)
  regY <- paste("Ydiff ~", paste(y_rhs, collapse = " + "))

  ## ---------- 链首 parallel mediators ----------
  regM_par <- sapply(seq_along(par_md), function(i){
    idx <- i + 1
    rhs <- c(paste0("a", idx, "*1"))
    if (paste0("a", idx) %in% MP && length(Wvars))
      rhs <- c(rhs, paste0("aw", idx, "_", Wvars, "*", Wvars))
    if (!is.null(ctrl_rhs)) rhs <- c(rhs, ctrl_rhs)
    paste(par_md[i], "~", paste(rhs, collapse = " + "))
  })

  ## ---------- M1diff （链尾）----------
  rhs_chain <- c("a1*1")
  if ("a1" %in% MP && length(Wvars))
    rhs_chain <- c(rhs_chain, paste0("aw1_", Wvars, "*", Wvars))
  for (i in seq_along(par_md)) {
    idx <- i + 1
    rhs_chain <- c(rhs_chain,
                   paste0("b_", idx, "_1*", par_md[i]),
                   paste0("d_", idx, "_1*", par_ma[i]))
    if (paste0("b_", idx, "_1") %in% MP)
      rhs_chain <- c(rhs_chain, add_int(paste0("^int_", par_md[i], "_"),
                                        paste0("bw_", idx, "_1")))
    if (paste0("d_", idx, "_1") %in% MP)
      rhs_chain <- c(rhs_chain, add_int(paste0("^int_", par_ma[i], "_"),
                                        paste0("dw_", idx, "_1")))
  }
  if (!is.null(ctrl_rhs)) rhs_chain <- c(rhs_chain, ctrl_rhs)
  regM_chain <- paste(chain_md, "~", paste(rhs_chain, collapse = " + "))

  ## ---------- 间接效应 ----------
  ind_lines <- c("indirect_1 := a1 * b1")
  ind_names <- "indirect_1"
  for (i in seq_along(par_md)) {
    idx <- i + 1
    ind_lines <- c(ind_lines,
                   paste0("indirect_", idx, " := a", idx, " * b", idx),
                   paste0("indirect_", idx, "_1 := a", idx, " * b_", idx, "_1 * b1"))
    ind_names <- c(ind_names,
                   paste0("indirect_", idx),
                   paste0("indirect_", idx, "_1"))
  }
  tot_ind <- paste("total_indirect :=", paste(ind_names, collapse = " + "))
  tot_eff <- "total_effect := cp + total_indirect"

  ## ---------- 汇总 ----------
  paste(c(regY, regM_par, regM_chain, ind_lines, tot_ind, tot_eff),
        collapse = "\n")
}


GenerateModelPC <- function(prepared_data, MP = character(0)) {

  ## ---------- 变量 ----------
  chain_md <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_ma <- grep("^M1avg$",  colnames(prepared_data), value = TRUE)
  all_md   <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_ma   <- sort(grep("^M\\d+avg$", colnames(prepared_data), value = TRUE))
  par_md   <- setdiff(all_md, chain_md)
  par_ma   <- setdiff(all_ma, chain_ma)
  n_par    <- length(par_md)

  between <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  controls<- c(between, within)
  ctrl_rhs<- if (length(controls)) paste(controls, collapse = " + ") else NULL

  Wvars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  ints  <- grep("^int_", colnames(prepared_data), value = TRUE)

  add_int <- function(pat_stub, coef_stub) {
    hits <- grep(pat_stub, ints, value = TRUE)
    if (!length(hits)) return(NULL)
    wtag <- sub("^.*_(W\\d+)$", "\\1", hits)
    paste0(coef_stub, "_", wtag, "*", hits)
  }

  ## ---------- Ydiff ----------
  y_rhs <- c("cp*1", paste0("b1*", chain_md), paste0("d1*", chain_ma),
             paste0("b", 2:(n_par+1), "*", par_md),
             paste0("d", 2:(n_par+1), "*", par_ma))
  if ("cp" %in% MP && length(Wvars)) {
    y_rhs <- c(y_rhs, paste0("cpw_", Wvars, "*", Wvars))
  } else if (!("cp" %in% MP) && length(Wvars)) {
    y_rhs <- c(y_rhs, Wvars)
  }
  if ("b1" %in% MP)
    y_rhs <- c(y_rhs, add_int(paste0("^int_", chain_md, "_"), "bw1"))
  if ("d1" %in% MP)
    y_rhs <- c(y_rhs, add_int(paste0("^int_", chain_ma, "_"), "dw1"))
  for (i in seq_len(n_par)) {
    idx <- i + 1
    if (paste0("b", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("^int_", par_md[i], "_"), paste0("bw", idx)))
    if (paste0("d", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("^int_", par_ma[i], "_"), paste0("dw", idx)))
  }
  if (!is.null(ctrl_rhs)) y_rhs <- c(y_rhs, ctrl_rhs)
  regY <- paste("Ydiff ~", paste(y_rhs, collapse = " + "))

  ## ---------- 链首 parallel mediators ----------
  regM_par <- sapply(seq_along(par_md), function(i){
    idx <- i + 1
    rhs <- c(paste0("a", idx, "*1"))
    if (paste0("a", idx) %in% MP && length(Wvars)) {
      rhs <- c(rhs, paste0("aw", idx, "_", Wvars, "*", Wvars))
    } else if (length(Wvars)) {
      rhs <- c(rhs, Wvars)
    }
    if (!is.null(ctrl_rhs)) rhs <- c(rhs, ctrl_rhs)
    paste(par_md[i], "~", paste(rhs, collapse = " + "))
  })

  ## ---------- M1diff （链尾）----------
  rhs_chain <- c("a1*1")
  if ("a1" %in% MP && length(Wvars)) {
    rhs_chain <- c(rhs_chain, paste0("aw1_", Wvars, "*", Wvars))
  } else if (length(Wvars)) {
    rhs_chain <- c(rhs_chain, Wvars)
  }
  for (i in seq_along(par_md)) {
    idx <- i + 1
    rhs_chain <- c(rhs_chain,
                   paste0("b_", idx, "_1*", par_md[i]),
                   paste0("d_", idx, "_1*", par_ma[i]))
    if (paste0("b_", idx, "_1") %in% MP)
      rhs_chain <- c(rhs_chain, add_int(paste0("^int_", par_md[i], "_"), paste0("bw_", idx, "_1")))
    if (paste0("d_", idx, "_1") %in% MP)
      rhs_chain <- c(rhs_chain, add_int(paste0("^int_", par_ma[i], "_"), paste0("dw_", idx, "_1")))
  }
  if (!is.null(ctrl_rhs)) rhs_chain <- c(rhs_chain, ctrl_rhs)
  regM_chain <- paste(chain_md, "~", paste(rhs_chain, collapse = " + "))

  ## ---------- 间接效应 ----------
  ind_lines <- c("indirect_1 := a1 * b1")
  ind_names <- "indirect_1"
  for (i in seq_along(par_md)) {
    idx <- i + 1
    ind_lines <- c(ind_lines,
                   paste0("indirect_", idx, " := a", idx, " * b", idx),
                   paste0("indirect_", idx, "_1 := a", idx, " * b_", idx, "_1 * b1"))
    ind_names <- c(ind_names,
                   paste0("indirect_", idx),
                   paste0("indirect_", idx, "_1"))
  }
  tot_ind <- paste("total_indirect :=", paste(ind_names, collapse = " + "))
  tot_eff <- "total_effect := cp + total_indirect"

  ## ---------- 汇总 ----------
  paste(c(regY, regM_par, regM_chain, ind_lines, tot_ind, tot_eff),
        collapse = "\n")
}





