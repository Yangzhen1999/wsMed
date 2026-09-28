# Fast design/pipeline checks, not an empirical coverage test.
library(wsMed)
source(".github/validation/standardization-simulation.R")
for (type in c("continuous", "categorical")) {
  d <- simulation_data(300000, type, 0, 671)
  empirical <- var(d$y2-d$y1)
  stopifnot(abs(empirical/simulation_truth(type)$variance_y - 1) < .015)
  expected_raw <- c(.02, .16, .42)
  stopifnot(isTRUE(all.equal(simulation_truth(type)$raw, expected_raw)))
}
design <- simulation_design()
out <- do.call(rbind, lapply(seq_len(nrow(design)), function(j)
  simulation_one(design[j, ], replicate = 2L, draws = 300L)))
stopifnot(nrow(out) == 24, all(is.na(out$error)),
  all(is.finite(out$estimate)), all(out$se > 0), all(out$lower < out$upper),
  all(out$invalid_fraction >= 0 & out$invalid_fraction < 1))
summary <- simulation_summary(out)
stopifnot(all(summary$attempted == 1), all(summary$successful == 1),
  all(summary$coverage >= 0 & summary$coverage <= 1))
# A failed analysis remains in the denominator and is never dropped silently.
failed <- out[1, ]; failed$replicate <- 3L
failed[c("estimate", "se", "lower", "upper")] <- NA_real_
failed$error <- "injected failure"
s <- simulation_summary(rbind(out[1, ], failed))
stopifnot(s$attempted == 2, s$successful == 1, s$failure_rate == .5)
stopifnot(s$coverage_wilson_lower >= 0, s$coverage_wilson_upper <= 1,
  s$coverage_wilson_lower <= s$coverage, s$coverage <= s$coverage_wilson_upper)
none <- simulation_summary(failed)
stopifnot(none$successful == 0, none$coverage_all_attempts == 0,
  is.na(none$coverage_wilson_lower), is.na(none$coverage_wilson_upper))
recorded <- read.csv(".github/validation/standardization-replicates.csv")
stored <- read.csv(".github/validation/standardization-summary.csv")
stopifnot(!anyDuplicated(recorded[c("scenario", "replicate", "probe")]))
recomputed <- simulation_summary(recorded)
recomputed <- recomputed[order(recomputed$scenario, recomputed$probe), ]
stopifnot(isTRUE(all.equal(recomputed, stored, check.attributes = FALSE, tolerance = 1e-12)))
cat("Simulation truth, eight analysis scenarios, and failure accounting: OK\n")
