# A reproducible finite-sample study, kept outside the CRAN package/test runtime.
# Rscript .github/validation/standardization-simulation.R output reps draws scenarios
# Example: ... output 200 2000 1,2,3,4,5,6,7,8
simulation_design <- function() {
  d <- expand.grid(type = c("continuous", "categorical"), n = c(150L, 500L),
    missing = c(0, .2), stringsAsFactors = FALSE)
  d$scenario <- seq_len(nrow(d)); d
}

simulation_truth <- function(type, w = c(-1, 0, 1)) {
  # M = a + aw*W + eM; Y = cp + cpw*W + (b+bw*W)*M + d*A + eY.
  # W, A, eM, eY are independent; Var(A)=Var(eM)=Var(eY)=1.
  # W is N(0,1) or discrete uniform {-1,0,1}. Both have E(W)=E(W^3)=0.
  a <- .4; aw <- .3; b <- .4; bw <- .2; cpw <- .1; d <- .2
  ew2 <- if (type == "continuous") 1 else 2/3
  ew4 <- if (type == "continuous") 3 else 2/3
  vy <- (cpw + b*aw + bw*a)^2 * ew2 + (bw*aw)^2 * (ew4 - ew2^2) +
    b^2 + bw^2 * ew2 + d^2 + 1
  list(variance_y = vy, raw = (a + aw*w)*(b + bw*w),
    marginal = (a + aw*w)*(b + bw*w)/sqrt(vy))
}

simulation_data <- function(n, type, missing, seed) {
  set.seed(seed)
  w <- if (type == "continuous") rnorm(n) else sample(c(-1, 0, 1), n, replace = TRUE)
  avg <- rnorm(n); m <- .4 + .3*w + rnorm(n)
  y <- .2 + .1*w + (.4 + .2*w)*m + .2*avg + rnorm(n)
  y1 <- rnorm(n)
  d <- data.frame(y1 = y1, y2 = y1 + y, m1 = avg-m/2, m2 = avg+m/2,
    W = if (type == "continuous") w else factor(w, levels = c(-1, 0, 1), labels = c("low", "mid", "high")))
  if (missing > 0) {
    d$m1[runif(n) < missing] <- NA
    d$y2[runif(n) < missing] <- NA
  }
  d
}

