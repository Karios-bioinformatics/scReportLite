\name{sc_report_data}
\alias{sc_report_data}
\title{Generate an interactive report from prepared result tables}
\usage{
sc_report_data(
  umap_df = NULL,
  cluster_col = "cluster",
  cell_col = "cell",
  sample_col = NULL,
  resolution_cols = NULL,
  active_resolution = NULL,
  clustree_edges = NULL,
  marker_df = NULL,
  gene_expr_df = NULL,
  pca_df = NULL,
  pca_color_by = "sample",
  pca_loading_df = NULL,
  pca_loading_top_n = 10,
  qc_df = NULL,
  feature_diag = NULL,
  output = "sc_report.html",
  title = "scRNA-seq Report",
  point_size = 3,
  point_alpha = 0.9,
  dim_opacity = 0.06,
  marker_n_top = 20,
  panels = c("umap", "marker_table"),
  use_webgl = TRUE,
  qc_metrics = NULL,
  report_warnings = character(),
  report_context = list()
)
}
\arguments{
\item{umap_df}{Prepared UMAP coordinates with cell and cluster columns.}
\item{cluster_col, cell_col, sample_col}{Column names for cluster, cell, and optional sample identities.}
\item{resolution_cols, active_resolution, clustree_edges}{Compatibility inputs for the read-only Preview resolution summary.}
\item{marker_df}{Optional user-supplied marker result table.}
\item{gene_expr_df}{Optional wide cell-by-gene expression table.}
\item{pca_df}{Optional cell-level PCA score table.}
\item{pca_color_by}{Initial PCA grouping mode.}
\item{pca_loading_df}{Optional PCA loading table.}
\item{pca_loading_top_n, marker_n_top}{Deprecated compatibility arguments; supplied rows are retained.}
\item{qc_df}{Optional cell-level QC table.}
\item{feature_diag}{Optional feature-diagnostics payload.}
\item{output}{Output HTML file path.}
\item{title}{Report title.}
\item{point_size, point_alpha, dim_opacity}{Plot display settings.}
\item{panels}{Requested report panels.}
\item{use_webgl}{Whether large interactive scatter views use WebGL.}
\item{qc_metrics}{QC columns to display; numeric non-identifier columns are inferred when omitted.}
\item{report_warnings}{Additional messages shown in Preview.}
\item{report_context}{Optional report-level cell, cluster, and sample summaries used when a module is absent.}
}
\value{Invisibly, the output HTML path.}
\description{Advanced interface for users who already have prepared report tables. No biological analysis is performed.}
