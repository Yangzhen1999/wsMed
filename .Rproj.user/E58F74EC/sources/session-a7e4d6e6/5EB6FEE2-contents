#' Get safe number of CPUs for parallel processing
#'
#' Automatically returns 1 when on CI to avoid errors.
#' @keywords internal
get_safe_ncpus <- function() {
  if (Sys.getenv("_R_CHECK_PACKAGE_NAME_", "") != "") {
    # 在 R CMD check 环境中强制用 1 核
    return(1L)
  } else {
    return(min(4L, parallel::detectCores(logical = FALSE)))
  }
}

