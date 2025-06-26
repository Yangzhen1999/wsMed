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
#' @param MP A character vector specifying which paths are moderated by variable(s) W.
#'           Valid entries include:
#'           - \code{"a2"}, \code{"a3"}, ...: moderation on the a paths (W → Mdiff), for mediators beyond M1.
#'           - \code{"b2"}, \code{"b3"}, ...: moderation on the b paths (Mdiff × W → Ydiff).
#'           - \code{"b_1_2"}, \code{"b_2_3"}, ...: moderation on cross-paths from one mediator to the next (e.g., M1 → M2).
#'           - \code{"d2"}, \code{"d3"}, ...: moderation on the d paths (Mavg × W → Ydiff).
#'           - \code{"d_1_2"}, \code{"d_2_3"}, ...: moderation on cross-paths from one Mavg to the next Mdiff.
#'           - \code{"cp"}: moderation on the direct effect from X to Y (i.e., W → Ydiff).
#'
#'           The function detects and inserts the correct interaction terms (e.g., \code{int_M2diff_W1}) based on these labels.
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

GenerateModelCN <- function(prepared_data, MP = character(0)) {

  ## -------- 变量 --------
  Md <- sort(grep("^M\\d+diff$", colnames(prepared_data), value = TRUE))
  Ma <- sort(grep("^M\\d+avg$",  colnames(prepared_data), value = TRUE))
  nM <- length(Md);  if (nM < 1) stop("Need at least one mediator.")

  between <- grep("^Cb\\d+(_\\d+)?$", colnames(prepared_data), value = TRUE)
  within  <- grep("^Cw\\d+(diff|avg)$", colnames(prepared_data), value = TRUE)
  controls<- c(between, within)
  ctrl_rhs<- if (length(controls)) paste(controls, collapse = " + ") else NULL

  ## ---- W 与交互列 ----
  Wvars <- grep("^W\\d+$", colnames(prepared_data), value = TRUE)
  Winfo <- attr(prepared_data, "W_info")
  if (!is.null(Winfo) && isTRUE(Winfo$type == "continuous"))
    Wvars <- Wvars[1]           # 连续 W 只保留第一个
  if (length(Wvars) == 1)       # 安全起见
    Wvars <- Wvars[1]

  int_vars <- grep("^int_", colnames(prepared_data), value = TRUE)

  ## ——— 帮助函数：仅保留 wtag ∈ Wvars ———
  add_mod_terms <- function(pat_stub, param_stub) {
    hits <- grep(pat_stub, int_vars, value = TRUE)
    if (!length(hits)) return(NULL)
    keep <- sub("^.*_(W\\d+)$", "\\1", hits) %in% Wvars
    hits <- hits[keep]
    if (!length(hits)) return(NULL)
    wtags <- sub("^.*_(W\\d+)$", "\\1", hits)
    paste0(param_stub, "_", wtags, "*", hits)
  }

  ## ---------- Ydiff ----------
  y_rhs <- c("cp*1")
  for (i in seq_len(nM)) {
    y_rhs <- c(y_rhs,
               paste0("b", i, "*", Md[i]),
               paste0("d", i, "*", Ma[i]))
    if (paste0("b", i) %in% MP && length(Wvars))
      y_rhs <- c(y_rhs, add_mod_terms(paste0("^int_M", i, "diff_"), paste0("bw", i)))
    if (paste0("d", i) %in% MP)
      y_rhs <- c(y_rhs, add_mod_terms(paste0("^int_M", i, "avg_"), paste0("dw", i)))
  }
  if ("cp" %in% MP && length(Wvars))
    y_rhs <- c(y_rhs, paste0("cpw_", Wvars, "*", Wvars))
  if (length(Wvars))
    y_rhs <- c(y_rhs, Wvars)  # 添加主效应 W
  if (!is.null(ctrl_rhs)) y_rhs <- c(y_rhs, ctrl_rhs)
  regY <- paste("Ydiff ~", paste(y_rhs, collapse = " + "))

  ## ---------- 每个 M 回归 ----------
  regM <- character(nM)
  for (i in seq_len(nM)) {
    rhs <- c(paste0("a", i, "*1"))
    if (paste0("a", i) %in% MP && length(Wvars))
      rhs <- c(rhs, paste0("aw", i, "_", Wvars, "*", Wvars))

    if (i > 1)
      for (j in seq_len(i-1)) {
        rhs <- c(rhs,
                 paste0("b_", j, "_", i, "*", Md[j]),
                 paste0("d_", j, "_", i, "*", Ma[j]))
        if (paste0("b_", j, "_", i) %in% MP)
          rhs <- c(rhs, add_mod_terms(paste0("^int_", Md[j], "_"), paste0("bw_", j, "_", i)))
        if (paste0("d_", j, "_", i) %in% MP)
          rhs <- c(rhs, add_mod_terms(paste0("^int_", Ma[j], "_"), paste0("dw_", j, "_", i)))
      }

    if (length(Wvars))
      rhs <- c(rhs, Wvars)  # 添加主效应 W
    if (!is.null(ctrl_rhs)) rhs <- c(rhs, ctrl_rhs)
    regM[i] <- paste(Md[i], "~", paste(rhs, collapse = " + "))
  }

  ## ---------- 清理重复主效应项 ----------
  for (i in seq_along(regM)) {
    for (w in Wvars) {
      if (grepl(paste0("aw", i, "_", w, "\\*", w), regM[i])) {
        regM[i] <- gsub(paste0("\\s*\\+\\s*", w, "(?=\\s|$)"), "", regM[i], perl = TRUE)
      }
    }
  }
  if (length(Wvars)) {
    for (w in Wvars) {
      if (grepl(paste0("cpw_", w, "\\*", w), regY)) {
        regY <- gsub(paste0("\\s*\\+\\s*", w, "(?=\\s|$)"), "", regY, perl = TRUE)
      }
    }
  }

  ## ---------- 间接效应 & 汇总 ----------
  make_ie <- function(pth){
    if (length(pth)==1) return(paste0("a", pth, " * b", pth))
    last <- pth[length(pth)]
    mid <- paste(sapply(seq_along(pth)[-1], function(k) paste0("b_", pth[k-1], "_", pth[k])), collapse=" * ")
    paste0("a", pth[1], " * ", mid, " * b", last)
  }

  ie_lines <- ie_names <- c()
  for (len in 1:nM)
    for (pth in utils::combn(nM,len, simplify=FALSE)){
      nm <- paste0("indirect_",paste(pth,collapse="_"))
      ie_lines <- c(ie_lines, paste(nm,":=",make_ie(pth)))
      ie_names <- c(ie_names, nm)
    }
  paste(c(regY, regM,
          ie_lines,
          paste("total_indirect :=", paste(ie_names, collapse=" + ")),
          "total_effect := cp + total_indirect"),
        collapse = "\n")
}