simulation_one <- function(s, replicate, draws) {
  # Each scenario/replicate has independent, recorded data, MI and MC seeds.
  seed <- 100000L + 10000L*s$scenario + replicate*3L
  warnings <- character()
  failure <- NA_character_
  results <- tryCatch(withCallingHandlers({
    d <- simulation_data(s$n, s$type, s$missing, seed)
    model <- wsMed::wsmed_model(c(before = "y1", after = "y2"),
      list(M = c(before = "m1", after = "m2")),
      moderator = list(variable = "W", interactions = "M -> Y"))
    f <- wsMed::wsmed_fit(model, d, missing = if (s$missing > 0) "mi" else "error",
      mi = list(m = 5, seed = seed + 1L))
    i <- wsMed::wsmed_infer(f, draws = draws, seed = seed + 2L)
    probes <- if (s$type == "continuous") c(-1, 0, 1) else c("low", "mid", "high")
    r <- wsMed::wsmed_effects(i, at = list(W = probes), scale = "marginal")
    data.frame(probe = c(-1, 0, 1), truth = simulation_truth(s$type)$marginal,
      estimate = r$table$estimate, se = r$table$std.error,
      lower = confint(r)[, 1], upper = confint(r)[, 2],
      invalid_fraction = 1 - nrow(r$draws)/draws,
      missing_cells = mean(is.na(d[c("m1", "y2")])),
      incomplete_rows = mean(!complete.cases(d)))
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error = function(e) { failure <<- conditionMessage(e); NULL })
  if (is.null(results)) results <- data.frame(probe = c(-1, 0, 1),
    truth = simulation_truth(s$type)$marginal, estimate = NA_real_, se = NA_real_,
    lower = NA_real_, upper = NA_real_, invalid_fraction = NA_real_,
    missing_cells = NA_real_, incomplete_rows = NA_real_)
  settings <- s[rep(1L, nrow(results)), , drop = FALSE]; rownames(settings) <- NULL
  cbind(settings, replicate = replicate, data_seed = seed, mi_seed = seed + 1L,
    mc_seed = seed + 2L, draws = draws, results,
    warning = paste(unique(warnings), collapse = " | "), error = failure)
}

simulation_summary <- function(results) {
  pieces <- split(results, interaction(results$scenario, results$probe, drop = TRUE))
  do.call(rbind, lapply(pieces, function(d) {
    ok <- complete.cases(d[c("estimate", "se", "lower", "upper")])
    x <- d[ok, ]; n <- nrow(x)
    coverage <- if (n) mean(x$lower <= x$truth & x$truth <= x$upper) else NA_real_
    empirical_se <- if (n > 1) sd(x$estimate) else NA_real_
    z <- qnorm(.975)
    center <- (coverage + z^2/(2*n))/(1 + z^2/n)
    half <- z*sqrt(coverage*(1-coverage)/n + z^2/(4*n^2))/(1 + z^2/n)
    cbind(d[1, c("scenario", "type", "n", "missing", "probe", "truth")],
      attempted = nrow(d), successful = n, failure_rate = mean(!ok),
      bias = if (n) mean(x$estimate-x$truth) else NA_real_,
      bias_mcse = empirical_se/sqrt(n), empirical_se = empirical_se,
      rms_model_se = if (n) sqrt(mean(x$se^2)) else NA_real_,
      coverage = coverage, coverage_mcse = sqrt(coverage*(1-coverage)/n),
      coverage_wilson_lower = if (n) max(0, center-half) else NA_real_,
      coverage_wilson_upper = if (n) min(1, center+half) else NA_real_,
      coverage_all_attempts = sum(ok & d$lower <= d$truth & d$truth <= d$upper, na.rm = TRUE)/nrow(d),
      mean_invalid_fraction = if (n) mean(x$invalid_fraction) else NA_real_,
      warning_rate = mean(nzchar(d$warning)))
  }))
}

simulation_run <- function(output, reps = 200L, draws = 2000L, selected = 1:8) {
  stopifnot(requireNamespace("wsMed", quietly = TRUE))
  stopifnot(reps >= 2L, draws >= 100L, !anyNA(selected), all(selected %in% 1:8), !anyDuplicated(selected))
  if (file.exists(output)) stop("Output directory already exists; preserve prior results.")
  dir.create(output, recursive = TRUE)
  design <- simulation_design(); design <- design[design$scenario %in% selected, ]
  write.csv(design, file.path(output, "design.csv"), row.names = FALSE)
  capture.output(sessionInfo(), file = file.path(output, "sessionInfo.txt"))
  all_results <- list(); k <- 0L
  for (j in seq_len(nrow(design))) for (r in seq_len(reps)) {
    k <- k + 1L; all_results[[k]] <- simulation_one(design[j, ], r, draws)
    if (r %% 10L == 0L || r == reps) {
      results <- do.call(rbind, all_results)
      write.csv(results, file.path(output, "replicates.csv"), row.names = FALSE)
      write.csv(simulation_summary(results), file.path(output, "summary.csv"), row.names = FALSE)
      message("Scenario ", design$scenario[j], ": ", r, "/", reps)
    }
  }
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args)) stop("Specify a new output directory; optional reps, draws, scenario IDs.")
  simulation_run(args[1],
    reps = if (length(args) >= 2L) as.integer(args[2]) else 200L,
    draws = if (length(args) >= 3L) as.integer(args[3]) else 2000L,
    selected = if (length(args) >= 4L) as.integer(strsplit(args[4], ",", fixed = TRUE)[[1]]) else 1:8)
}
