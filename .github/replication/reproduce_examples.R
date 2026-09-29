# Reproduce manuscript Examples 1-3 with wsMed 1.1.0.9000.
# Set the working directory to this folder, then source("reproduce_examples.R").
# Results are saved to example_results.txt; plots are displayed in R.

# Environment checks and recording are handled by run.R for each CI profile.
library(wsMed)
stopifnot(as.character(packageVersion("wsMed")) == "1.1.0.9000")
options(width = 120, knitr.table.format = "pipe")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

dat <- haven::read_sav("wsMed_examples.sav")

# Five PMM imputations, 20,000 Monte Carlo draws, and 95% confidence intervals.
# These package defaults are stated explicitly in each call below.
output_file <- "example_results.txt"
writeLines("wsMed 1.1.0.9000: manuscript Examples 1-3\n", output_file)
write_results <- function(code) {
  out <- capture.output(force(code))
  cat(out, sep = "\n")
  cat(out, "", file = output_file, sep = "\n", append = TRUE)
  invisible(out)
}

# Example 1: Parallel mediation
result1 <- wsMed(
  data = dat,
  M_C1 = c("TSRQ_T1", "WEMBS_T1", "SMUF_T1"),
  M_C2 = c("TSRQ_T2", "WEMBS_T2", "SMUF_T2"),
  Y_C1 = "DASSS_T1",
  Y_C2 = "DASSS_T2",
  form = "P",
  C_C1 = "HES_T1",
  C_C2 = "HES_T2",
  C = c("Age", "BMI"),
  Na = "MI",
  ci_method = "mc",
  seed = 123,
  mi_args = list(m = 5L, method_num = "pmm", decomposition = "eigen"),
  R = 20000L, alpha = 0.05, fixed.x = FALSE
)

write_results({
  cat("EXAMPLE 1: PARALLEL MEDIATION\n")
  print(result1, detail = "legacy")
})

# Example 2: Parallel-serial mediation
result2_predefined <- wsMed(
  data = dat,
  M_C1 = c("TSRQ_T1", "WEMBS_T1", "ISI_T1"),
  M_C2 = c("TSRQ_T2", "WEMBS_T2", "ISI_T2"),
  Y_C1 = "DASSS_T1",
  Y_C2 = "DASSS_T2",
  form = "PC",
  C_C1 = "HES_T1",
  C_C2 = "HES_T2",
  C = c("Age", "BMI"),
  Na = "MI",
  ci_method = "mc",
  standardized = TRUE,
  seed = 604,
  mi_args = list(m = 5L, method_num = "pmm", decomposition = "eigen"),
  R = 20000L, alpha = 0.05, fixed.x = FALSE
)

write_results({
  cat("EXAMPLE 2: PARALLEL-SERIAL MEDIATION (PC)\n")
  print(result2_predefined, detail = "legacy")
  printGM(result2_predefined)
})

custom_paths <- c(
  "M2 -> M1",
  "M3 -> M1",
  "M1 -> Y",
  "M2 -> Y",
  "M3 -> Y"
)

result2_custom <- wsMed(
  data = dat,
  M_C1 = c("TSRQ_T1", "WEMBS_T1", "ISI_T1"),
  M_C2 = c("TSRQ_T2", "WEMBS_T2", "ISI_T2"),
  Y_C1 = "DASSS_T1",
  Y_C2 = "DASSS_T2",
  form = "UD",
  paths = custom_paths,
  C_C1 = "HES_T1",
  C_C2 = "HES_T2",
  C = c("Age", "BMI"),
  Na = "MI",
  ci_method = "mc",
  standardized = TRUE,
  seed = 604,
  mi_args = list(m = 5L, method_num = "pmm", decomposition = "eigen"),
  R = 20000L, alpha = 0.05, fixed.x = FALSE
)

write_results({
  cat("EXAMPLE 2: PARALLEL-SERIAL MEDIATION (UD)\n")
  print(result2_custom, detail = "legacy")
  printGM(result2_custom)
})

# Example 3: Moderated mediation
result3 <- wsMed(
  data = dat,
  M_C1 = c("TSRQ_T1", "WEMBS_T1", "SMUF_T1"),
  M_C2 = c("TSRQ_T2", "WEMBS_T2", "SMUF_T2"),
  Y_C1 = "DASSS_T1",
  Y_C2 = "DASSS_T2",
  form = "P",
  C_C1 = "HES_T1",
  C_C2 = "HES_T2",
  C = "BMI",
  Na = "MI",
  ci_method = "mc",
  standardized = TRUE,
  W = "Age",
  W_type = "continuous",
  MP = c("a1", "b1", "cp"),
  seed = 604,
  mi_args = list(m = 5L, method_num = "pmm", decomposition = "eigen"),
  R = 20000L, alpha = 0.05, fixed.x = FALSE
)

write_results({
  cat("EXAMPLE 3: MODERATED MEDIATION\n")
  print(result3, detail = "legacy")
})

# Example 3 figures
age_range <- range(dat$Age, na.rm = TRUE)
result3_plot <- result3
for (nm in c("theta_curve", "path_curve")) {
  curve <- result3$moderation[[nm]]
  result3_plot$moderation[[nm]] <- subset(
    curve, W_raw >= age_range[1] & W_raw <= age_range[2])
}
# print() displays each plot when the script is run with source().
print(plot_moderation_curve(result3_plot, "indirect_effect_1",
  x_label = "Age (years)"))
print(plot_moderation_curve(result3_plot, "a1", x_label = "Age (years)"))
print(plot_contrasts(result3, paths = "indirect_effect_1"))

# Record the software environment in the same output file.
write_results({
  cat("REPRODUCTION ENVIRONMENT\n")
  sessionInfo()
})
cat("Completed. Results: example_results.txt; plots sent to the R graphics device.\n")

write_results({ print(extSoftVersion()); print(RNGkind()) })
