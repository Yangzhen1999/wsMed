# -----------------------------------------------------------------------------
# print_helpers.R-Internal utilities for print.wsMed()  --------------------
# -----------------------------------------------------------------------------

# =============================================================================
# 1. Generic numeric / table utilities
# =============================================================================

#' Format a numeric vector with fixed width and precision
#'
#' Convenience wrapper around [formatC()] that returns a *character* vector
#' with a fixed number of decimal places and total field width so that columns
#' line up neatly in console/markdown output.
#'
#' @param x      Numeric vector to be formatted.
#' @param digits Integer. Number of digits after the decimal point.
#' @param width  Integer or NULL. Total field width passed to [formatC()].
#'               If NULL, the helper uses a default width of 10 when
#'               digits <= 4, otherwise 12.
#'
#' @return A **character** vector the same length as *x*.
#' @keywords internal
#' @noRd
.fmt_num <- function(x, digits, width = NULL) {
  if (is.null(width)) width <- if (digits <= 4) 10 else 12
  formatC(x, format = "f", digits = digits, width = width, flag = " ")
}

#' Pretty print a data frame with smart alignment
#'
#' Numeric columns are formatted via [.fmt_num()] and printed with
#' right alignment; non numeric columns default to left alignment.  Specific
#' columns can be forced right aligned via *right_align*.
#'
#' @param df          A data.frame to print.
#' @param digits      Integer. Decimal places for numeric columns (default 3).
#' @param right_align Optional character vector of column names to right-align
#'                    even if they are not numeric.
#'
#' @return Invisibly returns *df* (the input). The function is called for its
#'         printing side-effect.
#' @keywords internal
#' @noRd
.print_tbl <- function(df, digits = 3, right_align = NULL) {
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], formatC, digits = digits, format = "f")

  align <- ifelse(num, "r", "l")
  if (!is.null(right_align)) {
    idx <- match(right_align, names(df), nomatch = 0L)
    align[idx[idx > 0]] <- "r"
  }
  print(knitr::kable(df, align = align, row.names = FALSE))
  invisible(df)
}

#' Build a compact Monte-Carlo parameter table (Estimate / SE / CI)
#'
#' @param mc   List with two elements:
#'   \describe{
#'     \item{\code{thetahat}}{Named numeric vector of point estimates.}
#'     \item{\code{thetahatstar}}{Matrix of draws}}
#' @param alpha Numeric in (0,1). Significance level.
#'
#' @return A data.frame with columns *name*, *Estimate*, *SE* and two CI
#'   columns (e.g., "2.5%CI.Lo", "97.5%CI.Up").
#' @keywords internal
#' @noRd
.mc_param_table <- function(mc, alpha) {
  est <- mc$thetahat$est
  se  <- apply(mc$thetahatstar, 2, stats::sd)
  pr  <- c(alpha / 2, 1 - alpha / 2)
  ci  <- t(apply(mc$thetahatstar, 2, stats::quantile, probs = pr))
  colnames(ci) <- sprintf("%.1f%%CI.%s", pr * 100, c("Lo", "Up"))
  data.frame(name = names(est), Estimate = est, SE = se, ci,
             row.names = NULL, check.names = FALSE)
}

# =============================================================================
# 2. Keys & lookup helpers
# =============================================================================

