# Test: build_qc_payload() sampling with max_points_per_group
#
# Regression test for a bug where the every-k downsampling code referenced
# the wrong parameter name (max_points_per_gene instead of max_points_per_group).

# Source package functions for dev-mode testing
pkg_root <- if (requireNamespace("scReportLite", quietly = TRUE)) {
  system.file(package = "scReportLite")
} else {
  normalizePath(file.path("..", ".."), winslash = "/")
}
src <- file.path(pkg_root, "R")
for (f in list.files(src, full.names = TRUE, pattern = "\\.R$")) {
  source(f)
}

make_qc <- function(n_ctrl, n_treat) {
  n <- n_ctrl + n_treat
  data.frame(
    cell         = paste0("cell_", seq_len(n)),
    sample       = c(rep("Control", n_ctrl), rep("Treatment", n_treat)),
    cluster      = rep(c("A", "B"), length.out = n),
    nCount_RNA   = pmax(100, rnorm(n, 5000, 2000)),
    nFeature_RNA = pmax(50,  rnorm(n, 2000, 800)),
    percent.mt   = pmax(0,  rnorm(n, 10, 5)),
    stringsAsFactors = FALSE
  )
}

test_that("build_qc_payload handles sample larger than max_points_per_group", {
  df <- make_qc(n_ctrl = 2000, n_treat = 50)
  max_pts <- 30

  payload <- build_qc_payload(df, max_points_per_group = max_pts)

  # Must not error, must return a list with expected elements
  expect_type(payload, "list")
  expect_true(all(c("samples", "sample_colors", "cells", "point_indices") %in% names(payload)))

  # point_indices is 0-based; check reasonable length
  n_idx <- length(payload$point_indices)
  # Control (2000 cells): k = ceiling(2000/30) = 67, ~30 points
  # Treatment (50 cells): all 50 cells included (n <= max_pts)
  # Total expected: ~ 30 + 50 = 80, but allow ±20% tolerance
  expected_min <- 60
  expected_max <- 100
  expect_true(n_idx >= expected_min && n_idx <= expected_max,
    info = sprintf("point_indices length %d not in [%d, %d]", n_idx, expected_min, expected_max))

  # Every index should be in [0, nrow(df)-1] (0-based)
  expect_true(all(payload$point_indices >= 0))
  expect_true(all(payload$point_indices < nrow(df)))
})

test_that("build_qc_payload small data (all cells fit) returns all indices", {
  df <- make_qc(5, 5)
  payload <- build_qc_payload(df, max_points_per_group = 100)

  expect_equal(length(payload$point_indices), 10)
  expect_equal(sort(payload$point_indices), 0:9)
})

test_that("build_qc_payload with missing columns errors clearly", {
  df <- data.frame(cell = "a", sample = "b", stringsAsFactors = FALSE)
  expect_error(build_qc_payload(df), "missing required columns")
})
