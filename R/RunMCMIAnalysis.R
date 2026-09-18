#' @title Monte Carlo SEM with Multiple Imputation (WsMed Workflow)
#'
#' @description
#' `RunMCMIAnalysis()` is a helper that:
#' \enumerate{
#' \item imputes missing data via \code{\link{PrepareMissingData}};
#' \item generates all WsMed variables in each completed data set;
#' \item fits the user-supplied SEM model to each replicate; and
#' \item pools the results via \code{MCMI2()}, producing Monte Carlo
#'       confidence intervals (MCCI) for all model parameters.
#' }
#'
#' @details
#' Internally the function calls:
#' \itemize{
#'   \item \code{PrepareMissingData()} – performs multiple imputation
#'         (\strong{logreg} / \strong{polyreg} for categorical variables,
#'         and \code{method_num} for numeric) and applies
#'         \code{\link{PrepareData}} to each imputed set;
#'   \item \code{MCMI2()} – pools parameter estimates across the
#'         \code{m} imputations and draws \code{R} Monte Carlo samples.
#' }
#'
#' Only the missing-data strategy \code{Na = "MI"} is supported.
#'
#' @param data_missing Data frame with missing values.
#' @param m Integer, number of imputations. Default \code{5}.
#' @param method_num Character, imputation method for numeric variables
#'   (e.g., \code{"pmm"}, \code{"norm"}). Default \code{"pmm"}.
#' @param seed Integer random seed (passed to \code{mice} and \code{MCMI2}).
#'
#' @param M_C1,M_C2 Character vectors: mediator names at condition 1 & 2
#'   (same length).
#' @param Y_C1,Y_C2 Character scalars: outcome names at condition 1 & 2.
#'
#' @param C_C1,C_C2 Optional character vectors: within-subject controls.
#' @param C Optional character vector: between-subject controls.
#' @param C_type Optional vector (length = \code{C});
#'   each element \code{"continuous"}, \code{"categorical"}, or
#'   \code{"auto"} (default).
#'
#' @param W Optional character vector: moderator name(s).
#' @param W_type Optional vector (length = \code{W});
#'   same coding as \code{C_type}.
#' @param keep_W_raw,keep_C_raw Logical; keep raw W / C columns in the
#'   processed data? Defaults \code{TRUE}.
#'
#' @param sem_model Character string, lavaan syntax of the SEM to be fitted.
#'
#' @param Na Character, missing-data strategy. Currently only
#'   \code{"MI"} is implemented.
#'
#' @param R Integer, number of Monte Carlo samples (default \code{20000L}).
#' @param alpha Numeric vector, significance levels for two-sided CIs
#'   (default \code{c(0.001, 0.01, 0.05)}).
#' @param decomposition Decomposition used by \code{MCMI2()}
#'   (\code{"eigen"} | \code{"chol"} | \code{"svd"}). Default \code{"eigen"}.
#' @param pd Logical, enforce positive-definite covariance (default \code{TRUE}).
#' @param tol Numeric tolerance for PD checks. Default \code{1e-6}.
#'
#' @param fixed.x Whether to treat exogenous covariates as fixed in every imputation.
#' @return A list with three elements:
#' \describe{
#'   \item{\code{mc_result}}{A \code{semmcci} object returned by
#'         \code{MCMI2()}.}
#'   \item{\code{first_imputed_data}}{The first processed data frame
#'         (useful for inspection or plotting).}
#'   \item{\code{imputation_summary}}{Diagnostics from
#'         \code{PrepareMissingData()}.}
#' }
#'
#' @seealso
#' \code{\link{PrepareMissingData}}, \code{\link{PrepareData}}, \code{MCMI2},
#' \code{wsMed}
#'
#' @keywords internal



RunMCMIAnalysis <- function(data_missing,
                            m            = 5,
                            method_num   = "pmm",   # ← 对连续变量的插补方法
                            seed         = 123,
                            ## ---------- 设计变量 ----------
                            M_C1,  M_C2,
                            Y_C1,  Y_C2,
                            C_C1 = NULL,  C_C2 = NULL,
                            C     = NULL, C_type = NULL,
                            W     = NULL, W_type = NULL,
                            keep_W_raw = TRUE,
                            keep_C_raw = TRUE,
                            ## ---------- SEM + MC ----------
                            sem_model,
                            Na           = "MI",
                            R            = 20000L,
                            alpha        = c(0.001, 0.01, 0.05),
                            decomposition= "eigen",
                            pd           = TRUE,
                            tol          = 1e-06,
                            fixed.x      = FALSE) {


  if (Na != "MI")
    stop("Currently RunMCMIAnalysis only supports Na = 'MI'.")

  quiet <- function(expr){
    nullfile <- if (.Platform$OS.type=="windows") "NUL" else "/dev/null"
    zz <- file(nullfile, open="wt")
    sink(zz); sink(zz, type="message")
    on.exit({ sink(type="message"); sink(); close(zz) }, add = TRUE)
    force(expr)
  }

  ## ---------- 1. PrepareMissingData ----------
  prepared <- quiet (PrepareMissingData(
    data_missing = data_missing,
    m            = m,
    method_num   = method_num,
    seed         = seed,
    M_C1         = M_C1,  M_C2 = M_C2,
    Y_C1         = Y_C1,  Y_C2 = Y_C2,
    C_C1         = C_C1,  C_C2 = C_C2,
    C            = C,     C_type = C_type,
    W            = W,     W_type = W_type,
    keep_W_raw   = keep_W_raw,
    keep_C_raw   = keep_C_raw
  ))

  processed_list     <- prepared$processed_data_list
  first_imputed_data <- processed_list[[1]]

  ## ---------- 2. Monte-Carlo multiple-imputation inference ----------
  mi_result <- MCMI2(
    sem_model   = sem_model,
    imputations = processed_list,
    R           = R,
    alpha       = alpha,
    decomposition = decomposition,
    pd          = pd,
    tol         = tol,
    seed        = seed,
    fixed.x     = fixed.x
  )

  ## ---------- 3. 返回 ----------
  list(
    mc_result          = mi_result,
    first_imputed_data = first_imputed_data,
    imputation_summary = prepared$imputation_summary
  )
}

