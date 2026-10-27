# Explain existing type decisions without changing either interface's coding.
.wsmed_input_notes <- function(model, data) {
  v <- model$input_vars
  if (!length(v$W)) return(character())
  x <- data[[v$W]]
  if (!is.numeric(x) || !setequal(unique(x[!is.na(x)]), c(0, 1))) return(character())
  guidance <- paste("For categorical predictors in either interface, use factor()",
    "with explicit levels; the first level is the reference group.")
  if (isTRUE(model$strict)) return(paste0("Numeric 0/1 moderator '", v$W,
    "' is continuous in wsmed_fit(). ", guidance))
  if (is.null(v$W_type) || identical(v$W_type, "auto")) return(paste0("wsMed() automatically treats numeric 0/1 moderator '",
    v$W, "' as categorical (reference: 0). ", guidance,
    " Set W_type = 'continuous' if a numeric interpretation is intended."))
  character()
}

# Support is descriptive: observed values among used participants, not a
# multivariate overlap diagnostic or a guarantee against sparse extrapolation.
.wsmed_probe_support <- function(fit, values) {
  v <- fit$model$input_vars
  used <- unique(unlist(fit$diagnostics$case_indices, use.names = FALSE))
  raw <- fit$raw_data[[v$W]][used]
  if (v$W_type == "continuous") {
    observed <- raw[is.finite(raw)]
    limits <- if (length(observed)) range(observed) else c(NA_real_, NA_real_)
    outside <- if (length(observed)) values < limits[1] | values > limits[2] else rep(NA, length(values))
    if (any(outside %in% TRUE)) warning(structure(list(message = paste0(
      "Moderator probes outside the observed fitted-case range of ", v$W, " [",
      paste(format(limits, digits = 6), collapse = ", "), "]: ",
      paste(format(values[outside], digits = 6), collapse = ", "), ". These estimates extrapolate."), call = NULL),
      class = c("wsmed_extrapolation_warning", "warning", "condition")))
    return(list(variable = v$W, observed_range = limits, observed_n = length(observed),
      reference = "Observed moderator values among participants used in at least one fit; imputed values excluded",
      probes = data.frame(at = as.character(values), extrapolated = outside)))
  }
  counts <- fit$diagnostics$category_counts
  counts <- counts[counts$variable == v$W, , drop = FALSE]
  rows <- lapply(values, function(value) {
    n <- counts$n[counts$level == value]
    data.frame(at = as.character(value), extrapolated = NA,
      n.observed = sum(as.character(raw) == value, na.rm = TRUE),
      n.fitted.min = if (length(n)) min(n) else NA_integer_,
      n.fitted.max = if (length(n)) max(n) else NA_integer_)
  })
  list(variable = v$W, reference = if (fit$Na == "MI")
    "Fitted group counts: range across completed datasets; observed counts exclude imputed moderator values" else
    "Fitted group counts after missing-data handling; observed counts exclude missing moderator values",
    probes = do.call(rbind, rows))
}

.wsmed_support_caption <- function(support, at, contrast_flags = NULL) {
  if (!is.null(contrast_flags)) return(if (any(contrast_flags %in% TRUE))
    "This contrast uses extrapolated conditional estimates; inspect query$source_terms." else NULL)
  if (is.null(support)) return(NULL)
  d <- support$probes[support$probes$at %in% at, , drop = FALSE]
  if (any(d$extrapolated %in% TRUE)) return(paste0("Extrapolation beyond observed fitted-case range: ",
    paste(d$at[d$extrapolated %in% TRUE], collapse = ", "), " (", support$variable, ")."))
  if (!is.null(support$observed_range) && all(is.na(support$observed_range)))
    return("Observed moderator range unavailable; support cannot be assessed.")
  if ("n.fitted.min" %in% names(d)) {
    counts <- ifelse(d$n.fitted.min == d$n.fitted.max, d$n.fitted.min,
      paste0(d$n.fitted.min, "-", d$n.fitted.max))
    count_text <- paste0("Fitted group n: ", paste(paste0(d$at, " = ", counts), collapse = "; "), ".")
    return(paste(c(strwrap(count_text, width = 78), strwrap(paste0(support$reference, "."), width = 78)),
      collapse = "\n"))
  }
  NULL
}
