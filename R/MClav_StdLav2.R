#' @title Standardize Parameter Estimates in a Lavaan Model
#'
#' @description Applies full standardization (including intercepts) to a fitted lavaan model
#' by converting to RAM form, performing standardization, and converting back to lavaan matrix structure.
#'
#' @param est A numeric vector of parameter estimates (free parameters).
#' @param object A fitted lavaan model object (used to extract model structure).
#'
#' @return A numeric vector of fully standardized parameter estimates (including intercepts and defined parameters).
#'
#' @details The function extracts the model's RAM representation via `Lav2RAM2`, applies `StdRAM2` standardization,
#' restores the standardized GLIST via `RAM2Lav2`, and retrieves standardized user-defined parameter estimates
#' with `lav_model_get_parameters()`.
#' @keywords internal

StdLav2 <- function(est, object) {
  lav_model <- object@Model

  # Set parameters: apply current est vector to model
  lav_model_new <- lavaan::lav_model_set_parameters(
    lavmodel = lav_model,
    x = est
  )

  # Extract GLIST (per group), apply dimnames
  glist_new <- lav_model_new@GLIST
  for (i in seq_along(glist_new)) {
    dimnames(glist_new[[i]]) <- lav_model@dimNames[[i]]
  }

  ng <- lav_model@nblocks
  nmat <- lav_model@nmat
  gp_labels <- object@Data@group.label
  if (length(gp_labels) == 0) {
    gp_labels <- "single_group"
  }

  out <- vector("list", ng)
  isum <- 0
  for (i in seq_len(ng)) {
    out[[i]] <- glist_new[seq_len(nmat[i]) + isum]
    isum <- isum + nmat[i]
  }
  names(out) <- unlist(gp_labels)
  glist_new <- out

  # ---- Use updated standardization pipeline ----

  # 1. Extract RAM
  ram_list <- lapply(glist_new, Lav2RAM2)  # Your new version

  # 2. Standardize RAM (A, S, M)
  ram_std_list <- lapply(ram_list, StdRAM2)

  # 3. Convert standardized RAM back to lavaan-style matrix list
  glist_std <- mapply(
    FUN = RAM2Lav2,  # use your updated function (list-style)
    ram = ram_std_list,
    lav_mod = glist_new,
    MoreArgs = list(standardized = TRUE),
    SIMPLIFY = FALSE
  )

  # 4. Update GLIST
  lav_model_new@GLIST <- if (ng == 1) {
    glist_std[[1]]
  } else {
    unlist(glist_std, recursive = FALSE)
  }

  # 5. Extract all user-defined parameter values (standardized)
  lavaan::lav_model_get_parameters(
    lavmodel = lav_model_new,
    type = "user",
    extra = TRUE
  )
}
