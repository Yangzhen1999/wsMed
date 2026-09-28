choice_case_args <- function() {
  e <- new.env()
  data("example_data", package = "wsMed", envir = e)
  list(data = e$example_data,
       M_C1 = c("A1", "B1", "C1"), M_C2 = c("A2", "B2", "C2"),
       Y_C1 = "D1", Y_C2 = "D2", R = 40L)
}

# Stop after real input validation, before expensive estimation. This also
# checks the canonical values that will control the downstream model dispatch.
capture_choice_settings <- function(arguments = list()) {
  validate <- wsMed:::validate_wsMed_inputs
  testthat::local_mocked_bindings(
    validate_wsMed_inputs = function(...) {
      supplied <- list(...)
      do.call(validate, supplied)
      stop(errorCondition("validated", class = "wsmed_validated",
                          settings = supplied[c("form", "Na", "ci_method")]))
    },
    .package = "wsMed"
  )
  tryCatch(
    do.call(wsMed, modifyList(choice_case_args(), arguments, keep.null = TRUE)),
    wsmed_validated = function(e) e$settings
  )
}

test_that("all valid choice combinations accept different letter cases", {
  variants <- list(identity, tolower, toupper,
                   function(x) paste0(toupper(substr(x, 1L, 1L)),
                                      tolower(substring(x, 2L))))
  for (form in c("P", "CN", "CP", "PC", "UD")) {
    for (na in c("DE", "FIML", "MI")) {
      for (ci in if (na == "MI") "mc" else c("mc", "bootstrap", "both")) {
        expected <- list(form = form, Na = na, ci_method = ci)
        for (variant in variants) {
          supplied <- lapply(expected, variant)
          if (form == "UD") {
            supplied$paths <- c("M1 -> Y", "M2 -> Y", "M3 -> Y")
          }
          expect_identical(capture_choice_settings(supplied), expected)
          validator_args <- modifyList(choice_case_args(), supplied)
          expect_true(do.call(wsMed:::validate_wsMed_inputs, validator_args))
        }
      }
    }
  }
})

test_that("defaults, NULL and existing unambiguous abbreviations are preserved", {
  defaults <- list(form = "P", Na = "DE", ci_method = "mc")
  expect_identical(capture_choice_settings(), defaults)
  expect_identical(capture_choice_settings(list(form = NULL, Na = NULL,
                                               ci_method = NULL)), defaults)
  expect_identical(capture_choice_settings(list(
    form = c("P", "CN", "CP", "PC", "UD"),
    Na = c("DE", "FIML", "MI"), ci_method = c("mc", "bootstrap", "both")
  )), defaults)
  expect_identical(capture_choice_settings(list(Na = "F", ci_method = "m")),
                   list(form = "P", Na = "FIML", ci_method = "mc"))
  expect_identical(capture_choice_settings(list(Na = "f", ci_method = "M")),
                   list(form = "P", Na = "FIML", ci_method = "mc"))
  expect_identical(capture_choice_settings(list(ci_method = "BOO")),
                   list(form = "P", Na = "DE", ci_method = "bootstrap"))
  expect_identical(capture_choice_settings(list(ci_method = "BOT")),
                   list(form = "P", Na = "DE", ci_method = "both"))
})

test_that("invalid values and ambiguous choices still fail", {
  for (argument in c("form", "Na", "ci_method")) {
    for (value in list("invalid", "", NA_character_, character(),
                       c("invalid", "other"), 1, TRUE, factor("P"))) {
      expect_error(capture_choice_settings(setNames(list(value), argument)))
      expect_error(do.call(wsMed:::validate_wsMed_inputs,
                          modifyList(choice_case_args(),
                                     setNames(list(value), argument))))
    }
  }
  expect_error(capture_choice_settings(list(form = "c")))
  expect_error(capture_choice_settings(list(ci_method = "B")))
  expect_error(capture_choice_settings(list(form = c("p", "cn"))))
  expect_error(capture_choice_settings(list(Na = c("de", "mi"))))
  expect_error(capture_choice_settings(list(ci_method = c("MC", "BOTH"))))
})

test_that("normalizing case preserves cross-argument restrictions", {
  for (ci in c("BOOTSTRAP", "BoTh")) {
    args <- list(Na = "mi", ci_method = ci)
    expect_error(capture_choice_settings(args), "only ci_method = 'mc'")
    expect_error(do.call(wsMed:::validate_wsMed_inputs,
                        modifyList(choice_case_args(), args)),
                 "only ci_method = 'mc'")
  }
  expect_error(capture_choice_settings(list(form = "ud")), "paths.*must be supplied")
  expect_error(capture_choice_settings(list(form = "p", paths = "M1 -> Y")),
               "paths.*only be supplied")
  expect_error(capture_choice_settings(list(form = "cp", M_C1 = "A1", M_C2 = "A2")),
               "require at least 3 mediators")
  expect_error(capture_choice_settings(list(Na = "de", ci_method = "BOTH", bootstrap = 0)),
               "bootstrap.*must be > 0")
  expect_error(capture_choice_settings(list(M_C1 = c("a1", "B1", "C1"))),
               "Missing columns")
  # The validator's own historical NULL default differs from wsMed()'s default.
  expect_error(do.call(wsMed:::validate_wsMed_inputs,
                      c(choice_case_args(), list(Na = "de", bootstrap = 0))),
               "bootstrap.*must be > 0")
})

test_that("real model fits give equal results after case normalization", {
  cases <- list(list(form = "p", Na = "de", ci_method = "MC"),
                list(form = "cn", Na = "de", ci_method = "Mc"),
                list(form = "cP", Na = "de", ci_method = "MC"),
                list(form = "pc", Na = "de", ci_method = "MC"),
                list(form = "Ud", Na = "de", ci_method = "MC",
                     paths = c("M1 -> M3", "M3 -> Y", "M2 -> Y")),
                list(form = "p", Na = "fImL", ci_method = "MC"),
                list(form = "p", Na = "mI", ci_method = "MC"))
  for (supplied in cases) {
    args <- choice_case_args()
    if (toupper(supplied$Na) != "DE") {
      args$data[seq_len(5L), "A1"] <- NA_real_
      args$mi_args <- list(m = 2L)
    }
    canonical <- supplied
    canonical$form <- toupper(canonical$form)
    canonical$Na <- toupper(canonical$Na)
    canonical$ci_method <- tolower(canonical$ci_method)
    set.seed(9123)
    reference <- do.call(wsMed, modifyList(args, canonical))
    set.seed(9123)
    actual <- do.call(wsMed, modifyList(args, supplied))
    expect_s3_class(actual, "wsMed")
    expect_identical(actual[c("form", "Na", "ci_method")],
                     reference[c("form", "Na", "ci_method")])
    expect_identical(actual$sem_model, reference$sem_model)
    expect_equal(lavaan::coef(actual$mc$fit), lavaan::coef(reference$mc$fit))
    expect_equal(actual$mc$result$thetahat, reference$mc$result$thetahat)
    expect_equal(actual$mc$result$thetahatstar, reference$mc$result$thetahatstar)
    expect_equal(actual$moderation, reference$moderation)
  }
})
