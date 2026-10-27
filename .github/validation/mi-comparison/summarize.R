# Rscript .../summarize.R NEW_OUTPUT CSV1 CSV2 CSV3 CSV4
source(".github/validation/standardization-simulation.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 2L)
output <- args[1]
if (file.exists(output)) stop("Use a new output directory.")
all <- do.call(rbind, lapply(args[-1], read.csv, stringsAsFactors = FALSE))
stopifnot(!anyDuplicated(all[c("scenario", "replicate", "method", "probe")]))
dir.create(output, recursive = TRUE)
all <- all[order(all$scenario, all$replicate, all$method, all$probe), ]
write.csv(all, file.path(output, "replicates.csv"), row.names = FALSE)
summaries <- list(); k <- 0L
for (method in unique(all$method)) for (scale in c("marginal", "raw")) {
  d <- all[all$method == method, ]
  if (scale == "raw") {
    d[c("truth", "estimate", "se", "lower", "upper")] <-
      d[c("raw_truth", "raw_estimate", "raw_se", "raw_lower", "raw_upper")]
    d$invalid_fraction <- NA_real_ # the stored fraction pertains to standardized draws
  }
  k <- k+1L; summaries[[k]] <- cbind(method = method, scale = scale, simulation_summary(d))
}
summary <- do.call(rbind, summaries)
summary <- summary[order(summary$scenario, summary$scale, summary$probe, summary$method), ]
write.csv(summary, file.path(output, "summary.csv"), row.names = FALSE)
pmm <- all[all$method == "pmm", ]
paired <- do.call(rbind, lapply(intersect(c("smcfcs", "smcfcs20"), unique(all$method)), function(arm) {
  smc <- all[all$method == arm, ]
  pair <- merge(pmm, smc, by = c("scenario", "replicate", "probe"), suffixes = c(".pmm", ".smc"))
  stopifnot(nrow(pair) == nrow(pmm), nrow(pair) == nrow(smc))
  do.call(rbind, lapply(split(pair, interaction(pair$scenario, pair$probe)), function(d) {
  bias_difference <- d$estimate.smc-d$estimate.pmm
  covered <- function(lower, truth, upper) !is.na(lower) & !is.na(upper) & lower <= truth & truth <= upper
  coverage_difference <- as.numeric(covered(d$lower.smc, d$truth.smc, d$upper.smc)) -
    as.numeric(covered(d$lower.pmm, d$truth.pmm, d$upper.pmm))
  ok <- is.finite(bias_difference)
  data.frame(method = arm, scenario = d$scenario[1], probe = d$probe[1], attempted_pairs = nrow(d),
    successful_pairs = sum(ok), bias_difference = mean(bias_difference[ok]),
    bias_difference_mcse = sd(bias_difference[ok])/sqrt(sum(ok)),
    coverage_difference = mean(coverage_difference),
    coverage_difference_mcse = sd(coverage_difference)/sqrt(nrow(d)))
  }))
}))
write.csv(paired, file.path(output, "paired.csv"), row.names = FALSE)
first_probe <- all[all$probe == 0, ]
denominators <- do.call(rbind, lapply(split(first_probe, interaction(first_probe$scenario, first_probe$method)), function(d) {
  x <- d$marginal_sd-d$true_sd; ok <- is.finite(x)
  data.frame(scenario = d$scenario[1], method = d$method[1], successful = sum(ok),
    true_sd = d$true_sd[1], mean_sd = mean(d$marginal_sd[ok]),
    bias = mean(x[ok]), bias_mcse = sd(x[ok])/sqrt(sum(ok)))
}))
write.csv(denominators, file.path(output, "denominators.csv"), row.names = FALSE)
