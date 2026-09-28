library(testthat)

## ---------------------------------------------------------
# Reproduce the MP filter used by analyze_mm_continuous
filter_by_MP <- function(paths, MP) {
  Filter(function(p) any(p$coefs %in% MP), paths)
}

## ---------------------------------------------------------
# Coefficient sets for five model structures
models <- list(
  modA = c("a1","a2","a3","b1","b2","b3","b_1_2","b_1_3"),
  modB = c("a1","a2","a3","b1","b2","b3","b_3_1","b_2_1","d_3_1"),
  modC = c("a1","a2","a3","b1","b2","b3","b_1_2","b_2_3","b_1_3","d_2_3"),
  modD = c("a1","a2","a3","b1","b2","b3"),                  # No chain between mediators
  modE = c("a1","a2","a3","a4",
           "b1","b2","b3","b4",
           "b_1_2","b_2_3","b_3_4","b_2_4")
)

# Expected path counts
expected_n <- c(modA = 5, modB = 5, modC = 7, modD = 3, modE = 12)

## ---------------------------------------------------------
test_that("get_indirect_paths extracts correct paths for 5 models", {

  for (mdl in names(models)) {

    cols  <- models[[mdl]]
    paths <- get_indirect_paths(cols)

    # Count paths
    expect_equal(length(paths), expected_n[[mdl]],
                 info = paste("model:", mdl, "total paths"))

    # Filter paths containing a1
    p_a1 <- filter_by_MP(paths, "a1")
    expect_true(length(p_a1) >= 1, info = paste(mdl, "MP=a1 non-empty"))
    expect_true(all(vapply(p_a1, \(p) "a1" %in% p$coefs, logical(1))),
                info = paste(mdl, "MP=a1 all contain a1"))

    # Filter paths containing a3 or a4
    p_a34 <- filter_by_MP(paths, c("a3","a4"))
    expect_true(length(p_a34) >= 1, info = paste(mdl, "MP=a3|a4 non-empty"))
    expect_true(all(vapply(p_a34, \(p) any(p$coefs %in% c("a3","a4")), logical(1))),
                info = paste(mdl, "MP=a3|a4 all contain a3/a4"))
  }
})
