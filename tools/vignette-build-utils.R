# Canonical text hashes survive Git's platform-specific line endings.
vignette_text_hash <- function(paths) {
  value <- unlist(lapply(paths, function(p) c(basename(p), readLines(p, warn = FALSE, encoding = "UTF-8"))), use.names = FALSE)
  tmp <- tempfile()
  on.exit(unlink(tmp))
  writeBin(charToRaw(enc2utf8(paste(value, collapse = "\n"))), tmp)
  unname(tools::md5sum(tmp))
}

vignette_build_index <- function(root, output_dir) {
  sources <- sort(list.files(file.path(root, "vignettes"), "\\.Rmd\\.original$", full.names = TRUE), method = "radix")
  code <- sort(list.files(file.path(root, "R"), "\\.[Rr]$", full.names = TRUE), method = "radix")
  names <- sub("\\.Rmd\\.original$", "", basename(sources))
  titles <- vapply(sources, function(p) {
    text <- readLines(p, warn = FALSE, encoding = "UTF-8")
    title <- grep("VignetteIndexEntry", text, value = TRUE)
    if (length(title) != 1L) stop("Expected one vignette title: ", p)
    sub(".*VignetteIndexEntry\\{(.*)\\}.*", "\\1", title)
  }, character(1))
  rendered <- file.path(output_dir, paste0(names, ".Rmd"))
  html <- file.path(root, "inst", "doc", paste0(names, ".html"))
  if (!all(file.exists(rendered))) stop("Missing rebuilt tutorials: ", paste(names[!file.exists(rendered)], collapse = ", "))
  data.frame(Article = names, Title = unname(titles),
    Source = vapply(sources, vignette_text_hash, character(1)),
    Rendered = vapply(rendered, vignette_text_hash, character(1)),
    HTML = vapply(html, function(p) if (file.exists(p)) vignette_text_hash(p) else "not-rendered", character(1)),
    Code = vignette_text_hash(code), stringsAsFactors = FALSE)
}

check_frozen_vignettes <- function(root) {
  path <- file.path(root, "vignettes", "build-manifest.dcf")
  if (!file.exists(path)) stop("Rebuild tutorials before packaging: missing build-manifest.dcf.")
  expected <- vignette_build_index(root, file.path(root, "vignettes"))
  stored <- as.data.frame(read.dcf(path), stringsAsFactors = FALSE)
  rownames(expected) <- rownames(stored) <- NULL
  if (!identical(stored, expected)) stop("Tutorial sources, package code or rendered tutorials changed; run rebuild_vignettes().")
  installed_sources <- file.path(root, "inst", "doc", paste0(expected$Article, ".Rmd"))
  if (!all(file.exists(installed_sources)) || !identical(unname(vapply(installed_sources, vignette_text_hash, character(1))), expected$Rendered))
    stop("Installed tutorial sources are stale; run rebuild_vignettes() in the repository.")
  if (!all(file.exists(file.path(root, "inst", "doc", paste0(expected$Article, ".html")))))
    stop("Missing prebuilt HTML tutorials; run rebuild_vignettes().")
  invisible(expected)
}

check_installed_vignettes <- function(root, lib, expected = NULL) {
  if (is.null(expected)) expected <- check_frozen_vignettes(root)
  installed <- find.package("wsMed", lib.loc = lib)
  index <- utils::vignette(package = "wsMed", lib.loc = lib)$results
  # R adds an '(source, pdf)' suffix to display titles; inspect the stored index.
  meta <- readRDS(file.path(installed, "Meta", "vignette.rds"))
  ids <- sub("\\.[Rr]md$", "", basename(meta$File))
  if (!setequal(ids, expected$Article) || anyDuplicated(ids)) stop("Installed tutorial inventory differs from sources.")
  if (!identical(as.character(meta$Title[match(expected$Article, ids)]), expected$Title))
    stop("Installed tutorial titles differ from sources.")
  if (is.null(index) || nrow(index) != nrow(expected)) stop("Installed tutorials are not discoverable through vignette().")
  installed_sources <- file.path(installed, "doc", paste0(expected$Article, ".Rmd"))
  if (!all(file.exists(installed_sources)) ||
      !identical(unname(vapply(installed_sources, vignette_text_hash, character(1))), expected$Rendered))
    stop("Installed tutorial content differs from the validated build inputs.")
  for (id in expected$Article) {
    html <- file.path(installed, "doc", paste0(id, ".html"))
    if (!file.exists(html) || file.info(html)$size == 0) stop("Missing installed HTML tutorial: ", id)
    text <- paste(readLines(html, warn = FALSE), collapse = "\n")
    tags <- regmatches(text, gregexpr('<img[^>]+src=["\x27][^"\x27]+["\x27]', text, perl = TRUE))[[1]]
    for (tag in tags) {
      src <- sub('.*src=["\x27]([^"\x27]+)["\x27].*', '\\1', tag, perl = TRUE)
      if (!grepl("^(data:|https?:|//)", src) && !file.exists(file.path(dirname(html), utils::URLdecode(src))))
        stop("Missing installed tutorial image: ", src)
    }
  }
  message("Installed tutorial inventory, titles and images verified: ", nrow(expected))
  invisible(expected)
}
