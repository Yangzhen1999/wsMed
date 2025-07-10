#' @title Conditional Indirect Effects with a Continuous Moderator
#'
#' @description
#' Summarises Monte-Carlo draws from a \code{semmcci} object when the
#' moderator \emph{W} is \strong{continuous}.
#' The function outputs:
#' \enumerate{
#'   \item \bold{mod_coeff}   – table of every moderated path coefficient
#'         (\code{aw}, \code{bw}, \code{dw}, \code{cpw}) with its base
#'         counterpart and 95 % CI;
#'   \item \bold{beta_coef}   – indirect effect at three reference points
#'         of \emph{W} (–1 SD, mean, +1 SD);
#'   \item \bold{path_HML}    – likewise, the moderated primary paths
#'         (\code{a}, \code{b}, …) at the three W levels;
#'   \item \bold{theta_curve} – full curve of the indirect effect over a
#'         user-defined grid of centred \emph{W};
#'   \item \bold{path_curve}  – full curve for every moderated base path.
#' }
#' Significance stars (\code{"*"}) are added where the CI excludes 0.
#'
#' @param mc_result A \code{semmcci} object returned by \code{MCMI2()}.
#' @param data A processed data frame (first element of
#'   \code{PrepareData()} output) that contains the raw moderator column.
#' @param W_raw_name Name of the moderator column in \code{data}.
#'   Default \code{"W"}.
#' @param ci_level Two-sided confidence level (default \code{0.95}).
#' @param W_values Numeric vector of raw \emph{W} values at which to
#'   evaluate “Low / Mid / High” effects.
#'   If \code{NULL} (default) the vector \eqn{mean(W) ± 1\,SD} is used.
#' @param n_curve Integer, number of points used to draw the continuous
#'   effect curve (default \code{120}).
#' @param digits Integer, decimal places for rounding (default \code{3}).
#'
#' @return A named list with components:
#' \describe{
#'   \item{\code{mod_coeff}}{Moderated path coefficients (\code{aw},
#'         \code{bw}, …).}
#'   \item{\code{beta_coef}}{Indirect effect at –1 SD / 0 SD / +1 SD.}
#'   \item{\code{path_HML}}{Moderated base paths at the three W levels.}
#'   \item{\code{theta_curve}}{Data frame of the indirect effect curve.}
#'   \item{\code{path_curve}}{Data frame of each moderated base-path
#'         curve.}
#' }
#'
#' @importFrom utils  tail modifyList
#' @importFrom stats  model.matrix
#' @importFrom methods slot
#' @importFrom stats complete.cases
#'
#' @keywords internal

# -----------------------------------------------------------------------------
# analyze_mm_continuous.R ── Monte‑Carlo summary for continuous moderation -----
# -----------------------------------------------------------------------------
# Public (internal‑only) engine that aggregates MC draws when the moderator W
# is *continuous*. Low‑level helpers live in cont_helpers.R (.cont_*).
# The function signature and returned list are identical to the original
# implementation so that existing tests keep working.


