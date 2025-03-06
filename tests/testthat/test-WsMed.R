library(testthat)
library(lavaan)
library(semhelpinghands)
library(semmcci)

data(example_data)
  set.seed(123)
  example_dataN <- mice::ampute(
    data = example_data,
    prop = 0.1,
  )$amp

  test_that("wsMed input validation works as expected", {
    valid_data <- example_data

    # 1. M_before 或 M_after 为空
    expect_error(wsMed(data = valid_data, M_before = NULL, M_after = c("A2"), Y_before = "C1", Y_after = "C2"), "Error: 'M_before' and 'M_after' cannot be NULL")

    # 2. Y_before 或 Y_after 为空
    expect_error(wsMed(data = valid_data, M_before = c("A1"), M_after = c("A2"), Y_before = NULL, Y_after = "C2"), "Error: 'Y_before' and 'Y_after' cannot be NULL")

    # 3. M_before 和 M_after 长度不一致
    expect_error(wsMed(data = valid_data, M_before = c("A1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2"), "Error: The lengths of 'M_before' and 'M_after' must match")

    # 4. 数据中缺少列
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "Nonexistent", Y_after = "C2"), "Error: Missing columns in data: Nonexistent")

    # 5. form 参数无效
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2", form = "Invalid"), "Error: Invalid 'form' parameter. Use 'P', 'CN', 'CP', or 'PC'")

    # 6. Na 参数无效
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2", Na = "Invalid"), "Error: Invalid 'Na' parameter. Use 'DE', 'FIML', or 'MI'")

    # 验证其他参数
    expect_error(wsMed(data = valid_data, M_before = NULL, M_after = c("A2"), Y_before = "C1", Y_after = "C2"), "Error: 'M_before' and 'M_after' cannot be NULL")
    expect_error(wsMed(data = valid_data, M_before = c("A1"), M_after = c("A2"), Y_before = NULL, Y_after = "C2"), "Error: 'Y_before' and 'Y_after' cannot be NULL")
    expect_error(wsMed(data = valid_data, M_before = c("A1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2"), "Error: The lengths of 'M_before' and 'M_after' must match")
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "Nonexistent", Y_after = "C2"), "Error: Missing columns in data: Nonexistent")
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2", form = "Invalid"), "Error: Invalid 'form' parameter. Use 'P', 'CN', 'CP', or 'PC'")
    expect_error(wsMed(data = valid_data, M_before = c("A1", "B1"), M_after = c("A2", "B2"), Y_before = "C1", Y_after = "C2", Na = "Invalid"), "Error: Invalid 'Na' parameter. Use 'DE', 'FIML', or 'MI'")
  })

  test_that("wsMed handle the missing data", {
    valid_data <- example_data
    valid_data_with_na <- valid_data
    valid_data_with_na$A1[1] <- NA

    # 数据中存在缺失值，但 Na = "DE"
    expect_warning(
      wsMed(data = valid_data_with_na, M_before = c("A1"), M_after = c("A2"), Y_before = "C1", Y_after = "C2", Na = "DE"),
      regexp = "The dataset contains missing values\\. Consider using 'Na = MI' or 'Na = FIML' to handle them"
    )

    # 数据中没有缺失值，但 Na = "MI"
    expect_message(
      wsMed(data = valid_data, M_before = c("A1"), M_after = c("A2"), Y_before = "C1", Y_after = "C2", Na = "MI"),
      regexp = "No missing values detected in the data\\. Switching to 'DE'\\."
    )
  })

  test_that("wsMed validates number of mediators correctly", {
    data(example_data)

    # Case 1: CN requires at least 2 mediators
    expect_error(
      wsMed(
        data = example_data,
        M_before = c("A2"),  # 只有 1 个中介变量
        M_after = c("A1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "CN"
      ),
      "Error: For 'CN' models, the number of mediators must be at least 2."
    )

    # Case 2: PC requires at least 3 mediators
    expect_error(
      wsMed(
        data = example_data,
        M_before = c("A2", "B2"),  # 只有 2 个中介变量
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "PC"
      ),
      "Error: For 'PC' and 'CP' models, the number of mediators must be at least 3."
    )

    # Case 3: CP requires at least 3 mediators
    expect_error(
      wsMed(
        data = example_data,
        M_before = c("A2", "B2"),  # 只有 2 个中介变量
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "CP"
      ),
      "Error: For 'PC' and 'CP' models, the number of mediators must be at least 3."
    )

    # Case 4: Valid mediator counts for CN
    expect_silent(
      wsMed(
        data = example_data,
        M_before = c("A2", "B2"),  # 满足 CN 要求的 2 个中介变量
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "CN"
      )
    )

    # Case 5: Valid mediator counts for PC
    expect_silent(
      wsMed(
        data = example_data,
        M_before = c("A2", "B2", "C2"),  # 满足 PC 要求的 3 个中介变量
        M_after = c("A1", "B1", "C1"),
        Y_before = "D2",
        Y_after = "D1",
        form = "PC"
      )
    )

    # Case 6: Valid mediator counts for CP
    expect_silent(
      wsMed(
        data = example_data,
        M_before = c("A2", "B2", "C2"),  # 满足 CP 要求的 3 个中介变量
        M_after = c("A1", "B1", "C1"),
        Y_before = "D2",
        Y_after = "D1",
        form = "CP"
      )
    )
  })

  test_that("wsMed generates correct results", {
    # 定义不同的测试场景
    scenarios <- list(
      DE = wsMed(
        data = example_data,
        M_before = c("A2", "B2"),
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "P",
        standardized = TRUE
      ),
      MI = wsMed(
        data = example_dataN,
        M_before = c("A2", "B2"),
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "P",
        Na = "MI",
        m = 5,
        standardized = TRUE
      ),
      FIML = wsMed(
        data = example_dataN,
        M_before = c("A2", "B2"),
        M_after = c("A1", "B1"),
        Y_before = "C2",
        Y_after = "C1",
        form = "P",
        Na = "FIML",
        standardized = TRUE
      )
    )

    # 对每种场景进行测试
    for (name in names(scenarios)) {
      result <- scenarios[[name]]

      # 检查基本返回结构
      expected_components <- c("prepared_data", "sem_model", "lavaan_fit",
                               "model_summary", "mi_result", "fiml_result",
                               "std_result", "std_mi_result", "std_fiml_result")
      expect_true(!is.null(result))
      expect_true(all(expected_components %in% names(result)))
      expect_type(result$standardized, "logical")

      # Test sem_model
      expect_type(result$sem_model, "character")
      expect_true(grepl("Ydiff ~", result$sem_model))
      expect_true(grepl("indirect", result$sem_model))

      # Test prepared_data
      expect_s3_class(result$prepared_data, "data.frame")
      expect_true(all(c("Ydiff", "M1diff", "M1avg") %in% colnames(result$prepared_data)))

      # Test lavaan_fit
      fit_measures <- lavaan::fitMeasures(result$lavaan_fit)
      expect_true(all(c("cfi", "rmsea", "srmr") %in% names(fit_measures)))

      # Test standardized results
      if (!is.null(result$standardized) && result$standardized) {
        if (name == "DE") {
          expect_true(!is.null(result$std_result))
          expect_type(result$std_result, "list")
        } else if (name == "MI") {
          expect_true(!is.null(result$std_mi_result))
          expect_s3_class(result$std_mi_result, "semmcci")
        } else if (name == "FIML") {
          expect_true(!is.null(result$std_fiml_result))
          expect_s3_class(result$std_fiml_result, "semmcci")
        }
      } else {
        expect_null(result$std_result)
        expect_null(result$std_mi_result)
        expect_null(result$std_fiml_result)
      }
    }
  })

  test_that("wsMed handles bootstrap correctly", {
    # Check invalid bootstrap parameter
    expect_error(
      wsMed(data = example_data, M_before = c("A2", "B2"), M_after = c("A1", "B1"),
            Y_before = "C2", Y_after = "C1", bootstrap = -1),
      "Error: 'bootstrap' must be a non-negative integer"
    )

    # Run with valid bootstrap parameter
    result <- wsMed(
      data = example_data,
      M_before = c("A2", "B2"),
      M_after = c("A1", "B1"),
      Y_before = "C2",
      Y_after = "C1",
      form = "P",
      bootstrap = 100,
      standardized = FALSE
    )

    # Check if lavaan_fit is an S4 object
    expect_s4_class(result$lavaan_fit, "lavaan")

    # Check if the fit has converged
    fit_info <- slot(result$lavaan_fit, "Fit")
    expect_true(fit_info@converged, info = "Model did not converge during bootstrap")

    # Validate the number of bootstrap replications
    bootstrap_info <- slot(result$lavaan_fit, "boot")
    expect_true(nrow(bootstrap_info$coef) == 100, info = "Bootstrap replications do not match the specified number")

    # Validate fit measures
    fit_measures <- lavaan::fitMeasures(result$lavaan_fit)
    expect_true(all(c("cfi", "rmsea", "srmr") %in% names(fit_measures)),
                info = "Fit measures are missing from the lavaan output")

    # Check parameter estimates with bootstrap confidence intervals
    params <- lavaan::parameterEstimates(result$lavaan_fit, boot.ci.type = "perc")
    expect_type(params, "list")
    expect_true("ci.lower" %in% colnames(params) && "ci.upper" %in% colnames(params),
                info = "Bootstrap confidence intervals are missing from the parameter estimates")

    # Additional validation of bootstrap results
    expect_true(all(!is.na(params$ci.lower)) && all(!is.na(params$ci.upper)),
                info = "Some bootstrap confidence intervals contain NA values")
    expect_true(all(params$ci.lower < params$ci.upper),
                info = "Invalid bootstrap confidence intervals: lower bound exceeds upper bound")

    # Check if bootstrap results match expectations
    non_converged <- attr(bootstrap_info$coef, "nonadmissible")
    expect_true(length(non_converged) == 0 || all(non_converged == 0),
                info = "Some bootstrap replications failed to converge")
  })
