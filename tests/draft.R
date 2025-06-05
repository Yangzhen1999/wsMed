result1 <- wsMed(
  data = example_data, #dataset
  M_C1 = c("A1","B1"), # A1/B1 is A/B mediator variable in condition 1
  M_C2 = c("A2","B2"), # A2/B2 is A/B mediator variable in condition 2
  Y_C1 = "C1", # C1 is outcome variable in condition 1
  Y_C2 = "C2", # C2 is outcome variable in condition 2
  W = "A3",
  MP   = c("cp","d1","a1","a2"),
  form = "P", # Parallel mediation
  ci_method = "mc" # use Monte Carlo confidence intervals
)
print(result1)

result2 <- wsMed(
  data = dat,
  M_C1 = c("M1_T1", "M2_T1"),
  M_C2 = c("M1_T2", "M2_T2"),
  Y_C1 = "Y_T1",
  Y_C2 = "Y_T2",
  W    = "W1",
  MP   = c("cp","d1","a1","a2","b_1_2","b2","d_1_2"),
  form = "CN",
  ci_method = "mc",
)
