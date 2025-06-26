#' @title Basic Contrasts for Indirect Effects and Pre/Post Path Coefficients
#'
#' @description
#' \code{calc_basic_contrasts()} extracts two sets of convenient summary
#' contrasts from a Monte-Carlo SEM result (\code{semmcci} object):
#' \enumerate{
#'   \item All pairwise differences between indirect effects
#'         (\code{indirect_*} columns).
#'   \item Pre-test (\eqn{X0}) and post-test (\eqn{X1}) coefficients for
#'         every primary \code{b} path, computed via
#'         \eqn{X1 = (2b + d) / 2} and \eqn{X0 = X1 - d}.
#' }
#' Each contrast is summarised by its Monte-Carlo mean, SD, and a symmetric
#' \eqn{100(1-\alpha)}\% confidence interval.
#'
#' @details
#' Given the matrix \code{thetahatstar} (\eqn{R \times P}) of Monte-Carlo
#' draws:
#' \itemize{
#'   \item Indirect-effect columns are detected by the pattern
#'         \verb{^indirect_}.
#'   \item \code{b} paths follow either \code{b1}, \code{b_1_2}, etc.
#'         Their matching \code{d} path (\code{d1}, \code{d_1_2}, …)
#'         is located and used to derive \eqn{X1} / \eqn{X0}.
#' }
#'
#' The helper \code{mc_summary_pct()} is applied to every contrast vector
#' to obtain
#' \code{Estimate}, \code{SE}, \code{<p>%CI.Lo}, \code{<p>%CI.Up}.
#' Column names are then cleaned by \code{fix_pct_names()} so that
#' \code{"2.5%CI.Lo"/"97.5%CI.Up"} (for a 95 % CI) are produced.
#'
#' @param mc_result A Monte-Carlo result of class \code{"semmcci"}
#'   (returned by \code{\link{MCMI2}}).
#' @param ci_level Confidence level for the CI columns (default \code{0.95}).
#' @param digits Number of decimal places in the summary (default \code{3}).
#'
#' @return A named list with up to two data frames:
#' \describe{
#'   \item{\code{IE_contrasts}}{All pairwise contrasts of indirect
#'         effects (or \code{NULL} if fewer than two IEs are present).}
#'   \item{\code{Xcoef}}{Rows \code{X1_b*} and \code{X0_b*} for every
#'         detected \code{b} path (or \code{NULL} if none).}
#' }
#'
#' @seealso
#' \code{\link{analyze_mm_categorical}}, \code{\link{analyze_mm_continuous}}
#'
#' @examples
#' ## Not run: --------------------------------------------------------------
#' # basic <- calc_basic_contrasts(mc_out)
#' # basic$IE_contrasts
#' # basic$Xcoef
#' ## End(Not run)
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
