# Panel: Sample Composition (Stacked Barplot) -----------------------------------
# v0.1.4
#
# Displays cluster composition per sample as a stacked bar chart.
# Each bar = one sample, each stack segment = one cluster.
# Hover shows sample, cluster, cell count, and percentage within sample.
# Cluster colours match the UMAP colour map.
# Helps observe sample-level heterogeneity and potential batch effects.
#
# Registered via panels.R — do NOT call register_panel() here.

panel_sample_composition <- list(
  name  = "sample_composition",
  title = "Sample Composition",

  render = function(params) {
    umap_df      <- params$umap_df
    cluster_col  <- params$cluster_col
    sample_col   <- params$sample_col
    colors       <- params$cluster_colors

    # Guard: sample column must be available
    if (is.null(sample_col) || !sample_col %in% colnames(umap_df)) {
      return(tags$p(
        class = "no-data",
        "Sample column not available. Provide sample_col to sc_report() to render this panel."
      ))
    }

    # Cross-tabulate: rows = samples, cols = clusters
    counts <- table(umap_df[[sample_col]], umap_df[[cluster_col]])
    sample_names  <- rownames(counts)
    cluster_names <- colnames(counts)

    # Sort clusters numerically if possible
    cl_numeric <- suppressWarnings(as.numeric(cluster_names))
    if (!anyNA(cl_numeric)) {
      cluster_names <- cluster_names[order(cl_numeric)]
    } else {
      cluster_names <- sort(cluster_names)
    }

    sample_totals <- as.integer(rowSums(counts))

    # Build a stacked bar chart: one trace per cluster
    p <- plotly::plot_ly(type = "bar")

    for (cl in cluster_names) {
      cl_counts <- as.integer(counts[, cl])
      cl_pct    <- round(cl_counts / sample_totals * 100, 1)

      hover <- sprintf(
        "Sample: %s<br>Cluster: %s<br>%d cells (%.1f%% of sample)",
        sample_names, cl, cl_counts, cl_pct
      )

      p <- plotly::add_trace(
        p,
        x          = factor(sample_names, levels = sample_names),
        y          = cl_counts,
        name       = paste0("Cluster ", cl),
        type       = "bar",
        marker     = list(
          color = unname(colors[cl]),
          line  = list(color = "#ffffff", width = 1)
        ),
        text       = hover,
        hoverinfo  = "text",
        hoverlabel = list(
          bgcolor = "#2d3436",
          font    = list(color = "#ffffff")
        )
      )
    }

    p <- plotly::layout(
      p,
      barmode   = "stack",
      xaxis     = list(
        title = "Sample",
        type  = "category"
      ),
      yaxis     = list(
        title = "Number of Cells"
      ),
      margin    = list(l = 60, r = 30, b = 60, t = 20),
      legend    = list(
        title = list(text = "Cluster"),
        traceorder = "normal"
      )
    )

    p <- plotly::config(
      p,
      displayModeBar = FALSE,
      displaylogo    = FALSE
    )

    htmltools::as.tags(p)
  }
)
