# Test: build_qc_payload() sampling with max_points_per_group
#
# Regression test for a bug where the every-k downsampling code referenced
# the wrong parameter name (max_points_per_gene instead of max_points_per_group).

build_qc_payload <- getFromNamespace("build_qc_payload", "scReportLite")
cluster_color_map <- getFromNamespace("cluster_color_map", "scReportLite")
natural_sort     <- getFromNamespace("natural_sort", "scReportLite")

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

  expect_type(payload, "list")
  expect_true(all(c("samples", "sample_colors", "cells", "point_indices") %in% names(payload)))

  n_idx <- length(payload$point_indices)
  expected_min <- 60
  expected_max <- 100
  expect_true(n_idx >= expected_min && n_idx <= expected_max,
    info = sprintf("point_indices length %d not in [%d, %d]", n_idx, expected_min, expected_max))

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

test_that("build_qc_payload rejects non-numeric QC columns", {
  df <- make_qc(5, 5)
  df$nCount_RNA <- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j")
  expect_error(build_qc_payload(df), "must be numeric")
})

test_that("build_qc_payload rejects Inf in QC columns", {
  df <- make_qc(5, 5)
  df$nCount_RNA[1] <- Inf
  expect_error(build_qc_payload(df), "contains Inf or NaN")
})

test_that("build_qc_payload rejects NaN in QC columns", {
  df <- make_qc(5, 5)
  df$nFeature_RNA[2] <- NaN
  expect_error(build_qc_payload(df), "contains Inf or NaN")
})

test_that("build_qc_payload preserves missing QC metrics", {
  df <- make_qc(5, 5)
  df$nCount_RNA[1] <- NA
  expect_message(
    payload <- build_qc_payload(df, max_points_per_group = 100),
    "build_qc_payload"
  )

  idx <- which(vapply(payload$cells, function(x) x$cell == df$cell[1], logical(1)))
  expect_true(is.na(payload$cells[[idx]]$nCount_RNA))
  expect_false(identical(payload$cells[[idx]]$nCount_RNA, 0))
  json <- jsonlite::toJSON(payload, auto_unbox = TRUE, na = "null")
  expect_match(json, '"nCount_RNA":null', fixed = TRUE)
})
