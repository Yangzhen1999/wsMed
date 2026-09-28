# Paired follow-up to the original screening study. Run from the repository root.
# Rscript .github/validation/mi-comparison/run.R NEW_OUTPUT SCENARIO [REPS]
source(".github/validation/standardization-simulation.R")

compatible_complete <- function(d, m, seed) {
  # This recipe is specific to the documented DGP: Y1 and M2 and W are observed,
  # and Y1 is independent of the other variables. It is not an automatic recipe
  # for arbitrary two-condition data, serial mediation, or missing moderators.
  stopifnot(!anyNA(d[c("y1", "m2", "W")]))
  z <- data.frame(yd = d$y2-d$y1, m1 = d$m1, m2 = d$m2, W = d$W)
  # smcfcs identifies automatic predictors from literal term labels. Variables
  # used only inside I(...) are not discovered; explicitly preserve m1 | m2,W.
  pred <- matrix(0, ncol(z), ncol(z), dimnames = list(names(z), names(z)))
  pred["m1", c("m2", "W")] <- 1
  set.seed(seed)
  invisible(capture.output(imp <- smcfcs::smcfcs(z, smtype = "lm",
    smformula = "yd ~ I(m2-m1)*W + I((m1+m2)/2)",
    method = c("", "norm", "", ""), predictorMatrix = pred,
    m = m, numit = 20, rjlimit = 5000)))
  completed <- lapply(imp$impDatasets, function(x) {
    out <- d; out$m1 <- x$m1
    missing_y <- is.na(d$y2)
    out$y2[missing_y] <- d$y1[missing_y] + x$yd[missing_y]
    out
  })
  list(completed = completed, trace = imp$smCoefIter, predictorMatrix = pred)
}

comparison_one <- function(s, replicate, method, output = NULL, draws = 2000L) {
  seed <- 100000L + 10000L*s$scenario + replicate*3L
  warning <- character(); error <- NA_character_
  result <- tryCatch(withCallingHandlers({
    d <- simulation_data(s$n, s$type, if (method == "complete") 0 else s$missing, seed)
    model <- wsMed::wsmed_model(c(before = "y1", after = "y2"),
      list(M = c(before = "m1", after = "m2")),
      moderator = list(variable = "W", interactions = "M -> Y"))
    if (method %in% c("smcfcs", "smcfcs20")) {
      imp <- compatible_complete(d, if (method == "smcfcs20") 20L else 5L, seed+1L)
      if (!is.null(output) && replicate == 1L) saveRDS(imp$trace, file.path(output, "imputation-trace.rds"))
      f <- wsMed::wsmed_fit(model, d, missing = "mi", mi = list(completed = imp$completed))
    } else if (method == "pmm") {
      f <- wsMed::wsmed_fit(model, d, missing = "mi", mi = list(m = 5, seed = seed+1L))
    } else {
      stopifnot(method == "complete")
      f <- wsMed::wsmed_fit(model, d)
    }
    i <- wsMed::wsmed_infer(f, draws = draws, seed = seed+2L)
    probes <- if (s$type == "continuous") c(-1, 0, 1) else c("low", "mid", "high")
    raw <- wsMed::wsmed_effects(i, at = list(W = probes), scale = "raw")
    std <- wsMed::wsmed_effects(i, at = list(W = probes), scale = "marginal")
    truth <- simulation_truth(s$type)
    data.frame(probe = c(-1, 0, 1), truth = truth$marginal,
      estimate = std$table$estimate, se = std$table$std.error,
      lower = confint(std)[, 1], upper = confint(std)[, 2],
      invalid_fraction = 1-nrow(std$draws)/draws,
      raw_truth = truth$raw, raw_estimate = raw$table$estimate,
      raw_se = raw$table$std.error, raw_lower = confint(raw)[, 1], raw_upper = confint(raw)[, 2],
      marginal_sd = wsMed::wsmed_reproducibility(f)$analysis$interpretation$marginal_outcome_sd,
      true_sd = sqrt(truth$variance_y))
  }, warning = function(w) {
    warning <<- c(warning, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error = function(e) { error <<- conditionMessage(e); NULL })
  if (is.null(result)) result <- data.frame(probe = c(-1, 0, 1),
    truth = simulation_truth(s$type)$marginal, estimate = NA_real_, se = NA_real_,
    lower = NA_real_, upper = NA_real_, invalid_fraction = NA_real_,
    raw_truth = simulation_truth(s$type)$raw, raw_estimate = NA_real_, raw_se = NA_real_,
    raw_lower = NA_real_, raw_upper = NA_real_, marginal_sd = NA_real_,
    true_sd = sqrt(simulation_truth(s$type)$variance_y))
  settings <- s[rep(1L, 3L), ]; rownames(settings) <- NULL
  cbind(settings, replicate = replicate, method = method, data_seed = seed,
    imputation_seed = if (method == "complete") NA_integer_ else seed+1L,
    mc_seed = seed+2L, draws = draws, result,
    warning = paste(unique(warning), collapse = " | "), error = error)
}

if (sys.nframe() == 0L) {
  stopifnot(requireNamespace("wsMed", quietly = TRUE), requireNamespace("smcfcs", quietly = TRUE))
  args <- commandArgs(trailingOnly = TRUE)
  output <- args[1]; scenario <- as.integer(args[2])
  reps <- if (length(args) >= 3L) as.integer(args[3]) else 200L
  methods <- if (length(args) >= 4L) strsplit(args[4], ",", fixed = TRUE)[[1]] else
    c("pmm", "smcfcs", "complete")
  stopifnot(all(methods %in% c("pmm", "smcfcs", "smcfcs20", "complete")), !anyDuplicated(methods))
  stopifnot(scenario %in% 5:8, reps >= 2L)
  if (file.exists(output)) stop("Use a new output directory.")
  dir.create(output, recursive = TRUE)
  capture.output(sessionInfo(), file = file.path(output, "environment.txt"))
  s <- simulation_design()[scenario, ]; results <- list(); k <- 0L
  for (r in seq_len(reps)) {
    for (method in methods) {
      k <- k+1L; results[[k]] <- comparison_one(s, r, method, output)
    }
    if (r %% 10L == 0L || r == reps) {
      write.csv(do.call(rbind, results), file.path(output, "replicates.csv"), row.names = FALSE)
      message("Scenario ", scenario, ": ", r, "/", reps)
    }
  }
}
