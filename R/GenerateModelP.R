GenerateModelP <- function(prepared_data) {
  # 提取生成的变量名称
  Mdiff_vars <- grep("M\\ddiff", colnames(prepared_data), value = TRUE)
  Mavg_vars <- grep("M\\davg", colnames(prepared_data), value = TRUE)

  regression_y <- paste(
    "Ydiff ~ cp*1",  # 截距部分
    paste(
      c(
        paste0("b", seq_along(Mdiff_vars), "*", Mdiff_vars),  # 动态生成每个 Mdiff 的回归系数
        paste0("d", seq_along(Mavg_vars), "*", Mavg_vars)    # 动态生成每个 Mavg 的回归系数
      ),
      collapse = " + "  # 用 " + " 拼接所有部分
    ),
    sep = " + "  # 确保 cp*1 和后续项之间有分隔符
  )

  # 2. 每个 Mdiff 的截距模型
  regression_m <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0(Mdiff_vars[i], " ~ a", i, "*1")
    }),
    collapse = "\n"
  )

  # 3. 每个间接效应公式
  indirect_effects <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      paste0("indirect", i, " := a", i, " * b", i)
    }),
    collapse = "\n"
  )

  # 4. 总间接效应
  total_indirect <- paste0(
    "total_indirect := ",
    paste(paste0("indirect", seq_along(Mdiff_vars)), collapse = " + ")
  )

  # 5. 总效应
  total_effect <- "total_effect := cp + total_indirect"

  # 6. 间接效应的对比公式
  indirect_contrasts <- ""
  if (length(Mdiff_vars) > 1) {
    indirect_combinations <- combn(seq_along(Mdiff_vars), 2)
    indirect_contrasts <- paste(
      apply(indirect_combinations, 2, function(pair) {
        paste0(
          "CI", pair[1],"vs", pair[2],
          " := indirect", pair[1], " - indirect", pair[2]
        )
      }),
      collapse = "\n"
    )
  }

  # 7. 前后测系数
  pre_post_coefficients <- paste(
    sapply(seq_along(Mdiff_vars), function(i) {
      x1_bi <- paste0("X1_b", i, " := (2*b", i, " + d", i, ") / 2")
      x0_bi <- paste0("X0_b", i, " := X1_b", i, " - d", i)
      paste(x1_bi, x0_bi, sep = "\n")
    }),
    collapse = "\n"
  )

  # 合并所有公式
  sem_model <- paste(
    regression_y,
    regression_m,
    indirect_effects,
    total_indirect,
    total_effect,
    indirect_contrasts,
    pre_post_coefficients,
    sep = "\n"
  )

  return(sem_model)
}
