# Test: with_seed() preserves caller's .Random.seed state
#
# Verifies that the internal with_seed helper does not pollute or
# create a persistent global .Random.seed where none existed before.

# Source package functions for dev-mode testing
pkg_root <- if (requireNamespace("scReportLite", quietly = TRUE)) {
  system.file(package = "scReportLite")
} else {
  normalizePath(file.path("..", ".."), winslash = "/")
}
if (!exists("with_seed", mode = "function")) {
  source(file.path(pkg_root, "R", "utils.R"))
}

test_that("with_seed restores existing .Random.seed", {
  set.seed(123)
  old <- .GlobalEnv$.Random.seed
  result <- with_seed(42, sample(1000, 10))
  expect_identical(.GlobalEnv$.Random.seed, old)
  expect_equal(length(result), 10)
})

test_that("with_seed removes .Random.seed when none existed before", {
  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(.Random.seed, envir = .GlobalEnv)
  }
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))

  result <- with_seed(42, sample(1000, 10))

  # After with_seed, .Random.seed should NOT exist (was removed)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  expect_equal(length(result), 10)
})

test_that("with_seed returns the expression value", {
  val <- with_seed(42, { x <- rnorm(5); sum(x) })
  expect_type(val, "double")
  expect_length(val, 1)
})

test_that("with_seed produces deterministic output", {
  a <- with_seed(42, sample(100, 5))
  b <- with_seed(42, sample(100, 5))
  expect_identical(a, b)
})
