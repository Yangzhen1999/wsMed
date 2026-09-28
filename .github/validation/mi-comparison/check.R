# Catch formula rank/translation failures for both moderator types. These are
# pipeline tests, not finite-sample coverage assertions.
source(".github/validation/mi-comparison/run.R")
if (!requireNamespace("smcfcs", quietly = TRUE)) stop("Install suggested package smcfcs for this check.")
for (scenario in 5:8) {
  s <- simulation_design()[scenario, ]
  d <- simulation_data(s$n, s$type, 0, 99)
  d$yd <- d$y2-d$y1
  x <- model.matrix(~ I(m2-m1)*W + I((m1+m2)/2), d)
  stopifnot(qr(x)$rank == ncol(x))
  incomplete <- simulation_data(s$n, s$type, s$missing, 99)
  supplied <- compatible_complete(incomplete, 2, 100)
  stopifnot(identical(unname(supplied$predictorMatrix["m1", ]), c(0, 0, 1, 1)))
  z <- comparison_one(s, 1L, "smcfcs", draws = 300L)
  stopifnot(nrow(z) == 3L, all(is.na(z$error)), all(is.finite(z$estimate)),
    all(z$lower < z$upper), all(z$invalid_fraction >= 0 & z$invalid_fraction < 1))
}
cat("Model-compatible MI: four scenario/formula/analysis smoke checks passed.\n")
