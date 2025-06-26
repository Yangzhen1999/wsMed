#' @title Compute Conditional Effects of Moderated Paths from Monte Carlo Results
#'
#' @description
#' Extracts conditional effects for moderated path coefficients from a Monte Carlo simulation result
#' (typically produced by `semmcci::MC()` or `semmcci::MCMI()`). Supports both user-defined discrete values
#' and quantile-based moderator values. Optionally includes Johnson-Neyman intervals to identify the regions
#' where moderated effects are statistically significant.
#'
#' @details
#' This function identifies moderated parameters in a structural equation model (e.g., `"aw1_1"`, `"bw2_1"`,
#' `"cpw1_1"`, `"dw_1_2_1"`) and evaluates the conditional effect of each path at different levels of the moderator variable.
#'
#' Conditional effects are computed by combining the unmoderated (main) and moderated (interaction) coefficients via:
#' \deqn{ \theta(W) = \theta + \theta_{int} \cdot W }
#' where \eqn{\theta} is the main path coefficient, \eqn{\theta_{int}} is the interaction coefficient (e.g., `"bw2_1"`),
#' and \eqn{W} is the moderator value.
#'
#' The function supports two approaches for choosing moderator values:
#' \itemize{
#'   \item \code{"discrete"}: Use manually specified values (e.g., -2, -1, 0, 1, 2).
#'   \item \code{"quantile"}: Automatically compute empirical quantiles (e.g., 5%, 25%, 50%, 75%, 95%) of the moderator from data.
#' }
#'
#' If \code{JN = TRUE}, the function also estimates Johnson-Neyman significance regions for each moderated path,
#' reporting the range of moderator values where the conditional effect is significantly different from zero.
#'
#' @param mc_result A `semmcci` object returned from `MC()` or `MCMI()`, containing Monte Carlo draws of model parameters.
#' @param W_method Character string. Method for specifying moderator values:
#'   \code{"discrete"} (default) or \code{"quantile"}.
#' @param W_values Numeric vector. Moderator values at which to compute conditional effects.
#'   Used only when \code{W_method = "discrete"}.
#' @param W_varname Character. Name of the moderator variable. Required for quantile-based extraction and JN plots.
#' @param data Optional data frame. Required if \code{W_method = "quantile"} or \code{JN = TRUE}.
#' @param ci_level Numeric. Confidence level for Monte Carlo confidence intervals. Default is 0.95.
#' @param digits Integer. Number of decimal places to round estimates. Default is 3.
#' @param JN Logical. Whether to compute Johnson-Neyman significance regions. Default is \code{FALSE}.
#' @param W_range Numeric vector of length 2. Range of moderator values to search for JN intervals. Default is \code{c(-3, 3)}.
#' @param resolution Integer. Number of equally spaced points within \code{W_range} to evaluate conditional effects for JN analysis. Default is 1000.
#' @param alpha Numeric. Significance level used in JN region computation. Default is 0.05.
#' @param verbose Logical. If \code{TRUE}, prints diagnostic messages. Default is \code{TRUE}.
#'
#' @return If \code{JN = FALSE}, returns a data frame with conditional estimates at each moderator level, with columns:
#' \itemize{
#'   \item \code{Moderator}: Name of the moderator variable.
#'   \item \code{Coefficient}: Name of the moderated parameter (e.g., "bw2_1").
#'   \item \code{Path}: Base path name (e.g., "b2").
#'   \item \code{Level}: Label for the moderator value (e.g., "-1", "50%", etc.).
#'   \item \code{W}: Numeric moderator value.
#'   \item \code{Estimate}: Estimated conditional effect.
#'   \item \code{SE}: Standard error of the conditional effect.
#'   \item \code{CI.Lower}: Lower bound of the confidence interval.
#'   \item \code{CI.Upper}: Upper bound of the confidence interval.
#' }
#'
#' If \code{JN = TRUE}, returns a list with two elements:
#' \itemize{
#'   \item \code{main}: The conditional effects table (same as above).
#'   \item \code{JN}: A data frame summarizing the Johnson-Neyman significance region for each moderated parameter.
#' }
#'
#' @seealso [get_jn_results()] for standalone JN region extraction.
#'
#' @export


