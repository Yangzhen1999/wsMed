#' @title Impute missing data using multiple imputation
#'
#' @description The `ImputeData` function performs multiple imputation on a data frame with missing values using the \code{mice} package. It handles missing data by creating multiple imputed datasets based on a specified imputation method and returns a list of completed data frames.
#'
#' @details This function replaces specified missing value placeholders (e.g., \code{-999}) with \code{NA}, and then applies the multiple imputation by chained equations (MICE) procedure to generate multiple imputed datasets. It supports flexible imputation methods and allows for specifying a custom predictor matrix.
#'
#' @param data_missing A data frame containing missing values to be imputed. The function replaces values coded as \code{-999} with \code{NA} before imputation.
#' @param m An integer specifying the number of imputed datasets to generate.
#' @param method A character string specifying the imputation method. Default is \code{"pmm"} (predictive mean matching).
#' @param seed An integer for setting the random seed to ensure reproducibility. Default is \code{123}.
#' @param predictorMatrix An optional matrix specifying the predictor structure for the imputation model. Default is \code{NULL}, meaning that the function will use the default predictor matrix created by \code{mice}.
#'
#' @return A list of \code{m} imputed data frames.
#'
#' @author
#' Wendie Yang, Shufai Cheung
#'
#' @examples
#' # Example data with missing values
#' data <- data.frame(
#'   M1 = c(rnorm(99), rep(NA, 1)),
#'   M2 = c(rnorm(99), rep(NA, 1)),
#'   Y1 = rnorm(100),
#'   Y2 = rnorm(100)
#' )
#' # Perform multiple imputation
#' imputed_data_list <- ImputeData(data, m = 5)
#' # Display the first imputed dataset
#' head(imputed_data_list[[1]])
#'
#' @importFrom mice mice complete
#' @export

ImputeData <- function(data_missing,
                       m      = 5,
                       method = "pmm",
                       seed   = 123,
                       predictorMatrix = NULL) {


  if (!is.data.frame(data_missing))
    stop("Input data must be a data.frame")   # Validate the data type first


  `%||%` <- function(a,b) if (is.null(a)) b else a
  nullfile <- if (.Platform$OS.type == "windows") "NUL" else "/dev/null"

  # Preprocess the data
  data_missing[data_missing == -999] <- NA
  if (!is.data.frame(data_missing))
    stop("Input data must be a data.frame")
  if (!all(vapply(data_missing,
                  function(z) is.numeric(z) || is.factor(z),
                  logical(1))))
    stop("All columns must be numeric or factor")

  ## ---- 1 predictorMatrix ----------------------------------------------
  if (is.null(predictorMatrix))
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.10)

  # Expand imputation methods to one entry per variable
  if (is.null(method)) {
    method <- vapply(data_missing, function(z) {
      if (is.numeric(z)) {
        "pmm"                   # Predictive mean matching for continuous variables
      } else if (is.factor(z)) {
        if (nlevels(z) == 2) {
          "logreg"              # Logistic regression for binary factors
        } else {
          "polyreg"             # Multinomial logistic regression for factors with more than two levels
        }
      } else {
        stop("Unsupported variable type for imputation: must be numeric or factor.")
      }
    }, character(1))
  } else if (length(method) == 1L) {
    method <- rep(method, ncol(data_missing))
  } else if (length(method) != ncol(data_missing)) {
    stop("Length of 'method' must be 1 or equal to number of variables")
  }
  names(method) <- names(data_missing)


  # Run mice without console output
  imp <- local({
    zz <- file(nullfile, open = "wt")
    sink(zz)                      # stdout
    sink(zz, type = "message")    # stderr
    on.exit({ sink(type = "message"); sink(); close(zz) }, add = TRUE)

    suppressWarnings(
      suppressMessages(
        mice::mice(
          data_missing,
          m               = m,
          method          = method,
          seed            = seed,
          predictorMatrix = predictorMatrix,
          printFlag       = FALSE)))
  })

  # Capture the printed summary of the mids object
  summary_imp <- local({
    zz <- file(nullfile, open = "wt")
    sink(zz)
    sink(zz, type = "message")
    on.exit({ sink(type = "message"); sink(); close(zz) }, add = TRUE)

    summary(imp)        # Return the summary while capturing its printed output
  })

  # Return results
  imputed_list <- lapply(mice::complete(imp, "all"), as.data.frame)

  list(
    mids              = imp,            # Imputation object
    imputed_data_list = imputed_list,   # List of completed data frames
    summary           = summary_imp     # Captured summary
  )
}


