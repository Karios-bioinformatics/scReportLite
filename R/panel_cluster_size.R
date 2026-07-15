# Panel: Cluster Size Barplot --------------------------------------------------
# v0.1.4
#
# Displays cell counts per cluster as an interactive plotly bar chart.
# Hover tooltips show both cell count and percentage of total.
# Bar colours match the cluster colour map used in the UMAP plot.
#
# Registered via .onLoad in panels.R — do NOT call register_panel() here.

panel_cluster_size <- list(
  name  = "cluster_size",
  title = "Cluster Size",

  render = function(params) {
    umap_df      <- params$umap_df
    cluster_col  <- params$cluster_col
    colors       <- params$cluster_colors
    n_total      <- if (is.null(params$n_total)) nrow(umap_df) else params$n_total

    # Count cells per cluster
    counts   <- table(umap_df[[cluster_col]])
    cl_names <- names(counts)

    # Build data frame
    df <- data.frame(
      cluster  = cl_names,
      n_cells  = as.integer(counts),
      pct      = round(as.numeric(counts) / n_total * 100, 1),
      stringsAsFactors = FALSE
    )

    natural_levels <- natural_sort(df$cluster)
    df <- df[match(natural_levels, df$cluster), , drop = FALSE]

    # Build hover tooltip
    df$hover <- sprintf(
      "Cluster %s<br>%d cells (%.1f%%)",
      df$cluster, df$n_cells, df$pct
    )

    # Bar colours — match UMAP cluster colour map
    bar_colors <- unname(colors[df$cluster])

    # Build plotly bar chart
    p <- plotly::plot_ly(
      df,
      x          = ~cluster,
      y          = ~n_cells,
      type       = "bar",
      marker     = list(
        color = bar_colors,
        line  = list(color = "#ffffff", width = 1)
      ),
      text       = ~hover,
      hoverinfo  = "text",
      hoverlabel = list(
        bgcolor = "#2d3436",
        font    = list(color = "#ffffff")
      )
    )

    p <- plotly::layout(
      p,
      xaxis = list(
        title    = "Cluster",
        type     = "category",
        categoryorder = "array",
        categoryarray = df$cluster
      ),
      yaxis = list(
        title = "Number of Cells"
      ),
      margin     = list(l = 60, r = 30, b = 60, t = 20),
      showlegend = FALSE,
      bargap     = 0.25
    )

    p <- plotly::config(
      p,
      displayModeBar = FALSE,
      displaylogo    = FALSE
    )

    htmltools::as.tags(p)
  }
)
