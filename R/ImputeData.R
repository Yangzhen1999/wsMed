ImputeData <- function(data_missing, m = 5, method = "pmm", seed = 123, predictorMatrix = NULL) {
  # 替换 -999 为 NA
  data_missing[data_missing == -999] <- NA

  # 输入检查
  if (!is.data.frame(data_missing)) stop("Input data must be a data frame.")
  if (!all(sapply(data_missing, function(x) is.numeric(x) || is.factor(x)))) stop("All columns must be numeric or factor.")

  # 动态生成 predictorMatrix
  if (is.null(predictorMatrix)) {
    predictorMatrix <- mice::quickpred(data_missing, mincor = 0.1)
  }

  # 动态选择方法
  if (is.null(method)) {
    method <- ifelse(sapply(data_missing, is.numeric), "pmm", "logreg")
  }

  # 插补数据
  imp <- mice::mice(data_missing, m = m, method = method, seed = seed, predictorMatrix = predictorMatrix)

  # 获取插补结果列表
  imputed_data_list <- mice::complete(imp, "all")
  imputed_data_list <- lapply(imputed_data_list, as.data.frame)

  # 生成诊断信息
  summary_imp <- summary(imp)

  return(list(
    imputed_data_list = imputed_data_list,  # 插补后的数据列表
    summary = summary_imp                 # 插补结果的汇总信息
  ))
}
