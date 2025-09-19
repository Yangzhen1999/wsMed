#' @title Prepare Data with Missing Values for Mediation Analysis
#'
#' @description
#' Handles missing values in the dataset through multiple imputation
#' and prepares the imputed datasets for within-subject mediation analysis.
#' The function imputes missing data, processes each imputed dataset,
#' and provides diagnostics for the imputation process.
#'
#' @details
#' This function is designed to preprocess datasets with missing values
#' for mediation analysis. It performs the following steps:
#'
#' - Multiple imputation: Uses specified imputation methods
#'   (for example, predictive mean matching) to generate
#'   \code{m} imputed datasets.
#'
#' - Data preparation: Applies \code{\link{PrepareData}} to each of the
#'   \code{m} imputed datasets to calculate difference scores
#'   and centered averages for mediators and the outcome variable.
#'
#' - Imputation diagnostics: Provides summary diagnostics for the imputation
#'   process, including information about missing data patterns and convergence.
#'
#' This function integrates imputation and data preparation, ensuring that
#' the resulting datasets are ready for subsequent mediation analysis.
#'
#' @param data_missing A data frame containing the raw dataset with missing values.
#' @param m An integer specifying the number of imputations to perform. Default is \code{5}.
#' @param seed An integer specifying the random seed for reproducibility. Default is \code{123}.
#' @param M_C1 A character vector of column names representing mediators at condition 1.
#' @param M_C2 A character vector of column names representing mediators at condition 2.
#'   Must match the length of \code{M_C1}.
#' @param Y_C1 A character string representing the column name of the outcome variable at condition 1.
#' @param Y_C2 A character string representing the column name of the outcome variable at condition 2.
#' @param C_C1 Character vector of within-subject control variable names (condition 1).
#' @param C_C2 Character vector of within-subject control variable names (condition 2).
#' @param C Character vector of between-subject control variable names.
#' @param W A character vector specifying the names of moderator variables
#'   that are used to generate interaction terms with mediators. These variables
#'   will be included in the imputation model and passed to \code{PrepareData}.
#'   Default is \code{NULL}.
#' @param method_num Character; imputation method for numeric variables
#'   (for example, \code{"pmm"}, \code{"norm"}). Default is \code{"pmm"}.
#' @param C_type Optional vector of the same length as \code{C}.
#'   Each element is \code{"continuous"}, \code{"categorical"}, or \code{"auto"}
#'   (default). Ignored when \code{C = NULL}.
#' @param W Optional character vector: moderator names (at most J).
#' @param W_type Optional vector of the same length as \code{W}.
#'   Same coding as \code{C_type}. Ignored when \code{W = NULL}.
#' @param center_W Logical. Whether to center the moderator variable W.
#' @param keep_W_raw,keep_C_raw Logical; keep the original W / C columns
#'   in the returned data?
#'
#' @return A list containing:
#' \describe{
#'   \item{\code{processed_data_list}}{A list of \code{m} data frames,
#'     each representing an imputed and processed dataset ready for
#'     within-subject mediation analysis.}
#'   \item{\code{imputation_summary}}{A summary of the imputation process,
#'     including diagnostics and convergence information.}
#' }
#'
#' @seealso \code{\link{PrepareData}}, \code{\link{ImputeData}}, \code{\link{wsMed}}
#'
#' @examples
#' # Example dataset with missing values
#' data(example_data)
#' set.seed(123)
#' example_dataN <- mice::ampute(
#'   data = example_data,
#'   prop = 0.1
#' )$amp
#'
#' # Prepare the dataset with multiple imputations
#' prepared_missing_data <- PrepareMissingData(
#'   data_missing = example_dataN,
#'   m = 5,
#'   M_C1 = c("A2", "B2"),
#'   M_C2 = c("A1", "B1"),
#'   Y_C1 = "C2",
#'   Y_C2 = "C1"
#' )
#'
#' # Access processed datasets
#' processed_data_list <- prepared_missing_data$processed_data_list
#' imputation_summary  <- prepared_missing_data$imputation_summary
#'
#' @export


PrepareMissingData <- function(data_missing,
                               m          = 5,
                               method_num = "pmm",
                               seed       = 123,
                               M_C1,  M_C2,
                               Y_C1,  Y_C2,
                               C_C1 = NULL,  C_C2 = NULL,
                               C     = NULL, C_type = NULL,
                               W     = NULL, W_type = NULL,
                               center_W   = TRUE,     # <‑‑ NEW
                               keep_W_raw = TRUE,
                               keep_C_raw = TRUE) {

  ## ---------- 0. basic checks ----------
  stopifnot(length(M_C1) == length(M_C2))
  stopifnot(all(c(Y_C1, Y_C2) %in% names(data_missing)))

  ## ---------- 1. subset ----------
  relevant <- unique(na.omit(c(Y_C1, Y_C2, M_C1, M_C2,
                               C_C1, C_C2, C, W)))
  dat <- data_missing[, relevant, drop = FALSE]

  ## ---------- 2. char → factor ----------
  dat[vapply(dat, is.character, logical(1))] <-
    lapply(dat[vapply(dat, is.character, logical(1))], factor)

  ## ---------- 3. build mice method/predictor matrix ----------
  init  <- mice::mice(dat, maxit = 0, print = FALSE)
  meth  <- init$method
  pred  <- init$predictorMatrix
  is_fac <- vapply(dat, is.factor, logical(1))

  for (v in names(dat)) {
    if (is_fac[v]) {
      k <- nlevels(dat[[v]])
      meth[v] <- if (k == 2) "logreg" else "polyreg"
    } else {
      meth[v] <- method_num
    }
  }

  ## ---------- 4. run mice ----------
  mids <- mice::mice(dat, m = m, method = meth,
                     predictorMatrix = pred, seed = seed, print = FALSE)
  imputed_list <- mice::complete(mids, action = "all")

  ## ---------- 5. call PrepareData on each completed set ----------
  processed <- lapply(
    imputed_list,
    function(d) PrepareData(
      data = d,
      M_C1 = M_C1,  M_C2 = M_C2,
      Y_C1 = Y_C1,  Y_C2 = Y_C2,
      C_C1 = C_C1,  C_C2 = C_C2,
      C     = C,    C_type = C_type,
      W     = W,    W_type = W_type,
      center_W = center_W,        # <‑‑ passes through
      keep_W_raw = keep_W_raw,
      keep_C_raw = keep_C_raw
    )
  )

  ## ---------- 6. return ----------
  list(
    mids               = mids,
    processed_data_list= processed,
    imputation_summary = summary(mids)
  )
}