#' Print a lookup table that maps indirect-effect labels to explicit paths
#'
#' @param x A wsMed object that contains mc$result (Monte-Carlo outcome) and
#'          data (prepared data set with Mdiff columns).
#'
#' @return Invisibly returns NULL. Called for its side-effect of printing.
#' @keywords internal
#' @noRd
.print_indirect_key <- function(x){
  if (is.null(x$mc$result$thetahat$est)) return(invisible())
  theta_names <- names(x$mc$result$thetahat$est)
  ind_names   <- grep("^indirect_\\d+", theta_names, value = TRUE)
  if (!length(ind_names)) return(invisible())

  mdiff_vars <- grep("^M\\d+diff$", names(x$data), value = TRUE)
  mnum <- gsub("^M(\\d+)diff$", "\\1", mdiff_vars)
  names(mdiff_vars) <- mnum

  key_tbl <- do.call(rbind, lapply(ind_names, function(ind_name){
    mids <- unlist(strsplit(sub("^indirect_", "", ind_name), "_"))
    data.frame(
      Ind  = sub("^indirect_", "ind_", ind_name),
      Path = paste("X ->", paste(mdiff_vars[mids], collapse = " -> "), "-> Ydiff")
    )
  }))
  cat("\nIndirect-effect key:\n")
  print(knitr::kable(key_tbl, align = "l", row.names = FALSE))
  invisible()
}
# =============================================================================
# Indirect-effect key （兼容 MC + Bootstrap）
# =============================================================================
.print_indirect_key <- function(x) {

  ## ---- 1  取得所有间接效应名称 ----------------------------------------
  ind_names <- character(0)

  ## 1-A  Monte-Carlo：thetahat$est
  if (!is.null(x$mc$result) &&
      !is.null(x$mc$result$thetahat$est)) {
    ind_names <- c(ind_names,
                   grep("^indirect_\\d+",
                        names(x$mc$result$thetahat$est),
                        value = TRUE))
  }

  ## 1-B  Bootstrap：param_boot（op == ":=" 且 lhs 以 indirect_ 开头）
  if (!is.null(x$param_boot) && nrow(x$param_boot)) {
    boot_ind <- with(x$param_boot,
                     lhs[ op == ":=" & grepl("^indirect_\\d+", lhs) ])
    ind_names <- c(ind_names, boot_ind)
  }

  ind_names <- unique(ind_names)
  if (!length(ind_names)) return(invisible())

  ## ---- 2  构造 Key 表 ------------------------------------------------
  mdiff_vars <- grep("^M\\d+diff$", names(x$data), value = TRUE)
  mnum <- sub("^M(\\d+)diff$", "\\1", mdiff_vars)
  names(mdiff_vars) <- mnum

  key_tbl <- do.call(rbind, lapply(ind_names, function(ind_name) {
    mids <- unlist(strsplit(sub("^indirect_", "", ind_name), "_"))
    data.frame(
      Ind  = sub("^indirect_", "ind_", ind_name),
      Path = paste("X ->",
                   paste(mdiff_vars[mids], collapse = " -> "),
                   "-> Ydiff"),
      check.names = FALSE)
  }))

  ## ---- 3  打印 -------------------------------------------------------
  cat("\nIndirect-effect key:\n")
  print(knitr::kable(key_tbl, align = "l", row.names = FALSE))
  invisible()
}

# =============================================================================
# 3. Variable & model-fit printers
# =============================================================================

#' Print a summary of variable names and sample size
#'
#' @param obj A wsMed object returned by [wsMed()].
#'
#' @return Invisibly returns NULL.
#' @keywords internal
#' @noRd
.print_variables <- function(obj) {
  iv <- obj$input_vars; if (is.null(iv)) return(invisible())
  cat("\n\n*************** VARIABLES ***************\n")
  cat("Outcome (Y):\n",
      "  Condition 1:", iv$Y_C1, "\n",
      "  Condition 2:", iv$Y_C2, "\n")
  cat("Mediators (M):\n")
  for (i in seq_along(iv$M_C1))
    cat(sprintf("  M%d:\n    Condition 1: %s\n    Condition 2: %s\n",
                i, iv$M_C1[i], iv$M_C2[i]))
  cinfo <- attr(obj$data, "C_info")
  if (!is.null(cinfo) && length(cinfo$raw)) {
    cat("Between-subject Covariates:\n")
    for (i in seq_along(cinfo$raw))
      cat("  ", cinfo$dummy_names[i], ":", cinfo$raw[i], "\n")
  }
  if (!is.null(iv$C_C1)) {
    cat("Within-subject Covariates:\n")
    for (i in seq_along(iv$C_C1))
      cat(sprintf("  Cw%d:\n    Condition 1: %s\n    Condition 2: %s\n",
                  i, iv$C_C1[i], iv$C_C2[i]))
  }
  winfo <- attr(obj$data, "W_info")
  if (!is.null(winfo) && length(winfo$raw)) {
    cat("Moderators (W):\n")
    for (i in seq_along(winfo$raw))
      cat("  ", winfo$dummy_names[i], ":", winfo$raw[i], "\n")
  }
  cat("Sample size (rows kept):", nrow(obj$data), "\n")
  invisible()
}

