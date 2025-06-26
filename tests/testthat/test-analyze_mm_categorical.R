test_that("analyze_mm_categorical works on wsMed categorical output", {

  set.seed(20250625)

  ## -------- 1. 运行一个最小 wsMed() -----------
  result6 <- wsMed(
    data   = example_data,
    M_C1   = c("A1","B1","C1"),
    M_C2   = c("A2","B2","C2"),
    Y_C1   = "D1",
    Y_C2   = "D2",
    W      = "Group",           W_type = "categorical",
    MP     = c("a1","b1","d1","cp","b_1_2","b_2_3"),
    form   = "CN",
    R      = 250               # Monte-Carlo 样本缩小
  )

  ## -------- 2. 提取 theta + 预处理数据 ---------
  theta   <- result6$mc$result$thetahatstar
  prepdat <- result6$data
  MP_vec  <- c("a1","b1","d1","cp","b_1_2","b_2_3")

  ## -------- 3. 调用待测函数 -------------------
  cat_out <- analyze_mm_categorical(
    mc_result     = theta,
    prepared_data = prepdat,
    MP            = MP_vec,
    ci_level      = .95,
    digits        = 4
  )

  ## -------- 4. 结构断言 -----------------------
  expect_type(cat_out, "list")
  expect_equal(cat_out$type, "categorical")

  expect_setequal(
    names(cat_out),
    c("type",
      "conditional_IE", "IE_contrasts",
      "conditional_overall", "overall_contrasts",
      "extra")
  )

  ## -------- 5. 组别与行数一致性 ---------------
  groups <- sort(unique(prepdat$Group))
  g      <- length(groups)

  # 5.1 conditional_IE 行数 = #path × #group
  expect_false(is.null(cat_out$conditional_IE))
  n_path <- length(unique(cat_out$conditional_IE$IE))
  expect_equal(
    nrow(cat_out$conditional_IE),
    n_path * g
  )
  expect_setequal(unique(cat_out$conditional_IE$Group), groups)

  # 5.2 IE_contrasts 行数 = choose(g,2) × #path
  expect_false(is.null(cat_out$IE_contrasts))
  expect_equal(
    nrow(cat_out$IE_contrasts),
    n_path * choose(g, 2)
  )

  # 5.3 conditional_overall: 每组 2 行 (total_indirect / total_effect)
  expect_equal(
    nrow(cat_out$conditional_overall),
    g * 2
  )
  expect_setequal(unique(cat_out$conditional_overall$Effect),
                  c("total_indirect","total_effect"))

  # 5.4 overall_contrasts 行数 = choose(g,2) × 2
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

  # path_levels 行数 = length(MP) × g
  expect_equal(
    nrow(pl),
    length(MP_vec) * g
  )

  ## -------- 7. CI 列名格式 --------------------
  ci_pattern <- "%CI\\.Lo$|%CI\\.Up$"
  expect_true(any(grepl(ci_pattern, names(cat_out$conditional_IE))))
  expect_true(any(grepl(ci_pattern, names(cat_out$conditional_overall))))
})
