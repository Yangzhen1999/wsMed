# Role metadata for the existing standardized parameter tables.
.wsmed_roles <- function(data) {
  maps <- c(attr(data, "W_info")$dummy_map, attr(data, "C_info")$dummy_map)
  dummy <- names(maps)[vapply(maps, function(x) !identical(x, "continuous"), logical(1))]
  products <- grep("^int_M[0-9]+(diff|avg)_W[0-9]+$", names(data), value = TRUE)
  components <- lapply(products, function(x) strsplit(sub("^int_", "", x), "_")[[1]])
  list(dummy = dummy, products = stats::setNames(components, products))
}

# Transform joint parameter draws, retaining covariance with scale estimates.
.wsmed_std_draws <- function(fit, draws) {
  pt <- lavaan::parameterTable(fit)
  point <- StdLav2(lavaan::coef(fit), fit)
  free_rows <- match(seq_len(fit@Model@nx.free), pt$free)
  if (ncol(draws) == nrow(pt)) draws <- draws[, free_rows, drop = FALSE]
  if (ncol(draws) != fit@Model@nx.free) stop("Incorrect standardized draw dimensions.")
  moments <- fit@external$wsmed_mi_marginal
  if (!is.null(moments) && (is.null(moments$draws) || nrow(moments$draws) != nrow(draws)))
    stop("Joint MI marginal-variance draws are unavailable; rerun inference.")
  reasons <- rep(NA_character_, nrow(draws))
  transformed <- t(vapply(seq_len(nrow(draws)), function(i) {
    tryCatch({
      z <- StdLav2(draws[i, ], fit,
        marginal_variances = if (is.null(moments)) NULL else
          stats::setNames(moments$draws[i, ], colnames(moments$draws)))
      if (any(!is.finite(z))) stop("Non-finite standardized parameter.")
      z
    }, error = function(e) {
      reasons[i] <<- conditionMessage(e)
      rep(NA_real_, length(point))
    })
  }, numeric(length(point))))
  valid <- apply(transformed, 1, function(x) all(is.finite(x)))
  if (any(!valid)) warning(sum(!valid), " of ", length(valid),
                           " standardized draws were invalid; see diagnostics.")
  if (sum(valid) < 2L) stop("Fewer than two valid standardized draws.")
  list(point = point, draws = transformed[valid, , drop = FALSE],
       diagnostics = list(requested = length(valid), valid = sum(valid),
                          invalid = sum(!valid), invalid_indices = which(!valid),
                          reasons = table(reasons, useNA = "no")))
}

.wsmed_std_boot <- function(fit, alpha, boot_ci_type) {
  z <- .wsmed_std_draws(fit, fit@external$sbt_boot_ustd)
  out <- lavaan::parameterTable(fit)[, c("lhs", "op", "rhs", "label")]
  out$est.std <- z$point
  out$boot.se <- apply(z$draws, 2, stats::sd)
  intervals <- vapply(seq_along(z$point), function(j) {
    x <- z$draws[, j]
    probs <- c(alpha / 2, 1 - alpha / 2)
    if (boot_ci_type != "perc" && length(unique(x)) > 1L) {
      # bca.simple: bias correction without acceleration.
      p <- mean(x < z$point[j])
      p <- min(max(p, 0.5 / length(x)), 1 - 0.5 / length(x))
      probs <- stats::pnorm(2 * stats::qnorm(p) + stats::qnorm(probs))
    }
    stats::quantile(x, probs, names = FALSE)
  }, numeric(2))
  out$boot.ci.lower <- intervals[1, ]
  out$boot.ci.upper <- intervals[2, ]
  # Invert the same percentile/bias-corrected distribution at zero.
  out$boot.p <- vapply(seq_along(z$point), function(j) {
    x <- z$draws[, j]
    if (length(x) < 1000L || length(unique(x)) == 1L) return(NA_real_)
    p <- mean(x <= 0)
    if (boot_ci_type != "perc") {
      bias <- min(max(mean(x < z$point[j]), .5 / length(x)), 1 - .5 / length(x))
      p <- stats::pnorm(stats::qnorm(p) - 2 * stats::qnorm(bias))
    }
    min(1, 2 * min(p, 1 - p))
  }, numeric(1))
  attr(out, "boot_est_std") <- z$draws
  attr(out, "standardization_diagnostics") <- z$diagnostics
  attr(out, "ci_method") <- paste(boot_ci_type, "type-7 quantiles; bca.simple has zero acceleration")
  out
}

# Row one is the plug-in point; remaining rows are sampling draws.
# All path products and contrasts thereby share exactly the same algebra.
.mm_evaluation_rows <- function(draws, point_estimates = NULL) {
  if (is.list(draws) && !is.data.frame(draws)) {
    if (is.null(point_estimates)) point_estimates <- draws$thetahat$est
    draws <- draws$thetahatstar
  }
  draws <- as.matrix(draws)
  if (is.null(point_estimates)) point_estimates <- colMeans(draws)
  if (!is.null(names(point_estimates))) point_estimates <- point_estimates[colnames(draws)]
  if (length(point_estimates) != ncol(draws) || any(!is.finite(point_estimates)))
    stop("Missing or invalid plug-in parameter estimates.")
  rbind(point_estimates, draws)
}
