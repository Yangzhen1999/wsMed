PrepareMissingData <- function(data_missing,
                               m = 5,
                               method = "pmm",
                               seed = 123,
                               M_before,
                               M_after,
                               Y_before,
                               Y_after) {
  # Step 1: 插补数据
  imputed_result <- ImputeData(
    data_missing = data_missing,
    m = m,
    method = method,
    seed = seed
  )

  # 获取插补后的数据集列表
  imputed_data_list <- imputed_result$imputed_data_list

  # Step 2: 对每个插补数据集进行数据处理
  processed_data_list <- lapply(imputed_data_list, function(imputed_data) {
    PrepareData(
      data = imputed_data,
      M_before = M_before,
      M_after = M_after,
      Y_before = Y_before,
      Y_after = Y_after
    )
  })

  # 返回处理后的数据集列表
  return(list(
    processed_data_list = processed_data_list,
    imputation_summary = imputed_result$summary  # 插补过程的诊断信息
  ))
}
