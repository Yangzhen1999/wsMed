#' @title Convert Lavaan Model to RAM Matrices
#'
#' @description Converts a lavaan-style matrix list into RAM (Reticular Action Model) format,
#' including the A (asymmetric paths), S (symmetric paths), F (filter matrix), and M (means/intercepts) matrices.
#'
#' @param lav_mod A named list of lavaan matrices including `lambda`, `beta`, `theta`, `psi`, and `alpha`.
#'
#' @return A list with components:
#' \describe{
#'   \item{A}{Asymmetric path matrix (including factor loadings and structural paths)}
#'   \item{S}{Symmetric path matrix (variances and covariances)}
#'   \item{F}{Filter matrix mapping latent and observed variables}
#'   \item{M}{Row vector of intercepts/means}
#' }
#'
#' @details This function reorganizes the lavaan-style matrices into the RAM representation,
#' commonly used for model standardization and transformation.
#' @keywords internal
Lav2RAM2 <- function(lav_mod) {
  ov_names <- rownames(lav_mod$theta)
  lv_names <- rownames(lav_mod$psi)
  lv_names <- lv_names[!(lv_names %in% ov_names)]
  all_names <- c(ov_names, lv_names)
  p <- length(ov_names)
  q <- length(lv_names)
  k <- length(all_names)

  # Initialize A, S, F
  a_mat <- matrix(0, k, k, dimnames = list(all_names, all_names))
  s_mat <- matrix(0, k, k, dimnames = list(all_names, all_names))
  f_mat <- cbind(diag(p), matrix(0, nrow = p, ncol = q))
  colnames(f_mat) <- all_names
  rownames(f_mat) <- ov_names

  # Initialize M (intercepts)
  m_mat <- matrix(0, nrow = 1, ncol = k)
  colnames(m_mat) <- all_names

  # Theta → S
  s_mat[rownames(lav_mod$theta), rownames(lav_mod$theta)] <- lav_mod$theta

  # Psi → S
  s_mat[rownames(lav_mod$psi), rownames(lav_mod$psi)] <- lav_mod$psi

  # Lambda → A
  a_mat[rownames(lav_mod$lambda), colnames(lav_mod$lambda)] <- lav_mod$lambda

  # Beta → A
  if (!is.null(lav_mod$beta)) {
    a_mat[rownames(lav_mod$beta), colnames(lav_mod$beta)] <- lav_mod$beta
  }

  # Only use alpha (no nu)
  if (!is.null(lav_mod$alpha)) {
    m_mat[, rownames(lav_mod$alpha)] <- lav_mod$alpha
  }

  return(list(
    A = a_mat,
    S = s_mat,
    F = f_mat,
    M = m_mat
  ))
}
