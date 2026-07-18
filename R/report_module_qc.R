# QC report module --------------------------------------------------------------

#' Build the QC report module
#'
#' @param available Whether QC data are available.
#' @return A report module specification.
#' @keywords internal
.build_qc_report_module <- function(available) {
  .new_report_module(
    id = "plot",
    label = "QC",
    available = available,
    container_id = "sr-view-plot",
    container_class = "sr-view-plot",
    layout_class = "sr-analysis-grid plot-layout",
    slots = list(
      left = tags$div(class = "plot-nav",
        tags$div(class = "sr-control-half sr-control-half-top",
          tags$div(class = "plot-nav-label sr-switcher-label", "QC"),
          tags$div(class = "sr-module-view-switcher",
          tags$button(type = "button",
            class = "plot-nav-item sr-module-view-button active",
            `data-plot-nav` = "overview",
            "Overview"),
          tags$button(type = "button",
            class = "plot-nav-item sr-module-view-button",
            `data-plot-nav` = "single",
            "Single metric")
          )
        ),
        tags$div(class = "sr-control-half sr-control-half-bottom",
          tags$div(class = "plot-nav-label", "Adjustments"),
          tags$div(id = "plot-controls-dynamic")
        )
      ),
      centre = tags$div(class = "plot-main", id = "plot-main",
        tags$div(id = "plot-active-canvas", style = "flex:1;min-height:0;")
      ),
      right = tags$div(class = "plot-params", id = "plot-params",
        tags$div(class = "section-title", "QC statistics"),
        tags$div(id = "sr-qc-summary-content",
          tags$div(class = "sr-detail-empty", "Select a cell or violin to inspect its statistics.")
        )
      ),
      bottom = tags$div(
        class = "sr-detail-deck sr-qc-detail-deck",
        id = "sr-qc-detail-deck",
        tags$div(class = "sr-detail-empty", "Select a cell to inspect its QC data.")
      )
    )
  )
}
