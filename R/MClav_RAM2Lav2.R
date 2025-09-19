#' @title Convert Standardized RAM Back to Lavaan Matrices
#'
#' @description Converts a standardized RAM object back to lavaan-style matrix structure.
#' Optionally ensures correlations for `theta` and `psi` matrices.
#'
#' @param ram A RAM list containing standardized matrices (`A`, `S`, `F`, and `M`).
#' @param lav_mod A lavaan-style matrix list (e.g., GLIST) to be updated.
#' @param standardized Logical. If TRUE, forces symmetric matrices to correlation form (cov2cor).
#'
#' @return A modified lavaan-style matrix list with updated `lambda`, `beta`, `theta`, `psi`, and `alpha`.
#'
#' @details This function restores the internal lavaan model matrix structure from a RAM representation.
#' @keywords internal

RAM2Lav2 <- function(ram, lav_mod, standardized = FALSE) {
  ov_names <- rownames(lav_mod$theta)
  lv_names <- rownames(lav_mod$psi)
  lv_names <- setdiff(lv_names, ov_names)

  a_mat <- ram$A

  if (!is.null(lav_mod$lambda)) {
    lav_mod$lambda[,] <- 0
    lambda_rnames <- rownames(lav_mod$lambda)
    lambda_cnames <- colnames(lav_mod$lambda)
    lav_mod$lambda[lambda_rnames, lambda_cnames] <- a_mat[lambda_rnames, lambda_cnames, drop = FALSE]

    lambda1 <- intersect(lambda_rnames, lambda_cnames)
    lav_mod$lambda[lambda1, ] <- 0
    lav_mod$lambda[lambda1, lambda1] <- 1
  }

  if (!is.null(lav_mod$beta)) {
    lav_mod$beta[,] <- 0
    beta_names <- rownames(lav_mod$beta)
    lav_mod$beta[beta_names, beta_names] <- a_mat[beta_names, beta_names, drop = FALSE]
  }

  s_mat <- ram$S

  if (!is.null(lav_mod$theta)) {
    lav_mod$theta[,] <- 0
    theta_names <- rownames(lav_mod$theta)
    lav_mod$theta[theta_names, theta_names] <- s_mat[theta_names, theta_names, drop = FALSE]
    if (standardized) {
      tmp <- diag(lav_mod$theta)
      lav_mod$theta <- stats::cov2cor(lav_mod$theta)
      diag(lav_mod$theta) <- tmp
    }
    if (exists("lambda1")) {
      lav_mod$theta[lambda1, lambda1] <- 0
    }
  }

  if (!is.null(lav_mod$psi)) {
    lav_mod$psi[,] <- 0
    psi_names <- rownames(lav_mod$psi)
    lav_mod$psi[psi_names, psi_names] <- s_mat[psi_names, psi_names, drop = FALSE]
    if (standardized) {
      tmp <- diag(lav_mod$psi)
      lav_mod$psi <- stats::cov2cor(lav_mod$psi)
      diag(lav_mod$psi) <- tmp
    }
  }

  # 不处理 nu，仅处理 alpha
  if (!is.null(lav_mod$alpha)) {
    lav_mod$alpha[,] <- 0
    alpha_names <- rownames(lav_mod$alpha)
    lav_mod$alpha[,] <- t(ram$M[, alpha_names, drop = FALSE])
  }

  return(lav_mod)
}
