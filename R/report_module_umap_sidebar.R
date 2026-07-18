# UMAP sidebar module ----------------------------------------------------------

#' Build UMAP sidebar slots and their serialized data ports
#'
#' @return A list containing sidebar tags and serialized UMAP-side data.
#' @keywords internal
.build_umap_sidebar_module <- function(has_umap, has_samples, umap_df,
                                       cluster_col, sample_col, clusters,
                                       cluster_cols, n_total, marker_df,
                                       umap_plot, gene_expr_df, feature_diag) {
  # ---- Sidebar: Cluster section (UMAP only) ----
  cluster_html <- if (has_umap) {
    lapply(clusters, function(cl) {
    n_cells <- sum(umap_df[[cluster_col]] == cl)
    pct     <- round(n_cells / n_total * 100, 1)
    cl_char <- as.character(cl)

    tags$div(
      class = "cluster-item",
      `data-cluster` = cl_char,
      tags$span(class = "cluster-check"),
      tags$span(
        class = "cluster-color-dot",
        style = sprintf("background-color: %s;", cluster_cols[cl_char])
      ),
      tags$span(class = "cluster-name", sprintf("Cluster %s", cl_char)),
      tags$span(
        class = "cluster-count",
        sprintf("%d (%.1f%%)", n_cells, pct)
      )
    )
    })
  } else {
    NULL
  }

  # ---- Sidebar: Sample section (optional, UMAP only) ----
  sample_html <- NULL
  if (has_umap && has_samples) {
    samples <- natural_sort(unique(umap_df[[sample_col]]))
    sample_html <- lapply(samples, function(s) {
      s_char <- as.character(s)
      n_cells <- sum(umap_df[[sample_col]] == s)
      pct     <- round(n_cells / n_total * 100, 1)
      tags$div(
        class = "sample-item",
        `data-sample` = s_char,
        tags$span(class = "sample-dot"),
        tags$span(class = "sample-name", s_char),
        tags$span(
          class = "sample-count",
          sprintf("%d (%.1f%%)", n_cells, pct)
        )
      )
    })
  }

  # ---- Marker data as JSON ----
  if (!is.null(marker_df) && nrow(marker_df) > 0) {
    marker_df$cluster <- as.character(marker_df$cluster)
    marker_json <- jsonlite::toJSON(marker_df, dataframe = "rows", auto_unbox = TRUE)
  } else {
    marker_json <- "[]"
  }

  clusters_json <- jsonlite::toJSON(as.character(clusters), auto_unbox = TRUE)

  # ---- UMAP plot as tags ----
  umap_tags <- if (!is.null(umap_plot)) htmltools::as.tags(umap_plot) else NULL

  # ---- Sidebar: tab-based layout ----
  sidebar_tabs <- list(
    tags$button(
      type = "button", class = "sidebar-tab active", id = "tab-clusters",
      `data-umap-mode` = "cluster", "Cluster"
    )
  )
  sidebar_contents <- list(
    tags$div(class = "sidebar-content", id = "sidebar-clusters",
      tags$div(class = "cluster-list", cluster_html)
    )
  )

  if (has_samples) {
    sidebar_tabs <- c(sidebar_tabs, list(
      tags$button(
        type = "button", class = "sidebar-tab", id = "tab-samples",
        `data-umap-mode` = "sample", "Sample"
      )
    ))
    sidebar_contents <- c(sidebar_contents, list(
      tags$div(class = "sidebar-content hidden", id = "sidebar-samples",
        tags$div(class = "sample-list", sample_html)
      )
    ))
  }

  # ---- Gene sidebar slot and data ports ----
  gene_sidebar <- .build_gene_sidebar_slot(
    gene_expr_df = gene_expr_df,
    marker_df = marker_df,
    feature_diag = feature_diag,
    cluster_cols = cluster_cols,
    clusters = clusters
  )
  sidebar_tabs <- c(sidebar_tabs, gene_sidebar$tabs)
  sidebar_contents <- c(sidebar_contents, gene_sidebar$contents)
  gene_expr_json <- gene_sidebar$gene_expr_json
  marker_gene_clusters_json <- gene_sidebar$marker_gene_clusters_json
  all_gene_sources_json <- gene_sidebar$all_gene_sources_json
  clusters <- gene_sidebar$clusters

  # ---- Sidebar assembly ----
  sidebar_html <- c(
    list(tags$div(class = "sidebar-tabs", sidebar_tabs)),
    sidebar_contents
  )

  list(
    sidebar_html = sidebar_html,
    marker_json = marker_json,
    clusters_json = clusters_json,
    umap_tags = umap_tags,
    gene_expr_json = gene_expr_json,
    marker_gene_clusters_json = marker_gene_clusters_json,
    all_gene_sources_json = all_gene_sources_json,
    marker_df = marker_df,
    clusters = clusters
  )
}

