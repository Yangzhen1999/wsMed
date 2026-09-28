# An observed product containing an endogenous mediator is not exogenous to
# that mediator's disturbance. Its upstream disturbances can also covary with
# it. Model these products as auxiliary responses, regressed on the remaining
# exogenous predictors, with freely covarying product disturbances. This is a
# reparameterization of their unrestricted joint predictor moment block, not
# a causal equation for the deterministic products. It retains lavaan's usual
# exogenous covariance handling and fixed.x semantics for genuine exogenous
# predictors (rather than inadvertently fixing endogenous product moments).
.wsmed_product_covariances <- function(syntax) {
  if (!grepl("int_M[0-9]+diff_W[0-9]+", syntax)) return(syntax)
  pt <- lavaan::lavaanify(syntax, fixed.x = FALSE)
  regressions <- pt[pt$op == "~", c("lhs", "rhs")]
  endogenous <- unique(regressions$lhs)
  predictors <- unique(regressions$rhs)
  products <- sort(grep("^int_M[0-9]+diff_W[0-9]+$", predictors, value = TRUE))
  if (!length(products)) return(syntax)
  exogenous <- sort(setdiff(predictors, c(endogenous, products)))
  ancestors <- function(node) {
    found <- node
    repeat {
      parents <- regressions$rhs[regressions$lhs %in% found]
      next_nodes <- union(found, intersect(parents, endogenous))
      if (identical(next_nodes, found)) return(found)
      found <- next_nodes
    }
  }
  residual_covariances <- unlist(lapply(products, function(product) {
    source <- sub("^int_(M[0-9]+diff)_W[0-9]+$", "\\1", product)
    paste(sort(ancestors(source)), "~~", product)
  }), use.names = FALSE)
  product_regressions <- paste(products, "~", paste(exogenous, collapse = " + "))
  product_covariances <- vapply(seq_along(products), function(i) {
    paste(products[i], "~~", paste(products[i:length(products)], collapse = " + "))
  }, character(1))
  paste(c(syntax, product_regressions, product_covariances, residual_covariances),
        collapse = "\n")
}