#' Print selected lavaan fit measures
#'
#' @param fit    A fitted lavaan model.
#' @param digits Integer. Decimal places for printed values.
#'
#' @return Invisibly returns NULL.
#' @keywords internal
#' @noRd
.print_fit <- function(fit, digits = 3) {
  if (is.null(fit)) return(invisible())
  fm <- lavaan::fitMeasures(fit,
                            c("chisq","df","pvalue","cfi","tli",
                              "rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
  tbl <- data.frame(Measure = c("Chi-Sq","df","p","CFI","TLI",
                                "RMSEA","RMSEA Low","RMSEA Up","SRMR"),
                    Value   = unname(fm))
  cat("\n\n*************** MODEL FIT ***************\n")
  .print_tbl(tbl, digits = digits)
  invisible()
}

# =============================================================================
# 4. Lavaan coefficient-label helper
# =============================================================================

#' Convert a lavaan lhs/rhs pair to a wsMed coefficient label
#'
#' @param lhs Character. Left-hand-side variable name.
#' @param rhs Character. Right-hand-side variable name.
#'
#' @return A character label (e.g., "b1", "aw1_W1") or NA_character_ if
#'         the pair does not map to a predefined coefficient.
#' @keywords internal
#' @noRd
.lav2coef <- function(lhs, rhs) {
  if (lhs == "Ydiff") {
    if (grepl("^M(\\d+)diff$", rhs))  return(paste0("b", sub("^M(\\d+)diff$", "\\1", rhs)))
    if (grepl("^M(\\d+)avg$",  rhs))  return(paste0("d", sub("^M(\\d+)avg$",  "\\1", rhs)))
    if (grepl("^int_M(\\d+)diff_", rhs)) return(sub("^int_", "bw", rhs))
    if (grepl("^int_M(\\d+)avg_",  rhs)) return(sub("^int_", "dw", rhs))
  }
  if (grepl("^M(\\d+)diff$", lhs) && grepl("^W\\d+$", rhs)) {
    idx <- sub("^M(\\d+)diff$", "\\1", lhs)
    return(paste0("aw", idx, "_", rhs))
  }
  NA_character_
}

# =============================================================================
# 5. MC-based regression / intercept / variance printer
# =============================================================================

#' Print regression paths, intercepts, and variances with MC estimates
#'
#' @param mc     Monte-Carlo list (elements thetahat, thetahatstar).
#' @param fit    A fitted lavaan model object.
#' @param alpha  Numeric in (0,1). Significance level for CIs.
#' @param digits Integer. Decimal places for numeric output.
#' @param title  Character. Suffix for section headers (default "MC").
#'
#' @return Invisibly returns NULL.
#' @keywords internal
#' @noRd
.print_mc_RIV <- function(mc, fit, alpha, digits = 3, title = "MC") {
  if (is.null(mc) || is.null(fit)) return(invisible())
  tbl  <- .mc_param_table(mc, alpha)
  lav  <- lavaan::parameterEstimates(fit, ci = FALSE)

  simple_key <- function(lhs, rhs, op) {
    switch(op,
           "~"  = paste0(lhs, "~", rhs),
           "~1" = paste0(lhs, "~1"),
           "~~" = paste0(lhs, "~~", rhs))
  }

  lav$coef_key <- mapply(function(lbl, lhs, op, rhs) {
    if (!is.na(lbl) && lbl != "" && lbl %in% tbl$name) return(lbl)
    key2 <- .lav2coef(lhs, rhs)
    if (!is.na(key2) && key2 %in% tbl$name) return(key2)
    simple_key(lhs, rhs, op)
  }, lav$label, lav$lhs, lav$op, lav$rhs, USE.NAMES = FALSE)

  safe_merge <- function(df, header) {
    df$Label <- lav$label[match(df$coef_key, lav$coef_key)]
    m <- merge(df, tbl, by.x = "coef_key", by.y = "name", all.x = TRUE, sort = FALSE)
    ci <- grep("%CI", names(tbl), value = TRUE)
    cols <- switch(header,
                   Path      = c("Path", "Label", "Estimate", "SE", ci),
                   Intercept = c("Intercept", "Label", "Estimate", "SE", ci),
                   Variance  = c("Variance", "Label", "Estimate", "SE", ci))
    m[, cols, drop = FALSE]
  }

  # Regression paths ----------------------------------------------------
  reg <- lav[lav$op == "~", ]
  if (nrow(reg)) {
    reg$coef_key <- reg$coef_key
    reg$Path <- paste(reg$lhs, "~", reg$rhs)
    cat(sprintf("\n\n*************** REGRESSION PATHS (%s) ***************\n", title))
    .print_tbl(safe_merge(reg, "Path"), digits)
  }

  # Intercepts ----------------------------------------------------------
  int <- lav[lav$op == "~1", ]
  if (nrow(int)) {
    int$coef_key <- int$coef_key
    int$Intercept <- paste0(int$lhs, "~1")
    cat(sprintf("\n\n*************** INTERCEPTS (%s) ***************\n", title))
    .print_tbl(safe_merge(int, "Intercept"), digits)
  }

  # Variances -----------------------------------------------------------
  var <- lav[lav$op == "~~" & lav$lhs == lav$rhs, ]
  if (nrow(var)) {
    var$coef_key <- var$coef_key
    var$Variance <- paste0(var$lhs, "~~", var$rhs)
    cat(sprintf("\n\n*************** VARIANCES (%s) ***************\n", title))
    .print_tbl(safe_merge(var, "Variance"), digits)
  }
  invisible()
}

# =============================================================================
# 6. MC totals / indirects printer
# =============================================================================

#' Print total, direct, and total indirect effects with CIs
#'
#' @param mc     Monte-Carlo list (elements thetahat, thetahatstar).
#' @param alpha  Numeric in (0,1). Significance level.
#' @param digits Integer. Decimal places for numeric output.
#' @param title  Character. Header suffix (default "MC").
#'
#' @return Invisibly returns NULL.
#' @keywords internal
#' @noRd
.print_mc_totals <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return(invisible())
  tbl <- .mc_param_table(mc, alpha)

  core <- c("total_effect", "cp", "total_indirect")
  lbls <- c("Total effect", "Direct effect", "Total indirect")
  idx  <- match(core, tbl$name, nomatch = 0)
  base <- tbl[idx[idx > 0], ]
  base$Label <- lbls[idx > 0]
  cat(sprintf("\n\n************* TOTAL / DIRECT / TOTAL-IND (%s) *************\n", title))
  .print_tbl(base[, c("Label", "Estimate", "SE", grep("%CI", names(base), value = TRUE))], digits)

  ind_idx <- grep("^indirect", tbl$name)
  if (length(ind_idx)) {
    ind <- tbl[ind_idx, ]
    ind$Label <- sub("^indirect_", "ind_", ind$name)
    cat("\nIndirect effects:\n")
    .print_tbl(ind[, c("Label", "Estimate", "SE", grep("%CI", names(ind), value = TRUE))], digits)
  }
  invisible()
}


# =============================================================================
# 7. Moderation-specific helpers
# =============================================================================

#' Print moderation coefficients (aw/bw/dw/cpw) with CIs
#'
#' @param mc     Monte-Carlo list.
#' @param alpha  Numeric. Significance level.
#' @param digits Integer. Decimal places.
#' @param title  Character. Header suffix (default "MC").
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_mc_moderation <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return(invisible())
  tbl <- .mc_param_table(mc, alpha)
  mod_idx <- grep("^(aw|bw|dw|cpw)", tbl$name)
  if (!length(mod_idx)) return(invisible())
  df <- tbl[mod_idx, ]
  df$Term <- df$name
  df <- df[, c("Term", "Estimate", "SE", grep("%CI", names(df), value = TRUE))]
  ord <- order(gsub("^(cpw).*", "0_\\1",
                    gsub("^(aw).*",  "1_\\1",
                         gsub("^(bw).*", "2_\\1",
                              gsub("^(dw).*", "3_\\1", df$Term)))))
  df <- df[ord, ]
  cat(sprintf("\n\n*************** MODERATION EFFECTS (%s) ***************\n", title))
  .print_tbl(df, digits)
  invisible()
}

