#' @title Summarise Effects with a Continuous Moderator
#'
#' @description
#' `analyze_mm_continuous()` summarises Monte Carlo draws from a `semmcci`
#' object when the moderator `W` is continuous. It reports moderated path
#' coefficients, conditional indirect effects, conditional path coefficients,
#' and effect curves across values of the moderator.
#'
#' @details
#' The function first summarises the coefficients associated with moderated
#' paths, including interaction terms such as `aw`, `bw`, `dw`, and `cpw`,
#' together with their corresponding base coefficients and confidence
#' intervals.
#'
#' It then evaluates conditional indirect effects and moderated path
#' coefficients at three reference values of the moderator. By default, these
#' values are the moderator mean and one standard deviation below and above
#' the mean. Alternative reference values can be supplied through `W_values`.
#'
#' Finally, the function evaluates the conditional indirect effects and
#' moderated path coefficients over a moderator grid. These results can be
#' used to plot effect curves or identify regions in which the confidence
#' interval excludes zero.
#'
#' An asterisk is added to an effect when its confidence interval excludes
#' zero.
#'
#' @param mc_result A `semmcci` object returned by `MCMI2()`.
#' @param data A processed data frame containing the original moderator
#'   variable. This is typically the first component returned by
#'   `PrepareData()`.
#' @param W_raw_name A character string giving the name of the moderator
#'   variable in `data`. The default is `"W"`.
#' @param ci_level A numeric value between zero and one specifying the
#'   two-sided confidence level. The default is `0.95`.
#' @param W_values An optional numeric vector containing three raw moderator
#'   values at which to evaluate the conditional effects. If `NULL`, the
#'   moderator mean and values one standard deviation below and above the mean
#'   are used.
#' @param n_curve A positive integer specifying the number of moderator values
#'   used to construct each effect curve. The default is `120`.
#' @param digits A non-negative integer specifying the number of decimal places
#'   used to round the reported results. The default is `3`.
#'
#' @return A named list with the following components:
#' \describe{
#'   \item{\code{mod_coeff}}{
#'     A data frame summarising the moderated path coefficients, their
#'     corresponding base coefficients, and confidence intervals.
#'   }
#'   \item{\code{beta_coef}}{
#'     A data frame containing the conditional indirect effects at the three
#'     reference values of the moderator.
#'   }
#'   \item{\code{path_HML}}{
#'     A data frame containing the conditional moderated path coefficients at
#'     the three reference values of the moderator.
#'   }
#'   \item{\code{theta_curve}}{
#'     A data frame containing the conditional indirect effects evaluated over
#'     the moderator grid.
#'   }
#'   \item{\code{path_curve}}{
#'     A data frame containing the conditional path coefficients evaluated over
#'     the moderator grid.
#'   }
#' }
#'
#' @importFrom methods slot
#' @importFrom stats complete.cases model.matrix
#' @importFrom utils head modifyList tail
#'
#' @keywords internal

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

  #conditional_overall <- add_sig(.clean_ci_names(overall_tbl))


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


  beta_out <- if (length(beta_tbl))
    add_sig(.clean_ci_names(do.call(rbind, beta_tbl)))
  else NULL

  path_HML <- if (length(path_HML))
    add_sig(.clean_ci_names(do.call(rbind, path_HML)))
  else NULL

  conditional_overall <- add_sig(.clean_ci_names(overall_tbl))

  mod_coeff <- add_sig(.clean_ci_names(mod_coeff))





  # ---------- 计算 Indirect Effect Contrasts ----------
  IE_contrasts <- NULL
  if (!is.null(beta_out)) {
    IE_contrast_raw <- make_contrasts(beta_out, value_col = "Estimate", contrast_col = "Contrast")

    IE_contrasts <- do.call(rbind, lapply(1:nrow(IE_contrast_raw), function(i) {
      pth <- paths[[which(sapply(paths, \(x) x$path_name == IE_contrast_raw$Path[i]))]]
      lvl_hi <- IE_contrast_raw$Contrast[i] |> strsplit(" - ") |> unlist() |> tail(1)
      lvl_lo <- IE_contrast_raw$Contrast[i] |> strsplit(" - ") |> unlist() |> head(1)

      wc_hi <- W_values[match(lvl_hi, Level_lbl)] - muW
      wc_lo <- W_values[match(lvl_lo, Level_lbl)] - muW

      samp_hi <- Reduce(`*`, lapply(pth$coefs, \(cn){
        base <- th[, cn]
        wcols <- grep(paste0("^", sub("^([abd])", "\\1w", cn), "(_|$)"), colnames(th), value=TRUE)
        wsum <- if (length(wcols)) rowSums(th[, wcols, drop=FALSE]) else 0
        base + wsum * wc_hi
      }))

      samp_lo <- Reduce(`*`, lapply(pth$coefs, \(cn){
        base <- th[, cn]
        wcols <- grep(paste0("^", sub("^([abd])", "\\1w", cn), "(_|$)"), colnames(th), value=TRUE)
        wsum <- if (length(wcols)) rowSums(th[, wcols, drop=FALSE]) else 0
        base + wsum * wc_lo
      }))

      diff_sample <- samp_hi - samp_lo
      cbind(IE_contrast_raw[i, c("Path", "Contrast")],
            t(mc_summary_se(diff_sample, ci_level, digits)))
    }))

    IE_contrasts <- .clean_ci_names(IE_contrasts)
  }

  # ---------- 计算 Path Coefficient Contrasts ----------
  path_contrasts <- NULL
  if (!is.null(path_HML)) {
    path_contrast_raw <- make_contrasts(path_HML, value_col = "Estimate", contrast_col = "Contrast")

    path_contrasts <- do.call(rbind, lapply(1:nrow(path_contrast_raw), function(i) {
      bc <- path_contrast_raw$Path[i]

      lvl_hi <- path_contrast_raw$Contrast[i] |> strsplit(" - ") |> unlist() |> tail(1)
      lvl_lo <- path_contrast_raw$Contrast[i] |> strsplit(" - ") |> unlist() |> head(1)

      wc_hi <- W_values[match(lvl_hi, Level_lbl)] - muW
      wc_lo <- W_values[match(lvl_lo, Level_lbl)] - muW

      wcols <- grep(paste0("^", sub("^([abd])", "\\1w", bc), "(_|$)"), colnames(th), value=TRUE)
      base <- th[, bc]
      wsum <- if (length(wcols)) rowSums(th[, wcols, drop=FALSE]) else 0

      samp_hi <- base + wsum * wc_hi
      samp_lo <- base + wsum * wc_lo
      diff_sample <- samp_hi - samp_lo
      cbind(path_contrast_raw[i, c("Path", "Contrast")],
            t(mc_summary_se(diff_sample, ci_level, digits)))
    }))

    path_contrasts <- .clean_ci_names(path_contrasts)
  }

  IE_contrasts <- if (!is.null(IE_contrasts))
    add_sig(fix_ci_names(.clean_ci_names(IE_contrasts), ci_level))
  else NULL

  path_contrasts <- if (!is.null(path_contrasts))
    add_sig(fix_ci_names(.clean_ci_names(path_contrasts), ci_level))
  else NULL


  list(
    mod_coeff         = mod_coeff,
    beta_coef         = beta_out,
    IE_contrasts        = IE_contrasts,
    path_contrasts      = path_contrasts,
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


#' Make CI column names
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

#' Fix characters mangled by `make.names()`
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
    pattern = "^X?([0-9.]+)(?:%?)?(?:[._]?CI)?[._]?(Lo|Up)?$",
    replacement = "\\1%CI.\\2",
    x = names(df),
    ignore.case = TRUE
  )

  # 找到所有匹配"%CI."结尾且未明确标记Lo/Up的列
  ci_cols <- grep("%CI\\.$", names(df))
  if (length(ci_cols) == 2) {
    names(df)[ci_cols[1]] <- sub("%CI\\.$", "%CI.Lo", names(df)[ci_cols[1]])
    names(df)[ci_cols[2]] <- sub("%CI\\.$", "%CI.Up", names(df)[ci_cols[2]])
  } else if (length(ci_cols) == 1) {
    # 如果只有一个匹配，默认当作Lo
    names(df)[ci_cols] <- sub("%CI\\.$", "%CI.Lo", names(df)[ci_cols])
  }

  df
}


