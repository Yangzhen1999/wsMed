#' @title Monte Carlo sampling for parameter estimates
#' @md
#'
#' @description Generates Monte Carlo samples for parameter estimates using a covariance matrix
#' and a location vector. With eigen decomposition, sampling uses the principal
#' symmetric square root of the covariance matrix.
#'
#' @details The eigen sampler is invariant to eigenvector signs and to rotations
#' within eigenspaces with repeated eigenvalues, up to numerical precision.
#' This changes fixed-seed draws relative to wsMed 1.1.0, while preserving their
#' target distribution. It does not guarantee identical results across different
#' fitted inputs, imputation algorithms, or software environments.
#'
#' @param R Integer. Number of Monte Carlo samples to generate.
#' @param scale Numeric matrix. The covariance matrix of the parameter estimates.
#' @param location Numeric vector. The mean (or location) of the parameter estimates.
#' @param decomposition Character. Decomposition method for the covariance matrix.
#' Options: `"chol"` (Cholesky), `"eigen"` (eigenvalue decomposition), `"svd"` (singular value decomposition). Default is `"eigen"`.
#' @param pd Logical. Ensure positive definiteness of the covariance matrix. Default is `TRUE`.
#' @param tol Numeric. Tolerance for positive definiteness checks. Default is `1e-06`.
#'
#' @return A list containing:
#' - `thetahatstar`: A matrix of simulated parameter estimates with dimensions `R x length(location)`.
#' - `decomposition`: The decomposition method used.
#'
#' @seealso [MCMI2()], [RunMCMIAnalysis()]
#'
#'
#' @keywords internal


ThetaHatStarWrapper <- function(R = 20000L,
                          scale,
                          location,
                          decomposition = "eigen",
                          pd = TRUE,
                          tol = 1e-06) {
  if (pd) {
    mat <- eigen(
      x = scale,
      symmetric = TRUE,
      only.values = FALSE
    )
    npd <- !TestPositiveDefinitewrapper(
      eigen = mat,
      tol = tol
    )
    if (npd) {
      stop(
        "The sampling variance-covariance matrix is nonpositive definite."
      )
    }
  }
  n <- R
  k <- length(location)
  z <- RandomGaussianZwrapper(
    n = n,
    k = k
  )
  if (decomposition == "chol") {
    dist <- RandomGaussianCholwrapper(
      Z = z,
      chol = chol(x = scale)
    )
  }
  if (decomposition == "eigen") {
    if (!pd) {
      mat <- eigen(
        x = scale,
        symmetric = TRUE,
        only.values = FALSE
      )
    }
    dist <- RandomGaussianEigenwrapper(
      Z = z,
      eigen = mat
    )
  }
  if (decomposition == "svd") {
    dist <- RandomGaussianSVDwrapper(
      Z = z,
      svd = svd(
        x = scale
      )
    )
  }
  dist <- Locationwrapper(
    X = dist,
    location = location,
    n = n,
    k = k
  )
  colnames(
    dist
  ) <- names(
    location
  )
  return(
    list(
      thetahatstar = dist,
      decomposition = decomposition
    )
  )
}

