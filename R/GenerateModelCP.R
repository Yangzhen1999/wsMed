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

GenerateModelCP <- function(prepared_data, MP = character(0)) {

  ## ---------- 变量提取 ----------
  chain_md  <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_ma  <- grep("^M1avg$",  colnames(prepared_data), value = TRUE)
  all_md    <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_ma    <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))
  par_md    <- setdiff(all_md, chain_md)
  par_ma    <- setdiff(all_ma, chain_ma)
  n_par     <- length(par_md)

  ## ---- C（between / within） ----
  between <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  controls<- c(between, within)
  ctrl_rhs<- if (length(controls)) paste(controls, collapse = " + ") else NULL

  ## ---- W & 交互項 ----
  Wvars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  ints  <- grep("^int_", colnames(prepared_data), value = TRUE)

  add_int <- function(path_stub, pat_stub, coef_stub) {
    hits <- grep(pat_stub, ints, value = TRUE)
    if (!length(hits)) return(NULL)
    wtag <- sub("^.*_(W\\d+)$", "\\1", hits)
    paste0(coef_stub, "_", wtag, "*", hits)
  }

  ## ========== Step‑1  Ydiff ==========
  y_rhs <- c("cp*1",
             paste0("b1*", chain_md),
             paste0("d1*", chain_ma))
  ## 链式 → parallel 部分
  for (i in seq_len(n_par)) {
    idx <- i + 1
    y_rhs <- c(y_rhs,
               paste0("b", idx, "*", par_md[i]),
               paste0("d", idx, "*", par_ma[i]))
  }
  ## 调节项
  if ("cp" %in% MP && length(Wvars))
    y_rhs <- c(y_rhs, paste0("cpw_", Wvars, "*", Wvars))
  if ("b1" %in% MP)
    y_rhs <- c(y_rhs, add_int("b1", paste0("^int_", chain_md, "_"), "bw1"))
  if ("d1" %in% MP)
    y_rhs <- c(y_rhs, add_int("d1", paste0("^int_", chain_ma, "_"), "dw1"))
  for (i in seq_len(n_par)) {
    idx <- i + 1
    if (paste0("b", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("b", idx),
                                paste0("^int_", par_md[i], "_"),
                                paste0("bw", idx)))
    if (paste0("d", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("d", idx),
                                paste0("^int_", par_ma[i], "_"),
                                paste0("dw", idx)))
  }
  if (!is.null(ctrl_rhs)) y_rhs <- c(y_rhs, ctrl_rhs)
  regY <- paste("Ydiff ~", paste(y_rhs, collapse = " + "))

  ## ========== Step‑2  M1diff ==========
  rhs1 <- c("a1*1")
  if ("a1" %in% MP && length(Wvars))
    rhs1 <- c(rhs1, paste0("aw1_", Wvars, "*", Wvars))
  if (!is.null(ctrl_rhs)) rhs1 <- c(rhs1, ctrl_rhs)
  regM_chain <- paste(chain_md, "~", paste(rhs1, collapse = " + "))

  ## ========== Step‑3  Parallel mediators ==========
  regM_par <- character(n_par)
  for (i in seq_len(n_par)) {
    idx <- i + 1
    rhs <- c(paste0("a", idx, "*1"),
             paste0("b_1_", idx, "*", chain_md),
             paste0("d_1_", idx, "*", chain_ma))
    if (paste0("a", idx) %in% MP && length(Wvars))
      rhs <- c(rhs, paste0("aw", idx, "_", Wvars, "*", Wvars))
    if (paste0("b_1_", idx) %in% MP)
      rhs <- c(rhs, add_int(paste0("b_1_", idx),
                            paste0("^int_", chain_md, "_"),
                            paste0("bw_1_", idx)))
    if (paste0("d_1_", idx) %in% MP)
      rhs <- c(rhs, add_int(paste0("d_1_", idx),
                            paste0("^int_", chain_ma, "_"),
                            paste0("dw_1_", idx)))
    if (!is.null(ctrl_rhs)) rhs <- c(rhs, ctrl_rhs)
    regM_par[i] <- paste(par_md[i], "~", paste(rhs, collapse = " + "))
  }

  ## ========== Step‑4  间接效应 ==========
  ind_lines <- c("indirect_1 := a1 * b1")
  ind_names <- "indirect_1"
  for (i in seq_len(n_par)) {
    idx <- i + 1
    ind_lines <- c(ind_lines,
                   paste0("indirect_", idx, " := a", idx, " * b", idx),
                   paste0("indirect_1_", idx, " := a1 * b_1_", idx, " * b", idx))
    ind_names <- c(ind_names, paste0("indirect_", idx), paste0("indirect_1_", idx))
  }
  tot_ind <- paste("total_indirect :=", paste(ind_names, collapse = " + "))
  tot_eff <- "total_effect := cp + total_indirect"

  ## ========== 汇总 ==========
  paste(c(regY, regM_chain, regM_par, ind_lines, tot_ind, tot_eff),
        collapse = "\n")
}


