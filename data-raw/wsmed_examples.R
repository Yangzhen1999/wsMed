# Run from the package root to reproduce the packaged analysis data.
# haven is needed only for this maintenance script, not to load the dataset.
if (!requireNamespace("haven", quietly = TRUE)) stop("Install haven first.")
source_file <- ".github/replication/wsMed_examples.sav"
stopifnot(unname(tools::md5sum(source_file)) == "ce2bcbd3fde83a793e94b226892f7453")
source_data <- haven::read_sav(source_file)
wsmed_examples <- as.data.frame(lapply(source_data, as.numeric))
stopifnot(identical(dim(wsmed_examples), c(123L, 14L)),
          identical(names(wsmed_examples), names(source_data)),
          identical(is.na(wsmed_examples), is.na(source_data)))
for (nm in names(source_data)) {
  stopifnot(identical(wsmed_examples[[nm]], as.numeric(source_data[[nm]])))
}
save(wsmed_examples, file = "data/wsmed_examples.rda", compress = "xz", version = 2)
