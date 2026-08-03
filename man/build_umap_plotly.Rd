\name{build_umap_plotly}
\alias{build_umap_plotly}
\title{Build an interactive Plotly UMAP scatter plot}
\usage{
build_umap_plotly(
  umap_df,
  cluster_col,
  cell_col,
  sample_col = NULL,
  point_size,
  point_alpha,
  use_webgl = TRUE
)
}
\arguments{
\item{umap_df}{Data frame with UMAP coordinates and cluster assignments.}
\item{cluster_col}{Name of the cluster column.}
\item{cell_col}{Name of the cell identifier column.}
\item{sample_col}{Optional sample column name.}
\item{point_size}{Scatter-point size.}
\item{point_alpha}{Initial point opacity.}
\item{use_webgl}{Whether to use WebGL rather than SVG rendering.}
}
\value{A Plotly HTML widget.}
\description{Creates one UMAP trace per non-empty cluster with complete per-cell custom data for linked report interactions.}
\keyword{internal}
