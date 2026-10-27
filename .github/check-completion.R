# rcmdcheck can return without a parsed ERROR after R CMD check exits early.
# Require the checker's completion marker independently of the action status.
check_completion <- function(directory) {
  logs <- list.files(directory, pattern = "^00check\\.log$",
                     recursive = TRUE, full.names = TRUE)
  if (!length(logs)) stop("No R CMD check log was produced.")
  for (path in logs) {
    contents <- readLines(path, warn = FALSE)
    if (!any(grepl("^\\* DONE[[:space:]]*$", contents))) {
      stop("R CMD check did not finish: ", path,
           ". Inspect the preceding output for an early termination.")
    }
    if (any(grepl("^Status:.*[1-9][0-9]* (ERROR|WARNING)", contents))) {
      stop("R CMD check reported errors or warnings: ", path)
    }
  }
  message("Completed R CMD check logs verified: ", length(logs))
  invisible(logs)
}
