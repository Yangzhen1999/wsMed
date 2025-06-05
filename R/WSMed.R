#' @title Within-Subject Mediation Analysis
#'
#' @description
#' Performs two-condition within-subject mediation analysis using structural equation modeling (SEM).
#' This function supports multiple types of mediation structures, handles missing data via deletion,
#' FIML, or multiple imputation, and provides both bootstrap and Monte Carlo confidence intervals for
#' unstandardized and standardized effects.
#'
#' @details
#' The `wsMed` function is designed for analyzing within-subject mediation models where both mediator
#' and outcome variables are measured under two conditions (e.g., before vs. after intervention).
#'
#' Key features:
#'
#' - **Data preprocessing**: Automatically computes difference scores and condition-mean scores.
#'
#' - **Model construction**: Supports four types of mediation models:
#'   - `"P"`: Parallel mediation
#'   - `"CN"`: Chained mediation
#'   - `"CP"`: Chained-to-parallel mediation
#'   - `"PC"`: Parallel-to-chained mediation
#'
#' - **Missing data strategies**:
#'   - `"DE"`: Listwise deletion of missing values.
#'   - `"FIML"`: Full Information Maximum Likelihood.
#'   - `"MI"`: Multiple imputation using the \pkg{mice} package.
#'
#' - **Inference options**:
#'   - `ci_method`: Choose `"bootstrap"` or `"mc"` (Monte Carlo) for confidence interval estimation.
#'     For `"MI"`, only `"mc"` is supported.
#'   - `MCmethod`: For FIML, choose how Monte Carlo is performed:
#'     - `"mc"` (default): uses `semmcci::MC()`
#'     - `"bootSD"`: uses custom simulation with bootstrap SD correction.
#'
#' - **Standardized results**: Optional standardized estimates with bootstrap or Monte Carlo CI.
#'
#' ## Workflow
#' The function proceeds through the following steps:
#' 1. Data preprocessing
#' 2. Model specification
#' 3. Model fitting
#' 4. Confidence interval estimation (bootstrap or Monte Carlo)
#' 5. Optional standardization of results
#'
#' @param data A data frame containing the input data.
#' @param M_C1 Character vector. Mediator variables under condition 1 (e.g., "before").
#' @param M_C2 Character vector. Mediator variables under condition 2 (e.g., "after").
#' @param Y_C1 Character. Outcome variable under condition 1.
#' @param Y_C2 Character. Outcome variable under condition 2.
#' @param form Character. Mediation model type: `"P"`, `"CN"`, `"CP"`, or `"PC"`. Defaults to `"P"`.
#' @param standardized Logical. Whether to compute standardized estimates. Defaults to `FALSE`.
#' @param Na Character. Missing data method: `"DE"`, `"FIML"`, or `"MI"`. Defaults to `"DE"`.
#' @param ci_method Character. Confidence interval method: `"bootstrap"` or `"mc"`. If `NULL`, defaults to:
#' `"mc"` for `"MI"` amd `"FIML"`, `"bootstrap"` for `"DE"`.
#' @param MCmethod Character. If `Na = "FIML"` and `ci_method = "mc"`, choose `"mc"` (default) or `"bootSD"`.
#' @param bootstrap Integer. Number of bootstrap samples (used for `"bootstrap"` CI). Defaults to `1000`.
#' @param iseed Integer. Random seed used in bootstrapping. Defaults to `123`.
#' @param boot_ci_type Character. Type of bootstrap CI: `"perc"`, `"bc"`, or `"bca.simple"`.
#' @param R Integer. Number of Monte Carlo repetitions. Defaults to `20000L`.
#' @param alpha Numeric vector. Significance levels for CI. Defaults to `c(0.01, 0.05)`.
#' @param mi_args A list of arguments used for multiple imputation (MI) and Monte Carlo inference with imputed data. The following fields can be specified:
#'   \describe{
#'     \item{\code{m}}{(integer) Number of imputations. Default is 5.}
#'     \item{\code{method}}{(character) Imputation method passed to \code{mice()}. Default is \code{"pmm"}.}
#'     \item{\code{decomposition}}{(character) Decomposition method used in Monte Carlo CI (\code{"eigen"}, \code{"chol"}, or \code{"svd"}). Default is \code{"eigen"}.}
#'     \item{\code{pd}}{(logical) Whether to check positive definiteness of covariance matrix. Default is \code{TRUE}.}
#'     \item{\code{tol}}{(numeric) Tolerance for positive-definiteness check. Default is \code{1e-6}.}
#'   }
#' @param moderation_args A list of arguments passed to compute conditional moderated effects. Includes:
#'   \describe{
#'     \item{\code{W_method}}{Method for defining moderator levels. Options: \code{"discrete"} or \code{"quantile"}.}
#'     \item{\code{W_values}}{Values or levels of the moderator variable for estimation. Default is \code{c(-1, 0, 1)}.}
#'     \item{\code{W_varname}}{Name of the moderator variable. Default is \code{"W1"}.}
#'     \item{\code{ci_level}}{Confidence level for intervals. Default is \code{0.95}.}
#'     \item{\code{digits}}{Number of digits to round results. Default is 3.}
#'   }
#'
#' @param jn_args A list of arguments passed to compute Johnson-Neyman regions (if \code{JN = TRUE}). Includes:
#'   \describe{
#'     \item{\code{JN}}{Logical. If \code{TRUE}, perform Johnson-Neyman analysis.}
#'     \item{\code{W_range}}{Range of moderator values to evaluate (e.g., \code{c(-3, 3)}).}
#'     \item{\code{resolution}}{Number of evaluation points in the range.}
#'     \item{\code{alpha}}{Significance level for confidence intervals. Default is \code{0.05}.}
#'     \item{\code{verbose}}{Whether to print diagnostic messages.}
#'   }
#' @param seed Integer. Random seed used in Monte Carlo simulation. Defaults to `123`.
#' @param alphastd Numeric. Significance level for standardized results. Defaults to `0.05`.
#' @param fixed.x Logical. Whether to treat predictors as fixed. Defaults to `FALSE`.
#' @param C_C1 Character vector of within-subject control variable names (condition 1).
#' @param C_C2 Character vector of within-subject control variable names (condition 2).
#' @param C Character vector of between-subject control variable names.
#' @param W A character vector specifying one or more moderator variable names.
#'   These variables will be centered (if needed) and used to create interaction
#'   terms with mediator-related predictors (e.g., \code{Mdiff} or \code{Mavg})
#'   in the SEM model. Default is \code{NULL}.
#' @param MP A character vector specifying which regression paths are moderated by
#'   the variables in \code{W}. Each element should indicate a target path, such as
#'   \code{"a1"}, \code{"b2"}, \code{"d_2_1"}, or \code{"cp"}:
#'   \itemize{
#'     \item \code{"a1"}, \code{"a2"}, etc.: Add \code{W} as predictors of \code{M1diff}, \code{M2diff}, etc.
#'     \item \code{"b1"}, \code{"b_1_2"}: Add interaction terms between \code{W} and \code{Mdiff} predictors in \code{Ydiff ~ ...}
#'     \item \code{"d1"}, \code{"d_1_2"}: Add interaction terms between \code{W} and \code{Mavg} predictors in \code{Ydiff ~ ...}
#'     \item \code{"cp"}: Include \code{W} directly in the regression for \code{Ydiff}, modeling moderation of the direct effect.
#'   }
#'   Default is \code{NULL}. Only effective when \code{W} is also specified.
#' @param store_boot_args A list of additional arguments passed to the internal bootstrap function
#'   \code{semboottools::store_boot()}. Typically used for advanced customization of bootstrap behavior.
#'   Not intended for general users.
#' @param ... Additional arguments passed to internal functions. Reserved for future extensions or developer use.

