#' Categorical predictors and supported variable types
#'
#' wsMed supports binary and multicategory between-subject covariates and one
#' categorical moderator in models with numeric outcomes and mediators.
#'
#' @section Supported roles:
#' Outcomes, mediators, and within-subject covariates must be numeric measures
#' analyzed by the continuous-response SEM. Binary or ordinal response models,
#' thresholds, and categorical links are not implemented. Storing a binary
#' outcome as numbers does not turn the estimator into a categorical-response
#' model. Between-subject covariates and the single moderator may instead be
#' unordered factors. Ordered factors are rejected by [wsmed_fit()]; explicitly
#' convert them to unordered factors only if a nominal interpretation is intended.
#'
#' @section Declaring categories:
#' In the staged workflow, [wsmed_fit()] treats numeric predictors, including
#' 0/1 columns, as continuous. Declare categorical predictors with [base::factor()]
#' and specify their levels explicitly. Every declared factor level must have
#' observations in the supplied data.
#'
#' The one-call [wsMed()] and [PrepareData()] interfaces retain automatic
#' detection: factors, character columns, and numeric columns whose observed
#' values are exactly 0 and 1 are categorical. Other numeric columns are
#' continuous unless \code{C_type} or \code{W_type} overrides detection.
#' Explicit factors and explicit type arguments make the intended interpretation
#' clear in scripts using the one-call interface.
#'
#' @section Reference coding and comparisons:
#' A factor with K levels is represented by K - 1 treatment indicators. The first
#' factor level is the reference; [stats::relevel()] changes it before fitting.
#' Indicators are not mean-centered. Coding does not depend on the global
#' \code{contrasts} option. Between-subject indicators use \code{Cb*} names and
#' moderator indicators use \code{W*} names. The \code{C_info} and \code{W_info}
#' attributes of prepared data record their mappings. Labels such as
#' \code{low vs high} identify the reference and comparison level: the indicator
#' is 0 at low and 1 at high, so its coefficient is high minus low.
#'
#' [wsmed_effects()] accepts original factor labels in \code{at}; by default
#' it extracts every level. [wsmed_contrasts()] compares effects using their
#' joint draws, preserving covariance. Do not subtract the endpoints of
#' separate confidence intervals to obtain an interval for a difference.
#' Marginally standardized conditional effects use the common model-implied
#' outcome-difference SD, not separate within-category SDs; factor labels and
#' dummy indicators retain their coding. See [standardize_moderation()].
#' Generated models account for the dependence of endogenous products on upstream
#' mediator disturbances. Reference changes preserve the implied marginal scales
#' of the same fitted model. MI pools marginal variance estimates jointly with
#' coefficients; compare the same completed datasets when checking recoding.
#' Refit saved models from before this covariance correction.
#'
#' @section Missing values:
#' The staged default \code{missing = "error"} rejects missing analysis values.
#' Listwise deletion and multiple imputation are available for incomplete
#' categorical predictors. FIML is allowed with fully observed categorical
#' predictors but [wsmed_fit()] rejects missing categorical predictors; the
#' one-call interface should follow the same restriction.
#' MI imputes the raw variables before constructing dummy variables and
#' interactions. The staged \code{mi$method} argument selects the method for
#' numeric variables (default \code{"pmm"}). Factors use logistic regression
#' for two levels and multinomial logistic regression for more than two levels.
#' This differs from the lower-level [ImputeData()] method argument.
#' MI supports Monte Carlo inference only.
#' @md
#'
#' @seealso [wsmed_model()], [wsmed_fit()], [wsmed_effects()],
#'   [wsmed_contrasts()], [PrepareData()], [ImputeData()]
#' @name wsmed_categorical
#' @examples
#' data(example_data)
#' dat <- example_data
#' dat$Group <- factor(dat$Group, levels = c("low", "med", "high"))
#' prepared <- PrepareData(dat, M_C1 = "A1", M_C2 = "A2",
#'                         Y_C1 = "D1", Y_C2 = "D2",
#'                         W = "Group", W_type = "categorical")
#' attr(prepared, "W_info")
#' @keywords models
NULL
