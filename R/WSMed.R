#' @title Analyze two-condition within-subject mediation
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
#' Monte Carlo inference uses the existing joint-parameter sampler. The legacy
#' \code{MCmethod = "bootSD"} option was accepted but never applied; it now
#' produces an explicit error rather than silently returning ordinary MC results.
#'
#' Standardization divides differences by their marginal model-implied SDs,
#' without recentering them. Dummy variables retain 0/1 units; interaction
#' terms use the product of their component scale factors, not the interaction
#' column SD. MC and bootstrap draws are transformed jointly with their scales.
#' Standardized bootstrap intervals use type-7 quantiles; bc and bca.simple
#' apply bias correction with zero acceleration. P-values use inversion of
#' that distribution and require at least 1000 valid replicates.
#'
#' Conditional tables use percentile intervals and fixed numerical probes.
#' With fixed.x=TRUE, scale transformations condition on the fitted external
#' moments rather than adding sampling uncertainty for those moments.
#' In MI, probes/centering references use the first completed data set;
#' fixed.x=TRUE also conditions on its external moments in the pooled transform.
#' In moderated MI models, marginal variances are pooled jointly with primitive
#' coefficients, including their delta-method within-imputation and Rubin
#' between-imputation covariance. MC propagates this joint uncertainty.
#' Endogenous product moments are estimated even with fixed.x=TRUE.
#'
#' Workflow: (1) preprocess -> (2) generate SEM syntax -> (3) fit
#' -> (4) compute confidence intervals -> (5) optional: standardize estimates.
#' See [wsmed_categorical] for supported categorical predictors, reference
#' coding, and missing-data restrictions. In both interfaces, declare categorical
#' covariates and moderators as unordered factors with explicit levels before
#' fitting. The first factor level is the reference group. Existing automatic
#' recognition of numeric 0/1 predictors is retained in this one-call interface.
#' The empirical manuscript dataset is
#' available as [wsmed_examples()]; [example_data()] is simulated tutorial data.
#' @md
#'
#' @param data A \link[base:data.frame]{data.frame} containing the raw scores.
#' @param M_C1,M_C2 Character vectors of mediator names under condition 1 and 2.
#' @param Y_C1,Y_C2 Character scalars for the outcome under each condition.
#' @param form Model type: \code{"P"}, \code{"CN"}, \code{"CP"},
#'   \code{"PC"}, or \code{"UD"}. Use \code{"UD"} to specify a
#'   user-defined mediation model. Values are case-insensitive.
#' @param paths A character vector defining directed paths when
#'   \code{form = "UD"}. Paths are specified using mediator labels
#'   \code{M1}, \code{M2}, and so on, with \code{Y} denoting the outcome.
#'   For example, \code{c("M1 -> M3", "M3 -> Y", "M2 -> Y")}.
#'   Must be \code{NULL} for the predefined model forms.
#' @param standardized Logical; if \code{TRUE}, return standardized parameter
#'   tables (including defined effects at the reference moderator value).
#'   Raw conditional results remain in moderation; standardized conditional
#'   tables and curves are added in moderation_std. Default FALSE. This choice
#'   is saved as the default for print, summary, wsmed_effects and generic plot;
#'   standardized = TRUE or FALSE on those methods overrides it for one query.
#'   Raw fitting parameters remain available through coef and vcov.
#'
#' @param Na Missing-data method: \code{"DE"}, \code{"FIML"}, or \code{"MI"}.
#'   Values are case-insensitive.
#' @param ci_method CI engine: \code{"mc"}, \code{"bootstrap"}, or \code{"both"}.
#'   Values are case-insensitive. The default (also used for \code{NULL}) is
#'   \code{"mc"}. With \code{Na = "MI"}, only \code{"mc"} is supported.
#' @param MCmethod NULL or \code{"mc"}. The unimplemented \code{"bootSD"}
#'   option is rejected explicitly.
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
#'   Automatic numeric 0/1 moderator detection emits a message and is recorded in
#'   \code{fit$diagnostics$input_notes}. Use an explicit type or factor for
#'   consistency with \code{wsmed_fit()}.
#' @param MP Character vector identifying which regression paths are moderated
#'   (for example, \code{"a1"}, \code{"b_1_2"}, \code{"cp"}). Main effects of
#'   W already included in each regression are always used when computing
#'   conditional intercepts, whether or not a/cp is explicitly listed in MP.
#'
#' @param mi_args List of MI-specific controls:
#' \describe{
#'   \item{\code{m}}{Number of imputations. Default 5.}
#'   \item{\code{method_num}}{Imputation method for \code{mice()}.}
#'   \item{\code{completed}}{Optional list of completed wide data frames or a
#'     \code{mice} mids object. Observed values, rows and factor levels must be
#'     preserved. The number of imputations is inferred; supplied m must match.
#'     Omit method_num. With external imputations, seed still controls MC only.
#'     See \code{\link{wsmed_fit}} for model-compatible imputation guidance.}
#'   \item{\code{decomposition}}{Covariance-decomposition method
#'     (\code{"eigen"}, \code{"chol"}, \code{"svd"}). The default
#'     \code{"eigen"} uses the principal symmetric covariance square root;
#'     fixed-seed MI draws differ from wsMed 1.1.0.}
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
#'   \item{moderation}{Raw conditional or moderated effect tables.}
#'   \item{moderation_std}{Standardized conditional tables and curves when
#'     standardized=TRUE and a moderator is supplied.}
#'   \item{form,Na,alpha}{Analysis settings.}
#'   \item{paths}{The user-defined paths when \code{form = "UD"};
#'     otherwise \code{NULL}.}
#'   \item{input_vars}{Names of all user-supplied variables.}
#'   \item{model,fit,inference}{Structured specification, reusable fit (including
#'     all imputation fits), and named stored inference objects.}
#' }
#' @details The one-call interface uses the same fitting and inference engines
#' as [wsmed_model()], [wsmed_fit()], and [wsmed_infer()]. Default printing is
#' concise; use \code{print(result, detail = "full")} for the original tables.
#' Use [wsmed_effects()] to query stored draws without rerunning the analysis.
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

  # Validate inputs
  # Normalize character choices only; retain match.arg() defaults, partial
  # matching and rejection of non-character or ambiguous inputs.
  if (is.character(ci_method)) ci_method <- tolower(ci_method)
  if (is.character(form)) form <- toupper(form)
  if (is.character(Na)) Na <- toupper(Na)
  ci_method <- match.arg(ci_method)
  form      <- match.arg(form)
  Na        <- match.arg(Na)

  if (!is.null(mi_args$completed)) {
    if (Na != "MI") stop("completed imputations require Na = 'MI'.")
    if (!is.null(mi_args$method_num))
      stop("method_num controls internal imputation; omit it with completed datasets.")
    cols <- unique(c(M_C1, M_C2, Y_C1, Y_C2, C_C1, C_C2, C, W))
    mi_args$completed <- .wsmed_completed(mi_args$completed, data, cols, mi_args$m)
    mi_args$m <- length(mi_args$completed)
    mi_args$engine <- "external"
  }

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
  if (identical(MCmethod, "bootSD"))
    stop("MCmethod = 'bootSD' was never implemented; use MCmethod = 'mc' or NULL.")

  # Normalize argument choices
  form <- match.arg(form)
  Na   <- match.arg(Na)

  # Merge default multiple-imputation arguments
  mi_defaults <- list(
    m             = 5L,
    method_num    = "pmm",
    decomposition = "eigen",
    pd            = TRUE,
    tol           = 1e-6,
    seed          = seed
  )
  mi_args <- modifyList(mi_defaults, mi_args)

  vars <- list(M_C1 = M_C1, M_C2 = M_C2, Y_C1 = Y_C1, Y_C2 = Y_C2,
    C_C1 = C_C1, C_C2 = C_C2, C = C, C_type = C_type, W = W, W_type = W_type, MP = MP)
  model <- .wsmed_legacy_model(vars, form, paths)
  .wsmed_preserve_rng({
    .v(sprintf("Na = %s  |  ci_method = %s", Na, ci_method), verbose = verbose)
    fit <- .wsmed_fit_core(model, data, Na, mi_args, fixed.x, verbose)
    inf <- list()
    if (ci_method %in% c("mc", "both")) {
      # Preserve the historical MI seed routing in the one-call API.
      mc_seed <- if (Na == "MI") mi_args$seed else seed
      inf$mc <- .wsmed_infer_core(fit, "mc", R, mc_seed, 1 - alpha,
        "perc", mi_args$decomposition, mi_args$pd, mi_args$tol, verbose)
    }
    if (ci_method %in% c("bootstrap", "both")) {
      boot_ci_type <- match.arg(boot_ci_type, c("perc", "bc", "bca.simple"))
      inf$bootstrap <- .wsmed_infer_core(fit, "bootstrap", bootstrap, iseed,
        1 - alpha, boot_ci_type, "eigen", TRUE, 1e-6, verbose)
    }
    .wsmed_assemble(fit, inf, alpha, standardized, verbose)
  }, preserve = !(Na == "MI" && is.null(mi_args$seed)) &&
    !(ci_method %in% c("mc", "both") && is.null(if (Na == "MI") mi_args$seed else seed)) &&
    !(ci_method %in% c("bootstrap", "both") && is.null(iseed)))
}
