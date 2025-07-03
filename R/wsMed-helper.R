#' Validate user inputs for \code{wsMed()}
#'
#' All checks \strong{stop()} with an informative message when they fail.
#' Invisibly returns \code{TRUE} on success.
#'
#' @keywords internal
validate_wsMed_inputs <- function(data,
                                  M_C1, M_C2, Y_C1, Y_C2,
                                  C_C1 = NULL, C_C2 = NULL, C = NULL,
                                  W     = NULL, W_type = NULL,
                                  MP    = NULL,
                                  form  = c("P","CN","CP","PC"),
                                  Na    = c("DE","FIML","MI"),
                                  R           = 20000L,
                                  bootstrap   = 1000L,
                                  m           = 5L,
                                  ci_level    = .95,
                                  ci_method   = NULL,
                                  MCmethod    = NULL) {

  ## ---- helper -------------------------------------------------------------
  check_cols <- function(vars, nm) {
    if (!is.null(vars) && !all(vars %in% names(data)))
      stop("Columns not found for ", nm, ": ",
           paste(setdiff(vars, names(data)), collapse = ", "),
           call. = FALSE)
  }
  ## ---- 0. data ------------------------------------------------------------
  if (is.null(data))
    stop("data cannot be NULL.", call. = FALSE)

  if (!is.data.frame(data))
    stop("data must be a data frame.", call. = FALSE)

  if (nrow(data) == 0)
    stop("data cannot be empty.", call. = FALSE)

  if (anyDuplicated(names(data)))
    stop("Duplicated column names in data: ",
         paste(names(data)[duplicated(names(data))], collapse = ", "),
         call. = FALSE)



  ## ---- 1. mediator & outcome columns -------------------------------------
  if (is.null(M_C1) || is.null(M_C2))
    stop("M_C1 and M_C2 cannot be NULL.", call. = FALSE)
  if (length(M_C1) != length(M_C2))
    stop("The lengths of M_C1 and M_C2 must match.", call. = FALSE)
  if (is.null(Y_C1) || is.null(Y_C2))
    stop("Y_C1 and Y_C2 cannot be NULL.", call. = FALSE)

  req <- c(M_C1, M_C2, Y_C1, Y_C2)
  miss <- setdiff(req, names(data))
  if (length(miss))
    stop("Missing columns in data: ", paste(miss, collapse = ", "),
         call. = FALSE)

  ## ---- 2. moderator -------------------------------------------------------
  if (!is.null(W) && (!is.character(W) || length(W) != 1L))
    stop("Exactly one moderator column name must be supplied in W.", call. = FALSE)
  if (!is.null(W) && !W %in% names(data))
    stop("Moderator W ('", W, "') is not a column in data.", call. = FALSE)

  if (!is.null(W) && (is.null(MP) || length(MP) == 0))
    stop("When W is specified you must also supply MP.", call. = FALSE)
  if (is.null(W) && !is.null(MP) && length(MP) > 0)
    stop("MP specified but W is NULL.", call. = FALSE)

  if (!is.null(MP)) {
    if (!is.character(MP) || anyNA(MP))
      stop("MP must be a character vector with no NA.", call. = FALSE)
    if (any(dup <- duplicated(MP)))
      stop("Duplicated names in MP: ", paste(MP[dup], collapse = ", "),
           call. = FALSE)
  }

  if (!is.null(W)) {
    W_type <- match.arg(W_type, c("categorical", "continuous"))
  }

  ## ---- 3. form & Na -------------------------------------------------------
  form <- match.arg(form, c("P", "CN", "CP", "PC"))
  Na   <- match.arg(Na,   c("DE", "FIML", "MI"))

  ## ---- 4. scalar integer parameters --------------------------------------
  assert_scalar_int(R,        "R",        lower = 1)
  assert_scalar_int(bootstrap,"bootstrap",lower = 0)
  if (Na == "MI") {
    assert_scalar_int(m,      "m",        lower = 1)
  }

  ## ---- 5. ci_level --------------------------------------------------------
  if (!is.numeric(ci_level) || length(ci_level) != 1 ||
      ci_level <= 0 || ci_level >= 1)
    stop("ci_level must be between 0 and 1 (e.g., 0.95).", call. = FALSE)

  ## ---- 6. ci_method -------------------------------------------------------
  ci_method <- if (is.null(ci_method)) {
    switch(Na, MI = "mc", FIML = "mc", DE = "bootstrap")
  } else {
    match.arg(ci_method, c("bootstrap","mc","both"))
  }

  if (Na == "MI" && ci_method == "bootstrap") {
    warning("CI method 'bootstrap' is not supported with MI; using 'mc'.",
            call. = FALSE)
  }
  if (Na == "DE" && ci_method == "bootstrap" && bootstrap == 0)
    stop("bootstrap = 0 but ci_method = 'bootstrap'.", call. = FALSE)

  ## ---- 7. MCmethod --------------------------------------------------------
  if (is.null(MCmethod)) {
    MCmethod <- "mc"
  } else if (!MCmethod %in% c("mc","bootSD")) {
    stop("MCmethod must be 'mc', 'bootSD', or NULL.", call. = FALSE)
  }

  ## ---- 8. control-variable columns ---------------------------------------
  check_cols(C_C1, "C_C1")
  check_cols(C_C2, "C_C2")
  check_cols(C,     "C")

  ## ---- 9. mediator count by form -----------------------------------------
  k <- length(M_C1)
  if (form == "CN" && k < 2)
    stop("Form 'CN' requires at least 2 mediators.", call. = FALSE)
  if (form %in% c("PC","CP") && k < 3)
    stop("Forms 'PC' and 'CP' require at least 3 mediators.", call. = FALSE)

  invisible(TRUE)
}



