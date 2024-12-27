#' @title Within-Subject Mediation Analysis
#'
#' @description Performs two-condition within-subject mediation analysis using structural equation
#' modeling (SEM). This function provides both standardized and unstandardized results for mediation effects.
#' It also supports handling missing data using Full Information Maximum Likelihood (FIML) or
#' Multiple Imputation (MI), and generates Monte Carlo confidence intervals for the estimated mediation effects.
#'
#' @details The `WsMed` function is designed for analyzing within-subject mediation models, where the
#' mediator and outcome variables are measured before and after an intervention or under multiple
#' conditions. Key features include:
#'
#' - **Data preprocessing**: Automatically computes difference scores and averages for mediator and
#' outcome variables to facilitate within-subject analysis.
#'
#' - **Model construction**: Supports different mediation model types:
#'   - `"P"`: Parallel mediation.
#'   - `"CN"`: Chained mediation.
#'   - `"CP"`/`"PC"`: Combined parallel and chained mediation.
#'
#' - **Missing data handling**:
#'   - `"DE"`: Deletes rows with missing data.
#'   - `"FIML"`: Uses Full Information Maximum Likelihood for missing data.
#'   - `"MI"`: Conducts multiple imputations (requires the `mice` package).
#'
#' - **Monte Carlo analysis**: Generates Monte Carlo confidence intervals for mediation effects.
#'
#' - **Standardized results**: Optionally computes standardized effect sizes and confidence intervals.
#'
#' ## Workflow
#' The function follows these main steps:
#' 1. Data preprocessing.
#' 2. Model construction.
#' 3. Model fitting.
#' 4. Monte Carlo analysis (optional).
#' 5. Standardization of results (optional).
#'
#' ## Supported Model Types
#' The `form` parameter allows you to select the type of mediation model:
#' - `"P"`: Parallel mediation.
#' - `"CN"`: Chained mediation.
#' - `"CP"`/`"PC"`: Combined parallel and chained mediation.
#'
#' ## Missing Data Strategies
#' The `Na` parameter determines how missing data are handled:
#' - `"DE"`: Delete rows with missing data (default).
#' - `"FIML"`: Use Full Information Maximum Likelihood (requires `lavaan`).
#' - `"MI"`: Perform multiple imputations (requires the `mice` package).
#'
#' @param data A data frame containing the input data.
#' @param M_before A character vector of column names representing the mediator variables measured "before."
#' @param M_after A character vector of column names representing the mediator variables measured "after."
#' @param Y_before A character string representing the outcome variable measured "before."
#' @param Y_after A character string representing the outcome variable measured "after."
#' @param form A string specifying the type of mediation model (`"P"`, `"CN"`, `"CP"`, or `"PC"`). Defaults to `"P"`.
#' @param standardized Logical. If `TRUE`, standardized effects and confidence intervals are computed. Defaults to `FALSE`.
#' @param Na A string specifying the missing data handling method (`"DE"`, `"FIML"`, or `"MI"`). Defaults to `"DE"`.
#' @param bootstrap An integer specifying the number of bootstrap samples for the `"DE"` method. Defaults to `1000`.
#' @param iseed An integer for setting the random seed. Defaults to `123`.
#' @param se A string specifying the method for computing standard errors (`"standard"` or `"bootstrap"`). Defaults to `"standard"`.
#' @param R An integer specifying the number of Monte Carlo repetitions. Defaults to `20000L`.
#' @param alpha A numeric vector specifying the significance levels for confidence intervals. Defaults to `c(0.001, 0.01, 0.05)`.
#' @param m An integer specifying the number of imputations for the `"MI"` method. Defaults to `5`.
#' @param method A string specifying the imputation method for the `"MI"` method (e.g., `"pmm"`). Defaults to `"pmm"`.
#' @param decomposition A string specifying the decomposition method for covariance matrices. Defaults to `"eigen"`.
#' @param pd Logical. If `TRUE`, checks the positive definiteness of covariance matrices. Defaults to `TRUE`.
#' @param tol A numeric value for the tolerance used in positive definiteness checks. Defaults to `1e-06`.
#' @param seed An integer for setting the random seed during Monte Carlo simulations. Defaults to `123`.
#' @param alphastd A numeric value specifying the significance level for standardized confidence intervals. Defaults to `0.05`.
#'
#' @return A list containing the following components:
#' - `prepared_data`: The preprocessed dataset.
#' - `model_summary`: Summary statistics of the fitted SEM model.
#' - `lavaan_fit`: The fitted SEM model object.
#' - `sem_model`: The constructed SEM model syntax.
#' - `mi_result`: Monte Carlo results for the multiple imputation method (if applicable).
#' - `fiml_result`: Monte Carlo results for the FIML method (if applicable).
#' - `std_result`: Standardized results for the `"DE"` method (if applicable).
#' - `std_mi_result`: Standardized results for the MI method (if applicable).
#' - `std_fiml_result`: Standardized results for the FIML method (if applicable).
#'
#' @examples
#' # Simulated example dataset
#' data(example_data)
#' # example 1
#' # parallel mediation model with unstandardized effects
#' result1 <- WsMed(
#'   data = example_data,
#'   M_before = c("A2", "B2"),
#'   M_after = c("A1", "B1"),
#'   Y_before = "C2",
#'   Y_after = "C1",
#'   form = "P",
#'   standardized = FALSE,
#' )
#' print(result1)
#'
#' @importFrom semhelpinghands standardizedSolution_boot_ci
#' @export

