testthat::test_that("report views preserve their module and slot contract", {
  assemble_report <- getFromNamespace("assemble_report", "scReportLite")

  umap_df <- data.frame(
    cell = c("cell_1", "cell_2"),
    cluster = c("0", "1"),
    sample = c("A", "B"),
    stringsAsFactors = FALSE
  )
  pca_df <- data.frame(
    cell = umap_df$cell,
    cluster = umap_df$cluster,
    PC_1 = c(-1, 1),
    PC_2 = c(1, -1),
    stringsAsFactors = FALSE
  )
  qc_payload <- list(
    cells = as.list(umap_df$cell),
    samples = list(),
    metrics = list()
  )
  feature_diag <- list(feature_scatter = data.frame(cell = umap_df$cell))

  output <- tempfile(fileext = ".html")
  libdir <- paste0(tools::file_path_sans_ext(output), "_files")
  on.exit(unlink(c(output, libdir), recursive = TRUE), add = TRUE)

  assemble_report(
    umap_plot = NULL,
    umap_df = umap_df,
    marker_df = NULL,
    cluster_col = "cluster",
    cell_col = "cell",
    sample_col = "sample",
    pca_df = pca_df,
    qc_payload = qc_payload,
    feature_diag = feature_diag,
    output = output,
    title = "Module contract",
    dim_opacity = 0.1,
    marker_n_top = 10L,
    panels = c("qc", "feature", "pca", "umap", "marker_table")
  )

  html <- paste(readLines(output, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  view_ids <- c(
    "sr-view-plot",
    "sr-view-feature",
    "sr-view-pca",
    "sr-view-umap"
  )
  testthat::expect_true(all(vapply(
    view_ids,
    function(id) {
      matches <- gregexpr(paste0('id="', id, '"'), html, fixed = TRUE)[[1]]
      length(matches) == 1L && matches[[1]] > 0L
    },
    logical(1)
  )))

  slot_classes <- c(
    "plot-nav", "plot-main", "plot-params",
    "feature-nav", "feature-main", "feature-params",
    "pca-controls", "pca-plot-area",
    "sidebar", "content-area"
  )
  testthat::expect_true(all(vapply(
    slot_classes,
    function(class_name) grepl(paste0('class="', class_name), html, fixed = TRUE),
    logical(1)
  )))

  tab_positions <- vapply(
    c("view-tab-plot", "view-tab-feature", "view-tab-pca", "view-tab-umap"),
    function(id) regexpr(id, html, fixed = TRUE)[[1]],
    integer(1)
  )
  testthat::expect_true(all(tab_positions > 0L))
  testthat::expect_equal(tab_positions, sort(tab_positions))

  data_markers <- c(
    "window._QC_DATA",
    "window._FEATURE_DIAG_DATA",
    "window._PCA_DATA",
    "window._MARKER_DATA"
  )
  testthat::expect_true(all(vapply(
    data_markers,
    function(marker) grepl(marker, html, fixed = TRUE),
    logical(1)
  )))
})
