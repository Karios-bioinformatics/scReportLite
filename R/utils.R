# scReportLite: Utility functions ------------------------------------------------

#' Validate input data frames for sc_report
#'
#' Checks that umap_df and optional marker_df contain required columns
#' with appropriate types. Stops with a clear error message on failure.
#'
#' @param umap_df Data frame with UMAP coordinates and cluster assignments
#' @param marker_df Optional marker gene data frame (can be NULL)
#' @param cluster_col Name of the cluster column
#' @param cell_col Name of the cell/barcode column
#' @return Invisibly TRUE if valid; stops otherwise
#'
#' @keywords internal
validate_inputs <- function(umap_df, marker_df, cluster_col, cell_col) {
  if (!is.data.frame(umap_df)) {
    stop("umap_df must be a data.frame", call. = FALSE)
  }

  required_umap <- c(cell_col, "UMAP_1", "UMAP_2", cluster_col)
  missing_umap <- setdiff(required_umap, colnames(umap_df))
  if (length(missing_umap) > 0) {
    stop(
      "umap_df is missing required columns: ",
      paste(missing_umap, collapse = ", "),
      call. = FALSE
    )
  }

  if (anyNA(umap_df[[cluster_col]])) {
    stop("cluster column '", cluster_col, "' contains NA values", call. = FALSE)
  }

  if (length(unique(umap_df[[cluster_col]])) < 1) {
    stop("cluster column '", cluster_col, "' must have at least one cluster",
         call. = FALSE)
  }

  # Validate marker_df if provided
  if (!is.null(marker_df)) {
    if (!is.data.frame(marker_df)) {
      stop("marker_df must be a data.frame or NULL", call. = FALSE)
    }
    required_marker <- c("cluster", "gene", "avg_log2FC", "p_val_adj")
    missing_marker <- setdiff(required_marker, colnames(marker_df))
    if (length(missing_marker) > 0) {
      stop(
        "marker_df is missing required columns: ",
        paste(missing_marker, collapse = ", "),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}


#' Generate a cluster-color mapping
#'
#' Creates a named vector mapping cluster IDs to hex color codes using
#' a 32-color qualitative palette optimized for distinguishability on white
#' backgrounds. Colors are recycled with a warning if cluster count exceeds
#' palette size.
#'
#' @param clusters Character vector of unique cluster identifiers
#' @return Named character vector of hex colors
#'
#' @keywords internal
cluster_color_map <- function(clusters) {
  # 32-color qualitative palette — saturated, wide hue spread,
  # tested for pairwise distinguishability on white background.
  palette <- c(
    "#E6194B", "#3CB44B", "#FFE119", "#0082C8", "#F58231", "#911EB4",
    "#46F0F0", "#F032E6", "#BCF60C", "#E6BEFF", "#008080", "#A52A2A",
    "#AA6E28", "#800000", "#22B14C", "#808000", "#000080", "#808080",
    "#DC143C", "#0A751C", "#FF6600", "#6200EA", "#B8860B", "#00CED1",
    "#6A1B9A", "#9E9D24", "#E91E63", "#0288D1", "#388E3C", "#D81B60",
    "#8D6E63", "#7C4DFF"
  )

  n <- length(clusters)
  if (n > length(palette)) {
    warning(
      "Number of clusters (", n, ") exceeds palette size (",
      length(palette), "). Colors will be recycled.",
      call. = FALSE
    )
  }
  colors <- rep(palette, length.out = n)
  names(colors) <- as.character(clusters)
  colors
}


#' Format a p-value for display
#'
#' Formats p-values with scientific notation for very small values
#' and fixed decimal for moderate values.
#'
#' @param p Numeric p-value
#' @return Character string of formatted p-value
#'
#' @keywords internal
format_pval <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 1e-4) return(format(p, digits = 2, scientific = TRUE))
  if (p < 0.001) return(sprintf("%.6f", p))
  if (p < 0.01) return(sprintf("%.5f", p))
  sprintf("%.4f", p)
}
