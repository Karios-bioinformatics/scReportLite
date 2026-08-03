\name{sc_report}
\alias{sc_report}
\title{Generate an interactive report from an existing Seurat object}
\usage{
sc_report(
  object,
  markers = NULL,
  cluster = NULL,
  sample = NULL,
  assay = NULL,
  layer = "data",
  umap = NULL,
  pca = NULL,
  qc_metrics = c("nCount_RNA", "nFeature_RNA", "percent.mt"),
  panels = "all",
  output_dir = NULL,
  output = NULL,
  title = NULL,
  overwrite = FALSE,
  open = FALSE,
  ...
)
}
\arguments{
\item{object}{A Seurat object. Seurat v5 is the primary supported interface; Seurat v4 is supported on a best-effort basis.}
\item{markers}{Optional user-supplied marker result table. Markers are never calculated by scReportLite.}
\item{cluster}{Optional metadata column used as cluster identity. Active identities are used when omitted.}
\item{sample}{Optional sample metadata column. \code{orig.ident} is used when available.}
\item{assay}{Assay from which existing expression values are read.}
\item{layer}{Existing expression layer used for gene colouring. Defaults to \code{"data"}; counts are never used as a silent fallback.}
\item{umap, pca}{Optional reduction names. Ambiguous reductions must be selected explicitly.}
\item{qc_metrics}{Metadata columns to expose as QC metrics.}
\item{panels}{Report pages to include, or \code{"all"}.}
\item{output_dir}{Report bundle directory. If omitted, a local-time-stamped directory is created.}
\item{output}{Compatibility argument for the legacy prepared-table interface. With a Seurat object, use \code{output_dir}.}
\item{title}{Report title. Defaults to the Seurat project name.}
\item{overwrite}{Whether an existing output directory may be replaced.}
\item{open}{Whether to open the generated report in a browser.}
\item{...}{Display options passed to \code{sc_report_data()}.}
}
\value{Invisibly, the path to the generated \code{index.html}.}
\description{
Extracts results that already exist in a Seurat object and turns them into an
interactive report. It does not normalize data, select features, calculate
PCA or UMAP, cluster cells, correct batches, calculate markers, perform
differential expression, or annotate cell types.
}
\examples{
\dontrun{
sc_report(object = seu, markers = markers)
}
}
