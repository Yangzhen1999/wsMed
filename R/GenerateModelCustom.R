#' Generate a User-Defined Within-Subject Mediation Model
#'
#' @description
#' Generates lavaan model syntax for a user-defined within-subject
#' mediation model. Users specify directed paths among mediators and
#' from mediators to the outcome. The function automatically adds the
#' corresponding difference and level components and identifies all
#' indirect effects.
#'
#' @param prepared_data A data frame returned by [PrepareData()].
#'   It must contain `M1diff`, `M1avg`, ..., and `Ydiff`.
#'
#' @param paths A character vector defining directed paths among mediators
#'   and from mediators to the outcome. For example:
#'   `c("M1 -> M2", "M2 -> Y")`.
#'
#' @param MP A character vector identifying moderated paths. Supported
#'   labels follow the existing wsMed convention:
#'   `a1`, `b1`, `d1`, `b_1_2`, `d_1_2`, and `cp`.
#'
#' @return A character string containing lavaan model syntax.
#'
#' @examples
#' prepared_data <- data.frame(
#'   M1diff = rnorm(100),
#'   M1avg  = rnorm(100),
#'   M2diff = rnorm(100),
#'   M2avg  = rnorm(100),
#'   M3diff = rnorm(100),
#'   M3avg  = rnorm(100),
#'   Ydiff  = rnorm(100)
#' )
#'
#' model <- GenerateModelCustom(
#'  prepared_data = prepared_data,
#'  paths = c(
#'    "M1 -> M3",
#'    "M1 -> Y",
#'    "M3 -> Y",
#'    "M2 -> Y"
#'  )
#')
#'
#' cat(model)
#'
#' @export

