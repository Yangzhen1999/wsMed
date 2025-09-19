#' Extract Parameter Estimates
#'
#' @author Ivan Jacob Agaloos Pesigan
#'
#' @param object object of class `lavaan`.
#' @param est Numeric vector.
#'   If not `NULL`, the parameter estimates are updated.
#'   using the supplied vector.
#'   This is used to update the values in the parameter vector
#'   using new estimates.
#' @return Returns a list with the following elements
#' \describe{
#'   \item{est}{Parameter estimates.}
#'   \item{par_names}{Parameter names.}
#'   \item{def}{Defined parameters.}
#'   \item{ceq}{Equality constraints.}
#'   \item{cin}{Inequality constraints.}
#'   \item{fixed}{Fixed parameters.}
#' }
#'
#' @family Lavaan Helper Functions
#' @keywords lavHelper parameters internal
#' @noRd
ThetaHat2 <- function(object,
                      est = NULL) {
  # extract all estimates including fixed parameters
  thetahat_names_free <- names(
    lavaan::coef(object)
  )
  thetahat_eq <- paste0(
    object@ParTable$lhs,
    object@ParTable$op,
    object@ParTable$rhs
  )
  thetahat_names <- thetahat_eq
  label <- object@ParTable$label
  thetahat_names <- ifelse(
    label == "",
    yes = thetahat_names,
    no = label
  )
  for (i in seq_along(object@ParTable$free)) {
    if (object@ParTable$free[i] > 0) {
      thetahat_names[i] <- thetahat_names_free[
        object@ParTable$free[i]
      ]
    }
  }
  if (is.null(est)) {
    # extract estimates from parameter table
    thetahat_est <- object@ParTable$est
  } else {
    # update with supplied values
    thetahat_est <- est
  }
  return(
    ThetaHatDef2(
      object = object,
      thetahat_est = thetahat_est,
      thetahat_names_free = thetahat_names_free,
      thetahat_names = thetahat_names
    )
  )
}

ThetaHatDef2 <- function(object,
                         thetahat_est,
                         thetahat_names_free,
                         thetahat_names) {
  thetahat_fixed <- thetahat_def <- thetahat_cin <- thetahat_ceq <- rep(
    x = NA,
    times = length(thetahat_est)
  )
  for (i in seq_along(thetahat_est)) {
    if (object@ParTable$op[i] == "==") {
      thetahat_names[i] <- paste0(
        object@ParTable$lhs[i],
        "_ceq"
      )
      thetahat_ceq[i] <- object@ParTable$lhs[i]
    }
    if (
      object@ParTable$op[i] %in% c(
        ">",
        "<",
        ">=",
        "<="
      )
    ) {
      thetahat_names[i] <- paste0(
        object@ParTable$lhs[i],
        "_cin"
      )
      thetahat_cin[i] <- object@ParTable$lhs[i]
    }
    if (object@ParTable$op[i] == ":=") {
      thetahat_def[i] <- object@ParTable$lhs[i]
    }
    if (object@ParTable$free[i] == 0) {
      fixed <- TRUE
      if (
        object@ParTable$op[i] %in% c(
          ":=",
          "==",
          ">",
          "<",
          ">=",
          "<="
        )
      ) {
        fixed <- FALSE
      }
      if (fixed) {
        thetahat_fixed[i] <- thetahat_names[i]
      }
    }
  }
  names(
    thetahat_est
  ) <- thetahat_names
  return(
    list(
      est = thetahat_est,
      par_names = thetahat_names,
      def = thetahat_def[
        stats::complete.cases(thetahat_def)
      ],
      ceq = thetahat_ceq[
        stats::complete.cases(thetahat_ceq)
      ],
      cin = thetahat_cin[
        stats::complete.cases(thetahat_cin)
      ],
      fixed = thetahat_fixed[
        stats::complete.cases(thetahat_fixed)
      ],
      free = thetahat_names_free
    )
  )
}
