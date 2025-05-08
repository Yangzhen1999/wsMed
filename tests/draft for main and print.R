devtools::load_all()
library(semboottools)
library(wsMed)
result1 <- wsMed2(
  data = example_data, #dataset
  M_C1 = c("A1","B1","C1"), # A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"), # A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1", # D1 is outcome variable in condition 1
  Y_C2 = "D2", # D2 is outcome variable in condition 2
  form = "P", # Parallel mediation
  standardized = TRUE, # Compute standardized effects
  bootstrap = 2000, # Bootstrap for confidence intervals
  boot_ci_type = "bc",
  iseed = 123 # Random seed for bootstrap
)
print(result5,delta = TRUE)
result4 <- wsMed5(
  data = example_data, #dataset
  M_C1 = c("A1","B1","C1"), # A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"), # A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1", # D1 is outcome variable in condition 1
  Y_C2 = "D2", # D2 is outcome variable in condition 2
  form = "P", # Parallel mediation
)
#' # Example dataset with missing values
data(example_data)
 set.seed(123)
 example_dataN <- mice::ampute(
   data = example_data,
   prop = 0.1
 )$amp

print(result5)
result5 <- wsMed(
  data = example_dataN,
  M_C1 = c("A1","B1","C1"),# A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2","C2"),# A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "D1", # D1 is outcome variable in condition 1
  Y_C2 = "D2", # D2 is outcome variable in condition 2
  form = "P", # chained mediation
  Na = "FIML", # Use Multiple Imputation ("MI") for handling missing data
  standardized = TRUE,
  R = 20000L,  # the number of Monte Carlo repetitions
  alpha =  0.05,  # Significance level
  alphastd = 0.05 # Significance level for standardized
)

result8 <- wsMed5(
  data = dataE,
  M_C1 = c("A1","B1"),# A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2"),# A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "C1", # D1 is outcome variable in condition 1
  Y_C2 = "C2", # D2 is outcome variable in condition 2
  form = "P", # chained mediation
  Na = "MI", # Use Multiple Imputation ("MI") for handling missing data
  standardized = TRUE,
  R = 20000L,  # the number of Monte Carlo repetitions
  alpha =  0.05,  # Significance level
  alphastd = 0.05 # Significance level for standardized
)
print(result8,digits = 5)


result7 <- wsMed(
  data = dataE,
  M_C1 = c("A1","B1"),# A1/B1/C1 is A/B/C mediator variable in condition 1
  M_C2 = c("A2","B2"),# A2/B2/C2 is A/B/C mediator variable in condition 2
  Y_C1 = "C1", # D1 is outcome variable in condition 1
  Y_C2 = "C2", # D2 is outcome variable in condition 2
  form = "P", # chained mediation
  Na = "FIML", # Use Multiple Imputation ("MI") for handling missing data
  standardized = TRUE,
  R = 20000L,  # the number of Monte Carlo repetitions
  alpha =  0.05,  # Significance level
  alphastd = 0.05 # Significance level for standardized
)
print(result7)

result6$std_result
result6$std_fiml_result

head( example_dataN)

# Set seed for reproducibility
set.seed(123)

# Define the number of rows for the dataset
num_rows <- 100  # Adjust this number as needed

# Generate the dataset with random values between 1 and 10
dataE <- data.frame(
  A1 = sample(10:15, num_rows, replace = TRUE),
  A2 = sample(20:25, num_rows, replace = TRUE),  # A2 is always larger than A1

  # B1 and B2 with a large difference
  B1 = sample(15:20, num_rows, replace = TRUE),
  B2 = sample(25:30, num_rows, replace = TRUE),  # B2 is always larger than B1

  # C1 and C2 with a large difference
  C1 = sample(20:25, num_rows, replace = TRUE),
  C2 = sample(30:35, num_rows, replace = TRUE),  # C2 is always larger than C1

  # Outcome variables
  D1 = sample(30:40, num_rows, replace = TRUE),
  D2 = sample(35:45, num_rows, replace = TRUE)
)

# View the first few rows of the generated data
head(dataE)
data(dataE)
set.seed(123)
dataE <- mice::ampute(
  data = dataE,
  prop = 0.1,
)$amp
summary(dataE)