#' @return A list with class `"wsMed"` containing:
#' \describe{
#'   \item{prepared_data}{The preprocessed dataset used for model fitting.}
#'   \item{sem_model}{Lavaan model syntax used.}
#'   \item{lavaan_fit}{The fitted lavaan object.}
#'   \item{model_summary}{Summary statistics from lavaan.}
#'   \item{ustd_result}{Bootstrap-based unstandardized results (if applicable).}
#'   \item{mc_de_result}{Monte Carlo results for DE (if applicable).}
#'   \item{fiml_result}{Monte Carlo results for FIML.}
#'   \item{mi_result}{Monte Carlo results for MI.}
#'   \item{std_result}{Standardized bootstrap results (DE or FIML with bootstrap).}
#'   \item{std_fiml_result}{Standardized MC results for FIML.}
#'   \item{std_mi_result}{Standardized MC results for MI.}
#'   \item{input_vars}{Input variable names.}
#'   \item{paras}{Analysis parameters including alpha, m, method, etc.}
#'   \item{ci_method}{Chosen CI method.}
#'   \item{MCmethod}{Chosen MC computation method (for FIML).}
#' }
#'
#' @examples
#' data(example_data)
#' set.seed(123)
#' example_dataN <- mice::ampute(
#'  data = example_data,
#'   prop = 0.1,
#'   )$amp
#'
#' result <- wsMed(
#'   data = example_data,
#'   M_C1 = c("A2", "B2"),
#'   M_C2 = c("A1", "B1"),
#'   Y_C1 = "C1",
#'   Y_C2 = "C2",
#'   form = "P",
#'   Na = "MI",
#'   standardized = FALSE,
#'   ci_method = "mc",
#'   alpha = 0.05,
#'   alphastd = 0.05
#' )
#' print(result)
#'
#' @importFrom semboottools standardizedSolution_boot
#' @export

