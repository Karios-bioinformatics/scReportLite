# scReportLite: QC diagnostic plots for Plot view ---------------------------------
# v0.3.0 — Four QC plots: nCount_RNA, nFeature_RNA, percent.mt distributions
#          plus nCount_RNA vs nFeature_RNA scatter.
#
# Architecture:
#   build_qc_plotly() takes qc_df and returns a named list of 4 plotly
#   htmlwidget objects.  The calling code (sc_report.R) embeds them into
#   the #sr-view-plot container and JS handles show/hide switching.
#
#   Distribution plots use horizontally-jittered scatter points, one trace
#   per sample, to provide full per-cell hover tooltips.
#   The scatter plot colours by sample with one trace per sample.


#' Build QC diagnostic plotly widgets
#'
#' Returns a named list of four plotly htmlwidget objects:
#' \describe{
#'   \item{nCount_RNA}{Distribution of UMI counts per cell, jittered by sample}
#'   \item{nFeature_RNA}{Distribution of detected genes per cell, jittered by sample}
#'   \item{percent_mt}{Distribution of mitochondrial percentage per cell, jittered by sample}
#'   \item{ncount_vs_nfeature}{Scatter plot of nCount_RNA vs nFeature_RNA, coloured by sample}
#' }
#'
#' @param qc_df Data frame with QC metrics. Must contain columns:
#'   \code{cell}, \code{sample}, \code{nCount_RNA}, \code{nFeature_RNA},
#'   \code{percent.mt}.
#'   Optional: \code{cluster}, \code{condition}, \code{batch}.
#' @param cluster_col Name of the cluster column in qc_df (default \code{"cluster"}).
#'   If the column exists, cluster info is included in hover tooltips.
#' @param cell_col Name of the cell/barcode column in qc_df.
#' @param sample_col Name of the sample column in qc_df.
#' @param use_webgl Use WebGL (scattergl) rendering.  Default \code{TRUE}.
#' @return A named list of four plotly htmlwidget objects.
#' @keywords internal
build_qc_plotly <- function(qc_df,
                             cluster_col = "cluster",
                             cell_col    = "cell",
                             sample_col  = "sample",
                             use_webgl   = TRUE) {

  # ---- Validate columns ----
  required <- c(cell_col, sample_col, "nCount_RNA", "nFeature_RNA", "percent.mt")
  missing <- setdiff(required, colnames(qc_df))
  if (length(missing) > 0) {
    stop("qc_df is missing required columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  has_cluster <- cluster_col %in% colnames(qc_df)

  samples      <- sort(unique(qc_df[[sample_col]]))
  sample_cols  <- cluster_color_map(samples)
  trace_type   <- if (use_webgl) "scattergl" else "scatter"

  message("build_qc_plotly: ", length(samples), " samples detected",
          if (use_webgl) " (WebGL)" else " (SVG)")

  # ---- Shared hover builder ----
  build_qc_hover <- function(df, i) {
    h <- paste0(
      "Cell: ",         df[[cell_col]][i],
      "<br>Sample: ",   df[[sample_col]][i],
      "<br>nCount_RNA: ",    df[["nCount_RNA"]][i],
      "<br>nFeature_RNA: ",  df[["nFeature_RNA"]][i],
      "<br>percent.mt: ",    sprintf("%.2f%%", df[["percent.mt"]][i])
    )
    if (has_cluster) {
      h <- paste0(h, "<br>Cluster: ", df[[cluster_col]][i])
    }
    h
  }

  # ---- Helper: build a distribution jitter plot for one metric ----
  build_dist_plot <- function(metric, y_title) {
    p <- plotly::plot_ly(type = trace_type)

    for (si in seq_along(samples)) {
      s   <- samples[si]
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      # Horizontal jitter within [si - 0.3, si + 0.3]
      jitter_x <- rep(si, n) + runif(n, -0.30, 0.30)

      hover_texts <- vapply(seq_len(n), function(i) build_qc_hover(sub, i),
                            character(1), USE.NAMES = FALSE)

      p <- plotly::add_trace(
        p,
        x          = jitter_x,
        y          = sub[[metric]],
        text       = hover_texts,
        hoverinfo  = "text",
        type       = trace_type,
        mode       = "markers",
        marker     = list(
          color   = unname(sample_cols[s]),
          size    = 3,
          opacity = 0.7
        ),
        name       = paste0("qc_", s),
        showlegend = FALSE
      )
    }

    p <- plotly::layout(
      p,
      title  = sprintf("QC \u2014 %s", y_title),
      xaxis  = list(
        title     = "",
        ticktext  = as.character(samples),
        tickvals  = seq_along(samples),
        showgrid  = FALSE
      ),
      yaxis  = list(title = y_title, showgrid = TRUE),
      hovermode = "closest",
      margin    = list(l = 80, r = 30, b = 80, t = 50),
      dragmode  = "pan"
    )
    p <- plotly::config(
      p,
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c(
        "sendDataToCloud", "lasso2d", "select2d",
        "autoScale2d", "toggleSpikelines"
      ),
      displaylogo = FALSE
    )
    p
  }

  # ---- Helper: nCount_RNA vs nFeature_RNA scatter ----
  build_scatter <- function() {
    p <- plotly::plot_ly(type = trace_type)

    for (s in samples) {
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      hover_texts <- vapply(seq_len(n), function(i) build_qc_hover(sub, i),
                            character(1), USE.NAMES = FALSE)

      p <- plotly::add_trace(
        p,
        x          = sub[["nCount_RNA"]],
        y          = sub[["nFeature_RNA"]],
        text       = hover_texts,
        hoverinfo  = "text",
        type       = trace_type,
        mode       = "markers",
        marker     = list(
          color   = unname(sample_cols[s]),
          size    = 3,
          opacity = 0.7
        ),
        name       = paste0("qc_scatter_", s),
        showlegend = FALSE
      )
    }

    p <- plotly::layout(
      p,
      title     = "QC \u2014 nCount_RNA vs nFeature_RNA",
      xaxis     = list(title = "nCount_RNA", showgrid = FALSE),
      yaxis     = list(title = "nFeature_RNA", showgrid = FALSE),
      hovermode = "closest",
      margin    = list(l = 80, r = 30, b = 60, t = 50),
      dragmode  = "pan"
    )
    p <- plotly::config(
      p,
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c(
        "sendDataToCloud", "lasso2d", "select2d",
        "autoScale2d", "toggleSpikelines"
      ),
      displaylogo = FALSE
    )
    p
  }

  # ---- Build all four plots ----
  message("  Building nCount_RNA distribution...")
  p_ncount <- build_dist_plot("nCount_RNA", "nCount_RNA")

  message("  Building nFeature_RNA distribution...")
  p_nfeature <- build_dist_plot("nFeature_RNA", "nFeature_RNA")

  message("  Building percent.mt distribution...")
  p_pct_mt  <- build_dist_plot("percent.mt", "percent.mt")

  message("  Building nCount vs nFeature scatter...")
  p_scatter <- build_scatter()

  list(
    nCount_RNA          = p_ncount,
    nFeature_RNA        = p_nfeature,
    percent_mt          = p_pct_mt,
    ncount_vs_nfeature  = p_scatter
  )
}