#' Assert a scalar (whole-number) integer with optional bounds
#' @keywords internal
assert_scalar_int <- function(x,
                              name       = deparse(substitute(x)),
                              lower      = NULL,
                              upper      = NULL,
                              allow_null = FALSE) {

  # ---- 1. NULL 处理 -------------------------------------------------------
  if (is.null(x)) {
    if (allow_null) return(invisible(TRUE))
    stop(sprintf("%s must not be NULL.", name), call. = FALSE)
  }

  # ---- 2. 标量整数检查 ----------------------------------------------------
  ok <- is.numeric(x) && length(x) == 1L && !is.na(x) && (x == as.integer(x))
  if (!ok) {
    stop(sprintf("%s must be a single whole number (e.g., 5 or 5L).", name),
         call. = FALSE)
  }

  # ---- 3. 上下界 ----------------------------------------------------------
  if (!is.null(lower) && x < lower)
    stop(sprintf("%s must be >= %s.", name, lower), call. = FALSE)
  if (!is.null(upper) && x > upper)
    stop(sprintf("%s must be <= %s.", name, upper), call. = FALSE)

  invisible(TRUE)
}


#' Null-coalescing operator
#'
#' Returns \code{x} unless it is \code{NULL}, otherwise returns \code{y}.
#'
#' @name null_coalesce
#' @aliases %||%
#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else y



#' Verbose message wrapper (internal)
#' @keywords internal
.v <- function(..., verbose = TRUE) if (verbose) message(...)

#' Debug printer with indentation (internal)
#' @keywords internal
dbg <- function(..., .lvl = 0, verbose = TRUE) {
  if (verbose) {
    pref <- paste(rep(".", .lvl), collapse = "")
    message("[DBG] ", pref, sprintf(...))
  }
}

#' Fit SEM and run Monte-Carlo draws
#'
#' @keywords internal
.fit_and_mc <- function(sem_model, data,
                        Na      = c("DE","FIML"),
                        R       = 20000,
                        alpha   = 0.05,
                        fixed.x = FALSE,
                        verbose = TRUE) {

  Na <- match.arg(Na)
  miss_opt <- if (Na == "DE") "listwise" else "fiml"

  fit <- lavaan::sem(sem_model,
                     data    = data,
                     missing = miss_opt,
                     fixed.x = fixed.x,
                     warn    = FALSE)

  if (!lavaan::lavInspect(fit, "converged"))
    warning("lavaan did not converge.")

  list(
    fit    = fit,
    result = MC(lav = fit, R = R, alpha = alpha)
  )
}

#' Create moderation output for wsMed
#'
#' @keywords internal
.make_moderation <- function(mc_res, data,
                             W,
                             MP      = NULL,
                             W_type  = c("categorical","continuous"),
                             alpha   = 0.05,
                             verbose = TRUE) {

  W_type <- match.arg(W_type)
  dbg("[MAKE_MODERATION] W = %s ; W_type = %s",
      paste(W, collapse = ", "), W_type, verbose = verbose)

  ## ---- A. 抽样矩阵 -------------------------------------------------------
  theta_draws <- if (is.matrix(mc_res) || is.data.frame(mc_res)) {
    as.matrix(mc_res)
  } else if (!is.null(mc_res$thetahatstar)) {          # semmcci
    mc_res$thetahatstar
  } else if (!is.null(mc_res$result$thetahatstar)) {   # 另一种嵌套
    mc_res$result$thetahatstar
  } else {
    stop(".make_moderation(): cannot locate Monte-Carlo draws.", call. = FALSE)
  }
  dbg(". theta_draws dim = %d x %d",
      nrow(theta_draws), ncol(theta_draws),
      verbose = verbose)

  ## ---- B. 无调节 ---------------------------------------------------------
  if (is.null(W)) {
    dbg(". W = NULL -> basic contrasts", verbose = verbose)
    basic <- calc_basic_contrasts(theta_draws, ci_level = 1 - alpha)
    return(list(
      type         = "none",
      IE_contrasts = basic$IE_contrasts %||% NULL,
      Xcoef        = basic$Xcoef        %||% NULL
    ))
  }

  ## ---- C. 分类调节 -------------------------------------------------------
  if (W_type == "categorical") {
    dbg(". categorical moderation branch", verbose = verbose)
    cat_out <- analyze_mm_categorical(
      mc_result     = theta_draws,
      prepared_data = data,
      MP            = MP,
      ci_level      = 1 - alpha
    )
    return(list(
      type                = "categorical",
      conditional_IE      = cat_out$conditional_IE,
      IE_contrasts        = cat_out$IE_contrasts,
      extra               = cat_out$extra,
      conditional_overall = cat_out$conditional_overall,
      overall_contrasts   = cat_out$overall_contrasts
    ))
  }

  ## ---- D. 连续调节 -------------------------------------------------------
  dbg(". continuous moderation branch", verbose = verbose)
  cont_out <- analyze_mm_continuous(
    mc_result   = theta_draws,
    data        = data,
    MP          = MP,
    W_raw_name  = W[1],
    ci_level    = 1 - alpha
  )
  cont_out$type <- "continuous"
  cont_out
}





