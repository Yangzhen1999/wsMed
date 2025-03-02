#' @title Process Monte Carlo Samples for Defined Parameters in SEM
#'
#' @description A wrapper for the internal `.MCDef()` function from the `semmcci` package.
#' This function processes Monte Carlo samples to compute defined parameters for structural
#' equation modeling (SEM).
#'
#' @details This function takes Monte Carlo samples of parameter estimates and a fitted SEM model
#' object to compute the defined parameters (e.g., indirect effects or user-defined contrasts)
#' based on the model syntax. It is particularly useful for examining derived quantities in SEM
#' analyses using Monte Carlo methods.
#'
#' @param object A fitted `lavaan` SEM model object.
#' @param thetahat A numeric vector of parameter estimates.
#' @param thetahatstar_orig A matrix of Monte Carlo samples, where rows represent samples and columns
#' represent parameters.
#'
#' @return A matrix of computed defined parameters for each Monte Carlo sample.
#'
#' @seealso [MCMI2()], [RunMCMIAnalysis()]
#'
#' @examples NULL
#' @export

MCDefWrapper <- function(object,
                   thetahat,
                   thetahatstar_orig) {
  # generate defined parameters
  if (length(thetahat$def) > 0) {
    def <- function(i) {
      tryCatch(
        {
          return(
            object@Model@def.function(
    thetahatstar_orig[
      i,
    ]
            )
          )
        },
    warning = function(w) {
      return(NA)
    },
    error = function(e) {
      return(NA)
    }
      )
    }
    thetahatstar_def <- lapply(
      X = seq_len(
        dim(
          thetahatstar_orig
        )[1]
      ),
      FUN = def
    )
    thetahatstar_def <- do.call(
      what = "rbind",
      args = thetahatstar_def
    )
    thetahatstar <- cbind(
      thetahatstar_orig,
      thetahatstar_def
    )
  } else {
    thetahatstar <- thetahatstar_orig
  }
  # generate equality
  if (length(thetahat$ceq) > 0) {
    ceq <- function(i) {
      out <- object@Model@ceq.function(
    thetahatstar[
      i,
    ]
      )
      names(out) <- paste0(
        thetahat$ceq,
        "_ceq"
      )
      return(out)
    }
    thetahatstar_ceq <- lapply(
      X = seq_len(
        dim(
          thetahatstar
        )[1]
      ),
      FUN = ceq
    )
    thetahatstar_ceq <- do.call(
      what = "rbind",
      args = thetahatstar_ceq
    )
    thetahatstar <- cbind(
      thetahatstar,
      thetahatstar_ceq
    )
  }
  # generate inequality
  if (length(thetahat$cin) > 0) {
    cin <- function(i) {
      out <- object@Model@cin.function(
    thetahatstar[
      i,
    ]
      )
      names(out) <- paste0(
        thetahat$cin,
        "_cin"
      )
      return(out)
    }
    thetahatstar_cin <- lapply(
      X = seq_len(
        dim(
          thetahatstar
        )[1]
      ),
      FUN = cin
    )
    thetahatstar_cin <- do.call(
      what = "rbind",
      args = thetahatstar_cin
    )
    thetahatstar <- cbind(
      thetahatstar,
      thetahatstar_cin
    )
  }
  # generate fixed
  if (length(thetahat$fixed) > 0) {
    fixed <- matrix(
      NA,
      ncol = length(
        thetahat$fixed
      ),
      nrow = dim(
        thetahatstar
      )[1]
    )
    colnames(
      fixed
    ) <- thetahat$fixed
    for (i in seq_len(dim(fixed)[2])) {
      fixed[
        ,
        i
      ] <- thetahat$est[
        thetahat$fixed[[i]]
      ]
    }
    thetahatstar <- cbind(
      thetahatstar,
      fixed
    )
  }
  # rearrange
  return(
    thetahatstar[
      ,
      thetahat$par_names
    ]
  )
}