analyze_mm_continuous <- function(mc_result, data, MP,
                                  W_raw_name = "W",
                                  ci_level   = 0.95,
                                  W_values   = NULL,
                                  n_curve    = 120,
                                  digits     = 8) {

  if (!W_raw_name %in% names(data))
    stop("Moderator column `", W_raw_name, "` not found in `data`.")

  if (!(is.character(MP) && length(MP) > 0))
    stop("`MP` must be a non-empty character vector of coefficient names.")

  th   <- mc_result
  Wraw <- data[[W_raw_name]]
  muW  <- mean(Wraw);  sdW <- sd(Wraw)
  if (is.null(W_values)) W_values <- muW + c(-1, 0, 1) * sdW
  Level_lbl <- c("-1 SD", "0 SD", "+1 SD")
  probs     <- c((1 - ci_level) / 2, (1 + ci_level) / 2)
  extend <- 0.5
  Wc_seq <- seq(min(Wraw) - extend*sdW, max(Wraw) + extend*sdW, length.out = n_curve) - muW

  ## ---------- 1. 所有调节项 ----------
  mod_cols <- grep("^(aw|bw|dw|cpw)", colnames(th), value = TRUE)
  mod_cols <- mod_cols[!grepl("_W[2-9]\\d*$", mod_cols)]

  ## ---------- 2. 提取 base 系数 ----------
  mod_coeff <- do.call(rbind, lapply(mod_cols, function(nm) {
    base <- sub("_W\\d+$", "", nm)
    base <- sub("^aw", "a", base)
    base <- sub("^bw", "b", base)
    base <- sub("^dw", "d", base)
    base <- sub("^cpw", "cp", base)

    data.frame(
      Path     = nm,
      BaseCoef = base,
      W_dummy  = W_raw_name,
      t(mc_summary_se(th[, nm], ci_level, digits)),
      row.names = NULL,
      check.names = FALSE
    )
  }))
  mod_coeff <- fix_pct_names(mod_coeff)

  ## ---------- 3. 识别包含 MP 的所有路径 ----------
  paths_all <- get_indirect_paths(colnames(th))
  paths <- Filter(\(p) any(p$coefs %in% MP), paths_all)

  if (!length(paths)) {
    warning("No indirect paths include any of: ", paste(MP, collapse = ", "))
    return(list(
      mod_coeff   = mod_coeff,
      beta_coef   = NULL,
      path_HML    = NULL,
      theta_curve = NULL,
      path_curve  = NULL
    ))
  }

  ## ---------- 4. 分析路径 ----------
  beta_tbl <- list(); theta_curve <- list()
  path_HML <- list(); path_curve <- list()

  for (pth in paths) {
    coef_list <- lapply(pth$coefs, function(cn) {
      base  <- th[, cn]
      wcols <- grep(paste0("^", sub("^([abd])", "\\1w", cn), "(_|$)"),
                    colnames(th), value = TRUE)
      wcols <- wcols[!grepl("_W[2-9]\\d*$", wcols)]
      wsum  <- if (length(wcols)) rowSums(th[, wcols, drop = FALSE]) else 0
      list(base = base, w = wsum)
    })

    for (k in seq_along(W_values)) {
      wc <- W_values[k] - muW
      samp <- Reduce(`*`, lapply(coef_list, \(z) z$base + z$w * wc))
      beta_tbl[[length(beta_tbl) + 1]] <- data.frame(
        Path      = pth$path_name,
        Mediators = pth$mediators,
        Level     = Level_lbl[k],
        W_value   = round(W_values[k], 3),
        t(mc_summary_se(samp, ci_level, digits)),
        row.names = NULL
      )
    }

    th_mat <- sapply(Wc_seq, \(wc) Reduce(`*`, lapply(coef_list, \(z) z$base + z$w * wc)))
    ci <- t(apply(th_mat, 2, quantile, probs = probs, na.rm = TRUE))
    theta_curve[[length(theta_curve) + 1]] <- data.frame(
      Path       = pth$path_name,
      Mediators  = pth$mediators,
      W_center   = Wc_seq,
      W_raw      = Wc_seq + muW,
      Estimate   = apply(th_mat, 2, mean),
      SE         = apply(th_mat, 2, sd),
      CI.LL      = ci[, 1],
      CI.UL      = ci[, 2],
      row.names  = NULL
    )
  }

  ## ---------- 4-bis. Total effect / Total indirect ----------
  ## (A) 先准备直接效应和调节项 -------------------------------
  cp_base  <- if ("cp" %in% colnames(th)) th[, "cp"] else 0
  cpw_cols <- grep("^cpw", colnames(th), value = TRUE)
  cpw_sum  <- if (length(cpw_cols))
    rowSums(th[, cpw_cols, drop = FALSE])
  else
    rep(0, length(cp_base))          # 与 cp_base 等长

  ## (B) 计算 Wc_seq 上的采样矩阵 -----------------------------
  # direct: cp + cpw * w
  direct_mat <- outer(cp_base, rep(1, length(Wc_seq))) +
    outer(cpw_sum,  Wc_seq, `*`)

  # indirect: 对每条路径求乘积，再对路径求和
  ind_mat <- sapply(Wc_seq, function(wc){
    rowSums(sapply(paths, function(pth){
      Reduce(`*`, lapply(pth$coefs, function(cn){
        base  <- th[, cn]
        wcols <- grep(paste0("^", sub("^([abd])", "\\1w", cn), "(_|$)"),
                      colnames(th), value = TRUE)
        wcols <- wcols[!grepl("_W[2-9]\\d*$", wcols)]
        wsum  <- if (length(wcols)) rowSums(th[, wcols, drop = FALSE]) else 0
        base + wsum * wc
      }))
    }))
  })

  tot_mat <- direct_mat + ind_mat   # total effect

  ## (C) 把整条曲线写入 theta_curve ---------------------------
  make_curve_df <- function(mat, label){
    ci <- t(apply(mat, 2, quantile, probs = probs))
    data.frame(
      Path      = label,
      Mediators = label,
      W_center  = Wc_seq,
      W_raw     = Wc_seq + muW,
      Estimate  = colMeans(mat),
      SE        = apply(mat, 2, sd),
      CI.LL     = ci[, 1],
      CI.UL     = ci[, 2],
      row.names = NULL
    )
  }

  theta_curve[[length(theta_curve)+1]] <- make_curve_df(ind_mat,  "total_indirect")
  theta_curve[[length(theta_curve)+1]] <- make_curve_df(tot_mat,  "total_effect")

  ## (D) 三个典型点（-1SD, 0, +1SD） --------------------------
  overall_tbl <- list()

  for (k in seq_along(W_values)) {
    wc <- W_values[k] - muW
    ind_sample <- ind_mat[, which.min(abs(Wc_seq - wc))]
    tot_sample <- tot_mat[, which.min(abs(Wc_seq - wc))]

    overall_tbl[[length(overall_tbl)+1]] <-
      data.frame(Effect = "total_indirect",
                 Level  = Level_lbl[k],
                 W_value = round(W_values[k], 3),
                 t(mc_summary_se(ind_sample, ci_level, digits)),
                 row.names = NULL)

    overall_tbl[[length(overall_tbl)+1]] <-
      data.frame(Effect = "total_effect",
                 Level  = Level_lbl[k],
                 W_value = round(W_values[k], 3),
                 t(mc_summary_se(tot_sample, ci_level, digits)),
                 row.names = NULL)
  }

  ## (E) 排序 + 清洗列名 + 显著性 ------------------------------
  overall_tbl <- do.call(rbind, overall_tbl)

  ord <- c("total_indirect", "total_effect")        # ② 排序
  overall_tbl <- overall_tbl[
    order(match(overall_tbl$Effect, ord),
          overall_tbl$W_value),]

  conditional_overall <- add_sig(.clean_ci_names(overall_tbl))


  ## ---------- 5. 计算单路径 HML ----------
  moderated_base <- unique(union(MP, mod_coeff$BaseCoef))
  moderated_base <- intersect(moderated_base, colnames(th))

  for (bc in moderated_base) {
    wcols <- grep(paste0("^", sub("^([abd])", "\\1w", bc), "(_|$)"),
                  colnames(th), value = TRUE)
    wcols <- wcols[!grepl("_W[2-9]\\d*$", wcols)]
    base <- th[, bc]
    wsum <- rowSums(th[, wcols, drop = FALSE])

    for (k in seq_along(W_values)) {
      wc <- W_values[k] - muW
      samp <- base + wsum * wc
      path_HML[[length(path_HML) + 1]] <- data.frame(
        Path     = bc,
        Level    = Level_lbl[k],
        W_value  = round(W_values[k], 3),
        t(mc_summary_se(samp, ci_level, digits)),
        row.names = NULL
      )
    }

    mat <- sapply(Wc_seq, \(wc) base + wsum * wc)
    ci <- t(apply(mat, 2, quantile, probs = probs, na.rm = TRUE))
    path_curve[[length(path_curve) + 1]] <- data.frame(
      Path      = bc,
      W_center  = Wc_seq,
      W_raw     = Wc_seq + muW,
      Estimate  = apply(mat, 2, mean),
      SE        = apply(mat, 2, sd),
      CI.LL     = ci[, 1],
      CI.UL     = ci[, 2],
      row.names = NULL
    )
  }


  ## ---------- 输出 ----------
  beta_out <- if (length(beta_tbl))
    add_sig(.clean_ci_names(do.call(rbind, beta_tbl)))
  else NULL

  path_HML <- if (length(path_HML))
    add_sig(.clean_ci_names(do.call(rbind, path_HML)))
  else NULL

  mod_coeff <- add_sig(fix_ci_names(mod_coeff, ci_level))


  list(
    mod_coeff         = mod_coeff,
    beta_coef         = beta_out,
    path_HML          = path_HML,
    conditional_overall = conditional_overall,   # ★ 新增 ★
    theta_curve       = if (length(theta_curve)) do.call(rbind, theta_curve) else NULL,
    path_curve        = if (length(path_curve))  do.call(rbind, path_curve)  else NULL
  )

}



