test_that("cell ID vectors must be complete and unique", {
  expect_error(
    validate_cell_ids(c("cell1", NA), "umap_df", "cell"),
    "contains NA"
  )
  expect_error(
    validate_cell_ids(c("cell1", "  "), "umap_df", "cell"),
    "contains empty"
  )
  expect_error(
    validate_cell_ids(c("cell1", "cell1"), "umap_df", "cell"),
    "must be unique"
  )
  expect_silent(validate_cell_ids(c("cell1", "cell2"), "umap_df", "cell"))
})

test_that("UMAP and PCA cell sets may differ in order but not membership", {
  expect_silent(validate_cross_view_cell_ids(
    c("cell1", "cell2"),
    c("cell2", "cell1")
  ))
  expect_error(
    validate_cross_view_cell_ids(c("cell1", "cell2"), c("cell1", "cell3")),
    "1 only in umap_df and 1 only in pca_df",
    fixed = TRUE
  )
})

test_that("gene expression IDs cannot be duplicated", {
  gene_expr <- data.frame(cell = c("cell1", "cell1"), GENE = c(1, 2))
  umap <- data.frame(cell = c("cell1", "cell2"))
  expect_error(
    validate_gene_expr_df(gene_expr, umap, "cell"),
    "must be unique"
  )
})
