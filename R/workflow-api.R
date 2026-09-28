#' Specify a two-condition mediation model
#'
#' @param outcome Named pair of outcome columns, in condition order.
#' @param mediators Named list of pairs of mediator columns.
#' @param conditions Two condition names. Defaults to the outcome pair names.
#' @param covariates List with `between` column names and `within` named pairs.
#' @param structure One of parallel, serial, serial_parallel, parallel_serial,
#'   or custom. Mediator order matters for predefined serial structures.
#' @param paths Directed edges using mediator role names and Y, for custom models.
#' @param moderator NULL or a list with `variable`, `main_effects`, `interactions`,
#'   and optionally `average_interactions`. Only main_effects = "all_equations"
#'   is currently supported. Interactions name edges such as "stress -> Y".
#' @return A `wsmed_model` specification, without data or fitted estimates.
#' @details All moderator main effects are explicitly included in all difference
#' equations. Difference-slope and average-slope interactions are separate.
#' Categorical between-subject predictors must be factors in the new workflow.
#' @md
#' @seealso [wsmed_categorical] for supported variable roles and factor coding.
#' @export
wsmed_model <- function(outcome, mediators, conditions = names(outcome),
                         covariates = list(), structure = "parallel",
                         paths = NULL, moderator = NULL) {
  if (!is.character(conditions) || length(conditions) != 2L || anyNA(conditions) ||
      any(!nzchar(conditions)) || anyDuplicated(conditions))
    stop("Supply two distinct named conditions.")
  pair <- function(x) {
    if (!is.character(x) || length(x) != 2L || anyNA(x) || any(!nzchar(x)) ||
        !identical(sort(names(x)), sort(conditions)))
      stop("Each variable pair must be named with the two conditions.")
    unname(x[conditions])
  }
  if (!is.list(mediators) || !length(mediators) || is.null(names(mediators)) ||
      anyNA(names(mediators)) || any(!nzchar(names(mediators))) ||
      anyDuplicated(names(mediators)) || "Y" %in% names(mediators) ||
      any(grepl("->", names(mediators), fixed = TRUE)))
    stop("mediators must be a list with distinct role names other than Y.")
  if (!is.list(covariates) || length(covariates) && (is.null(names(covariates)) ||
      anyDuplicated(names(covariates)) || any(!names(covariates) %in% c("between", "within"))))
    stop("covariates must contain only between and within.")
  yy <- pair(outcome); mm <- lapply(mediators, pair)
  cc <- lapply(covariates$within, pair)
  forms <- c(parallel = "P", serial = "CN", serial_parallel = "CP",
             parallel_serial = "PC", custom = "UD")
  structure <- match.arg(structure, names(forms))
  roles <- stats::setNames(c(paste0("M", seq_along(mm)), "Y"), c(names(mm), "Y"))
  edge <- function(x) {
    pieces <- trimws(strsplit(x, "->", fixed = TRUE)[[1]])
    if (length(pieces) != 2L || any(!pieces %in% names(roles)) || pieces[1] == "Y")
      stop("Invalid directed edge: ", x)
    unname(roles[pieces])
  }
  edges <- function(x) {
    if (is.null(x)) return(NULL)
    if (!is.character(x) || anyNA(x)) stop("Edges must be character strings.")
    vapply(x, function(z) paste(edge(z), collapse = " -> "), character(1))
  }
  coefficient <- function(x, prefix) {
    e <- edge(x); from <- sub("M", "", e[1]); to <- sub("M", "", e[2])
    if (e[2] == "Y") paste0(prefix, from) else paste0(prefix, "_", from, "_", to)
  }
  W <- MP <- NULL
  if (!is.null(moderator)) {
    if (!is.list(moderator) || is.null(names(moderator)) || anyDuplicated(names(moderator)) ||
        any(!names(moderator) %in% c("variable", "main_effects", "interactions", "average_interactions")))
      stop("Unknown moderator setting.")
    W <- moderator$variable
    if (!is.character(W) || length(W) != 1L || is.na(W) || !nzchar(W))
      stop("Exactly one moderator variable is required.")
    if (!identical(moderator$main_effects %||% "all_equations", "all_equations"))
      stop("Only moderator main_effects = 'all_equations' is supported.")
    MP <- c(paste0("a", seq_along(mm)), "cp",
      vapply(moderator$interactions, coefficient, character(1), prefix = "b"),
      vapply(moderator$average_interactions, coefficient, character(1), prefix = "d"))
  }
  vars <- list(M_C1 = vapply(mm, `[`, character(1), 1L),
    M_C2 = vapply(mm, `[`, character(1), 2L), Y_C1 = yy[1], Y_C2 = yy[2],
    C_C1 = if (length(cc)) vapply(cc, `[`, character(1), 1L) else NULL,
    C_C2 = if (length(cc)) vapply(cc, `[`, character(1), 2L) else NULL,
    C = covariates$between, C_type = NULL, W = W, W_type = NULL, MP = MP)
  cols <- unlist(vars[c("M_C1", "M_C2", "Y_C1", "Y_C2", "C_C1", "C_C2", "C", "W")], use.names = FALSE)
  if (!is.character(cols) || anyNA(cols) || any(!nzchar(cols)) || anyDuplicated(cols))
    stop("Analysis columns must be distinct nonempty names.")
  out <- .wsmed_legacy_model(vars, unname(forms[structure]), edges(paths))
  out$conditions <- conditions; out$mediator_names <- names(mm)
  out$call <- match.call(); out$strict <- TRUE
  # Validate the graph without fitting or supplying invented observations.
  schema <- as.data.frame(stats::setNames(rep(list(numeric()), 1 + 2 * length(mm)),
    c("Ydiff", paste0("M", seq_along(mm), "diff"), paste0("M", seq_along(mm), "avg"))))
  base <- out; base$input_vars$MP <- NULL
  syntax <- .wsmed_compile(base, schema)
  if (structure != "custom" && !is.null(paths)) stop("paths require structure = 'custom'.")
  if (out$form == "CN" && length(mm) < 2L || out$form %in% c("CP", "PC") && length(mm) < 3L)
    stop("Insufficient mediators for this serial structure.")
  labels <- lavaan::lavaanify(syntax)$label
  if (length(setdiff(MP, labels))) stop("Moderation names a path absent from the model.")
  out
}

