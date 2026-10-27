#' Export the settings and provenance of an analysis
#'
#' @param object A wsmed_model, wsmed_fit, wsmed_inference, wsmed_results, or
#'   current wsMed object. A one-call object exports all stored inference methods.
#' @param file Optional new .rds file for the report. Existing files are not overwritten.
#' @return A plain list of model specification, settings, reference coding,
#'   diagnostics, and recorded software versions; invisibly when written to file.
#' @details This report contains no participant-level data or simulation draws.
#' It is an analysis manifest, not a replacement for the data, analysis script,
#' or a dependency lockfile. It never fits, imputes, samples, or updates results.
#' Recorded fitting versions are separated from the environment used to export.
#' Metadata absent from an older saved object remain absent, not reconstructed
#' from currently installed package versions. Reports for extracted results
#' include the query and contrast definition as well as the upstream settings.
#' @examples
#' data(example_data)
#' m <- wsmed_model(c(before = "D1", after = "D2"),
#'   list(A = c(before = "A1", after = "A2")))
#' f <- wsmed_fit(m, example_data)
#' report <- wsmed_reproducibility(f)
#' report$analysis$missing
#' @export
wsmed_reproducibility <- function(object, file = NULL) {
  report <- .wsmed_repro_details(object)
  report$export_environment <- list(R = R.version.string,
    platform = R.version$platform, wsMed = as.character(utils::packageVersion("wsMed")))
  if (is.null(file)) return(report)
  if (!is.character(file) || length(file) != 1L || is.na(file) ||
      !grepl("\\.rds$", file, ignore.case = TRUE)) stop("file must name a new .rds file.")
  if (file.exists(file)) stop("Report file already exists: ", file)
  saveRDS(report, file)
  invisible(report)
}

.wsmed_repro_details <- function(object) {
  if (!inherits(object, c("wsMed", "wsmed_model", "wsmed_fit", "wsmed_inference", "wsmed_results")))
    stop("A wsMed workflow object is required.")
  if (inherits(object, "wsmed_results")) {
    report <- object$query$reproducibility
    if (is.null(report)) stop("This saved result has no recorded analysis manifest; use its original fit.")
    report$query <- object$query[setdiff(names(object$query), c("reproducibility", "inference_diagnostics"))]
    report$effect_diagnostics <- object$diagnostics
    return(report)
  }
  if (inherits(object, "wsMed")) {
    if (!inherits(object$fit, "wsmed_fit")) stop("This saved wsMed object predates recorded workflow provenance.")
    report <- .wsmed_repro_details(object$fit)
    report$inference <- lapply(object$inference, .wsmed_repro_inference)
    return(report)
  }
  if (inherits(object, "wsmed_inference")) {
    report <- .wsmed_repro_details(object$fit)
    report$inference <- stats::setNames(list(.wsmed_repro_inference(object)), object$method)
    return(report)
  }
  model <- if (inherits(object, "wsmed_model")) object else object$model
  if (!inherits(model, "wsmed_model")) stop("A wsMed workflow object is required.")
  # Calls can contain literal data expressions; export the resolved specification.
  report <- list(report_schema_version = 1L,
    model = model[setdiff(names(model), "call")])
  if (inherits(object, "wsmed_model")) return(report)
  if (!inherits(object, "wsmed_fit")) stop("A wsMed workflow object is required.")
  report$analysis <- list(missing = object$Na, fixed.x = object$fixed.x,
    standardized = object$standardized,
    imputation = if (object$Na == "MI") object$mi$controls else NULL,
    imputation_methods = object$mi$prepared$mids$method,
    input_rows = object$diagnostics$n_input, used_rows = object$diagnostics$n_used,
    syntax = object$sem_model, reference = object$reference,
    interpretation = .wsmed_analysis_description(object))
  report$fitting_versions <- object$provenance
  report$fit_diagnostics <- object$diagnostics[setdiff(names(object$diagnostics), "case_indices")]
  report
}

.wsmed_repro_inference <- function(object) {
  list(method = object$method, controls = object$controls,
    effect_interval = "percentile", provenance = object$provenance,
    diagnostics = object$diagnostics)
}
