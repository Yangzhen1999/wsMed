TransformMidsWithPrepareData <- function(mids_obj, M_C1, M_C2, Y_C1, Y_C2) {
  # Step 1: 提取插补数据列表
  imputed_list <- mice::complete(mids_obj, action = "all")

  # Step 2: 对每个数据集做 PrepareData()
  transformed_list <- lapply(imputed_list, function(dat) {
    PrepareData(
      data = dat,
      M_C1 = M_C1,
      M_C2 = M_C2,
      Y_C1 = Y_C1,
      Y_C2 = Y_C2
    )
  })

  # Step 3: 合并成 long format 数据
  long_data <- do.call(rbind, transformed_list)
  long_data$.imp <- rep(1:length(transformed_list), each = nrow(transformed_list[[1]]))
  long_data$.id <- rep(1:nrow(transformed_list[[1]]), times = length(transformed_list))

  # Step 4: 用 mice::as.mids 转换为新的 mids 对象
  new_mids <- mice::as.mids(long_data)

  return(new_mids)
}