#' Fit a specified mediation model without simulation
#'
#' @param model A `wsmed_model` object.
#' @param data A wide data frame with one row per participant.
#' @param missing Missing-data strategy: error, listwise, fiml, or mi.
#' @param mi MI controls: m, method, seed. Imputation and inference seeds are separate.
#' @param fixed.x Whether exogenous moments are fixed in the SEM.
#' @param verbose Show progress messages.
#' @return A `wsmed_fit` containing all fits and pooled estimates for MI.
#' @details This release preserves the existing per-imputation centering and
#' first-imputation reporting reference. It does not implement MI-bootstrap.
#' Factor outcome, mediator, and within-subject covariate columns are unsupported.
#' See [wsmed_categorical] for reference coding, numeric 0/1 predictors, and
#' restrictions on missing categorical predictors. `mi$method` specifies the
#' method for numeric variables; factors use logistic or multinomial regression.
#' Diagnostics include dataset-level convergence/admissibility, covariance checks,
#' case counts, warnings, and fitted category counts. Complete-case matrix rank
#' is descriptive, not an identification test for FIML. Counts below five receive
#' a descriptive small-category flag, not a universal validity cutoff.
#' Constant transformed variables are named in pre-fit errors. Non-converged
#' MI datasets stop pooling; known inadmissible fits cannot enter inference.
#' @md
#' @export
wsmed_fit <- function(model, data, missing = c("error", "listwise", "fiml", "mi"),
                       mi = list(), fixed.x = FALSE, verbose = FALSE) {
  if (!inherits(model, "wsmed_model")) stop("model must be a wsmed_model.")
  missing <- match.arg(missing)
  if (!is.data.frame(data) || !nrow(data) || anyDuplicated(names(data)))
    stop("data must be a nonempty data frame with unique column names.")
  if (!is.list(mi) || length(mi) && (is.null(names(mi)) || anyDuplicated(names(mi)) ||
      any(!names(mi) %in% c("m", "method", "seed")))) stop("Unknown MI control.")
  v <- model$input_vars
  cols <- unlist(v[c("M_C1", "M_C2", "Y_C1", "Y_C2", "C_C1", "C_C2", "C", "W")], use.names = FALSE)
  if (!all(cols %in% names(data))) stop("Missing columns: ", paste(setdiff(cols, names(data)), collapse = ", "))
  numeric_cols <- unlist(v[c("M_C1", "M_C2", "Y_C1", "Y_C2", "C_C1", "C_C2")], use.names = FALSE)
  if (!all(vapply(data[numeric_cols], is.numeric, logical(1))))
    stop("Outcomes, mediators and within-subject covariates must be numeric.")
  get_type <- function(nm) {
    x <- data[[nm]]
    if (is.ordered(x)) stop("Convert ordered predictors explicitly to nominal factors if intended.")
    if (is.factor(x)) {
      if (nlevels(x) < 2L || any(tabulate(x, nbins = nlevels(x)) == 0L))
        stop("All declared factor levels must be observed: ", nm)
      return("categorical")
    }
    if (is.numeric(x)) return("continuous")
    stop("Convert categorical predictors explicitly to factors: ", nm)
  }
  if (length(v$C)) v$C_type <- vapply(v$C, get_type, character(1))
  if (length(v$W)) v$W_type <- get_type(v$W)
  if (any(vapply(data[cols], function(x) is.numeric(x) && any(!is.finite(x) & !is.na(x)), logical(1))))
    stop("Analysis data contain non-finite values.")
  if (missing == "error" && anyNA(data[cols])) stop("Choose a missing-data strategy explicitly.")
  if (missing == "fiml" && any(vapply(data[c(v$C, v$W)], function(x)
      is.factor(x) && anyNA(x), logical(1))))
    stop("FIML with missing categorical predictors is unsupported; consider MI.")
  model$input_vars <- v
  ctrl <- utils::modifyList(list(m = 5L, method = "pmm", seed = NULL), mi)
  assert_scalar_int(ctrl$m, "m", lower = 2L)
  assert_scalar_int(ctrl$seed, "seed", lower = 0L, allow_null = TRUE)
  if (!is.logical(fixed.x) || length(fixed.x) != 1L || is.na(fixed.x)) stop("fixed.x must be TRUE or FALSE.")
  Na <- switch(missing, error = "DE", listwise = "DE", fiml = "FIML", mi = "MI")
  fit <- .wsmed_preserve_rng(.wsmed_fit_core(model, data, Na,
    list(m = ctrl$m, method_num = ctrl$method, seed = ctrl$seed), fixed.x, verbose),
    preserve = Na != "MI" || !is.null(ctrl$seed))
  fit$call <- match.call()
  fit
}

