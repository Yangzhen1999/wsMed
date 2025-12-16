#' @title Print Method for wsMed Objects
#'
#' @description Provides a comprehensive summary of results from a \code{wsMed} object, including:
#' - Input and computed variables with sample size.
#' - Model fit indices, regression paths, and variance estimates.
#' - Total, direct, and indirect effects with pairwise contrasts.
#' - Moderation effects and Monte Carlo confidence intervals for raw and standardized estimates (if applicable).
#' - Diagnostic notes for bootstrapping, imputation, and analysis parameters.
#'
#' The output is formatted for clarity, ensuring an intuitive presentation of mediation analysis results,
#' including dynamic confidence intervals, moderation keys, and C1-C2 coefficients.
#'
#' @details This function is specifically designed to display results from the within-subject mediation
#' analysis conducted using the \code{wsMed} function. Key features include:
#'
#' - **Variables**:
#'   - Shows input variables (`M_C1`, `M_C2`, `Y_C1`, `Y_C2`) and computed variables like `Ydiff`, `Mdiff`, and `Mavg`.
#'   - Reports the sample size used in the analysis.
#'
#' - **Model Fit Indices**:
#'   - Displays SEM fit indices (e.g., Chi-square, CFI, TLI, RMSEA, SRMR) to assess model quality.
#'
#' - **Regression Paths and Variance Estimates**:
#'   - Summarizes path coefficients, intercepts, variances, and confidence intervals.
#'
#' - **Effects**:
#'   - Reports total, direct, and indirect effects with their significance.
#'   - Highlights pairwise contrasts between indirect effects for mediation paths.
#'
#' - **Moderation Effects**:
#'   - Provides moderation results for identified variables with corresponding coefficients and paths.
#'
#' - **Monte Carlo Confidence Intervals**:
#'   - Includes results for raw and standardized estimates obtained using methods such as MI or FIML.
#'
#' - **Diagnostics**:
#'   - Summarizes analysis parameters like bootstrapping, imputation settings, Monte Carlo iterations, and random seeds.
#'
#' @param x A \code{wsMed} object containing the results of within-subject mediation analysis.
#' @param digits Numeric. Number of digits to display in the results.
#' @param delta Logical. Whether to include original delta-method-based SE, CI, and p-values alongside bootstrap results. Default is FALSE.
#' @param ... Additional arguments (not used currently).
#'
#' @return Invisibly returns the input \code{wsMed} object for further use.
#'
#' @seealso \code{\link{wsMed}}, \code{\link[lavaan]{sem}}, \code{\link[semhelpinghands]{standardizedSolution_boot_ci}}
#'
#' @examples
#' # Example dataset with missing values
#' data(example_data)
#' set.seed(123)
#' example_dataN <- mice::ampute(
#'   data = example_data,
#'   prop = 0.1
#' )$amp
#'
#' # Perform within-subject mediation analysis
#' result1 <- wsMed(
#'   data = example_dataN,
#'   M_C1 = c("A1", "B1"),
#'   M_C2 = c("A2", "B2"),
#'   Y_C1 = "C1",
#'   Y_C2 = "C2",
#'   form = "P",
#'   Na = "FIML",
#'   standardized = FALSE,
#'   ci_method = "mc",
#'   alpha = 0.05,
#'   alphastd = 0.05
#' )
#'
#' # Print the results
#' print(result1)
#'
#' @importFrom stats quantile sd
#' @importFrom utils str
#' @importFrom knitr kable
#' @importFrom utils combn
#' @importFrom stats coef
#' @method print wsMed
#' @export

