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
    layout_class = "sr-analysis-grid pca-layout",
    style = "display:none;",
    slots = list(
      left = tags$div(class = "pca-controls",
        tags$div(class = "pca-controls-section sr-pca-view-switcher",
          tags$div(class = "pca-controls-label sr-switcher-label", "PCA view"),
          tags$button(type = "button",
                      class = "pca-cm-btn sr-module-view-button active",
                      `data-pca-view` = "elbow", "Elbow"),
          tags$button(type = "button",
                      class = "pca-cm-btn sr-module-view-button",
                      `data-pca-view` = "score", "PC Score"),
          tags$button(type = "button",
                      class = "pca-cm-btn sr-module-view-button",
                      `data-pca-view` = "pair", "PCA")
        ),
        tags$div(class = "pca-controls-section",
          tags$div(class = "pca-controls-label", "Colour by"),
          tags$div(class = "pca-cm-buttons",
            tags$button(type = "button", class = "pca-cm-btn",
                        id = "pca-cm-cluster",
                        `data-pca-colour-mode` = "cluster", "Cluster"),
            if (has_sample) tags$button(
              type = "button", class = "pca-cm-btn active",
              id = "pca-cm-sample",
              `data-pca-colour-mode` = "sample", "Sample"
            )
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
          tags$button(type = "button", class = "pca-reset-btn",
                      `data-pca-reset` = "true", "Reset highlight")
        )
      ),
      centre = tags$div(class = "pca-plot-area", id = "pca-plot-area",
        tags$div(class = "pca-elbow-area", id = "pca-elbow-area",
          tags$div(class = "section-title", "PCA variance overview"),
          tags$div(class = "pca-container", id = "pca-elbow-container")
        ),
        tags$div(class = "pca-single-pc-area", id = "pca-single-pc-area",
                 style = "display:none;",
          tags$div(class = "section-title", id = "pca-single-pc-title",
                   "Single-PC score \u2014 PC_1"),
          tags$div(class = "pca-container", id = "pca-single-pc-container")
        ),
        tags$div(class = "pca-pair-area", id = "pca-pair-area",
                 style = "display:none;",
          tags$div(class = "section-title", id = "pca-pair-title",
                   "PCA \u2014 PC_1 vs PC_2"),
          tags$div(class = "pca-container", id = "pca-container")
        )
      ),
      right = tags$div(
        class = "sr-pca-loading-panel",
        tags$div(class = "section-title", "PC loading / composition"),
        tags$div(
          class = "sr-pca-loading-direction",
          tags$button(
            type = "button",
            class = "pca-cm-btn active",
            `data-pca-loading-direction` = "both",
            "Both"
          ),
          tags$button(
            type = "button",
            class = "pca-cm-btn",
            `data-pca-loading-direction` = "positive",
            "Positive"
          ),
          tags$button(
            type = "button",
            class = "pca-cm-btn",
            `data-pca-loading-direction` = "negative",
            "Negative"
          )
        ),
        tags$div(id = "sr-pca-loading-table",
          tags$div(class = "sr-detail-empty", "Select a PC to inspect its loadings.")
        )
      ),
      bottom = tags$div(
        class = "sr-detail-deck sr-pca-detail-deck",
        id = "sr-pca-detail-deck",
        tags$div(class = "sr-detail-empty", "Select a PC or cell to inspect its data.")
      )
    )
  )
}
