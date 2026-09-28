# Assemble compatibility tables from already fitted objects and stored draws.
.wsmed_assemble <- function(fit, inferences, alpha, standardized, verbose = FALSE) {
  prep <- fit$data
  sem_model <- fit$sem_model
  Na <- fit$Na
  form <- fit$model$form
  paths <- fit$model$paths
  v <- fit$model$input_vars
  M_C1 <- v$M_C1; M_C2 <- v$M_C2; Y_C1 <- v$Y_C1; Y_C2 <- v$Y_C2
  C_C1 <- v$C_C1; C_C2 <- v$C_C2; C <- v$C; C_type <- v$C_type
  W <- v$W; W_type <- v$W_type; MP <- v$MP
  need_mc <- !is.null(inferences$mc)
  need_boot <- !is.null(inferences$bootstrap)
  ci_method <- if (need_mc && need_boot) "both" else if (need_mc) "mc" else "bootstrap"
  mc <- list(fit = fit$backend[[1]], result = inferences$mc$backend$mc)
  fit_u <- inferences$bootstrap$backend$fit_u
  param_boot <- inferences$bootstrap$backend$bootstrap
  theta_mc <- inferences$mc$draws
  theta_boot <- inferences$bootstrap$draws
  boot_ci_type <- inferences$bootstrap$controls$interval
  if (need_boot) { mc$theta_boot <- theta_boot; mc$bootstrap <- param_boot }
  roles <- .wsmed_roles(prep)
  mc$fit@external$wsmed_roles <- roles
  if (!is.null(mc$result)) mc$result$args$lav@external$wsmed_roles <- roles
  if (!is.null(fit_u)) fit_u@external$wsmed_roles <- roles
  point_estimates <- if (!is.null(mc$result)) mc$result$thetahat$est else ThetaHatWrapper(mc$fit)$est
  make_mod <- function(theta_mat) {
    .make_moderation(
      mc_res  = theta_mat,
      point_estimates = point_estimates,
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

  mc$std_mc   <- NULL
  mc$std_boot <- NULL

  if (standardized) {
    if (need_mc && !is.null(theta_mc)) {
      mc$std_mc <- tryCatch(
        MCStd2(mc$result, alpha = alpha),
        error = function(e) {
          warning("MCStd2 failed: ", e$message)
          NULL
        }
      )
    }

    if (need_boot && exists("fit_u") && !is.null(fit_u)) {
      boot_ci_type <- match.arg(boot_ci_type,
                                choices = c("perc", "bc", "bca.simple"))

      mc$std_boot <- tryCatch(
        .wsmed_std_boot(fit_u, alpha, boot_ci_type),
        error = function(e) {
          warning("wsMed bootstrap standardization failed: ", e$message)
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
    W    = W,    W_type = W_type, MP = MP
  )


  out <- list(
    data       = prep,
    sem_model  = sem_model,
    mc         = mc,
    param_boot = param_boot,
    moderation = moderation,
    alpha      = alpha,
    Na         = Na,
    form       = form,
    ci_method  = ci_method,
    input_vars = input_vars,
    fit_u  = fit_u,
    paths = paths
  )

  class(out) <- "wsMed"
  if (standardized && length(W)) out$moderation_std <- standardize_moderation(out)

  .v(
    "Analysis completed successfully.",
    verbose = verbose
  )

  out$model <- fit$model
  out$fit <- fit
  out$inference <- inferences
  out
}
