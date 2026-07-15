# Report module data ports ------------------------------------------------------

#' Build embedded data and script tags for registered report modules
#'
#' @return A list of script tags in dependency order.
#' @keywords internal
.build_report_data_ports <- function(marker_json, clusters_json, marker_n_top,
                                     dim_opacity, has_samples, sample_comp_json,
                                     cluster_colors_json, gene_expr_json,
                                     marker_gene_clusters_json,
                                     all_gene_sources_json, has_plot, qc_payload,
                                     has_feature, feature_diag_json, use_webgl,
                                     has_pca, pca_data_json, pca_has_sample,
                                     pca_color_by, pca_all_pcs_json,
                                     pca_loading_json, pca_loading_top_n,
                                     first_view, has_umap, panel_js_extra) {
  # Every serialized payload crosses the same HTML <script> boundary. Escape at
  # this final boundary so individual builders cannot accidentally omit it.
  marker_json <- .escape_json_for_script(marker_json)
  clusters_json <- .escape_json_for_script(clusters_json)
  sample_comp_json <- .escape_json_for_script(sample_comp_json)
  cluster_colors_json <- .escape_json_for_script(cluster_colors_json)
  gene_expr_json <- .escape_json_for_script(gene_expr_json)
  marker_gene_clusters_json <- .escape_json_for_script(marker_gene_clusters_json)
  all_gene_sources_json <- .escape_json_for_script(all_gene_sources_json)
  feature_diag_json <- .escape_json_for_script(feature_diag_json)
  pca_data_json <- .escape_json_for_script(pca_data_json)
  pca_all_pcs_json <- .escape_json_for_script(pca_all_pcs_json)
  pca_loading_json <- .escape_json_for_script(pca_loading_json)

  list(
    tags$script(htmltools::HTML(sprintf(
      "window._MARKER_DATA = %s;\nwindow._CLUSTERS = %s;\nwindow._MARKER_NTOP = %d;\nwindow._DIM_OPACITY = %s;\nwindow._HAS_SAMPLES = %s;",
      marker_json,
      clusters_json,
      marker_n_top,
      dim_opacity,
      if (has_samples) "true" else "false"
    ))),
    tags$script(htmltools::HTML(sprintf(
      "window._SAMPLE_COMP_DATA = %s;",
      sample_comp_json
    ))),
    tags$script(htmltools::HTML(sprintf(
      "window._CLUSTER_COLORS = %s;",
      cluster_colors_json
    ))),
    tags$script(htmltools::HTML(sprintf(
      "window._GENE_EXPR_DATA = %s;",
      gene_expr_json
    ))),
    tags$script(htmltools::HTML(sprintf(
      "window._MARKER_GENE_CLUSTERS = %s;\nwindow._ALL_GENE_SOURCES = %s;",
      marker_gene_clusters_json,
      all_gene_sources_json
    ))),
    if (has_plot) tags$script(htmltools::HTML(paste0(
      "window._QC_DATA = ",
      .escape_json_for_script(jsonlite::toJSON(
        qc_payload, auto_unbox = TRUE, digits = 6, na = "null"
      )),
      ";"
    ))),
    if (has_feature) list(
      tags$script(htmltools::HTML(paste0(
        "window._FEATURE_DIAG_DATA = ", feature_diag_json, ";"
      ))),
      tags$script(htmltools::HTML(paste0(
        "window._FEATURE_USE_WEBGL = ", if (use_webgl) "true" else "false", ";"
      )))
    ),
    if (has_pca) list(
      tags$script(htmltools::HTML(paste0(
        "window._PCA_DATA = ", pca_data_json, ";"
      ))),
      tags$script(htmltools::HTML(paste0(
        "window._PCA_HAS_SAMPLE = ", if (pca_has_sample) "true" else "false", ";",
        "window._PCA_USE_WEBGL = ", if (use_webgl) "true" else "false", ";",
        "window._PCA_INIT_MODE = ",
        .escape_json_for_script(jsonlite::toJSON(
          pca_color_by, auto_unbox = TRUE
        )), ";",
        "window._PCA_COLORS = ", cluster_colors_json, ";",
        "window._PCA_ALL_PCS = ", pca_all_pcs_json, ";",
        "window._PCA_LOADING_DATA = ", pca_loading_json, ";",
        "window._PCA_LOADING_TOP_N = ", pca_loading_top_n, ";"
      )))
    ),
    tags$script(htmltools::HTML(sprintf(
      "window._SR_INITIAL_VIEW = '%s';
      window._SR_HAS_UMAP = %s;",
      first_view,
      if (has_umap) "true" else "false"
    ))),
    tags$script(htmltools::HTML(paste(report_js(), panel_js_extra, sep = "\n"))),
    if (has_feature) tags$script(htmltools::HTML(feature_js())),
    if (has_pca) tags$script(htmltools::HTML(
      "window._PCA_COLORS = window._PCA_COLORS || {};"
    ))
  )
}
