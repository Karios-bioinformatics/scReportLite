# Test: validate_inputs() rejects non-numeric UMAP coordinates
#
# Verifies that UMAP_1 / UMAP_2 must already be numeric — the previous
# "coercible" behaviour was removed to prevent silent data mismatches.

# Source package functions for dev-mode testing
pkg_root <- if (requireNamespace("scReportLite", quietly = TRUE)) {
  system.file(package = "scReportLite")
} else {
  normalizePath(file.path("..", ".."), winslash = "/")
}
if (!exists("validate_inputs", mode = "function")) {
  for (f in list.files(file.path(pkg_root, "R"), full.names = TRUE, pattern = "\\.R$")) {
    source(f)
  }
}

make_umap <- function(umap1, umap2) {
  data.frame(
    cell    = paste0("cell_", seq_along(umap1)),
    UMAP_1  = umap1,
    UMAP_2  = umap2,
    cluster = rep(c("A", "B"), length.out = length(umap1)),
    stringsAsFactors = FALSE
  )
}

test_that("valid numeric UMAP passes validation", {
  df <- make_umap(rnorm(10), rnorm(10))
  expect_silent(validate_inputs(df, marker_df = NULL, "cluster", "cell"))
})

test_that("character UMAP_1 is rejected", {
  df <- make_umap(c("1.0", "2.0", "3.0"), rnorm(3))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "must be numeric"
  )
})

test_that("character UMAP_2 is rejected", {
  df <- make_umap(rnorm(3), c("1.0", "2.0", "3.0"))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "must be numeric"
  )
})

test_that("NA in UMAP_1 is rejected", {
  df <- make_umap(c(1.0, NA, 3.0), rnorm(3))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "NA, NaN, or Inf"
  )
})

test_that("NaN in UMAP_1 is rejected", {
  df <- make_umap(c(1.0, NaN, 3.0), rnorm(3))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "NA, NaN, or Inf"
  )
})

test_that("Inf in UMAP_2 is rejected", {
  df <- make_umap(rnorm(3), c(1.0, Inf, 3.0))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "NA, NaN, or Inf"
  )
})

test_that("factor UMAP_1 is rejected (no silent coercion)", {
  df <- make_umap(factor(c("1", "2", "3")), rnorm(3))
  expect_error(
    validate_inputs(df, marker_df = NULL, "cluster", "cell"),
    "must be numeric"
  )
})
