# Feature Diagnostics report module -------------------------------------------

#' Build the Feature Diagnostics report module
#'
#' @param available Whether Feature Diagnostics data are available.
#' @param active Whether this is the initially active module.
#' @return A report module specification.
#' @keywords internal
.build_feature_report_module <- function(available, active) {
  .new_report_module(
    id = "feature",
    label = "Feature",
    available = available,
    container_id = "sr-view-feature",
    container_class = "sr-view-feature",
    layout_class = "feature-layout",
    style = if (!active) "display:none;" else "",
    slots = list(
      left = tags$div(class = "feature-nav", id = "feature-nav",
        tags$div(class = "feature-nav-label", "Feature Diagnostics"),
        tags$div(class = "feature-nav-item active", `data-feature-nav` = "scatter",
          onclick = "_FEATURE_selectView('scatter')",
          tags$span(class = "feature-nav-dot"), "FeatureScatter"),
        tags$div(class = "feature-nav-item", `data-feature-nav` = "varfeat",
          onclick = "_FEATURE_selectView('varfeat')",
          tags$span(class = "feature-nav-dot"), "Variable Features"),
        tags$div(class = "feature-nav-item", `data-feature-nav` = "topexp",
          onclick = "_FEATURE_selectView('topexp')",
          tags$span(class = "feature-nav-dot"), "Top Expressed Genes"),
        tags$div(class = "feature-nav-item", `data-feature-nav` = "elbow",
          onclick = "_FEATURE_selectView('elbow')",
          tags$span(class = "feature-nav-dot"), "Elbow Plot")
      ),
      centre = tags$div(class = "feature-main", id = "feature-main",
        tags$div(id = "feature-active-canvas",
          style = "flex:1;min-height:0;display:flex;flex-direction:column;")
      ),
      right = tags$div(class = "feature-params", id = "feature-params",
        tags$div(id = "feature-controls-dynamic")
      )
    )
  )
}

