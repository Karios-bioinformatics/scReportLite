testthat::test_that("gene expression data reaches the registered panel", {
  umap_df <- data.frame(
    cell = c("cell_1", "cell_2", "cell_3"),
    UMAP_1 = c(-1, 0, 1),
    UMAP_2 = c(1, 0, -1),
    cluster = c("0", "0", "1"),
    sample = c("A", "A", "B"),
    stringsAsFactors = FALSE
  )
  gene_expr_df <- data.frame(
    cell = umap_df$cell,
    CD3D = c(2.5, 1.2, 0),
    MS4A1 = c(0, 0.1, 3.4),
    stringsAsFactors = FALSE
  )

  output <- tempfile(fileext = ".html")
  libdir <- paste0(tools::file_path_sans_ext(output), "_files")
  on.exit(unlink(c(output, libdir), recursive = TRUE), add = TRUE)

  sc_report(
    umap_df = umap_df,
    gene_expr_df = gene_expr_df,
    cluster_col = "cluster",
    cell_col = "cell",
    sample_col = "sample",
    panels = c("umap", "gene_expression"),
    output = output,
    title = "Gene expression panel contract"
  )

  html <- paste(
    readLines(output, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  testthat::expect_match(
    html,
    'id="srl-panel-gene_expression"',
    fixed = TRUE
  )
  testthat::expect_match(
    html,
    'id="gene-summary-placeholder"',
    fixed = TRUE
  )
  testthat::expect_match(html, "window._GENE_EXPR_DATA", fixed = TRUE)
  testthat::expect_match(html, '"CD3D"', fixed = TRUE)
  testthat::expect_false(grepl(
    "Gene expression data not available",
    html,
    fixed = TRUE
  ))
})

testthat::test_that("gene expression panel keeps its explicit empty state", {
  panel <- getFromNamespace("panel_gene_expression", "scReportLite")
  html <- as.character(panel$render(list(gene_expr_df = NULL)))

  testthat::expect_match(
    html,
    "Gene expression data not available",
    fixed = TRUE
  )
  testthat::expect_false(grepl(
    'id="gene-summary-placeholder"',
    html,
    fixed = TRUE
  ))
})
