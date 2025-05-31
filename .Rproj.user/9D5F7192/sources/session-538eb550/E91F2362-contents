## ----------------------------------------------------------------------------------------------------------------------------
# Simulated example dataset
s_data <- data.frame(
  ID = 1:100,
  M1_C1 = rnorm(100), M1_C2 = rnorm(100),
  M2_C1 = rnorm(100), M2_C2 = rnorm(100),
  Y_C1 = rnorm(100),  Y_C2 = rnorm(100)
)
head(s_data)


## ----include=FALSE-----------------------------------------------------------------------------------------------------------
devtools::load_all()
library(wsMed)


## ----------------------------------------------------------------------------------------------------------------------------
result1 <- wsMed(
  data = example_data, #dataset
  M_C1 = c("A1","B1"), # A1/B1 is A/B mediator variable in condition 1
  M_C2 = c("A2","B2"), # A2/B2 is A/B mediator variable in condition 2
  Y_C1 = "C1", # C1 is outcome variable in condition 1
  Y_C2 = "C2", # C2 is outcome variable in condition 2
  form = "P", # Parallel mediation
)
print(result1)


## ----eval = FALSE------------------------------------------------------------------------------------------------------------
# result1 <- wsMed(
#   data = example_data, #dataset
#   M_C1 = c("A1","B1"), # A1/B1 is A/B mediator variable in condition 1
#   M_C2 = c("A2","B2"), # A2/B2 is A/B mediator variable in condition 2
#   Y_C1 = "C1", # C1 is outcome variable in condition 1
#   Y_C2 = "C2", # C2 is outcome variable in condition 2
#   form = "P", # Parallel mediation
#   ci_method = "mc" # use Monte Carlo confidence intervals
# )
# print(result1)


## ----------------------------------------------------------------------------------------------------------------------------
library(wsMed)
result2 <- wsMed(
  data = example_data, #dataset
  M_C1 = c("A1","B1","C1"), # A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"), # A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1", # D1 is outcome variable in condition 1
  Y_C2 = "D2", # D2 is outcome variable in condition 2
  form = "P", # Parallel mediation
  standardized = TRUE, # Compute standardized effects
  alpha =  0.05,  # Significance level
  alphastd = 0.05, # Significance level for standardized
  bootstrap = 2000, # Bootstrap for confidence intervals
  iseed = 123 # Random seed for bootstrap
)
print(result2)


## ----eval = FALSE------------------------------------------------------------------------------------------------------------
# library(wsMed)
# result2 <- wsMed(
#   data = example_data, #dataset
#   M_C1 = c("A1","B1","C1"), # A1/B1/C1 is A/B/C mediator variable in condition 1
#   M_C2 = c("A2","B2","C2"), # A2/B2/C2 is A/B/C mediator variable in condition 2
#   Y_C1 = "D1", # D1 is outcome variable in condition 1
#   Y_C2 = "D2", # D2 is outcome variable in condition 2
#   form = "P", # Parallel mediation
#   standardized = TRUE, # Compute standardized effects
#   ci_method = "mc", # Use Monte Carlo method for missing data
#   standardized = TRUE, # Compute standardized effects based on Monte Carlo method
#   R = 10000L,   # the number of Monte Carlo repetitions
#   alpha =  0.05,  # Significance level
#   alphastd = 0.05 # Significance level for standardized
# )
# print(result2)


## ----------------------------------------------------------------------------------------------------------------------------
library(knitr)
data(example_data)
set.seed(123)
example_dataN <- mice::ampute(
  data = example_data,
  prop = 0.1,
)$amp


## ----------------------------------------------------------------------------------------------------------------------------
library(wsMed)
result3 <- wsMed(
  data = example_data,# a dataset with missing data
  M_C1 = c("A1","B1"),# A1/B1 is A/B mediator variable in condition 1
  M_C2 = c("A2","B2"),# A2/B2 is A/B mediator variable in condition 2
  Y_C1 = "C1", # C1 is outcome variable in condition 1
  Y_C2 = "C2", # C2 is outcome variable in condition 2
  form = "P",# Parallel mediation
  Na = "DE",# Listwise deletion for the missing data
)
print(result3,digits =4)  # Set number of decimal places to 4 in the output


## ----------------------------------------------------------------------------------------------------------------------------
result4 <- wsMed(
  data = example_dataN,
  M_C1 = c("A1","B1","C1"),# A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"),# A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1", # D1 is outcome variable in condition 1
  Y_C2 = "D2", # D2 is outcome variable in condition 2
  form = "CN", # chained mediation
  Na = "MI", # Use Multiple Imputation ("MI") for handling missing data
  standardized = TRUE, # Compute standardized effects based on Monte Carlo method
  R = 20000L,  # the number of Monte Carlo repetitions
  alpha =  0.05,  # Significance level
  alphastd = 0.05 # Significance level for standardized
)
print(result4)


## ----------------------------------------------------------------------------------------------------------------------------
result5 <- wsMed(
  data = example_dataN,
  M_C1 = c("A1","B1","C1"),# A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"),# A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1",# D1 is outcome variable in condition 1
  Y_C2 = "D2",# D2 is outcome variable in condition 2
  form = "CP",# chained + parallel mediation, M1 is chained mediator by default
  Na = "FIML",# Use Full Information Maximum Likelihood ("FIML")  for handling missing data
  ci_method = "mc", # Use Monte Carlo method for missing data
  standardized = TRUE, # Compute standardized effects based on Monte Carlo method
  R = 10000L,   # the number of Monte Carlo repetitions
  alpha =  0.05,  # Significance level
  alphastd = 0.05 # Significance level for standardized
)
print(result5)

