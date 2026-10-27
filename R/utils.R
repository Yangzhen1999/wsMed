#' Get safe number of CPUs for parallel processing
#'
#' Automatically returns 1 when on CI to avoid errors.
#' @keywords internal
get_safe_ncpus <- function() {
  if (Sys.getenv("_R_CHECK_PACKAGE_NAME_", "") != "") {
    # Use one CPU under R CMD check
    return(1L)
  } else {
    return(min(4L, parallel::detectCores(logical = FALSE)))
  }
}

