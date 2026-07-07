# Test: validate_inputs() rejects non-numeric UMAP coordinates and
# marker_df columns with NA/NaN/Inf.

validate_inputs <- getFromNamespace("validate_inputs", "scReportLite")

make_umap <- function(umap1, umap2) {
  data.frame(
    cell    = paste0("cell_", seq_along(umap1)),
    UMAP_1  = umap1,
    UMAP_2  = umap2,
    cluster = rep(c("A", "B"), length.out = length(umap1)),
    stringsAsFactors = FALSE
  )
}

make_marker <- function(lfc, pval_adj) {
  data.frame(
    cluster     = "A",
    gene        = paste0("GENE_", seq_along(lfc)),
    avg_log2FC  = lfc,
    p_val_adj   = pval_adj,
    stringsAsFactors = FALSE
  )
}

# ---- UMAP validation ----

test_that("valid numeric UMAP passes validation", {
  df <- make_umap(rnorm(10), rnorm(10))
  expect_silent(validate_inputs(df, marker_df = NULL, "cluster", "cell"))
})

test_that("character UMAP_1 is rejected", {
  df <- make_umap(c("1.0", "2.0", "3.0"), rnorm(3))
  expect_error(validate_inputs(df, marker_df = NULL, "cluster", "cell"), "must be numeric")
})

test_that("NA in UMAP_1 is rejected", {
  df <- make_umap(c(1.0, NA, 3.0), rnorm(3))
  expect_error(validate_inputs(df, marker_df = NULL, "cluster", "cell"), "NA, NaN, or Inf")
})

test_that("Inf in UMAP_2 is rejected", {
  df <- make_umap(rnorm(3), c(1.0, Inf, 3.0))
  expect_error(validate_inputs(df, marker_df = NULL, "cluster", "cell"), "NA, NaN, or Inf")
})

test_that("factor UMAP_1 is rejected (no silent coercion)", {
  df <- make_umap(factor(c("1", "2", "3")), rnorm(3))
  expect_error(validate_inputs(df, marker_df = NULL, "cluster", "cell"), "must be numeric")
})

# ---- marker_df numeric validation ----

test_that("valid marker_df passes", {
  m <- make_marker(rnorm(5, 0, 1), runif(5, 0, 0.05))
  um <- make_umap(rnorm(10), rnorm(10))
  expect_silent(validate_inputs(um, marker_df = m, "cluster", "cell"))
})

test_that("marker_df avg_log2FC with NA is rejected", {
  m <- make_marker(c(1.0, NA, 0.5), c(0.01, 0.02, 0.03))
  um <- make_umap(rnorm(3), rnorm(3))
  expect_error(validate_inputs(um, marker_df = m, "cluster", "cell"),
               "contains NA, NaN, or Inf")
})

test_that("marker_df avg_log2FC with Inf is rejected", {
  m <- make_marker(c(1.0, Inf, 0.5), c(0.01, 0.02, 0.03))
  um <- make_umap(rnorm(3), rnorm(3))
  expect_error(validate_inputs(um, marker_df = m, "cluster", "cell"),
               "contains NA, NaN, or Inf")
})

test_that("marker_df p_val_adj with NaN is rejected", {
  m <- make_marker(c(1.0, -0.5, 0.5), c(0.01, NaN, 0.03))
  um <- make_umap(rnorm(3), rnorm(3))
  expect_error(validate_inputs(um, marker_df = m, "cluster", "cell"),
               "contains NA, NaN, or Inf")
})

test_that("marker_df p_val_adj non-numeric is rejected", {
  m <- make_marker(c(1.0, -0.5), c("0.01", "0.02"))
  um <- make_umap(rnorm(2), rnorm(2))
  expect_error(validate_inputs(um, marker_df = m, "cluster", "cell"),
               "must be numeric")
})
