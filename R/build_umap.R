# scReportLite: Interactive UMAP build -------------------------------------------
# v0.1.3 — traces built individually with per-point customdata so that
# click events and hover tooltips always refer to the same cell, regardless
# of whether SVG or WebGL rendering is used.

#' Build an interactive plotly UMAP scatter plot
#'
#' Creates a plotly scatter plot with one trace per cluster, built manually
#' so that customdata is embedded per-point. \code{customdata} is a 5-element
#' array for each cell:
#' \code{[cell_id, cluster, sample, UMAP_1, UMAP_2]}.
#' The plotly legend is hidden — cluster selection is handled by the custom
#' sidebar in the report HTML.
#'
#' @param umap_df Data frame with UMAP coordinates and cluster assignments
#' @param cluster_col Name of the cluster column in umap_df
#' @param cell_col Name of the cell/barcode column in umap_df
#' @param sample_col Optional name of the sample column (NULL to skip)
#' @param point_size Marker size for scatter points
#' @param point_alpha Opacity for markers (0-1), applied as initial value
#' @param use_webgl Use WebGL (scattergl) instead of SVG (scatter).
#'   Default: \code{TRUE}.
#' @return A plotly htmlwidget object
#'
#' @keywords internal
build_umap_plotly <- function(umap_df, cluster_col, cell_col,
                               sample_col = NULL,
                               point_size, point_alpha,
                               use_webgl = TRUE) {
  clusters    <- sort(unique(umap_df[[cluster_col]]))
  colors      <- cluster_color_map(clusters)
  has_samples <- !is.null(sample_col)

  trace_type <- if (use_webgl) "scattergl" else "scatter"

  message("build_umap_plotly: ", length(clusters), " clusters detected",
          if (use_webgl) " (WebGL)" else " (SVG)")

  # Start with an empty plot of the correct trace type
  p <- plotly::plot_ly(type = trace_type)

  for (cl in clusters) {
    cl_char <- as.character(cl)
    idx     <- umap_df[[cluster_col]] == cl
    sub     <- umap_df[idx, ]
    n       <- nrow(sub)

    message(sprintf("  Cluster %s: %d cells", cl_char, n))

    # ---- Hover text ----
    hover <- sprintf(
      "Cell: %s<br>Cluster: %s<br>UMAP_1: %.3f<br>UMAP_2: %.3f",
      sub[[cell_col]],
      sub[[cluster_col]],
      sub[["UMAP_1"]],
      sub[["UMAP_2"]]
    )

    # ---- Per-point customdata: [cell_id, cluster, sample, UMAP_1, UMAP_2] ----
    cd <- lapply(seq_len(n), function(i) {
      list(
        as.character(sub[[cell_col]][i]),
        cl_char,
        if (has_samples) as.character(sub[[sample_col]][i]) else "",
        sub[["UMAP_1"]][i],
        sub[["UMAP_2"]][i]
      )
    })

    p <- plotly::add_trace(
      p,
      x          = sub[["UMAP_1"]],
      y          = sub[["UMAP_2"]],
      customdata = cd,
      text       = hover,
      hoverinfo  = "text",
      name       = paste0("cluster_", cl_char),
      marker     = list(
        color   = unname(colors[cl_char]),
        size    = point_size,
        opacity = point_alpha
      ),
      mode       = "markers",
      showlegend = FALSE
    )
  }

  # ---- Layout ----
  p <- plotly::layout(
    p,
    xaxis = list(
      title    = "UMAP_1",
      showgrid = FALSE,
      zeroline = FALSE,
      showticklabels = TRUE
    ),
    yaxis = list(
      title    = "UMAP_2",
      showgrid = FALSE,
      zeroline = FALSE,
      showticklabels = TRUE,
      scaleanchor = "x",
      scaleratio  = 1
    ),
    hovermode  = "closest",
    margin     = list(l = 60, r = 30, b = 60, t = 30),
    dragmode   = "pan"
  )

  # ---- Config ----
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
