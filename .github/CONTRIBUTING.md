# Building and validating wsMed documentation

Work on the appropriate development branch. Ordinary readers should start with
the website's Get started guide; this page is for maintainers.

## Editable sources

Executable tutorial sources are `vignettes/*.Rmd.original`. Edit each as an
`.Rmd`, execute it, then restore `.Rmd.original`. New tutorials follow the same
convention. The neighboring frozen `.Rmd` files are generated output.
Keep examples independently runnable, specify random seeds and show only the
output needed to explain the task. Preserve meaningful statistical qualifications.

## Rebuild and check

```r
source("rebuild_vignettes.R")
rebuild_vignettes()
source("tools/vignette-build-utils.R")
check_frozen_vignettes(getwd())
```

The helper discovers all source tutorials. It also updates `inst/doc` HTML and
images so direct installations include current documentation. Commit sources,
frozen tutorials, generated images, installed documents and `build-manifest.dcf`.
CI validates their freshness before rebuilding.

```r
source("tools/build-release.R")
archive <- build_wsmed_release(getwd(), "../wsMed-candidate-build")
```

Use a new output directory. The build verifies installed tutorial titles and
images; it does not replace R CMD check on the exact source archive.
For a local website preview use `pkgdown::build_site()`; website publication is
a separate action. Add new articles to the categorized `_pkgdown.yml` index and
check all internal links and heading anchors. Preserve existing article URLs.

## Reproducibility and validation

Pin an audited commit for reproducible analyses and save an analysis manifest.
Use the same package build for numerical tables and figures. The simulation
reports in `.github/validation/RESULTS.md` and `.github/validation/mi-comparison/RESULTS.md`
document limitations as well as successful execution. In particular, default MI
can be incompatible with moderation interactions; platform agreement does not
establish nominal coverage. See the model-compatible imputation tutorial.

The website homepage is `pkgdown/index.md`; README.md keeps repository-relative
links suitable for GitHub. Styles live in `pkgdown/extra.css`. Keep the minimal
example consistent with the executable GetStarted tutorial.
