# Build and inspect an isolated source archive; never publish or modify Git.
# Rscript tools/build-release.R <package-root> <new-output-directory>
build_wsmed_release <- function(root, output) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  if (file.exists(output)) stop("Choose a new output directory; existing files are never overwritten.")
  for (p in c("pkgbuild", "pkgload", "knitr", "rmarkdown", "smcfcs"))
    if (!requireNamespace(p, quietly = TRUE)) stop("Install build dependency: ", p)
  dir.create(output, recursive = TRUE)
  output <- normalizePath(output, winslash = "/", mustWork = TRUE)
  stage <- file.path(output, "source", "wsMed")
  dir.create(stage, recursive = TRUE)
  items <- c("DESCRIPTION", "NAMESPACE", "NEWS.md", "README.md", ".Rbuildignore",
             "R", "man", "data", "tests", "vignettes", "tools", "rebuild_vignettes.R")
  items <- items[file.exists(file.path(root, items))]
  if (!all(file.copy(file.path(root, items), stage, recursive = TRUE))) stop("Could not stage package files.")
  dir.create(file.path(stage, "inst"))
  # Old inst/doc artifacts must not shadow newly built tutorials.
  inst <- list.files(file.path(root, "inst"), full.names = TRUE)
  inst <- inst[basename(inst) != "doc"]
  if (length(inst) && !all(file.copy(inst, file.path(stage, "inst"), recursive = TRUE))) stop("Could not stage installed assets.")
  e <- new.env(parent = globalenv())
  sys.source(file.path(stage, "rebuild_vignettes.R"), e)
  e$rebuild_vignettes(stage)
  sys.source(file.path(stage, "tools", "vignette-build-utils.R"), e)
  expected <- e$check_frozen_vignettes(stage)
  write.dcf(expected, file.path(output, "tutorial-input-manifest.dcf"))
  archive <- pkgbuild::build(stage, dest_path = output, vignettes = TRUE, manual = FALSE)
  # R CMD build may regenerate inst/doc HTML. Verify unchanged numerical/text
  # inputs separately from those intentionally regenerated presentation files.
  after <- e$vignette_build_index(stage, file.path(stage, "vignettes"))
  rownames(after) <- NULL
  stable <- setdiff(names(expected), "HTML")
  if (!identical(expected[stable], after[stable])) stop("Tutorial inputs changed during source-archive construction.")
  lib <- file.path(output, "library")
  dir.create(lib)
  log <- file.path(output, "install.log")
  status <- system2(file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R"),
    c("CMD", "INSTALL", "-l", shQuote(lib), shQuote(archive)), stdout = log, stderr = log)
  if (status != 0L) stop("Archive installation failed; inspect ", log)
  e$check_installed_vignettes(stage, lib, expected = expected)
  writeLines(c(paste("Archive:", archive), paste("MD5:", tools::md5sum(archive)),
    paste("Tutorials:", nrow(expected)),
    "Installed tutorial inventory, titles and images verified.",
    "This builds a candidate archive; R CMD check and release approval remain separate."), file.path(output, "BUILD-RESULT.txt"))
  invisible(archive)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) stop("Usage: Rscript tools/build-release.R <package-root> <new-output-directory>")
  build_wsmed_release(args[1], args[2])
}
