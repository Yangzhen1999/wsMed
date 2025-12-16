#' @title Prepare Data for Two-Condition Within-Subject Mediation (WsMed)
#'
#' @description
#' `PrepareData()` transforms raw pre/post data into the set of variables
#' required by the **WsMed** workflow.
#' It handles *mediators*, *outcome*, *within-subject controls*, *between-subject
#' controls*, *moderators*, and all necessary **interaction terms**, while
#' automatically centring / dummy-coding variables as needed.
#'
#' @details
#' The function performs the following steps:
#'
#' 1. **Outcome difference** (`Ydiff`) – `Y_C2 − Y_C1`.
#' 2. **Mediator variables** for each pair `(M_C1[i], M_C2[i])`
#'    * `Mi_diff` = `M_C2 − M_C1`
#'    * `Mi_avg`  = mean-centred average of the two occasions.
#' 3. **Between-subject controls C**
#'    * Continuous → grand-mean centred (`Cb1`, `Cb2`, …).
#'    * Categorical (binary or multi-level) → *k – 1* dummy variables
#'      (`Cb1_1`, `Cb2_1`, `Cb2_2`, …), with the first level as reference.
#' 4. **Within-subject controls Cw** – difference & centred-average versions
#'    (`Cw1diff`, `Cw1avg`, …).
#' 5. **Moderators W** (supports ≥ 1):
#'    * Continuous → grand-mean centred (`W1`, `W2`, …).
#'    * Categorical → dummy-coded like C.
#' 6. **Interaction terms** between every moderator dummy/centred column and
#'    each `Mi_diff` / `Mi_avg`:
#'    `int_<Mi_diff>_<Wj>`, `int_<Mi_avg>_<Wj>`.
#' 7. Adds two attributes:
#'    * `"W_info"` – raw names, dummy names, level mapping
#'    * `"C_info"` – same for between-subject C.
#'
#' Row counts are preserved even if input factors contain *NA*
#' (`model.matrix()` is called with `na.action = na.pass`).
#'
#' @param data A data frame with the raw pre/post measures.
#' @param M_C1,M_C2 Character vectors: mediator names at occasion 1 / 2
#'   (equal length).
#' @param Y_C1,Y_C2 Character scalars: outcome names at occasion 1 / 2.
#' @param C_C1,C_C2 Optional character vectors: within-subject control names.
#' @param C Optional character vector: between-subject control names.
#' @param C_type Optional vector of the same length as \code{C}.
#'   Each element \code{"continuous"}, \code{"categorical"}, or \code{"auto"}
#'   (default). Ignored when \code{C = NULL}.
#' @param W Optional character vector: moderator names (≤ *J*).
#' @param W_type Optional vector of the same length as \code{W}.
#'   Same coding as \code{C_type}. Ignored when \code{W = NULL}.
#' @param center_W Logical. Whether to center the moderator variable W.
#' @param keep_W_raw,keep_C_raw Logical; keep original W / C columns in the
#'   returned data?
#'
#'
#' @return
#' A data frame containing at minimum:
#' \itemize{
#'   \item \bold{Ydiff}
#'   \item \bold{Mi_diff}, \bold{Mi_avg} for each mediator \(i\)
#'   \item centred / dummy-coded \bold{Cb*}, \bold{Cw*diff}, \bold{Cw*avg}
#'   \item centred / dummy-coded \bold{W*} and all \bold{int_*} interaction terms
#' }
#' plus the attributes \code{"W_info"} and \code{"C_info"} described above.
#'
#' @seealso
#' \code{\link{PrepareMissingData}}, \code{\link{GenerateModelP}},
#' \code{\link{wsMed}}
#'
#' @examples
#' set.seed(1)
#' raw <- data.frame(
#'   A1 = rnorm(50), A2 = rnorm(50),   # mediator 1
#'   B1 = rnorm(50), B2 = rnorm(50),   # mediator 2
#'   C1 = rnorm(50), C2 = rnorm(50),   # outcome
#'   D1 = rnorm(50), D2 = rnorm(50),   # within-subject control
#'   W_bin  = sample(0:1, 50, TRUE),   # between-subject binary C
#'   W_fac3 = factor(sample(c("Low","Med","High"), 50, TRUE)) # moderator W
#' )
#'
#' prep <- PrepareData(
#'   data  = raw,
#'   M_C1  = c("A1","B1"), M_C2 = c("A2","B2"),
#'   Y_C1  = "C1",         Y_C2 = "C2",
#'   C_C1  = "D1",         C_C2 = "D2",
#'   C     = "W_bin",      C_type = "categorical",
#'   W     = "W_fac3",     W_type = "categorical"
#' )
#' head(prep)
#'
#' @export

