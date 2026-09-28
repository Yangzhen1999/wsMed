library(testthat)
test_that("analyze_mm_categorical works on wsMed categorical output", {

  data(example_data)
  set.seed(20250625)

  # Run a minimal wsMed analysis
  result6 <- wsMed(
    data   = example_data,
    M_C1   = c("A1","B1","C1"),
    M_C2   = c("A2","B2","C2"),
    Y_C1   = "D1",
    Y_C2   = "D2",
    W      = "Group",           W_type = "categorical",
    MP     = c("a1","b1","d1","cp","b_1_2","b_2_3"),
    form   = "CN",
    R      = 250               # Use fewer Monte Carlo draws for fast tests
  )

  # Extract draws and prepared data
  theta   <- result6$mc$result$thetahatstar
  prepdat <- result6$data
  MP_vec  <- c("a1","b1","d1","cp","b_1_2","b_2_3")

  # Call the function under test
  cat_out <- analyze_mm_categorical(
    mc_result     = theta,
    prepared_data = prepdat,
    MP            = MP_vec,
    ci_level      = .95,
    digits        = 4
  )

  # Assert the output structure
  expect_type(cat_out, "list")
  expect_equal(cat_out$type, "categorical")

  expect_setequal(
    names(cat_out),
    c("type",
      "conditional_IE", "IE_contrasts",
      "conditional_overall", "overall_contrasts",
      "extra")
  )

  # Check groups and row counts
  groups <- sort(unique(prepdat$Group))
  g      <- length(groups)

  # Conditional indirect-effect rows equal paths times groups
  expect_false(is.null(cat_out$conditional_IE))
  n_path <- length(unique(cat_out$conditional_IE$IE))
  expect_equal(
    nrow(cat_out$conditional_IE),
    n_path * g
  )
  expect_setequal(unique(cat_out$conditional_IE$Group), groups)

  # Contrast rows equal group pairs times paths
  expect_false(is.null(cat_out$IE_contrasts))
  expect_equal(
    nrow(cat_out$IE_contrasts),
    n_path * choose(g, 2)
  )

  # There are two overall effects per group
  expect_equal(
    nrow(cat_out$conditional_overall),
    g * 2
  )
  expect_setequal(unique(cat_out$conditional_overall$Effect),
                  c("total_indirect","total_effect"))

  # Overall contrasts equal group pairs times two effects
  expect_equal(
    nrow(cat_out$overall_contrasts),
    choose(g, 2) * 2
  )

  ## -------- 6. extra: path_levels / contrasts -
  expect_true(is.list(cat_out$extra))
  expect_setequal(names(cat_out$extra),
                  c("path_levels","path_contrasts"))

  pl <- cat_out$extra$path_levels
  pc <- cat_out$extra$path_contrasts
  expect_true(nrow(pl) > 0 && nrow(pc) > 0)

  # Path-level rows equal the number of MP terms times groups
  expect_equal(
    nrow(pl),
    length(MP_vec) * g
  )

  # Check CI column names
  ci_pattern <- "%CI\\.Lo$|%CI\\.Up$"
  expect_true(any(grepl(ci_pattern, names(cat_out$conditional_IE))))
  expect_true(any(grepl(ci_pattern, names(cat_out$conditional_overall))))
})
