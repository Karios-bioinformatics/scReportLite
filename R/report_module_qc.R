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
    layout_class = "plot-layout",
    slots = list(
      left = tags$div(class = "plot-nav",
        tags$div(class = "plot-nav-label", "QC"),
        tags$div(class = "plot-nav-item active", `data-plot-nav` = "overview",
          onclick = "_PLOT_selectQcView('overview')",
          tags$span(class = "plot-nav-dot"), "Overview"),
        tags$div(class = "plot-nav-item", `data-plot-nav` = "single",
          onclick = "_PLOT_selectQcView('single')",
          tags$span(class = "plot-nav-dot"), "Single metric"),
        tags$div(class = "plot-nav-item", `data-plot-nav` = "scatter",
          onclick = "_PLOT_selectQcView('scatter')",
          tags$span(class = "plot-nav-dot"), "nCount vs nFeature")
      ),
      centre = tags$div(class = "plot-main", id = "plot-main",
        tags$div(id = "plot-active-canvas", style = "flex:1;min-height:0;")
      ),
      right = tags$div(class = "plot-params", id = "plot-params",
        tags$div(id = "plot-controls-dynamic")
      )
    )
  )
}