PrepareData <- function(data,
                        M_C1, M_C2,
                        Y_C1, Y_C2,
                        C_C1 = NULL, C_C2 = NULL,
                        C = NULL,       C_type = NULL,
                        W = NULL,       W_type = NULL,
                        keep_W_raw = TRUE,
                        keep_C_raw = TRUE) {


  core_cols <- c(Y_C1, Y_C2, M_C1, M_C2, C_C1, C_C2, C, W)
  idx_complete <- stats::complete.cases(data[ , unique(core_cols), drop = FALSE])
  if (any(!idx_complete)) {
    data <- data[idx_complete, , drop = FALSE]
  }
  ## ---------- 基本检查 ----------
  stopifnot(length(M_C1) == length(M_C2))
  stopifnot(all(c(Y_C1, Y_C2) %in% names(data)))

  ## ---------- Outcome diff ----------
  data$Ydiff <- data[[Y_C2]] - data[[Y_C1]]

  ## ---------- 中介 diff / avg ----------
  diffs <- avgs <- list()
  for (i in seq_along(M_C1)) {
    diffs[[paste0("M", i, "diff")]] <- data[[M_C2[i]]] - data[[M_C1[i]]]
    m1c <- data[[M_C1[i]]] - mean(data[[M_C1[i]]], na.rm = TRUE)
    m2c <- data[[M_C2[i]]] - mean(data[[M_C2[i]]], na.rm = TRUE)
    avgs[[paste0("M", i, "avg")]]  <- (m1c + m2c) / 2
  }

  ## ---------- 辅助 ----------
  detect_type <- function(x) {
    if (is.factor(x) || is.character(x)) return("categorical")
    if (is.numeric(x) && setequal(unique(x[!is.na(x)]), c(0,1))) return("categorical")
    if (is.numeric(x)) return("continuous")
    stop("Unrecognized variable type.")
  }


  ## 取 k‑1 dummy 时直接用 levels 提取标签
  build_dummy_map <- function(base, lv_vec) {
    paste(base, "vs", lv_vec)
  }


  ## ---------- Between‑subject C ----------
  between_centered <- list(); c_dummy_map <- list()
  if (!is.null(C)) {
    if (is.null(C_type)) C_type <- rep("auto", length(C))
    stopifnot(length(C_type) == length(C))

    cb_counter <- 1L
    for (i in seq_along(C)) {
      var   <- C[i]
      raw   <- data[[var]]
      ctype <- if (C_type[i] == "auto") detect_type(raw) else tolower(C_type[i])

      if (ctype == "continuous") {
        nm <- paste0("Cb", cb_counter)
        between_centered[[nm]] <- raw - mean(raw, na.rm = TRUE)
        c_dummy_map[[nm]]      <- "continuous"
        cb_counter <- cb_counter + 1L

      } else {
        fac  <- factor(raw)
        base <- levels(fac)[1]
        k    <- nlevels(fac)
        if (k == 2) {
          nm   <- paste0("Cb", cb_counter, "_1")
          dummy<- if (is.numeric(raw) && setequal(unique(raw), c(0,1))) raw
          else as.numeric(fac == levels(fac)[2])
          between_centered[[nm]] <- dummy
          c_dummy_map[[nm]]      <- build_dummy_map(base, levels(fac)[2])
          cb_counter <- cb_counter + 1L
        } else {
          mm <- model.matrix(~ fac, na.action = stats::na.pass)[ , -1, drop = FALSE]  # 保留 NA 行
          for (j in seq_len(ncol(mm))) {
            nm <- paste0("Cb", cb_counter, "_", j)
            between_centered[[nm]] <- mm[, j]
            lv_tag <- levels(fac)[j + 1]                  # 取真实水平
            c_dummy_map[[nm]] <- build_dummy_map(base, lv_tag)
          }
          cb_counter <- cb_counter + 1L
        }
      }
    }
  }

  ## ---------- Within‑subject C ----------
  within_diffs <- within_avgs <- list()
  if (!is.null(C_C1) && !is.null(C_C2))
    for (i in seq_along(C_C1)) {
      wd <- data[[C_C2[i]]] - data[[C_C1[i]]]
      wa <- (data[[C_C1[i]]] + data[[C_C2[i]]]) / 2
      within_diffs[[paste0("Cw", i, "diff")]] <- wd - mean(wd, na.rm = TRUE)
      within_avgs [[paste0("Cw", i, "avg") ]] <- wa - mean(wa, na.rm = TRUE)
    }

  ## ---------- Moderator W ----------
  W_centered <- interaction_terms <- list()
  w_dummy_map <- list()
  if (!is.null(W)) {
    if (is.null(W_type)) W_type <- rep("auto", length(W))
    stopifnot(length(W_type) == length(W))

    w_counter <- 1L
    for (i in seq_along(W)) {
      var  <- W[i]
      raw  <- data[[var]]
      wtype<- if (W_type[i] == "auto") detect_type(raw) else tolower(W_type[i])

      if (wtype == "continuous") {
        nm <- paste0("W", w_counter)
        W_centered[[nm]] <- raw - mean(raw, na.rm = TRUE)
        w_dummy_map[[nm]] <- "continuous"
        w_counter <- w_counter + 1L

      } else {
        fac  <- factor(raw)
        base <- levels(fac)[1]
        k    <- nlevels(fac)
        if (k == 2) {
          nm    <- paste0("W", w_counter)
          dummy <- if (is.numeric(raw) && setequal(unique(raw), c(0,1))) raw
          else as.numeric(fac == levels(fac)[2])
          W_centered[[nm]] <- dummy
          w_dummy_map[[nm]] <- build_dummy_map(base, levels(fac)[2])
          w_counter <- w_counter + 1L
        } else {
          mm <- model.matrix(~ fac, na.action = stats::na.pass)[ , -1, drop = FALSE]
          for (j in seq_len(ncol(mm))) {
            nm <- paste0("W", w_counter)
            W_centered[[nm]] <- mm[, j]
            lv_tag <- levels(fac)[j + 1]
            w_dummy_map[[nm]] <- build_dummy_map(base, lv_tag)
            w_counter <- w_counter + 1L
          }
        }
      }
    }

    ## ----- 交互项 -----
    for (m in names(diffs))
      for (w in names(W_centered))
        interaction_terms[[paste0("int_", m, "_", w)]] <- diffs[[m]] * W_centered[[w]]

    for (m in names(avgs))
      for (w in names(W_centered))
        interaction_terms[[paste0("int_", m, "_", w)]] <- avgs[[m]] * W_centered[[w]]
  }

  ## ---------- 汇总 ----------
  all_vars <- c(diffs, avgs,
                between_centered, within_diffs, within_avgs,
                W_centered, interaction_terms)
  data_out <- cbind(data, as.data.frame(all_vars))

  sel <- c("Ydiff", names(diffs), names(avgs),
           names(between_centered), names(within_diffs), names(within_avgs),
           names(W_centered), names(interaction_terms))
  if (keep_W_raw && !is.null(W)) sel <- c(W, sel)
  if (keep_C_raw && !is.null(C)) sel <- c(C, sel)

  data_out <- data_out[ , unique(sel), drop = FALSE]

  ## ---------- 元信息 ----------
  attr(data_out, "W_info") <- list(
    raw         = W,
    dummy_names = names(W_centered),
    dummy_map   = w_dummy_map
  )
  attr(data_out, "C_info") <- list(
    raw         = C,
    dummy_names = names(between_centered),
    dummy_map   = c_dummy_map
  )

  data_out
}