GenerateModelCustom <- function(prepared_data,
                                paths,
                                MP = character(0)) {

  ## ------------------------------------------------------------------
  ## 1. Basic input validation
  ## ------------------------------------------------------------------

  if (!is.data.frame(prepared_data)) {
    stop(
      "`prepared_data` must be a data frame returned by PrepareData().",
      call. = FALSE
    )
  }

  if (!"Ydiff" %in% names(prepared_data)) {
    stop(
      "`prepared_data` must contain `Ydiff`.",
      call. = FALSE
    )
  }

  if (!is.character(paths) ||
      length(paths) == 0L ||
      anyNA(paths) ||
      any(!nzchar(trimws(paths)))) {
    stop(
      "`paths` must be a non-empty character vector.",
      call. = FALSE
    )
  }

  if (is.null(MP)) {
    MP <- character(0)
  }

  if (!is.character(MP)) {
    stop("`MP` must be a character vector.", call. = FALSE)
  }

  ## ------------------------------------------------------------------
  ## 2. Identify mediators
  ## ------------------------------------------------------------------

  mdiff_vars <- grep(
    "^M[1-9][0-9]*diff$",
    names(prepared_data),
    value = TRUE
  )

  if (length(mdiff_vars) == 0L) {
    stop(
      "`prepared_data` must contain at least one mediator difference score.",
      call. = FALSE
    )
  }

  mediator_ids <- as.integer(
    sub("^M([1-9][0-9]*)diff$", "\\1", mdiff_vars)
  )

  mediator_ids <- sort(mediator_ids)
  mediator_nodes <- paste0("M", mediator_ids)

  mdiff_vars <- paste0(mediator_nodes, "diff")
  mavg_vars  <- paste0(mediator_nodes, "avg")

  missing_mavg <- setdiff(mavg_vars, names(prepared_data))

  if (length(missing_mavg) > 0L) {
    stop(
      paste0(
        "The following mediator level components are missing: ",
        paste(missing_mavg, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 3. Parse paths
  ## ------------------------------------------------------------------

  normalized_paths <- gsub("\\s+", "", paths)

  valid_pattern <- "^M[1-9][0-9]*->(M[1-9][0-9]*|Y)$"

  invalid_paths <- paths[!grepl(valid_pattern, normalized_paths)]

  if (length(invalid_paths) > 0L) {
    stop(
      paste0(
        "Invalid path specification: ",
        paste(invalid_paths, collapse = ", "),
        ". Paths must use forms such as `M1 -> M2` or `M2 -> Y`."
      ),
      call. = FALSE
    )
  }

  split_paths <- strsplit(normalized_paths, "->", fixed = TRUE)

  edge_from <- vapply(split_paths, `[`, character(1), 1L)
  edge_to   <- vapply(split_paths, `[`, character(1), 2L)

  edges <- data.frame(
    from = edge_from,
    to   = edge_to,
    stringsAsFactors = FALSE
  )

  duplicated_edges <- duplicated(edges)

  if (any(duplicated_edges)) {
    duplicates <- paste0(
      edges$from[duplicated_edges],
      " -> ",
      edges$to[duplicated_edges]
    )

    stop(
      paste0(
        "Duplicated path specification: ",
        paste(unique(duplicates), collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  referenced_mediators <- unique(c(
    edges$from,
    edges$to[edges$to != "Y"]
  ))

  unknown_mediators <- setdiff(
    referenced_mediators,
    mediator_nodes
  )

  if (length(unknown_mediators) > 0L) {
    stop(
      paste0(
        "The following mediators are not available in `prepared_data`: ",
        paste(unknown_mediators, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  self_loops <- edges$from == edges$to

  if (any(self_loops)) {
    loops <- paste0(
      edges$from[self_loops],
      " -> ",
      edges$to[self_loops]
    )

    stop(
      paste0(
        "Self-loops are not allowed: ",
        paste(loops, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (!any(edges$to == "Y")) {
    stop(
      "At least one mediator must have a path to `Y`.",
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 4. Construct adjacency list and check for cycles
  ## ------------------------------------------------------------------

  all_nodes <- c(mediator_nodes, "Y")

  adjacency <- setNames(
    replicate(length(all_nodes), character(0), simplify = FALSE),
    all_nodes
  )

  for (i in seq_len(nrow(edges))) {
    adjacency[[edges$from[i]]] <- c(
      adjacency[[edges$from[i]]],
      edges$to[i]
    )
  }

  in_degree <- setNames(integer(length(all_nodes)), all_nodes)

  for (target in edges$to) {
    in_degree[target] <- in_degree[target] + 1L
  }

  queue <- names(in_degree)[in_degree == 0L]
  visited <- character(0)

  while (length(queue) > 0L) {
    current <- queue[1L]
    queue <- queue[-1L]

    visited <- c(visited, current)

    for (next_node in adjacency[[current]]) {
      in_degree[next_node] <- in_degree[next_node] - 1L

      if (in_degree[next_node] == 0L) {
        queue <- c(queue, next_node)
      }
    }
  }

  if (length(visited) != length(all_nodes)) {
    stop(
      paste0(
        "The custom mediation model must be acyclic. ",
        "A cycle was detected among the specified paths."
      ),
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 5. Identify covariates, moderators, and interaction variables
  ## ------------------------------------------------------------------

  between_covs <- grep(
    "^Cb[1-9][0-9]*(_[1-9][0-9]*)?$",
    names(prepared_data),
    value = TRUE
  )

  within_covs <- grep(
    "^Cw[1-9][0-9]*(diff|avg)$",
    names(prepared_data),
    value = TRUE
  )

  control_vars <- c(between_covs, within_covs)

  W_vars <- grep(
    "^W[1-9][0-9]*$",
    names(prepared_data),
    value = TRUE
  )

  if (length(W_vars) > 1L) {
    W_ids <- as.integer(sub("^W", "", W_vars))
    W_vars <- W_vars[order(W_ids)]
  }

  interaction_vars <- grep(
    "^int_",
    names(prepared_data),
    value = TRUE
  )

  if (length(MP) > 0L && length(W_vars) == 0L) {
    stop(
      "`MP` was specified, but no moderator variables were found.",
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 6. Helper functions for parameter names
  ## ------------------------------------------------------------------

  node_index <- function(node) {
    as.integer(sub("^M", "", node))
  }

  difference_variable <- function(node) {
    paste0(node, "diff")
  }

  average_variable <- function(node) {
    paste0(node, "avg")
  }

  edge_b_label <- function(from, to) {
    from_id <- node_index(from)

    if (to == "Y") {
      paste0("b", from_id)
    } else {
      paste0("b_", from_id, "_", node_index(to))
    }
  }

  edge_d_label <- function(from, to) {
    from_id <- node_index(from)

    if (to == "Y") {
      paste0("d", from_id)
    } else {
      paste0("d_", from_id, "_", node_index(to))
    }
  }

  moderated_terms <- function(variable, coefficient_stub) {
    if (length(W_vars) == 0L) {
      return(character(0))
    }

    expected_interactions <- paste0(
      "int_",
      variable,
      "_",
      W_vars
    )

    available <- expected_interactions %in% interaction_vars

    if (!all(available)) {
      missing_interactions <- expected_interactions[!available]

      stop(
        paste0(
          "The following interaction variables required by `MP` are missing: ",
          paste(missing_interactions, collapse = ", "),
          "."
        ),
        call. = FALSE
      )
    }

    paste0(
      coefficient_stub,
      "_",
      W_vars,
      "*",
      expected_interactions
    )
  }

  ## ------------------------------------------------------------------
  ## 7. Validate MP labels
  ## ------------------------------------------------------------------

  valid_MP <- c("cp", paste0("a", mediator_ids))

  for (i in seq_len(nrow(edges))) {
    valid_MP <- c(
      valid_MP,
      edge_b_label(edges$from[i], edges$to[i]),
      edge_d_label(edges$from[i], edges$to[i])
    )
  }

  valid_MP <- unique(valid_MP)
  invalid_MP <- setdiff(MP, valid_MP)

  if (length(invalid_MP) > 0L) {
    stop(
      paste0(
        "Unknown path label(s) in `MP`: ",
        paste(invalid_MP, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 8. Generate mediator regression equations
  ## ------------------------------------------------------------------

  mediator_regressions <- character(length(mediator_nodes))

  for (i in seq_along(mediator_nodes)) {
    mediator <- mediator_nodes[i]
    mediator_id <- node_index(mediator)

    a_label <- paste0("a", mediator_id)
    rhs <- paste0(a_label, "*1")

    incoming_edges <- edges[
      edges$to == mediator,
      ,
      drop = FALSE
    ]

    if (nrow(incoming_edges) > 0L) {
      source_ids <- vapply(
        incoming_edges$from,
        node_index,
        integer(1)
      )

      incoming_edges <- incoming_edges[
        order(source_ids),
        ,
        drop = FALSE
      ]

      for (j in seq_len(nrow(incoming_edges))) {
        source <- incoming_edges$from[j]

        b_label <- edge_b_label(source, mediator)
        d_label <- edge_d_label(source, mediator)

        source_diff <- difference_variable(source)
        source_avg  <- average_variable(source)

        rhs <- c(
          rhs,
          paste0(b_label, "*", source_diff),
          paste0(d_label, "*", source_avg)
        )

        if (b_label %in% MP) {
          rhs <- c(
            rhs,
            moderated_terms(
              source_diff,
              paste0("bw_", node_index(source), "_", mediator_id)
            )
          )
        }

        if (d_label %in% MP) {
          rhs <- c(
            rhs,
            moderated_terms(
              source_avg,
              paste0("dw_", node_index(source), "_", mediator_id)
            )
          )
        }
      }
    }

    if (length(W_vars) > 0L) {
      if (a_label %in% MP) {
        rhs <- c(
          rhs,
          paste0(
            "aw",
            mediator_id,
            "_",
            W_vars,
            "*",
            W_vars
          )
        )
      } else {
        rhs <- c(rhs, W_vars)
      }
    }

    if (length(control_vars) > 0L) {
      rhs <- c(rhs, control_vars)
    }

    mediator_regressions[i] <- paste0(
      mediator,
      "diff ~ ",
      paste(unique(rhs), collapse = " + ")
    )
  }

  ## ------------------------------------------------------------------
  ## 9. Generate outcome regression equation
  ## ------------------------------------------------------------------

  y_rhs <- "cp*1"

  outcome_edges <- edges[
    edges$to == "Y",
    ,
    drop = FALSE
  ]

  outcome_source_ids <- vapply(
    outcome_edges$from,
    node_index,
    integer(1)
  )

  outcome_edges <- outcome_edges[
    order(outcome_source_ids),
    ,
    drop = FALSE
  ]

  for (i in seq_len(nrow(outcome_edges))) {
    source <- outcome_edges$from[i]
    source_id <- node_index(source)

    b_label <- edge_b_label(source, "Y")
    d_label <- edge_d_label(source, "Y")

    source_diff <- difference_variable(source)
    source_avg  <- average_variable(source)

    y_rhs <- c(
      y_rhs,
      paste0(b_label, "*", source_diff),
      paste0(d_label, "*", source_avg)
    )

    if (b_label %in% MP) {
      y_rhs <- c(
        y_rhs,
        moderated_terms(
          source_diff,
          paste0("bw", source_id)
        )
      )
    }

    if (d_label %in% MP) {
      y_rhs <- c(
        y_rhs,
        moderated_terms(
          source_avg,
          paste0("dw", source_id)
        )
      )
    }
  }

  if (length(W_vars) > 0L) {
    if ("cp" %in% MP) {
      y_rhs <- c(
        y_rhs,
        paste0("cpw_", W_vars, "*", W_vars)
      )
    } else {
      y_rhs <- c(y_rhs, W_vars)
    }
  }

  if (length(control_vars) > 0L) {
    y_rhs <- c(y_rhs, control_vars)
  }

  outcome_regression <- paste0(
    "Ydiff ~ ",
    paste(unique(y_rhs), collapse = " + ")
  )

  ## ------------------------------------------------------------------
  ## 10. Find all directed paths from each mediator to Y
  ## ------------------------------------------------------------------

  find_paths_to_y <- function(current_node,
                              current_path = current_node) {

    if (current_node == "Y") {
      return(list(current_path))
    }

    next_nodes <- adjacency[[current_node]]

    if (length(next_nodes) == 0L) {
      return(list())
    }

    discovered_paths <- list()

    for (next_node in next_nodes) {
      new_paths <- find_paths_to_y(
        current_node = next_node,
        current_path = c(current_path, next_node)
      )

      discovered_paths <- c(
        discovered_paths,
        new_paths
      )
    }

    discovered_paths
  }

  indirect_paths <- list()

  for (mediator in mediator_nodes) {
    mediator_paths <- find_paths_to_y(mediator)

    if (length(mediator_paths) > 0L) {
      indirect_paths <- c(
        indirect_paths,
        mediator_paths
      )
    }
  }

  if (length(indirect_paths) == 0L) {
    stop(
      "No indirect paths from the mediators to `Y` were found.",
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 11. Convert paths into indirect-effect definitions
  ## ------------------------------------------------------------------

  indirect_names <- character(length(indirect_paths))
  indirect_lines <- character(length(indirect_paths))

  for (i in seq_along(indirect_paths)) {
    path <- indirect_paths[[i]]

    mediator_path <- path[path != "Y"]
    mediator_indices <- vapply(
      mediator_path,
      node_index,
      integer(1)
    )

    indirect_name <- paste0(
      "indirect_",
      paste(mediator_indices, collapse = "_")
    )

    coefficients <- paste0("a", mediator_indices[1L])

    for (j in seq_len(length(path) - 1L)) {
      coefficients <- c(
        coefficients,
        edge_b_label(path[j], path[j + 1L])
      )
    }

    indirect_names[i] <- indirect_name

    indirect_lines[i] <- paste0(
      indirect_name,
      " := ",
      paste(coefficients, collapse = " * ")
    )
  }

  ## ------------------------------------------------------------------
  ## 12. Warn about mediators that do not contribute to an indirect path
  ## ------------------------------------------------------------------

  mediators_in_indirect_paths <- unique(
    unlist(lapply(
      indirect_paths,
      function(path) path[path != "Y"]
    ))
  )

  disconnected_mediators <- setdiff(
    mediator_nodes,
    mediators_in_indirect_paths
  )

  if (length(disconnected_mediators) > 0L) {
    warning(
      paste0(
        "The following mediators do not belong to any path ending in Y: ",
        paste(disconnected_mediators, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  ## ------------------------------------------------------------------
  ## 13. Total indirect and total effects
  ## ------------------------------------------------------------------

  total_indirect <- paste0(
    "total_indirect := ",
    paste(indirect_names, collapse = " + ")
  )

  total_effect <- "total_effect := cp + total_indirect"

  ## ------------------------------------------------------------------
  ## 14. Combine model syntax
  ## ------------------------------------------------------------------

  sem_model <- paste(
    c(
      outcome_regression,
      mediator_regressions,
      indirect_lines,
      total_indirect,
      total_effect
    ),
    collapse = "\n"
  )

  sem_model
}
