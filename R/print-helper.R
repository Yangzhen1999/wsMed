# helper-print.R -------------------------------------------------------------
# Internal utilities for formatted printing of wsMed objects
# All helpers are **internal** (not exported).  They are shared by
#   * print.wsMed()
#   * summary / plot methods (future)
#   * unit tests
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# 1. Generic numeric / table utilities ------------------------------------
# -------------------------------------------------------------------------

#' Format a numeric vector with fixed width / digits
#' @keywords internal
.fmt_num <- function(x, digits, width = NULL) {
  if (is.null(width)) width <- if (digits <= 4) 10 else 12
  formatC(x, format = "f", digits = digits, width = width, flag = " ")
}

#' Nicely print a data.frame via knitr::kable
#' @keywords internal
.print_tbl <- function(df, digits = 3, right_align = NULL) {
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], formatC, digits = digits, format = "f")

  align <- ifelse(num, "r", "l")
  if (!is.null(right_align)) {
    idx <- match(right_align, names(df), nomatch = 0L)
    align[idx[idx > 0]] <- "r"
  }
  print(knitr::kable(df, align = align, row.names = FALSE))
}

#' Build a tiny parameter table (estimate / SE / CI) from MC draws
#' @keywords internal
.mc_param_table <- function(mc, alpha) {
  est <- mc$thetahat$est
  se  <- apply(mc$thetahatstar, 2, stats::sd)
  pr  <- c(alpha / 2, 1 - alpha / 2)
  ci  <- t(apply(mc$thetahatstar, 2, stats::quantile, probs = pr))
  colnames(ci) <- sprintf("%.1f%%CI.%s", pr * 100, c("Lo", "Up"))
  data.frame(name = names(est), Estimate = est, SE = se, ci,
             row.names = NULL, check.names = FALSE)
}

# -------------------------------------------------------------------------
# 2. VARIABLE & MODEL‑FIT blocks ------------------------------------------
# -------------------------------------------------------------------------

#' Print variable names / sample size
#' @keywords internal
.print_variables <- function(obj) {
  iv <- obj$input_vars; if (is.null(iv)) return()
  cat("\n\n*************** VARIABLES ***************\n")
  cat("Original Variables:\n")

  # Outcome ---------------------------------------------------------------
  cat("  Outcome (Y):\n",
      "    Condition 1:", iv$Y_C1, "\n",
      "    Condition 2:", iv$Y_C2, "\n")

  # Mediators -------------------------------------------------------------
  cat("  Mediators (M):\n")
  for (i in seq_along(iv$M_C1)) {
    cat(sprintf("    M%d:\n      Condition 1: %s\n      Condition 2: %s\n",
                i, iv$M_C1[i], iv$M_C2[i]))
  }

  # Between‑subject covariates -------------------------------------------
  cinfo <- attr(obj$data, "C_info")
  if (!is.null(cinfo) && length(cinfo$raw)) {
    cat("  Between-subject Covariates:\n")
    for (i in seq_along(cinfo$raw))
      cat("    ", cinfo$dummy_names[i], ":", cinfo$raw[i], "\n")
  }

  # Within‑subject covariates --------------------------------------------
  if (!is.null(iv$C_C1)) {
    cat("  Within-subject Covariates:\n")
    for (i in seq_along(iv$C_C1)) {
      cat(sprintf("    Cw%d:\n      Condition 1: %s\n      Condition 2: %s\n",
                  i, iv$C_C1[i], iv$C_C2[i]))
    }
  }

  # Moderators ------------------------------------------------------------
  winfo <- attr(obj$data, "W_info")
  if (!is.null(winfo) && length(winfo$raw)) {
    cat("  Moderators (W):\n")
    for (i in seq_along(winfo$raw))
      cat("    ", winfo$dummy_names[i], ":", winfo$raw[i], "\n")
  }

  cat("Sample size (rows kept):", nrow(obj$data), "\n")
}

