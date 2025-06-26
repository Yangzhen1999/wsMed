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
                  M_C1, M_C2, Y_C1, Y_C2,
                  C_C1 = NULL, C_C2 = NULL,
                  C     = NULL, C_type = NULL,
                  W     = NULL, W_type = NULL,
                  MP    = NULL,
                  form  = c("P", "CN", "CP", "PC"),
                  Na    = c("DE", "FIML", "MI"),
                  alpha = .05,
                  mi_args = list(),
                  R = 20000L,
                  # ── bootstrap (DE/FIML) ────────────────────────────────────
                  bootstrap    = 1000,
                  boot_ci_type = "perc",
                  iseed        = 123,
                  fixed.x      = FALSE,
                  # ── misc. ─────────────────────────────────────────────────
                  ci_method    = NULL,
                  MCmethod     = NULL,
                  seed         = 123,
                  standardized = FALSE,
                  verbose      = TRUE) {

  #───────────────────────────────────────────────────────────────────────────#
  # 0 ── 输入验证 ------------------------------------------------------------#
  #───────────────────────────────────────────────────────────────────────────#
  validate_wsMed_inputs(
    data      = data,
    M_C1      = M_C1,  M_C2 = M_C2,
    Y_C1      = Y_C1,  Y_C2 = Y_C2,
    C_C1      = C_C1,  C_C2 = C_C2,  C = C,
    W         = W,     W_type = W_type,
    MP        = MP,
    form      = form,
    Na        = Na,
    R         = R,
    bootstrap = bootstrap,
    m         = mi_args$m %||% 5L,
    ci_level  = 1 - alpha,
    ci_method = ci_method,
    MCmethod  = MCmethod
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 1 ── 参数标准化 ----------------------------------------------------------#
  form <- match.arg(form)
  Na   <- match.arg(Na)

  #───────────────────────────────────────────────────────────────────────────#
  # 2 ── MI 参数合并（若适用） ----------------------------------------------#
  mi_defaults <- list(
    m             = 5L,
    method_num    = "pmm",
    decomposition = "eigen",
    pd            = TRUE,
    tol           = 1e-6,
    seed          = seed
  )
  mi_args <- modifyList(mi_defaults, mi_args)

  #───────────────────────────────────────────────────────────────────────────#
  # 3 ── 预处理数据 ----------------------------------------------------------#
  .v("Preparing data …", verbose = verbose)
  prep <- PrepareData(
    data, M_C1, M_C2, Y_C1, Y_C2,
    C_C1, C_C2, C, C_type,
    W,    W_type,
    keep_W_raw = TRUE,
    keep_C_raw = TRUE
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 4 ── 构建模型语法 --------------------------------------------------------#
  .v(sprintf("Building SEM syntax (%s) …", form), verbose = verbose)
  sem_model <- switch(form,
                      P  = GenerateModelP (prep, MP),
                      CN = GenerateModelCN(prep, MP),
                      CP = GenerateModelCP(prep, MP),
                      PC = GenerateModelPC(prep, MP)
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 5 ── 拟合 + Monte-Carlo --------------------------------------------------#
  .v(sprintf("Fitting model / Monte-Carlo (Na = %s) …", Na), verbose = verbose)
  mc <- list()   # will store $result (semmcci), $fit

  if (Na %in% c("DE", "FIML")) {

    mc <- .fit_and_mc(sem_model, prep,
                      Na      = Na,
                      R       = R,
                      alpha   = alpha,
                      fixed.x = fixed.x,
                      verbose = verbose)

    if (Na == "DE" && isTRUE(ci_method %in% c("bootstrap", "both"))) {
      boot_ctl <- list(R = bootstrap, iseed = iseed,
                       object = mc$fit, do_bootstrapping = TRUE,
                       ncpus    = parallel::detectCores(1L),
                       parallel = "snow")
      fit_u <- do.call(semboottools::store_boot, boot_ctl)
      mc$bootstrap <- semboottools::parameterEstimates_boot(
        object = fit_u, level = 1 - alpha,
        boot_ci_type = boot_ci_type, boot_pvalue = TRUE)
    }

  } else {  # ── MI ──────────────────────────────────────────────────────────
    mi_out <- RunMCMIAnalysis(
      data_missing = data,
      m            = mi_args$m,
      method_num   = mi_args$method_num,
      seed         = mi_args$seed,
      M_C1, M_C2, Y_C1, Y_C2,
      C_C1, C_C2, C, C_type,
      W,    W_type,
      keep_W_raw = TRUE,
      keep_C_raw = TRUE,
      sem_model  = sem_model,
      Na         = "MI",
      R          = R,
      alpha      = alpha,
      decomposition = mi_args$decomposition,
      pd  = mi_args$pd,
      tol = mi_args$tol
    )
    mc$result <- mi_out$mc_result
    mc$fit    <- lavaan::sem(sem_model, mi_out$first_imputed_data,
                             fixed.x = fixed.x, warn = FALSE)
    prep <- mi_out$first_imputed_data
  }

  if (is.null(mc$result$thetahatstar))
    stop("Monte-Carlo draws are NULL; model may have failed.", call. = FALSE)

  #───────────────────────────────────────────────────────────────────────────#
  # 6 ── 调节分析 -----------------------------------------------------------#
  moderation <- .make_moderation(
    mc_res  = mc$result,
    data    = prep,
    W       = W,
    MP      = MP,
    W_type  = W_type,
    alpha   = alpha,
    verbose = verbose
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 7 ── 标准化 (可选) -------------------------------------------------------#
  mc$std <- if (standardized) MCStd2(mc$result, alpha) else NULL

  #───────────────────────────────────────────────────────────────────────────#
  # 8 ── 返回对象 -----------------------------------------------------------#
  out <- list(
    data        = prep,
    sem_model   = sem_model,
    input_vars  = list(
      M_C1 = M_C1, M_C2 = M_C2,
      Y_C1 = Y_C1, Y_C2 = Y_C2,
      C_C1 = C_C1, C_C2 = C_C2, C = C
    ),
    mc          = mc,
    moderation  = moderation,
    alpha       = alpha,
    Na          = Na,
    form        = form
  )
  class(out) <- "wsMed"
  out
}

