#' @title Monte Carlo confidence intervals for multiple imputation SEM models
#'
#' @description Computes Monte Carlo confidence intervals (MCCI) for structural equation models (SEM)
#' fitted to multiple imputed datasets. This function integrates SEM fitting across imputed datasets,
#' pools the results, and generates confidence intervals through Monte Carlo sampling.
#'
#' @details This function is designed for SEM models that require multiple imputation to handle missing data.
#' It performs the following steps:
#'
#' - **SEM Fitting**: Fits the specified SEM model to each imputed dataset using [lavaan::sem()].
#'
#' - **Pooling Results**: Combines parameter estimates and covariance matrices across imputations
#' using Rubin's rules.
#'
#' - **Monte Carlo Sampling**: Generates Monte Carlo samples based on the pooled estimates and covariance matrices,
#' and calculates confidence intervals for model parameters.
#'
#' This function supports custom estimators, handling of missing data, and precision adjustments for
#' Monte Carlo sampling. It is particularly useful for mediation analysis or complex SEM models
#' where missing data are addressed using multiple imputation.
#'
#' @param sem_model A character string specifying the SEM model syntax.
#' @param imputations A list of data frames, where each data frame represents an imputed dataset.
#' @param R An integer specifying the number of Monte Carlo samples. Default is `20000L`.
#' @param alpha A numeric vector specifying significance levels for the confidence intervals. Default is `c(0.001, 0.01, 0.05)`.
#' @param decomposition A character string specifying the decomposition method for the covariance matrix.
#' Default is `"eigen"`. Options include `"chol"`, `"eigen"`, or `"svd"`.
#' @param pd A logical value indicating whether to ensure positive definiteness of the covariance matrix. Default is `TRUE`.
#' @param tol A numeric value specifying the tolerance for positive definiteness checks. Default is `1e-06`.
#' @param seed An optional integer specifying the random seed for reproducibility. Default is `NULL`.
#' @param estimator A character string specifying the estimator for SEM fitting. Default is `"ML"` (Maximum Likelihood).
#' @param se A character string specifying the type of standard errors to compute. Default is `"standard"`.
#' @param missing A character string specifying the method for handling missing data in SEM fitting. Default is `"listwise"`.
#' @param fixed.x Whether exogenous covariates are treated as fixed in every
#'   imputation. Defaults to FALSE, consistently with wsMed().
#'
#' @return An object of class `semmcci` containing:
#' - `call`: The matched function call.
#' - `args`: A list of input arguments.
#' - `thetahat`: The pooled parameter estimates.
#' - `thetahatstar`: Monte Carlo samples for parameter estimates.
#' - `fun`: The name of the function (`"MCMI2"`).
#'
#' @seealso [lavaan::sem()], [semmcci::MC()], [semmcci::MCStd()]
#'
#' @examples
#' # Example SEM model
#' sem_model <- "
#'   Ydiff ~ b1 * M1diff + cp * 1
#'   M1diff ~ a1 * 1
#'   indirect := a1 * b1
#'   total := cp + indirect
#' "
#'
#' # Example imputed datasets
#' imputations <- list(
#'   data.frame(M1diff = rnorm(100), Ydiff = rnorm(100)),
#'   data.frame(M1diff = rnorm(100), Ydiff = rnorm(100))
#' )
#'
#' # Compute Monte Carlo confidence intervals
#' result <- MCMI2(
#'   sem_model = sem_model,
#'   imputations = imputations,
#'   R = 1000,
#'   alpha = c(0.05, 0.01),
#'   seed = 123
#' )
#' @import semmcci
#' @export

#' @details With \code{decomposition = "eigen"}, Monte Carlo sampling uses the
#' principal symmetric covariance square root. Equivalent eigenvector signs
#' and repeated-eigenvalue bases therefore produce the same draws up to numerical
#' precision. Fixed-seed draws differ from wsMed 1.1.0; the target distribution
#' and pooled point estimates are unchanged. Reproducing the complete analysis
#' also requires matching data, imputation settings, and software dependencies.
MCMI2 <- function(sem_model,
                 imputations,
                 R = 20000L,
                 alpha = c(0.001, 0.01, 0.05),
                 decomposition = "eigen",
                 pd = TRUE,
                 tol = 1e-06,
                 seed = NULL,
                 estimator = "ML",
                 se = "standard",
                 missing = "listwise",
                 fixed.x = FALSE) {
  stopifnot(
    is.character(sem_model),
    is.list(imputations) && all(sapply(imputations, is.data.frame))
  )

  fits <- lapply(imputations, function(data) {
    lavaan::sem(
      model = sem_model,
      data = data,
      estimator = estimator,
      se = se,
      missing = missing,
      fixed.x = fixed.x
    )
  })

  pooled <- .wsmed_pool_fits(fits)
  fit <- list(coefficients = pooled$est, covariance = pooled$total,
    backend = fits, point = .wsmed_point(fits[[1]], pooled$est),
    fixed.x = fixed.x, sem_model = sem_model,
    mi = list(prepared = list(processed_data_list = imputations), pooled = pooled))
  if (!is.null(seed)) set.seed(seed)
  out <- .wsmed_mi_mc(fit, R, alpha, seed, decomposition, pd, tol)
  out$call <- match.call()
  out
}
