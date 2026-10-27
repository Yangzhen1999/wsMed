# Algorithm identifiers are independent of the package development version:
# several statistically different builds can share the same DESCRIPTION version.
.wsmed_fit_algorithms <- function() list(
  product_moments = "endogenous-products-v1",
  mi_marginal_pooling = "joint-rubin-v1")

.wsmed_inference_algorithms <- function() list(
  mi_variance_sampler = "symmetric-psd-v1")

.wsmed_has_products <- function(fit) {
  syntax <- fit$sem_model %||% ""
  any(grepl("int_M[0-9]+diff_W[0-9]+", syntax))
}

.wsmed_check_schema <- function(object, action) {
  version <- object$schema_version
  if (!is.null(version) && !identical(version, 1L))
    stop("Unsupported saved-object schema for ", action,
      ". Use the wsMed version that created this object or refit from the original data.", call. = FALSE)
}

.wsmed_check_fit <- function(fit) {
  .wsmed_check_schema(fit, "inference/effect extraction")
  recorded <- fit$provenance$algorithms
  expected <- .wsmed_fit_algorithms()
  required <- "product_moments"
  if (identical(fit$Na, "MI")) required <- c(required, "mi_marginal_pooling")
  if (.wsmed_has_products(fit) && !identical(recorded[required], expected[required]))
    stop("This saved moderated fit has missing or incompatible algorithm metadata. ",
      "Refit from the original data with wsmed_fit() or wsMed(), then rerun inference; ",
      "updating the package cannot repair stored model moments. ",
      "Stored coefficients and full legacy output remain available for inspection.", call. = FALSE)
  invisible(fit)
}

.wsmed_check_inference <- function(object) {
  .wsmed_check_schema(object, "effect extraction")
  .wsmed_check_fit(object$fit)
  if (.wsmed_has_products(object$fit) && identical(object$fit$Na, "MI") &&
      identical(object$method, "mc") &&
      !identical(object$provenance$algorithms, .wsmed_inference_algorithms()))
    stop("This saved MI inference has missing or incompatible sampler metadata. ",
      "Keep the compatible fit and rerun wsmed_infer(fit, method = 'mc', seed = ...). ",
      "Stored draws cannot acquire the corrected sampler by re-extraction.", call. = FALSE)
  invisible(object)
}

.wsmed_check_legacy_standardization <- function(object) {
  if (inherits(object$fit, "wsmed_fit")) {
    .wsmed_check_fit(object$fit)
    invisible(lapply(object$inference, .wsmed_check_inference))
  } else if (any(grepl("int_M[0-9]+diff_W[0-9]+", object$sem_model %||% "")) ||
      any(grepl("int_M[0-9]+diff_W[0-9]+", names(object$mc$result$thetahat$est)))) {
    stop("This saved moderated result predates algorithm metadata. ",
      "Refit from the original data with wsMed() before standardizing it; ",
      "print(detail = 'full') can still inspect its stored output.", call. = FALSE)
  }
  invisible(object)
}
