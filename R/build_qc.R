# scReportLite: QC data payload for client-side rendering -----------------------
# v0.3.0 — Data-driven QC: build_qc_payload() prepares a JSON-serialisable
#          list of per-cell QC metrics.  No plotly widgets are created in R.
#          All QC plots are rendered on-demand by JS using Plotly.newPlot /
#          Plotly.react on a single active canvas.
#
# Architecture:
#   build_qc_payload() → list(samples, sample_colors, cells)
#   sc_report.R serialises to JSON → window._QC_DATA
#   JS _PLOT_renderCurrentState() reads _PLOT_STATE + _QC_DATA → renders


#' Build QC data payload for client-side rendering
#'
#' Returns a list ready for \code{jsonlite::toJSON(..., auto_unbox = TRUE)}
#' containing sample metadata and per-cell QC metrics.  No plotly htmlwidgets
#' are created — all rendering happens in the browser on a single active canvas.
#'
#' @param qc_df Data frame with QC metrics.
#' @param cluster_col Name of the cluster column (default "cluster").
#' @param cell_col Name of the cell/barcode column.
#' @param sample_col Name of the sample column.
#' @param max_points_per_group Cap on jitter-point rows per sample×metric group
#'   sent to the browser.  Violin KDE uses full data; only the overlay points
#'   are sampled.  Default 1000.
#' @return A named list with elements \code{samples}, \code{sample_colors},
#'   \code{cells} (a list of per-cell records).
#' @keywords internal
build_qc_payload <- function(qc_df,
                              cluster_col = "cluster",
                              cell_col    = "cell",
                              sample_col  = "sample",
                              max_points_per_group = 1000) {

  required <- c(cell_col, sample_col, "nCount_RNA", "nFeature_RNA", "percent.mt")
  missing <- setdiff(required, colnames(qc_df))
  if (length(missing) > 0)
    stop("qc_df is missing required columns: ", paste(missing, collapse = ", "),
         call. = FALSE)

  has_cluster <- cluster_col %in% colnames(qc_df)
  samples     <- natural_sort(unique(qc_df[[sample_col]]))
  sample_cols <- cluster_color_map(samples)
  # force plain character keys / values
  sample_cols <- setNames(unname(sample_cols), names(sample_cols))

  message("build_qc_payload: ", length(samples), " samples, ",
          nrow(qc_df), " cells")

  # ---- Build per-cell record list ----
  build_cells <- function(df) {
    n <- nrow(df)
    cells <- vector("list", n)
    for (i in seq_len(n)) {
      rec <- list(
        cell        = as.character(df[[cell_col]][i]),
        sample      = as.character(df[[sample_col]][i]),
        nCount_RNA  = if (is.na(df[["nCount_RNA"]][i]))   0 else df[["nCount_RNA"]][i],
        nFeature_RNA= if (is.na(df[["nFeature_RNA"]][i])) 0 else df[["nFeature_RNA"]][i],
        percent_mt  = if (is.na(df[["percent.mt"]][i]))   0 else df[["percent.mt"]][i]
      )
      if (has_cluster)
        rec$cluster <- as.character(df[[cluster_col]][i])
      cells[[i]] <- rec
    }
    cells
  }

  cells <- build_cells(qc_df)

  # ---- Point-overlay sampling (keep full data for violins, sample points) ----
  point_indices <- integer(0)
  for (s in samples) {
    idx_s <- which(qc_df[[sample_col]] == s)
    n_s   <- length(idx_s)
    if (n_s <= max_points_per_group) {
      point_indices <- c(point_indices, idx_s)
    } else {
      # deterministic sample: every k-th cell
      k <- with_seed(42, ceiling(n_s / max_points_per_gene))
      keep <- idx_s[seq(1, n_s, by = k)]
      point_indices <- c(point_indices, keep)
    }
  }

  list(
    samples       = as.character(samples),
    sample_colors = sample_cols,
    cells         = cells,
    point_indices = point_indices - 1L  # 0-based for JS
  )
}
