#' @title Johnson–Neyman (JN) Interval for a Continuous Moderator Curve
#'
#' @description
#' \code{jn_interval()} derives the Johnson–Neyman significance region(s)
#' from a data frame produced by
#' \code{\link{analyze_mm_continuous}()} (either \code{theta_curve} or
#' \code{path_curve}).
#' It locates every transition point where the Monte-Carlo confidence
#' band of an effect crosses zero and converts those points into raw-W
#' cut-offs together with cumulative-percent information.
#'
#' @details
#' Given a curve data frame that contains:
#' \itemize{
#'   \item column \code{W_raw} – the raw moderator values used on the
#'         horizontal axis;
#'   \item two CI columns named “\code{<p>%CI.Lo}” and
#'         “\code{<p>%CI.Up}” (picked by \code{pick_ci_cols()});
#' }
#' the function:
#' \enumerate{
#'   \item determines for every point whether the CI excludes zero
#'         (\emph{sig} flag);
#'   \item finds adjacent pairs where the flag flips, and linearly
#'         interpolates the exact zero-crossing on \code{W_raw};
#'   \item constructs contiguous intervals \eqn{[W_{lo}, W_{up}]} between
#'         the breakpoints;
#'   \item reports, for each interval:
#'         \itemize{
#'           \item the lower / upper cut-offs (\code{W_lo}, \code{W_up}),
#'           \item the cumulative-percent of raw W below each cut
#'                 (\code{pct_lo}, \code{pct_up}) and inside the interval
#'                 (\code{pct_span}),
#'           \item a \code{type} label:
#'                 \code{"Sig"} if the interval is significant
#'                 (CI excludes 0 for every grid point inside),
#'                 otherwise \code{"n.s."}.
#'         }
#' }
#'
#' @param curve_df A curve data frame returned by
#'   \code{analyze_mm_continuous()} containing columns \code{W_raw},
#'   \code{<p>%CI.Lo}, \code{<p>%CI.Up}.
#' @param W_raw_vector Numeric vector of the original (raw) moderator
#'   values; used to compute cumulative percentages.
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{\code{W_lo}, \code{W_up}}{Lower / upper raw-W cut-offs that
#'         delimit each sub-interval.}
#'   \item{\code{pct_lo}, \code{pct_up}}{Cumulative proportion of the
#'         sample below \code{W_lo} and \code{W_up}.}
#'   \item{\code{pct_span}}{Proportion of the sample that lies inside the
#'         interval.}
#'   \item{\code{type}}{\code{"Sig"} if the effect is significant across
#'         the whole interval, otherwise \code{"n.s."}.}
#' }
#'
#' If the confidence band never crosses zero, a single row with
#' \code{NA} values and \code{type = "none"} is returned.
#'
#' @seealso
#' \code{\link{analyze_mm_continuous}}, \code{\link{pick_ci_cols}}
#'
#' @examples
#' ## Not run: --------------------------------------------------------------
#' # jn_tbl <- jn_interval(out$theta_curve, processed$W_raw)
#' # print(jn_tbl)
#' ## End(Not run)
#'
#' @keywords internal

jn_interval <- function(curve_df, W_raw_vector) {
  ci <- pick_ci_cols(names(curve_df)); if (length(ci)<2)
    return(data.frame(W_lo=NA,W_up=NA,pct_lo=NA,pct_up=NA,
                      pct_span=NA,type="none"))
  lo <- curve_df[[ci[1]]]; up <- curve_df[[ci[2]]]
  sig<- lo*up>0; w <- curve_df$W_raw

  # cut‑points
  idx <- which(diff(sig)!=0); cuts <- numeric()
  for (i in idx) {
    t <- if (lo[i]*lo[i+1]<0) lo[i]/(lo[i]-lo[i+1])
    else                  up[i]/(up[i]-up[i+1])
    cuts<-c(cuts,w[i]+t*(w[i+1]-w[i]))
  }
  brk <- sort(unique(c(min(w),cuts,max(w))))
  ec  <- ecdf(W_raw_vector)

  out <- data.frame(
    W_lo   = head(brk,-1),
    W_up   = tail(brk,-1))
  out$pct_lo   <- sprintf("%.1f%%",100*ec(out$W_lo))
  out$pct_up   <- sprintf("%.1f%%",100*ec(out$W_up))
  out$pct_span <- sprintf("%.1f%%",
                          100* sapply(seq_len(nrow(out)), function(i)
                            mean(W_raw_vector>=out$W_lo[i] &
                                   W_raw_vector<=out$W_up[i])))
  out$type <- ifelse(mapply(function(a,b) any(sig & w>=a & w<=b),
                            out$W_lo,out$W_up),"Sig","n.s.")
  out
}


