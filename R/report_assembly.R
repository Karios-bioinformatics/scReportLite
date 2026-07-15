# scReportLite: HTML report assembly --------------------------------------------

# ---- HTML assembly -------------------------------------------------------------

#' Assemble and write the complete HTML report
#'
#' @param umap_plot A plotly htmlwidget object
#' @param umap_df The input UMAP data frame (for sidebar stats)
#' @param marker_df The input marker data frame (NULL or data.frame)
#' @param cluster_col Name of the cluster column
#' @param cell_col Name of the cell column
#' @param sample_col Optional name of the sample column in umap_df (NULL to skip)
#' @param output Path to output HTML file
#' @param title Report title
#' @param dim_opacity Opacity for non-highlighted points (0-1)
#' @param marker_n_top Number of top marker genes to show per cluster
#' @return Invisibly, the path to the output file
#'
#' @keywords internal
assemble_report <- function(umap_plot = NULL, umap_df = NULL, marker_df,
                             cluster_col, cell_col, sample_col,
                             gene_expr_df = NULL,
                             pca_df = NULL,
                             pca_data_json = "null",
                             pca_has_sample = FALSE,
                             pca_color_by = "cluster",
                             pca_all_pcs_json = "[]",
                             pca_loading_json = "[]",
                             pca_loading_top_n = 10,
                             qc_payload = NULL,
                             feature_diag = NULL,
                             feature_diag_json = "null",
                             use_webgl = TRUE,
                             output, title, dim_opacity, marker_n_top,
                             panels = c("umap", "marker_table")) {

  has_umap     <- !is.null(umap_df) && "umap" %in% panels
  has_pca      <- !is.null(pca_df) && "pca" %in% panels
  has_plot     <- !is.null(qc_payload) && "qc" %in% panels
  has_feature  <- !is.null(feature_diag) && "feature" %in% panels

  # ---- Compute clusters / sidebar stats (UMAP only) ----
  if (has_umap) {
    clusters     <- natural_sort(unique(umap_df[[cluster_col]]))
    cluster_cols <- cluster_color_map(clusters)
    n_total      <- nrow(umap_df)
    has_samples  <- !is.null(sample_col)
  } else {
    clusters     <- character(0)
    cluster_cols <- character(0)
    n_total      <- 0L
    has_samples  <- FALSE
    if (!is.null(pca_df))  n_total <- nrow(pca_df)
    if (!is.null(qc_payload$cells)) n_total <- length(qc_payload$cells)
  }

  # ---- Build the UMAP module's sidebar and data ports ----
  umap_sidebar <- .build_umap_sidebar_module(
    has_umap = has_umap,
    has_samples = has_samples,
    umap_df = umap_df,
    cluster_col = cluster_col,
    sample_col = sample_col,
    clusters = clusters,
    cluster_cols = cluster_cols,
    n_total = n_total,
    marker_df = marker_df,
    umap_plot = umap_plot,
    gene_expr_df = gene_expr_df,
    feature_diag = feature_diag
  )
  sidebar_html <- umap_sidebar$sidebar_html
  marker_json <- umap_sidebar$marker_json
  clusters_json <- umap_sidebar$clusters_json
  umap_tags <- umap_sidebar$umap_tags
  gene_expr_json <- umap_sidebar$gene_expr_json
  marker_gene_clusters_json <- umap_sidebar$marker_gene_clusters_json
  all_gene_sources_json <- umap_sidebar$all_gene_sources_json
  marker_df <- umap_sidebar$marker_df
  clusters <- umap_sidebar$clusters

  # ---- Build per-sample composition data (for JS-driven chart) ----
  sample_comp_json <- "{}"
  if (has_samples) {
    comp_counts <- table(umap_df[[sample_col]], umap_df[[cluster_col]])
    comp_list <- lapply(rownames(comp_counts), function(s) {
      row <- as.list(as.integer(comp_counts[s, ]))
      names(row) <- colnames(comp_counts)
      row
    })
    names(comp_list) <- rownames(comp_counts)
    sample_comp_json <- jsonlite::toJSON(comp_list, auto_unbox = TRUE)
  }

  # ---- Cluster colours as JSON (for JS-driven charts) ----
  cluster_colors_json <- jsonlite::toJSON(as.list(cluster_cols), auto_unbox = TRUE)

  # ---- Build panel sections for content area ----
  non_umap_panels  <- setdiff(panels, c("umap", "pca", "qc", "feature"))

  # Prepare shared panel params
  panel_params <- list(
    umap_df        = umap_df,
    marker_df      = marker_df,
    cluster_col    = cluster_col,
    cell_col       = cell_col,
    sample_col     = sample_col,
    cluster_colors = cluster_cols,
    n_total        = n_total
  )

  # Render each non-UMAP panel section
  panel_sections_html <- lapply(non_umap_panels, function(pn) {
    if (pn == "marker_table") {
      tags$div(class = "panel-section marker-section",
        tags$div(class = "section-title", id = "marker-title",
          "Click a cluster to view marker genes"
        ),
        tags$div(id = "marker-table-container",
          tags$p(class = "no-data",
            "Select a cluster from the sidebar to see its marker genes.")
        )
      )
    } else {
      render_panel_section(pn, panel_params)
    }
  })

  # Collect extra CSS and JS from panels
  panel_css_extra <- collect_panel_css(non_umap_panels)
  panel_js_extra  <- collect_panel_js(non_umap_panels)
  # ---- Register independently composable report modules ----
  report_modules <- list(
    .build_qc_report_module(has_plot),
    .build_feature_report_module(has_feature, active = FALSE),
    .build_pca_report_module(has_pca, pca_has_sample),
    .build_umap_report_module(
      has_umap,
      hidden = has_plot || has_feature,
      sidebar_html = sidebar_html,
      umap_tags = umap_tags,
      panel_sections_html = panel_sections_html
    )
  )
  first_view <- .first_report_module(report_modules)
  report_modules[[2]]$style <- if (first_view != "feature") "display:none;" else ""
  view_tabs_html <- .render_report_module_tabs(report_modules, first_view)

  data_port_tags <- .build_report_data_ports(
    marker_json = marker_json,
    clusters_json = clusters_json,
    marker_n_top = marker_n_top,
    dim_opacity = dim_opacity,
    has_samples = has_samples,
    sample_comp_json = sample_comp_json,
    cluster_colors_json = cluster_colors_json,
    gene_expr_json = gene_expr_json,
    marker_gene_clusters_json = marker_gene_clusters_json,
    all_gene_sources_json = all_gene_sources_json,
    has_plot = has_plot,
    qc_payload = qc_payload,
    has_feature = has_feature,
    feature_diag_json = feature_diag_json,
    use_webgl = use_webgl,
    has_pca = has_pca,
    pca_data_json = pca_data_json,
    pca_has_sample = pca_has_sample,
    pca_color_by = pca_color_by,
    pca_all_pcs_json = pca_all_pcs_json,
    pca_loading_json = pca_loading_json,
    pca_loading_top_n = pca_loading_top_n,
    first_view = first_view,
    has_umap = has_umap,
    panel_js_extra = panel_js_extra
  )


  # ---- Assemble full page ----
  page <- tags$html(
    tags$head(
      tags$meta(charset = "UTF-8"),
      tags$meta(
        name    = "viewport",
        content = "width=device-width, initial-scale=1.0"
      ),
      tags$title(title),
      tags$style(htmltools::HTML(paste(report_css(), panel_css_extra, sep = "\n")))
    ),
    tags$body(
      tags$div(class = "container",
        # Header
        tags$div(class = "report-header",
          tags$span(class = "report-title", title),
          tags$span(class = "report-meta",
            if (has_umap) {
              sprintf("%d cells | %d clusters | %s",
                      n_total, length(clusters),
                      format(Sys.time(), "%Y-%m-%d %H:%M"))
            } else {
              sprintf("%d cells | %s",
                      n_total,
                      format(Sys.time(), "%Y-%m-%d %H:%M"))
            }
          )
        ),

        # View tabs (standalone, only when PCA is available, v0.2.0)
        view_tabs_html,

        # Main layout with view containers
        tags$div(class = "main-layout",

          # Each module owns its slots; the framework only mounts them.
          lapply(report_modules, .render_report_module)
        )
      ),

      # ---- Embedded module data ports and scripts ----
      data_port_tags
    )
  )

  # ---- Attach Plotly dependencies for client-side Plotly views ----
  # When QC / Feature / PCA / UMAP are present, the report uses Plotly.newPlot
  # on the client. Without an R-side plotly widget, save_html won't detect the
  # dependency and won't generate the _files libdir.
  needs_plotly_client <- has_plot || has_feature || has_pca || has_umap
  if (needs_plotly_client) {
    dummy <- plotly::plot_ly(x = 1, y = 1, type = "scatter", mode = "markers")
    deps <- htmltools::htmlDependencies(htmltools::as.tags(dummy))
    page <- htmltools::attachDependencies(page, deps, append = TRUE)
  }

  libdir <- paste0(tools::file_path_sans_ext(output), "_files")
  htmltools::save_html(page, file = output, libdir = libdir)

  message("scReportLite: report written to ", normalizePath(output, mustWork = FALSE))
  message("  Dependencies: ", normalizePath(libdir, mustWork = FALSE))

  invisible(output)
}


