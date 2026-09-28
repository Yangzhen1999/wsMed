# Run from the package root. This base-R check also runs in the CI matrix.
source("R/RandomGaussianEigenwrapper.R")
source("R/RandomGaussianCholwrapper.R")
source("R/RandomGaussianSVDwrapper.R")

# A known positive-definite symmetric root supplies an independent oracle.
root <- matrix(c(2, .25, -.1, .25, 1.5, .2, -.1, .2, 1), 3)
sigma <- crossprod(root)
z <- matrix(seq(-2, 2, length.out = 21), 7, 3)
dec <- eigen(sigma, symmetric = TRUE)
draws <- RandomGaussianEigenwrapper(z, dec)
expected <- z %*% root
stopifnot(max(abs(draws - expected)) < 1e-11)
stopifnot(max(abs(draws - RandomGaussianSVDwrapper(z, svd(sigma)))) < 1e-11)

dec$vectors <- sweep(dec$vectors, 2, c(-1, 1, -1), `*`)
stopifnot(max(abs(draws - RandomGaussianEigenwrapper(z, dec))) < 1e-11)

angle <- .37
rotation <- diag(3)
rotation[1:2, 1:2] <- matrix(c(cos(angle), sin(angle),
                              -sin(angle), cos(angle)), 2)
repeated <- list(values = c(4, 4, 1), vectors = rotation)
stopifnot(max(abs(RandomGaussianEigenwrapper(z, repeated) -
                  sweep(z, 2, c(2, 2, 1), `*`))) < 1e-11)

# Cholesky has a different fixed-seed coupling, but the same covariance.
factor <- RandomGaussianCholwrapper(diag(3), chol(sigma))
stopifnot(max(abs(crossprod(factor) - sigma)) < 1e-11)
cat("PASS: target covariance, sign/rotation invariance, known-root draws, SVD agreement\n")
print(sessionInfo())
print(extSoftVersion())
