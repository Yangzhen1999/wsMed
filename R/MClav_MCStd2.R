#' @title Monte Carlo Summary for Standardized Estimates
#'
#' @description Computes standardized estimates, standard errors, and confidence intervals
#' based on Monte Carlo samples from a `semmcci` object. This function fully standardizes
#' both point estimates and sampling distributions (including intercepts).
#'
#' @param mc A Monte Carlo result object of class `semmcci`, typically from `MC()` or `MCMI()`.
#' @param alpha A numeric vector of significance levels (default: `c(0.001, 0.01, 0.05)`).
#'
#' @return A data frame containing:
#' \describe{
#'   \item{Parameter}{Parameter name}
#'   \item{Estimate}{Standardized point estimate}
#'   \item{SE}{Standard deviation of standardized samples}
#'   \item{R}{Number of Monte Carlo replications}
#'   \item{CI columns}{Multiple confidence intervals based on `alpha`}
#' }
#'
#' @details The function standardizes the sampling distribution using `StdLav2()` on each Monte Carlo draw,
#' then summarizes the distribution into SEs and quantile-based confidence intervals.
#' @keywords internal

MCStd2 <- function(mc,
                   alpha = c(0.001, 0.01, 0.05)) {
  stopifnot(inherits(mc, "semmcci"))
  stopifnot(mc$fun %in% c("MC", "MCMI"))

  # Step 1: 标准化估计值（包含截距）
  thetahat_std <- StdLav2(
    est = mc$thetahat$est,
    object = mc$args$lav
  )
  names(thetahat_std) <- colnames(mc$thetahatstar)

  # Step 2: 对每次抽样进行标准化
  n_iter <- nrow(mc$thetahatstar)
  i_free <- mc$args$lav@ParTable$free > 0
  p <- length(thetahat_std)


  foo <- function(i) {
    tryCatch(
      StdLav2(
        est = mc$thetahatstar[i, i_free],
        object = mc$args$lav
      ),
      error = function(e) rep(NA_real_, p),
      warning = function(w) rep(NA_real_, p)
    )
  }

  thetahatstar_std <- do.call(
    what = "rbind",
    args = lapply(seq_len(n_iter), foo)
  )
  colnames(thetahatstar_std) <- colnames(mc$thetahatstar)


  # Step 3: 生成汇总结果表
  se <- apply(thetahatstar_std, 2, sd, na.rm = TRUE)
  estimates <- thetahat_std
  R <- nrow(thetahatstar_std)

  # 计算所有 alpha 对应的置信区间
  lower_bounds <- alpha / 2
  upper_bounds <- 1 - lower_bounds
  ci_levels <- sort(c(lower_bounds, upper_bounds))

  ci_values <- t(sapply(ci_levels, function(level) {
    apply(thetahatstar_std, 2, quantile, probs = level, na.rm = TRUE)
  }))
  rownames(ci_values) <- paste0(round(ci_levels * 100, 1), "%")

  # 组装输出 data.frame
  result_table <- data.frame(
    Parameter = names(estimates),
    Estimate = estimates,
    SE = se,
    R = R,
    check.names = FALSE
  )

  # 添加 CI 列
  result_table <- cbind(result_table, as.data.frame(t(ci_values)))

  return(result_table)
}
