# Feature Diagnostics report module -------------------------------------------

#' Build the Feature Diagnostics report module
#'
#' @param available Whether Feature Diagnostics data are available.
#' @param active Whether this is the initially active module.
#' @return A report module specification.
#' @keywords internal
.build_feature_report_module <- function(available, active,
                                         resolution_payload = list()) {
  .new_report_module(
    id = "feature",
    label = "Feature",
    available = available,
    container_id = "sr-view-feature",
    container_class = "sr-view-feature",
    layout_class = "sr-analysis-grid feature-layout",
    style = if (!active) "display:none;" else "",
    slots = list(
      left = tags$div(class = "feature-nav", id = "feature-nav",
        tags$div(class = "sr-feature-view-switcher",
          tags$div(class = "feature-nav-label sr-switcher-label",
                   "Feature Diagnostics"),
          tags$button(type = "button",
            class = "feature-nav-item sr-module-view-button active",
            `data-feature-nav` = "scatter",
            "FeatureScatter"),
          tags$button(type = "button",
            class = "feature-nav-item sr-module-view-button",
            `data-feature-nav` = "varfeat",
            "Variable Features"),
          tags$button(type = "button",
            class = "feature-nav-item sr-module-view-button",
            `data-feature-nav` = "topexp",
            "Top Expressed Genes")
        ),
        tags$div(class = "feature-nav-label", "Adjustments"),
        tags$div(id = "feature-controls-dynamic")
      ),
      centre = tags$div(class = "feature-main", id = "feature-main",
        .build_resolution_capsule(
          resolution_payload,
          "sr-resolution-capsule-feature"
        ),
        tags$div(id = "feature-active-canvas",
          style = "flex:1;min-height:0;display:flex;flex-direction:column;")
      ),
      right = tags$div(class = "feature-params", id = "feature-params",
        tags$section(class = "sr-feature-top-panel", id = "sr-feature-top-panel",
          tags$div(class = "section-title", "Top N features"),
          tags$div(id = "sr-feature-top-list",
            tags$div(class = "sr-detail-empty", "Open Variable Features to inspect Top N.")
          )
        )
      ),
      bottom = tags$div(
        class = "sr-detail-deck sr-feature-detail-deck",
        id = "sr-feature-detail-deck",
        tags$div(class = "sr-detail-empty", "Select a cell or gene to inspect its data.")
      )
    )
  )
}
