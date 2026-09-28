#' Standardize conditional mediation results using existing joint draws
#'
#' @param object A wsMed result with a moderator and stored MC or bootstrap draws.
#' @return A moderation list with the same conditional tables and curves as the
#'   raw output, or a list with mc and boot components for ci_method="both".
#' @details Conditional indirect and total effects are divided by the marginal
#'   model-implied SD of Ydiff. Conditional paths use their endpoint scales.
#'   Moderator probe values remain fixed in raw units; continuous interaction
#'   coefficients in mod_coeff are reported per SD of W. Dummy variables retain
#'   0/1 units. Coefficients and scales are transformed jointly for each draw.
#'   Intervals are percentile intervals, as in the raw conditional tables.
#'   Metadata attributes record scales, probe conventions and draw diagnostics.
#'   With fixed.x=TRUE, external moments are held fixed. MI uses pooled primitive
#'   parameters and the existing first-imputation probing reference. For models
#'   with endogenous products, marginal variances are pooled jointly with
#'   coefficients before taking square roots, retaining their sampling covariance.
#' @export
standardize_moderation <- function(object) {
  if (!inherits(object, "wsMed")) stop("object must be a wsMed result.")
  if (is.null(object$input_vars[["W"]])) stop("A moderator is required.")
  run <- function(engine) {
    is_mc <- engine == "mc"
    fit <- if (is_mc) object$mc$result$args$lav else object$fit_u
    if (is.null(fit)) stop("Required fitted model is unavailable for ", engine, ".")
    draws <- if (is_mc) object$mc$result$thetahatstar else fit@external$sbt_boot_ustd
    if (is.null(draws)) stop("Required sampling draws are unavailable.")
    point <- if (is_mc) object$mc$result$thetahat$est else ThetaHatWrapper(fit)$est
    roles <- .wsmed_roles(object$data)
    # Keeping W in raw units here is algebraically equivalent to evaluating
    # fully standardized coefficients at wc / sW for EACH draw, not at a
    # single plug-in standardized W value.
    moderators <- attr(object$data, "W_info")$dummy_names
    roles$dummy <- union(roles$dummy, moderators)
    fit@external$wsmed_roles <- roles
    z <- .wsmed_std_draws(fit, draws)
    point_std <- StdLav2(point, fit)
    labels <- ThetaHatWrapper(fit)$par_names
    colnames(z$draws) <- names(point_std) <- labels
    mod <- .make_moderation(z$draws, object$data,
             W = object$input_vars[["W"]], MP = .phase2_focal_paths(object, engine),
             W_type = object$input_vars[["W_type"]], alpha = object$alpha,
             point_estimates = point_std)
    if (identical(mod$type, "continuous") && !is.null(mod$mod_coeff)) {
      # Report proper moderation coefficients per SD of W, while conditional
      # effects above continue to be evaluated at fixed raw moderator values.
      w <- moderators[1]
      pt <- lavaan::parameterTable(fit)
      idx <- which(pt$lhs == w & pt$op == "~~" & pt$rhs == w)
      if (length(idx) != 1L) stop("Cannot identify the moderator variance.")
      sw <- sqrt(z$draws[, idx]); sw_point <- sqrt(point_std[idx])
      mod$mod_coeff <- do.call(rbind, lapply(seq_len(nrow(mod$mod_coeff)), function(i) {
        row <- mod$mod_coeff[i, c("Path", "BaseCoef", "W_dummy"), drop = FALSE]
        nm <- row$Path
        summary <- .cat_summarize_vec(z$draws[, nm] * sw, 1 - object$alpha, 8)
        summary$Estimate <- unname(point_std[nm] * sw_point)
        cbind(row, summary)
      }))
      mod$mod_coeff <- .cat_add_sig(mod$mod_coeff)
    }
    attr(mod, "standardization") <- list(
      effect_scale = "marginal model-implied endpoint scales; IE / SD(Ydiff)",
      moderator_units = "raw; fixed numerical probes; dummy coding unchanged",
      mod_coeff_units = "per SD of continuous W; per 0/1 dummy contrast",
      interval = "percentile", engine = engine,
      fixed.x = lavaan::lavInspect(fit, "options")$fixed.x,
      MI_reference = if (identical(object$Na, "MI")) "first completed dataset" else NULL,
      diagnostics = z$diagnostics)
    mod
  }
  switch(object$ci_method, mc = run("mc"), bootstrap = run("boot"),
         both = list(mc = run("mc"), boot = run("boot")))
}

.phase2_focal_paths <- function(object, engine) {
  # New objects store MP explicitly. Older results can recover displayed paths.
  if (!is.null(object$input_vars$MP)) return(object$input_vars$MP)
  mod <- if (identical(object$ci_method, "both")) object$moderation[[engine]] else object$moderation
  paths <- if (identical(mod$type, "continuous")) mod$path_HML$Path else mod$extra$path_levels$Path
  unique(paths)
}
