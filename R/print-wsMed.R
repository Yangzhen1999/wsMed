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
#'   - Shows input variables (M_C1, M_C2, Y_C1, Y_C2) and computed variables like Ydiff, Mdiff, and Mavg.
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
#' @param ... Additional arguments (not used currently).
#'
#' @return Invisibly returns the input \code{wsMed} object for further use.
#'
#' @seealso \code{\link{wsMed}}, \code{\link[lavaan]{sem}}, \code{\link[semhelpinghands]{standardizedSolution_boot_ci}}
#'
#' @examples
#'
#' # Perform within-subject mediation analysis
#' library(wsMed)
#' result1 <- wsMed(
#'   data = example_data,
#'   M_C1 = c("A1", "B1"),
#'   M_C2 = c("A2", "B2"),
#'   Y_C1 = "C1",
#'   Y_C2 = "C2",
#'   form = "P",
#'   Na = "FIML",
#'   standardized = FALSE,
#'   alpha = 0.05
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


  if (!inherits(x, "wsMed"))
    stop("Not a wsMed object.")

  ## 1 变量信息 --------------------------------
  .print_variables(x)

  ## 2 模型拟合 --------------------------------
  .print_fit(x$mc$fit)

  ## ---------- 总 / 直 / 总间接 & 独立间接 ----------
  if (!is.null(x$mc$result))
    .print_mc_totals(x$mc$result, x$alpha, digits)


  if (!is.null(x$param_boot)) {
    .print_boot_totals(x$param_boot, x$alpha, digits)
  }

  ## ---------- 间接 key ----------
  .print_indirect_key(x)

  ## 3 Monte‑Carlo 总/直/间接 --------------------

  .print_mc_d_moderation(x$mc$result, x$alpha, digits)
  if (!is.null(x$param_boot))
    .print_boot_d_moderation(x$param_boot, x$alpha, digits)

  .print_d_key(x$data, x$mc$result)
  if (!is.null(x$param_boot))
    .print_d_key(x$data, x$mc$result, x$param_boot)

  ## 4 调节--------------------------------
  ## ---------- (1) basic contrasts ----------
  if (!is.null(x$moderation) && x$moderation$type == "none") {
    if (!is.null(x$moderation$IE_contrasts)) {
      cat("\n")
      cat("\n*************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************\n")
      tbl <- x$moderation$IE_contrasts        # ① 取出原表
      names(tbl) <- clean_ci_names(names(tbl))
      if ("Contrast" %in% names(tbl))         # ② 对齐，别动别的列
        tbl$Contrast <- align_minus(tbl$Contrast)
      .print_tbl(tbl, digits)
    }

    if (!is.null(x$moderation$Xcoef)) {
      cat("\n")
      cat("\n*************** C1-C2 COEFFICIENTS (No Moderator) ***************\n")
      .print_tbl(x$moderation$Xcoef, digits)
    }

  }


  if (!is.null(x$moderation)) {
    if (x$moderation$type == "categorical") {
      .print_moderation_categorical(x$moderation, digits)
    } else if (x$moderation$type == "continuous") {
      .print_moderation_continuous(x$moderation, digits)
    }
  }


  ## ---------- 回归 / 方差 / 截距 ----------
  .print_mc_RIV(x$mc$result, x$mc$fit, x$alpha, digits)
  if (!is.null(x$param_boot)) {
    .print_boot_RIV   (x$param_boot, x$alpha, digits)
  }

  ## 5 标准化（若有） ---------------------------
  if (!is.null(x$mc$std_mc)){
    cat("\n")
    cat("\n*************** STANDARDIZED (MC) ***************\n")
    .print_tbl(x$mc$std_mc, digits = digits)
  }

  if (!is.null(x$mc$std_boot)){
     cat("\n")
    .print_boot_std_all(x$mc$std_boot, x$alpha, digits)
  }

  invisible(x)
}
