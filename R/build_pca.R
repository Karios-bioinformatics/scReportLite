# scReportLite: Interactive PCA build -------------------------------------------
# v0.2.1 — pca_color_by parameter for per-metadata colour grouping


#' Build an interactive plotly PCA scatter plot
#'
#' Creates a plotly scatter plot with one trace per unique value of the
#' colour-grouping column, mirroring the UMAP build architecture.
#' \code{customdata} is a 5-element array for each cell:
#' \code{[cell_id, cluster, sample, PC_1, PC_2]}.
#' Hover text always includes the original cluster assignment regardless
#' of the colour-grouping column.
#'
#' @param pca_df Data frame with PCA coordinates and cluster assignments.
#'   Must contain columns: \code{cell}, \code{PC_1}, \code{PC_2}, \code{cluster}.
#' @param cluster_col Name of the cluster column in pca_df
#' @param cell_col Name of the cell/barcode column in pca_df
#' @param sample_col Optional name of the sample column (NULL to skip)
#' @param color_by Column name to colour by. Default \code{"cluster"}.
#'   Must exist in \code{pca_df}; falls back to \code{"cluster"} with a
#'   warning if missing.
#' @param point_size Marker size for scatter points
#' @param point_alpha Opacity for markers (0-1)
#' @param use_webgl Use WebGL (scattergl) instead of SVG (scatter).
#'   Default: \code{TRUE}.
#' @return A plotly htmlwidget object
#'
#' @keywords internal
build_pca_plotly <- function(pca_df, cluster_col, cell_col,
                              sample_col = NULL,
                              color_by = "cluster",
                              point_size, point_alpha,
                              use_webgl = TRUE) {
  # Resolve colour column — fall back to cluster_col if missing
  color_col <- color_by
  if (!color_col %in% colnames(pca_df)) {
    warning("PCA colour column '", color_col,
            "' not found in pca_df. Falling back to '", cluster_col, "'.",
            call. = FALSE)
    color_col <- cluster_col
  }

  groups     <- sort(unique(pca_df[[color_col]]))
  colors     <- cluster_color_map(groups)
  has_samples <- !is.null(sample_col) && sample_col %in% colnames(pca_df)

  trace_type <- if (use_webgl) "scattergl" else "scatter"

  message("build_pca_plotly: ", length(groups), " groups detected",
          " (colour by '", color_col, "')",
          if (use_webgl) " (WebGL)" else " (SVG)")

  p <- plotly::plot_ly(type = trace_type)

  for (grp in groups) {
    grp_char <- as.character(grp)
    idx      <- pca_df[[color_col]] == grp
    sub      <- pca_df[idx, ]
    n        <- nrow(sub)

    message(sprintf("  %s: %d cells", grp_char, n))

    # ---- Hover text (always includes cluster and optional sample) ----
    hover <- sprintf(
      "Cell: %s<br>Cluster: %s<br>PC_1: %.3f<br>PC_2: %.3f",
      sub[[cell_col]],
      sub[[cluster_col]],
      sub[["PC_1"]],
      sub[["PC_2"]]
    )

    if (has_samples) {
      hover <- paste0(hover, "<br>Sample: ", as.character(sub[[sample_col]]))
    }

    # ---- Per-point customdata: [cell_id, cluster, sample, PC_1, PC_2] ----
    cd <- lapply(seq_len(n), function(i) {
      list(
        as.character(sub[[cell_col]][i]),
        as.character(sub[[cluster_col]][i]),
        if (has_samples) as.character(sub[[sample_col]][i]) else "",
        sub[["PC_1"]][i],
        sub[["PC_2"]][i]
      )
    })

    p <- plotly::add_trace(
      p,
      x          = sub[["PC_1"]],
      y          = sub[["PC_2"]],
      customdata = cd,
      text       = hover,
      hoverinfo  = "text",
      name       = paste0("pca_", grp_char),
      marker     = list(
        color   = unname(colors[grp_char]),
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
      title    = "PC_1",
      showgrid = FALSE,
      zeroline = FALSE,
      showticklabels = TRUE
    ),
    yaxis = list(
      title    = "PC_2",
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
