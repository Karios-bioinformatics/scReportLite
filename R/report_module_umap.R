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
.build_umap_report_module <- function(available, hidden, sidebar_html,
                                      umap_tags, panel_sections_html) {
  .new_report_module(
    id = "umap",
    label = "UMAP",
    available = available,
    container_id = "sr-view-umap",
    container_class = "sr-view-umap",
    layout_class = NULL,
    style = if (hidden) "display:none;" else "",
    slots = list(
      left = tags$div(class = "sidebar", sidebar_html),
      centre = tags$div(class = "content-area",
        list(
          tags$div(class = "umap-section", id = "umap-section",
            tags$div(class = "section-title",
              "UMAP \u2014 click a cell to inspect, cluster to highlight"
            ),
            tags$div(class = "umap-container", id = "umap-container",
              umap_tags
            )
          ),
          tags$div(class = "cell-info-panel", id = "cell-info-panel",
            style = "display:none;",
            tags$div(class = "cell-info-header",
              tags$div(
                tags$span(class = "cell-info-title", "Cell Information"),
                tags$span(" \u2014 "),
                tags$span(class = "cell-info-cellid", id = "cell-info-cellid", "")
              ),
              tags$button(
                class = "copy-btn",
                id = "copy-cell-btn",
                onclick = "copyCellId()",
                "Copy Cell ID"
              )
            ),
            tags$div(
              id = "cell-info-content",
              tags$p(class = "cell-info-hint",
                "Click a cell on the UMAP to view its details")
            )
          )
        ),
        panel_sections_html
      )
    )
  )
}
