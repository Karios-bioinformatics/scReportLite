\name{build_qc_payload}
\alias{build_qc_payload}
\title{Build QC data payload for client-side rendering}
\usage{
build_qc_payload(
  qc_df,
  cluster_col = "cluster",
  cell_col = "cell",
  sample_col = "sample",
  qc_metrics = NULL,
  max_points_per_group = 1000,
  qc_status_col = NULL
)
}
\arguments{
\item{qc_df}{Data frame containing cell identifiers and QC metrics.}
\item{cluster_col}{Name of the optional cluster column.}
\item{cell_col}{Name of the cell identifier column.}
\item{sample_col}{Name of the sample column, or \code{NULL}.}
\item{qc_metrics}{Optional numeric QC columns. Numeric non-identifier columns are inferred when omitted.}
\item{max_points_per_group}{Deprecated compatibility argument. Every QC cell is retained.}
\item{qc_status_col}{Optional column indicating retained or filtered status.}
}
\value{A JSON-serialisable list containing samples, metric metadata, complete per-cell records, and point indices.}
\description{Prepares existing QC values for browser rendering. It does not calculate, impute, or filter QC values.}
\keyword{internal}
