#' @title Conditional Indirect Effects for Categorical Moderators
#'
#' @description
#' \code{analyze_mm_categorical()} summarises Monte-Carlo results from a
#' fitted semi-parametric SEM (\code{semmcci} object) when the moderator
#' \emph{W} is **categorical** (dummy–coded by
#' \code{\link{PrepareData}} / \code{\link{PrepareMissingData}}).
#' It returns:
#' \enumerate{
#' \item the conditional indirect effect (IE) of every mediation path at
#'       each category of \emph{W};
#' \item pairwise contrasts of these IEs across categories;
#' \item the conditional (moderated) \code{a}, \code{b}, \code{d}, or
#'       \code{cp} path coefficients at each category; and
#' \item all corresponding pairwise contrasts.
#' }
#' Significance stars (\code{"*"}) are appended to the upper-CI column
#' when the CI excludes zero.
#'
#' @details
#' The function relies on two objects:
#' \itemize{
#'   \item \code{mc_result}: output of \code{\link{MCMI2}} (class
#'         \code{"semmcci"}) that contains **R** Monte-Carlo draws
#'         (\code{thetahatstar}).
#'   \item \code{prepared_data}: the first data set returned by
#'         \code{PrepareData()}, whose attribute \verb{"W_info"} lists the
#'         dummy variables (\code{dummy_names}) and their level mapping
#'         (\code{dummy_map}).  These are used to reconstruct
#'         category-specific coefficients.
#' }
#'
#' For each indirect path named \code{indirect_1}, \code{indirect_1_2},
#' …, the function:
#' \enumerate{
#'   \item extracts the \eqn{R} draws,
#'   \item computes mean, SE, and symmetric \eqn{100(1-\alpha)}\% CI
#'         (default 95 %),
#'   \item repeats for every category of \emph{W},
#'   \item repeats for every pairwise contrast of categories.
#' }
#' The same procedure is applied to moderated
#' \code{a}, \code{b}, \code{d}, \code{cp} coefficients, combining each
#' base coefficient with its associated dummy‐interaction terms.
#'
#' @param mc_result A \code{semmcci} object returned by
#'   \code{\link{MCMI2}}.
#' @param prepared_data A processed data frame created by
#'   \code{\link{PrepareData}()} or
#'   \code{\link{PrepareMissingData}()} — must contain the attribute
#'   \verb{"W_info"}.
#' @param ci_level Numeric, two-sided confidence level for summary
#'   statistics (default \code{0.95}).
#' @param digits Integer, number of decimal places to keep in the printed
#'   summary (default \code{3}).
#' @param MP moderation Path
#'
#' @return A named list with up to four data frames (or \code{NULL} if the
#'   component is not applicable):
#' \describe{
#'   \item{\code{conditional_IE}}{Conditional indirect effects at each
#'         category of \emph{W}.}
#'   \item{\code{IE_contrasts}}{All pairwise contrasts of the indirect
#'         effects.}
#'   \item{\code{path_levels}}{Conditional \code{a}/\code{b}/\code{d}/\code{cp}
#'         coefficients at each category.}
#'   \item{\code{path_contrasts}}{All pairwise contrasts of those path
#'         coefficients.}
#' }
#'
#' In every data frame the columns are:
#' \itemize{
#'   \item \code{Estimate}, \code{SE}
#'   \item \code{<lower>%CI.Lo}, \code{<upper>%CI.Up} where
#'         \code{<lower>} = \eqn{(1-ci\_level)/2 \times 100} and
#'         \code{<upper>} = \eqn{100 - <lower>} (e.g.\ 2.5 % and 97.5 %
#'         for a 95 % CI).  When the CI excludes 0, the upper limit carries
#'         a trailing \code{"*"}.
#' }
#'
#' @seealso
#' \code{\link{analyze_mm_continuous}} for continuous moderators,
#' \code{\link{PrepareData}}, \code{\link{MCMI2}}
#'
#' @examples
#' ## Not run: --------------------------------------------------------------
#' # res <- analyze_mm_categorical(mc_out, processed[[1]])
#' # res$conditional_IE
#' ## End(Not run)
#'
#' @keywords internal