GenerateModelCP <- function(prepared_data, MP = character(0)) {

  ## ---------- 变量提取 ----------
  chain_md  <- grep("^M1diff$", colnames(prepared_data), value = TRUE)
  chain_ma  <- grep("^M1avg$",  colnames(prepared_data), value = TRUE)
  all_md    <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  all_ma    <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))
  par_md    <- setdiff(all_md, chain_md)
  par_ma    <- setdiff(all_ma, chain_ma)
  n_par     <- length(par_md)

  ## ---- C（between / within） ----
  between <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  controls<- c(between, within)
  ctrl_rhs<- if (length(controls)) paste(controls, collapse = " + ") else NULL

  ## ---- W & 交互項 ----
  Wvars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  ints  <- grep("^int_", colnames(prepared_data), value = TRUE)
  Winfo <- attr(prepared_data, "W_info")
  if (!is.null(Winfo) && isTRUE(Winfo$type == "continuous"))
    Wvars <- Wvars[1]  # 连续型只保留一个主效应变量

  add_int <- function(path_stub, pat_stub, coef_stub) {
    hits <- grep(pat_stub, ints, value = TRUE)
    if (!length(hits)) return(NULL)
    wtag <- sub("^.*_(W\\d+)$", "\\1", hits)
    paste0(coef_stub, "_", wtag, "*", hits)
  }

  ## ========== Step‑1  Ydiff ==========
  y_rhs <- c("cp*1",
             paste0("b1*", chain_md),
             paste0("d1*", chain_ma))
  for (i in seq_len(n_par)) {
    idx <- i + 1
    y_rhs <- c(y_rhs,
               paste0("b", idx, "*", par_md[i]),
               paste0("d", idx, "*", par_ma[i]))
  }
  if ("cp" %in% MP && length(Wvars))
    y_rhs <- c(y_rhs, paste0("cpw_", Wvars, "*", Wvars))
  if (!"cp" %in% MP && length(Wvars))
    y_rhs <- c(y_rhs, Wvars)
  if ("b1" %in% MP)
    y_rhs <- c(y_rhs, add_int("b1", paste0("^int_", chain_md, "_"), "bw1"))
  if ("d1" %in% MP)
    y_rhs <- c(y_rhs, add_int("d1", paste0("^int_", chain_ma, "_"), "dw1"))
  for (i in seq_len(n_par)) {
    idx <- i + 1
    if (paste0("b", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("b", idx), paste0("^int_", par_md[i], "_"), paste0("bw", idx)))
    if (paste0("d", idx) %in% MP)
      y_rhs <- c(y_rhs, add_int(paste0("d", idx), paste0("^int_", par_ma[i], "_"), paste0("dw", idx)))
  }
  if (!is.null(ctrl_rhs)) y_rhs <- c(y_rhs, ctrl_rhs)
  regY <- paste("Ydiff ~", paste(y_rhs, collapse = " + "))

  ## ========== Step‑2  M1diff ==========
  rhs1 <- c("a1*1")
  if ("a1" %in% MP && length(Wvars))
    rhs1 <- c(rhs1, paste0("aw1_", Wvars, "*", Wvars))
  if (!"a1" %in% MP && length(Wvars))
    rhs1 <- c(rhs1, Wvars)
  if (!is.null(ctrl_rhs)) rhs1 <- c(rhs1, ctrl_rhs)
  regM_chain <- paste(chain_md, "~", paste(rhs1, collapse = " + "))

  ## ========== Step‑3  Parallel mediators ==========
  regM_par <- character(n_par)
  for (i in seq_len(n_par)) {
    idx <- i + 1
    rhs <- c(paste0("a", idx, "*1"),
             paste0("b_1_", idx, "*", chain_md),
             paste0("d_1_", idx, "*", chain_ma))
    if (paste0("a", idx) %in% MP && length(Wvars))
      rhs <- c(rhs, paste0("aw", idx, "_", Wvars, "*", Wvars))
    if (!paste0("a", idx) %in% MP && length(Wvars))
      rhs <- c(rhs, Wvars)
    if (paste0("b_1_", idx) %in% MP)
      rhs <- c(rhs, add_int(paste0("b_1_", idx), paste0("^int_", chain_md, "_"), paste0("bw_1_", idx)))
    if (paste0("d_1_", idx) %in% MP)
      rhs <- c(rhs, add_int(paste0("d_1_", idx), paste0("^int_", chain_ma, "_"), paste0("dw_1_", idx)))
    if (!is.null(ctrl_rhs)) rhs <- c(rhs, ctrl_rhs)
    regM_par[i] <- paste(par_md[i], "~", paste(rhs, collapse = " + "))
  }

  ## ========== Step‑4  间接效应 ==========
  ind_lines <- c("indirect_1 := a1 * b1")
  ind_names <- "indirect_1"
  for (i in seq_len(n_par)) {
    idx <- i + 1
    ind_lines <- c(ind_lines,
                   paste0("indirect_", idx, " := a", idx, " * b", idx),
                   paste0("indirect_1_", idx, " := a1 * b_1_", idx, " * b", idx))
    ind_names <- c(ind_names, paste0("indirect_", idx), paste0("indirect_1_", idx))
  }
  tot_ind <- paste("total_indirect :=", paste(ind_names, collapse = " + "))
  tot_eff <- "total_effect := cp + total_indirect"

  ## ========== 汇总 ==========
  paste(c(regY, regM_chain, regM_par, ind_lines, tot_ind, tot_eff),
        collapse = "\n")
}