WsMed <- function(data,
                  M_before,
                  M_after,
                  Y_before,
                  Y_after,
                  form = "P",
                  standardized = FALSE,
                  Na = "DE",
                  bootstrap = 1000,
                  iseed = 123,
                  se = "boot",
                  R = 20000L,  # Monte Carlo 重复次数
                  alpha = c(0.001, 0.01, 0.05),  # 显著性水平
                  m = 5,  # 插补次数
                  method = "pmm",  # 插补方法
                  decomposition = "eigen",
                  pd = TRUE,
                  tol = 1e-06,
                  seed = 123,
                  alphastd = 0.05) {

  if (Na %in% c("MI", "FIML") && all(stats::complete.cases(data))) {
    message("No missing values detected in the data.")
    Na <- "DE"
  }

  if (Na == "DE") {
    data <- stats::na.omit(data)}

  # Step 1: 数据预处理
  prepared_data <- PrepareData(data = data,
                               M_before = M_before,
                               M_after = M_after,
                               Y_before = Y_before,
                               Y_after = Y_after)

  # Step 2: 构建模型
  # P is parallel mediation, CN is chained mediation, CP/PC is parallel + chain mediation
  if (form == "P") {
    sem_model <- GenerateModelP(prepared_data)
  } else if (form == "CP") {
    sem_model <- GenerateModelCP(prepared_data)
  } else if (form == "PC") {
    sem_model <- GenerateModelPC(prepared_data)
  } else if (form == "CN") {
    sem_model <- GenerateModelCN(prepared_data)
  } else {
    stop("Invalid 'form' parameter. Use 'CP', 'PC' or 'CN'.")
  }

  # fit the model
  if (Na == "DE") {
    # 删除缺失值的模型拟合
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      se = se,
      bootstrap = bootstrap,
      iseed = iseed
    )
  } else if (Na == "FIML") {
    # 使用 FIML 方法处理缺失值
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      missing = "fiml",
    )
  } else if (Na == "MI") {
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
    )
    if (!inherits(fit, "lavaan")) {
      stop("Model fitting failed. Check your input model and data.")
    }
  }

  # Monte Carlo
  mi_result <- NULL
  fiml_result <- NULL
  if (Na == "MI") {
    # Step 4: MCMI 分析（可选）
    mi_result <- RunMCMIAnalysis(
      data_missing = data,
      m = m,
      method = method,
      seed = seed,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after,
      sem_model = sem_model,
      Na = Na,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol
    )
  }
  if (Na == "FIML"){
    fiml_result <- MC(fit,
                      R = R,
                      alpha = alpha)
  }

  # Step 5: 标准化结果
  std_result <- NULL
  std_mi_result <- NULL
  std_fiml_result <- NULL

  if (standardized){
    if (Na == "DE") {
      std_result <- semhelpinghands::standardizedSolution_boot_ci(fit)
    }
    if (Na == "MI") {
      std_mi_result <- semmcci::MCStd(mi_result, alpha = alphastd)
    }
    if (Na == "FIML") {
      std_fiml_result <- semmcci::MCStd(fiml_result, alpha = alphastd)
    }
  }
  # Step 6: 返回结果
  return(list(
    prepared_data = prepared_data,
    model_summary = summary(fit, fit.measures = TRUE, standardized = standardized),
    lavaan_fit = fit,
    sem_model = sem_model,
    mi_result = mi_result,
    fiml_result = fiml_result,
    std_result = std_result,
    std_mi_result = std_mi_result,
    std_fiml_result = std_fiml_result
  ))
}