#' Print lavaan fit measures
#' @keywords internal
.print_fit <- function(fit) {
  if (is.null(fit)) return()
  fm <- lavaan::fitMeasures(fit,
                            c("chisq","df","pvalue","cfi","tli",
                              "rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
  tbl <- data.frame(
    Measure = c("Chi‑Sq","df","p","CFI","TLI",
                "RMSEA","RMSEA Low","RMSEA Up","SRMR"),
    Value   = unname(fm)
  )
  cat("\n\n*************** MODEL FIT ***************\n")
  .print_tbl(tbl, digits = 3)
}

# -------------------------------------------------------------------------
# 3. Lavaan coef‑name helper ----------------------------------------------
# -------------------------------------------------------------------------

#' Map lavaan lhs/rhs to wsMed coefficient label
#' @keywords internal
.lav2coef <- function(lhs, rhs) {
  if (lhs == "Ydiff") {
    if (grepl("^M(\\d+)diff$", rhs))
      return(paste0("b", sub("^M(\\d+)diff$", "\\1", rhs)))
    if (grepl("^M(\\d+)avg$",  rhs))
      return(paste0("d", sub("^M(\\d+)avg$",  "\\1", rhs)))
    if (grepl("^int_M(\\d+)diff_", rhs))
      return(sub("^int_", "bw", rhs))
    if (grepl("^int_M(\\d+)avg_",  rhs))
      return(sub("^int_", "dw", rhs))
  }
  if (grepl("^M(\\d+)diff$", lhs) && grepl("^W\\d+$", rhs)) {
    idx <- sub("^M(\\d+)diff$", "\\1", lhs)
    return(paste0("aw", idx, "_", rhs))
  }
  NA_character_
}

# -------------------------------------------------------------------------
# 4. Regression / Intercept / Variance tables from MC ---------------------
# -------------------------------------------------------------------------

#' Print MC-based regression / intercept / variance tables
#' @keywords internal
.print_mc_RIV <- function(mc, fit, alpha, digits = 3, title = "MC") {
  if (is.null(mc) || is.null(fit)) return()
  tbl  <- .mc_param_table(mc, alpha)
  lav  <- lavaan::parameterEstimates(fit, ci = FALSE)

  simple_key <- function(row) {
    switch(row$op,
           "~"  = paste0(row$lhs, "~", row$rhs),
           "~1" = paste0(row$lhs, "~1"),
           "~~" = paste0(row$lhs, "~~", row$rhs))
  }

  lav$coef_key <- mapply(function(lbl, lhs, op, rhs) {
    if (!is.na(lbl) && lbl != "" && lbl %in% tbl$name) return(lbl)
    key2 <- .lav2coef(lhs, rhs)
    if (!is.na(key2) && key2 %in% tbl$name) return(key2)
    simple_key(list(lhs = lhs, rhs = rhs, op = op))
  }, lav$label, lav$lhs, lav$op, lav$rhs, USE.NAMES = FALSE)

  safe_merge <- function(df, header) {
    df$Label <- lav$label[match(df$coef_key, lav$coef_key)]
    m <- merge(df, tbl, by.x = "coef_key", by.y = "name",
               all.x = TRUE, sort = FALSE)
    m[] <- lapply(m, function(z) if (is.factor(z)) as.character(z) else z)
    ci <- grep("%CI", names(tbl), value = TRUE)
    cols <- switch(header,
                   Path      = c("Path", "Label", "Estimate", "SE", ci),
                   Intercept = c("Intercept", "Label", "Estimate", "SE", ci),
                   Variance  = c("Variance", "Label", "Estimate", "SE", ci))
    m[, cols, drop = FALSE]
  }

  # Regression paths ------------------------------------------------------
  reg <- lav[lav$op == "~", ]
  if (nrow(reg)) {
    reg$Path <- paste(reg$lhs, "~", reg$rhs)
    cat("\n\n*************** REGRESSION PATHS (", title, ") ***************\n")
    .print_tbl(safe_merge(reg, "Path"), digits)
  }

  # Intercepts ------------------------------------------------------------
  int <- lav[lav$op == "~1", ]
  if (nrow(int)) {
    int$Intercept <- paste0(int$lhs, "~1")
    cat("\n\n*************** INTERCEPTS (", title, ") ***************\n")
    .print_tbl(safe_merge(int, "Intercept"), digits)
  }

  # Variances -------------------------------------------------------------
  var <- lav[lav$op == "~~" & lav$lhs == lav$rhs, ]
  if (nrow(var)) {
    var$Variance <- paste0(var$lhs, "~~", var$rhs)
    cat("\n\n*************** VARIANCES (", title, ") ***************\n")
    .print_tbl(safe_merge(var, "Variance"), digits)
  }
}

# -------------------------------------------------------------------------
# 5. MC totals / contrasts & misc helpers ----------------------------------
# -------------------------------------------------------------------------

#' Print total / direct / total indirect + individual indirects
#' @keywords internal
.print_mc_totals <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return()
  tbl <- .mc_param_table(mc, alpha)

  tot_names <- c("total_effect", "cp", "total_indirect")
  tag       <- c("Total effect", "Direct effect", "Total indirect")
  idx       <- match(tot_names, tbl$name, nomatch = 0)
  base      <- tbl[idx[idx > 0], ]
  base$Label <- tag[idx > 0]

  cat("\n\n************* TOTAL / DIRECT / TOTAL‑IND (", title, ") *************\n")
  .print_tbl(base[, c("Label", "Estimate", "SE", grep("%CI", names(base), value = TRUE))], digits)

  ind_idx <- grep("^indirect", tbl$name)
  if (length(ind_idx)) {
    ind <- tbl[ind_idx, ]
    ind$Label <- sub("^indirect_", "ind_", ind$name)
    cat("\nIndirect effects:\n")
    .print_tbl(ind[, c("Label", "Estimate", "SE", grep("%CI", names(ind), value = TRUE))], digits)
  }
}

# -------------------------------------------------------------------------
# 6. Moderation effect printers -------------------------------------------
# -------------------------------------------------------------------------

#' Print moderation coefficients of X (aw/bw/dw/cpw...)
#' @keywords internal
.print_mc_moderation <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return()
  tbl <- .mc_param_table(mc, alpha)
  mod_idx <- grep("^(aw|bw|dw|cpw)", tbl$name)
  if (!length(mod_idx)) return()

  df <- tbl[mod_idx, ]
  df$Term <- df$name
  df <- df[, c("Term", "Estimate", "SE", grep("%CI", names(df), value = TRUE))]

  # Order cpw -> aw -> bw -> dw
  ord <- order(gsub("^(cpw).*", "0_\\1",
                    gsub("^(aw).*",  "1_\\1",
                         gsub("^(bw).*", "2_\\1",
                              gsub("^(dw).*", "3_\\1", df$Term)))))
  df <- df[ord, ]
  cat("\n\n*************** MODERATION EFFECTS of X (", title, ") ***************\n")
  .print_tbl(df, digits)
}

