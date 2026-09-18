# Rebuild frozen vignettes from executable *.Rmd.original sources.
# From the repository root: source("rebuild_vignettes.R"); rebuild_vignettes()
# Or: Rscript rebuild_vignettes.R [package_root] [output_directory]
# A separate output directory permits validation without updating frozen files.
rebuild_vignettes <- function(root = getwd(), output_dir = file.path(root, "vignettes")) {
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