#' Print a key mapping aw/bw/dw coefficients to moderated paths
#'
#' @param prep A prepared data set (output of PrepareData()).
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_moderation_key <- function(prep) {
  info <- attr(prep, "W_info")
  if (is.null(info) || !length(info$dummy_names)) return(invisible())

  mavg <- grep("^M\\d+avg$",  names(prep), value = TRUE)
  mdif <- grep("^M\\d+diff$", names(prep), value = TRUE)

  rows <- list()
  for (i in seq_along(mdif))
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("aw", i),
                                           Path = paste0("X -> ", mdif[i]),
                                           Moderated = paste0("X -> ", mdif[i]))
  for (i in seq_along(mdif))
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("bw", i),
                                           Path = paste0(mdif[i], " -> Ydiff"),
                                           Moderated = paste0(mdif[i], " -> Ydiff"))
  for (i in seq_along(mavg))
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("dw", i),
                                           Path = paste0(mavg[i], " -> Ydiff"),
                                           Moderated = paste0(mavg[i], " -> Ydiff"))
  key <- do.call(rbind, rows)
  if (nrow(key)) {
    cat("\n\n*************** MODERATION KEY ***************\n")
    print(knitr::kable(key, align = "l", row.names = FALSE))
  }
  invisible()
}

#' Print d-path moderation coefficients (X moderating Mavg->...)
#'
#' @param mc     Monte-Carlo list.
#' @param alpha  Numeric. Significance level.
#' @param digits Integer. Decimal places.
#' @param title  Character. Header suffix (default "MC").
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_mc_d_moderation <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return(invisible())
  tbl <- .mc_param_table(mc, alpha)
  d_idx <- grep("^d(\\d+|_\\d+)+$", tbl$name)
  if (!length(d_idx)) return(invisible())
  out <- tbl[d_idx, c("name", "Estimate", "SE", grep("%CI", names(tbl), value = TRUE))]
  names(out)[1] <- "Coefficient"
  cat(sprintf("\n\n*************** MODERATION EFFECTS (d-paths, %s) ***************\n", title))
  .print_tbl(out, digits)
  invisible()
}

