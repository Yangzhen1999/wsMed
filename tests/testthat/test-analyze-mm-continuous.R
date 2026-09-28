library(testthat)

test_that("analyze_mm_continuous works on wsMed output (continuous W)", {

  set.seed(20250625)       # Reproducible seed

  ## ------------ 1. run a *minimal* wsMed() -----------
  ws_out <- wsMed(
    data = example_data,
    M_C1 = c("A1","B1","C1"),
    M_C2 = c("A2","B2","C2"),
    Y_C1 = "D1",            Y_C2 = "D2",
    form = "CP",
    W    = "D3",            W_type = "continuous",
    MP   = c("a1","b2","d1","cp","b_1_2","d_1_2"),
    R = 250                # Use fewer Monte Carlo draws for fast tests
  )

  theta   <- ws_out$mc$result$thetahatstar
  prepdat <- ws_out$data
  MP_vec  <- ws_out$input_vars$MP   # Retrieve MP from the fitted object

  # Call the function under test
  MP_vec <- c("a1","b2","d1","cp","b_1_2","d_1_2")

  cont_out <- analyze_mm_continuous(
    mc_result  = theta,
    data       = prepdat,
    MP         = MP_vec,
    W_raw_name = "D3",
    ci_level   = .95,
    n_curve    = 40,         # Use a lower curve resolution for fast tests
    digits     = 4
  )

  # Check the basic structure
  expect_type(cont_out, "list")

  # Require the six named components
  expect_setequal(names(cont_out),
                  c("mod_coeff","beta_coef","path_HML",
                    "conditional_overall",
                    "theta_curve","path_curve","IE_contrasts", "path_contrasts"))

  # The moderator-coefficient table includes the MP interaction columns
  expect_false(is.null(cont_out$mod_coeff))
  expect_true(all(
    grepl("^(aw|bw|dw|cpw)", cont_out$mod_coeff$Path)
  ))

  # Include every base coefficient named in MP
  expect_true(all(
    MP_vec %in% unique(cont_out$mod_coeff$BaseCoef)
  ))

  # The coefficient table has three rows per path
  expect_setequal(
    unique(cont_out$beta_coef$Level),
    c("-1 SD","0 SD","+1 SD")
  )

  # Path names from get_indirect_paths include b_1_2
  expect_true(any(grepl("1_2", cont_out$beta_coef$Path)))

  # The high/mean/low table has three rows per unique base coefficient
  expect_equal(
    nrow(cont_out$path_HML),
    length(unique(cont_out$path_HML$Path)) * 3
  )

  # Conditional overall effects have two effect types at three levels
  expect_equal(nrow(cont_out$conditional_overall), 6)

  # The curve contains total indirect and total effects
  expect_true(
    all(c("total_indirect","total_effect") %in%
          unique(cont_out$theta_curve$Path))
  )

  # The raw moderator vector has n_curve entries
  expect_equal(
    length(unique(cont_out$theta_curve$W_raw)),
    40
  )

  # Check CI column names
  expect_true(any(grepl("%CI.Lo$", names(cont_out$beta_coef))))
  expect_true(any(grepl("%CI.Up$", names(cont_out$beta_coef))))
})
