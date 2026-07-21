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
                                  form  = c("P", "CN", "CP", "PC", "UD"),
                                  paths = NULL,
                                  Na    = c("DE", "FIML", "MI"),
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
  form <- match.arg(
    form,
    c("P", "CN", "CP", "PC", "UD")
  )

  if (form == "UD") {

    if (is.null(paths)) {
      stop(
        "`paths` must be supplied when `form = \"UD\"`.",
        call. = FALSE
      )
    }

    if (!is.character(paths) ||
        length(paths) == 0L ||
        anyNA(paths) ||
        any(!nzchar(trimws(paths)))) {
      stop(
        paste0(
          "`paths` must be a non-empty character vector ",
          "when `form = \"UD\"`."
        ),
        call. = FALSE
      )
    }

  } else if (!is.null(paths)) {

    stop(
      "`paths` can only be supplied when `form = \"UD\"`.",
      call. = FALSE
    )
  }

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

  ## ---- 6. ci_method --------------------------------------------------------
  allowed_methods <- c("mc", "bootstrap", "both")

  ci_method <- if (is.null(ci_method)) {
    switch(Na,
           DE   = "bootstrap",
           FIML = "mc",
           MI   = "mc")
  } else {
    match.arg(ci_method, allowed_methods)
  }

  # ── 合法性规则
  # 1) MI 只能用 mc
  if (Na == "MI" && ci_method != "mc") {
    stop("With Na = 'MI', only ci_method = 'mc' is supported.",
         call. = FALSE)
  }

  # 2) DE / FIML 若涉及 bootstrap (bootstrap 或 both)，bootstrap 次数必须 > 0
  if (Na %in% c("DE", "FIML") &&
      ci_method %in% c("bootstrap", "both") &&
      bootstrap == 0) {
    stop("`bootstrap` must be > 0 when ci_method involves bootstrap.",
         call. = FALSE)
  }


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

  if (form == "CN" && k < 2L) {
    stop(
      "Form 'CN' requires at least 2 mediators.",
      call. = FALSE
    )
  }

  if (form %in% c("PC", "CP") && k < 3L) {
    stop(
      "Forms 'PC' and 'CP' require at least 3 mediators.",
      call. = FALSE
    )
  }

  if (form == "UD" && k < 1L) {
    stop(
      "Form 'UD' requires at least one mediator.",
      call. = FALSE
    )
  }

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

  debug_enabled <- isTRUE(
    getOption("wsMed.debug", FALSE)
  )

  if (isTRUE(verbose) && debug_enabled) {
    pref <- paste(rep(".", .lvl), collapse = "")

    message(
      "[DBG] ",
      pref,
      sprintf(...)
    )
  }

  invisible(NULL)
}
#' Fit SEM and run Monte-Carlo draws
#'
#' @keywords internal
.fit_and_mc <- function(sem_model, data,
                        Na        = c("DE", "FIML"),
                        R         = 20000,
                        alpha     = 0.05,
                        fixed.x   = FALSE,
                        verbose   = TRUE,
                        run_mc    = TRUE) {
  # 0) 解析缺失处理方式
  Na <- match.arg(Na)
  miss_opt <- if (Na == "DE") "listwise" else "fiml"

  # 1) 拟合模型 --------------------------------------------------------------
  fit <- lavaan::sem(sem_model,
                     data    = data,
                     missing = miss_opt,
                     fixed.x = fixed.x,
                     warn    = FALSE)

  if (!lavaan::lavInspect(fit, "converged"))
    warning("lavaan did not converge.")

  # 2) 可选 Monte-Carlo 抽样
  mc_out <- NULL
  if (run_mc) {
    if (verbose) message("  -- Monte-Carlo draws...")
    mc_out <- semmcci::MC(lav = fit, R = R, alpha = alpha)
  } else {
    if (verbose) message("  -- Monte-Carlo skipped (ci_method = 'bootstrap')")
  }

  # 3) 返回
  list(
    fit    = fit,     # lavaan 对象
    result = mc_out   # 可能是 NULL
  )
}


