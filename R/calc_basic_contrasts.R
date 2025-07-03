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

#' @title 计算 Monte Carlo 样本的估计值、标准误与 CI（带百分号列名）
#'
#' @description
#' `mc_summary_pct()` 对 Monte Carlo 抽样样本向量 `x` 进行摘要，
#' 计算其均值、标准差和置信区间，并生成带有百分号格式列名的
#' `data.frame`。常用于生成具有路径标签的中介效应或路径系数估计表。
#'
#' 返回列包含：
#' * `Path`: 路径标签；
#' * `Estimate`: 样本均值；
#' * `SE`: 样本标准差；
#' * `<p%CI.Lo>`, `<p%CI.Up>`: 百分位置信区间上下限，列名中带 `%`。
#'
#' @param x       数值向量，Monte Carlo 抽样结果。
#' @param label   字符型，输出中 `Path` 列的名称。
#' @param ci_level 置信区间水平（默认 `0.95`）。
#' @param digits  保留小数位数（默认 `3`）。
#'
#' @return
#' 一个 `data.frame`，包含路径标签、估计值、标准误与 CI。
#' 列名格式如 `"2.5%CI.Lo"` 与 `"97.5%CI.Up"`。
#'
#' @examples
#' \dontrun{
#' x <- rnorm(10000, mean = 0.2, sd = 0.05)
#' mc_summary_pct(x, label = "indirect_1")
#' }
#'
#' @seealso
#' [mc_summary_se()] – 返回标准命名列（`CI.LL`, `CI.UL`），适用于内部处理
#'
#' @export

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
