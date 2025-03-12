library(testthat)

####  测试 `printGM()` 兼容所有 `GenerateModel*()` 生成的 SEM 语法**
test_that("printGM correctly formats SEM output for all GenerateModel functions", {
  data(example_data)

  # 预处理数据
  prepared_data <- PrepareData(
    data = example_data,
    M_C1 = c("A1", "B1"),
    M_C2 = c("A2", "B2"),
    Y_C1 = "C1",
    Y_C2 = "C2"
  )

  # 需要测试的四个模型
  model_functions <- list(
    CN = GenerateModelCN,
    CP = GenerateModelCP,
    P  = GenerateModelP,
    PC = GenerateModelPC
  )

  # 逐个测试四个模型
  lapply(names(model_functions), function(model_name) {
    sem_model <- model_functions[[model_name]](prepared_data)

    # 捕获 `print.GM()` 输出
    output <- capture.output(printGM(sem_model))

    # 打印测试进度（可选）
    message("Testing printGM() for model: ", model_name)

    # 确保输出中包含核心部分标题
    expect_true(any(grepl("Outcome Difference Model \\(Ydiff\\)", output)), info = paste(model_name, "missing Ydiff"))
    expect_true(any(grepl("Mediator Difference Model", output)), info = paste(model_name, "missing Mediator Difference Model"))
    expect_true(any(grepl("Indirect Effects", output)), info = paste(model_name, "missing Indirect Effects"))
    expect_true(any(grepl("Total Effect", output)), info = paste(model_name, "missing Total Effect"))
  })
})

test_that("printGM works with wsMed() results", {
  data(example_data)

  result1 <- wsMed(
    data = example_data,
    M_C1 = c("A1", "B1", "C1"),
    M_C2 = c("A2", "B2", "C2"),
    Y_C1 = "D1",
    Y_C2 = "D2",
    form = "P",
    Na = "DE",
    standardized = TRUE,
    bootstrap = 1000,
    iseed = 123
  )

  # 捕获 `printGM()` 输出
  output <- capture.output(printGM(result1))

  # 确保输出中包含核心部分标题
  expect_true(any(grepl("Outcome Difference Model \\(Ydiff\\)", output)), info = "WsMed() output missing Ydiff")
  expect_true(any(grepl("Mediator Difference Model", output)), info = "WsMed() output missing Mediator Difference Model")
  expect_true(any(grepl("Indirect Effects", output)), info = "WsMed() output missing Indirect Effects")
  expect_true(any(grepl("Total Effect", output)), info = "WsMed() output missing Total Effect")
})

####  测试 `printGM()` 的错误处理**
test_that("printGM throws error for invalid inputs", {
  expect_error(printGM(list()), "Input must be a non-empty character string", fixed = TRUE)
  expect_error(printGM(data.frame()), "Input must be a non-empty character string", fixed = TRUE)
  expect_error(printGM(NULL), "Input must be a non-empty character string", fixed = TRUE)
  expect_error(printGM(NA_character_), "Input must be a non-empty character string", fixed = TRUE)
  expect_error(printGM(""), "Input must be a non-empty character string", fixed = TRUE)
})