#' Print a key mapping d-path coefficients to moderated paths
#'
#' @param prep Prepared data set (from PrepareData()).
#' @param mc   Monte-Carlo list (used to check which coefficients exist).
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_d_key <- function(prep, mc = NULL, param_boot = NULL) {
  if (is.null(prep)) return(invisible())

  ## ---- 1  收集已有的 d-系数名称 --------------------------------------
  have <- character(0)

  # 1-A  Monte-Carlo
  if (!is.null(mc) &&
      !is.null(mc$thetahat$est)) {
    have <- c(have, names(mc$thetahat$est))
  }

  # 1-B  Bootstrap
  if (!is.null(param_boot) && nrow(param_boot)) {
    boot_lab <- tolower(param_boot$label)
    have <- c(have, param_boot$label[grepl("^d(\\d+|_\\d+)+$", boot_lab)])
  }

  have <- unique(have)
  if (!length(have)) return(invisible())

  ## ---- 2  生成 key 表 ------------------------------------------------
  mdiff <- grep("^M\\d+diff$", names(prep), value = TRUE)
  mavg  <- grep("^M\\d+avg$",  names(prep), value = TRUE)

  rows <- list()
  add <- function(coef, path, mod)
    rows[[length(rows) + 1]] <<-
    data.frame(Coefficient = coef, Path = path, Moderated = mod)

  # 单阶 d1, d2 …
  for (i in seq_along(mavg)) {
    coef <- paste0("d", i)
    if (coef %in% have)
      add(coef,
          paste0(mavg[i],  " -> Ydiff"),
          paste0(mdiff[i], " -> Ydiff"))
  }

  # 多阶 d_1_2, d_1_3 …
  for (i in seq_along(mavg))
    for (j in seq_along(mdiff))
      if (i != j) {
        coef <- paste0("d_", i, "_", j)
        if (coef %in% have)
          add(coef,
              paste0(mavg[i],  " -> ", mdiff[j]),
              paste0(mdiff[i], " -> ", mdiff[j]))
      }

  if (!length(rows)) return(invisible())

  key <- do.call(rbind, rows)
  cat("\n\n*************** MODERATION KEY (d-paths) ***************\n")
  print(knitr::kable(key, align = "l", row.names = FALSE))
  invisible()
}

# =============================================================================
# 8. Moderation-results printers
# =============================================================================

#' Print moderation results when W is categorical
#'
#' @param m      List returned by analyze_mm_categorical_*().
#' @param digits Integer. Decimal places for numeric columns (default 3).
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_moderation_categorical <- function(m, digits = 3) {
  if (is.null(m) || !is.list(m)) return(invisible())
  cat("\n\n*************** MODERATION RESULTS (Categorical Moderator) ***************\n")
  if (!is.null(m$conditional_IE)) {
    cat("\n--- Conditional Indirect Effects ---\n")
    .print_tbl(m$conditional_IE, digits)
  }
  if (!is.null(m$IE_contrasts)) {
    cat("\n--- Indirect Effect Contrasts ---\n")
    .print_tbl(m$IE_contrasts, digits)
  }
  if (!is.null(m$extra$path_levels)) {
    cat("\n--- Conditional Path Coefficients ---\n")
    .print_tbl(m$extra$path_levels, digits)
  }
  if (!is.null(m$extra$path_contrasts)) {
    cat("\n--- Path Coefficient Contrasts ---\n")
    .print_tbl(m$extra$path_contrasts, digits)
  }
  if (!is.null(m$conditional_overall)) {
    cat("\n--- Conditional Overall Effects ---\n")
    .print_tbl(m$conditional_overall, digits)
  }
  if (!is.null(m$overall_contrasts)) {
    cat("\n--- Overall Effect Contrasts ---\n")
    .print_tbl(m$overall_contrasts, digits)
  }
  invisible()
}

#' Print moderation results when W is continuous
#'
#' @param m      List returned by analyze_mm_continuous_*().
#' @param digits Integer. Decimal places for numeric columns (default 3).
#'
#' @return Invisibly NULL.
#' @keywords internal
#' @noRd
.print_moderation_continuous <- function(m, digits = 3) {
  if (is.null(m) || !is.list(m)) return(invisible())
  cat("\n\n*************** MODERATION RESULTS (Continuous Moderator) ***************\n")
  if (!is.null(m$mod_coeff)) {
    cat("\n--- Moderated Coefficients ---\n")
    .print_tbl(m$mod_coeff, digits)
  }
  if (!is.null(m$beta_coef)) {
    cat("\n--- Conditional Indirect Effects ---\n")
    .print_tbl(m$beta_coef, digits, right_align = "Level")
  }
  if (!is.null(m$path_HML)) {
    cat("\n--- Moderated Path Coefficients ---\n")
    .print_tbl(m$path_HML, digits, right_align = "Level")
  }
  if (!is.null(m$conditional_overall)) {
    cat("\n--- Conditional Total Effect and Total Indirect Effect ---\n")
    .print_tbl(m$conditional_overall, digits, right_align = "Level")
  }
  invisible()
}