get_all_moderated_effects <- function(mc_result,
                                      W_method = c("discrete", "quantile"),
                                      W_values = c(-2, -1, 0, 1, 2),
                                      W_varname = "W1",
                                      data = NULL,
                                      ci_level = 0.95,
                                      digits = 3,
                                      JN = FALSE,
                                      W_range = NULL,
                                      resolution = 1000,
                                      alpha = 0.05,
                                      verbose = TRUE,
                                      return_empty_table = TRUE) {
  W_method <- match.arg(W_method)

  if (!inherits(mc_result, "semmcci")) {
    stop("Input must be a 'semmcci' object.")
  }

  all_names <- names(mc_result$thetahat$est)
  pattern <- "^(cpw|aw\\d+|bw\\d+|dw\\d+|bw_\\d+(?:_\\d+)*|dw_\\d+(?:_\\d+)*)$"
  mod_names <- grep(pattern, all_names, value = TRUE)

  if (length(mod_names) == 0) {
    if (verbose) message("⚠️ No moderated effects matched.")
    if (return_empty_table) {
      return(data.frame(
        Moderator = character(),
        Coefficient = character(),
        Path = character(),
        Level = character(),
        W = numeric(),
        Estimate = numeric(),
        SE = numeric(),
        CI.Lower = numeric(),
        CI.Upper = numeric(),
        stringsAsFactors = FALSE
      ))
    } else {
      return(NULL)
    }
  }

  # 自动推断 W_range
  if (is.null(W_range)) {
    if (!is.null(data) && W_varname %in% names(data)) {
      W_range <- quantile(data[[W_varname]], probs = c(0.025, 0.975), na.rm = TRUE)
      message("✔ Auto W_range = [", round(W_range[1], 2), ", ", round(W_range[2], 2),
              "] based on 95% quantile of ", W_varname, ".")
    } else {
      W_range <- c(-2, 2)
      warning("⚠ Could not detect W_range from data. Defaulting to [-2, 2].")
    }
  }

  # W values for conditional effect
  if (W_method == "quantile") {
    if (is.null(data)) stop("Raw data is required when W_method = 'quantile'.")
    if (!(W_varname %in% names(data))) stop(paste0("'", W_varname, "' not found in data."))
    W_values <- quantile(data[[W_varname]], probs = c(0.05, 0.25, 0.5, 0.75, 0.95), na.rm = TRUE)
    W_levels <- names(W_values)
  } else {
    W_levels <- paste0(W_values, " SD")
  }

  extract_main_path <- function(mod) {
    if (grepl("^cpw", mod)) return("cp")
    if (grepl("^aw\\d+$", mod)) return(paste0("a", sub("^aw(\\d+)$", "\\1", mod)))
    if (grepl("^bw\\d+$", mod)) return(paste0("b", sub("^bw(\\d+)$", "\\1", mod)))
    if (grepl("^dw\\d+$", mod)) return(paste0("d", sub("^dw(\\d+)$", "\\1", mod)))
    if (grepl("^bw_\\d+(?:_\\d+)*$", mod)) return(sub("^bw_", "b_", mod))
    if (grepl("^dw_\\d+(?:_\\d+)*$", mod)) return(sub("^dw_", "d_", mod))
    return(NA)
  }

  extract_moderator <- function(mod) {
    return(W_varname)
  }

  get_main_coef_name <- function(mod) extract_main_path(mod)
  theta_star <- mc_result$thetahatstar

  result_list <- lapply(mod_names, function(mod) {
    base_path <- extract_main_path(mod)
    main_coef <- get_main_coef_name(mod)
    moderator_var <- extract_moderator(mod)

    if (is.na(main_coef) || !(main_coef %in% colnames(theta_star)) || !(mod %in% colnames(theta_star))) {
      return(NULL)
    }

    beta_main <- theta_star[, main_coef]
    beta_int  <- theta_star[, mod]

    rows <- lapply(seq_along(W_values), function(i) {
      w <- W_values[i]
      eff_dist <- beta_main + beta_int * w
      probs <- c((1 - ci_level) / 2, 1 - (1 - ci_level) / 2)
      ci_vals <- quantile(eff_dist, probs = probs, na.rm = TRUE)

      data.frame(
        Moderator = W_varname,
        Coefficient = mod,
        Path = base_path,
        Level = W_levels[i],
        W = round(w, digits),
        Estimate = round(mean(eff_dist, na.rm = TRUE), digits),
        SE = round(sd(eff_dist, na.rm = TRUE), digits),
        CI.Lower = round(ci_vals[1], digits),
        CI.Upper = round(ci_vals[2], digits),
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, rows)
  })

  main_tbl <- do.call(rbind, result_list)
  rownames(main_tbl) <- NULL

  if (JN) {
    stars <- theta_star
    w_seq <- seq(W_range[1], W_range[2], length.out = resolution)
    probs <- c(alpha / 2, 1 - alpha / 2)

    jn_list <- lapply(mod_names, function(mod) {
      main_coef <- get_main_coef_name(mod)
      moderator_var <- extract_moderator(mod)

      if (!(mod %in% colnames(stars)) || !(main_coef %in% colnames(stars))) return(NULL)

      beta_main <- stars[, main_coef]
      beta_int  <- stars[, mod]

      cond_dists <- sapply(w_seq, function(w) beta_main + beta_int * w)
      sig_vec <- apply(cond_dists, 2, function(x) {
        ci <- quantile(x, probs = probs, na.rm = TRUE)
        !(ci[1] < 0 & ci[2] > 0)
      })

      rle_obj <- rle(sig_vec)
      min_run_length <- ceiling(length(w_seq) * 0.05)

      if (!any(rle_obj$values)) {
        lower <- upper <- NA
      } else {
        longest_sig <- which.max(ifelse(rle_obj$values, rle_obj$lengths, 0))
        if (rle_obj$lengths[longest_sig] < min_run_length) {
          lower <- upper <- NA
        } else {
          starts <- cumsum(c(1, head(rle_obj$lengths, -1)))
          idx_start <- starts[longest_sig]
          idx_end <- idx_start + rle_obj$lengths[longest_sig] - 1
          lower <- w_seq[idx_start]
          upper <- w_seq[idx_end]
        }
      }

      if (!is.null(data) && W_varname %in% names(data)) {
        wvec <- data[[W_varname]]
        lower_pct <- if (!is.na(lower)) ecdf(wvec)(lower) * 100 else NA
        upper_pct <- if (!is.na(upper)) ecdf(wvec)(upper) * 100 else NA
      } else {
        lower_pct <- upper_pct <- NA
      }

      data.frame(
        Moderator = moderator_var,
        Coefficient = mod,
        Path = main_coef,
        JN_Lower = round(lower, 3),
        JN_Upper = round(upper, 3),
        JN_Lower_pct = if (!is.na(lower_pct)) paste0(round(lower_pct, 1), "%") else NA,
        JN_Upper_pct = if (!is.na(upper_pct)) paste0(round(upper_pct, 1), "%") else NA,
        stringsAsFactors = FALSE
      )
    })

    jn_tbl <- do.call(rbind, jn_list)
    rownames(jn_tbl) <- NULL
    return(invisible(list(main = main_tbl, JN = jn_tbl)))
  }

  return(main_tbl)
}