#' Create moderation output for wsMed
#'
#' @keywords internal
.make_moderation <- function(mc_res, data,
                             W           = NULL,
                             MP          = NULL,
                             W_type      = c("categorical", "continuous", "none"),  ## ***
                             alpha       = 0.05,
                             verbose     = FALSE) {

  ## ---- 0. W & W_type 预处理 --------------------------------------------- ##
  # * 若没有 W，则强制 W_type = "none"
  if (is.null(W) || length(W) == 0L) {
    W_type <- "none"                                                  ## ***
  } else {
    W_type <- match.arg(W_type)       # "categorical" / "continuous"
  }

  dbg("[MAKE_MODERATION] W = %s ; W_type = %s",
      if (is.null(W)) "<NULL>" else paste(W, collapse = ", "),
      W_type, verbose = verbose)

  ## ---- A. 抽样矩阵 -------------------------------------------------------
  theta_draws <- if (is.matrix(mc_res) || is.data.frame(mc_res)) {
    as.matrix(mc_res)
  } else if (!is.null(mc_res$thetahatstar)) {
    mc_res$thetahatstar
  } else if (!is.null(mc_res$result$thetahatstar)) {
    mc_res$result$thetahatstar
  } else {
    stop(".make_moderation(): cannot locate Monte-Carlo draws.", call. = FALSE)
  }
  dbg(". theta_draws dim = %d x %d",
      nrow(theta_draws), ncol(theta_draws), verbose = verbose)

  ## ---- B. 无调节（basic contrasts） --------------------------------------
  if (W_type == "none") {                                               ## ***
    dbg(". W_type = 'none' -> basic contrasts", verbose = verbose)
    basic <- calc_basic_contrasts(theta_draws, ci_level = 1 - alpha)

    return(list(
      type         = "none",
      IE_contrasts = if (is.null(basic$IE_contrasts)) NULL else basic$IE_contrasts,
      Xcoef        = if (is.null(basic$Xcoef))        NULL else basic$Xcoef
    ))
  }

  ## ---- C. 分类调节 -------------------------------------------------------
  if (W_type == "categorical") {
    dbg(". categorical moderation branch", verbose = verbose)

    cat_out <- analyze_mm_categorical(
      mc_result     = theta_draws,          ## 可直接传矩阵版本
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




#' Add missing indirect-effect columns to a bootstrap matrix
#'
#' @param theta_boot Numeric matrix/data.frame: bootstrap draws (rows * free-parameters).
#' @param sem_model  Character: lavaan syntax containing \code{:=} definitions.
#' @param prefix     Prefix of derived names to insert (default \code{"indirect_"}).
#' @param warn       Emit a warning when RHS variables are absent (default \code{TRUE}).
#'
#' @return Same type as \code{theta_boot} with extra columns, if any.
#' @keywords internal
#' @noRd

.add_indirect_boot <- function(theta_boot,
                              sem_model,
                              prefix = "indirect_",
                              warn   = TRUE) {

  stopifnot(is.matrix(theta_boot) || is.data.frame(theta_boot),
            is.character(sem_model))

  ## 1. 提取所有 “name := formula” 行 -----------------------------
  sem_lines  <- trimws(unlist(strsplit(sem_model, "\n")))
  def_lines  <- grep(":=", sem_lines, value = TRUE)
  if (!length(def_lines))
    return(theta_boot)          # 模型里没定义派生量，直接返回

  parts      <- strsplit(def_lines, ":=")
  def_names  <- trimws(vapply(parts, `[`, 1, FUN.VALUE = ""))
  def_rhs    <- trimws(vapply(parts, `[`, 2, FUN.VALUE = ""))

  ## 2. 只保留以 prefix 开头、且在矩阵中还缺失的间接效应 ------
  sel        <- startsWith(def_names, prefix) &
    !(def_names %in% colnames(theta_boot))
  if (!any(sel))
    return(theta_boot)

  def_names  <- def_names[ sel ]
  def_rhs    <- def_rhs  [ sel ]

  ## 3. 逐个公式计算并追加
  df_boot <- as.data.frame(theta_boot)     # 方便 with() 评估
  for (i in seq_along(def_names)) {
    nm  <- def_names[i]
    rhs <- def_rhs[i]

    ## 检查公式里用到的列是否存在
    vars_in_rhs <- all.vars(parse(text = rhs))
    miss_cols   <- setdiff(vars_in_rhs, names(df_boot))
    if (length(miss_cols)) {
      if (warn)
        warning(sprintf("add_indirect_boot(): '%s' skipped - missing columns: %s",
                        nm, paste(miss_cols, collapse = ", ")), call. = FALSE)
      next
    }

    ## 向量化计算
    df_boot[[nm]] <- with(df_boot, eval(parse(text = rhs)))
  }

  ## 4. 保持原结构返回（matrix in, matrix out; data.frame in, data.frame out）
  if (is.matrix(theta_boot)) {
    cbind(theta_boot, as.matrix(df_boot[setdiff(names(df_boot),
                                                colnames(theta_boot))]))
  } else {
    df_boot
  }
}