#' @title Parse All Possible Indirect Paths from Column Names
#'
#' @description
#' Infers every unique mediation chain that can be constructed from a set of
#' coefficient names following the WsMed naming convention
#' (e.g., \code{a1}, \code{b_1_3}, \code{d_2_1}, \code{b3}).
#' The function returns a list; each element describes one indirect effect:
#' \itemize{
#'   \item \code{path_name}  – canonical name, e.g.\ \code{"indirect_effect_1_3"}\cr
#'         (mediators are concatenated in the encountered order);
#'   \item \code{coefs}      – vector of coefficient names that define the path;
#'   \item \code{mediators}  – readable label such as \code{"M1 M3"}.
#' }
#'
#' @details
#' Internally the function:
#' \enumerate{
#'   \item identifies all \code{a}, \code{b}, and \code{d} coefficients
#'         available in \code{col_names};
#'   \item constructs a directed graph from \code{X → Mi}, \code{Mi → Y},
#'         and \code{Mi → Mj} edges;
#'   \item runs a depth-first search from the exposure (\emph{X}) to the
#'         outcome (\emph{Y});
#'   \item converts every node sequence (X → … → Y) into the corresponding
#'         coefficient sequence.
#' }
#' Duplicate paths (identical mediator ordering) are removed.
#'
#' @param col_names Character vector of coefficient names
#'   (typically \code{colnames(mc_result$thetahatstar)}).
#'
#' @return A list of path descriptors; each element is itself a list with
#'   components \code{path_name}, \code{coefs}, and \code{mediators}.
#'   If no valid path exists, an empty list is returned.
#'
#' @keywords internal

