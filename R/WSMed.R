#' @title Within-Subject Mediation Analysis (Two-Condition)
#'
#' @description
#' \code{wsMed()} fits a structural equation model (SEM) for two-condition
#' within-subject mediation. It can handle missing data (DE, FIML, MI) and
#' computes both unstandardized and standardized effects with bootstrap or
#' Monte Carlo confidence intervals.
#'
#' @details
#' Model structures:
#' \itemize{
#'   \item \code{"P"}: parallel mediation
#'   \item \code{"CN"}: chained (serial) mediation
#'   \item \code{"CP"}: chained then parallel
#'   \item \code{"PC"}: parallel then chained
#'   \item \code{"UD"}: user-defined mediation model
#' }
#'
#' Missing-data strategies:
#' \itemize{
#'   \item \code{"DE"}: list-wise deletion
#'   \item \code{"FIML"}: full-information maximum likelihood
#'   \item \code{"MI"}: multiple imputation via \pkg{mice}
#' }
#'
#' Confidence-interval engines:
#' \itemize{
#'   \item Bootstrap: percentile, BC, or BCa (DE and FIML only)
#'   \item Monte Carlo: draws via \pkg{semmcci} (all \code{Na} options)
#' }
#' For \code{Na = "FIML"}, you may choose \code{MCmethod = "mc"} (default) or
#' \code{"bootSD"} to add a finite-sample SD correction.
#'
#' Workflow: (1) preprocess -> (2) generate SEM syntax -> (3) fit
#' -> (4) compute confidence intervals -> (5) optional: standardize estimates.
#'
#' @param data A \link[base:data.frame]{data.frame} containing the raw scores.
#' @param M_C1,M_C2 Character vectors of mediator names under condition 1 and 2.
#' @param Y_C1,Y_C2 Character scalars for the outcome under each condition.
#' @param form Model type: \code{"P"}, \code{"CN"}, \code{"CP"},
#'   \code{"PC"}, or \code{"UD"}. Use \code{"UD"} to specify a
#'   user-defined mediation model.
#' @param paths A character vector defining directed paths when
#'   \code{form = "UD"}. Paths are specified using mediator labels
#'   \code{M1}, \code{M2}, and so on, with \code{Y} denoting the outcome.
#'   For example, \code{c("M1 -> M3", "M3 -> Y", "M2 -> Y")}.
#'   Must be \code{NULL} for the predefined model forms.
#' @param standardized Logical; if \code{TRUE}, return standardized effects. Default \code{FALSE}.
#'
#' @param Na Missing-data method: \code{"DE"}, \code{"FIML"}, or \code{"MI"}.
#' @param ci_method CI engine: \code{"bootstrap"} or \code{"mc"}.
#'   If \code{NULL} (default) the choice is \code{"bootstrap"} for \code{Na = "DE"}
#'   and \code{"mc"} otherwise.
#' @param MCmethod If \code{Na = "FIML"} and \code{ci_method = "mc"},
#'   choose \code{"mc"} (default) or \code{"bootSD"}.
#'
#' @param bootstrap Integer; number of bootstrap replicates (DE and FIML only).
#' @param boot_ci_type Character; bootstrap CI type: \code{"perc"}, \code{"bc"},
#'   or \code{"bca.simple"}.
#' @param R Integer; number of Monte Carlo draws. Default \code{20000L}.
#' @param alpha Numeric vector in (0, 1); two-sided significance levels.
#' @param iseed,seed Integer seeds for bootstrap and Monte Carlo, respectively.
#'
#' @param fixed.x Logical; passed to \pkg{lavaan}.
#'
#' @param C_C1,C_C2 Character vectors of within-subject covariates (per condition).
#' @param C Character vector of between-subject covariates.
#' @param C_type Character; type of \code{C}: \code{"continuous"} or \code{"categorical"}.
#'
#' @param W Character vector of moderators. Default \code{NULL}.
#' @param W_type Character; \code{"continuous"} or \code{"categorical"}.
#' @param MP Character vector identifying which regression paths are moderated
#'   (for example, \code{"a1"}, \code{"b_1_2"}, \code{"cp"}).
#'
#' @param mi_args List of MI-specific controls:
#' \describe{
#'   \item{\code{m}}{Number of imputations. Default 5.}
#'   \item{\code{method_num}}{Imputation method for \code{mice()}.}
#'   \item{\code{decomposition}}{Covariance-decomposition method
#'     (\code{"eigen"}, \code{"chol"}, \code{"svd"}).}
#'   \item{\code{pd}}{Logical; positive-definiteness check.}
#'   \item{\code{tol}}{Tolerance for the positive-definiteness check.}
#' }
#'
#' @param verbose Logical; print progress messages.
#'
#' @return An object of class \code{"wsMed"} with elements:
#' \describe{
#'   \item{data}{Preprocessed data frame.}
#'   \item{sem_model}{Generated \pkg{lavaan} syntax.}
#'   \item{mc}{List with Monte Carlo draws, bootstrap tables (if any),
#'     and the fitted model.}
#'   \item{moderation}{Conditional or moderated effect tables.}
#'   \item{form,Na,alpha}{Analysis settings.}
#'   \item{paths}{The user-defined paths when \code{form = "UD"};
#'     otherwise \code{NULL}.}
#'   \item{input_vars}{Names of all user-supplied variables.}
#' }
#'
#' @examples
#' data("example_data", package = "wsMed")
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
                  form = c("P", "CN", "CP", "PC", "UD"),
                  Na    = c("DE", "FIML", "MI"),
                  alpha = .05,
                  mi_args = list(),
                  R = 20000L,
                  ## ── bootstrap (DE) ───────────────────────────────────────
                  bootstrap    = 2000,
                  boot_ci_type = "perc",
                  iseed        = 123,
                  fixed.x      = FALSE,
                  ## ── misc. ───────────────────────────────────────────────
                  ci_method    = c("mc", "bootstrap", "both"),
                  MCmethod     = NULL,
                  seed         = 123,
                  standardized = FALSE,
                  verbose      = FALSE,
                  paths = NULL) {

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
    paths     = paths,
    Na        = Na,
    R         = R,
    bootstrap = bootstrap,
    m         = mi_args$m %||% 5L,
    ci_level  = 1 - alpha,
    ci_method = ci_method,
    MCmethod  = MCmethod
  )

  # ── 参数标准化 ----------------------------------------------------------#
  form <- match.arg(form)
  Na   <- match.arg(Na)

  # ── MI 参数合并（若适用） ----------------------------------------------#
  mi_defaults <- list(
    m             = 5L,
    method_num    = "pmm",
    decomposition = "eigen",
    pd            = TRUE,
    tol           = 1e-6,
    seed          = seed
  )
  mi_args <- modifyList(mi_defaults, mi_args)

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
  sem_model <- switch(
    form,
    P = GenerateModelP(
      prepared_data = prep,
      MP = MP
    ),
    CN = GenerateModelCN(
      prepared_data = prep,
      MP = MP
    ),
    CP = GenerateModelCP(
      prepared_data = prep,
      MP = MP
    ),
    PC = GenerateModelPC(
      prepared_data = prep,
      MP = MP
    ),
    UD = GenerateModelCustom(
      prepared_data = prep,
      paths = paths,
      MP = MP
    )
  )
  ## ── 3  拟合 + 抽样（按 Na & ci_method 分流） ──────────────────────
  .v(sprintf("Na = %s  |  ci_method = %s", Na, ci_method), verbose = verbose)

  need_mc   <- ci_method %in% c("mc", "both")      # 是否跑 Monte-Carlo
  need_boot <- ci_method %in% c("bootstrap", "both")

  mc          <- list()        # 统一容器
  theta_mc    <- NULL
  theta_boot  <- NULL
  param_boot  <- NULL
  fit_u <- NULL

  ## ---- 3A: MI  --------------------------------------------------------------
  if (Na == "MI") {

    mi_out <- RunMCMIAnalysis(
      data_missing = data,
      m            = mi_args$m,
      method_num   = mi_args$method_num,
      seed         = mi_args$seed,
      M_C1, M_C2, Y_C1, Y_C2,
      C_C1, C_C2, C, C_type,
      W,    W_type,
      keep_W_raw   = TRUE,
      keep_C_raw   = TRUE,
      sem_model    = sem_model,
      Na           = "MI",
      R            = R,
      alpha        = alpha,
      decomposition = mi_args$decomposition,
      pd            = mi_args$pd,
      tol           = mi_args$tol
    )

    mc$result <- mi_out$mc_result
    theta_mc  <- mc$result$thetahatstar
    mc$fit    <- lavaan::sem(sem_model, mi_out$first_imputed_data,
                             fixed.x = fixed.x, warn = FALSE)
    prep      <- mi_out$first_imputed_data           # 后续调节分析用

  } else {

    ## ---- 3B: DE / FIML ------------------------------------------------------

    # 3B-1  拟合 lavaan +（可选）MC
    mc <- .fit_and_mc(
      sem_model, prep,
      Na      = Na,
      R       = R,
      alpha   = alpha,
      fixed.x = fixed.x,
      verbose = verbose,
      run_mc  = need_mc              # ← 关键开关
    )

    if (!is.null(mc$result)) {
      theta_mc <- mc$result$thetahatstar
    }

    # 3B-2  Bootstrap（如需）
    if (need_boot) {
      .v(sprintf("Bootstrap draws (B = %d) ...", bootstrap), verbose = verbose)

      fit_u <- semboottools::store_boot(
        object           = mc$fit,
        R                = bootstrap,
        iseed            = iseed,
        do_bootstrapping = TRUE,
        ncpus            = parallel::detectCores(1L),
        parallel         = "snow")

      theta_boot <- slot(fit_u, "external")$sbt_boot_ustd
      ok <- complete.cases(theta_boot)
      if (!all(ok)) {
        .v(sprintf("Filtered %d non-converged replicates.", sum(!ok)),
           verbose = verbose)
        theta_boot <- theta_boot[ok, , drop = FALSE]
      }

      theta_boot <- .add_indirect_boot(theta_boot, sem_model)

      param_boot <- semboottools::parameterEstimates_boot(
        object        = fit_u,
        level         = 1 - alpha,
        boot_ci_type  = boot_ci_type,
        boot_pvalue   = TRUE)

      mc$theta_boot <- theta_boot
      mc$bootstrap  <- param_boot
      assign("fit_u", fit_u, inherits = TRUE)   # 供后面标准化块使用
    }
  }

  ## ---- 3C: 结果存在性检查 ---------------------------------------------------
  if (is.null(theta_mc) && is.null(theta_boot))
    stop("No sampling draws were produced; model may have failed.",
         call. = FALSE)



  ## ── 5  调节分析 (路由 CI 来源) ─────────────────────────────────
  make_mod <- function(theta_mat) {
    .make_moderation(
      mc_res  = theta_mat,
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
                       both      = list(mc   = make_mod(theta_mc),
                                        boot = make_mod(theta_boot)))

  ## ── 6  标准化结果 ───────────────────────────────────────────────
  mc$std_mc   <- NULL   # Monte-Carlo 标准化结果
  mc$std_boot <- NULL   # Bootstrap   标准化结果

  if (standardized) {
    ## 6-A  Monte-Carlo 标准化
    if (need_mc && !is.null(theta_mc)) {
      mc$std_mc <- tryCatch(
        MCStd2(mc$result, alpha = alpha),
        error = function(e) {
          warning("MCStd2 failed: ", e$message)
          NULL
        }
      )
    }

    ## 6-B  Bootstrap 标准化（仅 DE / FIML）
    if (need_boot && exists("fit_u") && !is.null(fit_u)) {
      boot_ci_type <- match.arg(boot_ci_type,
                                choices = c("perc", "bc", "bca.simple"))

      mc$std_boot <- tryCatch(
        semboottools::standardizedSolution_boot(
          object             = fit_u,
          level              = 1 - alpha,
          type               = "std.all",
          boot_ci_type       = boot_ci_type,
          save_boot_est_std  = TRUE,
          boot_pvalue        = TRUE),
        error = function(e) {
          warning("standardizedSolution_boot failed: ", e$message)
          NULL
        }
      )
    }

  }


  input_vars <- list(
    M_C1 = M_C1, M_C2 = M_C2,
    Y_C1 = Y_C1, Y_C2 = Y_C2,
    C_C1 = C_C1, C_C2 = C_C2,
    C    = C,    C_type = C_type,
    W    = W,    W_type = W_type
  )


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
    ci_method  = ci_method,
    input_vars = input_vars,
    fit_u  = fit_u,
    paths = paths
  )

  class(out) <- "wsMed"

  .v(
    "Analysis completed successfully.",
    verbose = verbose
  )

  out
}



