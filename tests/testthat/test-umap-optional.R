# Test: sc_report() UMAP-optional mode
#
# Verifies that sc_report() can generate reports without UMAP data
# (QC-only, Feature-only, PCA-only) and correctly errors on invalid
# combinations.

sc_report <- getFromNamespace("sc_report", "scReportLite")

make_qc <- function(n = 50) {
  data.frame(
    cell         = paste0("cell_", seq_len(n)),
    sample       = rep(c("A", "B"), length.out = n),
    nCount_RNA   = rnorm(n, 5000, 2000),
    nFeature_RNA = rnorm(n, 2000, 800),
    percent.mt   = pmax(0, rnorm(n, 10, 5)),
    stringsAsFactors = FALSE
  )
}

make_feature <- function() {
  set.seed(1)
  fs <- data.frame(cell = paste0("cell_", 1:50), nCount_RNA = rnorm(50, 5000, 2000),
                   nFeature_RNA = rnorm(50, 2000, 800), cluster = "1",
                   sample = "A", stringsAsFactors = FALSE)
  list(feature_scatter = list(data = fs, default_x = "nCount_RNA",
        default_y = "nFeature_RNA", default_color_by = "cluster"))
}

make_pca <- function(n = 50) {
  data.frame(
    cell    = paste0("cell_", seq_len(n)),
    cluster = rep(c("A", "B"), length.out = n),
    PC_1    = rnorm(n),
    PC_2    = rnorm(n),
    stringsAsFactors = FALSE
  )
}

test_that("QC-only report generates HTML", {
  qc <- make_qc(20)
  out <- file.path(tempdir(), "test_qc_only.html")
  sc_report(umap_df = NULL, qc_df = qc, panels = "qc", output = out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 500)
  unlink(out)
})

test_that("Feature-only report generates HTML", {
  fd <- make_feature()
  out <- file.path(tempdir(), "test_feature_only.html")
  sc_report(umap_df = NULL, feature_diag = fd, panels = "feature", output = out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 500)
  unlink(out)
})

test_that("PCA-only report generates HTML", {
  pca <- make_pca(20)
  out <- file.path(tempdir(), "test_pca_only.html")
  sc_report(umap_df = NULL, pca_df = pca, panels = "pca", output = out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 500)
  unlink(out)
})

test_that("umap panel with NULL umap_df errors clearly", {
  expect_error(
    sc_report(umap_df = NULL, panels = "umap", output = file.path(tempdir(), "tmp.html")),
    "umap_df is NULL"
  )
})

test_that("gene_expr_df without umap_df errors clearly", {
  ge <- data.frame(cell = "c1", GENE = 1.5, stringsAsFactors = FALSE)
  expect_error(
    sc_report(umap_df = NULL, gene_expr_df = ge, panels = "qc",
              qc_df = make_qc(10), output = file.path(tempdir(), "tmp.html")),
    "gene_expr_df requires umap_df"
  )
})

test_that("marker_table with NULL umap_df warns and still generates with QC", {
  qc <- make_qc(20)
  out <- file.path(tempdir(), "test_marker_skip.html")
  expect_warning(
    sc_report(umap_df = NULL, qc_df = qc, panels = c("qc", "marker_table"),
              output = out),
    "marker_table"
  )
  expect_true(file.exists(out))
  unlink(out)
})

test_that("Full UMAP report still works (backward compat)", {
  umap <- data.frame(
    cell   = paste0("cell_", 1:20),
    UMAP_1 = rnorm(20), UMAP_2 = rnorm(20),
    cluster = rep(c("A", "B"), each = 10),
    stringsAsFactors = FALSE
  )
  out <- file.path(tempdir(), "test_full_umap.html")
  sc_report(umap, panels = c("umap", "marker_table"), output = out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 1000)
  unlink(out)
})

test_that("No viewable panels errors clearly", {
  expect_error(
    sc_report(umap_df = NULL, panels = "marker_table",
              output = file.path(tempdir(), "tmp.html")),
    "No viewable panels"
  )
})
