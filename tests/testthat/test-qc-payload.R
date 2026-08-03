# Test: build_qc_payload() preserves every QC cell

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

test_that("build_qc_payload ignores the legacy cap and keeps every cell", {
  df <- make_qc(n_ctrl = 2000, n_treat = 50)
  max_pts <- 30

  payload <- build_qc_payload(df, max_points_per_group = max_pts)

  expect_type(payload, "list")
  expect_true(all(c("samples", "sample_colors", "cells", "point_indices") %in% names(payload)))

  expect_equal(length(payload$point_indices), nrow(df))
  expect_equal(payload$point_indices, seq.int(0L, nrow(df) - 1L))
})

test_that("build_qc_payload small data (all cells fit) returns all indices", {
  df <- make_qc(5, 5)
  payload <- build_qc_payload(df, max_points_per_group = 100)

  expect_equal(length(payload$point_indices), 10)
  expect_equal(sort(payload$point_indices), 0:9)
})

test_that("build_qc_payload with missing columns errors clearly", {
  df <- data.frame(sample = "b", value = 1, stringsAsFactors = FALSE)
  expect_error(build_qc_payload(df), "missing required columns")
})

test_that("build_qc_payload rejects non-numeric QC columns", {
  df <- make_qc(5, 5)
  df$nCount_RNA <- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j")
  expect_error(build_qc_payload(df, qc_metrics = "nCount_RNA"), "must be numeric")
})

test_that("build_qc_payload treats Inf as missing with a warning", {
  df <- make_qc(5, 5)
  df$nCount_RNA[1] <- Inf
  expect_warning(payload <- build_qc_payload(df), "treated as missing")
  expect_true(is.na(payload$cells[[1]]$nCount_RNA))
})

test_that("build_qc_payload treats NaN as missing with a warning", {
  df <- make_qc(5, 5)
  df$nFeature_RNA[2] <- NaN
  expect_warning(payload <- build_qc_payload(df), "treated as missing")
  expect_true(is.na(payload$cells[[2]]$nFeature_RNA))
})

test_that("build_qc_payload supports custom metrics and no sample column", {
  df <- data.frame(cell = c("a", "b"), cluster = c("1", "2"), custom_qc = c(1, 2))
  payload <- build_qc_payload(df, sample_col = NULL)
  expect_identical(payload$metrics, "custom_qc")
  expect_false(payload$has_sample)
  expect_identical(payload$samples, "All cells")
  expect_equal(payload$cells[[2]]$custom_qc, 2)
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

test_that("build_qc_payload preserves retained and filtered cell status", {
  df <- make_qc(1L, 1L)
  df$retained <- c(TRUE, FALSE)
  payload <- build_qc_payload(df)
  testthat::expect_identical(
    vapply(payload$cells, `[[`, character(1), "qc_status"),
    c("retained", "filtered")
  )
})