#' make_contrasts
#' @keywords internal
make_contrasts <- function(df, value_col = "Estimate", contrast_col = "Contrast") {
  combs <- combn(unique(df$Level), 2, simplify = FALSE)
  contrast_list <- lapply(combs, function(pair) {
    est_diff <- df[df$Level == pair[2], value_col] - df[df$Level == pair[1], value_col]
    data.frame(
      Path = unique(df$Path),
      Mediators = if ("Mediators" %in% names(df)) unique(df$Mediators) else NA,
      Contrast = paste(pair[2], "-", pair[1]),
      Estimate = est_diff
    )
  })
  do.call(rbind, contrast_list)
}
make_contrasts <- function(df, value_col = "Estimate", contrast_col = "Contrast") {
  combs <- combn(unique(df$Level), 2, simplify = FALSE)
  contrast_list <- lapply(combs, function(pair) {
    est_diff <- df[df$Level == pair[2], value_col] - df[df$Level == pair[1], value_col]
    data.frame(
      Path = unique(df$Path),
      Mediators = if ("Mediators" %in% names(df)) unique(df$Mediators) else NA,
      Contrast = paste(pair[2], "-", pair[1]),
      Estimate = est_diff
    )
  })
  out <- do.call(rbind, contrast_list)

  # 加入排序逻辑
  ord <- c("a", "b", "cp", "indirect_effect")
  out$sort_index <- sapply(out$Path, function(x) {
    idx <- which(startsWith(x, ord))
    if (length(idx)) idx else Inf
  })
  out <- out[order(out$sort_index, out$Path), ]
  out$sort_index <- NULL  # 去掉临时列

  out
}

#' mc_summary_se
#' @keywords internal
#' @noRd
mc_summary_se <- function(x, ci_level, digits) {
  probs <- c((1 - ci_level)/2, (1 + ci_level)/2)
  est <- mean(x)
  se  <- sd(x)
  ci  <- quantile(x, probs = probs)
  out <- c(Estimate = est, SE = se, ci)
  round(out, digits)
}

