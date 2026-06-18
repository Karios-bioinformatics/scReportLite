# scReportLite: Interactive UMAP build -------------------------------------------
# v0.1.6 — hover_cols, color_by, annotation_col, show_cluster_label support


#' Build an interactive plotly UMAP scatter plot
#'
#' Creates a plotly scatter plot with one trace per cluster, built manually
#' so that customdata is embedded per-point. \code{customdata} is an array
#' for each cell:
#' \code{[cell_id, cluster, sample, UMAP_1, UMAP_2, annotation_val]}.
#' The plotly legend is hidden for cluster-coloured plots; when
#' \code{color_by} is set to a discrete column, a legend is shown.
#'
#' @param umap_df Data frame with UMAP coordinates and cluster assignments
#' @param cluster_col Name of the cluster column in umap_df
#' @param cell_col Name of the cell/barcode column in umap_df
#' @param sample_col Optional name of the sample column (NULL to skip)
#' @param hover_cols Optional character vector of extra columns to show
#'   in hover tooltips. Columns not found trigger a warning and are skipped.
#' @param color_by Optional column name for UMAP point colouring.
#'   \code{NULL} (default) colours by cluster. Discrete columns receive
#'   categorical colours with a legend; continuous columns use the Viridis
#'   colour scale with a colour bar.
#' @param annotation_col Optional column name shown in hover text and
#'   the cell info panel.
#' @param show_cluster_label If \code{TRUE} (default), adds cluster-ID
#'   labels at cluster centroids.
#' @param point_size Marker size for scatter points
#' @param point_alpha Opacity for markers (0-1), applied as initial value
#' @param use_webgl Use WebGL (scattergl) instead of SVG (scatter).
#'   Default: \code{TRUE}.
#' @return A plotly htmlwidget object
#'
#' @keywords internal
build_umap_plotly <- function(umap_df, cluster_col, cell_col,
                               sample_col = NULL,
                               hover_cols = NULL,
                               color_by = NULL,
                               annotation_col = NULL,
                               show_cluster_label = TRUE,
                               point_size, point_alpha,
                               use_webgl = TRUE) {
  clusters    <- sort(unique(umap_df[[cluster_col]]))
  colors      <- cluster_color_map(clusters)
  has_samples <- !is.null(sample_col)

  # ---- Validate color_by ----
  use_color_by <- FALSE
  color_by_discrete <- FALSE
  color_by_values <- NULL
  color_by_palette <- NULL

  if (!is.null(color_by)) {
    if (!is.character(color_by) || length(color_by) != 1) {
      warning("color_by must be a single column name string. Falling back to cluster colouring.",
              call. = FALSE)
    } else if (!color_by %in% colnames(umap_df)) {
      warning("color_by column '", color_by, "' not found in umap_df. Falling back to cluster colouring.",
              call. = FALSE)
    } else if (color_by == cluster_col) {
      # Same as default — trace-level cluster palette, no legend needed
      message("build_umap_plotly: colouring by cluster (default)")
    } else {
      use_color_by <- TRUE
      cb_vals <- umap_df[[color_by]]
      if (is.numeric(cb_vals)) {
        color_by_discrete <- FALSE
      } else {
        color_by_discrete <- TRUE
        color_by_values <- sort(unique(as.character(cb_vals)))
        color_by_palette <- cluster_color_map(color_by_values)
      }
      message("build_umap_plotly: colouring by '", color_by, "'",
              if (color_by_discrete) " (discrete)" else " (continuous)")
    }
  }

  # Compute global min/max for continuous colour scale (shared across traces)
  global_cmin <- NULL
  global_cmax <- NULL
  if (use_color_by && !color_by_discrete) {
    global_cmin <- min(umap_df[[color_by]], na.rm = TRUE)
    global_cmax <- max(umap_df[[color_by]], na.rm = TRUE)
    if (global_cmin == global_cmax) {
      global_cmax <- global_cmin + 0.001  # avoid zero-range scale
    }
  }

  # ---- Validate hover_cols ----
  hover_cols_valid <- character(0)
  if (!is.null(hover_cols)) {
    if (!is.character(hover_cols)) {
      warning("hover_cols must be a character vector. Ignored.", call. = FALSE)
    } else {
      for (hc in hover_cols) {
        if (hc %in% colnames(umap_df)) {
          hover_cols_valid <- c(hover_cols_valid, hc)
        } else {
          warning("hover_cols: column '", hc, "' not found in umap_df. Skipping.",
                  call. = FALSE)
        }
      }
    }
  }

  # ---- Validate annotation_col ----
  has_annotation <- FALSE
  if (!is.null(annotation_col)) {
    if (!is.character(annotation_col) || length(annotation_col) != 1) {
      warning("annotation_col must be a single column name string. Ignored.",
              call. = FALSE)
    } else if (!annotation_col %in% colnames(umap_df)) {
      warning("annotation_col '", annotation_col,
              "' not found in umap_df. Ignored.", call. = FALSE)
    } else {
      has_annotation <- TRUE
    }
  }

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

    # Append hover_cols
    for (hc in hover_cols_valid) {
      val <- sub[[hc]]
      if (is.numeric(val)) {
        hover <- paste0(hover, "<br>", hc, ": ", format(val, digits = 4))
      } else {
        hover <- paste0(hover, "<br>", hc, ": ", as.character(val))
      }
    }

    # Append annotation_col
    if (has_annotation) {
      hover <- paste0(hover, "<br>", annotation_col, ": ",
                      as.character(sub[[annotation_col]]))
    }

    # ---- Per-point customdata: [cell_id, cluster, sample, UMAP_1, UMAP_2, annotation] ----
    cd <- lapply(seq_len(n), function(i) {
      list(
        as.character(sub[[cell_col]][i]),          # [1] cell_id
        cl_char,                                    # [2] cluster
        if (has_samples) as.character(sub[[sample_col]][i]) else "",  # [3] sample
        sub[["UMAP_1"]][i],                         # [4] UMAP_1
        sub[["UMAP_2"]][i],                         # [5] UMAP_2
        if (has_annotation) as.character(sub[[annotation_col]][i]) else ""  # [6] annotation
      )
    })

    # ---- Marker (colours) ----
    if (use_color_by) {
      cb_vals <- umap_df[[color_by]][idx]

      if (color_by_discrete) {
        # Discrete: per-point hex colours from palette
        pt_colors <- unname(color_by_palette[as.character(cb_vals)])
        marker <- list(
          color   = pt_colors,
          size    = point_size,
          opacity = point_alpha
        )
      } else {
        # Continuous: per-point numeric values with shared Viridis colour scale.
        # Only the first trace shows the colour bar to avoid duplicates.
        marker <- list(
          color      = cb_vals,
          cmin       = global_cmin,
          cmax       = global_cmax,
          colorscale = "Viridis",
          showscale  = identical(cl, clusters[[1]]),
          colorbar   = list(title = color_by),
          size       = point_size,
          opacity    = point_alpha
        )
      }
    } else {
      # Default: trace-level cluster colour
      marker <- list(
        color   = unname(colors[cl_char]),
        size    = point_size,
        opacity = point_alpha
      )
    }

    p <- plotly::add_trace(
      p,
      x          = sub[["UMAP_1"]],
      y          = sub[["UMAP_2"]],
      customdata = cd,
      text       = hover,
      hoverinfo  = "text",
      name       = paste0("cluster_", cl_char),
      marker     = marker,
      mode       = "markers",
      showlegend = FALSE
    )
  }

  # ---- Cluster labels (centroid annotations) ----
  if (show_cluster_label) {
    for (cl in clusters) {
      cl_char <- as.character(cl)
      idx <- umap_df[[cluster_col]] == cl
      cx  <- mean(umap_df[["UMAP_1"]][idx])
      cy  <- mean(umap_df[["UMAP_2"]][idx])

      p <- plotly::add_annotations(
        p,
        x          = cx,
        y          = cy,
        text       = cl_char,
        showarrow  = FALSE,
        font       = list(size = 13, color = "#2d3436"),
        bgcolor    = "rgba(255,255,255,0.75)",
        borderpad  = 3
      )
    }
  }

  # ---- Legend for discrete color_by ----
  if (use_color_by && color_by_discrete) {
    for (val in color_by_values) {
      p <- plotly::add_trace(
        p,
        x          = list(NA),
        y          = list(NA),
        type       = trace_type,
        mode       = "markers",
        name       = val,
        marker     = list(color = unname(color_by_palette[val]), size = 8),
        showlegend = TRUE,
        legendgroup = "cb"
      )
    }
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