PrepareData <- function(data,
                        M_C1, M_C2,
                        Y_C1, Y_C2,
                        C_C1 = NULL, C_C2 = NULL,
                        C = NULL,       C_type = NULL,
                        W = NULL,       W_type = NULL,
                        center_W = TRUE,          # <‑‑ NEW ARGUMENT
                        keep_W_raw = TRUE,
                        keep_C_raw = TRUE) {

  ## ---------- basic checks ----------
  stopifnot(is.data.frame(data))
  stopifnot(length(M_C1) == length(M_C2))
  stopifnot(all(c(Y_C1, Y_C2) %in% names(data)))
  if (!is.logical(center_W) || length(center_W) != 1)
    stop("`center_W` must be TRUE or FALSE.", call. = FALSE)


  ### 在 PrepareData() 函数顶端基本检查之后立即加入 -----------------
  # >>>> enforce single‑moderator rule
  if (!is.null(W) && length(W) != 1)
    stop("Exactly one moderator variable can be supplied in `W`.", call. = FALSE)


  ## ---------- Outcome diff ----------
  data$Ydiff <- data[[Y_C2]] - data[[Y_C1]]

  ## ---------- Mediator diff / avg ----------
  diffs <- avgs <- list()
  for (i in seq_along(M_C1)) {
    diffs[[paste0("M", i, "diff")]] <- data[[M_C2[i]]] - data[[M_C1[i]]]
    m1c <- data[[M_C1[i]]] - mean(data[[M_C1[i]]], na.rm = TRUE)
    m2c <- data[[M_C2[i]]] - mean(data[[M_C2[i]]], na.rm = TRUE)
    avgs[[paste0("M", i, "avg")]] <- (m1c + m2c) / 2
  }

  ## ---------- helpers ----------
  detect_type <- function(x) {
    if (is.factor(x) || is.character(x)) return("categorical")
    if (is.numeric(x) && setequal(unique(x[!is.na(x)]), c(0, 1)))
      return("categorical")
    if (is.numeric(x)) return("continuous")
    stop("Unsupported variable type.")
  }
  build_dummy_map <- function(base, lv_vec) paste(base, "vs", lv_vec)

  ## ---------- Between‑subject C ----------
  between_centered <- c_dummy_map <- list()
  if (!is.null(C)) {
    if (is.null(C_type)) C_type <- rep("auto", length(C))
    stopifnot(length(C_type) == length(C))

    cb_counter <- 1L
    for (i in seq_along(C)) {
      var   <- C[i]
      raw   <- data[[var]]
      ctype <- if (C_type[i] == "auto") detect_type(raw) else tolower(C_type[i])

      if (ctype == "continuous") {
        nm <- paste0("Cb", cb_counter)
        between_centered[[nm]] <- raw - mean(raw, na.rm = TRUE)
        c_dummy_map[[nm]]      <- "continuous"
        cb_counter <- cb_counter + 1L

      } else {                           # ----- categorical C -----------
        fac  <- factor(raw)
        base <- levels(fac)[1]
        k    <- nlevels(fac)
        if (k == 2) {
          nm   <- paste0("Cb", cb_counter, "_1")
          dummy<- if (is.numeric(raw) && setequal(unique(raw), c(0, 1))) raw
          else as.numeric(fac == levels(fac)[2])
          between_centered[[nm]] <- dummy
          c_dummy_map[[nm]]      <- build_dummy_map(base, levels(fac)[2])
          cb_counter <- cb_counter + 1L
        } else {
          mm <- model.matrix(~ fac, na.action = stats::na.pass)[, -1, drop = FALSE]
          for (j in seq_len(ncol(mm))) {
            nm <- paste0("Cb", cb_counter, "_", j)
            between_centered[[nm]] <- mm[, j]
            lv_tag <- levels(fac)[j + 1]
            c_dummy_map[[nm]] <- build_dummy_map(base, lv_tag)
          }
          cb_counter <- cb_counter + 1L
        }
      }
    }
  }

  ## ---------- Within‑subject C ----------
  within_diffs <- within_avgs <- list()
  if (!is.null(C_C1) && !is.null(C_C2))
    for (i in seq_along(C_C1)) {
      wd <- data[[C_C2[i]]] - data[[C_C1[i]]]
      wa <- (data[[C_C1[i]]] + data[[C_C2[i]]]) / 2
      within_diffs[[paste0("Cw", i, "diff")]] <- wd - mean(wd, na.rm = TRUE)
      within_avgs [[paste0("Cw", i, "avg") ]] <- wa - mean(wa, na.rm = TRUE)
    }

  ## ---------- Moderator W ----------
  W_centered <- interaction_terms <- w_dummy_map <- list()
  if (!is.null(W)) {
    if (is.null(W_type)) W_type <- rep("auto", length(W))
    stopifnot(length(W_type) == length(W))

    w_counter <- 1L
    for (i in seq_along(W)) {
      var  <- W[i]
      raw  <- data[[var]]
      wtype<- if (W_type[i] == "auto") detect_type(raw) else tolower(W_type[i])

      if (wtype == "continuous") {                # ----- numeric W -----
        nm <- paste0("W", w_counter)
        W_centered[[nm]] <-
          if (center_W) raw - mean(raw, na.rm = TRUE) else raw
        w_dummy_map[[nm]] <- "continuous"
        w_counter <- w_counter + 1L

      } else {                                    # ----- categorical W -----
        fac  <- factor(raw)
        base <- levels(fac)[1]
        k    <- nlevels(fac)
        if (k == 2) {
          nm    <- paste0("W", w_counter)
          dummy <- if (is.numeric(raw) && setequal(unique(raw), c(0, 1))) raw
          else as.numeric(fac == levels(fac)[2])
          W_centered[[nm]] <- dummy
          w_dummy_map[[nm]] <- build_dummy_map(base, levels(fac)[2])
          w_counter <- w_counter + 1L
        } else {
          mm <- model.matrix(~ fac, na.action = stats::na.pass)[, -1, drop = FALSE]
          for (j in seq_len(ncol(mm))) {
            nm <- paste0("W", w_counter)
            W_centered[[nm]] <- mm[, j]
            lv_tag <- levels(fac)[j + 1]
            w_dummy_map[[nm]] <- build_dummy_map(base, lv_tag)
            w_counter <- w_counter + 1L
          }
        }
      }
    }

    ## ----- interaction terms (unchanged logic) -----
    for (m in names(diffs))
      for (w in names(W_centered))
        interaction_terms[[paste0("int_", m, "_", w)]] <- diffs[[m]] * W_centered[[w]]

    for (m in names(avgs))
      for (w in names(W_centered))
        interaction_terms[[paste0("int_", m, "_", w)]] <- avgs[[m]] * W_centered[[w]]
  }

  ## ---------- combine ----------
  all_vars <- c(diffs, avgs,
                between_centered, within_diffs, within_avgs,
                W_centered, interaction_terms)
  data_out <- cbind(data, as.data.frame(all_vars))

  sel <- c("Ydiff", names(diffs), names(avgs),
           names(between_centered), names(within_diffs), names(within_avgs),
           names(W_centered), names(interaction_terms))
  if (keep_W_raw && !is.null(W)) sel <- c(W, sel)
  if (keep_C_raw && !is.null(C)) sel <- c(C, sel)

  data_out <- data_out[, unique(sel), drop = FALSE]

  ## ---------- attributes ----------
  attr(data_out, "W_info") <- list(
    raw         = W,
    dummy_names = names(W_centered),
    dummy_map   = w_dummy_map
  )
  attr(data_out, "C_info") <- list(
    raw         = C,
    dummy_names = names(between_centered),
    dummy_map   = c_dummy_map
  )
  data_out
}






