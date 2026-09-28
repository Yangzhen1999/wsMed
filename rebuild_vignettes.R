# Rebuild frozen vignettes from executable *.Rmd.original sources.
# From the repository root: source("rebuild_vignettes.R"); rebuild_vignettes()
# Or: Rscript rebuild_vignettes.R [package_root] [output_directory]
# A separate output directory permits validation without updating frozen files.
# Use articles = "ModularWorkflow" to rebuild only the staged-workflow tutorial.
# Use articles = "CategoricalPredictors" to rebuild the categorical examples.
# Use articles = "WorkflowReliability" for diagnostics, manifests, and migration.
# Use articles = "CompatibleImputation" for external model-aware MI; install
# the suggested smcfcs package to execute its substantive-model example.
# Edit executable sources as .Rmd temporarily, then restore .Rmd.original before
# running this helper. Frozen .Rmd files are generated output, not source files.
rebuild_vignettes <- function(root = getwd(), output_dir = file.path(root, "vignettes"),
                             articles = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  description <- file.path(root, "DESCRIPTION")
  if (!file.exists(description) || read.dcf(description)[1, "Package"] != "wsMed") {
    stop("root must be the wsMed package directory.")
  }
  for (package in c("knitr", "pkgload")) {
    if (!requireNamespace(package, quietly = TRUE)) stop("Install package: ", package)
  }
  inputs <- sort(list.files(file.path(root, "vignettes"),
                            pattern = "\\.Rmd\\.original$", full.names = TRUE))
  if (!length(inputs)) stop("No .Rmd.original vignette sources found.")
  if (!is.null(articles)) {
    available <- sub("\\.Rmd\\.original$", "", basename(inputs))
    if (!is.character(articles) || !length(articles) || anyNA(articles) ||
        anyDuplicated(articles) || any(!articles %in% available)) {
      stop("articles must name existing .Rmd.original sources without extensions.")
    }
    inputs <- inputs[match(articles, available)]
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)
  old_wd <- getwd()
  old_chunk <- knitr::opts_chunk$get()
  old_knit <- knitr::opts_knit$get()
  on.exit({
    setwd(old_wd)
    knitr::opts_chunk$restore(old_chunk)
    knitr::opts_knit$restore(old_knit)
  }, add = TRUE)
  pkgload::load_all(root, quiet = TRUE)
  setwd(output_dir)
  outputs <- character(length(inputs))
  for (i in seq_along(inputs)) {
    name <- sub("\\.Rmd\\.original$", "", basename(inputs[i]))
    knitr::opts_chunk$restore(old_chunk)
    knitr::opts_knit$restore(old_knit)
    knitr::opts_chunk$set(cache = FALSE, error = FALSE,
                         fig.path = paste0("figure/", name, "-"))
    knitr::opts_knit$set(root.dir = output_dir)
    outputs[i] <- file.path(output_dir, paste0(name, ".Rmd"))
    message("Rebuilding ", basename(inputs[i]))
    knitr::knit(inputs[i], output = outputs[i],
                envir = new.env(parent = globalenv()), quiet = TRUE)
  }
  # Model diagrams referenced by the source vignettes must travel with them.
  diagrams <- list.files(file.path(root, "inst", "extdata"),
                         pattern = "^W[a-d]\\.png$", full.names = TRUE)
  if (length(diagrams) && !all(file.copy(diagrams, output_dir, overwrite = TRUE))) {
    stop("Could not copy vignette model diagrams.")
  }
  invisible(outputs)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  root <- if (length(args)) args[1] else getwd()
  output_dir <- if (length(args) >= 2L) args[2] else file.path(root, "vignettes")
  rebuild_vignettes(root, output_dir)
}