# 9-a  帮手：根据候选列表找出真正的列名（忽略大小写）
#' Pick a column name ignoring case
#'
#' @param df        A data.frame whose names are to be searched.
#' @param candidates Character vector of candidate names.
#'
#' @return A single character string: the first matching column name
#'   (exact text in `df`), or `NA_character_` if none found.
#' @keywords internal
#' @noRd
.pick_col <- function(df, candidates) {
  hits <- intersect(tolower(names(df)), tolower(candidates))
  if (length(hits)) names(df)[match(hits[1], tolower(names(df)))] else NA_character_
}



#' Convert a `parameterEstimates_boot()` block to a tidy table
#'
#' @param df    Data frame returned by `parameterEstimates_boot()`.
#' @param alpha Numeric. Significance level (e.g., .05).
#'
#' @return A data.frame with columns *Estimate*, *SE*, *\[CI.Lo\]*,
#'   *\[CI.Up\]* (and optionally *P*), ready for printing.
#' @keywords internal
#' @noRd
.boot_param_table <- function(df, alpha) {
  r <- nrow(df)

  ## 空区块：直接返回空表（列名随 alpha 生成）
  lo_name <- sprintf("%.1f%%CI.Lo", 100 * alpha / 2)
  up_name <- sprintf("%.1f%%CI.Up", 100 * (1 - alpha / 2))
  if (r == 0) {
    out <- data.frame(
      Estimate = numeric(0),
      SE       = numeric(0),
      CI.Lo    = numeric(0),
      CI.Up    = numeric(0),
      check.names = FALSE
    )
    names(out)[3:4] <- c(lo_name, up_name)
    return(out)
  }

  ## —— 1 侦测各列（忽略大小写） --------------------------------------
  est_col <- .pick_col(df, c("est", "estimate"))
  se_col  <- .pick_col(df, c("boot.se", "bse", "se_boot", "se"))
  lo_col  <- .pick_col(df, c("boot.ci.lower", "bci.lo", "ci.lower"))
  up_col  <- .pick_col(df, c("boot.ci.upper", "bci.up", "ci.upper"))
  p_col   <- .pick_col(df, c("bp", "boot.p", "p_boot"))   # ←★ 新增

  safe <- function(col) if (is.na(col) || length(df[[col]]) != r)
    rep(NA_real_, r) else df[[col]]

  ## —— 2 组装表格 ------------------------------------------------------
  out <- data.frame(
    Estimate = safe(est_col),
    SE       = safe(se_col),
    CI.Lo    = safe(lo_col),
    CI.Up    = safe(up_col),
    check.names = FALSE
  )
  names(out)[3:4] <- c(lo_name, up_name)

  ## —— 3 如有 P 列且不全是 NA，就附加 -------------------------------
  if (!is.na(p_col) && any(!is.na(df[[p_col]]))) {
    out$P <- safe(p_col)            # 列名简洁地叫 “P”
    # 把 “P” 列放在 SE 之后更顺眼
    out <- out[, c("Estimate", "SE", "P", lo_name, up_name), drop = FALSE]
  }

  out
}



#' Print regression / intercept / variance sections (bootstrap)
#'
#' @param df     Data frame from `parameterEstimates_boot()`.
#' @param alpha  Numeric. Significance level.
#' @param digits Integer. Decimal places.
#' @param title  Character. Header suffix (default "BOOT").
#'
#' @return Invisibly `NULL`.
#' @keywords internal
#' @noRd
.print_boot_RIV <- function(df, alpha, digits = 3, title = "BOOT") {
  if (is.null(df) || !nrow(df)) return(invisible())

  add_path_tbl <- function(sub, header, key_fun) {
    if (!nrow(sub)) return()
    tbl <- cbind(key_fun(sub), .boot_param_table(sub, alpha))
    cat(sprintf("\n\n*************** %s (%s) ***************\n", header, title))
    .print_tbl(tbl, digits)
  }

  # 1 回归路径 -----------------------------------------------------------------
  reg <- df[df$op == "~", ]
  add_path_tbl(reg, "REGRESSION PATHS",
               function(x) data.frame(
                 Path  = paste(x$lhs, "~", x$rhs),
                 Label = x$label,
                 check.names = FALSE))

  # 2 截距 ---------------------------------------------------------------------
  int <- df[df$op == "~1", ]
  add_path_tbl(int, "INTERCEPTS",
               function(x) data.frame(
                 Intercept = paste0(x$lhs, "~1"),
                 Label     = x$label,
                 check.names = FALSE))

  # 3 方差 ---------------------------------------------------------------------
  var <- df[df$op == "~~" & df$lhs == df$rhs, ]
  add_path_tbl(var, "VARIANCES",
               function(x) data.frame(
                 Variance = paste0(x$lhs, "~~", x$rhs),
                 check.names = FALSE))

  invisible()
}


