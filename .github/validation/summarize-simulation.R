# Recompute every reported summary from the retained per-attempt results.
# Run from the repository root; never overwrite the recorded study by default.
source(".github/validation/standardization-simulation.R")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify input replicate CSV and a new output summary CSV.")
if (file.exists(args[2])) stop("Output already exists; preserve prior summaries.")
results <- read.csv(args[1], stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(results[c("scenario", "replicate", "probe")]))
out <- simulation_summary(results)
out <- out[order(out$scenario, out$probe), ]
write.csv(out, args[2], row.names = FALSE)
