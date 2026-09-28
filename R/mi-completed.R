# Accept imputations made by a model-aware external imputer. Validation cannot
# certify statistical compatibility, but must prevent changing observed data.
.wsmed_completed <- function(completed, data, variables, m = NULL) {
  if (inherits(completed, "mids")) completed <- mice::complete(completed, "all")
  if (!is.list(completed) || is.data.frame(completed) || length(completed) < 2L ||
      !all(vapply(completed, is.data.frame, logical(1))))
    stop("completed must be a list of at least two completed data frames or a mids object.")
  if (!is.null(m)) assert_scalar_int(m, "m", lower = 2L)
  if (!is.null(m) && !identical(as.integer(m), length(completed)))
    stop("m must equal the number of supplied completed datasets.")
  lapply(seq_along(completed), function(j) {
    d <- completed[[j]]
    if (nrow(d) != nrow(data) || anyDuplicated(names(d)) ||
        !all(variables %in% names(d)) || !identical(row.names(d), row.names(data)))
      stop("Completed dataset ", j, " must preserve participant rows, row names and analysis columns.")
    for (nm in variables) {
      original <- data[[nm]]; x <- d[[nm]]; observed <- !is.na(original)
      if (is.character(original)) {
        original <- factor(original)
        if (is.character(x)) x <- factor(x, levels = levels(original))
        d[[nm]] <- x
      }
      if (anyNA(x) || (is.numeric(x) && any(!is.finite(x))))
        stop("Completed dataset ", j, " contains missing/non-finite analysis values: ", nm)
      if (is.factor(original)) {
        if (!is.factor(x) || !identical(levels(x), levels(original)) ||
            !identical(is.ordered(x), is.ordered(original)))
          stop("Completed dataset ", j, " must preserve factor levels and ordering: ", nm)
      } else if (is.numeric(original) && !is.numeric(x)) {
        stop("Completed dataset ", j, " must preserve numeric analysis columns: ", nm)
      }
      if (!isTRUE(all.equal(unname(x[observed]), unname(original[observed]),
                           tolerance = 0, check.attributes = FALSE)))
        stop("Completed dataset ", j, " changes observed values or participant order: ", nm)
    }
    d[, variables, drop = FALSE]
  })
}

.wsmed_prepare_completed <- function(data, completed, prep_args) {
  relevant <- unique(na.omit(unlist(prep_args[c("Y_C1", "Y_C2", "M_C1", "M_C2",
    "C_C1", "C_C2", "C", "W")], use.names = FALSE)))
  raw <- .wsmed_completed(completed, data, relevant)
  processed <- lapply(raw, function(d) do.call(PrepareData,
    c(list(data = d), prep_args, list(keep_W_raw = TRUE, keep_C_raw = TRUE))))
  list(mids = NULL, completed_data = raw, processed_data_list = processed,
    imputation_summary = list(engine = "external", m = length(raw)))
}