get_indirect_paths <- function(col_names) {
  # 收集路径系数
  a <- grep("^a\\d+$", col_names, value = TRUE)
  b <- grep("^b\\d+$", col_names, value = TRUE)
  b_nm <- grep("^b_\\d+_\\d+$", col_names, value = TRUE)

  # 构建边：X → M#diff（由 a_i），M#diff → M#diff（b_i_j），M#diff → Y（b_i）
  edges <- data.frame(src = character(), tgt = character(), label = character())

  # X → Mi
  for (ai in a) {
    mi <- sub("^a", "", ai)
    edges <- rbind(edges, data.frame(src = "X", tgt = paste0("M", mi, "diff"), label = ai))
  }

  # Mi → Y
  for (bi in b) {
    mi <- sub("^b", "", bi)
    edges <- rbind(edges, data.frame(src = paste0("M", mi, "diff"), tgt = "Y", label = bi))
  }

  # Mi → Mj
  for (bij in b_nm) {
    idx <- unlist(regmatches(bij, gregexpr("\\d+", bij)))
    edges <- rbind(edges, data.frame(src = paste0("M", idx[1], "diff"),
                                     tgt = paste0("M", idx[2], "diff"),
                                     label = bij))
  }

  # 构建图
  graph <- split(edges, edges$src)

  # DFS 查找所有从 X 到 Y 的路径
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

  # 构建间接路径列表
  result <- lapply(raw_paths, function(nodes) {
    coefs <- character()
    mediators <- character()
    for (i in seq_len(length(nodes) - 1)) {
      edge <- edges[edges$src == nodes[i] & edges$tgt == nodes[i+1], ]
      if (nrow(edge)) coefs <- c(coefs, edge$label[1])
      if (grepl("^M\\d+diff$", nodes[i])) {
        mediators <- c(mediators, sub("^M(\\d+)diff$", "\\1", nodes[i]))
      }
    }
    list(
      path_name = paste0("indirect_effect_", paste(mediators, collapse = "_")),
      coefs     = coefs,
      mediators = paste(mediators, collapse = " ")
    )
  })

  # 去重
  result[!duplicated(sapply(result, `[[`, "path_name"))]
}