wsMed <- function(data,
                  M_C1,
                  M_C2,
                  Y_C1,
                  Y_C2,
                  C_C1 = NULL,
                  C_C2 = NULL,
                  C     = NULL,
                  W     = NULL,
                  MP    = NULL,
                  form = "P",
                  standardized = FALSE,
                  Na = "DE",
                  ci_method = NULL, # 用户不输入时留空
                  bootstrap = 1000,
                  iseed = 123,
                  boot_ci_type = "perc",
                  R = 20000L,  # Monte Carlo 重复次数
                  fixed.x = FALSE,
                  alpha = 0.05,  # 显著性水平
                  alphastd = 0.05,
                  seed = 123,
                  MCmethod = NULL,
                  mi_args = list(
                    m = 5,
                    method = "pmm",
                    decomposition = "eigen",
                    pd = TRUE,
                    tol = 1e-06
                  ),
                  mod_effect_args = list(),    # 调节路径主效应参数
                  store_boot_args = list(),
                  ...) {


  {# 展开 mi_args 到局部变量
    m             <- mi_args$m             %||% 5
    method        <- mi_args$method        %||% "pmm"
    decomposition <- mi_args$decomposition %||% "eigen"
    pd            <- mi_args$pd            %||% TRUE
    tol           <- mi_args$tol           %||% 1e-06
  }
  # 输入验证
  {
    # 检查 data
    if (is.null(data) || length(data) == 0) {
      stop("Error: 'data' cannot be NULL or empty.")
    }
    if (!is.data.frame(data)) {
      stop("Error: 'data' must be a data frame.")
    }

    # 检查 M_C1 和 M_C2
    if (is.null(M_C1) || is.null(M_C2)) {
      stop("Error: 'M_C1' and 'M_C2' cannot be NULL. Please provide valid column names.")
    }
    if (length(M_C1) != length(M_C2)) {
      stop("Error: The lengths of 'M_C1' and 'M_C2' must match.")
    }

    # 检查 Y_C1 和 Y_C2
    if (is.null(Y_C1) || is.null(Y_C2)) {
      stop("Error: 'Y_C1' and 'Y_C2' cannot be NULL. Please provide valid column names.")
    }

    # 检查必需列
    required_columns <- c(M_C1, M_C2, Y_C1, Y_C2)
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


    # 设置默认 ci_method 并验证合法性
    if (is.null(ci_method)) {
      ci_method <- switch(Na,
                          "MI" = "mc",
                          "FIML" = "mc",
                          "DE" = "bootstrap")
    } else {
      ci_method <- match.arg(ci_method, choices = c("bootstrap", "mc", "both"))

      # 加入逻辑限制提示
      if (Na == "MI" && ci_method == "bootstrap") {
        warning("CI method 'bootstrap' is not supported with MI. Defaulting to 'mc'.")
        ci_method <- "mc"
      } else if (Na == "MI" && ci_method == "both") {
        warning("For MI, only Monte Carlo CI is available. Bootstrap CI will be skipped.")
      }
    }


    # 检查 MCmethod 合法性
    # 设置默认 MCmethod 并验证
    if (is.null(MCmethod)) {
      MCmethod <- "mc"  # 默认使用 semmcci::MC()
    } else {
      if (!MCmethod %in% c("mc", "bootSD")) {
        stop("MCmethod must be either 'mc', 'bootSD', or NULL.")
      }
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
    }

    # 验证调节变量数量
    num_mediators <- length(M_C1)
    if (form == "CN" && num_mediators < 2) {
      stop("Error: For 'CN' models, the number of mediators must be at least 2.")
    }
    if (form %in% c("PC", "CP") && num_mediators < 3) {
      stop("Error: For 'PC' and 'CP' models, the number of mediators must be at least 3.")
    }
  }


  # Step 1: 数据预处理
  prepared_data <- PrepareData(data = data,
                               M_C1 = M_C1,
                               M_C2 = M_C2,
                               Y_C1 = Y_C1,
                               Y_C2 = Y_C2,
                               C_C1 = C_C1,
                               C_C2 = C_C2,
                               C     = C,
                               W     = W)

  # Step 2: 构建模型
  # P is parallel mediation, CN is chained mediation, CP/PC is parallel + chain mediation
  {
    if (form == "P") {
      sem_model <- GenerateModelP(prepared_data, MP = MP)
    } else if (form == "CP") {
      sem_model <- GenerateModelCP(prepared_data, MP = MP)
    } else if (form == "PC") {
      sem_model <- GenerateModelPC(prepared_data, MP = MP)
    } else if (form == "CN") {
      sem_model <- GenerateModelCN(prepared_data, MP = MP)
    } else {
      stop("Invalid 'form' parameter. Use 'CP', 'PC' or 'CN'.")
    }
  }



  # Step 3: 选择方法
  ustd_result <- NULL
  mi_output  <- NULL
  fiml_result <- NULL
  mi_result <- NULL
  mc_de_result  <-  NULL
  ncpus <- get_safe_ncpus()

  # Step 4: 拟合模型
  if (Na == "DE") {
    # 删除缺失值的模型拟合
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      fixed.x = fixed.x,
      missing = "listwise",
      warn = FALSE
    )

    # bootstrap CI
    if (ci_method %in% c("bootstrap", "both")) {

      if (length(store_boot_args) == 0) {
        store_boot_args <- list()
      }
      if (!"ncpus" %in% names(store_boot_args)) {
        store_boot_args$ncpus <- get_safe_ncpus()
      }
      if (!"parallel" %in% names(store_boot_args)) {
        store_boot_args$parallel <- "snow"
      }

      store_boot_args1 <- utils::modifyList(store_boot_args,
                                            list(R = bootstrap,
                                                 iseed = iseed,
                                                 object = fit,
                                                 do_bootstrapping = TRUE))


      fit_u <- do.call(semboottools::store_boot,
                       store_boot_args1)

      ustd_result <- semboottools::parameterEstimates_boot(
        level = 1-alpha,
        object = fit_u,
        boot_ci_type = boot_ci_type,
        boot_pvalue = TRUE,
      )
    }
    # Monte Carlo CI
    if (ci_method %in% c("mc", "both")) {
      mc_de_result <- MC(
        lav = fit,
        R = R,
        alpha = alpha
      )
    }
  }
  else if (Na == "FIML") {
    # 使用 FIML 方法处理缺失值
    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      missing = "fiml",
      fixed.x = fixed.x,
      warn = FALSE
    )

    # Bootstrap CI
    if (ci_method %in% c("bootstrap", "both")) {
      if (!"ncpus" %in% names(store_boot_args)) {
        store_boot_args$ncpus <- get_safe_ncpus()
      }
      if (!"parallel" %in% names(store_boot_args)) {
        store_boot_args$parallel <- "snow"
      }

      store_boot_args1 <- utils::modifyList(store_boot_args,
                                            list(R = bootstrap,
                                                 iseed = iseed,
                                                 object = fit,
                                                 do_bootstrapping = TRUE))

      ustd_result <- semboottools::parameterEstimates_boot(
        object = fit_u,
        level = 1-alpha,
        boot_ci_type = boot_ci_type,
        boot_pvalue = TRUE
      )
    }

    # Monte Carlo CI
    if (ci_method %in% c("mc", "both")) {
      if (MCmethod == "mc") {
        fiml_result <- MC(
          lav = fit,
          R = R,
          alpha = alpha
        )
      } else if (MCmethod == "bootSD") {
        mc_fiml_result <- run_mc_mediation(
          fit = fit,
          data = prepared_data,
          standardized = standardized,
          R = R,
          seed = seed,
          alpha = alpha,
          alphastd = alphastd
        )
        fiml_result <- summarize_mc_ci(mc_fiml_result$unstd_result)
      }
    }
  }
  else if (Na == "MI") {
    mi_output <- RunMCMIAnalysis(
      data_missing = data,
      m = m,
      method = method,
      seed = seed,
      M_C1 = M_C1,
      M_C2 = M_C2,
      Y_C1 = Y_C1,
      Y_C2 = Y_C2,
      C_C1 = C_C1,
      C_C2 = C_C2,
      C = C,
      W = W,
      sem_model = sem_model,
      Na = Na,
      R = R,
      alpha = alpha,
      decomposition = decomposition,
      pd = pd,
      tol = tol
    )
    mi_result <- mi_output$mc_result
    prepared_data <- mi_output$first_imputed_data

    fit <- lavaan::sem(
      model = sem_model,
      data = prepared_data,
      fixed.x = fixed.x,
      warn = FALSE
    )}

  # Step 6 前添加，防止 NA 进入布尔逻辑判断
  mod_effect_args <- utils::modifyList(
    list(
      JN = TRUE,
      W_method = "discrete",
      W_values = c(-2, -1, 0, 1, 2),
      ci_level = 0.95,
      digits = 3
    ),
    mod_effect_args
  )

  # Step 6: 调节效应与 JN 分析
  moderated_effects_main <- NULL
  moderated_effects_jn <- NULL
  moderated_effects_conditional <- NULL
  if (!is.null(mc_de_result) || !is.null(fiml_result) || !is.null(mi_result)) {
    mc_obj <- mi_result %||% fiml_result %||% mc_de_result
    if (!is.null(mc_obj) && inherits(mc_obj, "semmcci")) {
      # 自动推断调节变量名称
      if (!is.null(W) && is.character(W) && length(W) >= 1 && W[1] %in% names(prepared_data)) {
        W_varname <- W[1]
      } else if (!is.null(W) && is.list(W) && length(W) >= 1 && all(sapply(W, is.character))) {
        W_varname <- names(W)[1]
      } else {
        W_varname <- "W1"
      }

      # ---------- 主效应表 + JN ----------
      mod_out <- tryCatch({
        args_all <- c(
          list(mc_result = mc_obj, data = prepared_data, W_varname = W_varname),
          mod_effect_args
        )
        do.call(get_all_moderated_effects, args_all)
      }, error = function(e) {
        warning("get_all_moderated_effects failed: ", e$message)
        NULL
      })

      # 拆分主效应表与 JN 表
      if (is.list(mod_out) && all(c("main", "JN") %in% names(mod_out))) {
        moderated_effects_main <- mod_out$main
        moderated_effects_jn   <- mod_out$JN
      } else {
        moderated_effects_main <- mod_out
        moderated_effects_jn   <- NULL
      }


      # ---------- 条件间接效应（基于 W 水平） ----------
      moderated_effects_conditional <- tryCatch({
        # 提取 mod_effect_args 中仅适用于 get_conditional_indirect_effects 的参数
        args_cond <- c(
          list(
            mc_result = mc_obj,
            data = prepared_data,
            W_varname = W_varname
          ),
          mod_effect_args[intersect(names(mod_effect_args), c("W_method", "W_values", "ci_level", "digits"))]
        )

        do.call(get_conditional_indirect_effects, args_cond)
      }, error = function(e) {
        warning("get_conditional_indirect_effects failed: ", e$message)
        NULL
      })
    }
  }


  # Step 5: 标准化结果
  # 初始化结果变量
  std_result <- NULL
  std_mi_result <- NULL
  std_fiml_result <- NULL

  if (standardized) {
    tryCatch({
      if (Na %in% c("DE", "FIML") &&
          ci_method %in% c("bootstrap", "both") &&
          exists("fit_u")) {

        boot_ci_type <- match.arg(boot_ci_type, choices = c("perc", "bc", "bca.simple"))

        std_result <- semboottools::standardizedSolution_boot(
          object = fit_u,
          level = max(1 - alphastd),
          type = "std.all",
          boot_ci_type = boot_ci_type,
          save_boot_est_std = TRUE,
          boot_pvalue = TRUE
        )

        if (is.null(std_result)) {
          warning("Standardized solution for DE/FIML (bootstrap) returned NULL.")
        }
      }


      # FIML（Monte Carlo 标准化）
      if (Na == "FIML" && ci_method == "mc") {
        if (!exists("fiml_result") || is.null(fiml_result)) {
          warning("FIML MC result is NULL, cannot compute standardized solution.")
        } else {
          if (MCmethod == "mc") {
            std_fiml_result <- tryCatch(
              MCStd2(fiml_result, alpha = alphastd),
              error = function(e) {
                warning("MCStd2 failed for FIML: ", e$message)
                NULL
              }
            )
          } else if (MCmethod == "bootSD") {
            # 注意：此时 fiml_result 是 summarize_mc_ci() 的输出
            if (!("std_result" %in% names(fiml_result)) || is.null(fiml_result$std_result)) {
              warning("No std_result found in fiml_result for bootSD MC method.")
              std_fiml_result <- NULL
            } else {
              std_fiml_result <- fiml_result$std_result
            }
          }
        }
      }

      if (Na == "MI") {
        if (is.null(mi_result)) {
          warning("MI result is NULL, cannot compute standardized solution.")
        } else {
          std_mi_result <- MCStd2(mi_result,alpha = alphastd)
        }
      }
    }, error = function(e) {
      warning("Error during standardized solution generation: ", e$message)
    })

  }

  input_vars <- list(
    M_C1 = M_C1,
    M_C2 = M_C2,
    Y_C1 = Y_C1,
    Y_C2 = Y_C2,
    C_C1 = C_C1,
    C_C2 = C_C2,
    C = C
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
    lavaan_fit = fit,
    sem_model = sem_model,
    mc_de_result = mc_de_result,
    mi_result = mi_result,
    fiml_result = fiml_result,
    std_result = std_result,
    boot_ci_type = boot_ci_type,
    bootstrap = bootstrap,
    ustd_result = ustd_result,
    moderated_effects_main = moderated_effects_main,
    moderated_effects_jn = moderated_effects_jn,
    moderated_effects_conditional = moderated_effects_conditional,
    std_mi_result = std_mi_result,
    std_fiml_result = std_fiml_result,
    input_vars = input_vars,
    alphastd = alphastd,
    alpha = alpha,
    Na = Na,
    iseed = iseed,
    paras = paras,
    standardized = standardized,
    MCmethod = MCmethod,
    ci_method = ci_method
  )
  class(out) <- "wsMed"
  return(out)
}


