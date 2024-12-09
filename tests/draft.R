test_that("draft", {
  skip("This test is skipped for demonstration purposes")

library(lavaan)
library(haven)
library(semhelpinghands)
ea <- read_sav("C:/Users/Administrator/Desktop/IN.sav")
read
SimpleMed <- function(data, M_before, M_after, Y_before, Y_after, standardized = FALSE, bootstrap = NULL, iseed = NULL, se = "standard") {
  # prepare data
  prepared_data <- preparedata(data = data,
                               M_before = M_before,
                               M_after = M_after,
                               Y_before = Y_before,
                               Y_after = Y_after)
  # build the model
  sem_model <- GenerateModel(prepared_data)

  # fit the model
  fit <- lavaan::sem(
    sem_model,
    data = prepared_data,
    se = se,
    bootstrap = bootstrap,
    iseed = iseed
  )

  # 返回拟合结果
  return(list(
    model_summary = summary(fit, fit.measures = TRUE, standardized = standardized),
    lavaan_fit = fit,
    sem_model = sem_model,
    prepared_data = prepared_data
  ))
}


fit_med <- sem(model, data = data, se = "boot",
               bootstrap = 10000, iseed = 47319)


summary(fit_med, ci = TRUE, standardized = TRUE)
std_med_boot_ci <- standardizedSolution_boot_ci(fit_med)
 fit <- lavaan::sem(sem_model, data = prepared_data, missing = "fiml")
example_data <- data.frame(
  M1_before = rnorm(100),
  M1_after = rnorm(100),
  M2_before = rnorm(100),
  M2_after = rnorm(100),
  Y_before = rnorm(100),
  Y_after = rnorm(100)
)

prepared_data <- preparedata(data = ea,
                             M_before = "A2",
                             M_after = "A1",
                             Y_before = "B2",
                             Y_after = "B1")

results <- SimpleMed(
  data = ea,
   M_before = c("A2", "B2"),
                             M_after = c("A1", "B1"),
                             Y_before = "C2",
                             Y_after = "C1")
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123
)

# 使用示例
# 假设数据集中包含以下列：
# M_before: c("M1_pre", "M2_pre")
# M_after: c("M1_post", "M2_post")
# Y_before: "Y_pre"
# Y_after: "Y_post"

# 示例调用
# result <- SimpleMed(data, M_before = c("M1_pre", "M2_pre"), M_after = c("M1_post", "M2_post"), Y_before = "Y_pre", Y_after = "Y_post")

# 查看结果
# print(result$model_summary)
# cat(result$lavaan_model)  # 查看生成的 lavaan 模型公式
library(psych)
df <- data("Tal.Or", package = "psych")
set.seed(42)
df <- mice::ampute(Tal.Or)$amp

model <- "
  reaction ~ cp * cond + b * pmi
  pmi ~ a * cond
  indirect := a * b
  direct := cp
  total := cp + (a * b)
"

model <- '
  # 回归方程
  Ydiff ~ cp*1 + b1*M1diff + b2*M2diff + d1*M1avg + d2*M2avg
  M1diff ~ a1*1
  M2diff ~ a2*1

  # 间接效应
  indirect1 := a1 * b1
  indirect2 := a2 * b2

  # 总间接效应
  total_indirect := indirect1 + indirect2
  # 总效应
  total_effect := cp + total_indirect
'

model <- '
  # 回归方程
  Ydiff ~ cp*1 + b1*M1diff + b2*M2diff + d1*M1avg + d2*M2avg
  M2diff ~ a2*1 + b3*M1diff + d3*M1avg
  M1diff ~ a1*1

  # 间接效应
  indirect1 := a1 * b1
  indirect2 := a2 * b2
  indirect3 := a1 * b3 * b2

  # 总间接效应
  total_indirect := indirect1 + indirect2 + indirect3
  # 总效应
  total_effect := cp + total_indirect
'


fit <- lavaan::sem(model, data = Tal.Or)
fit <- lavaan::sem(model, data = prepared_data)
fit <- lavaan::sem(model, data = df, missing = "fiml")
summary(fit)

# 查看方差-协方差矩阵
vcov_matrix <- vcov(fit)

# 打印矩阵
print(vcov_matrix)
diag(vcov_matrix)
lavaan::inspect(fit, "converged")
summary(prepared_data)
cor(prepared_data, use = "complete.obs")


results <- SimpleMed(
  data = ea,
  M_before = c("A2", "B2"),
  M_after = c("A1", "B1"),
  Y_before = "C2",
  Y_after = "C1",
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123,
  se = "boot"
)

results$std_result
results2 <- SimpleMed(
  data = ea,
  M_before = c("A2", "B2"),
  M_after = c("A1", "B1"),
  Y_before = "C2",
  Y_after = "C1",
  form = "Cn",
  standardized = FALSE,
)


results <- SimpleMed(
  data = ea,
  M_before = c("A2", "B2", "C2"),
  M_after = c("A1", "B1", "C1"),
  Y_before = "D2",
  Y_after = "D1",
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123,
  se = "boot"
)

results <- SimpleMed(
  data = eaN,
  M_before = c("A2", "B2"),
  M_after = c("A1", "B1"),
  Y_before = "D2",
  Y_after = "D1",
  form = "CP",
  standardized = TRUE,
  Na = "MI",
)

results$mcmi_result

results$sem_model
results$lavaan_fit

results <- SimpleMed(
  data = ea,
  M_before = c("A2", "B2", "C2", "D2"),
  M_after = c("A1", "B1", "C1", "D1"),
  Y_before = "A3",
  Y_after = "B3",
  form = "PC",
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123,
  se = "boot"
)

results
set.seed(123) # 确保结果可重复
eaN <- mice::ampute(
  data = ease,       # 输入完整数据
  prop = 0.1,      # 缺失值比例 (20%)
  patterns = NULL, # 使用默认的缺失模式
  mech = "MAR"     # 缺失机制为 MAR (Missing at Random)
)$amp

summary(eaN)


# 调用综合函数，生成 MCMI 输入对象
mcmi_input <- GenerateMCMIInput(
  data = eaN,
  M_before = c("A2", "B2", "C2"),
  M_after = c("A1", "B1", "C1"),
  Y_before = "D2",
  Y_after = "D1",
  m = 5L,
  seed = 42
)

mi <- mice::mice(
  data = eaN,
  print = FALSE,
  m = 5L, # use a large value e.g., 100L for actual research,
  seed = 42
)

# 查看结果
print(mcmi_input)

# 假设想保留 A1, A2, B1, B2 列
ease <- ea[, c("A1", "A2", "B1", "B2", "C1", "C2", "D1", "D2")]
# 查看保留的列
head(ease)

# 提取第一个插补数据集
imputed_data_1 <- mice::complete(mcmi_input, action = 1)


# 查看插补后的数据
head(imputed_data_1)
class(mcmi_input)
print(mcmi_input)
names(mcmi_input$data)
# 提取插补前的原始数据
original_data <- mice::complete(new_mi, action = 0)
# 检查插补数据是否存在结构问题
imputed_data_all <- mice::complete(mcmi_input, action = "all")
lapply(imputed_data_all, function(data) dim(data)) # 检查每个插补数据集的维度

})
# 安装 usethis 包（如果尚未安装）
install.packages("usethis")

# 加载 usethis 包
library(usethis)

# 创建 vignettes 文件夹并生成模板
usethis::use_vignette("getting-started")
