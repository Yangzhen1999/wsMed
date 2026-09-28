test_that("eigen sampling ignores arbitrary signs and repeated-eigenvalue bases", {
  angle <- 0.37
  rotation <- matrix(c(cos(angle), sin(angle), -sin(angle), cos(angle)), 2)
  basis <- diag(3)
  basis[1:2, 1:2] <- rotation
  decomposition <- list(values = c(4, 4, 1), vectors = diag(3))
  alternative <- list(values = c(4, 4, 1),
                      vectors = sweep(basis, 2, c(-1, 1, -1), `*`))
  z <- matrix(seq(-2, 2, length.out = 15), 5, 3)
  expected <- sweep(z, 2, c(2, 2, 1), `*`)
  expect_equal(RandomGaussianEigenwrapper(z, decomposition), expected,
               tolerance = 1e-12)
  expect_equal(RandomGaussianEigenwrapper(z, alternative), expected,
               tolerance = 1e-12)
})

test_that("the sampling transform has the specified covariance including singular cases", {
  for (sigma in list(matrix(c(2, .6, .6, 1), 2), matrix(1, 2, 2),
                     matrix(9, 1, 1))) {
    transform <- RandomGaussianEigenwrapper(diag(nrow(sigma)),
                                            eigen(sigma, symmetric = TRUE))
    expect_equal(crossprod(transform), sigma, tolerance = 1e-12)
    expect_equal(transform, t(transform), tolerance = 1e-12)
  }
})

test_that("a nearly repeated spectrum does not amplify tiny input perturbations", {
  sigma <- diag(c(2, 2, 1))
  perturbed <- sigma
  perturbed[1, 2] <- perturbed[2, 1] <- 1e-13
  z <- matrix(seq(-2, 2, length.out = 30), 10, 3)
  before <- RandomGaussianEigenwrapper(z, eigen(sigma, symmetric = TRUE))
  after <- RandomGaussianEigenwrapper(z, eigen(perturbed, symmetric = TRUE))
  expect_lt(max(abs(before - after)), 1e-10)
})

test_that("MI sampler preserves location, names, seed behavior and covariance checks", {
  sigma <- matrix(c(2, .6, .6, 1), 2)
  location <- c(b1 = .2, d1 = -.1)
  set.seed(23)
  a <- ThetaHatStarWrapper(R = 40000, scale = sigma, location = location)
  set.seed(23)
  b <- ThetaHatStarWrapper(R = 40000, scale = sigma, location = location)
  expect_identical(a, b)
  expect_identical(colnames(a$thetahatstar), names(location))
  expect_equal(unname(colMeans(a$thetahatstar)), unname(location), tolerance = .03)
  expect_equal(unname(cov(a$thetahatstar)), sigma, tolerance = .04)
  expect_error(ThetaHatStarWrapper(R = 10, scale = diag(c(1, -1)),
                                  location = location), "nonpositive definite")
  # Existing clipping of negligible negative eigenvalues is retained.
  set.seed(23)
  near_psd <- ThetaHatStarWrapper(R = 5, scale = diag(c(1, -1e-12)),
                                 location = c(a = 0, b = 0))
  expect_equal(unname(near_psd$thetahatstar[, 2]), rep(0, 5))
})
