# Complete legacy output, available through print(x, detail = "full").
.print_wsmed_full <- function(x, digits = 3, ...){


  if (!inherits(x, "wsMed"))
    stop("Not a wsMed object.")

  # Variable information
  .print_variables(x)

  # Model fit
  .print_fit(x$mc$fit)

  # Total, direct, total indirect, and specific indirect effects
  if (!is.null(x$mc$result))
    .print_mc_totals(x$mc$result, x$alpha, digits)


  if (!is.null(x$param_boot)) {
    .print_boot_totals(x$param_boot, x$alpha, digits)
  }

  # Indirect-effect key
  .print_indirect_key(x)

  # Monte Carlo total, direct, and indirect effects

  .print_mc_d_moderation(x$mc$result, x$alpha, digits)
  if (!is.null(x$param_boot))
    .print_boot_d_moderation(x$param_boot, x$alpha, digits)

  .print_d_key(x$data, x$mc$result)
  if (!is.null(x$param_boot))
    .print_d_key(x$data, x$mc$result, x$param_boot)

  mods <- if (identical(x$ci_method, "both")) x$moderation else
    stats::setNames(list(x$moderation), x$ci_method)
  for (engine in names(mods)) {
    mod <- mods[[engine]]
    cat("\nUNSTANDARDIZED CONDITIONAL EFFECTS (", engine, ")\n", sep = "")
    cat("Percentile intervals; moderator probes and centering references are held fixed.\n")
  # Moderation results
  ## ---------- (1) basic contrasts ----------
  if (isTRUE(mod$type == "none")) {
    if (!is.null(mod$IE_contrasts)) {
      cat("\n")
      cat("\n*************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************\n")
      tbl <- mod$IE_contrasts        # Extract the original contrast table
      names(tbl) <- clean_ci_names(names(tbl))
      if ("Contrast" %in% names(tbl))         # Align only the Contrast column
        tbl$Contrast <- align_minus(tbl$Contrast)
      .print_tbl(tbl, digits)
    }

    if (!is.null(mod$Xcoef)) {
      cat("\n")
      cat("\n*************** C1-C2 COEFFICIENTS (No Moderator) ***************\n")
      .print_tbl(mod$Xcoef, digits)
    }

  }


  if (!is.null(mod$type)) {
    if (mod$type == "categorical") {
      .print_moderation_categorical(mod, digits)
    } else if (mod$type == "continuous") {
      .print_moderation_continuous(mod, digits)
    }
  }


  }

  if (!is.null(x$moderation_std)) {
    stdmods <- if (identical(x$ci_method, "both")) x$moderation_std else
      stats::setNames(list(x$moderation_std), x$ci_method)
    for (engine in names(stdmods)) {
      mod <- stdmods[[engine]]
      cat("\nSTANDARDIZED CONDITIONAL EFFECTS (", engine, ")\n", sep = "")
      cat("Marginal endpoint scales; fixed raw W probes; percentile intervals.\n")
      cat("Moderation coefficients: per SD of continuous W; categorical contrasts keep 0/1 units.\n")
      if (isTRUE(attr(mod, "standardization")$fixed.x))
        cat("External moments held fixed (fixed.x=TRUE).\n")
      if (identical(mod$type, "continuous")) .print_moderation_continuous(mod, digits)
      if (identical(mod$type, "categorical")) .print_moderation_categorical(mod, digits)
    }
  }

  # Regressions, variances, and intercepts
  .print_mc_RIV(x$mc$result, x$mc$fit, x$alpha, digits)
  if (!is.null(x$param_boot)) {
    .print_boot_RIV   (x$param_boot, x$alpha, digits)
  }

  # Standardized results, when available
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
