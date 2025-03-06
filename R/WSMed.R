#' @title Within-Subject Mediation Analysis
#'
#' @description Performs two-condition within-subject mediation analysis using structural equation
#' modeling (SEM). This function provides both standardized and unstandardized results for mediation effects.
#' It also supports handling missing data using Full Information Maximum Likelihood (FIML) or
#' Multiple Imputation (MI), and generates Monte Carlo confidence intervals for the estimated mediation effects.
#'
#' @details The `wsMed` function is designed for analyzing within-subject mediation models, where the
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
#' @param fixed.x Logical. If `TRUE`, the x variables are fixed. Default is `FALSE`.

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
#' result1 <- wsMed(
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

wsMed <- function(data,
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
                  fixed.x = FALSE,
                  alpha = c(0.01, 0.05),  # 显著性水平
                  m = 5,  # 插补次数
                  method = "pmm",  # 插补方法
                  decomposition = "eigen",
                  pd = TRUE,
                  tol = 1e-06,
                  seed = 123,
                  alphastd = c(0.01, 0.05)) {

  # 输入验证
  {
    # 检查 data
    if (is.null(data) || length(data) == 0) {
      stop("Error: 'data' cannot be NULL or empty.")
    }
    if (!is.data.frame(data)) {
      stop("Error: 'data' must be a data frame.")
    }

    # 检查 M_before 和 M_after
    if (is.null(M_before) || is.null(M_after)) {
      stop("Error: 'M_before' and 'M_after' cannot be NULL. Please provide valid column names.")
    }
    if (length(M_before) != length(M_after)) {
      stop("Error: The lengths of 'M_before' and 'M_after' must match.")
    }

    # 检查 Y_before 和 Y_after
    if (is.null(Y_before) || is.null(Y_after)) {
      stop("Error: 'Y_before' and 'Y_after' cannot be NULL. Please provide valid column names.")
    }

    # 检查必需列
    required_columns <- c(M_before, M_after, Y_before, Y_after)
    missing_columns <- required_columns[!required_columns %in% colnames(data)]
    if (length(missing_columns) > 0) {
      stop(paste("Error: Missing columns in data:", paste(missing_columns, collapse = ", ")))
    }

    # 验证 form 参数
    if (!form %in% c("P", "CN", "CP", "PC")) {
      stop("Error: Invalid 'form' parameter. Use 'P', 'CN', 'CP', or 'PC'.")
    }

    # 验证 Na 参数
    if (!Na %in% c("DE", "FIML", "MI")) {
      stop("Error: Invalid 'Na' parameter. Use 'DE', 'FIML', or 'MI'.")
    }

    # 验证 bootstrap, R, 和 m
    if (!is.numeric(bootstrap) || bootstrap < 0) {
      stop("Error: 'bootstrap' must be a non-negative integer.")
    }
    if (!is.numeric(R) || R <= 0) {
      stop("Error: 'R' must be a positive integer.")
    }
    if (!is.numeric(m) || m <= 0) {
      stop("Error: 'm' must be a positive integer.")
    }

    # 处理缺失值
    if (Na %in% c("MI", "FIML")) {
      total_missing <- sum(is.na(data))
      if (total_missing == 0) {
        message("No missing values detected in the data. Switching to 'DE'.")
        Na <- "DE"
      }
    }
    if (Na == "DE") {
      total_missing <- sum(is.na(data))
      if (total_missing > 0) {
        warning("The dataset contains missing values. Consider using 'Na = MI' or 'Na = FIML' to handle them")
      }
      data <- stats::na.omit(data)
    }

    # 验证调节变量数量
    num_mediators <- length(M_before)
    if (form == "CN" && num_mediators < 2) {
      stop("Error: For 'CN' models, the number of mediators must be at least 2.")
    }
    if (form %in% c("PC", "CP") && num_mediators < 3) {
      stop("Error: For 'PC' and 'CP' models, the number of mediators must be at least 3.")
    }
  }


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
      iseed = iseed,
      fixed.x = fixed.x,
      warn = FALSE
    )
  } else if (Na == "FIML") {
    # 使用 FIML 方法处理缺失值
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      missing = "fiml",
      fixed.x = fixed.x,
      warn = FALSE
    )
  } else if (Na == "MI") {
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      fixed.x = fixed.x,
      warn = FALSE
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
  # 初始化结果变量
  std_result <- NULL
  std_mi_result <- NULL
  std_fiml_result <- NULL

  # 生成标准化结果
  if (standardized) {
    tryCatch({
      if (Na == "DE") {
        std_result <- semhelpinghands::standardizedSolution_boot_ci(fit)
        if (is.null(std_result)) {
          warning("Standardized solution for DE method returned NULL.")
        }
      }

      if (Na == "MI") {
        if (is.null(mi_result)) {
          warning("MI result is NULL, cannot compute standardized solution.")
        } else {
          std_mi_result <- tryCatch(
            semmcci::MCStd(mi_result, alpha = alphastd),
            error = function(e) {
              warning("Standardized solution for MI failed: ", e$message)
              NULL
            }
          )
        }
      }

      if (Na == "FIML") {
        if (is.null(fiml_result)) {
          warning("FIML result is NULL, cannot compute standardized solution.")
        } else {
          std_fiml_result <- tryCatch(
            semmcci::MCStd(fiml_result, alpha = alphastd),
            error = function(e) {
              warning("Standardized solution for FIML failed: ", e$message)
              NULL
            }
          )
        }
      }
    }, error = function(e) {
      warning("Error during standardized solution generation: ", e$message)
    })
  }


  input_vars <- list(
    M_before = M_before,
    M_after = M_after,
    Y_before = Y_before,
    Y_after = Y_after
  )

  paras <- list(
    alpha = alpha,  # 显著性水平
    m = m,  # 插补次数
    method = method,  # 插补方法
    decomposition = decomposition,
    pd = pd,
    tol = tol,
    seed = seed,
    alphastd = alphastd
  )

  out <- list(
    prepared_data = prepared_data,
    model_summary = summary(fit, fit.measures = TRUE, standardized = standardized),
    lavaan_fit = fit,
    sem_model = sem_model,
    mi_result = mi_result,
    fiml_result = fiml_result,
    std_result = std_result,
    std_mi_result = std_mi_result,
    std_fiml_result = std_fiml_result,
    input_vars = input_vars,
    alphastd = alphastd,
    alpha = alpha,
    Na = Na,
    iseed = iseed,
    paras = paras,
    standardized = standardized
  )

  # Step 6: 返回结果
  class(out) <- "wsMed"
  return(out)
}
