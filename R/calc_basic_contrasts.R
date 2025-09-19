#' @title Basic Contrasts for Indirect Effects and Pre/Post Path Coefficients
#'
#' @description
#' `calc_basic_contrasts()` extracts two convenient sets of contrasts from a
#' Monte-Carlo SEM result (`semmcci` object):
#' \enumerate{
#'   \item All pairwise differences between indirect effects
#'         (`indirect_*` columns);
#'   \item Pre-test (\eqn{X_0}) and post-test (\eqn{X_1}) coefficients for every
#'         primary \eqn{b} path, obtained with
#'         \eqn{X_1 = (2b + d)/2}, \eqn{X_0 = X_1 - d}.
#' }
#'
#' @details
#' * Indirect-effect columns are detected by the regular expression
#'   `^indirect_`.
#' * A primary \eqn{b} path is any coefficient named `b1`, `b_1_2`, …
#'   Its matching \eqn{d} path (`d1`, `d_1_2`, …) is paired automatically.
#'
#' Each contrast is summarised with its Monte-Carlo mean, SD, and a symmetric
#' \eqn{100(1-\alpha)} % confidence interval.  Helper functions
#' `mc_summary_pct()` and `fix_pct_names()` ensure that the final CI columns are
#' named, for example, `2.5%CI.Lo` and `97.5%CI.Up`.
#'
#' @param mc_result A Monte-Carlo result of class `"semmcci"`
#'                  (returned by [MCMI2()]).
#' @param ci_level  Confidence level for the CI (default `0.95`).
#' @param digits    Decimal places to keep (default `3`).
#'
#' @return A list with up to two data frames:
#' \describe{
#'   \item{IE_contrasts}{Pairwise contrasts of indirect effects, or `NULL` if
#'         fewer than two are present.}
#'   \item{Xcoef}{Rows `X1_b*` and `X0_b*` for every detected \eqn{b} path,
#'         or `NULL` if no \eqn{b} path is found.}
#' }
#'
#' @keywords internal



calc_basic_contrasts <- function(mc_result, ci_level=.95, digits=3){
  th_star <- mc_result
  ## 所有 indirect_* 两两差
  ind_cols <- grep("^indirect_",colnames(th_star),value=TRUE)
  ie_diff <- list()
  if (length(ind_cols)>1)
    for (pair in utils::combn(ind_cols,2,simplify=FALSE)){
      diff <- th_star[,pair[2]] - th_star[,pair[1]]
      ie_diff[[length(ie_diff)+1]] <-
        data.frame(Contrast=paste(pair[2]," - ",pair[1]),
                   mc_summary_pct(diff,".",ci_level,digits)[,-1])
    }
  ## X1/X0  前后测
  b_cols <- grep("^b(_|\\d)",colnames(th_star),value=TRUE)
  X_tbl  <- list()
  for (b in b_cols){
    d <- sub("^b","d",b)
    if (!(d %in% colnames(th_star))) next
    X1 <- (2*th_star[,b] + th_star[,d])/2
    X0 <- X1 - th_star[,d]
    X_tbl[[length(X_tbl)+1]] <- cbind(Coeff=paste0("X1_",b),
                                      mc_summary_pct(X1,".",ci_level,digits)[,-1])
    X_tbl[[length(X_tbl)+1]] <- cbind(Coeff=paste0("X0_",b),
                                      mc_summary_pct(X0,".",ci_level,digits)[,-1])
  }
  list(IE_contrasts = if(length(ie_diff)) fix_pct_names(do.call(rbind,ie_diff)) else NULL,
       Xcoef        = if(length(X_tbl))  fix_pct_names(do.call(rbind,X_tbl))  else NULL)
}


#' @title Compute Monte Carlo Estimates, Standard Errors, and CIs (with Percent Labels)
#'
#' @description
#' `mc_summary_pct()` summarizes a numeric vector of Monte Carlo samples `x` by
#' computing its mean, standard deviation, and percentile-based confidence interval.
#' The result is returned as a `data.frame` with column names that include percentage
#' signs. This function is typically used to generate tables of mediation effects or
#' path coefficient estimates with path labels.
#'
#' Returned columns include:
#' * `Path`: Path label.
#' * `Estimate`: Sample mean.
#' * `SE`: Sample standard deviation.
#' * `<p%CI.Lo>`, `<p%CI.Up>`: Lower and upper bounds of the percentile CI,
#'   with `%` in the column names.
#'
#' @param x       Numeric vector of Monte Carlo samples.
#' @param label   Character string for the value in the `Path` column of the output.
#' @param ci_level Confidence level for the CI (default `0.95`).
#' @param digits  Number of decimal places to retain (default `3`).
#'
#' @return
#' A `data.frame` containing the path label, estimate, standard error, and CI.
#' Column names are formatted like `"2.5%CI.Lo"` and `"97.5%CI.Up"`.
#'
#' @keywords internal


mc_summary_pct <- function(x, label, ci_level = .95, digits = 3) {
  lo <- (1 - ci_level)/2 * 100; up <- (1 + ci_level)/2 * 100
  labs <- sprintf(c("%.1f%%CI.Lo","%.1f%%CI.Up"), c(lo, up))
  ci   <- quantile(x, probs = c(lo, up)/100, na.rm = TRUE)
  df <- data.frame(Path = label,
                   Estimate = round(mean(x, na.rm = TRUE), digits),
                   SE       = round(sd(x,   na.rm = TRUE), digits),
                   check.names = FALSE)
  df[[labs[1]]] <- round(ci[1], digits); df[[labs[2]]] <- round(ci[2], digits)
  rownames(df) <- NULL; df
}