#' Apply uncertainty quantification to an existing fit
#'
#' @param object A `wsmed_fit`, or a new `wsMed` one-call result.
#' @param method mc or bootstrap. MI currently supports mc only.
#' @param draws Number of draws; defaults to 20000 for mc and 2000 for bootstrap.
#' @param seed Random seed, independent of the imputation seed.
#' @param level Confidence level.
#' @param interval Bootstrap interval type: perc, bc, or bca.simple.
#'   This controls the legacy parameter table stored in the inference backend.
#'   Effect extraction and confint methods always use percentile intervals.
#'   bca.simple uses zero acceleration, rather than a full BCa calculation.
#' @param decomposition MI covariance factorization: eigen, chol, or svd.
#' @param pd,tol MI covariance checks; passed to the existing sampler.
#' @return A `wsmed_inference` storing draws and the original fit.
#' @details Inference never reimputes or changes the supplied fit. Bootstrap
#' necessarily fits resampled datasets. No new statistical engine is introduced.
#' Seeded calls restore the caller's random state; seed = NULL consumes the
#' current random stream and advances it normally.
#' Fits with endogenous products must record compatible model and MI pooling
#' algorithm identifiers. Older unversioned moderated fits require refitting
#' from the original data; package version alone cannot identify their algorithms.
#' @export
wsmed_infer <- function(object, method = c("mc", "bootstrap"), draws = NULL,
                         seed = NULL, level = 0.95, interval = "perc",
                         decomposition = "eigen", pd = TRUE, tol = 1e-6) {
  if (inherits(object, "wsMed")) object <- object$fit
  if (!inherits(object, "wsmed_fit")) stop("object must contain an independent wsmed_fit.")
  method <- match.arg(method)
  if (is.null(draws)) draws <- if (method == "mc") 20000L else 2000L
  assert_scalar_int(draws, "draws", lower = 2L)
  assert_scalar_int(seed, "seed", lower = 0L, allow_null = TRUE)
  .wsmed_level(level)
  interval <- match.arg(interval, c("perc", "bc", "bca.simple"))
  decomposition <- match.arg(decomposition, c("eigen", "chol", "svd"))
  if (!is.logical(pd) || length(pd) != 1L || is.na(pd)) stop("pd must be TRUE or FALSE.")
  if (!is.numeric(tol) || length(tol) != 1L || !is.finite(tol) || tol <= 0)
    stop("tol must be a positive finite number.")
  .wsmed_preserve_rng(.wsmed_infer_core(object, method, draws, seed, level,
    interval, decomposition, pd, tol), preserve = !is.null(seed))
}

.wsmed_level <- function(level) {
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1)
    stop("level must be a finite number between zero and one.")
  invisible(level)
}
