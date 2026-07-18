# UMAP report module ------------------------------------------------------------

#' Build the UMAP report module
#'
#' @param available Whether UMAP data are available.
#' @param hidden Whether the module starts hidden.
#' @param sidebar_html Sidebar tags.
#' @param umap_tags Plotly UMAP tags.
#' @param panel_sections_html Additional content panels.
#' @return A report module specification.
#' @keywords internal
.build_resolution_capsule <- function(resolution_payload, capsule_id) {
  resolution_items <- lapply(
    resolution_payload$resolutions %||% list(),
    function(item) {
      tags$button(
        type = "button",
        class = paste(
          "sr-resolution-dot",
          if (identical(item$id, resolution_payload$active)) "active" else ""
        ),
        `data-resolution` = item$id,
        title = item$id,
        item$label %||% item$id
      )
    }
  )
  if (!length(resolution_items)) return(NULL)
  tags$div(
    class = "sr-resolution-capsule",
    id = capsule_id,
    `data-resolution-context` = capsule_id,
    resolution_items
  )
}

.build_umap_report_module <- function(available, hidden, sidebar_html,
                                      umap_tags, panel_sections_html,
                                      resolution_payload = list()) {
  .new_report_module(
    id = "umap",
    label = "UMAP",
    available = available,
    container_id = "sr-view-umap",
    container_class = "sr-view-umap",
    layout_class = "sr-analysis-grid sr-umap-layout",
    style = if (hidden) "display:none;" else "",
    slots = list(
      left = tags$div(class = "sidebar", sidebar_html),
      centre = tags$div(class = "content-area",
        .build_resolution_capsule(
          resolution_payload,
          "sr-resolution-capsule-umap"
        ),
        list(
          tags$div(class = "umap-section", id = "umap-section",
            tags$div(class = "section-title",
              "UMAP \u2014 click a cell to inspect, cluster to highlight"
            ),
            tags$div(class = "umap-container", id = "umap-container",
              umap_tags
            )
          )
        )
      ),
      right = tags$div(
        class = "sr-umap-stat-panel",
        id = "sr-umap-stat-panel",
        tags$div(class = "section-title", "Cluster size"),
        tags$div(id = "sr-umap-stat-content",
          tags$div(class = "sr-detail-empty", "Global cluster statistics appear here.")
        ),
        tags$div(class = "sr-umap-result-panels", panel_sections_html)
      ),
      bottom = tags$div(
        class = "sr-detail-deck sr-umap-detail-deck",
        id = "sr-umap-detail-deck",
        tags$div(class = "cell-info-panel", id = "cell-info-panel",
          tags$div(class = "cell-info-header",
            tags$span(class = "cell-info-title", "Cell Information"),
            tags$span(class = "cell-info-cellid", id = "cell-info-cellid", ""),
            tags$button(
              type = "button", class = "copy-btn", id = "copy-cell-btn",
              `data-copy-cell` = "true", "Copy Cell ID"
            )
          ),
          tags$div(
            id = "cell-info-content",
            tags$p(class = "cell-info-hint",
              "Select a cell, cluster, sample, or gene.")
          )
        )
      )
    )
  )
}