analyze_mm_categorical <- function(mc_result, prepared_data,
                                       MP       = NULL,
                                       ci_level = 0.95,
                                       digits   = 8,
                                       debug    = FALSE) {

  # ========== 0. 小工具 ====================================================
  say <- function(...) if (debug) message(sprintf(...))

  make_ci_names <- function(ci) {
    lo <- paste0(formatC((1 - ci) / 2 * 100, format = "f", digits = 1), "%CI.Lo")
    up <- paste0(formatC((1 + ci) / 2 * 100, format = "f", digits = 1), "%CI.Up")
    c(lo, up)
  }
  summarize_vec <- function(v) {
    qs <- quantile(v, c((1 - ci_level)/2, (1 + ci_level)/2), names = FALSE)
    out <- data.frame(
      Estimate = mean(v),
      SE       = sd(v),
      check.names = FALSE
    )
    ci_names <- make_ci_names(ci_level)
    out[[ci_names[1]]] <- qs[1]
    out[[ci_names[2]]] <- qs[2]
    out[] <- lapply(out, round, digits)
    out
  }
  add_sig <- function(df) {
    ci_names <- make_ci_names(ci_level)
    if (all(ci_names %in% names(df)))
      df$Sig <- ifelse(df[[ci_names[1]]] * df[[ci_names[2]]] > 0, "*", "")
    df
  }
  pack_df <- function(lst, lbl) {
    if (!length(lst)) {
      say("→ %s: 空列表，返回 NULL", lbl)
      return(NULL)
    }
    out <- add_sig(do.call(rbind, lst))
    say("→ %s: %d 行", lbl, nrow(out))
    out
  }

  # ========== 1. 基础对象 =================================================
  theta <- as.matrix(mc_result)          # ※ 直接把 result 对象当抽样矩阵
  if (nrow(theta) == 0) stop("抽样矩阵为空！")
  Winfo  <- attr(prepared_data, "W_info")
  stopifnot(!is.null(Winfo))
  grp_var <- if (!is.null(Winfo$factor_name)) Winfo$factor_name else Winfo$raw
  groups  <- sort(unique(prepared_data[[grp_var]]))

  say("=== 基本信息 ===")
  say("• 调节变量组别: %s", paste(groups, collapse = ", "))
  say("• theta 维度: %d × %d", nrow(theta), ncol(theta))

  # ========== 2. 路径解析 =================================================
  get_indirect_paths <- function(col_names) {
    a <- grep("^a_?\\d+$",      col_names, value = TRUE)        # a1 / a_1
    b <- grep("^b_?\\d+$",      col_names, value = TRUE)        # b1 / b_1
    b_nm <- grep("^b_\\d+_\\d+$", col_names, value = TRUE)      # b_1_2

    edges <- data.frame(src = character(), tgt = character(), label = character())
    for (ai in a) {
      mi <- sub("^a_?", "", ai)
      edges <- rbind(edges, data.frame(src = "X", tgt = paste0("M", mi, "diff"), label = ai))
    }
    for (bi in b) {
      mi <- sub("^b_?", "", bi)
      edges <- rbind(edges, data.frame(src = paste0("M", mi, "diff"), tgt = "Y", label = bi))
    }
    for (bij in b_nm) {
      idx <- unlist(regmatches(bij, gregexpr("\\d+", bij)))
      edges <- rbind(edges, data.frame(src = paste0("M", idx[1], "diff"),
                                       tgt = paste0("M", idx[2], "diff"),
                                       label = bij))
    }
    graph <- split(edges, edges$src)
    dfs <- function(path) {
      last <- tail(path, 1)
      if (last == "Y") return(list(path))
      if (!last %in% names(graph)) return(list())
      paths <- list()
      for (tgt in graph[[last]]$tgt) {
        if (tgt %in% path) next
        paths <- c(paths, dfs(c(path, tgt)))
      }
      paths
    }
    raw_paths <- dfs("X")
    if (!length(raw_paths)) return(list())
    result <- lapply(raw_paths, function(nodes) {
      coefs <- mediators <- character()
      for (i in seq_len(length(nodes) - 1)) {
        edge <- edges[edges$src == nodes[i] & edges$tgt == nodes[i+1], ]
        coefs <- c(coefs, edge$label[1])
        if (grepl("^M\\d+diff$", nodes[i]))
          mediators <- c(mediators, sub("^M(\\d+)diff$", "\\1", nodes[i]))
      }
      list(
        path_name = paste0("indirect_effect_", paste(mediators, collapse = "_")),
        coefs     = coefs,
        mediators = paste(mediators, collapse = " ")
      )
    })
    result[!duplicated(sapply(result, `[[`, "path_name"))]
  }

  get_mod_prefix <- function(base) {
    if (base == "cp")              return("cpw")
    if (grepl("^a_?\\d+$", base))  return(paste0("aw", sub("^a_?", "", base)))
    if (grepl("^b_?\\d+$", base))  return(paste0("bw", sub("^b_?", "", base)))
    if (grepl("^d_?\\d+$", base))  return(paste0("dw", sub("^d_?", "", base)))
    if (grepl("^b_\\d+_\\d+$", base)) return(paste0("bw_", sub("^b_", "", base)))
    if (grepl("^d_\\d+_\\d+$", base)) return(paste0("dw_", sub("^d_", "", base)))
    base
  }

  apply_mod <- function(base, group) {
    base_vec <- theta[, base, drop = TRUE]
    # 若 MP 为空或 base 不在 MP，则不考虑调节项
    if (length(MP) && base %in% MP) {
      prefix <- get_mod_prefix(base)
      mods <- grep(paste0("^", prefix, "_W\\d+$"), colnames(theta), value = TRUE)
      for (m in mods) {
        dm   <- sub(".*_(W\\d+)$", "\\1", m)  # eg. W1
        wval <- unique(prepared_data[[dm]][prepared_data[[grp_var]] == group])
        stopifnot(length(wval) == 1)
        base_vec <- base_vec + theta[, m] * wval
      }
    }
    base_vec
  }

  pars   <- colnames(theta)
  paths_all <- get_indirect_paths(pars)
  paths     <- Filter(function(p) any(p$coefs %in% MP), paths_all)

  say("• 可用间接路径总数: %d, 经 MP 筛选后: %d",
      length(paths_all), length(paths))

  # ========== 3. 容器 =====================================================
  cond_IE <- IE_ct <- list()
  path_lv <- path_ct <- list()
  tot_ind_vals <- setNames(vector("list", length(groups)), groups)
  for (g in groups) tot_ind_vals[[g]] <- numeric(nrow(theta))

  # ========== 4. 各条间接路径 & 总间接 ====================================
  for (pth in paths) {
    vals_g <- list()
    for (g in groups) {
      comp_list <- lapply(pth$coefs, function(cn) apply_mod(cn, g))
      vals_g[[g]] <- Reduce(`*`, comp_list)
      tot_ind_vals[[g]] <- tot_ind_vals[[g]] + vals_g[[g]]
    }
    for (g in groups)
      cond_IE[[length(cond_IE)+1]] <-
        data.frame(IE = pth$path_name, Group = g,
                   summarize_vec(vals_g[[g]]), check.names = FALSE)
    for (pr in utils::combn(groups, 2, simplify = FALSE)) {
      diffv <- vals_g[[pr[2]]] - vals_g[[pr[1]]]
      IE_ct[[length(IE_ct)+1]] <-
        data.frame(IE = pth$path_name,
                   Contrast = paste(pr[2], "-", pr[1]),
                   summarize_vec(diffv), check.names = FALSE)
    }
  }

  # ========== 5. 单路径系数 ===============================================
  for (base in MP) {
    for (g in groups)
      path_lv[[length(path_lv)+1]] <-
        data.frame(Path = base, Group = g,
                   summarize_vec(apply_mod(base, g)), check.names = FALSE)
    for (pr in utils::combn(groups, 2, simplify = FALSE)) {
      diffv <- apply_mod(base, pr[2]) - apply_mod(base, pr[1])
      path_ct[[length(path_ct)+1]] <-
        data.frame(Path = base, Contrast = paste(pr[2], "-", pr[1]),
                   summarize_vec(diffv), check.names = FALSE)
    }
  }

  # ========== 6. 总间接 & 总效应 ==========================================
  cond_overall <- overall_ct <- list()
  dir_vals <- setNames(lapply(groups, function(g) apply_mod("cp", g)), groups)
  tot_eff_vals <- mapply(`+`, dir_vals, tot_ind_vals, SIMPLIFY = FALSE)

  say("• tot_ind_vals 均值: %s",
      paste(round(sapply(tot_ind_vals, mean), 6), collapse = ", "))

  for (g in groups) {
    cond_overall[[length(cond_overall)+1]] <-
      data.frame(Effect = "total_indirect", Group = g,
                 summarize_vec(tot_ind_vals[[g]]), check.names = FALSE)
    cond_overall[[length(cond_overall)+1]] <-
      data.frame(Effect = "total_effect", Group = g,
                 summarize_vec(tot_eff_vals[[g]]), check.names = FALSE)
  }
  for (pr in utils::combn(groups, 2, simplify = FALSE)) {
    hi <- pr[2]; lo <- pr[1]; lab <- paste(hi, "-", lo)
    overall_ct[[length(overall_ct)+1]] <-
      data.frame(Effect = "total_indirect", Contrast = lab,
                 summarize_vec(tot_ind_vals[[hi]] - tot_ind_vals[[lo]]),
                 check.names = FALSE)
    overall_ct[[length(overall_ct)+1]] <-
      data.frame(Effect = "total_effect",  Contrast = lab,
                 summarize_vec(tot_eff_vals[[hi]] - tot_eff_vals[[lo]]),
                 check.names = FALSE)
  }


  cond_overall <- pack_df(cond_overall)
  overall_ct <- pack_df(overall_ct)

  cond_overall <- cond_overall[
      order(match(cond_overall$Effect,
                  c("total_indirect", "total_effect"))), ]

  overall_ct <- overall_ct[
    order(match(overall_ct$Effect,
                c("total_indirect", "total_effect"))), ]

  # ========== 7. 返回 =====================================================
  res <- list(
    type                 = "categorical",
    conditional_IE       = pack_df(cond_IE,        "conditional_IE"),
    IE_contrasts         = pack_df(IE_ct,          "IE_contrasts"),
    conditional_overall  = cond_overall,
    overall_contrasts    = overall_ct,
    extra = list(
      path_levels    = pack_df(path_lv, "path_levels"),
      path_contrasts = pack_df(path_ct, "path_contrasts")
    )
  )
  say("=== DONE ===")
  say("• conditional_overall 为空? %s", is.null(res$conditional_overall))
  say("• overall_contrasts   为空? %s", is.null(res$overall_contrasts))

  invisible(res)
}


