# PCA report module -------------------------------------------------------------

#' Build the PCA report module
#'
#' @param available Whether PCA data are available.
#' @param has_sample Whether sample colouring is available.
#' @return A report module specification.
#' @keywords internal
.build_pca_report_module <- function(available, has_sample) {
  .new_report_module(
    id = "pca",
    label = "PCA",
    available = available,
    container_id = "sr-view-pca",
    container_class = "sr-view-pca",
    layout_class = "pca-layout",
    style = "display:none;",
    slots = list(
      left = tags$div(class = "pca-controls",
        tags$div(class = "pca-controls-section",
          tags$div(class = "pca-controls-label", "Colour by"),
          tags$div(class = "pca-cm-buttons",
            tags$button(class = "pca-cm-btn active", id = "pca-cm-cluster",
                        onclick = "switchPcaColorMode('cluster')", "Cluster"),
            if (has_sample) tags$button(class = "pca-cm-btn", id = "pca-cm-sample",
                        onclick = "switchPcaColorMode('sample')", "Sample")
          )
        ),
        tags$div(class = "pca-controls-section",
          tags$div(class = "pca-controls-label", "PCs"),
          tags$div(class = "pca-pc-list", id = "pca-pc-list")
        ),
        tags$div(class = "pca-controls-section",
          tags$div(class = "pca-controls-label", "Groups"),
          tags$div(class = "pca-group-list", id = "pca-group-list")
        ),
        tags$div(class = "pca-controls-section",
          tags$button(class = "pca-reset-btn",
                      onclick = "resetPcaHighlight()", "Reset highlight")
        )
      ),
      centre = tags$div(class = "pca-plot-area", id = "pca-plot-area",
        tags$div(class = "pca-single-pc-area", id = "pca-single-pc-area",
                 style = "display:none;",
          tags$div(class = "section-title", id = "pca-single-pc-title",
                   "Single-PC score \u2014 PC_1"),
          tags$div(class = "pca-container", id = "pca-single-pc-container")
        ),
        tags$div(class = "pca-loading-area", id = "pca-loading-area",
                 style = "display:none;",
          tags$div(class = "section-title", "PC loading / composition"),
          tags$div(id = "pca-loading-content")
        ),
        tags$div(class = "pca-pair-area", id = "pca-pair-area",
          tags$div(class = "section-title", id = "pca-pair-title",
                   "PCA \u2014 PC_1 vs PC_2"),
          tags$div(class = "pca-container", id = "pca-container")
        )
      )
    )
  )
}
