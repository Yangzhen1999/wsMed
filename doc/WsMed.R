## ----echo=FALSE, out.width="100%"---------------------------------------------
knitr::include_graphics("WsMed.svg")

## -----------------------------------------------------------------------------
library(wsMed)
library(knitr)
data(example_data)
set.seed(123) 
example_dataN <- mice::ampute(
  data = example_data,       
  prop = 0.1,      
)$amp

## -----------------------------------------------------------------------------
result1 <- WsMed(
  data = example_dataN,
  M_before = c("A1","B1"),
  M_after = c("A2","B2"),
  Y_before = "C1",
  Y_after = "C2",
  form = "P",
  Na = "MI",
  standardized = TRUE
)
print(result1)

## -----------------------------------------------------------------------------
result2 <- WsMed(
  data = example_dataN,
  M_before = c("A2", "B2", "C2"),
  M_after = c("A1", "B1", "C1"),
  Y_before = "D2",
  Y_after = "D1",
  form = "CN",
  standardized = TRUE,
  bootstrap = 1000,
  iseed = 123,
  se = "boot"
)
print(result2)

## -----------------------------------------------------------------------------
result3 <- WsMed(
  data = example_dataN,
  M_before = c("A1","B1"),
  M_after = c("A2","B2"),
  Y_before = "C1",
  Y_after = "C2",
  form = "CP",
  Na = "FIML",
  standardized = TRUE
)
print(result3)

