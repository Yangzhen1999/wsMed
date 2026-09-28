# Run from the repository root; the original submission is never overwritten.
root <- normalizePath(getwd(), winslash = "/")
inputs <- file.path(root, ".github", "replication")
output <- Sys.getenv("WSMED_RESULTS_DIR", file.path(inputs, "results"))
dir.create(output, recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(output, winslash = "/")
profile <- Sys.getenv("WSMED_PROFILE", "reference-core")
stopifnot(unname(tools::md5sum(file.path(inputs, "wsMed_examples.sav"))) ==
            "ce2bcbd3fde83a793e94b226892f7453")
expected <- c(wsMed = "1.1.0.9000", lavaan = "0.6-19", mice = "3.17.0",
              haven = "2.5.4", semmcci = "1.1.4.9000",
              semboottools = "0.0.0.9011", MASS = "7.3-65",
              ggplot2 = "4.0.0", knitr = "1.49", xfun = "0.51")
if (profile == "reference-core") {
  stopifnot(getRversion() == package_version("4.4.3"))
  for (p in names(expected)) {
    if (packageVersion(p) != package_version(expected[[p]]))
      stop("Version mismatch for ", p, ": ", packageVersion(p),
           "; expected ", expected[[p]])
  }
}
stopifnot(file.copy(file.path(inputs, "wsMed_examples.sav"), output,
                   overwrite = TRUE))
warnings_seen <- character()
analysis <- new.env(parent = globalenv())
setwd(output)
pdf("figures.pdf", width = 8, height = 6)
tryCatch(
  withCallingHandlers(
    source(file.path(inputs, "reproduce_examples.R"), local = analysis,
           encoding = "UTF-8"),
    warning = function(w) {
      warnings_seen <<- c(warnings_seen, conditionMessage(w))
    }),
  finally = {
    dev.off()
    writeLines(warnings_seen, "warnings.txt")
  }
)
fits <- list(example1 = analysis$result1, example2_pc = analysis$result2_predefined,
             example2_ud = analysis$result2_custom, example3 = analysis$result3)
snapshot <- lapply(fits, function(x) {
  a <- x$mc$result$args
  draws <- x$mc$result$thetahatstar
  list(
    imputations = lapply(a$imputations, function(d) lapply(d, as.numeric)),
    pooled_mean = as.list(a$pooled$est),
    pooled_covariance = list(names = colnames(a$pooled$total),
                             values = unname(a$pooled$total)),
    mc_preview = list(names = colnames(draws),
                      values = unname(draws[seq_len(min(64, nrow(draws))), , drop = FALSE])),
    parameter_tables = x$mc$std_mc,
    conditional_tables = x$moderation,
    standardization_diagnostics = attr(x$mc$std_mc, "standardization_diagnostics"),
    printed = capture.output(print(x, detail = "full")),
    # Preserve normal manuscript formatting, but test numerical agreement
    # before three-decimal rounding can amplify a tiny optimizer difference.
    printed_precise = capture.output(print(x, detail = "full", digits = 10))
  )
})
versions <- vapply(loadedNamespaces(), function(p) packageDescription(p)$Version,
                   character(1))
info <- list(profile = profile, os = Sys.info()[["sysname"]],
             R = R.version.string, commit = Sys.getenv("GITHUB_SHA", "local"),
             versions = as.list(versions), numerical_libraries = as.list(extSoftVersion()),
             warnings = warnings_seen, data_md5 = unname(tools::md5sum("wsMed_examples.sav")))
clean_json <- function(x) {
  if (inherits(x, "table")) return(as.list(setNames(as.numeric(x), names(x))))
  if (is.list(x)) return(lapply(x, clean_json))
  x
}
saveRDS(list(environment = info, fits = snapshot), "snapshot.rds")
jsonlite::write_json(clean_json(list(environment = info, fits = snapshot)), "snapshot.json",
                     auto_unbox = TRUE, digits = NA, pretty = FALSE, null = "null",
                     na = "null")
capture.output(sessionInfo(), extSoftVersion(), RNGkind(), file = "environment.txt")
write.csv(data.frame(package = names(versions), version = unname(versions)),
          "dependencies.csv", row.names = FALSE)
cat("Completed full analysis; snapshot saved to ", output, "\n", sep = "")