# -----------------------------------------------------------------------------
# mc_summary_helpers.R ── Internal utils formerly in‑lined in analyze_mm_*() ----
# -----------------------------------------------------------------------------
#' @title  mc_summary_se
#' @param x   Numeric vector of length *R* (e.g., one column of `thetahatstar`).
#' @param ci  Two‑sided confidence level (default 0.95).
#' @param digits Integer; round results to this many decimal places.
#'
#' @return A named numeric vector: *Estimate, SE, <lower>%CI.Lo, <upper>%CI.Up*.
#' @keywords internal
mc_summary_se <- function(x, ci = .95, digits = 3) {
  qs <- quantile(x, c((1 - ci) / 2, (1 + ci) / 2), na.rm = TRUE)
  names(qs) <- .make_ci_names(ci)
  round(c(Estimate = mean(x), SE = sd(x), qs), digits)
}

#' Make CI column names like "2.5%CI.Lo / 97.5%CI.Up"
#' @keywords internal
.make_ci_names <- function(ci) {
  lo <- paste0(round((1 - ci) / 2 * 100, 1), "%CI.Lo")
  up <- paste0(round((1 + ci) / 2 * 100, 1), "%CI.Up")
  c(lo, up)
}

#' Fix legacy CI column names in a data.frame
#'
#' Converts columns like `CI[LL]` / `CI[UL]` or `CI.LL` / `CI.UL` to the
#' standard produced by `.make_ci_names()`.
#' @keywords internal
fix_ci_names <- function(df, ci = .95) {
  old <- grep("CI\\[LL\\]|CI\\.LL|CI\\[UL\\]|CI\\.UL", names(df), value = TRUE)
  if (length(old) >= 2) {
    new <- .make_ci_names(ci)
    names(df)[match(old[1], names(df))] <- new[1]
    names(df)[match(old[2], names(df))] <- new[2]
  }
  df
}

#' Append significance stars based on CI
#' @keywords internal
add_sig <- function(df) {
  ci_cols <- grep("%CI\\.Lo$|%CI\\.Up$", names(df), value = TRUE)
  if (length(ci_cols) == 2)
    df$Sig <- ifelse(df[[ci_cols[1]]] * df[[ci_cols[2]]] > 0, "*", "")
  else df$Sig <- ""
  df
}

#' Fix % characters mangled by `make.names()`
#' @keywords internal
fix_pct_names <- function(df) {
  if (is.null(df) || !is.data.frame(df)) return(df)
  names(df) <- sub("^X([0-9.]+)(\\.CI\\.(Lo|Up))", "\\1%CI.\\2", names(df))  # e.g. X2.5.CI.Lo → 2.5%CI.Lo
  names(df) <- sub("([0-9]+)\\.CI\\.(Lo|Up)", "\\1%CI.\\2", names(df))      # 2.5.CI.Lo → 2.5%CI.Lo
  df
}

#' Clean all CI column names into the standard form
#' @keywords internal
.clean_ci_names <- function(df, ci_level = 0.95) {
  names(df) <- gsub(
    pattern = "^X?([0-9.]+)(?:%?)?([._]CI)?[._]?(Lo|Up)$",
    replacement = "\\1%CI.\\3",
    x = names(df),
    ignore.case = TRUE
  )
  df
}

