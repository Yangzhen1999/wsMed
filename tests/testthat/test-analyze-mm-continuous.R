library(testthat)

test_that("analyze_mm_continuous works on wsMed output (continuous W)", {

  set.seed(20250625)       # 可复现

  ## ------------ 1. run a *minimal* wsMed() -----------
  ws_out <- wsMed(
    data = example_data,
    M_C1 = c("A1","B1","C1"),
    M_C2 = c("A2","B2","C2"),
    Y_C1 = "D1",            Y_C2 = "D2",
    form = "CP",
    W    = "D3",            W_type = "continuous",
    MP   = c("a1","b2","d1","cp","b_1_2","d_1_2"),
    R = 250                # Monte-Carlo 抽样数降到 250
  )

  theta   <- ws_out$mc$result$thetahatstar
  prepdat <- ws_out$data
  MP_vec  <- ws_out$input_vars$MP   # 或直接用上面那行常量

  ## ------------ 2. 调用待测函数 -----------------------
  MP_vec <- c("a1","b2","d1","cp","b_1_2","d_1_2")

  cont_out <- analyze_mm_continuous(
    mc_result  = theta,
    data       = prepdat,
    MP         = MP_vec,
    W_raw_name = "D3",
    ci_level   = .95,
    n_curve    = 40,         # 曲线分辨率缩小
    digits     = 4
  )

  ## ------------ 3. 基本结构断言 -----------------------
  expect_type(cont_out, "list")

  # ① 必含 6 个命名元素
  expect_setequal(names(cont_out),
                  c("mod_coeff","beta_coef","path_HML",
                    "conditional_overall",
                    "theta_curve","path_curve","IE_contrasts", "path_contrasts"))

  # ② mod_coeff 检测到与 MP 对应的调节列
  expect_false(is.null(cont_out$mod_coeff))
  expect_true(all(
    grepl("^(aw|bw|dw|cpw)", cont_out$mod_coeff$Path)
  ))

  # 至少要覆盖 MP 中的每个基础系数
  expect_true(all(
    unique(cont_out$mod_coeff$BaseCoef) %in% MP_vec
  ))

  # ③ beta_coef 有三行 × 每条路径
  expect_setequal(
    unique(cont_out$beta_coef$Level),
    c("-1 SD","0 SD","+1 SD")
  )

  # 路径名称来自 get_indirect_paths，至少要包含 b_1_2 的那条
  expect_true(any(grepl("1_2", cont_out$beta_coef$Path)))

  # ④ path_HML 行数应 = length(unique(baseCoef)) × 3
  expect_equal(
    nrow(cont_out$path_HML),
    length(unique(cont_out$path_HML$Path)) * 3
  )

  # ⑤ conditional_overall 应有 total_indirect + total_effect × 3 level = 6
  expect_equal(nrow(cont_out$conditional_overall), 6)

  # ⑥ theta_curve 至少包含 total_indirect / total_effect 曲线
  expect_true(
    all(c("total_indirect","total_effect") %in%
          unique(cont_out$theta_curve$Path))
  )

  # ⑦ W_raw 序列长度 = n_curve
  expect_equal(
    length(unique(cont_out$theta_curve$W_raw)),
    40
  )

  # ⑧ CI 列名格式检查
  expect_true(any(grepl("%CI.Lo$", names(cont_out$beta_coef))))
  expect_true(any(grepl("%CI.Up$", names(cont_out$beta_coef))))
})
