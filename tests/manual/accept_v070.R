# scReportLite v0.7.0 manual acceptance script
#
# Run from the package root in the RStudio Console:
#   source("tests/manual/accept_v070.R", echo = TRUE)
#
# This script generates a deterministic five-page report with every current
# input layer represented. It does not install packages or modify package code.

required_packages <- c(
  "devtools", "testthat", "plotly", "htmltools", "jsonlite", "Matrix"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing packages: ", paste(missing_packages, collapse = ", "), "\n",
    "Install them in the RStudio Console with:\n",
    "install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))",
    call. = FALSE
  )
}

devtools::load_all(".", quiet = TRUE)

set.seed(700L)
n_cells <- 240L
cell_ids <- sprintf("cell_%04d", seq_len(n_cells))
samples <- rep(c("Control_1", "Control_2", "Treat_1", "Treat_2"),
               each = n_cells / 4L)
clusters <- rep(as.character(0:7), length.out = n_cells)

umap_df <- data.frame(
  cell = cell_ids,
  UMAP_1 = stats::rnorm(n_cells),
  UMAP_2 = stats::rnorm(n_cells),
  cluster = clusters,
  sample = samples,
  res_0.2 = rep(as.character(0:3), length.out = n_cells),
  res_0.4 = clusters,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

marker_df <- do.call(rbind, lapply(as.character(0:7), function(cluster) {
  data.frame(
    cluster = cluster,
    gene = paste0("Marker_", cluster, "_", seq_len(6L)),
    avg_log2FC = seq(2.5, 0.5, length.out = 6L),
    p_val_adj = 10^(-seq(12, 2, length.out = 6L)),
    stringsAsFactors = FALSE
  )
}))

gene_expr_df <- data.frame(
  cell = cell_ids,
  CD3D = stats::rgamma(n_cells, shape = 1.4),
  MS4A1 = stats::rgamma(n_cells, shape = 1.1),
  LST1 = stats::rgamma(n_cells, shape = 1.6),
  COL1A1 = stats::rgamma(n_cells, shape = 0.8),
  stringsAsFactors = FALSE
)

pca_df <- data.frame(
  cell = cell_ids,
  cluster = clusters,
  sample = samples,
  PC_1 = stats::rnorm(n_cells),
  PC_2 = stats::rnorm(n_cells),
  PC_3 = stats::rnorm(n_cells),
  PC_4 = stats::rnorm(n_cells),
  stringsAsFactors = FALSE
)

pca_loading_df <- expand.grid(
  gene = paste0("LoadingGene_", seq_len(20L)),
  PC = paste0("PC_", seq_len(4L)),
  stringsAsFactors = FALSE
)
pca_loading_df$loading <- stats::rnorm(nrow(pca_loading_df))

qc_df <- data.frame(
  cell = cell_ids,
  sample = samples,
  cluster = clusters,
  nCount_RNA = round(stats::rlnorm(n_cells, 8, 0.45)),
  nFeature_RNA = round(stats::rlnorm(n_cells, 7, 0.30)),
  percent.mt = stats::runif(n_cells, 0, 25),
  retained = seq_len(n_cells) %% 9L != 0L,
  stringsAsFactors = FALSE
)

feature_scatter <- qc_df[c(
  "cell", "cluster", "sample", "nCount_RNA", "nFeature_RNA", "percent.mt"
)]
variable_features <- data.frame(
  gene = paste0("VariableGene_", seq_len(100L)),
  mean = 10^stats::runif(100L, -3, 2),
  variance = stats::runif(100L),
  variance_standardized = stats::rexp(100L),
  variable = c(rep(TRUE, 60L), rep(FALSE, 40L)),
  rank = c(seq_len(60L), rep(NA_integer_, 40L)),
  label = c(rep(TRUE, 15L), rep(FALSE, 85L)),
  stringsAsFactors = FALSE
)
top_summary <- data.frame(
  gene = paste0("TopGene_", seq_len(16L)),
  rank = seq_len(16L),
  mean_percent = stats::runif(16L, 0.1, 4),
  q1_percent = stats::runif(16L, 0, 0.2),
  median_percent = stats::runif(16L, 0.2, 0.5),
  q3_percent = stats::runif(16L, 0.5, 1),
  lower_whisker_percent = 0,
  upper_whisker_percent = stats::runif(16L, 1, 2),
  max_percent = stats::runif(16L, 2, 6),
  detection_rate = stats::runif(16L, 10, 95),
  outlier_count = rep(2L, 16L),
  stringsAsFactors = FALSE
)
top_outliers <- do.call(rbind, lapply(seq_len(nrow(top_summary)), function(i) {
  indices <- c(i, i + nrow(top_summary))
  data.frame(
    gene = top_summary$gene[i],
    percent = c(top_summary$max_percent[i] * 0.85,
                top_summary$max_percent[i]),
    cell = cell_ids[indices],
    sample = samples[indices],
    cluster = clusters[indices],
    stringsAsFactors = FALSE
  )
}))
elbow_df <- data.frame(
  PC = seq_len(20L),
  stdev = rev(seq(1, 10, length.out = 20L)),
  variance = rev(seq(1, 100, length.out = 20L)),
  variance_percent = rep(5, 20L),
  cumulative_variance = seq(5, 100, by = 5),
  stringsAsFactors = FALSE
)
feature_diag <- structure(
  list(
    feature_scatter = list(
      data = feature_scatter,
      default_x = "nCount_RNA",
      default_y = "nFeature_RNA",
      default_color_by = "cluster"
    ),
    variable_features = variable_features,
    top_expressed = list(
      summary = top_summary,
      outliers = top_outliers,
      top_genes = top_summary$gene
    ),
    elbow = elbow_df
  ),
  class = c("scReportLite_feature_diag", "list")
)

output <- normalizePath("v070_acceptance.html", mustWork = FALSE)
sc_report(
  umap_df = umap_df,
  cluster_col = "cluster",
  cell_col = "cell",
  sample_col = "sample",
  resolution_cols = c("res_0.2", "res_0.4"),
  active_resolution = "res_0.4",
  marker_df = marker_df,
  gene_expr_df = gene_expr_df,
  pca_df = pca_df,
  pca_loading_df = pca_loading_df,
  qc_df = qc_df,
  feature_diag = feature_diag,
  panels = c(
    "qc", "feature", "pca", "umap", "marker_table",
    "cluster_size", "sample_composition", "gene_expression"
  ),
  use_webgl = TRUE,
  output = output,
  title = "scReportLite v0.7.0 Acceptance"
)

html <- paste(readLines(output, warn = FALSE, encoding = "UTF-8"),
              collapse = "\n")
required_markers <- c(
  "sr-view-preview", "sr-view-plot", "sr-view-feature",
  "sr-view-pca", "sr-view-umap", "window._QC_DATA",
  "window._FEATURE_DIAG_DATA", "window._PCA_DATA",
  "window._GENE_EXPR_DATA", "srl-panel-gene_expression",
  "gene-summary-placeholder", "Resolution overview"
)
missing_markers <- required_markers[
  !vapply(required_markers, grepl, logical(1), x = html, fixed = TRUE)
]
if (length(missing_markers)) {
  stop("Generated report is missing: ",
       paste(missing_markers, collapse = ", "), call. = FALSE)
}
if (grepl("Gene expression data not available", html, fixed = TRUE)) {
  stop("Gene expression panel received an empty-state payload", call. = FALSE)
}

message("Acceptance report generated: ", output)
message("Dependency directory: ",
        paste0(tools::file_path_sans_ext(output), "_files"))
message("Next: open the HTML in a browser and complete the interaction checklist.")