print.wsMed <- function(x, digits = 3, ...){

  {
    # 回归方差截距部分
    .lav2coef <- function(lhs, rhs){
      if (lhs == "Ydiff"){
        if (grepl("^M(\\d+)diff$", rhs))
          return(paste0("b", sub("^M(\\d+)diff$", "\\1", rhs)))
        if (grepl("^M(\\d+)avg$",  rhs))
          return(paste0("d", sub("^M(\\d+)avg$",  "\\1", rhs)))
        if (grepl("^int_M(\\d+)diff_", rhs))
          return(sub("^int_", "bw", rhs))
        if (grepl("^int_M(\\d+)avg_",  rhs))
          return(sub("^int_", "dw", rhs))
      }
      if (grepl("^M(\\d+)diff$", lhs) && grepl("^W\\d+$", rhs)){
        idx <- sub("^M(\\d+)diff$", "\\1", lhs)
        return(paste0("aw", idx, "_", rhs))
      }
      NA_character_
    }

    .print_mc_RIV <- function(mc, fit, alpha, digits = 3, title = "MC"){
      if (is.null(mc) || is.null(fit)) return()
      tbl  <- .mc_param_table(mc, alpha)
      lav  <- lavaan::parameterEstimates(fit, ci = FALSE)
      ci_c <- grep("%CI", names(tbl), value = TRUE)

      simple_key <- function(row){
        switch(row$op,
               "~"  = paste0(row$lhs,"~",row$rhs),
               "~1" = paste0(row$lhs,"~1"),
               "~~" = paste0(row$lhs,"~~",row$rhs))
      }

      ## === 生成 coef_key：label → 简写 → simple ========================
      lav$coef_key <- mapply(function(lbl,lhs,op,rhs){
        if (!is.na(lbl) && lbl != "" && lbl %in% tbl$name) return(lbl)
        key2 <- .lav2coef(lhs, rhs)
        if (!is.na(key2) && key2 %in% tbl$name) return(key2)
        key3 <- simple_key(list(lhs=lhs, rhs=rhs, op=op))
        key3
      }, lav$label, lav$lhs, lav$op, lav$rhs, USE.NAMES = FALSE)

      safe_merge <- function(df, header){
        df$Label <- lav$label[match(df$coef_key, lav$coef_key)]  # 加入 label 对应项

        m <- merge(df, tbl, by.x = "coef_key", by.y = "name", all.x = TRUE, sort = FALSE)
        m[] <- lapply(m, function(z) if (is.factor(z)) as.character(z) else z)
        ci_c <- grep("%CI", names(tbl), value = TRUE)

        cols <- switch(header,
                       Path      = c("Path", "Label", "Estimate", "SE", ci_c),
                       Intercept = c("Intercept", "Label", "Estimate", "SE", ci_c),
                       Variance  = c("Variance", "Label", "Estimate", "SE", ci_c)
        )

        m[, cols, drop = FALSE]
      }



      ## ---------- Regression ------------------------------------------
      reg <- lav[lav$op=="~", ]
      if (nrow(reg)){
        reg$Path <- paste(reg$lhs,"~",reg$rhs)
        cat("\n")
        cat("\n*************** REGRESSION PATHS (",title,") ***************\n")
        .print_tbl(safe_merge(reg,"Path"), digits)
      }

      ## ---------- Intercept ------------------------------------------
      int <- lav[lav$op=="~1", ]
      if (nrow(int)){
        int$Intercept <- paste0(int$lhs,"~1")
        cat("\n")
        cat("\n*************** INTERCEPTS (",title,") ***************\n")
        .print_tbl(safe_merge(int,"Intercept"), digits)
      }

      ## ---------- Variance -------------------------------------------
      var <- lav[lav$op=="~~" & lav$lhs==lav$rhs, ]
      if (nrow(var)){
        var$Variance <- paste0(var$lhs,"~~",var$rhs)
        cat("\n")
        cat("\n*************** VARIANCES (",title,") ***************\n")
        .print_tbl(safe_merge(var,"Variance"), digits)
      }
    }


    #变量部分
    .fmt_num <- function(x, digits, width = NULL){
      if (is.null(width)) width <- if (digits <= 4) 10 else 12
      formatC(x, format = "f", digits = digits, width = width, flag = " ")
    }

    .print_variables <- function(obj){
      iv <- obj$input_vars
      if (is.null(iv)) return()
      cat("\n")
      cat("\n*************** VARIABLES ***************\n")
      cat("Original Variables:\n")

      ## ----------- Outcome ---------------------
      cat("  Outcome (Y):\n")
      cat("    Condition 1:", iv$Y_C1, "\n")
      cat("    Condition 2:", iv$Y_C2, "\n")

      ## ----------- Mediators -------------------
      cat("  Mediators (M):\n")
      for (i in seq_along(iv$M_C1)) {
        cat(sprintf("    M%d:\n", i))
        cat("      Condition 1:", iv$M_C1[i], "\n")
        cat("      Condition 2:", iv$M_C2[i], "\n")
      }

      ## ----------- Between-subject Covariates ---
      cinfo <- attr(obj$data, "C_info")
      if (!is.null(cinfo) && length(cinfo$raw)) {
        cat("  Between-subject Covariates:\n")
        for (i in seq_along(cinfo$raw)) {
          cat("    ", cinfo$dummy_names[i], ":", cinfo$raw[i], "\n")
        }
      }

      ## ----------- Within-subject Covariates -----
      if (!is.null(iv$C_C1)) {
        cat("  Within-subject Covariates:\n")
        for (i in seq_along(iv$C_C1)) {
          cat(sprintf("    Cw%d:\n", i))
          cat("      Condition 1:", iv$C_C1[i], "\n")
          cat("      Condition 2:", iv$C_C2[i], "\n")
        }
      }

      ## ----------- Moderators --------------------
      winfo <- attr(obj$data, "W_info")
      if (!is.null(winfo) && length(winfo$raw)) {
        cat("  Moderators (W):\n")
        for (i in seq_along(winfo$raw)) {
          cat("    ", winfo$dummy_names[i], ":", winfo$raw[i], "\n")
        }
      }

      cat("Sample size (rows kept):", nrow(obj$data), "\n")
    }


    #模型拟合
    .print_fit <- function(fit){
      if (is.null(fit)) return()
      fm <- lavaan::fitMeasures(fit,
                                c("chisq","df","pvalue","cfi","tli",
                                  "rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
      tbl <- data.frame(
        Measure = c("Chi‑Sq","df","p","CFI","TLI",
                    "RMSEA","RMSEA Low","RMSEA Up","SRMR"),
        Value   = unname(fm)
      )
      cat("\n")
      cat("\n*************** MODEL FIT ***************\n")
      .print_tbl(tbl, digits = 3)
    }


    .mc_param_table <- function(mc, alpha){
      est <- mc$thetahat$est
      se  <- apply(mc$thetahatstar, 2, stats::sd)
      pr  <- c(alpha/2, 1-alpha/2)
      ci  <- t(apply(mc$thetahatstar, 2, stats::quantile, probs = pr))
      colnames(ci) <- sprintf("%.1f%%CI.%s", pr*100, c("Lo","Up"))
      data.frame(name = names(est), Estimate = est, SE = se, ci,
                 row.names = NULL, check.names = FALSE)
    }

    .print_tbl <- function(df, digits = 3, right_align = NULL){
      num <- vapply(df, is.numeric, logical(1))
      df[num] <- lapply(df[num], function(z)
        formatC(z, digits = digits, format = "f"))

      ## 默认按数值列判定对齐方式
      align <- ifelse(num, "r", "l")

      ## 若指定列需额外右对齐，强制改为 "r"
      if (!is.null(right_align)) {
        idx <- match(right_align, names(df), nomatch = 0L)
        align[idx[idx > 0]] <- "r"
      }

      print(knitr::kable(df, align = align, row.names = FALSE))
    }



    .print_mc_moderation <- function(mc, alpha, digits = 3, title = "MC"){
      if (is.null(mc)) return()
      tbl <- .mc_param_table(mc, alpha)

      ## 抓调节项 (aw, bw, dw, cpw… 以及多 dummy)
      mod_pat <- "^(aw|bw|dw|cpw).*"
      mod_idx <- grep(mod_pat, tbl$name)
      if (!length(mod_idx)) return()

      df <- tbl[mod_idx, ]
      df$Term <- df$name
      df <- df[ , c("Term","Estimate","SE",
                    grep("%CI", names(df), value = TRUE))]
      ## 按 cpw → aw → bw → dw 排序
      ord <- order(gsub("^(cpw).*", "0_\\1",
                        gsub("^(aw).*",  "1_\\1",
                             gsub("^(bw).*",  "2_\\1",
                                  gsub("^(dw).*",  "3_\\1", df$Term)))))
      df <- df[ord, ]
      cat("\n")
      cat("\n*************** MODERATION EFFECTS of X (", title, ") ***************\n")
      .print_tbl(df, digits)
    }

    .print_moderation_key <- function(prep){
      info <- attr(prep, "W_info")
      if (is.null(info) || !length(info$dummy_names)) return()

      mavg <- grep("^M\\d+avg$",  names(prep), value = TRUE)
      mdif <- grep("^M\\d+diff$", names(prep), value = TRUE)

      rows <- list()
      ## a‑path mods (aw…)
      for (i in seq_along(mdif)){
        coef <- paste0("aw", i)
        rows[[length(rows)+1]] <-
          data.frame(Coefficient = coef,
                     Path        = paste0("X → ", mdif[i]),
                     Moderated   = paste0("X → ", mdif[i]))
      }
      ## b‑path mods (bw…): mediator → Y
      for (i in seq_along(mdif)){
        coef <- paste0("bw", i)
        rows[[length(rows)+1]] <-
          data.frame(Coefficient = coef,
                     Path        = paste0(mdif[i], " → Ydiff"),
                     Moderated   = paste0(mdif[i], " → Ydiff"))
      }
      ## d‑path mods (dw…): Mavg → downstream Mdif
      for (i in seq_along(mavg)){
        coef <- paste0("dw", i)
        rows[[length(rows)+1]] <-
          data.frame(Coefficient = coef,
                     Path        = paste0(mavg[i], " → Ydiff"),
                     Moderated   = paste0(mavg[i], " → Ydiff"))
      }
      key <- do.call(rbind, rows)

      if (nrow(key)){
        cat("\n")
        cat("\n*************** MODERATION KEY ***************\n")
        print(knitr::kable(key, align = "l", row.names = FALSE))
      }
    }


    #X调节

    .print_mc_d_moderation <- function(mc, alpha, digits = 3, title = "MC"){
      if (is.null(mc)) return()
      tbl <- .mc_param_table(mc, alpha)
      d_idx <- grep("^d(\\d+|_\\d+)+$", tbl$name)
      if (!length(d_idx)) return()

      out <- tbl[d_idx, c("name","Estimate","SE",
                          grep("%CI", names(tbl), value = TRUE))]
      names(out)[1] <- "Coefficient"
      cat("\n")
      cat("\n*************** MODERATION EFFECTS of X (d‑paths, ",title,") ***************\n")
      .print_tbl(out, digits)
    }

    .print_d_key <- function(prep, mc){
      if (is.null(prep) || is.null(mc)) return()
      have <- names(mc$thetahat$est)

      mdiff <- grep("^M\\d+diff$", names(prep), value = TRUE)
      mavg  <- grep("^M\\d+avg$",  names(prep), value = TRUE)
      rows  <- list()

      add_row <- function(cff, path, mod)
        rows[[length(rows)+1]] <<- data.frame(
          Coefficient = cff, Path = path, Moderated = mod)

      ## 一阶 d_i
      for (i in seq_along(mavg)){
        coef <- paste0("d", i)
        if (coef %in% have)
          add_row(coef,
                  paste0(mavg[i]," → Ydiff"),
                  paste0(mdiff[i]," → Ydiff"))
      }
      ## 多阶 d_i_j
      for (i in seq_along(mavg))
        for (j in seq_along(mdiff))
          if (i!=j){
            coef <- paste0("d_", i, "_", j)
            if (coef %in% have)
              add_row(coef,
                      paste0(mavg[i]," → ", mdiff[j]),
                      paste0(mdiff[i]," → ", mdiff[j]))
          }

      if (length(rows)){
        key <- do.call(rbind, rows)
        cat("\n")
        cat("\n*************** MODERATION KEY (d‑paths) ***************\n")
        print(knitr::kable(key, align = "l", row.names = FALSE))
      }
    }


    .print_mc_totals <- function(mc, alpha, digits = 3, title = "MC"){
      if (is.null(mc)) return()
      tbl <- .mc_param_table(mc, alpha)

      tot_names <- c("total_effect","cp","total_indirect")
      tag <- c("Total effect","Direct effect","Total indirect")
      idx <- match(tot_names, tbl$name, nomatch = 0)
      base <- tbl[idx[idx>0], ]
      base$Label <- tag[idx>0]
      cat("\n")
      cat("\n************* TOTAL / DIRECT / TOTAL‑IND (", title, ") *************\n")
      .print_tbl(base[ , c("Label","Estimate","SE",
                           grep("%CI", names(base), value = TRUE))],
                 digits = digits)

      ## 单独间接
      ind_idx <- grep("^indirect", tbl$name)
      if (length(ind_idx)){
        ind <- tbl[ind_idx, ]
        ind$Label <- sub("^indirect_", "ind_", ind$name)
        cat("\n")
        cat("\nIndirect effects:\n")
        .print_tbl(ind[ , c("Label","Estimate","SE",
                            grep("%CI", names(ind), value = TRUE))],
                   digits = digits)
      }
    }

    ## ----- 间接 key ---------------------------------------------------------
    .print_indirect_key <- function(x){
      ## 所有间接效应参数
      if (is.null(x$mc$result$thetahat$est)) return()
      theta_names <- names(x$mc$result$thetahat$est)
      ind_names   <- grep("^indirect_\\d+", theta_names, value = TRUE)

      if (!length(ind_names)) return()

      ## 找到数据中的中介变量（用于命名匹配）
      mdiff_vars <- grep("^M\\d+diff$", names(x$data), value = TRUE)
      mnum <- gsub("^M(\\d+)diff$", "\\1", mdiff_vars)
      names(mdiff_vars) <- mnum  # 方便编号查找

      ## 生成路径表
      paths <- lapply(ind_names, function(ind_name){
        key <- sub("^indirect_", "", ind_name)  # 提取数字序列，如 1_2
        mids <- unlist(strsplit(key, "_"))
        path <- paste(mdiff_vars[mids], collapse = " -> ")
        data.frame(Ind = sub("^indirect_", "ind_", ind_name),
                   Path = paste("X ->", path, "-> Ydiff"))
      })

      key_tbl <- do.call(rbind, paths)
      cat(("\n"))
      cat("\nIndirect‑effect key:\n")
      print(knitr::kable(key_tbl, align = "l", row.names = FALSE))
    }


    #W为分类变量
    .print_moderation_categorical <- function(m, digits = 3) {
      if (is.null(m) || !is.list(m)) return()
      cat("\n")
      cat("\n*************** MODERATION RESULTS (Categorical Moderator) ***************\n")

      if (!is.null(m$conditional_IE)) {
        cat("\n")
        cat("\n--- Conditional Indirect Effects ---\n")
        .print_tbl(m$conditional_IE, digits)
      }

      if (!is.null(m$IE_contrasts)) {
        cat("\n")
        cat("\n--- Indirect Effect Contrasts ---\n")
        .print_tbl(m$IE_contrasts, digits)
      }

      if (!is.null(m$extra$path_levels)) {
        cat("\n")
        cat("\n--- Conditional Path Coefficients ---\n")
        .print_tbl(m$extra$path_levels, digits)
      }

      if (!is.null(m$extra$path_contrasts)) {
        cat("\n")
        cat("\n--- Path Coefficient Contrasts ---\n")
        .print_tbl(m$extra$path_contrasts, digits)
      }

      if (!is.null(m$conditional_overall)) {
        cat("\n")
        cat("\n--- Conditional Overall Effects ---\n")
        .print_tbl(m$conditional_overall, digits)
      }

      if (!is.null(m$overall_contrasts)) {
        cat("\n")
        cat("\n--- Overall Effect Contrasts ---\n")
        .print_tbl(m$overall_contrasts, digits)
      }
    }


    #连续变量
    .print_moderation_continuous <- function(m, digits = 3) {
      if (is.null(m) || !is.list(m)) return()
      cat("\n")
      cat("\n*************** MODERATION RESULTS (Continuous Moderator) ***************\n")

      # 1. 打印调节项斜率表
      if (!is.null(m$mod_coeff)) {
        cat("\n")
        cat("\n--- Moderated Coefficients ---\n")
        .print_tbl(m$mod_coeff, digits)
      }

      # 2. 打印调节后间接效应（HML）
      if (!is.null(m$beta_coef)) {
        cat("\n")
        cat("\n--- Conditional Indirect Effects ---\n")
        .print_tbl(m$beta_coef, digits, right_align = "Level")
      }

      # 3. 打印路径系数的三水平估计
      if (!is.null(m$path_HML)) {
        cat("\n")
        cat("\n--- Moderated Path Coefficients ---\n")
        .print_tbl(m$path_HML, digits, right_align = "Level" )
      }

      # 4. 打印直接效应和总间接效应
      if (!is.null(m$conditional_overall)) {
        cat("\n")
        cat("\n--- Conditional Total Effect and Total Indirect Effect  ---\n")
        .print_tbl(m$conditional_overall, digits, right_align = "Level" )
      }
    }


  }

  if (!inherits(x, "wsMed"))
    stop("Not a wsMed object.")

  ## 1 变量信息 --------------------------------
  .print_variables(x)

  ## 2 模型拟合 --------------------------------
  .print_fit(x$mc$fit)

    ## ---------- 总 / 直 / 总间接 & 独立间接 ----------
  .print_mc_totals(x$mc$result, x$alpha, digits)

  ## ---------- 间接 key ----------
  .print_indirect_key(x)

  ## 3 Monte‑Carlo 总/直/间接 --------------------
  ## ---------- 回归 / 方差 / 截距 ----------
  .print_mc_RIV(x$mc$result, x$mc$fit, x$alpha, digits)



  ## 4 调节--------------------------------
  ## ---------- (1) basic contrasts ----------
  if (!is.null(x$moderation) && x$moderation$type == "none") {
    if (!is.null(x$moderation$IE_contrasts)) {
      cat("\n")
      cat("\n*************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************\n")
      .print_tbl(x$moderation$IE_contrasts, digits)
    }
    if (!is.null(x$moderation$Xcoef)) {
      cat("\n")
      cat("\n*************** C1–C2 COEFFICIENTS (No Moderator) ***************\n")
      .print_tbl(x$moderation$Xcoef, digits)
    }

  }

  .print_mc_d_moderation(x$mc$result, x$alpha, digits)
  .print_d_key(x$data, x$mc$result)


  if (!is.null(x$moderation)) {
    if (x$moderation$type == "categorical") {
      .print_moderation_categorical(x$moderation, digits)
    } else if (x$moderation$type == "continuous") {
      .print_moderation_continuous(x$moderation, digits)
    }
  }

  ## 5 标准化（若有） ---------------------------
  if (!is.null(x$mc$std)){
    cat("\n")
    cat("\n*************** STANDARDIZED (MC) ***************\n")
    .print_tbl(x$mc$std, digits = digits)
  }

  ## 6 bootstrap （仅 listwise） ---------------
  if (!is.null(x$mc$bootstrap)){
    cat("\n*************** BOOTSTRAP (DE) *****************\n")
    .print_tbl(x$mc$bootstrap, digits = digits)
  }

  invisible(x)
}



