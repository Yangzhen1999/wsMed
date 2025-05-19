#' @title Prepare Data with Missing Values for Mediation Analysis
#'
#' @description Handles missing values in the dataset through multiple imputation
#' and prepares the imputed datasets for within-subject mediation analysis. The function
#' imputes missing data, processes each imputed dataset, and provides diagnostics for the imputation process.
#'
#' @details This function is designed to preprocess datasets with missing values for mediation analysis.
#' It performs the following steps:
#'
#' - **Multiple Imputation**: Uses specified imputation methods (e.g., predictive mean matching) to generate
#' `m` imputed datasets.
#'
#' - **Data Preparation**: Applies [PrepareData()] to each of the `m` imputed datasets to calculate difference scores
#' and centered averages for mediators and the outcome variable.
#'
#' - **Imputation Diagnostics**: Provides summary diagnostics for the imputation process, including
#' information about missing data patterns and convergence.
#'
#' This function integrates imputation and data preparation, ensuring that the resulting datasets
#' are ready for subsequent mediation analysis.
#'
#' @param data_missing A data frame containing the raw dataset with missing values.
#' @param m An integer specifying the number of imputations to perform. Default is `5`.
#' @param method A character string specifying the imputation method. Default is `"pmm"`
#' (predictive mean matching).
#' @param seed An integer specifying the random seed for reproducibility. Default is `123`.
#' @param M_C1 A character vector of column names representing mediators "before" the intervention.
#' @param M_C2 A character vector of column names representing mediators "after" the intervention.
#' Must match the length of `M_C1`.
#' @param Y_C1 A character string representing the column name of the outcome variable "before" the intervention.
#' @param Y_C2 A character string representing the column name of the outcome variable "after" the intervention.
#'
#' @return A list containing:
#' - `processed_data_list`: A list of `m` data frames, each representing an imputed and processed dataset,
#' ready for within-subject mediation analysis.
#' - `imputation_summary`: A summary of the imputation process, including diagnostics and convergence information.
#'
#' @seealso [PrepareData()], [ImputeData()], [wsMed()]
#'
#' @examples
#' # Example dataset with missing values
#' data(example_data)
#' set.seed(123)
#' example_dataN <- mice::ampute(
#'    data = example_data,
#'    prop = 0.1,
#'    )$amp
#'
#' # Prepare the dataset with multiple imputations
#' prepared_missing_data <- PrepareMissingData(
#'   data_missing = example_dataN,
#'   m = 5,
#'   method = "pmm",
#'   M_C1 = c("A2", "B2"),
#'   M_C2 = c("A1", "B1"),
#'   Y_C1 = "C2",
#'   Y_C2 = "C1",
#' )
#'
#' # Access processed datasets
#' processed_data_list <- prepared_missing_data$processed_data_list
#' imputation_summary <- prepared_missing_data$imputation_summary
#'
#' @export

PrepareMissingData <- function(data_missing,
                               m = 5,
                               method = "pmm",
                               seed = 123,
                               M_C1,
                               M_C2,
                               Y_C1,
                               Y_C2) {
  if (length(M_C1) != length(M_C2)) {
    stop("Error in PrepareMissingData: M_C1 and M_C2 must have the same length.")
  }

  if (!(Y_C1 %in% colnames(data_missing)) || !(Y_C2 %in% colnames(data_missing))) {
    stop("Error in PrepareMissingData: Y_C1 or Y_C2 is missing in the dataset.")
  }

  imputed_result <- ImputeData(
    data_missing = data_missing,
    m = m,
    method = method,
    seed = seed
  )

  imputed_data_list <- imputed_result$imputed_data_list

  processed_data_list <- lapply(imputed_data_list, function(imputed_data) {
    PrepareData(
      data = imputed_data,
      M_C1 = M_C1,
      M_C2 = M_C2,
      Y_C1 = Y_C1,
      Y_C2 = Y_C2
    )
  })

  return(list(
    mids = imputed_result$mids,
    processed_data_list = processed_data_list,
    imputation_summary = imputed_result$summary
  ))
}
