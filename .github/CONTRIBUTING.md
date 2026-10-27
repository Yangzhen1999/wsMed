# Building and validating wsMed documentation

Work on the appropriate development branch. Ordinary readers should start with
the website's Get started guide; this page is for maintainers.

## Editable sources

Executable tutorial sources are `vignettes/*.Rmd.original`. Edit each as an
`.Rmd`, execute it, then restore `.Rmd.original`. New tutorials follow the same
convention. The neighboring frozen `.Rmd` files are generated output.
Keep examples independently runnable, specify random seeds and show only the
output needed to explain the task. Preserve meaningful statistical qualifications.

Start user tutorials with the simplest call that demonstrates the task. Rely on
the documented defaults of `wsMed()` (including its seed), and show `print()`,
`summary()` and `plot()` before optional selectors or extraction code. Put each
argument on its own line in multiline calls. Introduce explicit settings after
the default workflow, explaining what they change. Installation examples use
CRAN and GitHub `master`; historical validation records retain their audited
versions and commits.

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
Routine CI validates their freshness, then builds and checks the committed
tutorials without repeating their long Monte Carlo and bootstrap analyses.

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

Routine pull requests and main/master pushes run R CMD check on Windows,
macOS and Linux with R-release, plus Linux with R-devel. Package regression
tests remain part of these checks, and an independent completion check rejects
truncated check logs. Development-branch pushes do not also trigger a duplicate
run when a pull request is open. Branches without a pull request can be checked
with the workflow's Run workflow button.

For release preparation, run R-CMD-check manually with `full_validation` enabled.
This adds R-oldrel and the dependencies-only environment, and re-executes all
tutorial sources once on Linux R-release. The checked source-archive installation
is reused to verify installed tutorials; it does not trigger another full rebuild.
Run Manuscript replication and Monte Carlo reproducibility manually before
release and after changes to numerical methods, imputation, standardization or
the manuscript examples. Their numerical references and evidence checks remain
unchanged. The separate package-test matrix has been removed because R CMD check
already runs those tests on the supported platforms.

Website previews run when website inputs change. They use the committed
tutorials after verifying freshness; full tutorial execution belongs to the
validation workflow rather than each website build.

Pin an audited commit for reproducible analyses and save an analysis manifest.
Use the same package build for numerical tables and figures. The simulation
reports in `.github/validation/RESULTS.md` and `.github/validation/mi-comparison/RESULTS.md`
document limitations as well as successful execution. In particular, default MI
can be incompatible with moderation interactions; platform agreement does not
establish nominal coverage. See the model-compatible imputation tutorial.

The website homepage is `pkgdown/index.md`; README.md keeps repository-relative
links suitable for GitHub. Styles live in `pkgdown/extra.css`. Keep the minimal
example consistent with the executable GetStarted tutorial.
