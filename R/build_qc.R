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
#' @param max_points_per_group Deprecated compatibility argument. Since v0.7.0,
#'   every QC cell is sent to the browser and no point sampling is performed.
#' @param qc_status_col Optional column identifying whether a cell was retained
#'   or filtered. When omitted, \code{qc_status}, \code{filter_status}, or
#'   \code{retained} is detected when present.
#' @return A named list with elements \code{samples}, \code{sample_colors},
#'   \code{cells} (a list of per-cell records).
#' @keywords internal
build_qc_payload <- function(qc_df,
                              cluster_col = "cluster",
                              cell_col    = "cell",
                              sample_col  = "sample",
                              max_points_per_group = 1000,
                              qc_status_col = NULL) {

  required <- c(cell_col, sample_col, "nCount_RNA", "nFeature_RNA", "percent.mt")
  missing <- setdiff(required, colnames(qc_df))
  if (length(missing) > 0)
    stop("qc_df is missing required columns: ", paste(missing, collapse = ", "),
         call. = FALSE)

  has_cluster <- cluster_col %in% colnames(qc_df)
  if (is.null(qc_status_col)) {
    candidates <- intersect(
      c("qc_status", "filter_status", "retained"),
      colnames(qc_df)
    )
    qc_status_col <- if (length(candidates)) candidates[[1L]] else NULL
  }
  if (!is.null(qc_status_col) && !qc_status_col %in% colnames(qc_df)) {
    stop("qc_status_col not found in qc_df: ", qc_status_col, call. = FALSE)
  }
  samples     <- natural_sort(unique(qc_df[[sample_col]]))
  sample_cols <- cluster_color_map(samples)
  # force plain character keys / values
  sample_cols <- stats::setNames(unname(sample_cols), names(sample_cols))

  message("build_qc_payload: ", length(samples), " samples, ",
          nrow(qc_df), " cells")

  # Validate QC metric columns
  qc_cols <- c("nCount_RNA", "nFeature_RNA", "percent.mt")
  for (col in qc_cols) {
    vals <- qc_df[[col]]
    if (!is.numeric(vals)) {
      stop("qc_df column '", col, "' must be numeric, got ", class(vals)[1],
           call. = FALSE)
    }
    bad <- is.nan(vals) | is.infinite(vals)
    if (any(bad, na.rm = TRUE)) {
      stop("qc_df column '", col, "' contains Inf or NaN values",
           call. = FALSE)
    }
  }

  # ---- Build per-cell record list ----
  build_cells <- function(df) {
    n <- nrow(df)
    cells <- vector("list", n)
    for (i in seq_len(n)) {
      rec <- list(
        cell        = as.character(df[[cell_col]][i]),
        sample      = as.character(df[[sample_col]][i]),
        nCount_RNA  = df[["nCount_RNA"]][i],
        nFeature_RNA= df[["nFeature_RNA"]][i],
        percent_mt  = df[["percent.mt"]][i]
      )
      if (has_cluster)
        rec$cluster <- as.character(df[[cluster_col]][i])
      raw_status <- if (is.null(qc_status_col)) "retained" else df[[qc_status_col]][i]
      retained <- if (is.logical(raw_status)) {
        isTRUE(raw_status)
      } else {
        tolower(as.character(raw_status)) %in% c(
          "retained", "pass", "passed", "keep", "kept", "true", "1"
        )
      }
      rec$qc_status <- if (retained) "retained" else "filtered"
      cells[[i]] <- rec
    }
    cells
  }

  cells <- build_cells(qc_df)

  # v0.7.0 never samples QC cells: every point remains available for decisions.
  point_indices <- seq_len(nrow(qc_df))

  list(
    samples       = as.character(samples),
    sample_colors = sample_cols,
    cells         = cells,
    point_indices = point_indices - 1L  # 0-based for JS
  )
}