#' Print total, direct and indirect effects (bootstrap)
#'
#' @inheritParams .print_boot_RIV
#'
#' @return Invisibly `NULL`.
#' @keywords internal
#' @noRd
.print_boot_totals <- function(df, alpha, digits = 3, title = "BOOT") {
  if (is.null(df) || !nrow(df)) return(invisible())

  # 保留 Defined parameters + cp
  dpar <- df[df$op == ":=" | df$label == "cp", ]    # ←★ 唯一改动

  if (!nrow(dpar)) return(invisible())

  tbl <- data.frame(
    Label = ifelse(dpar$op == ":=", dpar$lhs, dpar$label),  # cp 行取 label
    .boot_param_table(dpar, alpha),
    check.names = FALSE
  )


  tbl$Label[tolower(tbl$Label) == "cp"] <- "direct_effect"
  core <- c("total_effect", "direct_effect", "total_indirect")
  if (any(tbl$Label %in% core)) {
    cat(sprintf("\n\n************* TOTAL / DIRECT / TOTAL-IND (%s) *************\n",
                title))
    .print_tbl(tbl[tbl$Label %in% core, ], digits)
  }

  ind_idx <- grep("^indirect", tbl$Label)
  if (length(ind_idx)) {
    cat("\nIndirect effects:\n")
    .print_tbl(tbl[ind_idx, ], digits)
  }
  invisible()
}


#' Print moderated *d*-path coefficients (bootstrap)
#'
#' @inheritParams .print_boot_RIV
#' @param dbg Logical. If `TRUE`, emit debug messages.
#'
#' @return Invisibly `NULL`.
#' @keywords internal
#' @noRd
.print_boot_d_moderation <- function(df, alpha, digits = 3,
                                     title = "BOOT", dbg = FALSE) {

  # ── 0  early exit ──────────────────────────────────────────────────────
  if (is.null(df) || !nrow(df)) {
    if (dbg) message("[DBG] 'df' is NULL or has zero rows.")
    return(invisible())
  }

  # ── 1  locate d-path rows ──────────────────────────────────────────────
  sel <- grepl("^d(\\d+|_\\d+)+$", df$label)
  if (!any(sel)) {
    if (dbg) message("[DBG] No rows match d-path labels.")
    return(invisible())
  }
  sub <- df[sel, ]

  if (dbg) {
    message("[DBG] Number of d-path rows: ", nrow(sub))
    message("[DBG] Column names in d-path block: ",
            paste(names(sub), collapse = ", "))
  }

  # ── 2  tidy numeric columns ────────────────────────────────────────────
  vals <- .boot_param_table(sub, alpha)

  if (dbg) {
    message("[DBG] .boot_param_table() returned ", nrow(vals), " rows")
    message("[DBG] Column names of returned table: ",
            paste(names(vals), collapse = ", "))
  }

  # safeguard: row counts must match
  if (nrow(vals) != nrow(sub)) {
    stop("Row mismatch: sub = ", nrow(sub),
         ", vals = ", nrow(vals),
         ". Check .boot_param_table for alignment issues.")
  }

  # ── 3  assemble & print ───────────────────────────────────────────────
  out <- data.frame(
    Coefficient = sub$label,
    vals,
    check.names = FALSE
  )

  cat(sprintf(
    "\n\n*************** MODERATION EFFECTS (d-paths, %s) ***************\n",
    title))
  .print_tbl(out, digits)
  invisible()
}


#' Safe column extractor for standardized-solution tables
#'
#' @param df   Data frame (standardized bootstrap output).
#' @param r    Expected number of rows.
#' @param cands Character vector of candidate column names.
#'
#' @return A numeric vector of length `r`; missing columns replaced by `NA`.
#' @keywords internal
#' @noRd
.boot_pick <- function(df, r, cands) {
  idx <- match(tolower(cands), tolower(names(df)))
  idx <- idx[!is.na(idx)][1]
  if (!is.na(idx) && length(df[[idx]]) == r) df[[idx]] else rep(NA_real_, r)
}




