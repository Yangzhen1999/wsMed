#' @title Compute Conditional Indirect Effects at Different Levels of a Moderator
#'
#' @description
#' This function computes conditional indirect effects at different values of a moderator variable,
#' based on Monte Carlo simulation results from a `semmcci` object. The conditional estimates are
#' obtained by grouping samples according to moderator values and summarizing the corresponding
#' simulated indirect effect distributions.
#'
#' @details
#' The function extracts predefined indirect effects (e.g., `"indirect_1"`, `"indirect_1_2"`) from
#' the Monte Carlo sample and evaluates how these effects change across different levels of a moderator.
#'
#' Moderator values can be specified either manually (standard deviation units) or automatically using empirical quantiles:
#' \itemize{
#'   \item \code{"discrete"}: Moderator values are computed as \code{mean ± SD × value}, where values default to \code{-2, -1, 0, 1, 2}.
#'   \item \code{"quantile"}: Moderator values are based on empirical quantiles (default: 5%, 25%, 50%, 75%, 95%) from the raw data.
#' }
#'
#' For each moderator level, this function:
#' \itemize{
#'   \item Groups individuals based on proximity to the target moderator value.
#'   \item Extracts the corresponding Monte Carlo draws of each indirect effect.
#'   \item Computes the mean, standard deviation, and Monte Carlo confidence intervals.
#' }
#'
#' @param mc_result A `semmcci` object returned by `MC()` or `MCMI()`, containing simulated indirect effect distributions.
#' @param data A data frame containing the moderator variable.
#' @param W_varname Character. Name of the moderator variable in `data`.
#' @param W_method Character. Either \code{"quantile"} (default) or \code{"discrete"}, determines how moderator values are defined.
#' @param W_values Numeric vector. Optional. If \code{W_method = "quantile"}, interpreted as quantile probabilities (e.g., \code{c(0.25, 0.5, 0.75)}).
#'        If \code{"discrete"}, interpreted as standard deviation units (e.g., \code{c(-1, 0, 1)}). Defaults: \code{c(0.05, 0.25, 0.5, 0.75, 0.95)} or \code{c(-2, -1, 0, 1, 2)}.
#' @param ci_level Numeric. Confidence level for Monte Carlo intervals. Default is 0.95.
#' @param digits Integer. Number of decimal places to round results. Default is 3.
#'
#' @return A data frame with the conditional indirect effect estimates, with columns:
#' \itemize{
#'   \item \code{Path}: Name of the indirect effect (e.g., \code{"indirect_1"}).
#'   \item \code{W}: Numeric value of the moderator used to define the group.
#'   \item \code{level}: Label for the moderator level (e.g., \code{"50%"} or \code{"0 SD"}).
#'   \item \code{Estimate}: Estimated conditional indirect effect.
#'   \item \code{SE}: Standard deviation across Monte Carlo samples (proxy for standard error).
#'   \item \code{CI.Lower}: Lower bound of the Monte Carlo confidence interval.
#'   \item \code{CI.Upper}: Upper bound of the Monte Carlo confidence interval.
#' }
#'
#' @seealso [get_all_moderated_effects()] for conditional estimates of moderated paths.
#'
#' @export

get_conditional_indirect_effects <- function(mc_result,
                                             data,
                                             W_varname = "W1",
                                             W_method = c("quantile", "discrete"),
                                             W_values = NULL,
                                             ci_level = 0.95) {
  if (!inherits(mc_result, "semmcci")) {
    stop("Input must be a 'semmcci' object.")
  }
  if (is.null(data) || !(W_varname %in% names(data))) {
    stop("Valid data and W_varname must be provided.")
  }

  W_method <- match.arg(W_method)
  W_raw <- data[[W_varname]]

  if (W_method == "quantile") {
    probs <- if (is.null(W_values)) c(0.05, 0.25, 0.5, 0.75, 0.95) else W_values
    W_values <- quantile(W_raw, probs = probs, na.rm = TRUE)
    level_labels <- paste0(round(probs * 100), "%")
  } else {
    SD_unit <- if (is.null(W_values)) c(-2, -1, 0, 1, 2) else W_values
    mean_W <- mean(W_raw, na.rm = TRUE)
    sd_W <- sd(W_raw, na.rm = TRUE)
    W_values <- mean_W + SD_unit * sd_W
    level_labels <- paste0(SD_unit, " SD")
  }

  W_values <- as.numeric(W_values)
  names(W_values) <- level_labels

  param_names <- colnames(mc_result$thetahatstar)
  indirect_names <- grep("^indirect(_\\d+)*$", param_names, value = TRUE)
  if (length(indirect_names) == 0) return(NULL)

  W_groups <- sapply(W_raw, function(wi) {
    diffs <- abs(wi - W_values)
    W_values[which.min(diffs)]
  })
  group_indices <- lapply(W_values, function(w) which(W_groups == w))

  ci_lower_name <- sprintf("%.1f%%CI.Lo", (1 - ci_level) / 2 * 100)
  ci_upper_name <- sprintf("%.1f%%CI.Up", (1 + ci_level) / 2 * 100)

  result_list <- lapply(indirect_names, function(ind_name) {
    samples <- mc_result$thetahatstar[, ind_name]
    rows <- mapply(function(i, label) {
      sub_samples <- samples[group_indices[[i]]]
      est <- mean(sub_samples, na.rm = TRUE)
      se <- sd(sub_samples, na.rm = TRUE)
      ci <- quantile(sub_samples, probs = c((1 - ci_level) / 2, 1 - (1 - ci_level) / 2), na.rm = TRUE)
      row <- data.frame(
        Path = ind_name,
        W = W_values[i],
        level = label,
        Estimate = est,
        SE = se,
        stringsAsFactors = FALSE
      )
      row[[ci_lower_name]] <- ci[1]
      row[[ci_upper_name]] <- ci[2]
      row
    }, i = seq_along(W_values), label = names(W_values), SIMPLIFY = FALSE)
    do.call(rbind, rows)
  })

  result <- do.call(rbind, result_list)

  extract_sort_key <- function(path) {
    parts <- strsplit(sub("^indirect_", "", path), "_")[[1]]
    nums <- suppressWarnings(as.numeric(parts))
    nums[is.na(nums)] <- Inf
    return(nums)
  }

  sort_key_list <- lapply(result$Path, extract_sort_key)
  max_len <- max(lengths(sort_key_list))
  sort_matrix <- t(sapply(sort_key_list, function(x) {
    c(length(x), x, rep(Inf, max_len - length(x)))
  }))
  sort_df <- as.data.frame(sort_matrix)
  sort_df$W <- result$W

  ord <- do.call(order, sort_df)
  result <- result[ord, ]
  rownames(result) <- NULL
  return(result)
}

