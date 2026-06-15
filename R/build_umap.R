# scReportLite: Interactive UMAP build -------------------------------------------

#' Build an interactive plotly UMAP scatter plot
#'
#' Creates a plotly scatter plot with one trace per cluster. Each trace
#' is a separate layer, enabling per-cluster opacity control via JavaScript.
#' The plotly legend is hidden — cluster selection is handled by the custom
#' sidebar in the report HTML.
#'
#' @param umap_df Data frame with UMAP coordinates and cluster assignments
#' @param cluster_col Name of the cluster column in umap_df
#' @param cell_col Name of the cell/barcode column in umap_df
#' @param point_size Marker size for scatter points
#' @param point_alpha Opacity for markers (0-1), applied as initial value
#' @return A plotly htmlwidget object
#'
#' @keywords internal
build_umap_plotly <- function(umap_df, cluster_col, cell_col,
                               point_size, point_alpha,
                               use_webgl = TRUE) {
  clusters <- sort(unique(umap_df[[cluster_col]]))
  colors <- cluster_color_map(clusters)

  message("build_umap_plotly: ", length(clusters), " clusters detected",
          if (use_webgl) " (WebGL)" else " (SVG)")

  # Prepare columns for single-call plot_ly with split
  umap_df$cluster_for_plot <- as.character(umap_df[[cluster_col]])
  umap_df$hover <- sprintf(
    "Cell: %s<br>Cluster: %s<br>UMAP_1: %.3f<br>UMAP_2: %.3f",
    umap_df[[cell_col]],
    umap_df[[cluster_col]],
    umap_df[["UMAP_1"]],
    umap_df[["UMAP_2"]]
  )

  # Per-cluster cell counts for debug
  for (cl in clusters) {
    n <- sum(umap_df$cluster_for_plot == as.character(cl))
    message(sprintf("  Cluster %s: %d cells", cl, n))
  }

  # Single call: split = per-cluster traces, color + colors = explicit palette
  # so UMAP point colors match sidebar cluster_color_map() output exactly.
  trace_type <- if (use_webgl) "scattergl" else "scatter"
  p <- plotly::plot_ly(
    data       = umap_df,
    x          = ~UMAP_1,
    y          = ~UMAP_2,
    split      = ~cluster_for_plot,
    color      = ~cluster_for_plot,
    colors     = colors,
    type       = trace_type,
    mode       = "markers",
    text       = ~hover,
    hoverinfo  = "text",
    marker     = list(
      size    = point_size,
      opacity = point_alpha
    ),
    showlegend = FALSE
  )

  pb <- plotly::plotly_build(p)
  message("  length(plotly_build(p)$x$data) = ", length(pb$x$data),
          "  (expected ", length(clusters), ")")

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
