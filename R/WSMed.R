#' @title Within-Subject Mediation Analysis (Two-Condition)
#'
#' @description
#' wsMed() fits a structural-equation model (SEM) for two-condition
#' within-subject mediation, optionally handles missing data (DE / FIML / MI),
#' and quantifies unstandardised as well as standardised effects with either
#' bootstrap or Monte-Carlo confidence intervals.
#'
#' @details
#' **Model structures**
#' \itemize{
#'   \item \code{"P"}  Parallel mediation
#'   \item \code{"CN"} Chained (serial) mediation
#'   \item \code{"CP"} Chained → parallel
#'   \item \code{"PC"} Parallel → chained
#' }
#'
#' **Missing-data strategies**
#' \itemize{
#'   \item \code{"DE"}   List-wise deletion
#'   \item \code{"FIML"} Full-information maximum likelihood
#'   \item \code{"MI"}   Multiple imputation via \pkg{mice}
#' }
#'
#' **Confidence-interval engines**
#' \itemize{
#'   \item \strong{Bootstrap} — percentile, BC, or BCa (DE / FIML only)
#'   \item \strong{Monte Carlo} — draws from \code{semmcci} (all Na options)
#' }
#' For \code{Na = "FIML"} you may choose \code{MCmethod = "mc"} (default) or
#' \code{"bootSD"} to add a finite-sample SD correction.
#'
#' Workflow: ① preprocess → ② generate SEM syntax → ③ fit → ④ compute CIs
#' → ⑤ (optionally) standardise estimates.
#'
#' @param data A \link[base:data.frame]{data.frame} containing the raw scores.
#' @param M_C1,M_C2 Character vectors of mediator names under condition 1 and 2.
#' @param Y_C1,Y_C2 Character scalars for the outcome under each condition.
#' @param form     Model type: \code{"P"}, \code{"CN"}, \code{"CP"}, or \code{"PC"}.
#' @param standardized Logical; return standardised effects as well?  Default \code{FALSE}.
#'
#' @param Na          Missing-data method: \code{"DE"}, \code{"FIML"}, or \code{"MI"}.
#' @param ci_method   CI engine: \code{"bootstrap"} or \code{"mc"}.
#'                    If \code{NULL} (default) the choice is
#'                    \code{"bootstrap"} for DE and \code{"mc"} otherwise.
#' @param MCmethod    If \code{Na = "FIML"} and \code{ci_method = "mc"},
#'                    choose \code{"mc"} (default) or \code{"bootSD"}.
#'
#' @param bootstrap   Integer; bootstrap replicates (DE / FIML only).
#' @param boot_ci_type Character; bootstrap CI type: \code{"perc"}, \code{"bc"},
#'                     or \code{"bca.simple"}.
#' @param R       Integer; Monte-Carlo draws.  Default \code{20000L}.
#' @param alpha   Numeric in (0,1); two-sided significance level(s).
#' @param iseed,seed Integer seeds for bootstrap and Monte-Carlo respectively.
#'
#' @param fixed.x  Logical; pass to \pkg{lavaan}.
#'
#' @param C_C1,C_C2 Character vectors of within-subject covariates (per condition).
#' @param C         Character vector of between-subject covariates.
#' @param C_type    Character; type of \code{C}: \code{"continuous"} or \code{"categorical"}.
#'
#' @param W      Character vector of moderator(s); default \code{NULL}.
#' @param W_type Character; \code{"continuous"} or \code{"categorical"}.
#' @param MP     Character vector identifying which regression paths are
#'               moderated (e.g., \code{"a1"}, \code{"b_1_2"}, \code{"cp"}).
#'
#' @param mi_args List of MI-specific controls:
#'   \describe{
#'     \item{\code{m}}{Number of imputations (default 5).}
#'     \item{\code{method_num}}{Imputation method for \code{mice()}.}
#'     \item{\code{decomposition}}{Covariance-decomposition method
#'           (\code{"eigen"}, \code{"chol"}, \code{"svd"}).}
#'     \item{\code{pd}}{Logical; PD check.}
#'     \item{\code{tol}}{Tolerance for PD check.}
#'   }
#'
#' @param verbose Logical; print progress messages?
#'
#' @return An object of class \code{"wsMed"} with elements:
#' \describe{
#'   \item{data}{Pre-processed data frame}
#'   \item{sem_model}{Generated lavaan syntax}
#'   \item{mc}{List with Monte-Carlo draws, bootstrap tables (if any), and the fitted model}
#'   \item{moderation}{Conditional / moderated effect tables}
#'   \item{form,Na,alpha}{Analysis settings}
#'   \item{input_vars}{Names of all user-supplied variables}
#' }
#'
#' @examples
#' data(example_data)
#' set.seed(123)
#' result <- wsMed(
#'   data = example_data,
#'   M_C1 = c("A2", "B2"),
#'   M_C2 = c("A1", "B1"),
#'   Y_C1 = "C1", Y_C2 = "C2",
#'   form = "P", Na = "DE"
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
  .v("Preparing data ...", verbose = verbose)
  prep <- PrepareData(
    data, M_C1, M_C2, Y_C1, Y_C2,
    C_C1, C_C2, C, C_type,
    W,    W_type,
    keep_W_raw = TRUE,
    keep_C_raw = TRUE
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 4 ── 构建模型语法 --------------------------------------------------------#
  .v(sprintf("Building SEM syntax (%s) ...", form), verbose = verbose)
  sem_model <- switch(form,
                      P  = GenerateModelP (prep, MP),
                      CN = GenerateModelCN(prep, MP),
                      CP = GenerateModelCP(prep, MP),
                      PC = GenerateModelPC(prep, MP)
  )

  #───────────────────────────────────────────────────────────────────────────#
  # 5 ── 拟合 + Monte-Carlo --------------------------------------------------#
  .v(sprintf("Fitting model / Monte-Carlo (Na = %s) ...", Na), verbose = verbose)
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

      raw_mat <- slot(fit_u, "external")$sbt_boot_ustd   # B × nCoef
      mc$theta_boot <- raw_mat
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
  ## ---------------------------------------------
  ##  在主函数第 5 步末尾（fit_u 已经生成、raw_mat 也已就绪）加上：
  ## ---------------------------------------------

  ## ---- quick NA check -------------------------------------------------
  chk_theta <- function(mat, label){
    if (is.null(mat)) return()
    n_na  <- sum(is.na(mat))
    n_row <- nrow(mat); n_col <- ncol(mat)
    message(sprintf("[DBG] %s : dim = %d x %d | N_NA = %d",
                    label, n_row, n_col, n_na))
    # 额外：若想看到哪些列含 NA
    if (n_na > 0) {
      bad_cols <- colnames(mat)[colSums(is.na(mat)) > 0]
      message(sprintf("       cols with NA: %s",
                      paste(bad_cols, collapse = ", ")))
    }
  }
  chk_theta(theta_mc,   "theta_mc")
  chk_theta(theta_boot, "theta_boot")



  theta_mc   <- mc$result$thetahatstar     # 一定存在
  theta_boot <- if (exists("raw_mat")) raw_mat else NULL

  if (ci_method == "mc") {
    moderation <- .make_moderation(
      mc_res  = theta_mc,    # ← 只用 Monte-Carlo
      data    = prep, W = W, MP = MP,
      W_type  = W_type, alpha = alpha, verbose = verbose)

  } else if (ci_method == "bootstrap") {
    if (is.null(theta_boot))
      stop("Bootstrap draws not available; set ci_method = 'mc' or 'both'.")
    moderation <- .make_moderation(
      mc_res  = theta_boot,  # ← 只用 Bootstrap
      data    = prep, W = W, MP = MP,
      W_type  = W_type, alpha = alpha, verbose = verbose)

  } else {                       # ci_method == "both"
    moderation_mc   <- .make_moderation(theta_mc,   prep, W, MP, W_type, alpha)
    moderation_boot <- .make_moderation(theta_boot, prep, W, MP, W_type, alpha)

    # 存成一个 list，打印函数再决定怎么显示
    moderation <- list(mc   = moderation_mc,
                       boot = moderation_boot)
  }

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
                  ## ── bootstrap (DE) ───────────────────────────────────────
                  bootstrap    = 1000,
                  boot_ci_type = "perc",
                  iseed        = 123,
                  fixed.x      = FALSE,
                  ## ── misc. ───────────────────────────────────────────────
                  ci_method    = c("mc", "bootstrap", "both"),
                  MCmethod     = NULL,
                  seed         = 123,
                  standardized = FALSE,
                  verbose      = TRUE) {

  ## ── 0  输入验证 ──────────────────────────────────────────────────────
  ci_method <- match.arg(ci_method)
  form      <- match.arg(form)
  Na        <- match.arg(Na)

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

  ## ── 1  预处理数据 ────────────────────────────────────────────────────
  .v("Preparing data ...", verbose = verbose)
  prep <- PrepareData(
    data, M_C1, M_C2, Y_C1, Y_C2,
    C_C1, C_C2, C, C_type,
    W,    W_type,
    keep_W_raw = TRUE,
    keep_C_raw = TRUE
  )

  ## ── 2  构建 SEM 语法 ────────────────────────────────────────────────
  .v(sprintf("Building SEM syntax (%s) ...", form), verbose = verbose)
  sem_model <- switch(form,
                      P  = GenerateModelP (prep, MP),
                      CN = GenerateModelCN(prep, MP),
                      CP = GenerateModelCP(prep, MP),
                      PC = GenerateModelPC(prep, MP)
  )

  ## ── 3  Monte-Carlo (& 适用时 FIML) 拟合与抽样 ──────────────────────
  .v(sprintf("Fitting model / Monte-Carlo (Na = %s) ...", Na), verbose = verbose)
  mc <- .fit_and_mc(
    sem_model, prep,
    Na      = Na,
    R       = R,
    alpha   = alpha,
    fixed.x = fixed.x,
    verbose = verbose)

  theta_mc <- mc$result$thetahatstar          # (必定存在)

  ## ── 4  如果要求 Bootstrap，再执行一次抽样 ─────────────────────────
  theta_boot <- NULL
  param_boot <- NULL

  if (Na == "DE" && ci_method %in% c("bootstrap","both")) {

    fit_u <- semboottools::store_boot(
      object            = mc$fit,
      R                 = bootstrap,
      iseed             = iseed,
      do_bootstrapping  = TRUE,
      ncpus             = parallel::detectCores(1L),
      parallel          = "snow")

    theta_boot <- slot(fit_u, "external")$sbt_boot_ustd   # B × nCoef

    ok <- complete.cases(theta_boot)
    if (!all(ok)) {
      .v("Filtered %d non-converged bootstrap replicates.", sum(!ok),
         verbose = verbose)
      theta_boot <- theta_boot[ok, , drop = FALSE]
    }

    param_boot <- semboottools::parameterEstimates_boot(
      object        = fit_u,
      level         = 1 - alpha,
      boot_ci_type  = boot_ci_type,
      boot_pvalue   = TRUE)

    mc$theta_boot <- theta_boot          # 供外部查阅
    mc$bootstrap  <- param_boot
  }

  ## ── 5  按 ci_method 路由给 .make_moderation() ────────────────────
  make_mod <- function(th) {
    .make_moderation(
      mc_res  = th,
      data    = prep,
      W       = W,
      MP      = MP,
      W_type  = W_type,
      alpha   = alpha,
      verbose = verbose)
  }

  moderation <- switch(ci_method,
                       mc        = make_mod(theta_mc),
                       bootstrap = make_mod(theta_boot),
                       both      = list(mc = make_mod(theta_mc),
                                        boot = make_mod(theta_boot))
  )

  ## ── 6  标准化 (Monte-Carlo) ────────────────────────────────────────
  mc$std <- if (standardized) MCStd2(theta_mc, alpha) else NULL

  ## ── 7  返回对象 ────────────────────────────────────────────────────
  out <- list(
    data       = prep,
    sem_model  = sem_model,
    mc         = mc,                 # 所有 MC + bootstrap 抽样结果
    param_boot = param_boot,         # bootstrap 参数表 (NULL if not used)
    moderation = moderation,         # 已路由
    alpha      = alpha,
    Na         = Na,
    form       = form,
    ci_method  = ci_method
  )
  class(out) <- "wsMed"
  out
}

