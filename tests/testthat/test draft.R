test_that("draft", {
  skip("This test is skipped for demonstration purposes")

library(knitr)

result1 <- WsMed(
  data = example_data,
  M_before = c("A1","B1","C1"),
  M_after = c("A2","B2"."C2"),
  Y_before = "D1",
  Y_after = "D2",
  form = "P",
  Na = "DE",
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123
)
print(result1)

result2 <- WsMed(
  data = example_dataN,
  M_before = c("A1","B1","C1"),
  M_after = c("A2","B2","C2"),
  Y_before = "D1",
  Y_after = "D2",
  form = "CN",
  Na = "MI",
  standardized = TRUE,
  R = 20000L,  # Monte Carlo 重复次数
  alpha = c(0.001, 0.01, 0.05),  # 显著性水平
  m = 5,  # 插补次数
  method = "pmm",  # 插补方法
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06,
  seed = 123,
  alphastd = c(0.001, 0.01, 0.05)
)
print(result2)

result3 <- WsMed(
  data = example_dataN,
  M_before = c("A1","B1","C1"),
  M_after = c("A2","B2","C2"),
  Y_before = "D1",
  Y_after = "D2",
  form = "CP",
  Na = "FIML",
  standardized = TRUE,
  R = 10000L,  # Monte Carlo 重复次数
  alpha = 0.05,  # 显著性水平
  m = 5,  # 插补次数
  method = "pmm",  # 插补方法
  decomposition = "eigen",
  pd = TRUE,
  tol = 1e-06,
  seed = 234,
  alphastd = 0.05
)
print(result3)


result4 <- WsMed(
  data = example_dataN,
  M_before = c("A1","B1"),
  M_after = c("A2","B2"),
  Y_before = "C1",
  Y_after = "C2",
  form = "CN",
  Na = "MI",
  standardized = TRUE,
)
print(result4)

})