#' Print full standardized bootstrap table
#'
#' @param std_boot Data frame from `standardizedSolution_boot()`.
#' @param alpha    Numeric. Significance level.
#' @param digits   Integer. Decimal places.
#' @param title    Character. Header suffix (default "BOOT-STD").
#'
#' @return Invisibly `NULL`.
#' @keywords internal
#' @noRd
.print_boot_std_all <- function(std_boot, alpha = .05, digits = 3,
                                title = "BOOT-STD") {
  if (is.null(std_boot) || !nrow(std_boot)) return(invisible())
  r   <- nrow(std_boot)
  loH <- sprintf("%.1f%%CI.Lo", 100 * alpha / 2)
  upH <- sprintf("%.1f%%CI.Up", 100 * (1 - alpha / 2))

  ## 数值列
  vals <- data.frame(
    Estimate = .boot_pick(std_boot, r, c("est.std","std","std.all")),
    SE       = .boot_pick(std_boot, r, c("boot.se","bse","se")),
    P        = .boot_pick(std_boot, r, c("boot.p","bp","pvalue")),
    CI.Lo    = .boot_pick(std_boot, r, c("boot.ci.lower","bci.lo","ci.lower")),
    CI.Up    = .boot_pick(std_boot, r, c("boot.ci.upper","bci.up","ci.upper")),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  names(vals)[4:5] <- c(loH, upH)

  ## 关键字列
  key   <- character(r)
  reg_i <- std_boot$op == "~"
  int_i <- std_boot$op == "~1"
  var_i <- std_boot$op == "~~" & std_boot$lhs == std_boot$rhs
  cov_i <- std_boot$op == "~~" & std_boot$lhs != std_boot$rhs
  def_i <- std_boot$op == ":="

  key[reg_i] <- paste(std_boot$lhs[reg_i], "~", std_boot$rhs[reg_i])
  key[int_i] <- paste0(std_boot$lhs[int_i], "~1")
  key[var_i] <- paste0(std_boot$lhs[var_i], "~~", std_boot$rhs[var_i])
  key[cov_i] <- paste(std_boot$lhs[cov_i], "~~", std_boot$rhs[cov_i])
  key[def_i] <- std_boot$lhs[def_i]

  label <- std_boot$label
  label[is.na(label) | label == ""] <- ""          #  空串替代 NA

  ## 合并大表（先加 Section 作排序后再删除
  sec <- character(r)
  sec[reg_i] <- "1_Regressions"
  sec[cov_i] <- "2_Covariances"
  sec[int_i] <- "3_Intercepts"
  sec[var_i] <- "4_Variances"
  sec[def_i] <- "5_Defined"

  big_tbl <- data.frame(
    Term  = key,
    Label = label,
    vals,
    Section = sec,                      # 排序用
    check.names = FALSE, stringsAsFactors = FALSE
  )
  big_tbl <- big_tbl[order(big_tbl$Section), ]
  big_tbl$Section <- NULL               #  删除 Section 列

  ## 打印
  cat("\n*************** STANDARDIZED (", title, ") ***************\n", sep = "")
  .print_tbl(big_tbl, digits)
  invisible()
}



# ---------- 小工具：让 “-” 左右对齐 -------
#' Align text around a minus sign for pretty printing
#'
#' @param x   Character vector of "lhs - rhs" strings.
#' @param sep Character. Separator symbol (default "`-`").
#'
#' @return A character vector with padded spaces so that the minus
#'   signs line up in monospaced fonts.
#' @keywords internal
#' @noRd
align_minus <- function(x, sep = "-") {
  stopifnot(is.character(x))

  parts <- strsplit(x, sep, fixed = TRUE)
  lhs   <- trimws(vapply(parts, `[`, 1, FUN.VALUE = ""))
  rhs   <- trimws(vapply(parts, `[`, 2, FUN.VALUE = ""))

  wL <- max(nchar(lhs))
  wR <- max(nchar(rhs))

  fmt <- paste0("%-", wL, "s  -  %-", wR, "s")
  sprintf(fmt, lhs, rhs)
}


# ── 工具：修正 CI 列名
#' Clean CI column names produced by `fix_pct_names()`
#'
#' @param nm Character vector of column names.
#'
#' @return A character vector with collapsed `".."` and the duplicated
#'   `"CI..CI"` artifact removed.
#' @keywords internal
#' @noRd
clean_ci_names <- function(nm) {
  nm <- gsub("CI\\.\\.CI", "CI", nm, perl = TRUE)  # 把 “CI..CI” → “CI”
  nm <- gsub("\\.\\.", ".",  nm, perl = TRUE)      # 折叠任何 “..”
  nm
}