#' Print a table mapping aw/bw/dw to paths (for continuous moderator)
#' @keywords internal
.print_moderation_key <- function(prep) {
  info <- attr(prep, "W_info")
  if (is.null(info) || !length(info$dummy_names)) return()

  mavg <- grep("^M\\d+avg$",  names(prep), value = TRUE)
  mdif <- grep("^M\\d+diff$", names(prep), value = TRUE)

  rows <- list()
  for (i in seq_along(mdif)) {
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("aw", i),
                                           Path = paste0("X → ", mdif[i]),
                                           Moderated = paste0("X → ", mdif[i]))
  }
  for (i in seq_along(mdif)) {
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("bw", i),
                                           Path = paste0(mdif[i], " → Ydiff"),
                                           Moderated = paste0(mdif[i], " → Ydiff"))
  }
  for (i in seq_along(mavg)) {
    rows[[length(rows) + 1]] <- data.frame(Coefficient = paste0("dw", i),
                                           Path = paste0(mavg[i], " → Ydiff"),
                                           Moderated = paste0(mavg[i], " → Ydiff"))
  }
  key <- do.call(rbind, rows)
  if (nrow(key)) {
    cat("\n\n*************** MODERATION KEY ***************\n")
    print(knitr::kable(key, align = "l", row.names = FALSE))
  }
}

#' Print moderation effects for d‑paths (X moderating Mavg→...)
#' @keywords internal
.print_mc_d_moderation <- function(mc, alpha, digits = 3, title = "MC") {
  if (is.null(mc)) return()
  tbl <- .mc_param_table(mc, alpha)
  d_idx <- grep("^d(\\d+|_\\d+)+$", tbl$name)
  if (!length(d_idx)) return()

  out <- tbl[d_idx, c("name", "Estimate", "SE", grep("%CI", names(tbl), value = TRUE))]
  names(out)[1] <- "Coefficient"
  cat("\n\n*************** MODERATION EFFECTS of X (d‑paths, ", title, ") ***************\n")
  .print_tbl(out, digits)
}

#' Print key for d‑path moderation
#' @keywords internal
.print_d_key <- function(prep, mc) {
  if (is.null(prep) || is.null(mc)) return()
  have <- names(mc$thetahat$est)
  mdiff <- grep("^M\\d+diff$", names(prep), value = TRUE)
  mavg  <- grep("^M\\d+avg$",  names(prep), value = TRUE)
  rows  <- list()

  add_row <- function(cff, path, mod)
    rows[[length(rows) + 1]] <<- data.frame(Coefficient = cff, Path = path, Moderated = mod)

  for (i in seq_along(mavg)) {
    coef <- paste0("d", i)
    if (coef %in% have)
      add_row(coef, paste0(mavg[i], " → Ydiff"), paste0(mdiff[i], " → Ydiff"))
  }
  for (i in seq_along(mavg))
    for (j in seq_along(mdiff))
      if (i != j) {
        coef <- paste0("d_", i, "_", j)
        if (coef %in% have)
          add_row(coef,
                  paste0(mavg[i], " → ", mdiff[j]),
                  paste0(mdiff[i], " → ", mdiff[j]))
      }
  if (length(rows)) {
    key <- do.call(rbind, rows)
    cat("\n\n*************** MODERATION KEY (d‑paths) ***************\n")
    print(knitr::kable(key, align = "l", row.names = FALSE))
  }
}

