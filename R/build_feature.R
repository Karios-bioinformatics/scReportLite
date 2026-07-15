# scReportLite: Seurat Feature Diagnostics builder ----------------------------------------
# v0.4.0 - Feature Diagnostics view (Seurat-first).
#
# build_seurat_feature_diagnostics() extracts lightweight diagnostic data
# from a Seurat object so it can be passed to sc_report(..., feature_diag = ...).
# No full expression matrices are returned - only summary statistics and
# sampled points suitable for interactive HTML rendering.

#' Build Seurat feature diagnostics payload
#'
#' Extracts FeatureScatter, VariableFeatures, Top Expressed Genes, and ElbowPlot
#' data from a Seurat object as lightweight data.frames / lists ready for
#' \code{sc_report(feature_diag = ...)}.  No expression matrices are included
#' in the output.
#'
#' @param seurat_obj A Seurat object (tested with Seurat v4/v5).
#' @param assay Assay name to use for expression data. If \code{NULL},
#'   \code{DefaultAssay(seurat_obj)} is used.
#' @param reduction Name of the PCA reduction in the Seurat object.
#'   Default \code{"pca"}.
#' @param scatter_features Character vector of metadata/QC columns to include
#'   in the FeatureScatter data. Default: \code{c("nCount_RNA", "nFeature_RNA",
#'   "percent.mt")}.  Columns that don't exist are silently skipped.
#' @param scatter_gene_features Optional character vector of gene names whose
#'   expression should be included in FeatureScatter data. Default \code{NULL}.
#' @param top_n_variable Max number of variable-feature rows to include in the
#'   output.  Default 2000.
#' @param top_n_label Number of top variable genes to mark as "label" for the
#'   frontend.  Default 20.
#' @param top_n_expressed Number of top expressed genes to include in the
#'   boxplot summary.  Default 50.
#' @param max_points_per_gene Max jitter points per gene for Top Expressed.
#'   Default 1000.
#' @param max_scatter_points Max cells in FeatureScatter output.  Larger
#'   datasets are deterministically sampled.  Default 50000.
#' @param dims Dimensions to check for PCA (used for fallback and ElbowPlot).
#'   Default \code{1:50}.
#' @return A list with elements \code{feature_scatter}, \code{variable_features},
#'   \code{top_expressed}, and \code{elbow}.  Each sub-element is \code{NULL}
#'   when the data is unavailable.  The top-level list has class
#'   \code{"scReportLite_feature_diag"}.
#' @export
#'
#' @examples
#' \dontrun{
#' library(Seurat)
#' data("pbmc_small")
#' fd <- build_seurat_feature_diagnostics(pbmc_small)
#' sc_report(umap_df, feature_diag = fd,
#'           panels = c("feature", "umap"))
#' }
build_seurat_feature_diagnostics <- function(
    seurat_obj,
    assay                 = NULL,
    reduction             = "pca",
    scatter_features      = c("nCount_RNA", "nFeature_RNA", "percent.mt"),
    scatter_gene_features = NULL,
    top_n_variable        = 2000,
    top_n_label           = 20,
    top_n_expressed       = 50,
    max_points_per_gene   = 1000,
    max_scatter_points    = 50000,
    dims                  = 1:50) {

  if (!requireNamespace("Seurat", quietly = TRUE)) {
    stop(
      "Package 'Seurat' is required to use build_seurat_feature_diagnostics().\n",
      "SeuratObject alone is insufficient \u2014 this function calls Seurat::DefaultAssay,",
      " Seurat::GetAssayData, Seurat::Idents, etc.\n",
      "Install with: install.packages('Seurat')",
      call. = FALSE
    )
  }

  if (is.null(assay)) {
    assay <- tryCatch(Seurat::DefaultAssay(seurat_obj),
                      error = function(e) "RNA")
  }

  # ---- A. FeatureScatter data ----
  message("build_seurat_feature_diagnostics: building FeatureScatter data...")
  fs_data <- .build_feature_scatter(
    seurat_obj, assay, scatter_features, scatter_gene_features,
    max_scatter_points
  )

  # ---- B. VariableFeaturePlot data ----
  message("build_seurat_feature_diagnostics: building VariableFeatures data...")
  vf_data <- .build_variable_features(seurat_obj, assay, top_n_variable,
                                       top_n_label)

  # ---- C. Top Expressed Genes data ----
  message("build_seurat_feature_diagnostics: building Top Expressed Genes data...")
  te_data <- .build_top_expressed(seurat_obj, assay, top_n_expressed,
                                   max_points_per_gene)

  # ---- D. ElbowPlot data ----
  message("build_seurat_feature_diagnostics: building ElbowPlot data...")
  elb_data <- .build_elbow(seurat_obj, reduction, dims)

  out <- list(
    feature_scatter  = fs_data,
    variable_features = vf_data,
    top_expressed    = te_data,
    elbow            = elb_data
  )
  class(out) <- c("scReportLite_feature_diag", "list")
  out
}
